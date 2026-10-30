#[compute]
#version 450

// Fine terrain for one tile, from the simulated islands (Island) and their
// rivers. One pass, one invocation per output vertex (the tile's vertex grid
// plus a one-vertex ring for seamless normals):
//
//   1. Large scale: the island's eroded heightfield, bicubic (with its
//      analytic gradient), plus the sea floor below the coast.
//   2. Sub-grid erosion: a single-pass erosion filter after clayjohn's "Eroded
//      Terrain Noise": octaves of gaussian-windowed cosines oriented across the
//      slope, so troughs line up into gullies running downhill; each octave is
//      bent by the gullies already carved, which makes them branch. Gully depth
//      scales with slope x wavelength. Faded out on valley floors, lakes, beaches.
//   3. Valley floors and channels from the river segments: floodplains (the whole
//      meander belt on lowland rivers) blending into the hillsides over a wide
//      apron, then channels, oxbow lakes and meander scars cut into them.
//   4. Water: lake level from the grid, river level from the nearest channel.
//
// All coordinates are relative to the tile origin. A segment only shapes the
// ground within its floor half-width + BANK_REACH, and its influence has faded
// to nothing before that, so dropping it there changes nothing: tiles agree.

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer Grid { vec4 v[]; } grid; // h, sd, lake level, area
layout(set = 0, binding = 1, std430) restrict readonly buffer Isl { vec4 v[]; } isl;   // 2 per island
layout(set = 0, binding = 2, std430) restrict readonly buffer Segs { vec4 v[]; } segs; // 3 per segment
layout(set = 0, binding = 3, std430) restrict writeonly buffer Out { vec4 v[]; } outb; // 2 per vertex

layout(push_constant, std430) uniform Params {
	int n_isl;
	int n_seg;
	int out_n;
	uint seed;
	vec2 origin;          // world xz of vertex 0 (noise only)
	float spacing;
	float min_wavelength; // erosion octaves shorter than this are skipped (LOD)
	float bank_reach;
	float pad0;
	float pad1;
	float pad2;
} pc;

const float TAU = 6.28318530718;
const float NO_LAKE = -1.0e4;
const float SHELF_SAT = 650.0;
const float OCEAN_FLOOR = -(0.05 * SHELF_SAT + 70.0 + 1.2);

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

float gnoise(vec2 p, uint s) {
	vec2 i = floor(p);
	vec2 f = p - i;
	ivec2 ii = ivec2(i);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a0 = rnd(hash2i(ii, s)) * TAU;
	float a1 = rnd(hash2i(ii + ivec2(1, 0), s)) * TAU;
	float a2 = rnd(hash2i(ii + ivec2(0, 1), s)) * TAU;
	float a3 = rnd(hash2i(ii + ivec2(1, 1), s)) * TAU;
	float a = dot(vec2(cos(a0), sin(a0)), f);
	float b = dot(vec2(cos(a1), sin(a1)), f - vec2(1.0, 0.0));
	float c = dot(vec2(cos(a2), sin(a2)), f - vec2(0.0, 1.0));
	float d = dot(vec2(cos(a3), sin(a3)), f - vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) * 1.414;
}

float fbm(vec2 p, uint s, int octaves) {
	const mat2 ROT = mat2(0.8, -0.6, 0.6, 0.8);
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < octaves; i++) {
		sum += amp * gnoise(p, s + uint(i) * 7u);
		p = ROT * p * 2.03;
		amp *= 0.5;
	}
	return sum;
}

// ---------------------------------------------------------------- islands

vec4 cell(int base, int w, int hgt, int i, int j) {
	i = clamp(i, 0, w - 1);
	j = clamp(j, 0, hgt - 1);
	return grid.v[base + j * w + i];
}

vec4 cr(float t) {
	float t2 = t * t;
	float t3 = t2 * t;
	return vec4(-0.5 * t3 + t2 - 0.5 * t, 1.5 * t3 - 2.5 * t2 + 1.0,
			-1.5 * t3 + 2.0 * t2 + 0.5 * t, 0.5 * t3 - 0.5 * t2);
}

vec4 dcr(float t) {
	float t2 = t * t;
	return vec4(-1.5 * t2 + 2.0 * t - 0.5, 4.5 * t2 - 5.0 * t, -4.5 * t2 + 4.0 * t + 0.5, 1.5 * t2 - t);
}

// Sea floor below the coast, by signed coast distance: shelf, then a drop,
// flattening out at OCEAN_FLOOR well inside every island's domain.
float sea(float sd) {
	float s = min(max(-sd, 0.0), SHELF_SAT);
	return -(0.05 * s + 70.0 * smoothstep(30.0, 600.0, s) + 1.2 * smoothstep(0.0, 25.0, s));
}

