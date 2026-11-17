shader_type spatial;
render_mode cull_disabled;
// An octopus (scripts/creatures/octopus.gd): its eight arms, the web
// between them, posed here from the arms' figures (each a curve: from its
// base on the crown, turning along its length as its curl says, a wave
// running down it), its mantle raised or laid back and breathing, its skin
// coloured as its chromatophores say, raised in papillae, its suckers.
//
// CUSTOM0: x its part (0 head and mantle, 1 an arm, 2 the web, 3 an eye,
// 4 the siphon, 5 an eye's horn); an arm's: y the arm (0..7), z along it
// (0 its base, 1 its tip), w round it (0: its oral side, its suckers');
// the web's: y the arm on its left, z across to the next (0..1), w out
// along them (0..1); the head's: y along its axis (0 the crown, 1 the
// mantle's tip). UV the head's skin's.

uniform float arm_len = 0.7; // m
uniform float arm_r0 = 0.022; // m: an arm's radius at its base
uniform float crown_r = 0.03; // m: the ring the arms come from
uniform float crown_y = 0.04; // m: the crown above the bottom
uniform float web_depth = 0.18; // of an arm's length
uniform float web_sag = 0.15;
uniform vec4 arm_a[8]; // yaw, pitch (down +), curl (rad over its length), the wave's (rad)
uniform vec4 arm_b[8]; // the wave's phase, waves along it, twist, reach (its length's share)
uniform vec4 arm_c[8]; // a curl to the side (rad over its length), the tip's own curl, -, -
uniform float lift = 0.0; // m: its body raised off the bottom
uniform float floor_on = 1.0; // (on the bottom: no arm through it)
uniform vec3 neck = vec3(0.0, 0.1, 0.03); // the pivot the mantle swings on
uniform vec3 mantle_c = vec3(0.0, 0.15, 0.12); // the mantle's middle (at rest)
uniform float neck_u = 0.42;
uniform float mantle_pitch = 0.0; // rad: up (+) from where it was made
uniform float mantle_swell = 0.0; // breathing, and the jet's
uniform float papillae = 0.2; // its skin raised
uniform float size_k = 1.0; // (its patterns' scale)

uniform vec3 base_col : source_color = vec3(0.55, 0.32, 0.22);
uniform vec3 dark_col : source_color = vec3(0.28, 0.12, 0.08);
uniform vec3 spot_col : source_color = vec3(0.92, 0.86, 0.78);
uniform vec3 camo_col : source_color = vec3(0.45, 0.42, 0.36);
uniform float spots = 0.3; // its pale spots
uniform float chroma = 0.5; // 0 pale, 1 dark (its chromatophores spread)
uniform float mottle = 0.5;
uniform float camo = 0.0; // matched to the bottom
uniform float pale = 0.0; // blanched
uniform float wave_amp = 0.0; // dark clouds passing over it
uniform float eye_bar = 0.0; // dark round the eyes (a display)
uniform float dead = 0.0;

varying float v_part;
varying vec3 v_pat;
varying float v_t;
varying float v_th;
varying float v_q;
varying vec3 v_eye;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

vec3 yaw_dir(float y) {
	return vec3(-sin(y), 0.0, -cos(y));
}

float arm_radius(float t) {
	return arm_r0 * max(1.0 - 0.93 * pow(t, 0.9), 0.04);
}

