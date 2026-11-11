shader_type spatial;

// Hard ticks (Ticks: the blacklegged tick, the lone star tick): every tick
// one instance of one mesh, posed here (as the ants are: ant.gdshader),
// from the clock and its own few numbers (INSTANCE_CUSTOM: x how fast it
// walks, 0..1; y questing (0..1: its front legs up and out, waving, to
// catch a host going by) less laying (0..1: its mouthparts down, its egg
// mass growing before it); z its own random 0..1; w its stage and its
// fill: its whole part the stage (0 larva, 1 nymph, 2 male, 3 female; +4
// dead: its legs curled under it, shrivelled; 8 gone: on a host, drawn
// there instead, TickLoad), its fraction how engorged (0 flat .. 1 a
// swollen grape of blood)).
//
// The mesh (Ticks._build_mesh) an unfed adult female standing, in metres,
// the ground under its middle at the origin, facing -z; CUSTOM0.x its
// part: 0 the body (the idiosoma: the alloscutum, its soft leathery back,
// that swells), 1 the female's (and the young's) small scutum, its shield,
// 4 the male's conscutum (his whole back), 2 the mouthparts (the capitulum:
// palps and hypostome), 3 the eyes (the lone star's, at the scutum's
// edges), 8-15 the legs (8 + pair * 2 + side; pair 3, the fourth, the
// larva has none), .y a leg's segment (0 coxa .. 3 tarsus), .z along it.

uniform vec3 hips[8];
uniform vec3 leg_dirs[8];
uniform vec3 body_c;       // the body's middle (its swelling's)
uniform vec3 body_half;    // its half sizes, unfed
uniform float stride_hz = 2.2;
uniform bool attached = false; // (on a host: its legs splayed, gripping, its mouthparts in)

uniform vec3 scutum_color : source_color = vec3(0.1, 0.06, 0.04);
uniform vec3 body_color : source_color = vec3(0.6, 0.16, 0.07);
uniform vec3 nymph_color : source_color = vec3(0.55, 0.52, 0.48);
uniform vec3 larva_color : source_color = vec3(0.62, 0.5, 0.4);
uniform vec3 fed_color : source_color = vec3(0.45, 0.42, 0.42); // (half fed)
uniform vec3 full_color : source_color = vec3(0.4, 0.38, 0.42); // (full)
uniform vec3 full_pattern : source_color = vec3(0.6, 0.55, 0.5); // (its pale marbling, full)
uniform float pattern_k = 0.4;
uniform vec3 leg_color : source_color = vec3(0.12, 0.07, 0.05);
uniform vec3 leg_band : source_color = vec3(0.12, 0.07, 0.05);
uniform vec3 male_color : source_color = vec3(0.17, 0.1, 0.07);
uniform vec3 male_mark : source_color = vec3(0.75, 0.68, 0.6);
uniform float male_rim = 1.0;  // (his pale rim: the blacklegged male's)
uniform float male_streaks = 0.0; // (pale streaks at his back edge: the lone star's)
uniform vec3 spot_color : source_color = vec3(0.95, 0.75, 0.6);
uniform float spot = 0.0;      // (the lone star female's white spot)
uniform float festoons = 0.0;  // (the scalloped rear margin: the lone star's)
uniform float punctate = 0.5;  // (the scutum's pits)

