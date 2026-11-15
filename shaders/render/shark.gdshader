shader_type spatial;
render_mode cull_disabled;

// A great white shark (GreatWhiteShark): one mesh (GreatWhiteShark.build),
// life size (a grown female's, 4.6 m; the node scaled for a male, a pup),
// facing -z, posed here from its motor's numbers.
//
// CUSTOM0: x its part (0 the body, 1 an eye, 2 the first dorsal, 3 the
// second dorsal, 4 the anal fin, 5 the tail, 6 the left pectoral, 7 the
// right, 8 a pelvic, 9 an upper tooth, 10 a lower tooth, 11 a clasper, 12 a
// keel), y how far along the body it is (0 the snout .. 1 the tail's root:
// the wave's), z round it or out along a fin (0 its root .. 1 its tip), w
// across a fin (0 its leading edge .. 1 its trailing). CUSTOM1: x how much
// it goes with the lower jaw, y with the upper (its gum, its teeth thrown
// forward), z with the head (raised as it bites), w its side (-1 left, 1
// right: a pectoral's, a pelvic's, a clasper's).
//
// - swimming: a lamnid's beat, nearly all in its tail (its body stiff, its
//   head yawing a little against it); the body bent into a turn; arched
//   (its back humped: a threat); the tail fin turned with the stalk
// - its bite: its snout lifted, its lower jaw dropped, its upper jaw thrown
//   forward and down out from under the snout, its eyes rolled back white;
//   then the jaws shut
// - its gills flaring; its pectorals angled (planing, braking, held down in
//   a threat); a male's claspers swung forward (mating)

uniform float phase = 0.0;      // the beat's (rad: the motor keeps it, so it never jumps with the pace)
uniform float amp = 0.12;       // the tail's sweep (m, the mesh's)
uniform float bend = 0.0;       // the body curved into a turn (-1 .. 1)
uniform float arch = 0.0;       // its back humped (0 .. 1)
uniform float jaw = 0.0;        // the lower jaw dropped (0 .. 1)
uniform float protrude = 0.0;   // the upper jaw thrown forward (0 .. 1)
uniform float snout = 0.0;      // the snout lifted (0 .. 1)
uniform float eye_roll = 0.0;   // its eyes rolled back (0 .. 1: white)
uniform float gill = 0.0;       // its gill slits flared (0 .. 1)
uniform float pec = 0.0;        // its pectorals held down (rad; negative: up, braking)
uniform float clasp = 0.0;      // a male's claspers swung forward (0 .. 1)
uniform vec3 jaw_pivot = vec3(0.0, -0.08, -1.42);
uniform vec3 snout_pivot = vec3(0.0, 0.05, -1.3);
uniform vec3 pec_root[2];       // each pectoral's root (front), its axis (along the root) the next
uniform vec3 pec_axis[2];
uniform vec3 clasp_root = vec3(0.07, -0.25, 0.6);
uniform float z_snout = -2.3;
uniform float z_stalk = 1.45;
uniform vec3 dorsal_color : source_color = vec3(0.4, 0.43, 0.45);
uniform vec3 belly_color : source_color = vec3(0.92, 0.92, 0.9);
uniform float pup = 0.0;        // (a pup's: the black tips of its pectorals, beneath)
uniform float scars = 0.4;      // (how scarred: old bite marks, scratches)
uniform float mating_scars = 0.0; // (a female's: his bites, on her flanks and pectorals)
uniform float seed = 0.3;

varying float v_part;
varying vec3 v_rest;
varying vec3 v_rn;
varying vec4 v_c;
varying float v_side;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void turn(inout vec3 v, inout vec3 n, vec3 o, vec3 axis, float a) {
	vec3 k = normalize(axis);
	float c = cos(a);
	float s = sin(a);
	vec3 p = v - o;
	v = o + p * c + cross(k, p) * s + k * dot(k, p) * (1.0 - c);
	n = n * c + cross(k, n) * s + k * dot(k, n) * (1.0 - c);
}

