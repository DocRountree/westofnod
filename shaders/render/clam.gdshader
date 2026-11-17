shader_type spatial;
render_mode cull_disabled;
// A Pacific littleneck clam (scripts/creatures/clam.gd): its two valves
// (sculptured across and along: concentric ridges crossed by fine radial
// ribs; cream to grey brown, mottled and zigzagged in brown; white inside,
// its muscle scars and pallial line), hinged on its back and gaping as its
// adductors let it; inside, its mantle and its body; its foot out from
// under, digging; its siphons (fused, two openings at the tip, the
// incurrent fringed with tentacles) up to the sand's top, or drawn in.
//
// COLOR.r its part: 0 a valve outside, 0.25 inside, 0.5 its flesh, 0.75
// its foot, 1 its siphons (0.9 a tentacle); COLOR.g which valve (0 left, 1
// right). UV: a valve's (s out from the beak, 0..1; round it, 0..1); the
// siphons' (along, round). CUSTOM0: x along (foot, siphon), yzw a
// direction (the foot's, the siphons').

uniform float L = 0.055; // m: its length
uniform float hinge_y = 0.022; // m: the hinge line's height (its back)
uniform float siphon_ref = 0.02; // m: its siphons' length as made
uniform vec3 siphon_base = vec3(0.0236, 0.0033, 0.0); // where they come out of it

instance uniform float gape = 0.0; // rad: its valves apart
instance uniform float flesh = 1.0; // what's left of it (0: an empty shell)
instance uniform float foot = 0.0; // 0 in, 1 out its full length
instance uniform float siphon = 0.0; // m: its siphons out (0: in)
instance uniform float pulse = 0.0; // its siphons' tips: drawing water
instance uniform float tone = 0.5; // its shell's colour, light to dark
instance uniform float seed = 0.0;
instance uniform float bleach = 0.0; // an old empty shell, sun and sea faded

varying float v_part;
varying vec2 v_uv;
varying float v_side;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	v_part = COLOR.r;
	v_uv = UV;
	v_side = COLOR.g * 2.0 - 1.0;
	if (COLOR.r > 0.95 || (COLOR.r > 0.85 && COLOR.r < 0.95)) { // its siphons: out along their way, or in
		vec3 d = CUSTOM0.yzw;
		float t = CUSTOM0.x;
		VERTEX += d * t * (siphon - siphon_ref);
		float out_k = clamp(siphon / 0.006, 0.0, 1.0); // (drawn in: thin, back inside its shell)
		float flare = (1.0 + 0.12 * pulse * smoothstep(0.85, 1.0, t)) * mix(0.35, 1.0, out_k);
		vec3 q = VERTEX - siphon_base;
		float along = dot(q, d);
		VERTEX = siphon_base + d * (along - (1.0 - out_k) * 0.016) + (q - d * along) * flare;
		VERTEX = mix(siphon_base - d * 0.01, VERTEX, step(0.02, flesh)); // (nothing of them, its flesh gone)
		if (COLOR.r < 0.95) { // a tentacle: waving
			VERTEX += vec3(sin(TIME * 3.0 + UV.y * 20.0), cos(TIME * 2.3 + UV.y * 13.0), 0.0) * 0.0006 * UV.x;
		}
	} else if (COLOR.r > 0.7) { // its foot: out from under it, probing
		vec3 d = CUSTOM0.yzw;
		float t = CUSTOM0.x;
		VERTEX += d * t * foot * L * 0.55;
		VERTEX += vec3(0.0, 0.0, 1.0) * sin(TIME * 2.0 + t * 3.0) * 0.002 * foot * t;
		VERTEX = mix(vec3(0.0, -0.005, 0.0), VERTEX, mix(0.5, 1.0, foot) * step(0.02, flesh)); // (in: tucked inside its valves)
	} else if (COLOR.r > 0.4) { // its flesh: shrinking as it's eaten
		VERTEX *= mix(0.05, 1.0, flesh);
	} else { // a valve: swung on the hinge
		float a = -v_side * gape * 0.5;
		vec3 q = VERTEX - vec3(0.0, hinge_y, 0.0);
		vec3 n = NORMAL;
		VERTEX = vec3(q.x, q.y * cos(a) - q.z * sin(a), q.y * sin(a) + q.z * cos(a)) + vec3(0.0, hinge_y, 0.0);
		NORMAL = vec3(n.x, n.y * cos(a) - n.z * sin(a), n.y * sin(a) + n.z * cos(a));
	}
}

