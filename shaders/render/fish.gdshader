shader_type spatial;
render_mode cull_disabled;

// Fish in schools (FishSchool: the Chinook salmon, the rainbow trout, the
// Atlantic bluefin tuna), as the mollies are (molly.gdshader): every fish
// one instance of one mesh, posed here from the clock and its own numbers,
// a school a draw call. INSTANCE_CUSTOM: x how fast it swims (0..1), y how
// hard it's turning (-1..1), z its own random, w its mouth open (0..1:
// feeding, rising to take a fly, a strike).
//
// The mesh (FishSchool.build_mesh) at rest, life size, metres, facing -z,
// its snout at z_head, its tail fin's edge at z_tail. CUSTOM0: x the part
// (0 the body, 1 an eye, 2 its pupil, 3 the (first) dorsal fin, 4 the
// adipose fin or the second dorsal, 5 the tail fin, 6/7 the pectorals, 8/9
// the pelvics, 10 the anal fin, 11 a finlet, 12 the lower jaw, 13 a keel),
// y a fin's way out from its base (0..1), z along its base (0..1).
// - swimming: a salmon's and a trout's wave down the body (stiff the head,
//   the tail sweeping), a tuna's beat all in its tail (the body nearly
//   still: stiff, 0..1, how much of the body's held); faster and wider the
//   faster it swims; the body curved into a turn
// - the pectorals sculling slow, laid back fast; the jaw opening (and the
//   gill covers flaring a little) as it feeds, and breathing
// species: 0 Chinook salmon (variant 1: spawning), 1 rainbow trout (1: a
// steelhead), 2 Atlantic bluefin tuna.

uniform int species = 0;
uniform int variant = 0;
uniform float z_head = -0.45;
uniform float z_tail = 0.45;
uniform float stiff = 0.0;
uniform vec3 pec_pivots[2];
uniform vec3 jaw_pivot = vec3(0.0, -0.01, -0.4);
uniform float spot_cell = 0.012; // m between its spots
uniform float half_h = 0.1; // m, the body's half height (its bands' scale)

varying float v_part;
varying float v_s;
varying float v_t;
varying float v_u;
varying vec3 v_rest;
varying vec3 v_rn;

void turn(inout vec3 v, inout vec3 n, vec3 o, vec3 axis, float a) {
	vec3 k = normalize(axis);
	float c = cos(a);
	float s = sin(a);
	vec3 p = v - o;
	v = o + p * c + cross(k, p) * s + k * dot(k, p) * (1.0 - c);
	n = n * c + cross(k, n) * s + k * dot(k, n) * (1.0 - c);
}

// (the wave's sideways reach at s, head 0 .. tail 1)
float wave_at(float s, float amp, float k, float ph) {
	float env = mix(0.05 + s * s, pow(smoothstep(0.55, 1.0, s), 1.4) * 1.1, stiff);
	return amp * env * sin(k * s - ph);
}

