shader_type spatial;
render_mode cull_disabled;

// A bird (Bird; the wild turkey its first): one mesh, posed by
// bird_rig.gdshaderinc (its joints from its motor, its wings and its tail's
// fan worked out here), feathered here.
//
// CUSTOM0: its part, and where on it (x the part; y, z: along and round a
// skin (round: 0 under its middle, 0.5 over its back), or along (0 root ..
// 1 tip) and across (-1 .. 1) a feather; w: a feather's own number, or the
// skin's region). The parts: 0 the feathered skin (w: 0 the body, 1 the
// neck); 1 bare skin (the head, the upper neck); 2 the bill; 3 an eye; 4
// the snood; 5 wattle and caruncles; 6 the beard; 7 a feathered leg; 8 a
// bare leg, the toes; 9 claws, spurs; 10 a wing's own surface (its
// coverts); 11 primaries; 12 secondaries; 13 tertials; 14 tail feathers;
// 15 tail coverts (w: -1 the lower row .. the upper).

#include "res://shaders/render/bird_rig.gdshaderinc"

uniform float puff = 0.0;      // the body's feathers raised (strutting)
uniform float flush = 0.0;     // the bare head's colours up (strutting: white crown, blue face, scarlet wattles)
uniform float snood = 0.0;     // the snood let down over the bill (0: a short horn)
uniform float eye_shut = 0.0;
uniform float down = 0.0;      // a poult's down (1), not feathers
uniform float hen = 0.0;       // a hen's duller feathers, buff tipped
uniform float bare_from = 0.42; // where along the skin the bare neck begins
uniform vec3 snood_at;
uniform float feather_cm = 4.0; // a body feather's width
uniform float sway = 0.0;      // the beard's, the wattle's swing (its motor's)

uniform vec3 bronze : source_color = vec3(0.3, 0.19, 0.08);
uniform vec3 copper : source_color = vec3(0.46, 0.17, 0.07);
uniform vec3 green : source_color = vec3(0.1, 0.27, 0.16);
uniform vec3 dark : source_color = vec3(0.035, 0.03, 0.03);
uniform vec3 tip_color : source_color = vec3(0.02, 0.02, 0.02); // a body feather's edge (a hen's: buff)
uniform vec3 tail_tip : source_color = vec3(0.72, 0.5, 0.3);
uniform vec3 tail_brown : source_color = vec3(0.4, 0.22, 0.1);
uniform vec3 covert_tip : source_color = vec3(0.5, 0.22, 0.1);
uniform vec3 skin_red : source_color = vec3(0.8, 0.07, 0.09);
uniform vec3 skin_blue : source_color = vec3(0.2, 0.47, 0.85);
uniform vec3 skin_pale : source_color = vec3(0.86, 0.9, 0.9);
uniform vec3 leg_color : source_color = vec3(0.72, 0.38, 0.4);
uniform vec3 bill_color : source_color = vec3(0.62, 0.55, 0.45);
uniform vec3 down_color : source_color = vec3(0.86, 0.72, 0.42);
uniform vec3 down_dark : source_color = vec3(0.3, 0.19, 0.1);

varying flat int part;
varying vec3 fc; // (CUSTOM0.yzw)
varying vec3 rest;
varying vec3 rest_n;
varying vec2 suv;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	part = int(round(CUSTOM0.x));
	fc = CUSTOM0.yzw;
	rest = VERTEX;
	rest_n = NORMAL;
	suv = UV;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	if (part == 0 && int(round(CUSTOM1.x)) == 0) {
		// the body's feathers raised: fuller, most over its back and breast
		float body = 1.0 - smoothstep(bare_from - 0.25, bare_from, CUSTOM0.y);
		v += n * puff * 0.045 * body * (0.55 + 0.45 * sin(CUSTOM0.z * 6.2832 - 1.5708));
	}
	if (part == 4) {
		// the snood: a short horn, or let down, long, over the bill and past it
		float along = CUSTOM0.y;
		vec3 d = v - snood_at;
		vec3 up_pose = snood_at + d;
		vec3 hang = snood_at + vec3(d.x, 0.0, d.z) + vec3(0.0, 0.012 - along * along * 0.085, -0.012 - along * 0.035 + along * along * 0.012);
		hang.x += 0.006 * sway * along * along;
		v = mix(up_pose, hang, snood);
	}
	if (part == 6) // (the beard swinging from its root)
		v.x += 0.03 * sway * CUSTOM0.y * CUSTOM0.y;
	if (part == 5)
		v.x += 0.006 * sway * CUSTOM0.y;
	bird_pose(CUSTOM1, CUSTOM2, v, n);
	VERTEX = v;
	NORMAL = n;
}