void fragment() {
	vec3 col;
	float rough = 0.55;
	float s = v_uv.x;
	float th = v_uv.y;
	if (v_part < 0.4) {
		// sculpture: growth ridges round it (closer and stronger to its margin), fine radial ribs out from the beak
		float ridges = pow(0.5 + 0.5 * cos(s * 34.0 * 6.2831853 / (1.0 + s)), 3.0) * smoothstep(0.15, 0.6, s);
		float ribs = pow(0.5 + 0.5 * cos(th * 64.0 * 6.2831853), 2.0) * (1.0 - 0.6 * smoothstep(0.6, 1.0, s));
		float lattice = clamp(ridges * 0.7 + ribs * 0.4, 0.0, 1.0);
		if (v_part < 0.1) {
			vec3 base = mix(vec3(0.82, 0.77, 0.66), vec3(0.5, 0.45, 0.38), tone);
			// its markings: brown zigzags and blotches, each its own
			float zz = abs(fract(th * (6.0 + floor(seed * 5.0)) + abs(fract(s * 5.0) - 0.5) * 0.6) - 0.5);
			float mark = smoothstep(0.12, 0.05, zz) * step(0.35, hash2(vec2(floor(th * 9.0), floor(s * 4.0)) + seed * 13.0));
			float blot = smoothstep(0.55, 0.75, hash2(floor(vec2(th * 14.0, s * 9.0)) + seed * 7.0)) * 0.5;
			col = mix(base, vec3(0.38, 0.26, 0.18), clamp(mark * 0.75 + blot * 0.5, 0.0, 1.0));
			col *= 0.9 + 0.14 * lattice;
			col *= 0.9 + 0.12 * smoothstep(0.0, 0.2, s); // (its beak worn)
			col = mix(col, vec3(0.9, 0.88, 0.84), bleach * 0.8);
			NORMAL_MAP = vec3(0.5 + 0.2 * (ribs - 0.5), 0.5 + 0.2 * (ridges - 0.5), 1.0);
			rough = 0.7;
		} else { // inside: porcelain white; the muscle scars, the pallial line
			col = vec3(0.94, 0.92, 0.88);
			float scar_a = smoothstep(0.1, 0.06, length(vec2(th - 0.2, s - 0.55) * vec2(1.0, 1.4)));
			float scar_p = smoothstep(0.1, 0.06, length(vec2(th - 0.8, s - 0.55) * vec2(1.0, 1.4)));
			float pallial = smoothstep(0.02, 0.0, abs(s - 0.82)) * step(0.15, th) * step(th, 0.85);
			col = mix(col, vec3(0.85, 0.82, 0.78), max(scar_a, scar_p) * 0.6 + pallial * 0.4);
			col = mix(col, vec3(0.62, 0.5, 0.58), smoothstep(0.75, 1.0, th) * 0.12); // (a faint flush at its back end)
			rough = 0.18;
		}
	} else if (v_part < 0.6) { // its mantle and body: cream, its edge brown fringed
		col = mix(vec3(0.92, 0.78, 0.64), vec3(0.55, 0.38, 0.26), smoothstep(0.8, 1.0, v_uv.x) * 0.7);
		rough = 0.35;
		SSS_STRENGTH = 0.4;
	} else if (v_part < 0.8) { // its foot: pale, translucent
		col = vec3(0.93, 0.82, 0.72);
		rough = 0.3;
		SSS_STRENGTH = 0.5;
	} else { // its siphons: buff, flecked brown, darker to their tips; the two openings
		float fleck = step(0.8, hash2(floor(v_uv * vec2(30.0, 18.0)) + seed));
		col = mix(vec3(0.86, 0.79, 0.68), vec3(0.45, 0.32, 0.22), fleck * 0.6 + smoothstep(0.75, 1.0, v_uv.x) * 0.5);
		if (v_part < 0.95) {
			col = vec3(0.8, 0.7, 0.55);
		}
		rough = 0.35;
		SSS_STRENGTH = 0.3;
	}
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.45;
}
