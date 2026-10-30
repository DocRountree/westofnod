#[compute]
#version 450

// Final island maps at full resolution, one invocation per cell:
//   height, water level, material (RGBA8), water attributes (RGBA8).
//
// From the eroded heightfield (bicubic) and the rivers' history:
//  - Floodplains: the meander belt is flattened to just above the river and
//    blends into the hillsides over a wide apron.
//  - Scroll bars and swales: each recorded past course of a meandering river
//    sweeps the ground it crossed; the time it last did so gives low ridges and
//    damp swales parallel to the channel, generation after generation.
//  - Oxbow lakes: cutoff loops, filling with sediment as they age: open water,
//    then marsh, then a faint curved scar.
//  - Natural levees beside the active channel, then the channel itself.
//  - Lakes from the hydrology grid.
// Segments are bucketed on a coarse grid; each cell only reads its bucket.

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer Base { float v[]; } base;
layout(set = 0, binding = 1, std430) restrict readonly buffer Dep { float v[]; } dep;
layout(set = 0, binding = 2, std430) restrict readonly buffer Lakes { float v[]; } lakes;
layout(set = 0, binding = 3, std430) restrict readonly buffer Segs { vec4 v[]; } segs;
layout(set = 0, binding = 4, std430) restrict readonly buffer Buckets { ivec2 v[]; } buckets;
layout(set = 0, binding = 5, std430) restrict readonly buffer Index { int v[]; } index;
layout(set = 0, binding = 6, std430) restrict writeonly buffer OutH { float v[]; } out_h;
layout(set = 0, binding = 7, std430) restrict writeonly buffer OutW { float v[]; } out_w;
layout(set = 0, binding = 8, std430) restrict writeonly buffer OutM { uint v[]; } out_m;
layout(set = 0, binding = 9, std430) restrict writeonly buffer OutF { uint v[]; } out_f;

layout(push_constant, std430) uniform Params {
	int n1;        // base grid
	int nh;        // hydrology grid (lakes)
	int nf;        // output grid
	int nb;        // buckets per side
	vec2 origin;   // world xz of cell (0, 0) of every grid
	float domain;  // side of the square domain (m)
	float bucket;  // bucket size (m)
} pc;

const float NO_LAKE = -1.0e4;
const float TAU = 6.28318530718;
const float SCROLL_BANDS = 16.0;

float base_at(int i, int j) {
	i = clamp(i, 0, pc.n1 - 1);
	j = clamp(j, 0, pc.n1 - 1);
	return base.v[j * pc.n1 + i];
}

vec4 cr(float t) {
	float t2 = t * t;
	float t3 = t2 * t;
	return vec4(-0.5 * t3 + t2 - 0.5 * t, 1.5 * t3 - 2.5 * t2 + 1.0,
			-1.5 * t3 + 2.0 * t2 + 0.5 * t, 0.5 * t3 - 0.5 * t2);
}

float base_bicubic(vec2 g) {
	ivec2 c = ivec2(floor(g));
	vec2 f = g - vec2(c);
	vec4 wx = cr(f.x);
	vec4 wy = cr(f.y);
	float h = 0.0;
	for (int j = 0; j < 4; j++) {
		for (int i = 0; i < 4; i++) {
			h += base_at(c.x - 1 + i, c.y - 1 + j) * wx[i] * wy[j];
		}
	}
	return h;
}

float bilinear(int which, int n, vec2 g) {
	g = clamp(g, vec2(0.0), vec2(n - 1) - 0.001);
	ivec2 c = ivec2(floor(g));
	vec2 f = g - vec2(c);
	int k = c.y * n + c.x;
	float a, b, d, e;
	if (which == 0) {
		a = dep.v[k]; b = dep.v[k + 1]; d = dep.v[k + n]; e = dep.v[k + n + 1];
	} else {
		a = lakes.v[k]; b = lakes.v[k + 1]; d = lakes.v[k + n]; e = lakes.v[k + n + 1];
	}
	return mix(mix(a, b, f.x), mix(d, e, f.x), f.y);
}

uint pack4(vec4 v) {
	uvec4 u = uvec4(clamp(v, 0.0, 1.0) * 255.0 + 0.5);
	return u.x | (u.y << 8) | (u.z << 16) | (u.w << 24);
}

