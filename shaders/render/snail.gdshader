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
// shell's way round its tube (0 its outside, 0.25 its top), or 1 at an
// eye; on the body .y its way round (0 its sole's middle .. 1 its back's);
// .w 1 on the shell's flared lip. UV.x: on the shell, how open to the
// light (0 down in a suture .. 1).

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
uniform float shell_whorls = 5.0;
uniform float shell_grow = 1.5;
uniform float skin_cell = 0.0012; // (m: a tubercle's width)

uniform vec3 body_color : source_color = vec3(0.7, 0.5, 0.33);
uniform vec3 body_dark : source_color = vec3(0.4, 0.3, 0.24); // (the grooves between its tubercles)
uniform vec3 sole_color : source_color = vec3(0.8, 0.7, 0.58);
uniform vec3 tentacle_color : source_color = vec3(0.45, 0.42, 0.48);
uniform float tubercles = 1.0; // (its skin's network of grooves: 0 smooth)
uniform vec3 band_color : source_color = vec3(0.36, 0.2, 0.13); // (the dark bands along its neck)
uniform float band = 0.0;
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
varying float open_k;

// 0 at a .. 1 at b, eased (either way round)
float ramp(float a, float b, float x) {
	float f = clamp((x - a) / (b - a), 0.0, 1.0);
	return f * f * (3.0 - 2.0 * f);
}

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
	open_k = UV.x;
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
	float head_w = ramp(neck.z * 0.4, neck.z * 1.25, rest.z); // (0 behind the neck .. 1 the head)
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
		if (part == 0) { // (the foot's fringe rippling, lapping the ground)
			float rim = smoothstep(0.12, 0.3, CUSTOM0.y) * (1.0 - smoothstep(0.4, 0.55, CUSTOM0.y));
			v.x += sign(rest.x) * rim * skin_cell * 0.2 * (0.3 + walk) * sin(rest.z / skin_cell * 0.9 - t * glide_hz * 9.0);
		}
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
		float fr = ramp(mid.z * 0.2, mid.z * 4.5, rest.z) * (part == 6 || part == 8 ? 0.0 : 1.0);
		if (part >= 2 && part <= 5) fr = 1.0;
		turn(v, n, mid, rt, 0.72 * rear * fr);
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

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// a cellular network (the skin's tubercles): x 0 in a groove .. 1 a bump's
// top; y the cell's own random
vec2 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 9.0, d2 = 9.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++)
	for (int x = -1; x <= 1; x++) {
		vec2 g = vec2(float(x), float(y));
		vec2 o = vec2(hash(i + g), hash(i + g + 17.3));
		float d = length(g + o - f);
		if (d < d1) { d2 = d1; d1 = d; id = hash(i + g + 5.1); } else if (d < d2) d2 = d;
	}
	return vec2(smoothstep(0.0, 0.22, d2 - d1), id);
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
	float rough = 0.24;
	float spec = 0.6;
	float coat = 0.0;
	vec3 nrm = NORMAL;
	if (part == 0 || part == 6 || part == 8) {
		// the skin: rows of low tubercles, longer than wide, a network of
		// fine grooves between them, each its own shade; dark bands along
		// the neck; the foot's fringe paler, grooved down; the sole pale,
		// smooth; all of it wet
		float a = part == 0 ? sc.x : 0.75;
		float ring = rest.x < 0.0 ? a : 2.0 - a; // (round it, unbroken over the back)
		vec2 q = vec2(rest.z / (skin_cell * 1.35), ring * 24.0 + 0.5 * sin(rest.z / skin_cell * 0.4));
		if (part == 6)
			q = rest.yz / skin_cell;
		vec2 cl = tubercles > 0.0 ? cells(q) : vec2(1.0, 0.5);
		float fade = clamp(1.0 - length(fwidth(q)) / 0.9, 0.0, 1.0);
		float top = mix(1.0, cl.x, fade);
		float sole = 1.0 - smoothstep(0.12, 0.22, a);
		float rim = smoothstep(0.15, 0.24, a) * (1.0 - smoothstep(0.42, 0.52, a));
		float skin = (1.0 - sole) * (1.0 - rim * 0.7);
		c = body_color * (0.86 + 0.28 * cl.y * fade);
		// (paler low on its sides, warmer and darker up its back)
		c = mix(c, mix(c, sole_color, 0.55), 1.0 - smoothstep(0.45, 0.7, a));
		float bnd = smoothstep(0.66, 0.74, a) * (1.0 - smoothstep(0.86, 0.94, a));
		bnd *= ramp(tail_z * 0.5, neck.z * 0.5, rest.z) * (0.7 + 0.3 * cl.y);
		c = mix(c, band_color, bnd * band);
		c = mix(c, body_dark, (1.0 - top) * tubercles * skin * 0.85);
		nrm = bump(nrm, VERTEX, top * skin_cell * 0.05 * tubercles * fade * skin, 1.0);
		// the fringe: fine grooves down it
		float gz = rest.z / (skin_cell * 0.45);
		float groove = smoothstep(0.75, 1.0, abs(sin(gz * 3.1416))) * clamp(1.0 - fwidth(gz) * 1.5, 0.0, 1.0);
		c = mix(c, mix(sole_color, body_color, 0.35), rim * 0.75);
		c *= 1.0 - 0.3 * groove * rim;
		c = mix(c, sole_color, sole);
		// (the head greyer, toward the tentacles)
		c = mix(c, tentacle_color, ramp(neck.z * 1.25, snout_z, rest.z) * 0.4 * (1.0 - sole));
		if (part == 6) { // (the mantle: the body's skin up into the shell, smoother, greyer, mottled; its collar pale)
			float mot = vnoise(rest.yz / skin_cell * 2.2) * 0.6 + vnoise(rest.xy / skin_cell * 5.0) * 0.4;
			vec2 mc = cells(vec2(rest.z, rest.y * 0.8 + rest.x * 0.6) / (skin_cell * 1.35));
			float up = smoothstep(0.05, 0.3, sc.x);
			vec3 low = mix(body_dark, body_color * (0.86 + 0.28 * mc.y), mix(1.0, mc.x, tubercles * 0.85));
			c = mix(low, mix(body_color, tentacle_color, 0.35) * (0.62 + 0.4 * mot), up);
			if (sc.y > 0.5)
				c = mix(sole_color, body_color, 0.7) * (0.6 + 0.25 * mot);
			nrm = NORMAL;
		}
		if (part == 8) // (the breathing pore: opening, closing)
			c = mix(body_dark * 0.6, vec3(0.03), smoothstep(-0.2, 0.6, sin(TIME * 0.35 + rest.x * 3000.0)));
		SSS_STRENGTH = body_sss;
		BACKLIGHT = c * 0.35 * body_sss;
		coat = 0.3;
	}
	if (part >= 2 && part <= 5) {
		// a tentacle: see-through, grey, darker along its middle (the
		// muscle that draws it in), its bulb paler; the eye a black dot
		float along = sc.x;
		float facing = abs(dot(normalize(nrm), normalize(VIEW)));
		c = mix(mix(mix(body_color, tentacle_color, 0.5), tentacle_color, smoothstep(0.0, 0.12, along)), tentacle_color * 1.25, smoothstep(0.85, 1.0, along));
		c *= mix(1.15, 0.72, smoothstep(0.3, 0.95, facing));
		if (sc.y > 0.5) { // (an eye)
			c = vec3(0.012);
			rough = 0.08;
		}
		SSS_STRENGTH = body_sss;
		BACKLIGHT = c * 0.6;
		coat = 0.4;
	}
	if (part == 7) {
		float whorl = sc.x;
		float ph = sc.y;
		float rel = pow(shell_grow, whorl - shell_whorls); // (this whorl's size, a share of the last's)
		// growth ribs across the tube, close and sharp (as many a whorl all
		// the way in: finer toward the apex); each its own shade
		float g = whorl * ribs + 0.35 * sin(whorl * 23.0);
		float gi = floor(g);
		float rib = pow(0.5 + 0.5 * cos((fract(g) - 0.5) * 6.2832), 1.6);
		float fade = clamp(1.0 - fwidth(g) * 1.3, 0.0, 1.0);
		c = shell_base * (0.92 + 0.16 * hash(vec2(gi, 5.3)) * fade);
		c = mix(c, c * vec3(0.8, 0.74, 0.62), 0.6 * vnoise(vec2(whorl * 7.0, ph * 5.0)) * step(0.5, flames)); // (the horn clouded, browner in places)
		if (flames > 0.0) {
			// the flames: blotches across the whorl, slanting back, broken
			// round it into rows (on the shoulder, round the outside,
			// beneath), each row's set a little off the last's: a zigzag;
			// their edges ragged, some missing, each its own width
			float pb = fract(ph + 0.12) * 5.0;
			float bi = floor(pb);
			float bf = fract(pb);
			float fl = 0.0;
			float ragged = 0.2 * (vnoise(vec2(whorl * flames * 6.0, ph * 30.0)) - 0.5);
			for (int k = 0; k < 2; k++) {
				float b = mod(bi + float(k), 5.0);
				float off = (mod(b, 2.0) < 0.5 ? 0.0 : 0.3) + 0.2 * hash(vec2(b, 2.0));
				float fz = whorl * flames + off + 1.5 * ph;
				float idx = floor(fz);
				float w = mix(0.16, 0.46, hash(vec2(idx, b * 7.0 + 3.1)));
				float f = fract(fz) + ragged;
				float m = smoothstep(0.0, 0.05, f) * smoothstep(w + 0.05, w - 0.03, f);
				m *= smoothstep(0.15, 0.45, hash(vec2(idx, b * 3.0 + 9.7))); // (some faint, some missing)
				fl += m * (k == 0 ? 1.0 - smoothstep(0.7, 1.0, bf) : smoothstep(0.7, 1.0, bf));
			}
			fl *= smoothstep(apex_whorls - 0.3, apex_whorls + 0.4, whorl);
			fl *= 1.0 - 0.35 * smoothstep(0.55, 0.7, ph) * (1.0 - smoothstep(0.85, 0.95, ph)); // (fainter beneath)
			vec3 fc = shell_flame * (0.75 + 0.5 * vnoise(vec2(whorl * 40.0, ph * 9.0)));
			c = mix(c, fc, clamp(fl, 0.0, 1.0) * 0.92);
		}
		c = mix(shell_apex, c, smoothstep(apex_whorls * 0.6, apex_whorls, whorl));
		c *= mix(1.0, 0.72 + 0.4 * rib, fade * min(rib_depth, 1.0));
		nrm = bump(nrm, VERTEX, rib * 0.00014 * rel * rib_depth * fade, 1.0);
		c = mix(c, lip_color, smoothstep(0.35, 0.85, lipv));
		// (the sutures, the umbilicus: in shadow, grimed)
		c *= mix(0.3, 1.0, smoothstep(0.0, 0.8, open_k));
		rough = mix(0.65, 0.14, shell_gloss);
		rough = mix(0.7, rough, smoothstep(0.1, 0.9, open_k));
		spec = 0.55;
		coat = 0.6 * shell_gloss;
		if (glassy > 0.0) { // (see-through: light through it, the body's shadow in it)
			BACKLIGHT = c * 0.6 * glassy;
			float inside = vnoise(vec2(whorl * 9.0, ph * 6.0));
			c = mix(c, mix(shell_apex, c, 0.55), glassy * 0.5 * (1.0 - drawn_in) * smoothstep(shell_whorls - 1.1, shell_whorls - 0.5, whorl) * (0.5 + 0.5 * inside));
			AO = mix(1.0, 0.8 + 0.2 * open_k, glassy);
		}
		if (!FRONT_FACING) { // (its inside, pearly)
			c = shell_inner * 0.6;
			rough = 0.25;
			coat = 0.0;
		}
	}
	if (part == 9) { // (the epiphragm: dried mucus, papery white)
		c = vec3(0.86, 0.85, 0.8) * (0.9 + 0.1 * vnoise(rest.xz * 9000.0));
		rough = 0.8;
		spec = 0.3;
	}
	NORMAL = nrm;
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = spec;
	CLEARCOAT = coat;
	CLEARCOAT_ROUGHNESS = 0.12;
}