vec3 bump(vec3 nrm, vec3 pos, float h, float k) {
	vec3 dpx = dFdx(pos);
	vec3 dpy = dFdy(pos);
	float dhx = dFdx(h);
	float dhy = dFdy(h);
	vec3 r1 = cross(dpy, nrm);
	vec3 r2 = cross(nrm, dpx);
	float det = dot(dpx, r1);
	vec3 g = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * nrm - g * k);
}

// The body's feathers, overlapping like shingles (p: across, along, in
// feathers; they point along +y): x how far from its tip (0 the edge .. 1
// its root, hidden), y its own random, z how far across it (-1 .. 1).
vec3 shingle(vec2 p) {
	float row = floor(p.y);
	for (int k = 1; k >= 0; k--) {
		float r = row - float(k);
		float x = p.x + 0.5 * mod(r, 2.0) + 0.17 * hash(vec2(r, 3.3));
		float col = floor(x);
		float fx = fract(x) * 2.0 - 1.0;
		float fy = p.y - r; // (0 its root .. past 1: its tip, over the next row)
		float reach = 1.0 + 0.85 * sqrt(max(1.0 - fx * fx, 0.0));
		if (fy < reach || k == 0)
			return vec3(clamp((reach - fy) / 0.85, 0.0, 1.0), hash(vec2(col, r)), fx);
	}
	return vec3(1.0, 0.0, 0.0);
}

// A metal sheen that turns with the light: bronze, copper, green.
vec3 sheen(float t) {
	t = fract(t);
	vec3 c = mix(bronze, copper, smoothstep(0.0, 0.35, t));
	c = mix(c, green, smoothstep(0.35, 0.7, t));
	return mix(c, bronze, smoothstep(0.7, 1.0, t));
}

// A feather's vane: its bars across (n to its length, w wide), wavering.
float bars(float u, float v, float n, float w, float seed) {
	float x = u * n + 0.25 * abs(v) + 0.06 * sin(v * 9.0 + seed * 20.0);
	return smoothstep(w, w + 0.12, abs(fract(x) - 0.5) * 2.0);
}

