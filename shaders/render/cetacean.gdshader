shader_type spatial;
render_mode cull_disabled;

// The whales and dolphins (Cetacean): one mesh each (Cetacean.build), life
// size, facing -z, posed here from its motor's numbers.
//
// CUSTOM0: x its part (0 body, 1 eye, 2 dorsal fin, 3 flipper, 4 flukes, 5
// a tooth, 6 baleen), y s (0 the snout .. 1 the flukes' notch), z out along
// a fin (0 root .. 1 tip), w across it (0 leading .. 1 trailing; an eye's:
// how far toward its front). CUSTOM1: x with the lower jaw, y its pouch (a
// blue whale's throat), z its side (a flipper's, a fluke's), w round it (0
// its back's middle .. 1 its belly's; a fin's: 0 its top face, 1 its under).
//
// - swimming: its flukes beating up and down, the beat in its tail stock
//   and flukes, its body before still; bent into its turns
// - its jaws: the lower dropped open (a blue whale's near a right angle);
//   a blue whale's throat ballooning out, its pleats spread
// - a flipper raised and slapped down; its flukes slammed (lobtailing)
// - arched: its tail lifted (a blue whale's flukes up as it sounds)

uniform int species = 0;        // 0 a blue whale, 1 an orca, 2 a bottlenose dolphin
uniform float tl = 24.0;        // its mesh's length (m)
uniform float phase = 0.0;
uniform float amp = 0.5;        // the flukes' reach up and down (m, the mesh's)
uniform float bend = 0.0;       // into a turn (-1 .. 1)
uniform float arch = 0.0;       // its tail lifted (0 .. 1)
uniform float jaw = 0.0;        // its lower jaw dropped (0 .. 1)
uniform float jaw_max = 1.0;    // (rad)
uniform float pouch = 0.0;      // its throat ballooned (0 .. 1)
uniform float flip = 0.0;       // its flippers raised (1) .. slapped down (-)
uniform float slam = 0.0;       // its flukes raised (1) .. slammed (-)
uniform vec3 jaw_pivot = vec3(0.0, -0.2, -6.5);
uniform vec3 flip_root = vec3(1.2, -0.5, -4.5);
uniform float calf = 0.0;
uniform float scars = 0.5;
uniform float seed = 0.3;

varying float v_part;
varying vec3 v_rest;
varying vec3 v_rn;
varying vec4 v_c;
varying vec4 v_c1;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) { return vnoise(p) * 0.55 + vnoise(p * 2.1) * 0.3 + vnoise(p * 4.3) * 0.15; }

void turn(inout vec3 v, inout vec3 n, vec3 o, vec3 axis, float a) {
	vec3 k = normalize(axis);
	float c = cos(a);
	float s = sin(a);
	vec3 p = v - o;
	v = o + p * c + cross(k, p) * s + k * dot(k, p) * (1.0 - c);
	n = n * c + cross(k, n) * s + k * dot(k, n) * (1.0 - c);
}

// up and down at s: still before the tail, the beat in its stock and flukes
float wave(float s) {
	float env = 0.03 + 0.97 * pow(smoothstep(0.45, 1.05, s), 1.6);
	return amp * env * sin(3.4 * s - phase);
}

