shader_type spatial;
render_mode cull_disabled;

// Sailfin mollies (Mollies): every fish one instance of one mesh, posed
// here in the vertex shader (as the ants are: ant.gdshader), from the clock
// and its own four numbers, so a school of hundreds is a draw call; the CPU
// only moves each fish along. INSTANCE_CUSTOM: x how fast it swims (0..1;
// negative, how far into grazing, 0..-1), y how hard it's turning (-1 left
// .. 1 right), z its own random 0..1 (its beat's phase), w its sex and
// display (a female's 0; a male's 1 + how far his sail is raised, 0..0.99).
//
// The mesh (Mollies.build_mesh) at rest, life size, in metres, facing -z,
// its snout at z_head, its tail fin's edge at z_tail. CUSTOM0: x the part
// (0 the body, 1 an eye, 2 its pupil, 3 a female's dorsal fin, 4 a male's
// sail, 5 the tail fin, 6/7 the pectorals, 8/9 the pelvics, 10 a female's
// anal fin, 11 a male's gonopodium, 12 the lips), y a fin's way out from
// its base (0 .. 1 its edge), z along its base (0 .. 1: its rays), w its
// base's height (a dorsal's, an anal fin's: where it folds down to).
// - swimming: a wave down the body to the tail, faster and wider the
//   faster it goes (the head nearly still, the tail sweeping); turning,
//   the body curved into the turn; the tail fin spread with the sweep
// - hovering: the pectorals sculling, the body barely moving
// - grazing (pecking at the bottom): the head jerking side to side, the
//   lips working
// - a male's sail: half folded as he swims, raised to display, quivering
// A female's dorsal and anal fins are drawn only on her, a male's sail and
// gonopodium on him (the others folded to nothing).

uniform float z_head = -0.028;
uniform float z_tail = 0.042;
uniform vec3 pec_pivots[2];
uniform vec3 olive : source_color = vec3(0.3, 0.34, 0.24);
uniform vec3 silver : source_color = vec3(0.62, 0.64, 0.58);
uniform vec3 belly : source_color = vec3(0.86, 0.85, 0.78);
uniform vec3 spot : source_color = vec3(0.18, 0.16, 0.12);
uniform vec3 iris : source_color = vec3(0.78, 0.72, 0.48);

varying float v_part;
varying float v_s;
varying float v_t;
varying float v_u;
varying vec3 v_rest;
varying vec3 v_rn;
varying float v_male;

void turn(inout vec3 v, inout vec3 n, vec3 o, vec3 axis, float a) {
	vec3 k = normalize(axis);
	float c = cos(a);
	float s = sin(a);
	vec3 p = v - o;
	v = o + p * c + cross(k, p) * s + k * dot(k, p) * (1.0 - c);
	n = n * c + cross(k, n) * s + k * dot(k, n) * (1.0 - c);
}

