#[compute]
#version 450

// An ant colony's walking (AntColony; Beetles on the ground), on the GPU.
// Each one's mind is the CPU's (where to go, what to do), or, for the ants
// themselves, here too (push constant y 1: see main); here
// its body: turning to its target with a weave, speeding up and slowing,
// stepping on, kept apart from the others near it (a hashed grid; less
// round food, not from its mate), set on the ground (a height grid baked
// round the colony), its transform and pose written out. Three passes
// (push constant x): 0 the grid cleared, 1 each put in its bucket, 2 each
// walked. An ant flagged in the air (a beetle flying, riding its mate) is
// left where the CPU has it.

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

const uint TABLE = 16384u;
const uint SLOTS = 16u;

layout(set = 0, binding = 0, std430) restrict readonly buffer Params {
	vec4 a; // dt, time, how many, top speed (m/s)
	vec4 b; // the cell (m: how far apart they keep), its body's height (m), its lay tilt (rad), how far from food it stands to feed (m)
	vec4 hm; // the height grid: its corner x, z (m), its step (m), its samples a side (0: level, 0 m)
	vec4 nest; // (its mind here) where they live, x y z; how wide their lanes to and from it (m)
} prm;
layout(set = 0, binding = 1, std430) restrict readonly buffer PosIn { float f[]; } pin;
layout(set = 0, binding = 2, std430) restrict writeonly buffer PosOut { float f[]; } pout;
layout(set = 0, binding = 3, std430) restrict buffer Yaw { float f[]; } yaw_;
layout(set = 0, binding = 4, std430) restrict buffer Speed { float f[]; } spd;
layout(set = 0, binding = 5, std430) restrict buffer Target { float f[]; } tgt;
layout(set = 0, binding = 6, std430) restrict readonly buffer Food { float f[]; } food;
layout(set = 0, binding = 7, std430) restrict readonly buffer Pace { float f[]; } pace;
layout(set = 0, binding = 8, std430) restrict readonly buffer Seed { float f[]; } seed;
layout(set = 0, binding = 9, std430) restrict readonly buffer Task { int i[]; } task;
layout(set = 0, binding = 10, std430) restrict buffer FeedK { float f[]; } feedk;
layout(set = 0, binding = 11, std430) restrict buffer LayK { float f[]; } layk;
layout(set = 0, binding = 12, std430) restrict readonly buffer Fly { float f[]; } fly;
layout(set = 0, binding = 13, std430) restrict readonly buffer Air { int i[]; } air;
layout(set = 0, binding = 14, std430) restrict readonly buffer Partner { int i[]; } partner;
layout(set = 0, binding = 15, std430) restrict buffer GridCount { int c[]; } gcount;
layout(set = 0, binding = 16, std430) restrict buffer GridSlots { int s[]; } gslot;
layout(set = 0, binding = 17, std430) restrict writeonly buffer Out { float f[]; } outb;
layout(set = 0, binding = 18, std430) restrict readonly buffer Heights { float f[]; } hts;
layout(set = 0, binding = 19, std430) restrict buffer Counters { uint c[]; } ctr; // 0: gone off the baked ground; 1: loads taken up this frame; 2: loads brought home
// each one's mind's own (push constant y 1: its mind here too), 12 floats: its wait (s), its place round the food (rad), the middle (3) and the reach of where it scouts, its heading (rad), its pause (> 0 stopped for another, < 0 just parted), its trip (0 to the food and at it, 1 home with its load, 2 in at the nest), 3 spare
layout(set = 0, binding = 20, std430) restrict buffer Mind { float f[]; } mind;

layout(push_constant, std430) uniform Push { ivec4 v; } pc;

uint bucket(ivec2 c) {
	return ((uint(c.x) * 73856093u) ^ (uint(c.y) * 19349663u)) & (TABLE - 1u);
}

vec3 P(uint i) { return vec3(pin.f[i * 3u], pin.f[i * 3u + 1u], pin.f[i * 3u + 2u]); }