struct Base {
	float h;      // terrain before rivers
	vec2 g;       // gradient of the island heightfield
	float sd;     // coast distance
	float lake;   // lake level (NO_LAKE if none)
	float lakef;  // 0..1 how much this point is inside a lake
	float area;   // drainage area, m^2
	float dx;     // island grid spacing
};

Base base_height(vec2 q, vec2 p) {
	Base b = Base(OCEAN_FLOOR, vec2(0.0), -1e4, NO_LAKE, 0.0, 0.0, 50.0);
	for (int k = 0; k < pc.n_isl; k++) {
		vec4 I0 = isl.v[k * 2];
		vec4 I1 = isl.v[k * 2 + 1];
		float dx = I0.z;
		vec2 gp = (q - I0.xy) / dx; // crop origin -> cell coordinates
		int w = int(I0.w);
		int hgt = int(I1.x);
		int base = int(I1.y);
		if (gp.x < 1.0 || gp.y < 1.0 || gp.x > float(w) - 2.0 || gp.y > float(hgt) - 2.0) continue;
		ivec2 c = ivec2(floor(gp));
		vec2 f = gp - vec2(c);
		vec4 wx = cr(f.x);
		vec4 wy = cr(f.y);
		vec4 dwx = dcr(f.x);
		vec4 dwy = dcr(f.y);
		float h = 0.0;
		vec2 g = vec2(0.0);
		for (int j = 0; j < 4; j++) {
			for (int i = 0; i < 4; i++) {
				float v = cell(base, w, hgt, c.x - 1 + i, c.y - 1 + j).x;
				h += v * wx[i] * wy[j];
				g += v * vec2(dwx[i] * wy[j], wx[i] * dwy[j]);
			}
		}
		g /= dx;
		vec4 c00 = cell(base, w, hgt, c.x, c.y);
		vec4 c10 = cell(base, w, hgt, c.x + 1, c.y);
		vec4 c01 = cell(base, w, hgt, c.x, c.y + 1);
		vec4 c11 = cell(base, w, hgt, c.x + 1, c.y + 1);
		float sd = mix(mix(c00.y, c10.y, f.x), mix(c01.y, c11.y, f.x), f.y);
		// Coastline detail finer than the grid.
		sd += (0.12 * dx + 4.0) * fbm(p / 45.0, 17u, 3) * (1.0 - smoothstep(0.0, 2.0 * dx, abs(sd)));
		float hi = max(h, 0.0) * smoothstep(-0.5 * dx, 0.0, sd) + sea(sd);
		if (hi > b.h) {
			b.h = hi;
			b.g = g;
			b.sd = sd;
			b.dx = dx;
			vec4 lk = vec4(c00.z, c10.z, c01.z, c11.z);
			vec4 ind = step(vec4(NO_LAKE + 1.0), lk);
			b.lakef = mix(mix(ind.x, ind.y, f.x), mix(ind.z, ind.w, f.x), f.y);
			b.lake = max(max(lk.x, lk.y), max(lk.z, lk.w));
			b.area = mix(mix(c00.w, c10.w, f.x), mix(c01.w, c11.w, f.x), f.y);
		}
	}
	return b;
}

// ---------------------------------------------------------------- erosion filter

// One octave in octave space: returns (value in [-1, 1], d/dx, d/dy).
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

// ---------------------------------------------------------------- main