// An arm's curve to t: its point, and its frame (T along it, N its oral side, B).
void arm_frame(int a, float t, out vec3 P, out vec3 T, out vec3 N, out vec3 B) {
	vec4 A = arm_a[a];
	vec4 Q = arm_b[a];
	vec4 C = arm_c[a];
	vec3 d = yaw_dir(A.x);
	P = vec3(0.0, crown_y + lift, 0.0) + d * crown_r;
	T = normalize(d * cos(A.y) - vec3(0.0, 1.0, 0.0) * sin(A.y));
	vec3 side = normalize(cross(vec3(0.0, 1.0, 0.0), d));
	N = normalize(cross(T, side)); // (its oral side: under it, laid out)
	if (dot(N, vec3(0.0, -1.0, 0.0)) < 0.0) {
		N = -N;
	}
	B = cross(T, N);
	float tw = Q.z;
	vec3 n2 = N * cos(tw) + B * sin(tw);
	B = cross(T, n2);
	N = n2;
	float L = arm_len * Q.w;
	int steps = max(int(ceil(t * 18.0)), 1);
	float h = t / float(steps);
	for (int i = 0; i < steps; i++) {
		float s = (float(i) + 0.5) * h;
		float k = A.z + A.w * sin(Q.y * 6.2831853 * s - Q.x) + C.y * smoothstep(0.55, 1.0, s);
		T = normalize(T + (N * k + B * C.x) * h);
		N = normalize(N - T * dot(N, T));
		B = cross(T, N);
		P += T * h * L;
	}
	if (floor_on > 0.5) {
		P.y = max(P.y, arm_radius(t) * 0.8);
	}
}

void vertex() {
	v_part = CUSTOM0.x;
	v_t = 0.0;
	v_th = 0.0;
	v_q = 0.0;
	v_eye = vec3(0.0);
	v_pat = VERTEX * 18.0 / size_k;
	if (CUSTOM0.x > 0.5 && CUSTOM0.x < 1.5) { // an arm
		int a = int(CUSTOM0.y + 0.5);
		float t = CUSTOM0.z;
		float th = CUSTOM0.w;
		vec3 P, T, N, B;
		arm_frame(a, t, P, T, N, B);
		float r = arm_radius(t);
		vec3 off = cos(th) * N + sin(th) * B;
		float oral = smoothstep(0.35, 0.95, cos(th));
		float bump = papillae * smoothstep(0.1, -0.5, cos(th)) * (vnoise(vec3(t * arm_len * 70.0 / size_k, th * 2.0, CUSTOM0.y * 7.0)) - 0.35);
		VERTEX = P + off * r * (1.0 - 0.2 * oral + 0.45 * bump);
		NORMAL = off;
		v_t = t;
		v_th = th;
		v_pat = vec3(t * arm_len * 9.0 / size_k + CUSTOM0.y * 3.1, cos(th) * 0.6, sin(th) * 0.6);
		v_q = -log(1.0 - 0.93 * t) / 0.93 * (arm_len / (arm_r0 * 1.05)); // (its suckers counted along it)
	} else if (CUSTOM0.x > 1.5 && CUSTOM0.x < 2.5) { // the web: arm to arm
		int a = int(CUSTOM0.y + 0.5);
		int b = (a + 1) % 8;
		float s = CUSTOM0.z;
		float t = CUSTOM0.w * web_depth * (1.0 - 0.45 * sin(3.14159 * s));
		vec3 Pa, Ta, Na, Ba, Pb, Tb, Nb, Bb;
		arm_frame(a, t, Pa, Ta, Na, Ba);
		arm_frame(b, t, Pb, Tb, Nb, Bb);
		vec3 P = mix(Pa, Pb, s);
		vec3 n = normalize(mix(Na, Nb, s));
		P += n * sin(3.14159 * s) * distance(Pa, Pb) * web_sag;
		VERTEX = P;
		NORMAL = -n;
		v_pat = vec3(t * arm_len * 9.0 / size_k + CUSTOM0.y * 3.1, s, 0.3);
		v_t = t;
		v_th = 3.14159;
	} else {
		vec3 rest = VERTEX;
		if (CUSTOM0.x < 0.5) { // the head and the mantle: breathing, laid back or raised
			float w = smoothstep(neck_u - 0.05, neck_u + 0.18, CUSTOM0.y);
			VERTEX = mantle_c + (VERTEX - mantle_c) * (1.0 + mantle_swell * w);
			float pa = mantle_pitch * w;
			vec3 q = VERTEX - neck;
			q = vec3(q.x, q.y * cos(pa) + q.z * sin(pa), -q.y * sin(pa) + q.z * cos(pa));
			VERTEX = neck + q;
			NORMAL = vec3(NORMAL.x, NORMAL.y * cos(pa) + NORMAL.z * sin(pa), -NORMAL.y * sin(pa) + NORMAL.z * cos(pa));
			float bump = papillae * (vnoise(rest * 60.0 / size_k) - 0.4);
			VERTEX += NORMAL * bump * 0.012 * size_k;
		} else if (CUSTOM0.x > 2.5 && CUSTOM0.x < 3.5) { // an eye
			v_eye = CUSTOM0.yzw;
		} else if (CUSTOM0.x > 4.5) { // an eye's horn: raised with its papillae
			VERTEX = vec3(CUSTOM0.y, CUSTOM0.z, CUSTOM0.w) + (VERTEX - vec3(CUSTOM0.y, CUSTOM0.z, CUSTOM0.w)) * (0.25 + 1.2 * papillae);
		}
		v_pat = rest * 18.0 / size_k;
		VERTEX.y += lift;
	}
}

