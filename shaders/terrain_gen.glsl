#[compute]
#version 450

// Terrain generation pipeline, run as a sequence of dispatches over one tile:
//
//   0  BASE      coarse grid: archipelago uplift field (islands + ridged mountains)
//   1  DIFFUSE   coarse grid: nonlinear hillslope diffusion, one explicit step per dispatch
//   2  ERODE     fine grid: bicubic sample of the diffused field + single-pass
//                erosion filter (after clayjohn's "Eroded Terrain Noise" shadertoy)
//   3  DEPOSIT   fine grid: alluvial back-fill up to a smooth sediment surface
//   4  OUTPUT    vertex grid (+1 ring): smoothed deposit, channels, coastal shaping
//
// Every stage only reads a bounded neighbourhood, and every grid is aligned to world
// coordinates, so a tile padded by the total stencil reach is bit-for-bit seamless
// with its neighbours. That is what makes the world infinite without global passes.

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer CoarseA { float v[]; } ca;
layout(set = 0, binding = 1, std430) restrict buffer CoarseB { float v[]; } cb;
layout(set = 0, binding = 2, std430) restrict buffer FineA { vec4 v[]; } fa;  // h, h_base, gully depth, river axis
layout(set = 0, binding = 3, std430) restrict buffer FineB { float v[]; } fb;
layout(set = 0, binding = 4, std430) restrict buffer FineC { float v[]; } fc;
layout(set = 0, binding = 5, std430) restrict buffer Out { vec4 v[]; } outb; // h, alluvium, gully, channel

layout(push_constant, std430) uniform Params {
	int stage;
	int flip;
	int coarse_n;
	int fine_n;
	ivec2 coarse_origin;   // coarse cell index of element 0
	vec2 fine_origin;      // world xz of fine element 0
	float spacing;         // fine spacing, metres
	float coarse_spacing;  // coarse spacing, metres
	int fine_pad;
	int out_n;
	int unused;
	uint seed;
	float min_wavelength;  // erosion octaves below this are skipped (LOD)
	float pad0;
} pc;

const float TAU = 6.28318530718;
const float CELL = 2600.0;          // archipelago cell size, metres
const float CRITICAL_SLOPE = 0.95;  // hillslope diffusion threshold slope

// ---------------------------------------------------------------- hashing / noise

uint pcg(uint v) {
	uint s = v * 747796405u + 2891336453u;
	uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
	return (w >> 22u) ^ w;
}

uint hash2i(ivec2 c, uint s) {
	return pcg(uint(c.x) * 1597334677u ^ pcg(uint(c.y) ^ (s * 3812015801u + pc.seed)));
}

float rnd(uint h) {
	return float(h & 0xFFFFFFu) / 16777216.0;
}

vec2 grad2(ivec2 c, uint s) {
	float a = rnd(hash2i(c, s)) * TAU;
	return vec2(cos(a), sin(a));
}

float gnoise(vec2 p, uint s) {
	vec2 i = floor(p);
	vec2 f = p - i;
	ivec2 ii = ivec2(i);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = dot(grad2(ii, s), f);
	float b = dot(grad2(ii + ivec2(1, 0), s), f - vec2(1.0, 0.0));
	float c = dot(grad2(ii + ivec2(0, 1), s), f - vec2(0.0, 1.0));
	float d = dot(grad2(ii + ivec2(1, 1), s), f - vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) * 1.414;
}

const mat2 ROT = mat2(0.8, -0.6, 0.6, 0.8);

float fbm(vec2 p, uint s, int octaves) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < octaves; i++) {
		sum += amp * gnoise(p, s + uint(i) * 7u);
		p = ROT * p * 2.03;
		amp *= 0.5;
	}
	return sum;
}

float ridged(vec2 p, uint s, int octaves) {
	float sum = 0.0;
	float amp = 0.55;
	float prev = 1.0;
	for (int i = 0; i < octaves; i++) {
		float n = 1.0 - abs(gnoise(p, s + uint(i) * 13u));
		n *= n;
		sum += n * amp * prev;
		prev = clamp(n * 1.6, 0.0, 1.0);
		p = ROT * p * 2.07;
		amp *= 0.48;
	}
	return sum;
}

// ---------------------------------------------------------------- stage 0: uplift field