varying flat int part;
varying vec3 rest;
varying flat float stage;
varying float fill;
varying flat float dead;
varying float seg_along;
varying flat int seg;

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
	seg = int(round(CUSTOM0.y));
	seg_along = CUSTOM0.z;
	rest = VERTEX;
	float walk = INSTANCE_CUSTOM.x;
	float quest = max(INSTANCE_CUSTOM.y, 0.0);
	float lay = max(-INSTANCE_CUSTOM.y, 0.0);
	float seed = INSTANCE_CUSTOM.z;
	float w = INSTANCE_CUSTOM.w;
	float st = floor(w);
	float e = fract(w) / 0.999;
	dead = st >= 4.0 && st < 8.0 ? 1.0 : 0.0;
	if (dead > 0.5) st -= 4.0;
	stage = st;
	if (st > 2.5 && dead > 0.5) e = min(e, 0.35); // (spent: shrivelled)
	if (st == 2.0) e *= 0.15; // (a male hardly swells)
	fill = e;
	float t = TIME + seed * 41.0;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	vec3 up = vec3(0.0, 1.0, 0.0);
	// its shield: the male's whole back, or the small one
	if ((part == 4 && st != 2.0) || (part == 1 && st == 2.0))
		v = body_c;
	// the larva: six legs (no fourth pair)
	if (part >= 14 && part <= 15 && st == 0.0)
		v = hips[part - 8];
	// engorging: its soft back swelling, back and up, round as a grape;
	// the shield and the head left as they were, small at its front
	float grow = e * e * (3.0 - 2.0 * e);
	if (part == 0) {
		vec3 q = v - body_c;
		float front = -body_half.z * 0.75;
		float back = max(q.z - front, 0.0);
		q.x *= 1.0 + 1.6 * grow;
		q.z = q.z + back * 1.9 * grow;
		q.y = q.y * (1.0 + 5.0 * grow) + body_half.y * 2.2 * grow;
		v = body_c + q;
		n = normalize(vec3(n.x / (1.0 + 1.6 * grow), n.y / (1.0 + 5.0 * grow), n.z));
	}
	if (part == 1 || part == 2 || part == 3) // (lifted on its swollen back, its front tipped down)
		v.y += body_half.y * 1.6 * grow;
	// the legs: walking (alternating: 1L 2R 3L 4R, then the others), the
	// front pair questing (up and out, waving); dead, curled in under it
	if (part >= 8 && part <= 15) {
		int i = part - 8;
		float side = (i % 2 == 1) ? 1.0 : -1.0;
		int pair = i / 2;
		vec3 o = hips[i];
		vec3 outw = leg_dirs[i];
		vec3 across = normalize(cross(up, outw));
		bool set_a = (pair % 2 == 0) == (side < 0.0);
		float p = fract(t * stride_hz * mix(0.6, 1.0, walk) + (set_a ? 0.0 : 0.5));
		float sw = 0.35 * walk;
		float ang = p < 0.5 ? mix(-sw, sw, smoothstep(0.0, 1.0, p * 2.0)) : mix(sw, -sw, (p - 0.5) * 2.0);
		float lift = p < 0.5 ? sin(3.14159 * p * 2.0) * walk : 0.0;
		if (pair == 0 && quest > 0.0) { // (questing: up and out, waving slowly)
			lift += quest * (1.6 + 0.15 * sin(t * 2.1 + side));
			ang += quest * (0.25 * side * -1.0 + 0.3 * sin(t * 1.3 + side * 1.7));
		}
		if (attached) { // (splayed flat, gripping)
			lift -= 0.25;
		}
		if (grow > 0.0) // (the legs splayed out from under the swollen body)
			lift += 0.25 * grow;
		if (dead > 0.5) // (curled under it)
			lift -= 1.1 * float(seg) * 0.4;
		turn(v, n, o, across, -0.6 * lift);
		turn(v, n, o, up, ang * side);
	}
	// the mouthparts: probing the air questing, down laying (its egg mass
	// pushed out before it); the whole tipped forward to bite on a host
	if (part == 2 || part == 3) {
		vec3 o = vec3(0.0, body_c.y, body_c.z - body_half.z * 0.9);
		turn(v, n, o, vec3(1.0, 0.0, 0.0), -0.5 * lay + 0.08 * quest * sin(t * 3.0) - (attached ? 0.4 : 0.0));
	}
	// questing: the front of it raised a little
	if (quest > 0.0) {
		turn(v, n, vec3(0.0, 0.0, body_c.z + body_half.z * 0.5), vec3(1.0, 0.0, 0.0), 0.25 * quest);
	}
	// its size by its stage
	float sz = st == 0.0 ? 0.22 : (st == 1.0 ? 0.45 : 1.0);
	v *= sz;
	if (w >= 8.0) // (gone, on a host: not drawn here)
		v = vec3(0.0, -1000.0, 0.0);
	VERTEX = v;
	NORMAL = normalize(n);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec3 c = body_color;
	float rough = 0.55;
	float spec = 0.45;
	vec3 q = (rest - body_c) / body_half; // (where on its body, unfed: -1..1)
	if (stage == 1.0) c = nymph_color;
	if (stage == 0.0) c = larva_color;
	if (part == 0) {
		// its soft back: finely wrinkled leather; engorging, tan, then
		// grey, then slate, marbled pale, glossy and taut
		float wr = noise(rest.xz * 9000.0);
		c *= 0.85 + 0.3 * wr;
		if (fill > 0.0) {
			vec3 f = mix(fed_color, full_color, smoothstep(0.5, 1.0, fill));
			c = mix(c, f, smoothstep(0.05, 0.5, fill));
			// the pale marbling: down its middle and out along its sides,
			// branching (the gut's caeca showing through)
			float mx = abs(q.x);
			float br = noise(vec2(q.x * 3.0, q.z * 4.0) + 7.0) * 0.6 + 0.4 * sin(q.z * 9.0 + mx * 6.0);
			float pale = smoothstep(0.55, 0.85, br) * smoothstep(0.3, 0.9, fill) * pattern_k;
			c = mix(c, full_pattern, pale);
			// its pores: fine dark specks
			float sp_ = step(0.92, hash(floor(rest.xz * 30000.0)));
			c *= 1.0 - 0.25 * sp_ * smoothstep(0.4, 1.0, fill);
			rough = mix(0.55, 0.22, fill);
			spec = 0.6;
		}
		// the festoons: the scalloped margin at its back
		if (festoons > 0.0 && q.z > 0.35 && fill < 0.5) {
			float a = atan(q.x, q.z);
			float sc = 0.5 + 0.5 * cos(a * 11.0 * 3.14159 / 1.6);
			c *= 1.0 - festoons * 0.35 * smoothstep(0.75, 0.95, length(q.xz)) * sc;
		}
		if (q.y < -0.3) c *= 0.75; // (beneath, darker)
	}
	if (part == 1) {
		c = scutum_color;
		if (spot > 0.0 && stage == 3.0) { // (the lone star: one white spot at its tip)
			float d = length((rest.xz - vec2(body_c.x, body_c.z - body_half.z * 0.06)) / vec2(body_half.x * 0.24, body_half.z * 0.2));
			c = mix(c, spot_color, (1.0 - smoothstep(0.8, 1.0, d)) * spot);
		}
		rough = 0.4;
		spec = 0.55;
	}
	if (part == 4) {
		c = male_color;
		float rim = smoothstep(0.78, 0.95, length(q.xz * vec2(1.0, 1.0)));
		c = mix(c, male_mark, rim * male_rim);
		if (male_streaks > 0.0) { // (pale streaks at his back edge, a spot or two on his shoulders)
			float s1 = smoothstep(0.55, 0.7, q.z) * (1.0 - smoothstep(0.08, 0.14, abs(abs(q.x) - 0.45)));
			float s2 = (1.0 - smoothstep(0.1, 0.16, length(vec2(abs(q.x) - 0.55, q.z + 0.45))));
			c = mix(c, male_mark, max(s1, s2) * male_streaks);
		}
		rough = 0.4;
		spec = 0.55;
	}
	if (part == 1 || part == 4) { // (its shield finely pitted)
		float pit = step(0.82, hash(floor(rest.xz * 26000.0)));
		c *= 1.0 - punctate * 0.4 * pit;
	}
	if (part == 2)
		c = mix(scutum_color, leg_color, 0.5);
	if (part == 3) {
		c = vec3(0.85, 0.75, 0.4);
		rough = 0.2;
	}
	if (part >= 8) { // (the legs: banded pale at each joint, some kinds)
		c = leg_color;
		float band = smoothstep(0.82, 0.95, seg_along) + (1.0 - smoothstep(0.0, 0.08, seg_along));
		c = mix(c, leg_band, clamp(band, 0.0, 1.0));
		rough = 0.45;
	}
	if (dead > 0.5) c *= 0.8;
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = spec;
}
