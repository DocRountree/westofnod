#[compute]
#version 450

// Hydrology-first terrain. The CPU plans each island's drainage (IslandPlanner):
// coastline lobes, a river network grown inland from the coast, lakes, meanders
// and oxbows. This shader builds the land around those rivers, then erodes it.
//
//   stage 0  BASE   (fine grid) every river/valley segment defines a cross-section:
//                   channel, floodplain, then valley sides rising with the local
//                   side slope. The terrain is the lowest of these (so ridges
//                   form where neighbouring valleys meet), plus hills/mountains
//                   that fade in away from the valley floors, clipped by the
//                   coastal profile. Lakes get a sill and a basin; channels are
//                   cut last so every river stays connected to its lake or sea.
//   stage 1  ERODE  (vertex grid + 1 ring) single-pass erosion filter after
//                   clayjohn's "Eroded Terrain Noise", faded out near water.
//
// Primitive coordinates are relative to the tile origin. Every pixel uses only
// primitives within `influence` metres, and each tile is sent all primitives in
// that reach, so neighbouring tiles agree exactly: the world is seamless.

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer Segs { vec4 v[]; } segs;
layout(set = 0, binding = 1, std430) restrict readonly buffer Lakes { vec4 v[]; } lakes;
layout(set = 0, binding = 2, std430) restrict readonly buffer Lobes { vec4 v[]; } lobes;
layout(set = 0, binding = 3, std430) restrict readonly buffer Peaks { vec4 v[]; } peaks;
layout(set = 0, binding = 4, std430) restrict buffer FineA { vec4 v[]; } fa; // h, valley dist, water level, water kind
layout(set = 0, binding = 5, std430) restrict buffer FineB { vec4 v[]; } fb; // mountain, alluvium, channel cut, lake dist
layout(set = 0, binding = 6, std430) restrict buffer Out { vec4 v[]; } outb; // 2 per vertex

layout(push_constant, std430) uniform Params {
	int stage;
	int n_seg;
	int n_lake;
	int n_lobe;
	int n_peak;
	int fine_n;
	int out_n;
	int fine_pad;
	vec2 origin;          // world xz of vertex 0 (for noise only)
	float spacing;
	float min_wavelength; // erosion octaves below this are skipped (LOD)
	uint seed;
	float influence;
	float grad_r;         // erosion gradient stencil radius, fine cells
	float pad1;
} pc;

const float TAU = 6.28318530718;

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
		float g = gnoise(p, s + uint(i) * 13u);
		float n = 1.0 - sqrt(g * g + 0.004); // smooth |g|: no crease for the erosion to trip on
		n *= n;
		sum += n * amp * prev;
		prev = clamp(n * 1.6, 0.0, 1.0);
		p = ROT * p * 2.07;
		amp *= 0.48;
	}
	return sum;
}

// ---------------------------------------------------------------- island primitives

float lobe_f(int l, int i) {
	return lobes.v[l * 6 + (i >> 2)][i & 3];
}

// Mirrors IslandPlanner.coast(): metres inland of the coastline (negative at sea).
float coast(vec2 q) {
	float best = -1e5;
	for (int l = 0; l < pc.n_lobe; l++) {
		vec2 d = q - vec2(lobe_f(l, 0), lobe_f(l, 1));
		float R = lobe_f(l, 2);
		float len = length(d);
		if (R * 1.6 - len <= best) continue;
		float th = atan(d.y, d.x);
		float f = 1.0;
		for (int k = 0; k < 9; k++) {
			f += lobe_f(l, 4 + k) * cos(float(k + 2) * th + lobe_f(l, 13 + k));
		}
		best = max(best, R * max(f, 0.3) - len);
	}
	return best;
}

// Mirrors IslandPlanner.mountain().
float mountain(vec2 q) {
	float m = 0.0;
	for (int i = 0; i < pc.n_peak; i++) {
		vec4 pk = peaks.v[i];
		vec2 d = q - pk.xy;
		float t = 1.0 - min(dot(d, d) / (pk.z * pk.z), 1.0);
		m = max(m, pk.w * t * t);
	}
	return m;
}

