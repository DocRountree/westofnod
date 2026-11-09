#[compute]
#version 450

// The krill's steering (Krill: a pool of them, every krill in a body of
// water), on the GPU: each one by its own neighbours alone (no swarm's
// middle, no swarm at all: the swarms are whatever clusters form, joining
// when they meet, splitting when they're broken up). Three passes over one
// pipeline (push constant x): 0 the neighbour grid cleared, 1 each krill
// put in its cell's bucket (a hashed grid: any size of water), 2 each krill
// steered (apart from those very near, the way its neighbours face, toward
// them; the water's slow currents; its own doing: feeding, its escape, a
// place sent to), moved, and its transform and pose written out for the
// near or the far mesh (by its distance from the camera), each counted.

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

const uint TABLE = 65536u; // grid buckets
const uint SLOTS = 24u; // krill a bucket holds (more: not seen by the rest)
const int MAX_SEEN = 40; // neighbours a krill looks at, at most

struct Krill {
	vec4 pos; // xyz, its size
	vec4 vel; // xyz, its own random 0..1
	vec4 head; // the way it faces (level), how far into feeding
	vec4 vs; // its velocity smoothed (its heading and pitch follow this)
	vec4 st; // its task (0 swarming, 1 feeding, 2 escaping), s left at it, s into its escape, s left going to its goal
	vec4 flee; // what it's escaping from
	vec4 goal; // where it's been sent
};

layout(set = 0, binding = 0, std430) restrict readonly buffer Params {
	vec4 tank_min; // the water: its bottom's corner
	vec4 tank_max; // and its surface's
	vec4 cam; // the camera (the pool's space), the far mesh from this far (m)
	vec4 sim; // dt, time, how many, cruise (m/s)
	vec4 esc; // an escape: from here, all within w (0: none)
	vec4 feed_ev; // feeding: all within w of here (0: none)
	vec4 goal_from; // sent: all within w of here
	vec4 goal_to; // to here, for w s
	vec4 tune; // escape speed, apart (m), neighbour reach (m), currents' strength
} prm;
layout(set = 0, binding = 1, std430) restrict readonly buffer StateIn { Krill k[]; } sin_;
layout(set = 0, binding = 2, std430) restrict writeonly buffer StateOut { Krill k[]; } sout;
layout(set = 0, binding = 3, std430) restrict buffer GridCount { int c[]; } gcount;
layout(set = 0, binding = 4, std430) restrict buffer GridSlots { int s[]; } gslot;
layout(set = 0, binding = 5, std430) restrict writeonly buffer OutNear { float f[]; } onear;
layout(set = 0, binding = 6, std430) restrict writeonly buffer OutFar { float f[]; } ofar;
layout(set = 0, binding = 7, std430) restrict buffer Counters { uint c[]; } ctr;

layout(push_constant, std430) uniform Push { ivec4 v; } pc;

uint bucket(ivec3 c) {
	uint h = (uint(c.x) * 73856093u) ^ (uint(c.y) * 19349663u) ^ (uint(c.z) * 83492791u);
	return h & (TABLE - 1u);
}

float rnd(uint i, float t) {
	uint h = i * 747796405u + uint(t * 997.0) * 2891336453u;
	h = ((h >> ((h >> 28u) + 4u)) ^ h) * 277803737u;
	return float((h >> 22u) ^ h) / 4294967295.0;
}

void write_out(uint slot, bool far_, mat3 b, vec3 o, vec4 custom) {
	uint base = slot * 16u;
	float v[16] = float[16](b[0].x, b[1].x, b[2].x, o.x, b[0].y, b[1].y, b[2].y, o.y, b[0].z, b[1].z, b[2].z, o.z,
			custom.x, custom.y, custom.z, custom.w);
	if (far_) {
		for (int q = 0; q < 16; q++) ofar.f[base + uint(q)] = v[q];
	} else {
		for (int q = 0; q < 16; q++) onear.f[base + uint(q)] = v[q];
	}
}