// Smooth-max over jittered islands (each a few overlapping lobes) on a world-aligned
// cell grid. Returns ~1 at an island core, 0 at its coast, negative over open ocean.
float island_field(vec2 p, out float peak) {
	vec2 q = p + 280.0 * vec2(fbm(p / 1100.0, 11u, 3), fbm(p / 1100.0, 23u, 3));
	ivec2 cell = ivec2(floor(q / CELL));
	float sum = 0.0;
	float psum = 0.0;
	const float K = 7.0;
	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			ivec2 c = cell + ivec2(dx, dy);
			uint h = hash2i(c, 101u);
			bool origin = (c.x == 0 && c.y == 0);
			if (!origin && rnd(h) > 0.78) {
				continue; // empty ocean cell
			}
			vec2 j = vec2(rnd(pcg(h + 1u)), rnd(pcg(h + 2u))) - 0.5;
			vec2 center = (vec2(c) + 0.5 + j * 0.45) * CELL;
			float r = mix(380.0, 900.0, rnd(pcg(h + 3u)));
			float pk = mix(45.0, 150.0, rnd(pcg(h + 4u)));
			if (origin) {
				center = vec2(0.0);
				r = 760.0;
				pk = 110.0;
			}
			for (int l = 0; l < 4; l++) {
				uint hl = pcg(h + 17u * uint(l) + 5u);
				vec2 off = l == 0 ? vec2(0.0) : (vec2(rnd(hl), rnd(pcg(hl))) - 0.5) * r * 1.7;
				float lr = l == 0 ? r : r * mix(0.35, 0.8, rnd(pcg(hl + 9u)));
				float e = 1.0 - length(q - center - off) / lr;
				float w = exp(K * e);
				sum += w;
				psum += w * pk;
			}
		}
	}
	peak = sum > 1e-20 ? psum / sum : 60.0;
	return log(sum + 1e-12) / K;
}

float base_height(vec2 p) {
	float peak;
	float e = island_field(p, peak);
	e += 0.15 * fbm(p / 430.0, 31u, 4) + 0.035 * fbm(p / 140.0, 37u, 3);
	if (e < 0.0) {
		// Shelf, then slope down to the abyssal floor.
		float s = -e;
		return -(55.0 * s + 70.0 * smoothstep(0.12, 0.5, s));
	}
	float plains = 20.0 * e;
	float hills = 7.0 * (fbm(p / 260.0, 53u, 3) * 0.5 + 0.5) * smoothstep(0.02, 0.25, e);
	float mt = pow(smoothstep(0.2, 0.9, e), 1.4);
	float rid = ridged(p / 950.0, 41u, 5);
	return plains + hills + peak * mt * (0.25 + 0.95 * rid);
}

// ---------------------------------------------------------------- stage 1: diffusion

float coarse_at(int x, int y) {
	x = clamp(x, 0, pc.coarse_n - 1);
	y = clamp(y, 0, pc.coarse_n - 1);
	int i = y * pc.coarse_n + x;
	return pc.flip == 0 ? ca.v[i] : cb.v[i];
}

// ---------------------------------------------------------------- stage 2: erosion

float final_coarse(int x, int y) {
	x = clamp(x, 0, pc.coarse_n - 1);
	y = clamp(y, 0, pc.coarse_n - 1);
	return ca.v[y * pc.coarse_n + x]; // diffusion runs an even number of steps
}

vec4 catmull(float t) {
	float t2 = t * t;
	float t3 = t2 * t;
	return vec4(-0.5 * t3 + t2 - 0.5 * t,
			1.5 * t3 - 2.5 * t2 + 1.0,
			-1.5 * t3 + 2.0 * t2 + 0.5 * t,
			0.5 * t3 - 0.5 * t2);
}

float sample_diffused(vec2 p) {
	vec2 u = p / pc.coarse_spacing - vec2(pc.coarse_origin);
	vec2 i = floor(u);
	vec2 f = u - i;
	ivec2 b = ivec2(i);
	vec4 wx = catmull(f.x);
	vec4 wy = catmull(f.y);
	float r = 0.0;
	for (int y = 0; y < 4; y++) {
		float row = 0.0;
		for (int x = 0; x < 4; x++) {
			row += wx[x] * final_coarse(b.x + x - 1, b.y + y - 1);
		}
		r += wy[y] * row;
	}
	return r;
}