void fragment() {
	vec3 nrm = NORMAL;
	vec3 view = normalize(VIEW);
	if (dot(nrm, view) < 0.0)
		nrm = -nrm;
	float ndv = clamp(dot(nrm, view), 0.0, 1.0);
	vec3 c = dark;
	float rough = 0.6;
	float metal = 0.0;
	float spec = 0.5;
	float u = fc.x;
	float v = fc.y;
	if (part == 0 || part == 7 || part == 10) {
		// feathers: each a dark vane, a band of metal near its end that
		// turns bronze to copper to green with the light, its edge black
		// (a tom's) or buff (a hen's)
		vec2 p;
		float size = 1.0;
		float region = 0.0; // (0 the body .. 1 the breast and neck: smaller)
		if (part == 0) {
			region = smoothstep(0.0, 0.1, u);
			size = mix(1.0, 0.42, region);
			p = vec2(suv.x, -suv.y) / (feather_cm * 0.01 * size) * vec2(1.0, 1.25);
		} else if (part == 7) {
			size = 0.45;
			p = vec2(suv.x, suv.y) / (feather_cm * 0.01 * size) * vec2(1.0, 1.25);
		} else {
			size = 0.55;
			p = vec2(suv.x, suv.y) / (feather_cm * 0.01 * size) * vec2(1.0, 1.25);
		}
		vec3 f = shingle(p);
		float edge = 1.0 - smoothstep(0.03, 0.1, f.x);
		float band = smoothstep(0.05, 0.14, f.x) * (1.0 - 0.75 * smoothstep(0.55, 0.95, f.x));
		float patch = vnoise(suv * 9.0 + rest.x * 5.0);
		float hue = 0.05 + ndv * 0.7 + f.y * 0.25 + (part == 10 ? 0.15 + v * 0.3 : 0.0) + patch * 0.5;
		vec3 metalc = sheen(hue) * (0.45 + 0.75 * f.y * f.y + 0.3 * patch);
		c = mix(dark, metalc, band * (1.0 - 0.45 * hen));
		c = mix(c, mix(tip_color, vec3(0.6, 0.5, 0.36), hen * (0.4 + 0.6 * region)), edge);
		c *= 0.75 + 0.25 * (1.0 - f.z * f.z); // (its vane darker to its sides)
		metal = band * 0.75 * (1.0 - edge);
		rough = mix(0.62, 0.34, band);
		spec = 0.55;
		float fade = clamp(1.0 - length(fwidth(p)) * 0.9, 0.0, 1.0);
		nrm = bump(nrm, VERTEX, (smoothstep(0.0, 0.5, f.x) * 0.5 + (1.0 - abs(f.z)) * 0.15) * feather_cm * 0.0012 * size * fade * (1.0 + puff), 1.0);
		if (part == 10) {
			// (the greater coverts, the row over the flight feathers: a coppery bar)
			float bar = smoothstep(0.62, 0.72, v);
			c = mix(c, mix(copper, bronze, 0.4) * (0.55 + 0.5 * f.y), bar * band);
		}
		if (down > 0.0) {
			// a poult's down: buff, a dark stripe over its crown and down its back, mottled
			float fluff = vnoise(rest.xz * 900.0) * 0.5 + vnoise(rest.xy * 1700.0) * 0.5;
			float stripe = part == 0 ? (1.0 - smoothstep(0.035, 0.08, abs(v - 0.5))) + 0.8 * (1.0 - smoothstep(0.025, 0.06, abs(abs(v - 0.5) - 0.15))) : 0.0;
			stripe *= part == 0 ? 0.55 + 0.45 * smoothstep(0.6, 1.0, u) + 0.4 * (1.0 - smoothstep(0.0, 0.5, u)) : 1.0;
			stripe = max(stripe, part == 10 ? 0.5 * vnoise(suv * 300.0) : 0.0); // (the wing stubs mottled)
			vec3 dc = mix(down_color * (0.8 + 0.3 * fluff), down_dark, clamp(stripe, 0.0, 1.0) * (0.6 + 0.4 * fluff));
			dc = mix(dc, down_color * 1.12, part == 0 ? 1.0 - smoothstep(0.0, 0.25, v < 0.5 ? v : 1.0 - v) : 0.0);
			c = mix(c, dc, down);
			metal *= 1.0 - down;
			rough = mix(rough, 0.95, down);
			nrm = normalize(mix(nrm, NORMAL, down));
		}
	}
	if (part == 1 || part == 4 || part == 5 || (part == 0 && u > bare_from - 0.04)) {
		// bare skin: warty, wrinkled; red, blue about the face, pale over
		// the crown; its colours up, strutting. Bristles thin on it.
		vec2 q = rest.zy * 520.0 + rest.xx * 300.0;
		vec2 i = floor(q);
		vec2 f2 = fract(q);
		float d1 = 9.0;
		float id = 0.0;
		for (int y = -1; y <= 1; y++)
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 7.7));
			float d = length(g + o - f2);
			if (d < d1) { d1 = d; id = hash(i + g + 2.2); }
		}
		float wart = 1.0 - smoothstep(0.2, 0.62, d1);
		float crown = smoothstep(0.3, 0.9, rest_n.y) * smoothstep(0.84, 0.92, u);
		float face = smoothstep(0.84, 0.92, u) * (1.0 - crown) * smoothstep(-0.7, 0.0, rest_n.y);
		vec3 red = skin_red * (0.75 + 0.35 * id);
		vec3 dull = mix(vec3(0.66, 0.24, 0.27), vec3(0.45, 0.36, 0.55), id * 0.6);
		vec3 skin = mix(dull, red, 0.55 + 0.45 * flush);
		skin = mix(skin, mix(mix(skin_blue, dull, 0.45), skin_blue, flush), face * (0.55 + 0.45 * flush));
		skin = mix(skin, mix(mix(skin_pale, skin_blue, 0.5), skin_pale, flush) , crown * (0.35 + 0.65 * flush));
		// (the neck's caruncles: beads of red on blue-grey)
		float neck = 1.0 - smoothstep(0.6, 0.85, u);
		skin = mix(skin, mix(vec3(0.3, 0.36, 0.5), skin_pale * vec3(0.8, 0.9, 1.0), flush) , neck * (1.0 - wart) * 0.6 * float(part == 0));
		if (part == 5 || part == 4)
			skin = mix(red, mix(red, skin_pale, 0.25), wart * 0.3) * (part == 4 ? mix(0.75, 1.0, flush) : 1.0);
		skin = mix(skin, skin * vec3(0.6, 0.65, 0.75), hen * 0.6);
		float bare = part == 0 ? smoothstep(bare_from - 0.04, bare_from + 0.03, u + 0.03 * (vnoise(rest.xy * 300.0) - 0.5)) : 1.0;
		c = mix(c, skin * (0.8 + 0.25 * wart), bare);
		rough = mix(rough, 0.5, bare);
		metal *= 1.0 - bare;
		nrm = normalize(mix(nrm, bump(normalize(NORMAL * (dot(NORMAL, view) < 0.0 ? -1.0 : 1.0)), VERTEX, wart * 0.0009, 1.0), bare));
		SSS_STRENGTH = 0.3 * bare;
	}
	if (part == 2) {
		c = mix(bill_color * 0.55, bill_color, smoothstep(0.1, 0.8, u));
		rough = 0.35;
	}
	if (part == 3) {
		c = mix(vec3(0.16, 0.08, 0.04), vec3(0.01), smoothstep(0.35, 0.6, ndv));
		rough = 0.06;
		spec = 0.8;
		if (eye_shut > 0.5)
			c = vec3(0.45, 0.42, 0.5);
	}
	if (part == 6) {
		c = mix(vec3(0.02), vec3(0.12, 0.1, 0.07), smoothstep(0.75, 1.0, u) + 0.2 * hash(vec2(fc.z * 31.0, 1.0)));
		rough = 0.45;
	}
	if (part == 8) {
		// scaled legs: plates down the front, pink red
		float sc = fract(rest.y * 85.0 + 0.5 * step(0.5, fract(v * 4.0)));
		float line = smoothstep(0.0, 0.12, sc) * smoothstep(0.0, 0.1, fract(v * 4.0));
		c = leg_color * mix(0.55, 1.0, line) * (0.85 + 0.15 * vnoise(rest.xy * 900.0));
		c = mix(c, down_color * vec3(1.0, 0.8, 0.7), down * 0.6);
		rough = 0.45;
		nrm = bump(nrm, VERTEX, line * 0.0004, 1.0);
	}
	if (part == 9) {
		c = vec3(0.1, 0.08, 0.07);
		rough = 0.3;
	}
	if (part >= 11 && part <= 15) {
		// a flight feather or a tail feather: its shaft, its barbs, its bars
		float seed = hash(vec2(fc.z * 17.0, float(part)));
		float shaft = 1.0 - smoothstep(0.02, 0.07, abs(v));
		float barbs = 0.9 + 0.1 * sin((u * 160.0 - abs(v) * 30.0));
		if (part == 11 || part == 12) {
			// black, barred white (a primary's bars clean; a secondary's
			// browner, its outer edge bronzed)
			float b = bars(u, v, part == 11 ? 11.0 : 9.0, 0.5, seed);
			c = mix(vec3(0.86, 0.84, 0.78), vec3(0.05, 0.045, 0.04), b);
			if (part == 12)
				c = mix(c, mix(bronze, copper, 0.5) * 0.7, smoothstep(0.55, 1.0, u) * 0.6 + smoothstep(0.3, 0.9, -v) * 0.35);
			c = mix(c, vec3(0.35, 0.28, 0.2), hen * 0.25);
		} else if (part == 13) {
			c = mix(dark, sheen(0.3 + ndv + seed * 0.3), 0.6 * smoothstep(0.3, 0.9, u));
			metal = 0.4;
		} else {
			// a tail feather: brown, finely barred dark, a broad black
			// band below its tip, the tip buff (a covert's chestnut)
			float fine = bars(u, v, part == 14 ? 26.0 : 18.0, 0.42, seed);
			vec3 base = tail_brown * (0.8 + 0.4 * vnoise(vec2(u * 30.0, v * 4.0 + seed * 9.0)));
			c = mix(base, vec3(0.05, 0.035, 0.03), (1.0 - fine) * 0.9);
			float wav = 0.012 * sin(v * 7.0 + seed * 6.0);
			float blackb = smoothstep(0.76, 0.8, u + wav) * (1.0 - smoothstep(0.9, 0.925, u + wav));
			c = mix(c, vec3(0.025, 0.02, 0.02), blackb);
			vec3 tipc = part == 14 ? tail_tip : covert_tip;
			c = mix(c, tipc * (0.85 + 0.25 * vnoise(vec2(v * 12.0, seed * 30.0))), smoothstep(0.9, 0.93, u + wav));
			if (part == 15) // (a covert: a sheen of copper below its band)
				c = mix(c, sheen(0.2 + ndv * 0.6) * 0.9, 0.5 * smoothstep(0.45, 0.75, u) * (1.0 - smoothstep(0.76, 0.8, u)));
		}
		c *= barbs;
		c = mix(c, c * 0.5 + vec3(0.25, 0.22, 0.18) * 0.5, shaft * 0.6);
		c = mix(c, down_color, down);
		rough = 0.5;
		spec = 0.4;
		// (cupped across its shaft)
		nrm = normalize(nrm + cross(nrm, vec3(0.0, 0.0, 1.0)) * v * 0.0);
	}
	NORMAL = nrm;
	ALBEDO = c;
	ROUGHNESS = rough;
	METALLIC = metal;
	SPECULAR = spec;
}