void main() {
	ivec2 id = ivec2(gl_GlobalInvocationID.xy);
	if (id.x >= pc.nf || id.y >= pc.nf) return;
	float cf = pc.domain / float(pc.nf - 1);
	vec2 q = vec2(id) * cf;          // domain-relative
	vec2 p = pc.origin + q;

	float h = base_bicubic(q / (pc.domain / float(pc.n1 - 1)));
	float deposit = bilinear(0, pc.n1, q / (pc.domain / float(pc.n1 - 1)));

	// ---- rivers and their history
	float floor_h = 1e9;
	float floor_w = 0.0;
	float t_last = -1.0;      // when a past course last swept this point
	float ox_bed = 1e9;       // oxbow / scar bed
	float ox_level = 0.0;
	float ox_water = 0.0;
	float marsh = 0.0;
	float chan_bed = 1e9;
	float levee = 0.0;
	float wd = 1e9;           // distance into the nearest channel's water (< 0 inside)
	float wlev = 0.0;
	vec2 flow = vec2(0.0);

	ivec2 bc = clamp(ivec2(q / pc.bucket), ivec2(0), ivec2(pc.nb - 1));
	ivec2 bk = buckets.v[bc.y * pc.nb + bc.x];
	for (int n = 0; n < bk.y; n++) {
		int i = index.v[bk.x + n];
		vec4 S0 = segs.v[i * 3];
		vec4 S1 = segs.v[i * 3 + 1];
		vec4 S2 = segs.v[i * 3 + 2];
		vec2 ab = S0.zw - S0.xy;
		vec2 aq = p - S0.xy;
		float t = clamp(dot(aq, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
		float d = length(aq - ab * t);
		float e = mix(S1.x, S1.y, t);
		float hw = mix(S1.z, S1.w, t);
		float F = mix(S2.x, S2.y, t);
		int kind = int(S2.w + 0.5);
		float bankh = 0.4 + 0.1 * hw; // floodplain height above the water
		if ((kind == 0 || kind == 1) && F > 0.0) {
			float blend = min(0.5 * F + 20.0, 100.0);
			float wgt = 1.0 - smoothstep(0.0, blend, d - F);
			float lvl = e + bankh;
			floor_h = min(floor_h, mix(1e5, lvl, wgt));
			floor_w = max(floor_w, wgt);
		}
		if (kind == 1) {
			float bw = 1.0 + 0.6 * hw;
			if (d < hw + bw) {
				float r = d / hw;
				float bed = d < hw ? e - S2.z * (1.0 - r * r) : e - 0.15 + (bankh + 0.15) * smoothstep(hw, hw + bw, d);
				chan_bed = min(chan_bed, bed);
			}
			// Natural levee: overbank deposits thin away from the channel.
			if (d > hw) {
				levee = max(levee, (0.15 + 0.04 * hw) * exp(-(d - hw) / (3.0 * hw + 4.0)));
			}
			if (d - hw < wd) {
				wd = d - hw;
				wlev = e;
				flow = normalize(ab) * clamp((S1.x - S1.y) / max(length(ab), 0.1) * 300.0, 0.2, 1.0);
			}
		} else if (kind == 2) {
			// Oxbow cut off at time S2.z: open water while young, filling with age.
			float age = 1.0 - S2.z;
			float fill = clamp(age * 1.4, 0.0, 1.0);
			float depth = (0.6 + 0.12 * hw) * (1.0 - fill) + 0.25;
			if (d < hw * 1.3) {
				float r = clamp(d / (hw * 1.3), 0.0, 1.0);
				ox_bed = min(ox_bed, e - depth * (1.0 - r * r));
				ox_level = e;
				if (fill < 0.75 && d < hw) {
					ox_water = 1.0;
				}
				marsh = max(marsh, (1.0 - r) * smoothstep(0.3, 0.8, fill));
			}
		} else if (kind == 3) {
			if (d < hw) {
				t_last = max(t_last, S2.z);
			}
		}
	}

	// ---- compose
	float hb = h;
	if (floor_w > 0.0) {
		float flat_h = min(h, floor_h + 0.06 * max(h - floor_h, 0.0));
		h = mix(h, flat_h, floor_w);
	}
	float swale = 0.0;
	if (t_last >= 0.0) {
		// Scroll bars: ridge and swale by when the channel last passed here.
		float band = cos(TAU * t_last * SCROLL_BANDS);
		h += 0.22 * band * floor_w;
		swale = smoothstep(0.2, -0.8, band) * floor_w;
	}
	h += levee * floor_w;
	h = min(h, ox_bed);
	h = min(h, chan_bed);

	// ---- water
	float wlevel = h - 2.0;
	float cover = 0.0;
	float kind_out = 0.0;
	vec2 gl = q / (pc.domain / float(pc.nh - 1));
	float lake_lv = bilinear(1, pc.nh, gl);
	// Lake indicator: bilinear of "is lake" from the four surrounding cells.
	ivec2 lc = clamp(ivec2(floor(gl)), ivec2(0), ivec2(pc.nh - 2));
	vec2 lf = clamp(gl - vec2(lc), 0.0, 1.0);
	vec4 lk = vec4(lakes.v[lc.y * pc.nh + lc.x], lakes.v[lc.y * pc.nh + lc.x + 1],
			lakes.v[(lc.y + 1) * pc.nh + lc.x], lakes.v[(lc.y + 1) * pc.nh + lc.x + 1]);
	vec4 ind = step(vec4(NO_LAKE + 1.0), lk);
	float lakef = mix(mix(ind.x, ind.y, lf.x), mix(ind.z, ind.w, lf.x), lf.y);
	float lake_level = max(max(lk.x, lk.y), max(lk.z, lk.w));
	if (lakef > 0.3 && lake_level > NO_LAKE + 1.0) {
		wlevel = lake_level;
		cover = clamp((lake_level - h) / 0.3, 0.0, 1.0) * smoothstep(0.3, 0.5, lakef);
		kind_out = 2.0;
		flow = vec2(0.0);
	} else if (wd < 30.0 * cf && wlev > -1.0) { // carried well past the banks, so mips keep the level
		wlevel = wlev - 0.1;
		cover = clamp(0.5 - wd / cf, 0.0, 1.0);
		kind_out = 1.0;
	}
	if (ox_water > 0.0 && ox_level - 0.1 > h) {
		wlevel = ox_level - 0.1;
		cover = max(cover, clamp((ox_level - 0.1 - h) / 0.2, 0.0, 1.0));
		kind_out = 2.0;
		flow = vec2(0.0);
	}
	if (kind_out != 1.0) flow = vec2(0.0);

	int o = id.y * pc.nf + id.x;
	out_h.v[o] = h;
	out_w.v[o] = wlevel;
	// Material: floodplain, wetness (swales, silted oxbows), river bed, fan/delta deposits.
	float bed = h < hb - 0.3 && chan_bed < 1e8 ? 1.0 : 0.0;
	out_m.v[o] = pack4(vec4(floor_w, max(swale * 0.7, marsh), max(bed, cover * float(kind_out == 1.0)),
			clamp(deposit / 4.0, 0.0, 1.0)));
	out_f.v[o] = pack4(vec4(cover, flow * 0.5 + 0.5, kind_out / 2.0));
}