// One octave of the erosion filter: a sum of gaussian-windowed cosines (gabor-like
// splats) on a jittered grid, each oscillating along `dir` (perpendicular to the
// downhill direction), so their troughs line up into gullies running downhill.
// Returns (value, d/dx, d/dy) in octave space.
vec3 erosion_octave(vec2 p, vec2 dir, uint s) {
	vec2 ip = floor(p);
	vec2 fp = p - ip;
	vec3 va = vec3(0.0);
	float wt = 0.0;
	for (int i = -2; i <= 1; i++) {
		for (int j = -2; j <= 1; j++) {
			vec2 o = vec2(i, j);
			ivec2 c = ivec2(ip - o);
			uint h = hash2i(c, s);
			vec2 jit = (vec2(rnd(h), rnd(pcg(h))) - 0.5);
			vec2 pp = fp + o - jit;
			float w = exp(-dot(pp, pp) * 2.0);
			wt += w;
			float mag = dot(pp, dir) * TAU;
			va += vec3(cos(mag), -sin(mag) * TAU * dir) * w;
		}
	}
	return va / wt;
}

// Same splat layout as erosion_octave but returns the summed phasor (cos, sin), so the
// stripe phase is well defined everywhere ("phasor noise"). Used to place river axes.
vec2 phasor_octave(vec2 p, vec2 dir, uint s) {
	vec2 ip = floor(p);
	vec2 fp = p - ip;
	vec2 va = vec2(0.0);
	for (int i = -2; i <= 1; i++) {
		for (int j = -2; j <= 1; j++) {
			vec2 o = vec2(i, j);
			uint h = hash2i(ivec2(ip - o), s);
			vec2 pp = fp + o - (vec2(rnd(h), rnd(pcg(h))) - 0.5);
			float w = exp(-dot(pp, pp) * 2.0);
			float mag = dot(pp, dir) * TAU;
			va += vec2(cos(mag), sin(mag)) * w;
		}
	}
	return va;
}

// ---------------------------------------------------------------- fine grid helpers

int fidx(ivec2 c) {
	c = clamp(c, ivec2(0), ivec2(pc.fine_n - 1));
	return c.y * pc.fine_n + c.x;
}

float lowland_of(float hb) {
	return 1.0 - smoothstep(10.0, 42.0, hb);
}