void vertex() {
	int part = int(round(CUSTOM0.x));
	float swim = clamp(INSTANCE_CUSTOM.x, 0.0, 1.0);
	float bend = INSTANCE_CUSTOM.y;
	float seed = INSTANCE_CUSTOM.z;
	float mouth = INSTANCE_CUSTOM.w;
	float t = TIME + seed * 41.0;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	v_rest = VERTEX;
	v_rn = NORMAL;
	// the jaw: open feeding, and a little with each breath
	if (part == 12) {
		float breathe = 0.04 * (0.5 + 0.5 * sin(t * 4.0)) * (1.0 - swim * 0.6);
		turn(v, n, jaw_pivot, vec3(1.0, 0.0, 0.0), -(0.45 * mouth + breathe));
	}
	// the pectorals
	if (part == 6 || part == 7) {
		int s = part - 6;
		float side = s == 1 ? 1.0 : -1.0;
		vec3 o = pec_pivots[s];
		float scull = (1.0 - swim) * 0.35 * sin(t * 5.0 + float(s));
		turn(v, n, o, vec3(0.0, 1.0, 0.0), (0.3 * swim + scull) * side);
	}
	// the tail fin spread with the beat
	if (part == 5)
		v.y *= mix(0.92, 1.03, swim) + 0.02 * sin(t * 3.0);
	// the body's wave
	float L = z_tail - z_head;
	float s = clamp((VERTEX.z - z_head) / L, 0.0, 1.0);
	v_s = s;
	float freq = mix(1.0, 5.0, swim) * mix(1.0, 1.6, stiff);
	float ph = t * freq * 6.2832;
	float amp = L * mix(0.02, 0.085, swim);
	float k = 6.2832 * mix(0.9, 0.55, stiff);
	float dx = wave_at(s, amp, k, ph);
	float slope = (wave_at(s + 0.01, amp, k, ph) - dx) / (0.01 * L);
	float cv = -bend * 0.18 * L * (1.0 - 0.5 * stiff);
	dx += cv * (s - 0.3) * (s - 0.3);
	slope += cv * 2.0 * (s - 0.3) / L;
	v.x += dx;
	n.z -= slope * n.x;
	VERTEX = v;
	NORMAL = normalize(n);
	v_part = CUSTOM0.x;
	v_t = CUSTOM0.y;
	v_u = CUSTOM0.z;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float h31(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

// (spots: black, round, scattered, each its own size)
float spots(vec2 p, float cell, float r) {
	vec2 c = floor(p / cell);
	float best = 9.0;
	for (int x = -1; x <= 1; x++)
		for (int y = -1; y <= 1; y++) {
			vec2 q = c + vec2(float(x), float(y));
			vec2 at = (q + vec2(h21(q), h21(q + 7.1))) * cell;
			best = min(best, length(p - at) / (cell * (0.5 + 0.7 * h21(q + 2.3))));
		}
	return 1.0 - smoothstep(r * 0.75, r, best);
}

void fragment() {
	int part = int(round(v_part));
	float ny = normalize(v_rn).y;
	float hy = v_rest.y / half_h; // (up its side: -1 the belly .. 1 the back)
	vec2 sp = vec2(v_rest.z, v_rest.y);
	vec3 c;
	float metal = 0.0;
	float rough = 0.3;
	vec3 white = vec3(0.9, 0.9, 0.88);
	if (part == 0 || part == 12 || part == 13) {
		if (species == 0) {
			if (variant == 0) { // (the sea: dark blue-green above, silver, white)
				c = mix(vec3(0.72, 0.75, 0.78), vec3(0.17, 0.25, 0.29), smoothstep(-0.05, 0.6, hy));
				c = mix(c, white, 1.0 - smoothstep(-0.75, -0.35, hy));
				metal = 0.55;
			} else { // (spawning: olive and dark maroon, the belly grey)
				c = mix(vec3(0.42, 0.18, 0.14), vec3(0.2, 0.18, 0.12), smoothstep(0.0, 0.7, hy));
				c = mix(c, vec3(0.45, 0.42, 0.4), 1.0 - smoothstep(-0.8, -0.4, hy));
				rough = 0.5;
			}
			float spot = spots(sp, spot_cell, 0.32) * smoothstep(0.05, 0.3, hy);
			c = mix(c, vec3(0.03), spot * 0.85);
		} else if (species == 1) {
			bool steel = variant == 1;
			c = mix(steel ? vec3(0.7, 0.72, 0.72) : vec3(0.62, 0.62, 0.55), steel ? vec3(0.22, 0.3, 0.32) : vec3(0.27, 0.32, 0.18), smoothstep(0.0, 0.65, hy));
			c = mix(c, white, 1.0 - smoothstep(-0.75, -0.35, hy));
			// (its band: pink red along its side; faint on a steelhead)
			float band = 1.0 - smoothstep(0.1, 0.3, abs(hy + 0.05));
			c = mix(c, vec3(0.86, 0.42, 0.46), band * (steel ? 0.25 : 0.7) * smoothstep(0.08, 0.2, v_s));
			float spot = spots(sp, spot_cell, 0.34) * smoothstep(-0.25, 0.1, hy);
			c = mix(c, vec3(0.04), spot * (steel ? 0.5 : 0.9));
			metal = steel ? 0.5 : 0.25;
		} else {
			// (the bluefin: deep metallic navy above, silver white below,
			// faint pale bars and dots down its lower sides)
			c = mix(vec3(0.75, 0.77, 0.8), vec3(0.04, 0.08, 0.2), smoothstep(0.0, 0.5, hy));
			c = mix(c, white, 1.0 - smoothstep(-0.7, -0.3, hy));
			float bars = step(0.6, fract(v_rest.z / 0.07)) * (1.0 - smoothstep(-0.1, 0.1, hy)) * smoothstep(-0.7, -0.4, hy);
			c = mix(c, white, bars * 0.3);
			metal = 0.7;
			rough = 0.22;
			if (part == 13)
				c = vec3(0.05);
		}
		// (the gill cover's edge; the lateral line)
		float gill = 1.0 - smoothstep(0.0, 0.004, abs(v_rest.z - (z_head + (z_tail - z_head) * 0.2 - abs(v_rest.y) * 0.25)));
		c *= 1.0 - 0.35 * gill * (1.0 - smoothstep(0.6, 0.9, abs(hy)));
		c *= 1.0 - 0.15 * (1.0 - smoothstep(0.0, 0.03, abs(hy - 0.1))) * smoothstep(0.2, 0.3, v_s);
		// its scales
		vec2 g = vec2(v_rest.z, v_rest.y) / (spot_cell * 0.2);
		g.x += floor(g.y) * 0.5;
		c *= 0.94 + 0.08 * h21(floor(g));
		if (part == 12 && species == 0 && variant == 1)
			c = mix(c, vec3(0.75, 0.7, 0.6), 0.4); // (a spawner's pale hooked jaw)
	} else if (part == 1) {
		c = species == 2 ? vec3(0.15, 0.15, 0.12) : vec3(0.75, 0.65, 0.35);
		rough = 0.1;
		metal = 0.5;
	} else if (part == 2) {
		c = vec3(0.01);
		rough = 0.05;
	} else {
		// fins
		c = species == 2 ? vec3(0.12, 0.14, 0.2) : (species == 0 && variant == 1 ? vec3(0.18, 0.12, 0.1) : vec3(0.42, 0.42, 0.36));
		float ray = 1.0 - smoothstep(0.1, 0.25, abs(fract(v_u * 10.0) - 0.5));
		c *= 1.0 - 0.2 * ray;
		if (species < 2 && (part == 3 || part == 5 || part == 4)) // (spotted, the salmon's and trout's)
			c = mix(c, vec3(0.03), spots(vec2(v_u * 6.0, v_t * 3.0), 1.0, 0.3) * (part == 4 ? 0.0 : 0.8));
		if (species == 1 && variant == 0 && (part == 8 || part == 9 || part == 10))
			c = mix(c, white, smoothstep(0.85, 0.95, v_t)); // (a trout's white fin edges)
		if (species == 2) {
			if (part == 11) // (the finlets: yellow, edged black)
				c = mix(vec3(0.95, 0.8, 0.15), vec3(0.05), smoothstep(0.8, 0.95, v_t));
			if (part == 3)
				c = vec3(0.45, 0.42, 0.3); // (the first dorsal: grey yellow)
			if (part == 4 || part == 10)
				c = vec3(0.35, 0.22, 0.15); // (the second dorsal, the anal: reddish brown)
		}
		rough = 0.5;
	}
	ALBEDO = c;
	METALLIC = metal;
	ROUGHNESS = rough;
	SPECULAR = 0.6;
	RIM = 0.2;
	if (part >= 3 && part != 12 && part != 13)
		BACKLIGHT = vec3(0.3);
}
