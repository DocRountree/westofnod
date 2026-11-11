shader_type spatial;
render_mode cull_disabled;

// Land snails (Snails): every snail one instance of one mesh, posed here
// from the clock and its own few numbers (INSTANCE_CUSTOM: x how fast it
// glides, 0..1; y feeding (0..1) less laying (0..1: its head down in the
// soil); z its own random 0..1; w its size and pose: its whole part its
// size (1000 full grown), its fraction 0.5 + 0.49 (withdrawn - reared),
// withdrawn 0..1 (into its shell), reared 0..1 (mating: its front up)).
//
// The mesh (Snails._build_mesh) out and gliding, in metres, the ground
// under its shell at the origin, facing -z; CUSTOM0.x its part: 0 the body
// (foot, head: by where along it, z), 2/3 the upper tentacles (left,
// right), 4/5 the lower, 6 the mantle's collar, 7 the shell, 8 its
// breathing pore, 9 the epiphragm (shown only sealed); .y along a
// tentacle (0 base .. 1 tip) or the shell's whorls from its apex; .z the
// shell's way round its tube (0..1), or 1 at an eye; .w 1 on the shell's
// flared lip.

uniform vec3 neck;        // where the head's turned about
uniform vec3 mid;         // where the front's reared about
uniform vec3 ap;          // the shell's mouth's centre
uniform vec3 ap_out;      // the way out of it
uniform vec3 tent_base[4]; // the tentacles' roots (upper left, right, lower left, right)
uniform vec3 tent_dir[4];
uniform float snout_z;
uniform float tail_z;
uniform vec3 shell_axis;
uniform float shell_drop; // (m: how far the shell settles, withdrawn)

uniform vec3 body_color : source_color = vec3(0.7, 0.5, 0.33);
uniform vec3 body_dark : source_color = vec3(0.4, 0.3, 0.24); // (the grooves between its tubercles)
uniform vec3 sole_color : source_color = vec3(0.8, 0.7, 0.58);
uniform vec3 tentacle_color : source_color = vec3(0.45, 0.42, 0.48);
uniform float tubercles = 1.0; // (its skin's network of grooves: 0 smooth)
uniform float body_sss = 0.3;
uniform vec3 shell_base : source_color = vec3(0.78, 0.6, 0.32);
uniform vec3 shell_flame : source_color = vec3(0.42, 0.14, 0.07);
uniform vec3 shell_apex : source_color = vec3(0.7, 0.55, 0.35); // (the first whorls' colour)
uniform vec3 shell_inner : source_color = vec3(0.85, 0.8, 0.72);
uniform vec3 lip_color : source_color = vec3(0.96, 0.95, 0.9);
uniform float flames = 9.0;    // flames a whorl (0: none)
uniform float ribs = 30.0;     // growth ribs a whorl
uniform float rib_depth = 0.6;
uniform float shell_gloss = 0.5;
uniform float glassy = 0.0;    // (a see-through shell: the body's shadow in it, light through it)
uniform float apex_whorls = 1.5;
uniform float glide_hz = 0.6;  // its sole's waves

varying flat int part;
varying vec3 rest;
varying vec3 rest_n;
varying vec2 sc; // (the shell's whorls, its way round; or along a tentacle, its eye)
varying flat float lipv;
varying float drawn_in;

vec3 rot(vec3 v, vec3 a, float ang) {
	float c = cos(ang), s = sin(ang);
	return v * c + cross(a, v) * s + a * dot(a, v) * (1.0 - c);
}

void turn(inout vec3 v, inout vec3 n, vec3 o, vec3 a, float ang) {
	v = rot(v - o, a, ang) + o;
	n = rot(n, a, ang);
}