void vertex() {
	int part = int(round(CUSTOM0.x));
	float fin_t = CUSTOM0.y;
	float base_y = CUSTOM0.w;
	float swim = max(INSTANCE_CUSTOM.x, 0.0);
	float graze = max(-INSTANCE_CUSTOM.x, 0.0);
	float bend = INSTANCE_CUSTOM.y;
	float seed = INSTANCE_CUSTOM.z;
	bool male = INSTANCE_CUSTOM.w >= 1.0;
	float display = male ? fract(INSTANCE_CUSTOM.w) : 0.0;
	float t = TIME + seed * 41.0;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	v_rest = VERTEX;
	v_rn = NORMAL;
	// (the other sex's fins: folded away to nothing)
	if ((part == 3 || part == 10) && male)
		v = vec3(v.x * 0.0, base_y, v.z);
	if ((part == 4 || part == 11) && !male)
		v = vec3(0.0, base_y, v.z);
	// the fins' own: the sail half folded swimming, raised to display; the
	// dorsal up; the anal fin
	if (part == 4) {
		float h = mix(0.5, 1.0, display) * (1.0 - 0.25 * swim * (1.0 - display));
		h += 0.03 * display * sin(t * 23.0 + v.z * 300.0); // (quivering)
		float up = v.y - base_y;
		v.y = base_y + up * h;
		v.z += (1.0 - h) * up * 0.8; // (folded back as it lowers)
	}
	if (part == 3 || part == 10) {
		float h = 0.9 - 0.25 * swim;
		float up = v.y - base_y;
		v.y = base_y + up * h;
		v.z += (1.0 - h) * abs(up) * 0.6;
	}
	// the pectorals: sculling, hovering; laid back, swimming fast
	if (part == 6 || part == 7) {
		int s = part - 6;
		float side = s == 1 ? 1.0 : -1.0;
		vec3 o = pec_pivots[s];
		float scull = (1.0 - swim) * (0.55 + 0.25 * graze);
		float a = scull * sin(t * 7.5 + float(s) * 0.4) + 0.25 * swim * sin(t * 3.0);
		turn(v, n, o, vec3(0.0, 1.0, 0.0), (0.35 * swim - 0.25 + a * 0.6) * side);
		turn(v, n, o, vec3(0.0, 0.0, 1.0), (0.2 * a) * side);
	}
	if (part == 8 || part == 9) { // (the pelvics, a little)
		float side = part == 9 ? 1.0 : -1.0;
		v.x += side * 0.0005 * sin(t * 5.0) * fin_t;
	}
	// the tail fin: spread wide with the beat, closed a little hovering
	if (part == 5) {
		float spread = mix(0.85, 1.05, swim);
		v.y *= mix(1.0, spread, fin_t);
	}
	// the body's wave, head to tail; curved into a turn
	float L = z_tail - z_head;
	float s = clamp((VERTEX.z - z_head) / L, 0.0, 1.0);
	v_s = s;
	float freq = mix(1.6, 6.5, swim);
	float ph = t * freq * 6.2832;
	float amp = L * mix(0.025, 0.1, swim);
	float k = 6.2832 * 0.95;
	float env = 0.05 + s * s;
	float dx = amp * env * sin(k * s - ph);
	float slope = amp * (2.0 * s * sin(k * s - ph) - env * k * cos(k * s - ph)) / L;
	float cv = -bend * 0.22 * L;
	dx += cv * (s - 0.3) * (s - 0.3);
	slope += cv * 2.0 * (s - 0.3) / L;
	// grazing: the head jerking, pecking
	float jerk = graze * 0.0012 * sin(t * 15.0) * pow(1.0 - s, 3.0);
	dx += jerk;
	v.x += dx;
	n.z -= slope * n.x;
	// the lips working
	if (part == 12)
		v.y += graze * 0.0004 * max(sin(t * 15.0), 0.0);
	VERTEX = v;
	NORMAL = normalize(n);
	v_part = CUSTOM0.x;
	v_t = fin_t;
	v_u = CUSTOM0.z;
	v_male = male ? 1.0 : 0.0;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	int part = int(round(v_part));
	bool male = v_male > 0.5;
	vec3 c;
	float rough = 0.3;
	float spec = 0.6;
	float rim = 0.0;
	if (part == 0 || part == 12) {
		// olive above, silvery down the sides, pale beneath
		float ny = normalize(v_rn).y;
		c = mix(silver, olive, smoothstep(0.1, 0.7, ny));
		c = mix(c, belly, 1.0 - smoothstep(-0.75, -0.2, ny));
		// its scales: a net of them, each its edge darker, rows of dark
		// spots down its sides (a sailfin's), iridescent on a male
		vec2 g = vec2(v_rest.z * 830.0, v_rest.y * 830.0);
		g.x += floor(g.y) * 0.5;
		vec2 f = fract(g) - 0.5;
		float edge = smoothstep(0.32, 0.5, max(abs(f.x), abs(f.y) * 1.1));
		float side = 1.0 - smoothstep(0.35, 0.8, abs(ny));
		float row = 1.0 - smoothstep(0.08, 0.2, length(f));
		float body = smoothstep(0.08, 0.2, v_s) * (1.0 - smoothstep(0.82, 0.9, v_s));
		c *= 1.0 - 0.18 * edge * side;
		vec3 dot_c = male ? mix(spot, vec3(0.75, 0.42, 0.15), 0.35) : spot; // (his rows of orange-brown dots)
		c = mix(c, dot_c, row * side * body * (0.45 + 0.25 * h21(floor(g))));
		if (male) // (his throat and breast orange)
			c = mix(c, vec3(0.85, 0.55, 0.25), (1.0 - smoothstep(0.12, 0.3, v_s)) * (1.0 - smoothstep(-0.8, -0.2, ny)) * 0.55);
		rim = male ? 0.45 : 0.25; // (the scales' sheen: a male's blue-green)
		if (part == 12)
			c *= 0.55;
	} else if (part == 1) {
		c = iris;
		rough = 0.15;
		spec = 0.9;
	} else if (part == 2) {
		c = vec3(0.01);
		rough = 0.05;
		spec = 1.0;
	} else if (part == 11) {
		c = olive * 0.8;
	} else {
		// a fin: membrane between darker rays; a male's sail spotted dark,
		// its edge orange; his tail fin orange in its middle, dark rimmed
		float ray = 1.0 - smoothstep(0.08, 0.22, abs(fract(v_u * 9.0) - 0.5));
		c = mix(vec3(0.62, 0.62, 0.55), vec3(0.4, 0.4, 0.33), ray * 0.6);
		if (part == 4 || part == 3) {
			vec2 g = vec2(v_u * 8.0, v_t * 4.0);
			float d = length(fract(g) - 0.5);
			c = mix(c, spot, (1.0 - smoothstep(0.12, 0.25, d)) * 0.6);
			if (part == 4) {
				c = mix(c, vec3(0.9, 0.5, 0.15), smoothstep(0.8, 0.92, v_t)); // (the orange edge)
				c = mix(c, vec3(0.25, 0.4, 0.45), 0.15);
			}
		}
		if (part == 5 && male) {
			c = mix(c, vec3(0.85, 0.6, 0.2), (1.0 - smoothstep(0.3, 0.75, v_t)) * 0.5);
			c = mix(c, vec3(0.1, 0.09, 0.07), smoothstep(0.85, 0.97, v_t));
		}
		rough = 0.5;
		spec = 0.3;
	}
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = spec;
	RIM = rim;
	RIM_TINT = 0.8;
	if (part >= 3 && part != 11 && part != 12) // (the fins thin: lit through)
		BACKLIGHT = vec3(0.35);
}