// the wave's sideways reach at s (0 the snout .. 1 the tail's root): a
// lamnid's, its body stiff, all in its tail; its head yawing a little
float wave(float s) {
	float env = 0.05 + 0.95 * pow(smoothstep(0.42, 1.0, s), 1.5);
	return amp * env * sin(4.2 * s - phase) - amp * 0.08 * (1.0 - smoothstep(0.0, 0.35, s)) * sin(phase);
}

void vertex() {
	int part = int(round(CUSTOM0.x));
	v_part = float(part);
	v_c = CUSTOM0;
	v_side = CUSTOM1.w;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	v_rest = VERTEX;
	v_rn = NORMAL;
	// the bite: the lower jaw dropped, the upper thrown forward, the snout lifted
	if (CUSTOM1.x > 0.0)
		turn(v, n, jaw_pivot, vec3(1.0, 0.0, 0.0), -0.85 * jaw * CUSTOM1.x);
	if (CUSTOM1.y > 0.0)
		v += vec3(0.0, -0.075, -0.07) * protrude * CUSTOM1.y;
	if (CUSTOM1.z > 0.0)
		turn(v, n, snout_pivot, vec3(1.0, 0.0, 0.0), 0.26 * snout * CUSTOM1.z);
	// the pectorals: down (a threat, steering), up (braking)
	if (part == 6 || part == 7) {
		int k = part - 6;
		float side = k == 1 ? 1.0 : -1.0;
		turn(v, n, pec_root[k], pec_axis[k], -side * pec * CUSTOM0.z);
	}
	if (part == 11) // (a clasper swung forward and out)
		turn(v, n, clasp_root * vec3(sign(CUSTOM1.w), 1.0, 1.0), vec3(1.0, 0.0, 0.0), 1.1 * clasp);
	// the body: its wave, its turn, its arch
	float L = z_stalk - z_snout;
	float s = clamp((VERTEX.z - z_snout) / L, 0.0, 1.0);
	float w = wave(s);
	float slope = (wave(1.0) - wave(0.97)) / (0.03 * L);
	float past = max(VERTEX.z - z_stalk, 0.0);
	float dx = w + past * slope + bend * s * s * 0.55;
	v.x += dx;
	v.y += arch * 0.12 * sin(3.1416 * s) - arch * 0.1 * past;
	// (its normals turned with the bend)
	float ang = atan(slope + bend * 2.0 * s * 0.55 / L) * smoothstep(0.4, 1.0, s);
	n = normalize(vec3(n.x * cos(ang) + n.z * sin(ang), n.y, -n.x * sin(ang) + n.z * cos(ang)));
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

// (where the grey above meets the white below, as a height on the side: -1
// the belly's middle .. 1 the back's; along it, s)
float border(float s) {
	float b = -0.15;
	b = mix(b, -0.55, smoothstep(0.08, 0.16, s)); // (dipping under the eye to the mouth's corner)
	b = mix(b, -0.15, smoothstep(0.2, 0.3, s));   // (up over the gills)
	b = mix(b, 0.05, smoothstep(0.32, 0.5, s));   // (along the flank's middle)
	b = mix(b, -0.3, smoothstep(0.62, 0.78, s));  // (down behind the pelvics)
	b = mix(b, 0.15, smoothstep(0.85, 1.0, s));   // (the stalk's lower half white)
	return b;
}

void shade(bool front, vec3 vtx, vec3 up_v, inout vec3 nrm, out vec3 c, out float rough, out float spec, out float sss) {
	int part = int(round(v_part));
	vec3 rp = v_rest;
	float s = v_c.y;
	c = dorsal_color;
	rough = 0.42;
	spec = 0.45;
	sss = 0.0;
	if (!front && part == 0) { // (the inside, seen through its open mouth: its gums, its throat)
		float ridge = 0.5 + 0.5 * sin(rp.z * 140.0 + vnoise(rp.xz * 30.0) * 2.0);
		c = mix(vec3(0.22, 0.06, 0.06), vec3(0.4, 0.16, 0.16), ridge * 0.5) * mix(0.08, 0.9, smoothstep(-1.5, -2.0, rp.z)); // (dark deep in)
		rough = 0.5;
		spec = 0.4;
		return;
	}
	if (part == 1) { // the eye: black, round, wet; rolled back, its white
		float k = dot(normalize(v_rn), vec3(sign(rp.x), 0.0, 0.0));
		c = mix(vec3(0.015), vec3(0.06, 0.06, 0.07), smoothstep(0.75, 0.95, k));
		c = mix(c, vec3(0.82, 0.8, 0.78) * mix(0.8, 1.0, k), eye_roll);
		rough = 0.08;
		spec = 0.8;
		return;
	}
	if (part == 9 || part == 10) { // a tooth: ivory, its edges serrated, its tip translucent
		float t = v_c.z;
		c = mix(vec3(0.93, 0.9, 0.82), vec3(0.98, 0.97, 0.94), t);
		c *= 1.0 - 0.25 * step(0.85, fract(v_c.w * 30.0 + t * 3.0)) * smoothstep(0.2, 0.6, abs(v_c.w - 0.5) * 2.0);
		c = mix(c * 0.55, c, smoothstep(0.0, 0.25, t)); // (its root in the gum)
		rough = 0.25;
		spec = 0.6;
		sss = 0.2;
		return;
	}
	// the skin: grey above, white below, their meeting ragged
	float h = 0.0; // (height on the side: -1 .. 1)
	if (part == 0) {
		h = cos(v_c.z * 6.2832);
		// (ragged: blotches, tongues of grey down into the white, white up into the grey; no regular teeth)
		float b = border(s) + 0.16 * (vnoise(vec2(s * 26.0, 3.1 + seed * 9.0)) - 0.5) + 0.09 * (vnoise(vec2(s * 75.0, h * 4.0 + 7.7)) - 0.5) + 0.04 * (vnoise(vec2(s * 220.0, h * 12.0)) - 0.5);
		float white = 1.0 - smoothstep(b - 0.012, b + 0.012, h);
		c = mix(dorsal_color * (0.92 + 0.1 * vnoise(rp.zy * 9.0)), belly_color, white);
		c *= mix(1.0, 0.82, smoothstep(0.55, 1.0, h)); // (darkest along the back)
		// (smudges of grey just over the border, and below it here and there)
		float smudge = smoothstep(0.62, 0.8, vnoise(vec2(s * 40.0, h * 9.0 + seed * 30.0))) * (1.0 - smoothstep(0.0, 0.35, abs(h - b)));
		c = mix(c, dorsal_color * 0.85, smudge * 0.6);
		// the gill slits: five, curving down each side ahead of the pectoral
		float gz = (rp.z + 1.47) / 0.085;
		float gi = floor(gz + 0.5);
		if (gi >= 0.0 && gi <= 4.0 && h > -0.62 + gi * 0.03 && h < 0.22 - gi * 0.02) { // (low on the side, the last the shortest)
			float off = abs(gz - gi - 0.06 * h * h);
			float slit = 1.0 - smoothstep(0.02 + 0.07 * gill, 0.05 + 0.1 * gill, off);
			float lip = (1.0 - smoothstep(0.05, 0.16, off)) * (1.0 - slit); // (the flap's edge ahead of it, a little raised)
			c = mix(c, mix(vec3(0.07, 0.07, 0.08), vec3(0.38, 0.1, 0.1), smoothstep(0.4, 0.9, gill) * 0.7), slit * 0.92);
			c *= 1.0 - 0.12 * lip;
			nrm = bump(nrm, vtx, (lip - slit) * 0.004, 1.0);
		}
		// the black spot under the pectoral's root, behind
		float ax = length(vec2((rp.z + 0.68) / 0.04, (h + 0.66) / 0.04));
		c = mix(c, vec3(0.04), (1.0 - smoothstep(0.8, 1.1, ax))); // (the black spot in the pectoral's armpit, beneath)
		// the snout: its pores (the ampullae), its nostrils beneath
		float sn = 1.0 - smoothstep(0.12, 0.2, s);
		vec2 pc = rp.xz * 160.0 + rp.y * 80.0;
		float pore = step(0.9, hash(floor(pc))) * (1.0 - smoothstep(0.15, 0.3, length(fract(pc) - 0.5)));
		c *= 1.0 - 0.3 * pore * sn * (1.0 - smoothstep(-0.1, 0.4, h));
		float nost = 1.0 - smoothstep(0.0, 0.012, length(vec2(abs(rp.x) - 0.08, rp.z + 2.13)) - 0.01);
		c = mix(c, vec3(0.05), nost * step(h, -0.3));
		// old scars: pale scratches and dark-edged bites, and the female's from him
		float sc = 0.0;
		for (int k = 0; k < 6; k++) {
			float fk = float(k) + seed * 13.0;
			vec2 at = vec2(0.25 + 0.6 * hash(vec2(fk, 1.0)), -0.2 + 0.7 * hash(vec2(fk, 2.0)));
			vec2 dir = normalize(vec2(1.0, (hash(vec2(fk, 3.0)) - 0.5) * 1.5));
			vec2 q = vec2(s, h * 0.18) - vec2(at.x, at.y * 0.18);
			float along = dot(q, dir);
			float across = dot(q, vec2(-dir.y, dir.x));
			sc = max(sc, (1.0 - smoothstep(0.0008, 0.002, abs(across))) * (1.0 - smoothstep(0.006, 0.022, abs(along))) * step(float(k), scars * 6.0) * (0.5 + 0.5 * vnoise(vec2(along * 400.0, fk))));
		}
		c = mix(c, mix(c, vec3(0.8, 0.79, 0.78), 0.45), sc);
		float ms = mating_scars * smoothstep(0.6, 0.9, vnoise(vec2(s * 90.0, h * 25.0))) * smoothstep(0.3, 0.55, s) * (1.0 - smoothstep(0.6, 0.72, s)) * smoothstep(-0.4, 0.1, h);
		c = mix(c, vec3(0.7, 0.45, 0.42), ms * 0.7);
	} else if (part == 6 || part == 7) { // a pectoral: grey above; white beneath, its trailing edge and tip dark (a pup's black)
		bool under = dot(nrm, up_v) < 0.0; // (its normal, already turned to face the eye on either side, against its own up, rolled as it is)
		float span = v_c.z;
		float trail = v_c.w;
		if (under) {
			c = belly_color;
			c = mix(c, vec3(0.12), smoothstep(0.82, 0.97, trail) * 0.7 + smoothstep(0.78, 0.95, span) * mix(0.55, 1.0, pup));
		} else {
			c = dorsal_color * 0.95;
			c = mix(c, dorsal_color * 0.6, smoothstep(0.85, 1.0, trail) * 0.6);
		}
		c = mix(c, vec3(0.75, 0.5, 0.48), mating_scars * smoothstep(0.5, 0.85, vnoise(vec2(span * 30.0, trail * 20.0))) * 0.5);
	} else { // the other fins, the keels, a clasper: grey, darker to their trailing edges and tips
		c = dorsal_color * (0.9 + 0.08 * vnoise(rp.zy * 25.0));
		if (part == 2 || part == 5)
			c = mix(c, dorsal_color * 0.55, smoothstep(0.8, 1.0, v_c.w) * 0.7 + smoothstep(0.85, 1.0, v_c.z) * 0.3);
		if (part == 8 || part == 4 || part == 11) // (beneath: paler)
			c = mix(c, belly_color * 0.9, 0.55);
	}
	// its skin: fine denticles, a soft sheen
	float den = vnoise(rp.xz * 900.0 + rp.y * 400.0) * 0.6 + vnoise(rp.zy * 2300.0) * 0.4;
	nrm = bump(nrm, vtx, den * 0.00025, 1.0);
	c *= 0.96 + 0.06 * den;
}

void fragment() {
	vec3 nrm = NORMAL;
	vec3 c;
	float rough;
	float spec;
	float sss;
	shade(FRONT_FACING, VERTEX, normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz), nrm, c, rough, spec, sss);
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = spec;
	SSS_STRENGTH = sss;
	NORMAL = nrm;
}