// Deep sea saturates, so islands outside a tile's search radius never matter.
float seabed(float c) {
	float s = min(-c, 450.0);
	return -(0.06 * s + 90.0 * smoothstep(60.0, 450.0, s));
}

float soft(float x, float k) {
	return 0.5 * (x + sqrt(x * x + k * k));
}

// ---------------------------------------------------------------- erosion filter

// One octave: gaussian-windowed cosines on a jittered grid oscillating along `dir`
// (perpendicular to downhill), so troughs line up as gullies running downhill.
// Returns (value, d/dx, d/dy) in octave space.
vec3 erosion_octave(vec2 p, vec2 dir, uint s) {
	vec2 ip = floor(p);
	vec2 fp = p - ip;
	vec3 va = vec3(0.0);
	float wt = 0.0;
	for (int i = -2; i <= 1; i++) {
		for (int j = -2; j <= 1; j++) {
			vec2 o = vec2(i, j);
			uint h = hash2i(ivec2(ip - o), s);
			vec2 pp = fp + o - (vec2(rnd(h), rnd(pcg(h))) - 0.5);
			float w = exp(-dot(pp, pp) * 2.0);
			wt += w;
			float mag = dot(pp, dir) * TAU;
			va += vec3(cos(mag), -sin(mag) * TAU * dir) * w;
		}
	}
	return va / wt;
}