void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);
	if (id.x >= pc.out_n || id.y >= pc.out_n) return;
	vec2 q = (vec2(id) - 1.0) * pc.spacing;
	vec2 p = pc.origin + q;

	Base B = base_height(q, p);

	// ---- valley floors and channels
	float floor_h = 1e9;   // ground with the floodplains flattened in
	float floor_w = 0.0;   // 0..1 how much this point is valley floor
	float chan_h = 1e9;    // lowest channel profile
	float dfl = 1e9;       // distance beyond the nearest floor edge
	float alluv = 0.0;     // on a floodplain
	float scar = 0.0;      // in an old meander scar
	float wd = 1e9;        // distance into the nearest channel's water (< 0 inside)
	float wlev = 0.0;
	float wkind = 0.0;
	vec2 flow = vec2(0.0);
	for (int i = 0; i < pc.n_seg; i++) {
		vec4 S0 = segs.v[i * 3];
		vec4 S1 = segs.v[i * 3 + 1];
		vec4 S2 = segs.v[i * 3 + 2];
		vec2 ab = S0.zw - S0.xy;
		vec2 aq = q - S0.xy;
		float t = clamp(dot(aq, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
		float d = length(aq - ab * t);
		float F = mix(S2.x, S2.y, t);
		float hw = mix(S1.z, S1.w, t);
		if (d > max(F, 1.6 * hw + 2.0) + pc.bank_reach) continue;
		float e = mix(S1.x, S1.y, t);
		int kind = int(S2.w + 0.5);
		float bankh = 0.3 + 0.12 * hw; // floodplain height above the water
		if (kind <= 1 && F > 0.0) {
			// The floor is flat out to F, then blends into the hillside over a
			// wide apron (no bluff edge). Never raises the ground.
			float x = d - F;
			float blend = min(0.5 * F + 20.0, 0.9 * pc.bank_reach);
			float wgt = 1.0 - smoothstep(0.0, blend, x);
			float lvl = e + bankh;
			float flat_h = min(B.h, lvl + 0.08 * max(B.h - lvl, 0.0));
			floor_h = min(floor_h, mix(B.h, flat_h, wgt));
			floor_w = max(floor_w, wgt);
			dfl = min(dfl, x);
			alluv = max(alluv, 1.0 - smoothstep(0.7 * F, F + 0.6 * blend, d));
		}
		if (kind >= 1 && hw > 0.0) {
			float depth = S2.z;
			float bw = 1.0 + 0.6 * hw;
			if (d < hw + bw) {
				float r = d / hw;
				float bed = d < hw ? e - depth * (1.0 - r * r) : e - 0.15 + (bankh + 0.15) * smoothstep(hw, hw + bw, d);
				chan_h = min(chan_h, bed);
			}
			if (kind == 3) {
				scar = max(scar, 1.0 - smoothstep(hw * 0.5, hw + bw, d));
			} else if (d - hw < wd) {
				wd = d - hw;
				wlev = e;
				wkind = kind == 1 ? 1.0 : 2.0;
				flow = kind == 1 ? normalize(ab) * clamp((S1.y - S1.x) / max(length(ab), 0.1) * 40.0, 0.15, 1.0) : vec2(0.0);
			}
		}
	}

	// ---- sub-grid erosion
	float slope = length(B.g);
	float inland = smoothstep(2.0, 30.0, B.sd);
	float strength = inland * smoothstep(0.02, 0.12, slope) * (1.0 - B.lakef)
			* smoothstep(0.0, 25.0 + 0.3 * B.dx, dfl);
	float eh = 0.0;
	if (strength > 0.0) {
		vec2 eg = vec2(0.0);
		float wl = 1.4 * B.dx;
		float a = 0.2 * wl * min(slope, 1.2) * strength;
		for (int k = 0; k < 7; k++) {
			if (wl < pc.min_wavelength) break;
			vec2 gg = B.g + eg * 0.7;
			float L = length(gg);
			vec2 dir = L > 1e-5 ? vec2(gg.y, -gg.x) / L : vec2(0.0);
			vec3 v = erosion_octave(p / wl, dir, 200u + uint(k));
			eh += a * (v.x - 1.0) * 0.5;
			eg += a * 0.5 * v.yz / wl;
			a *= 0.47;
			wl *= 0.5;
		}
	}
	float h = B.h + eh;
	if (pc.min_wavelength < 16.0) {
		h += 0.35 * fbm(p / 13.0, 61u, 2) * inland * smoothstep(0.0, 10.0, dfl) * (1.0 - B.lakef);
	}

	// ---- carve the hydrology in
	float before = h;
	// Floors flatten the large-scale ground; the erosion detail fades out on them.
	h = min(B.h, floor_h) + (h - B.h) * (1.0 - floor_w);
	float cut_floor = before - h;
	h = min(h, chan_h);
	float cut = before - h - cut_floor;
	h -= 0.6 * scar; // silted-up loops: shallow, damp hollows

	// ---- water
	float wlevel = h - 3.0;
	float kind_out = 0.0;
	if (B.lakef > 0.0 && B.lake > NO_LAKE + 1.0 && h < B.lake + 0.5 && (wd > 0.0 || B.lakef > 0.5)) {
		wlevel = B.lake;
		kind_out = h < B.lake ? 2.0 : 0.0;
		flow = vec2(0.0);
	} else if (wd < 2.5 && wlev > -0.5) {
		wlevel = wlev - 0.1;
		kind_out = wd < 0.8 ? wkind : 0.0;
	}
	int o = (id.y * pc.out_n + id.x) * 2;
	outb.v[o] = vec4(h, max(alluv, scar * 0.5), -eh, cut);
	outb.v[o + 1] = vec4(wlevel, kind_out, flow);
}