float rnd(uint i, float t, uint salt) {
	uint h = i * 747796405u + uint(t * 997.0) * 2891336453u + salt * 1664525u;
	h = ((h >> ((h >> 28u) + 4u)) ^ h) * 277803737u;
	return float((h >> 22u) ^ h) / 4294967295.0;
}

float wrap_pi(float a) {
	return a - 6.2831853 * floor((a + 3.14159265) / 6.2831853);
}

// the ground's height at x, z (the baked grid, bilinear; past it, its edge)
float ground(float x, float z) {
	int res = int(prm.hm.w);
	if (res < 2) return 0.0;
	vec2 g = clamp((vec2(x, z) - prm.hm.xy) / prm.hm.z, vec2(0.0), vec2(float(res - 1)) - 0.001);
	ivec2 c = ivec2(floor(g));
	vec2 f = g - vec2(c);
	float h00 = hts.f[c.y * res + c.x];
	float h10 = hts.f[c.y * res + c.x + 1];
	float h01 = hts.f[(c.y + 1) * res + c.x];
	float h11 = hts.f[(c.y + 1) * res + c.x + 1];
	return mix(mix(h00, h10, f.x), mix(h01, h11, f.x), f.y);
}

void main() {
	uint i = gl_GlobalInvocationID.x;
	int pass_ = pc.v.x;
	uint n = uint(prm.a.z);
	float cell = prm.b.x;
	if (pass_ == 0) {
		if (i < TABLE) gcount.c[i] = 0;
		if (i == 0u) { ctr.c[0] = 0u; ctr.c[1] = 0u; ctr.c[2] = 0u; }
		return;
	}
	if (i >= n) return;
	vec3 p0 = P(i);
	if (pass_ == 1) {
		uint h = bucket(ivec2(floor(p0.xz / cell)));
		int s = atomicAdd(gcount.c[h], 1);
		if (s < int(SLOTS)) gslot.s[h * SLOTS + uint(s)] = int(i);
		return;
	}
	float dt = prm.a.x;
	float t = prm.a.y;
	float top = prm.a.w;
	if (air.i[i] != 0) { // (in the air: the CPU's)
		pout.f[i * 3u] = p0.x; pout.f[i * 3u + 1u] = p0.y; pout.f[i * 3u + 2u] = p0.z;
		return;
	}
	float yaw = yaw_.f[i];
	float speed = spd.f[i];
	float sd = seed.f[i];
	vec3 fwd = vec3(-sin(yaw), 0.0, -cos(yaw));
	vec3 tg = vec3(tgt.f[i * 3u], tgt.f[i * 3u + 1u], tgt.f[i * 3u + 2u]);
	vec3 fd = vec3(food.f[i * 3u], food.f[i * 3u + 1u], food.f[i * 3u + 2u]);
	float pause = 0.0;
	uint mb = i * 12u;
	if (pc.v.y == 1) {
		// its mind (AntColony._think's, an ant's, here). Scouting: a
		// wandering line, its heading kept and drifting, a stop now and
		// then, turned back in when it's far out. Foraging: to its place
		// round the food, its mouth to it once it's there; fed, home along
		// the line to the nest (to its own side of it), in a while, out
		// again. (Laying, 3, and steered, 4: told from the CPU.)
		int tk = task.i[i];
		float wait = mind.f[mb] - dt;
		float fk = feedk.f[i];
		pause = mind.f[mb + 7u];
		int ph = int(mind.f[mb + 8u]);
		if (tk != 3) layk.f[i] = max(layk.f[i] - dt * 2.0, 0.0);
		if (tk == 0) {
			fk = max(fk - dt * 2.0, 0.0);
			if (wait <= 0.0) {
				if (rnd(i, t, 1u) < 0.2) {
					tg = p0;
					wait = mix(0.4, 1.2, rnd(i, t, 2u));
				} else {
					float hd = mind.f[mb + 6u] + mix(-0.9, 0.9, rnd(i, t, 3u));
					vec3 off = p0 - vec3(mind.f[mb + 2u], mind.f[mb + 3u], mind.f[mb + 4u]);
					if (length(off.xz) > mind.f[mb + 5u] * 0.85) {
						float home = atan(off.x, off.z);
						hd += wrap_pi(home - hd) * 0.7;
					}
					mind.f[mb + 6u] = hd;
					tg = p0 + vec3(-sin(hd), 0.0, -cos(hd)) * mix(0.02, 0.06, rnd(i, t, 4u));
					wait = mix(0.5, 1.4, rnd(i, t, 5u));
				}
			}
		} else if (tk == 1 && ph > 0) {
			fk = max(fk - dt * 2.0, 0.0);
			if (ph == 1) {
				vec3 along = fd - prm.nest.xyz;
				along.y = 0.0;
				vec3 lane = length(along) > 1e-4 ? cross(normalize(along), vec3(0.0, 1.0, 0.0)) * (sd - 0.5) * prm.nest.w : vec3(0.0);
				tg = prm.nest.xyz + lane;
				if (length(p0.xz - tg.xz) < 0.006 || wait <= 0.0) {
					atomicAdd(ctr.c[2], 1u); // (home with it: counted)
					ph = 2;
					wait = mix(1.0, 2.5, rnd(i, t, 9u));
				}
			} else if (wait <= 0.0) {
				ph = 0;
				mind.f[mb + 1u] = rnd(i, t, 10u) * 6.2831853;
				wait = mix(3.0, 7.0, rnd(i, t, 11u));
			}
		} else if (tk == 1) {
			float slot = mind.f[mb + 1u];
			tg = fd + vec3(cos(slot), 0.0, sin(slot)) * prm.b.w;
			bool there = length(p0.xz - tg.xz) < 0.003;
			fk = fk + clamp((there && speed < 0.015 ? 1.0 : 0.0) - fk, -dt * 2.0, dt * 2.0);
			if (wait <= 0.0) {
				if (there) { // (fed, its load taken up: home with it; counted)
					ph = 1;
					wait = 40.0;
					atomicAdd(ctr.c[1], 1u);
				} else {
					slot += mix(0.6, 1.8, rnd(i, t, 6u)) * (rnd(i, t, 7u) < 0.5 ? 1.0 : -1.0);
					wait = mix(3.0, 7.0, rnd(i, t, 8u));
					mind.f[mb + 1u] = slot;
				}
			}
		} else {
			fk = max(fk - dt * 2.0, 0.0);
		}
		if (tk == 0 || tk == 1) {
			tgt.f[i * 3u] = tg.x; tgt.f[i * 3u + 1u] = tg.y; tgt.f[i * 3u + 2u] = tg.z;
		}
		// (stopped for one it's met; then a while before it'll stop again)
		if (pause > 0.0) {
			pause -= dt;
			if (pause <= 0.0) pause = -mix(2.0, 5.0, rnd(i, t, 12u));
		} else if (pause < 0.0) {
			pause = min(pause + dt, 0.0);
		}
		mind.f[mb] = wait;
		mind.f[mb + 8u] = float(ph);
		feedk.f[i] = fk;
	}
	vec3 to = tg - p0;
	to.y = 0.0;
	float d = length(to);
	float want = speed;
	if (d > 0.0012) { // (a wandering line: weaving a little either side of the way)
		float wiggle = (sin(t * 2.3 + sd * 40.0) * 0.35 + sin(t * 5.1 + sd * 13.0) * 0.15) * clamp(d / 0.03, 0.0, 1.0);
		float ang = atan(-to.x, -to.z) + wiggle;
		float turn = wrap_pi(ang - yaw);
		yaw += clamp(turn, -6.0 * dt, 6.0 * dt);
		float own = pace.f[i] > 0.0 ? pace.f[i] : top * (0.75 + 0.5 * sd);
		want = min(own, d * 5.0) * clamp(1.0 - abs(turn) / 1.3, 0.0, 1.0);
	} else {
		want = 0.0;
		if (task.i[i] == 1) { // (at the food: facing it)
			vec3 f = fd - p0;
			float turn = wrap_pi(atan(-f.x, -f.z) - yaw);
			yaw += clamp(turn, -4.0 * dt, 4.0 * dt);
		}
	}
	if (pause > 0.0) want = 0.0;
	float ease = pause > 0.0 ? 2.0 : 0.6;
	speed = speed + clamp(want - speed, -dt * ease, dt * ease);
	vec3 p = p0 + fwd * speed * dt;
	// kept apart from those near (round food hardly: they crowd round it)
	float crowd = (task.i[i] == 1 && length(p.xz - fd.xz) < 0.04) ? 0.08 : 1.0;
	ivec2 c = ivec2(floor(p.xz / cell));
	vec3 push = vec3(0.0);
	bool met = false;
	for (int dz = -1; dz <= 1; dz++)
	for (int dx = -1; dx <= 1; dx++) {
		uint h = bucket(c + ivec2(dx, dz));
		int m = min(gcount.c[h], int(SLOTS));
		for (int s = 0; s < m; s++) {
			uint j = uint(gslot.s[h * SLOTS + uint(s)]);
			if (j == i || partner.i[i] == int(j)) continue;
			vec3 off = p - P(j);
			off.y = 0.0;
			float l = length(off);
			if (l < cell && l > 1e-6) {
				push += off / l * min((cell - l) * min(dt * 6.0, 0.5), top * 0.4 * dt) * crowd;
				met = true;
			}
		}
	}
	if (pc.v.y == 1) { // (met another, walking: a stop, now and then, feeling each other over)
		if (met && pause == 0.0 && speed > 0.004 && task.i[i] != 4 && feedk.f[i] < 0.1 && rnd(i, t, 13u) < 1.2 * dt)
			pause = mix(0.3, 0.9, rnd(i, t, 14u));
		mind.f[mb + 7u] = pause;
	}
	p += push;
	p.y = ground(p.x, p.z);
	if (prm.hm.w >= 2.0) { // (off the baked ground: told, so it's baked again)
		vec2 g = (p.xz - prm.hm.xy) / prm.hm.z;
		if (any(lessThan(g, vec2(0.0))) || any(greaterThan(g, vec2(prm.hm.w - 1.0)))) atomicAdd(ctr.c[0], 1u);
	}
	pout.f[i * 3u] = p.x; pout.f[i * 3u + 1u] = p.y; pout.f[i * 3u + 2u] = p.z;
	yaw_.f[i] = yaw;
	spd.f[i] = speed;
	// its transform: turned to its way, tipped tail down laying; its pose
	float tilt = prm.b.z * layk.f[i];
	float cy = cos(yaw), sy = sin(yaw), ct = cos(tilt), st = sin(tilt);
	// Basis(UP, yaw) * Basis(RIGHT, tilt): columns
	vec3 bx = vec3(cy, 0.0, -sy);
	vec3 by = vec3(sy * st, ct, cy * st);
	vec3 bz = vec3(sy * ct, -st, cy * ct);
	vec3 o = p + vec3(0.0, prm.b.y, 0.0);
	uint base = i * 16u;
	float v[16] = float[16](bx.x, by.x, bz.x, o.x, bx.y, by.y, bz.y, o.y, bx.z, by.z, bz.z, o.z,
			clamp(speed / top, 0.0, 1.0), feedk.f[i] - layk.f[i], sd, fly.f[i] + ((pc.v.y == 1 && task.i[i] == 1 && int(mind.f[mb + 8u]) == 1) ? 64.0 : 0.0));
	for (int q = 0; q < 16; q++) outb.f[base + uint(q)] = v[q];
}