// Cross-section of one river/valley segment at q (without its channel): the
// water/valley-floor level, a floodplain, then valley sides rising with the
// segment's side slope. Also returns the segment's local attributes.
float valley(int i, vec2 q, out float d, out float e, out float w, out float F, out int kind, out int chain) {
	vec4 A = segs.v[i * 3];
	vec2 ab = A.zw - A.xy;
	vec2 aq = q - A.xy;
	float t = clamp(dot(aq, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
	d = length(aq - ab * t);
	vec4 B = segs.v[i * 3 + 1];
	vec4 S = segs.v[i * 3 + 2];
	e = mix(B.x, B.y, t);
	w = mix(B.z, B.w, t);
	F = mix(S.x, S.y, t);
	int packed = int(S.w + 0.5);
	kind = packed & 3;
	chain = packed >> 2;
	float k = 4.0 + 0.25 * F;
	float rise = S.z * max(soft(d - F, k) - soft(-F, k), 0.0);
	// Fade a profile out well before the influence cutoff so the minimum never
	// jumps when a segment drops out of reach.
	float far_d = max(d - 0.55 * pc.influence, 0.0);
	rise += 0.015 * far_d * far_d;
	if (kind == 0) {
		return e + 0.01 * d + rise;
	}
	return e + 0.4 + 0.012 * max(d - 0.5 * w, 0.0) + rise;
}

int fidx(ivec2 c) {
	c = clamp(c, ivec2(0), ivec2(pc.fine_n - 1));
	return c.y * pc.fine_n + c.x;
}

// Base-height gradient by central differences r cells wide.
vec2 grad_at(ivec2 f, int r) {
	return vec2(fa.v[fidx(f + ivec2(r, 0))].x - fa.v[fidx(f - ivec2(r, 0))].x,
			fa.v[fidx(f + ivec2(0, r))].x - fa.v[fidx(f - ivec2(0, r))].x) / (2.0 * pc.spacing * float(r));
}

void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);

	if (pc.stage == 0) {
		if (id.x >= pc.fine_n || id.y >= pc.fine_n) return;
		vec2 q = (vec2(id) - float(pc.fine_pad)) * pc.spacing;
		vec2 p = pc.origin + q;

		// ---- rivers and valleys
		float V1 = 1e9;      // lowest valley profile (no channels)
		int c1 = -1;         // its river chain
		float V2 = 1e9;      // lowest profile of any other chain
		float C = 1e9;       // channel beds and banks
		float dv = 1e9;      // distance beyond the nearest valley floor
		float alluv = 0.0;
		float wd = 1e9;      // distance to nearest open water edge
		float we = -1e9;     // its water level
		for (int i = 0; i < pc.n_seg; i++) {
			float d, e, w, F;
			int kind, chain;
			float v = valley(i, q, d, e, w, F, kind, chain);
			if (d > pc.influence) continue;
			if (v < V1) {
				if (chain != c1) {
					V2 = V1;
					c1 = chain;
				}
				V1 = v;
			} else if (chain != c1 && v < V2) {
				V2 = v;
			}
			dv = min(dv, d - F);
			if (kind == 0) continue;
			float hw = 0.5 * w;
			float bankw = 1.5 + 0.25 * w;
			if (d < hw + bankw) {
				float depth = min(0.5 + 0.12 * w, 3.5) * (kind == 2 ? 0.7 : 1.0);
				float r = d / hw;
				float bed = d < hw ? e - depth * (1.0 - r * r) : e + 0.4 * smoothstep(hw, hw + bankw, d);
				C = min(C, bed);
			}
			if (d - hw < wd) {
				wd = d - hw;
				we = e;
			}
			alluv = max(alluv, (1.0 - smoothstep(0.75 * F, F, d)) * smoothstep(4.0, 16.0, F - hw));
		}
		// Where two different rivers' valleys meet, the hard minimum leaves a sharp
		// crease, and the erosion filter (steered by the gradient) would flip across
		// it. Blend the two lowest distinct valleys; the blend width grows with
		// height above the valley floor, so floodplains and channels stay exact.
		float V = V1;
		if (V2 < 1e8) {
			float ks = clamp(0.12 * dv, 0.0, 10.0);
			if (ks > 0.01) {
				float hb = max(ks - abs(V1 - V2), 0.0) / ks;
				V = min(V1, V2) - hb * hb * ks * 0.25;
			}
		}

		// ---- hills and mountains between the valleys
		float m = mountain(q);
		float c = coast(q);
		c += 12.0 * gnoise(p / 90.0, 5u) * (1.0 - smoothstep(0.0, 250.0, abs(c)));
		float inland = smoothstep(0.0, 900.0, c);
		float amp = 3.0 + 7.0 * inland + 75.0 * m;
		float hn = 0.6 * ridged(p / 380.0, 41u, 4) + 0.4 * (fbm(p / 210.0, 53u, 3) * 0.5 + 0.5);
		// A low coastal berm keeps the shore above the swell, except on floodplains,
		// where rivers reach the sea at grade.
		float h = V + amp * hn * smoothstep(0.0, 70.0 + 50.0 * m, dv)
				+ 1.6 * smoothstep(0.0, 90.0, c) * smoothstep(0.0, 40.0, dv);

		// ---- coast: beaches, cliffs where mountains or rough coast meet the sea
		float cliff = smoothstep(0.55, 0.8, fbm(p / 700.0, 81u, 2) * 0.5 + 0.5);
		float beach = mix(0.03, 0.1, cliff) + 0.6 * m;
		float land = c >= 0.0 ? beach * c : seabed(c);
		float kc = 4.0;
		float hc0 = max(kc - abs(h - land), 0.0) / kc;
		h = min(h, land) - hc0 * hc0 * kc * 0.25;

		// ---- lakes: sill around the shore, then channels, then the basin
		float dL = 1e9;
		float lev = 0.0;
		float sill = -1e9;
		float bowl = 1e9;
		for (int j = 0; j < pc.n_lake; j++) {
			vec4 L0 = lakes.v[j * 2];
			vec4 L1 = lakes.v[j * 2 + 1];
			vec2 d = q - L0.xy;
			float th = atan(d.y, d.x);
			float r = L0.z * (1.0 + 0.15 * sin(3.0 * th + L1.y) + 0.08 * sin(5.0 * th + 2.0 * L1.y));
			float dd = length(d) - r;
			sill = max(sill, L0.w + 0.6 - 0.25 * max(dd - 12.0, 0.0));
			// Shore and basin: rises gently above the waterline, shelves down below it.
			float shore = dd >= 0.0 ? L0.w + 0.2 * dd + 0.03 * dd * dd
					: L0.w - 0.3 * smoothstep(0.0, 3.0, -dd) - L1.x * smoothstep(0.0, L0.z * 0.5, -dd);
			bowl = min(bowl, shore);
			if (dd < dL) {
				dL = dd;
				lev = L0.w;
			}
		}
		h = max(h, sill);
		float hc = min(h, C);
		float cut = h - hc;
		h = hc;
		h = min(h, bowl);

		// Water level: the nearest lake or channel's, carried a few metres past the
		// shore so the water sheet stays flat and the banks hide its edge.
		float wlevel = h - 3.0;
		float wkind = 0.0;
		if (dL < 12.0) {
			wlevel = lev;
			wkind = dL < 1.5 ? 2.0 : 0.0;
		} else if (wd < 12.0 && we > 0.15) {
			wlevel = we - 0.1;
			wkind = wd < 2.0 ? 1.0 : 0.0;
		}
		int i = fidx(id);
		fa.v[i] = vec4(h, dv, wlevel, wkind);
		fb.v[i] = vec4(m, alluv, cut, dL);
		return;
	}

	if (pc.stage == 1) {
		if (id.x >= pc.out_n || id.y >= pc.out_n) return;
		ivec2 f = id + ivec2(pc.fine_pad - 1);
		vec4 A = fa.v[fidx(f)];
		vec4 B = fb.v[fidx(f)];
		vec2 p = pc.origin + (vec2(id) - 1.0) * pc.spacing;
		float h = A.x;
		// A wide stencil: the base has creases where valley profiles meet, and a
		// one-cell gradient would flip the gully direction abruptly across them.
		int r = int(pc.grad_r);
		vec2 g = grad_at(f, r);
		float slope = length(g);
		float m = B.x;

		// Erosion carves the slopes between valleys; valley floors, lakes,
		// beaches and the sea are left to the hydrology.
		float strength = smoothstep(4.0, 45.0, A.y) * smoothstep(0.5, 6.0, h)
				* smoothstep(0.03, 0.3, slope) * smoothstep(5.0, 30.0, B.w);
		float eh = 0.0;
		if (strength > 0.0) {
			vec2 eg = vec2(0.0);
			// Scale amplitude by strength up front so the branching term (the gullies'
			// own gradient) stays in proportion to the slope it bends.
			float a = (4.0 + 9.0 * m) * strength;
			float wl = 80.0;
			for (int k = 0; k < 6; k++) {
				if (wl < pc.min_wavelength) break;
				// Branching: bend each octave by the gullies already carved.
				vec2 gg = g + eg * 0.6;
				float L = length(gg);
				vec2 dir = L > 1e-5 ? vec2(gg.y, -gg.x) / L : vec2(0.0);
				vec3 v = erosion_octave(p / wl, dir, 200u + uint(k));
				eh += a * (v.x - 1.0) * 0.5;
				eg += a * 0.5 * v.yz / wl;
				a *= 0.46;
				wl *= 0.5;
			}
		}
		float detail = 0.0;
		if (pc.min_wavelength < 20.0) {
			detail = 0.5 * fbm(p / 22.0, 61u, 2) * smoothstep(1.0, 8.0, A.y) * smoothstep(0.5, 3.0, h);
		}
		int o = (id.y * pc.out_n + id.x) * 2;
		outb.v[o] = vec4(h + eh + detail, B.y, -eh, B.z);
		outb.v[o + 1] = vec4(A.z, A.w, 0.0, 0.0);
		return;
	}
}