void vertex() {
	part = int(round(CUSTOM0.x));
	rest = VERTEX;
	rest_n = NORMAL;
	sc = CUSTOM0.yz;
	lipv = CUSTOM0.w;
	float walk = INSTANCE_CUSTOM.x;
	float feed = max(INSTANCE_CUSTOM.y, 0.0);
	float lay = max(-INSTANCE_CUSTOM.y, 0.0);
	float seed = INSTANCE_CUSTOM.z;
	float wv = INSTANCE_CUSTOM.w;
	float size = floor(wv) / 1000.0;
	float pose = (fract(wv) - 0.5) / 0.49;
	float hide = clamp(pose, 0.0, 1.0);
	float rear = clamp(-pose, 0.0, 1.0);
	drawn_in = hide;
	float t = TIME + seed * 53.0;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 rt = vec3(1.0, 0.0, 0.0);
	bool soft = part != 7 && part != 9; // (the body and all on it)
	float head_w = smoothstep(neck.z * 0.4, neck.z * 1.25, rest.z); // (0 behind the neck .. 1 the head)
	if (part >= 2 && part <= 5)
		head_w = 1.0;
	// the tentacles: feeling about (the upper waving slowly, the lower
	// dabbing down); drawn in (withdrawn, or the eye-stalks pulled in as it
	// rears) toward their roots
	float tin = smoothstep(0.0, 0.3, hide);
	if (part >= 2 && part <= 5) {
		int i = part - 2;
		float side = (i % 2 == 1) ? 1.0 : -1.0;
		vec3 b = tent_base[i];
		vec3 d = tent_dir[i];
		float along = CUSTOM0.y;
		float bend = along * along;
		if (i < 2) {
			float ph = t * 0.7 + float(i) * 2.1;
			turn(v, n, b, up, (0.3 * sin(ph) + 0.12 * sin(t * 1.9 + float(i))) * bend * 1.6);
			turn(v, n, b, rt, (0.25 * sin(t * 0.53 + float(i) * 1.3) - 0.2 * feed) * bend * 1.6);
		} else {
			float dab = max(sin(t * 2.2 + float(i) * 1.7), 0.0);
			turn(v, n, b, rt, -(0.25 * walk + 0.45 * feed) * dab * bend * 2.0);
			turn(v, n, b, up, 0.2 * sin(t * 1.3 + float(i)) * bend);
		}
		v = b + (v - b) * mix(1.0, 0.08, tin);
	}
	// the body stretching as it glides, its front reaching on; its waves
	// rippling down its sides
	if (soft) {
		float front = clamp((-v.z) / max(-snout_z, 1e-5), 0.0, 1.0);
		v.z -= 0.06 * walk * front * (-snout_z) * (0.8 + 0.2 * sin(t * glide_hz * 6.2832));
		float wave = sin(rest.z * 900.0 + t * glide_hz * 6.2832 * 2.0);
		v.y += 0.00004 * walk * wave * smoothstep(0.0, 0.002, rest.y);
	}
	// the head: swaying, nodding; down to its food (rasping), down into
	// the soil laying; the whole front up, mating (the foot's fronts
	// pressed together)
	if (soft && head_w > 0.0) {
		float sway = (0.18 * sin(t * 0.45) + 0.06 * sin(t * 1.3)) * (0.4 + 0.6 * walk);
		float nod = -0.4 * feed - 0.05 * feed * sin(t * 3.5) - 0.75 * lay + 0.04 * sin(t * 0.8);
		turn(v, n, neck, up, sway * head_w);
		turn(v, n, neck, rt, nod * head_w);
		if (lay > 0.0) v.y -= 0.0015 * lay * head_w;
	}
	if (soft && rear > 0.0) {
		float fr = smoothstep(mid.z, mid.z * 3.0, rest.z) * (part == 6 || part == 8 ? 0.0 : 1.0);
		if (part >= 2 && part <= 5) fr = 1.0;
		turn(v, n, mid, rt, -0.85 * rear * fr);
		turn(v, n, mid, up, 0.12 * rear * sin(t * 0.6) * fr);
	}
	// withdrawn: the head and the foot drawn up into the shell's mouth,
	// shrinking into it; the shell settling down to the ground
	float bin = smoothstep(0.15, 1.0, hide);
	if (soft) {
		vec3 inside = ap - ap_out * 0.004;
		v = mix(v, inside + (v - inside) * 0.08, bin);
	}
	float drop = shell_drop * bin;
	if (part == 7 || part == 9) {
		// (rocking a little as it glides)
		turn(v, n, ap, up, 0.03 * walk * sin(t * glide_hz * 3.1416));
		turn(v, n, ap, rt, 0.02 * walk * sin(t * glide_hz * 6.2832));
	}
	if (part == 9 && hide < 0.985)
		v = ap; // (the film: only sealed)
	v.y -= drop;
	v *= size;
	VERTEX = v;
	NORMAL = normalize(n);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// a cellular network (the skin's tubercles): 0 in a groove .. 1 a bump's top
float cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 9.0, d2 = 9.0;
	for (int y = -1; y <= 1; y++)
	for (int x = -1; x <= 1; x++) {
		vec2 g = vec2(float(x), float(y));
		vec2 o = vec2(hash(i + g), hash(i + g + 17.3));
		float d = length(g + o - f);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) d2 = d;
	}
	return smoothstep(0.0, 0.25, d2 - d1);
}