void vertex() {
	int part = int(round(CUSTOM0.x));
	v_part = float(part);
	v_c = CUSTOM0;
	v_c1 = CUSTOM1;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	v_rest = VERTEX;
	v_rn = NORMAL;
	// its throat ballooned (out along its skin, most below), then its jaw dropped
	if (CUSTOM1.y > 0.0)
		v += normalize(vec3(n.x * 0.7, min(n.y, 0.0) - 0.4, 0.0)) * pouch * CUSTOM1.y * tl * 0.075;
	if (CUSTOM1.x > 0.0)
		turn(v, n, jaw_pivot, vec3(1.0, 0.0, 0.0), -jaw_max * jaw * CUSTOM1.x);
	// its flippers: raised (to slap), brought down
	if (part == 3) {
		float side = sign(CUSTOM1.z);
		turn(v, n, flip_root * vec3(side, 1.0, 1.0), vec3(0.0, 0.0, 1.0), side * flip * 1.1 * CUSTOM0.z);
	}
	// the body: its beat, its turn, its tail lifted, slammed
	float s = CUSTOM0.y;
	if (part == 2 || part == 3 || part == 1 || part == 5 || part == 6)
		s = (VERTEX.z / tl + 0.5) / 0.96;
	float w = wave(s);
	float past = max(s - 1.0, 0.0) * tl * 0.96 + (part == 4 ? max(VERTEX.z - (0.46 * tl), 0.0) * 0.0 : 0.0);
	float slope = (wave(1.0) - wave(0.97)) / (0.03 * tl * 0.96);
	float fl = part == 4 ? (VERTEX.z - 0.46 * tl) : 0.0;
	v.y += w + fl * slope * 1.2;
	float tail = smoothstep(0.55, 1.0, s);
	v.y += arch * tl * 0.1 * tail * tail + slam * tl * 0.09 * pow(smoothstep(0.65, 1.0, s), 2.0);
	v.x += bend * s * s * tl * 0.06;
	float ang = atan(slope * 1.2) * smoothstep(0.85, 1.0, s);
	n = normalize(vec3(n.x, n.y * cos(ang) - n.z * sin(ang), n.y * sin(ang) + n.z * cos(ang)));
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

// (a soft-edged ellipse: d its point from the middle, r its half axes)
float blob(vec2 d, vec2 r, float soft) {
	return 1.0 - smoothstep(1.0 - soft, 1.0 + soft, length(d / r));
}

void shade(bool front, vec3 vtx, inout vec3 nrm, out vec3 c, out float rough, out float spec) {
	int part = int(round(v_part));
	float s = v_c.y;
	float round_ = v_c1.w; // (0 its back .. 1 its belly)
	float up = 1.0 - 2.0 * round_; // (1 its back's middle .. -1 its belly's)
	vec3 rp = v_rest / tl;
	float side = abs(rp.x) / max(abs(rp.x) + 0.001, 0.001);
	rough = 0.38;
	spec = 0.5;
	if (!front && part == 0) { // (inside its open mouth: its gums, its tongue)
		c = species == 0 ? vec3(0.32, 0.2, 0.2) : vec3(0.45, 0.2, 0.22);
		rough = 0.5;
		return;
	}
	if (part == 1) { // an eye: dark, wet
		c = vec3(0.03, 0.025, 0.025);
		rough = 0.08;
		spec = 0.9;
		return;
	}
	if (part == 5) { // a tooth: ivory
		c = vec3(0.86, 0.83, 0.74);
		rough = 0.35;
		return;
	}
	if (part == 6) { // baleen: black plates, their fringes paler, comb fine
		float fr = smoothstep(0.6, 1.0, v_c.z);
		c = mix(vec3(0.05, 0.05, 0.055), vec3(0.32, 0.3, 0.27), fr * (0.5 + 0.5 * sin(v_rest.z * 400.0)));
		rough = 0.6;
		return;
	}
	if (species == 0) { // a blue whale: mottled blue grey, paler dappling; its belly lighter, a yellow film of diatoms; the pleats
		vec2 q = vec2(rp.z * 60.0, rp.y * 60.0 + rp.x * 40.0 + seed * 10.0);
		float mot = fbm(q);
		float mot2 = fbm(q * 2.7 + 3.0);
		c = vec3(0.28, 0.36, 0.45) * (0.85 + 0.25 * mot);
		c = mix(c, vec3(0.56, 0.62, 0.67), smoothstep(0.62, 0.78, mot2) * 0.35); // (its pale mottles)
		c = mix(c, c * 1.18 + vec3(0.03, 0.03, 0.0), smoothstep(0.1, -0.6, up) * 0.6);
		c = mix(c, vec3(0.62, 0.6, 0.42), smoothstep(-0.6, -0.95, up) * 0.25 * (1.0 - calf));
		if (v_c1.y > 0.0) { // its pleats: grooves from its chin to its navel; spread, pink between
			float across = atan(rp.x, -(rp.y + 0.04)) * 34.0;
			float g = smoothstep(0.75, 1.0, abs(sin(across * 1.5708)));
			c = mix(c, mix(c * 0.55, vec3(0.78, 0.6, 0.58), pouch), g * v_c1.y * 0.8);
			nrm = bump(nrm, vtx, g * v_c1.y * 0.004 * tl / 24.0, 1.0);
		}
		if (part == 3) // (its flippers: paler beneath and at their tips)
			c = mix(c, vec3(0.62, 0.67, 0.7), smoothstep(0.7, 1.0, v_c.z) * 0.4 + v_c1.w * 0.3);
		if (part == 4)
			c = mix(c, vec3(0.6, 0.65, 0.68), v_c1.w * 0.4);
		// its splashguard, its blowholes: two slits behind a raised ridge
		if (part == 0) {
			float bh = blob(vec2(abs(rp.x) - 0.0045, rp.z - (0.19 * 0.96 - 0.5) - 0.004), vec2(0.0012, 0.009), 0.25) * step(0.6, up);
			c = mix(c, vec3(0.06, 0.06, 0.07), bh);
		}
	} else if (species == 1) { // an orca: black, its white patches, its grey saddle
		vec3 black = vec3(0.025, 0.026, 0.03);
		vec3 white = mix(vec3(0.95, 0.95, 0.93), vec3(0.95, 0.78, 0.6), calf * 0.8);
		c = black;
		float w = 0.0;
		// its chin and throat, narrowing between its flippers, then wide down its belly, a lobe up each flank behind
		float edge = mix(-0.25, -0.62, smoothstep(0.08, 0.2, s));                 // (throat, wide)
		edge = mix(edge, -0.9, smoothstep(0.2, 0.3, s));                           // (narrow between the flippers)
		edge = mix(edge, -0.55, smoothstep(0.38, 0.48, s));                        // (its belly)
		edge = mix(edge, 0.2, smoothstep(0.52, 0.62, s) * (1.0 - smoothstep(0.66, 0.74, s))); // (the flank lobe)
		edge = mix(edge, -0.7, smoothstep(0.74, 0.82, s));
		if (s < 0.05) edge = mix(-0.9, edge, smoothstep(0.0, 0.05, s));
		w = 1.0 - smoothstep(edge - 0.04, edge + 0.04, up);
		w *= 1.0 - smoothstep(0.88, 0.95, s); // (not on its tail stock)
		// its eye patch: above and behind the eye, sloping up toward its back
		vec2 ed = vec2(s - 0.16, up - (0.18 + (s - 0.16) * 2.0));
		w = max(w, blob(ed, vec2(0.04, 0.12), 0.15) * step(0.0, abs(rp.x) - 0.01));
		c = mix(c, white, w);
		// its saddle: grey, behind the dorsal fin, over its back
		float sad = blob(vec2(s - 0.47, up - 1.0), vec2(0.06, 0.45), 0.4) * (0.6 + 0.4 * fbm(rp.zx * 90.0));
		c = mix(c, vec3(0.42, 0.43, 0.45), sad * (1.0 - calf * 0.5) * float(part == 0));
		if (part == 4) // (its flukes: white beneath)
			c = mix(black, white, v_c1.w * smoothstep(0.1, 0.25, v_c.z) * (1.0 - smoothstep(0.85, 1.0, v_c.w)) * 0.9);
		if (part == 2 || part == 3)
			c = black;
		rough = 0.3;
		spec = 0.6;
	} else { // a bottlenose dolphin: its dark cape along its back, grey flanks, its belly pale pink white
		vec3 cape = vec3(0.16, 0.18, 0.21);
		vec3 flank = vec3(0.38, 0.41, 0.44);
		vec3 belly = vec3(0.9, 0.87, 0.86);
		float cap_edge = mix(0.55, 0.3, smoothstep(0.1, 0.4, s));
		cap_edge = mix(cap_edge, 0.55, smoothstep(0.5, 0.7, s));
		c = mix(flank, cape, smoothstep(cap_edge - 0.12, cap_edge + 0.12, up + 0.05 * fbm(rp.zy * 40.0)));
		c = mix(c, belly, smoothstep(-0.35, -0.6, up));
		// its beak darker above; a faint stripe from its eye to its flipper; one from blowhole to beak
		c = mix(c, cape * 0.9, smoothstep(0.1, 0.06, s) * smoothstep(-0.2, 0.3, up));
		float stripe = blob(vec2(s - 0.17, up - (-0.05 - (s - 0.12) * 1.2)), vec2(0.06, 0.06), 0.4) * step(0.12, s) * step(s, 0.22);
		c = mix(c, cape, stripe * 0.4);
		if (part == 2 || part == 3 || part == 4)
			c = mix(cape, flank, v_c1.w * 0.5);
		c = mix(c, c * 0.85, calf * 0.4);
		rough = 0.28;
		spec = 0.55;
		if (part == 0) { // (its blowhole: a crescent on top)
			float bh = blob(vec2(rp.x, rp.z - (0.15 * 0.96 - 0.5)), vec2(0.007, 0.002), 0.3) * step(0.7, up);
			c = mix(c, vec3(0.05), bh);
		}
	}
	if (species == 1 && part == 0) { // (an orca's blowhole)
		float bh = blob(vec2(rp.x, rp.z - (0.155 * 0.96 - 0.5)), vec2(0.008, 0.0022), 0.3) * step(0.75, up);
		c = mix(c, vec3(0.0), bh);
	}
	// old scars: rake marks (an orca's, a dolphin's: from others' teeth), pale
	float sc = scars * step(0.0, 1.0) * smoothstep(0.72, 0.9, vnoise(vec2(rp.z * 120.0 + seed * 30.0, rp.x * 300.0 + rp.y * 900.0))) * smoothstep(0.5, 0.95, vnoise(rp.zy * 25.0 + seed * 7.0));
	c = mix(c, c * 0.6 + vec3(0.32), sc * (species == 0 ? 0.25 : 0.4) * (1.0 - calf));
	// its skin: smooth, wet, a faint ripple
	float rip = vnoise(rp.zx * 600.0) * 0.5 + vnoise(rp.zy * 1500.0) * 0.5;
	nrm = bump(nrm, vtx, rip * 0.0006 * tl / 7.0, 1.0);
}

void fragment() {
	vec3 nrm = NORMAL;
	vec3 c;
	float rough;
	float spec;
	shade(FRONT_FACING, VERTEX, nrm, c, rough, spec);
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = spec;
	NORMAL = nrm;
}