void main() {
	uint i = gl_GlobalInvocationID.x;
	int pass_ = pc.v.x;
	uint n = uint(prm.sim.z);
	float R = prm.tune.z;
	if (pass_ == 0) {
		if (i < TABLE) gcount.c[i] = 0;
		if (i == 0u) { ctr.c[0] = 0u; ctr.c[1] = 0u; }
		return;
	}
	if (i >= n) return;
	if (pass_ == 1) {
		uint h = bucket(ivec3(floor(sin_.k[i].pos.xyz / R)));
		int slot = atomicAdd(gcount.c[h], 1);
		if (slot < int(SLOTS)) gslot.s[h * SLOTS + uint(slot)] = int(i);
		return;
	}
	// pass 2: steering
	Krill me = sin_.k[i];
	vec3 p = me.pos.xyz;
	float sz = me.pos.w;
	vec3 v = me.vel.xyz;
	float seed = me.vel.w;
	vec3 hd = me.head.xyz;
	float feed_k = me.head.w;
	vec3 vs = me.vs.xyz;
	float task = me.st.x;
	float task_t = me.st.y;
	float flip_t = me.st.z;
	float goal_t = me.st.w;
	vec3 flee = me.flee.xyz;
	vec3 goal = me.goal.xyz;
	float dt = prm.sim.x;
	float T = prm.sim.y;
	float cruise = prm.sim.w;
	float esc_speed = prm.tune.x;
	float apart = prm.tune.y * sz;
	// what's been asked of those here (the sandbox's keys)
	if (prm.esc.w > 0.0 && distance(p, prm.esc.xyz) < prm.esc.w) {
		task = 2.0;
		task_t = 0.6 + 0.5 * rnd(i, T + 1.0);
		flip_t = 0.0;
		flee = prm.esc.xyz;
	}
	if (prm.feed_ev.w > 0.0 && distance(p, prm.feed_ev.xyz) < prm.feed_ev.w) {
		task = 1.0;
		task_t = 4.0 + 5.0 * rnd(i, T + 2.0);
	}
	if (prm.goal_from.w > 0.0 && distance(p, prm.goal_from.xyz) < prm.goal_from.w) {
		goal = prm.goal_to.xyz;
		goal_t = prm.goal_to.w;
	}
	// its neighbours: the 27 cells round its own
	vec3 sep = vec3(0.0);
	vec3 align = vec3(0.0);
	vec3 coh = vec3(0.0);
	float wsum = 0.0;
	int seen = 0;
	ivec3 c = ivec3(floor(p / R));
	for (int dz = -1; dz <= 1 && seen < MAX_SEEN; dz++)
	for (int dy = -1; dy <= 1 && seen < MAX_SEEN; dy++)
	for (int dx = -1; dx <= 1 && seen < MAX_SEEN; dx++) {
		uint h = bucket(c + ivec3(dx, dy, dz));
		int m = min(gcount.c[h], int(SLOTS));
		for (int s = 0; s < m && seen < MAX_SEEN; s++) {
			uint j = uint(gslot.s[h * SLOTS + uint(s)]);
			if (j == i) continue;
			vec3 q = sin_.k[j].pos.xyz;
			vec3 off = p - q;
			float d = length(off);
			if (d > R || d < 1e-6) continue;
			seen++;
			if (d < apart) sep += off / d * (apart - d) / apart;
			float w = (1.0 - d / R) * (1.0 - d / R);
			align += sin_.k[j].head.xyz * w;
			coh += q * w;
			wsum += w;
		}
	}
	vec3 acc = sep * 1.8;
	if (wsum > 1e-4) {
		vec3 a = align / wsum;
		acc += (a * cruise - v) * 1.0 * min(wsum, 1.0); // (the way they face)
		acc += (coh / wsum - p) * 1.4 * min(wsum, 1.0); // (toward them)
	}
	// the water's slow currents (a few metres across, shifting): what moves
	// the swarms about, and pulls them apart where it parts
	vec3 flow = vec3(sin(p.z * 0.9 + T * 0.07 + 1.3) + 0.5 * sin(p.y * 2.1 - T * 0.05),
			0.25 * sin(p.x * 1.1 + p.z * 0.7 + T * 0.04),
			cos(p.x * 0.8 - T * 0.06 + 0.4) + 0.5 * cos(p.y * 1.7 + T * 0.03));
	acc += (flow * cruise * 0.7 - v) * prm.tune.w * (wsum > 1e-4 ? 0.35 : 1.0);
	float want = cruise * (0.7 + 0.6 * seed);
	if (goal_t > 0.0) {
		goal_t -= dt;
		if (distance(goal, p) > 0.06) acc += normalize(goal - p) * 0.06;
	}
	task_t -= dt;
	if (task < 0.5) { // swarming: now and then off to feed
		if (task_t <= 0.0) {
			task_t = 6.0 + 14.0 * rnd(i, T + 3.0);
			if (rnd(i, T + 4.0) < 0.35) {
				task = 1.0;
				task_t = 4.0 + 5.0 * rnd(i, T + 5.0);
			}
		}
	} else if (task < 1.5) { // feeding: hanging nearly still, its basket working
		acc = acc * 0.5 - v * 1.5;
		want = 0.0;
		if (task_t <= 0.0) { task = 0.0; task_t = 4.0 + 16.0 * rnd(i, T + 6.0); }
	} else { // its escape: shot backward by each flick of its tail, away
		flip_t += dt;
		vec3 away = p - flee;
		away.y *= 0.3;
		away = length(away) > 1e-4 ? normalize(away) : -hd;
		float kick = max(sin(flip_t * 6.2831853 * 3.0), 0.0);
		acc = away * esc_speed * 9.0 * kick - v * 2.0;
		want = esc_speed;
		if (task_t <= 0.0) { task = 0.0; task_t = 4.0 + 16.0 * rnd(i, T + 7.0); }
	}
	feed_k = clamp(feed_k + (task > 0.5 && task < 1.5 ? 1.0 : -1.0) * dt * 1.5, 0.0, 1.0);
	// the walls, the bottom, the surface
	vec3 lo = prm.tank_min.xyz + vec3(0.03, 0.03, 0.03);
	vec3 hi = prm.tank_max.xyz - vec3(0.03, 0.02, 0.03);
	vec3 wall = max(lo - p, vec3(0.0)) - max(p - hi, vec3(0.0));
	acc += wall * 40.0;
	if (task < 0.5) acc.y -= v.y * 1.2; // (level, mostly)
	v += acc * dt;
	float spd = length(v);
	float top = task > 1.5 ? esc_speed : max(want * 1.6, 0.015);
	if (spd > top) v *= top / spd;
	vec3 np = clamp(p + v * dt, prm.tank_min.xyz, prm.tank_max.xyz - vec3(0.0, 0.006, 0.0));
	np.y = max(np.y, prm.tank_min.y + 0.006);
	// its pose: facing its way (escaping, the way it faced: it goes
	// backward), tipped head up feeding
	vs = mix(vs, v, 1.0 - exp(-4.0 * dt));
	bool escaping = task > 1.5;
	if (escaping) {
		vec3 away = vec3(np.x - flee.x, 0.0, np.z - flee.z);
		if (length(away) > 1e-4) hd = mix(hd, -normalize(away), 1.0 - exp(-8.0 * dt));
	} else if (length(vs) > 0.008) {
		vec3 flat_ = vec3(vs.x, 0.0, vs.z);
		if (length(flat_) > 1e-4) hd = mix(hd, normalize(flat_), 1.0 - exp(-3.0 * dt));
	}
	hd.y = 0.0;
	hd = length(hd) > 1e-4 ? normalize(hd) : vec3(0.0, 0.0, -1.0);
	float pitch = escaping ? 0.0 : clamp(atan(vs.y, max(length(vs.xz), 0.01)), -0.4, 0.4) * 0.6;
	pitch += 0.6 * feed_k;
	vec3 z = -hd;
	vec3 x = normalize(cross(vec3(0.0, 1.0, 0.0), z));
	vec3 y = cross(z, x);
	float cp = cos(pitch);
	float sp = sin(pitch);
	mat3 b = mat3(x, y * cp + z * sp, -y * sp + z * cp) * sz;
	float swim = clamp(length(vs) / (cruise * 2.0), 0.0, 1.0);
	float curl = escaping ? max(sin(flip_t * 6.2831853 * 3.0), 0.0) : 0.0;
	bool far_ = distance(np, prm.cam.xyz) > prm.cam.w;
	uint slot = atomicAdd(ctr.c[far_ ? 1 : 0], 1u);
	write_out(slot, far_, b, np, vec4(swim, feed_k, seed, curl));
	Krill o;
	o.pos = vec4(np, sz);
	o.vel = vec4(v, seed);
	o.head = vec4(hd, feed_k);
	o.vs = vec4(vs, 0.0);
	o.st = vec4(task, task_t, flip_t, goal_t);
	o.flee = vec4(flee, 0.0);
	o.goal = vec4(goal, 0.0);
	sout.k[i] = o;
}