void fragment() {
	float m1 = vnoise(v_pat * 1.0);
	float m2 = vnoise(v_pat * 2.7 + 5.0);
	float fine = vnoise(v_pat * 9.0);
	vec3 col = mix(base_col, dark_col, smoothstep(0.35, 0.75, m1 * 0.65 + m2 * 0.35) * mottle);
	col *= mix(1.35, 0.55, chroma) * (0.85 + 0.3 * fine);
	float sp = smoothstep(0.82, 0.88, vnoise(v_pat * 3.6 + 11.0)) * spots;
	col = mix(col, spot_col, sp);
	float cloud = 0.5 + 0.5 * sin(v_pat.x * 1.4 + v_pat.z * 0.9 - TIME * 2.6);
	col *= 1.0 - wave_amp * 0.55 * smoothstep(0.55, 0.95, cloud);
	col = mix(col, camo_col * (0.75 + 0.5 * m2) * (0.85 + 0.3 * fine), camo);
	col = mix(col, vec3(0.86, 0.82, 0.76) * (0.9 + 0.15 * fine), pale);
	float rough = 0.38;
	if (v_part > 0.5 && v_part < 1.5) { // an arm: its oral side pale, its suckers in two rows
		float oral = smoothstep(0.45, 0.85, cos(v_th));
		col = mix(col, vec3(0.88, 0.76, 0.68) * mix(1.0, 0.8, chroma * 0.5), oral * (1.0 - pale) * 0.85);
		float best = 9.0;
		for (int row = 0; row < 2; row++) {
			float rc = row == 0 ? -0.33 : 0.33;
			float q = v_q + (row == 0 ? 0.0 : 0.5);
			float d = length(vec2(fract(q) - 0.5, (v_th > 3.14159 ? v_th - 6.2831853 : v_th) - rc) / vec2(1.0, 0.62));
			best = min(best, d);
		}
		if (cos(v_th) > 0.2 && best < 0.46) {
			float rim = smoothstep(0.46, 0.38, best) * smoothstep(0.12, 0.3, best);
			col = mix(vec3(0.96, 0.9, 0.86), vec3(0.62, 0.45, 0.42), smoothstep(0.24, 0.1, best)) * (0.85 + 0.15 * rim);
			rough = 0.25;
		}
	} else if (v_part > 1.5 && v_part < 2.5) { // the web: thinner, the light through it
		col *= 0.95;
		BACKLIGHT = col * 0.35;
	} else if (v_part > 2.5 && v_part < 3.5) { // an eye: its gold iris, the pupil a dark bar, level
		vec3 e = normalize(v_eye);
		float iris = smoothstep(0.5, 0.62, abs(e.x));
		float bar = step(abs(e.y), 0.13) * step(abs(e.z), 0.42) * iris;
		vec3 ic = mix(vec3(0.74, 0.62, 0.32), vec3(0.03), bar);
		col = mix(col, ic, iris);
		col = mix(col, vec3(0.05, 0.04, 0.03), eye_bar * 0.7 * (1.0 - iris));
		rough = mix(rough, 0.08, iris);
	} else if (v_part > 3.5 && v_part < 4.5) { // the siphon
		col *= 0.9;
	}
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	col = mix(col, vec3(0.8, 0.78, 0.74) * (0.85 + 0.15 * fine), dead);
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.55;
	SSS_STRENGTH = 0.25;
}