void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);

	if (pc.stage == 0) {
		if (id.x >= pc.coarse_n || id.y >= pc.coarse_n) return;
		vec2 p = vec2(pc.coarse_origin + id) * pc.coarse_spacing;
		ca.v[id.y * pc.coarse_n + id.x] = base_height(p);
		return;
	}

	if (pc.stage == 1) {
		if (id.x >= pc.coarse_n || id.y >= pc.coarse_n) return;
		float h = coarse_at(id.x, id.y);
		float hl = coarse_at(id.x - 1, id.y);
		float hr = coarse_at(id.x + 1, id.y);
		float hd = coarse_at(id.x, id.y - 1);
		float hu = coarse_at(id.x, id.y + 1);
		float lap = hl + hr + hd + hu - 4.0 * h;
		vec2 g = vec2(hr - hl, hu - hd) / (2.0 * pc.coarse_spacing);
		// Nonlinear (Roering-style) hillslope diffusion: transport grows sharply as the
		// slope nears the critical angle, giving convex crests and planar steep flanks.
		// Below sea level the seabed is smoothed faster (marine reworking).
		float s2 = min(dot(g, g) / (CRITICAL_SLOPE * CRITICAL_SLOPE), 0.6);
		float D = h < 0.0 ? 0.22 : min(0.09 / (1.0 - s2), 0.23);
		float r = h + D * lap;
		int i = id.y * pc.coarse_n + id.x;
		if (pc.flip == 0) cb.v[i] = r; else ca.v[i] = r;
		return;
	}

	if (pc.stage == 2) {
		if (id.x >= pc.fine_n || id.y >= pc.fine_n) return;
		vec2 p = pc.fine_origin + vec2(id) * pc.spacing;
		float hb = sample_diffused(p);
		const float E = 1.5;
		vec2 g = vec2(sample_diffused(p + vec2(E, 0.0)) - sample_diffused(p - vec2(E, 0.0)),
				sample_diffused(p + vec2(0.0, E)) - sample_diffused(p - vec2(0.0, E))) / (2.0 * E);
		float slope = length(g);
		float low = lowland_of(hb);

		// Uplands get full-strength gullies; lowlands get faint channels so drainage
		// carries on across the plains to the sea (they are mostly buried in stage 7).
		float upland = smoothstep(3.0, 30.0, hb) * smoothstep(0.02, 0.30, slope);
		float plain = 0.2 * smoothstep(-1.0, 2.0, hb) * smoothstep(0.004, 0.03, slope);
		float strength = max(upland, plain * low);

		// Meander: wiggle the filter's sample position, more so on gentle lowlands.
		vec2 warp = vec2(gnoise(p / 95.0, 71u), gnoise(p / 95.0 + 17.3, 73u)) * mix(3.0, 20.0, low);
		vec2 pe = p + warp;

		float eh = 0.0;
		vec2 eg = vec2(0.0);
		float a = 14.0;
		float wl = 80.0;
		for (int k = 0; k < 6; k++) {
			if (wl < pc.min_wavelength) break;
			// Branching: bend this octave's direction by the gullies already carved.
			vec2 gg = g + eg * 0.6;
			float L = length(gg);
			vec2 dir = L > 1e-5 ? vec2(gg.y, -gg.x) / L : vec2(0.0);
			vec3 v = erosion_octave(pe / wl, dir, 200u + uint(k));
			eh += a * (v.x - 1.0) * 0.5;   // carve only: crests stay, troughs cut down
			eg += a * 0.5 * v.yz / wl;
			a *= 0.46;
			wl *= 0.5;
		}
		eh *= strength;

		// Lowland rivers: one wide-spaced, strongly meandering phasor octave. Its trough
		// axes (phase = pi) become fixed-width channels cut into the floodplain (stage 4).
		float river = 0.0;
		if (low > 0.0 && slope > 0.002) {
			const float RIVER_WL = 260.0;
			const float RIVER_HALF_WIDTH = 4.0;
			vec2 rw = vec2(gnoise(p / 170.0, 75u), gnoise(p / 170.0 + 5.1, 77u)) * 45.0;
			vec2 dir = vec2(g.y, -g.x) / slope;
			vec2 ph = phasor_octave((p + warp + rw) / RIVER_WL, dir, 199u);
			float phase = atan(ph.y, ph.x);
			float dist = (3.14159265 - abs(phase)) / TAU * RIVER_WL;
			river = (1.0 - smoothstep(RIVER_HALF_WIDTH * 0.4, RIVER_HALF_WIDTH, dist))
					* smoothstep(0.15, 0.4, length(ph))
					* low * smoothstep(-3.0, 1.0, hb) * smoothstep(0.002, 0.012, slope);
		}

		float detail = 0.0;
		if (pc.min_wavelength < 20.0) {
			detail = 0.7 * fbm(p / 22.0, 61u, 2) * smoothstep(-2.0, 4.0, hb) * (1.0 - 0.7 * low);
		}
		fa.v[fidx(id)] = vec4(hb + eh + detail, hb, -eh, river);
		return;
	}

	if (pc.stage == 3) {
		if (id.x >= pc.fine_n || id.y >= pc.fine_n) return;
		int i = fidx(id);
		vec4 A = fa.v[i];
		vec2 p = pc.fine_origin + vec2(id) * pc.spacing;
		// Sediment surface: rivers leaving the uplands drop their load once the
		// gradient eases, back-filling every valley up to a smooth surface that
		// follows the diffused base topography. Low down that surface sits just
		// below the base (flat floodplains and coastal plain that hills poke out of);
		// higher up it sits deeper, so only valley bottoms are filled (flat-floored
		// valleys, and fans/aprons where gullies open onto the plain).
		float allowance = mix(0.4, 12.0, 1.0 - lowland_of(A.y));
		float S = A.y - allowance + 0.25 * gnoise(p / 60.0, 91u);
		float k = 0.8;
		float hh = max(k - abs(A.x - S), 0.0) / k;
		float hf = max(A.x, S) + hh * hh * k * 0.25;
		float sub = smoothstep(-4.0, 0.5, A.y);
		fb.v[i] = (hf - A.x) * sub;
		fc.v[i] = A.w * 1.4;
		return;
	}

	if (pc.stage == 4) {
		if (id.x >= pc.out_n || id.y >= pc.out_n) return;
		ivec2 f = id + ivec2(pc.fine_pad - 1);
		float dep = 0.0;
		for (int y = -2; y <= 2; y++) {
			for (int x = -2; x <= 2; x++) {
				dep += fb.v[fidx(f + ivec2(x, y))];
			}
		}
		dep /= 25.0;
		float channel = 0.0;
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				channel += fc.v[fidx(f + ivec2(x, y))];
			}
		}
		channel /= 9.0;
		vec4 A = fa.v[fidx(f)];
		float h = A.x + dep - channel;
		// Beaches: flatten the profile around sea level.
		h -= 0.35 * h * exp(-h * h * 0.25);
		outb.v[id.y * pc.out_n + id.x] = vec4(h, dep, A.z, channel);
		return;
	}
}