// the normal tipped by a height h over the surface (its screen derivatives)
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

void fragment() {
	vec3 c = body_color;
	float rough = 0.28;
	float spec = 0.6;
	vec3 nrm = NORMAL;
	if (part == 0 || part == 6 || part == 8) {
		// the skin: a network of grooves round low bumps (along the body),
		// the sole beneath paler, smooth; wet
		vec2 q = vec2(rest.z, rest.y + abs(rest.x) * 0.6) * 1700.0;
		float cl = tubercles > 0.0 ? cells(q) : 1.0;
		float fade = clamp(1.0 - length(fwidth(q)) / 0.8, 0.0, 1.0);
		cl = mix(1.0, cl, fade);
		c = mix(body_dark, body_color, mix(1.0, cl, tubercles));
		nrm = bump(nrm, VERTEX, cl * 0.00004 * tubercles * fade, 1.0);
		float sole = (1.0 - smoothstep(0.0002, 0.0007, rest.y)) * smoothstep(0.2, 0.6, -rest_n.y);
		c = mix(c, sole_color, sole);
		if (rest.z < neck.z) // (the head a little darker, toward the tentacles)
			c = mix(c, tentacle_color, smoothstep(neck.z, neck.z * 1.6, rest.z) * 0.35);
		if (part == 6)
			c = mix(body_color, body_dark, 0.35);
		if (part == 8) // (the breathing pore: opening, closing)
			c = mix(body_dark * 0.6, vec3(0.03), smoothstep(-0.2, 0.6, sin(TIME * 0.35 + rest.x * 3000.0)));
		SSS_STRENGTH = body_sss;
	}
	if (part >= 2 && part <= 5) {
		c = tentacle_color;
		if (sc.y > 0.5) { // (an eye)
			c = vec3(0.01);
			rough = 0.05;
		}
		SSS_STRENGTH = body_sss;
	}
	if (part == 7) {
		float whorl = sc.x;
		float round_ = sc.y;
		// growth ribs across the tube (finer toward the apex), the flames
		// running across them, slanting, ragged; the first whorls plain
		float g = whorl * ribs;
		float rib = 0.5 + 0.5 * sin(g * 6.2832 + sin(g * 1.7) * 0.6);
		float fade = clamp(1.0 - fwidth(g) * 1.5, 0.0, 1.0);
		c = shell_base;
		if (flames > 0.0) {
			float fz = whorl * flames + round_ * 0.55 + 0.08 * sin(round_ * 25.0 + whorl * 7.0);
			float idx = floor(fz);
			float h = hash(vec2(idx, 3.1));
			float w = mix(0.12, 0.42, h * h); // (each flame its own width, some only a thread)
			float f = fract(fz + 0.06 * sin(round_ * 40.0 + idx * 3.7)); // (their edges zigzagging)
			float flame = smoothstep(w + 0.05, w - 0.02, f) * smoothstep(0.0, 0.04, f);
			flame *= step(0.12, hash(vec2(idx, 9.7))); // (a few missing)
			// (a paler band round the shoulder)
			float shoulder = 1.0 - smoothstep(0.03, 0.08, abs(round_ - 0.0));
			flame *= 1.0 - 0.7 * shoulder;
			flame *= smoothstep(apex_whorls - 0.3, apex_whorls + 0.4, whorl);
			c = mix(c, shell_flame, flame);
		}
		c = mix(shell_apex, c, smoothstep(apex_whorls * 0.6, apex_whorls, whorl));
		c *= mix(1.0, 0.85 + 0.25 * rib, fade * min(rib_depth * 1.4, 1.0));
		nrm = bump(nrm, VERTEX, rib * 0.00003 * rib_depth * fade, 1.0);
		c = mix(c, lip_color, smoothstep(0.4, 0.9, lipv));
		rough = mix(0.65, 0.12, shell_gloss);
		spec = 0.55;
		if (glassy > 0.0) { // (see-through: light through it, the body's shadow in it)
			BACKLIGHT = c * 0.6 * glassy;
			c = mix(c, c * 0.7, glassy * 0.3 * (1.0 - drawn_in));
		}
		if (!FRONT_FACING) { // (its inside, pearly)
			c = shell_inner * 0.6;
			rough = 0.25;
		}
	}
	if (part == 9) { // (the epiphragm: dried mucus, papery white)
		c = vec3(0.86, 0.85, 0.8);
		rough = 0.8;
		spec = 0.3;
	}
	NORMAL = nrm;
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = spec;
}
