shader_type spatial;
render_mode cull_disabled;
// A purple sea urchin (scripts/creatures/sea_urchin.gd). COLOR: r the way
// along a spine / tube foot / tooth, g its kind (0 the test, 1 a spine, 0.5 a
// tube foot, 0.75 a tooth), b a phase. CUSTOM0: its direction, its length.

instance uniform vec3 threat = vec3(0.0); // (toward it, in its own frame; its length how much)
instance uniform float graze = 0.0;       // (its teeth working)
instance uniform float feet = 1.0;        // (its tube feet out)
instance uniform float juvenile = 0.0;    // (spat: greenish, pale spined)
instance uniform float seed = 0.0;

varying float v_kind;
varying float v_t;
varying vec3 v_p;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	float kind = COLOR.g;
	float t = COLOR.r;
	float ph = (COLOR.b + seed) * 6.2831;
	vec3 d = CUSTOM0.xyz;
	float ln = CUSTOM0.w;
	v_kind = kind;
	v_t = t;
	v_p = VERTEX;
	if (kind > 0.9) { // a spine: on its ball joint, swaying slow; swung to point at a threat
		vec3 sway = vec3(sin(TIME * 0.45 + ph), 0.0, cos(TIME * 0.37 + ph * 1.7)) * 0.1;
		vec3 tw = threat - dot(threat, d) * d; // (toward it, across the spine)
		float facing = smoothstep(-0.2, 0.6, dot(normalize(threat + vec3(1e-4)), d));
		VERTEX += t * ln * (sway * (1.0 - length(threat) * 0.7) + tw * 0.55 * (1.0 - facing * 0.6));
	} else if (kind > 0.4 && kind < 0.6) { // a tube foot: reaching, waving; drawn in
		float out_ = clamp(feet, 0.0, 1.0);
		vec3 wave = vec3(sin(TIME * 0.9 + ph), 0.4 * sin(TIME * 0.7 + ph * 2.3), cos(TIME * 1.1 + ph * 1.3)) * 0.28;
		VERTEX += t * t * ln * wave * out_;
		VERTEX += t * t * ln * graze * vec3(-d.x, -0.9, -d.z) * 0.45; // (eating: the feet pulling the food in under it)
		VERTEX -= d * ln * t * (1.0 - mix(0.12, 1.0, out_)); // (shortened, toward its base)
	} else if (kind > 0.7 && kind < 0.8) { // a tooth: the lantern opening and closing
		float open = graze * max(sin(TIME * 3.2), 0.0);
		VERTEX.xz += normalize(VERTEX.xz + vec2(1e-5)) * t * 0.0025 * open;
	}
}

void fragment() {
	vec3 c;
	float rough = 0.45;
	float sss = 0.0;
	vec3 purple = mix(vec3(0.27, 0.06, 0.3), vec3(0.32, 0.34, 0.2), juvenile);
	if (v_kind < 0.25) { // the test: beaded with tubercles, its five paler ambulacra, the periproct on top, the mouth's membrane beneath
		float a = atan(v_p.z, v_p.x);
		float r = length(v_p.xz);
		float amb = smoothstep(0.82, 0.97, cos(5.0 * a));
		vec2 g = vec2(a * 14.0, v_p.y * 420.0 + r * 200.0);
		float tub = 1.0 - smoothstep(0.16, 0.3, length(fract(g) - 0.5));
		c = purple * (0.9 + 0.2 * h21(floor(g)));
		c = mix(c, mix(vec3(0.38, 0.14, 0.42), vec3(0.5, 0.52, 0.36), juvenile), tub * 0.4);
		c = mix(c, c * 1.25 + vec3(0.02), amb * 0.5);
		float top = 1.0 - smoothstep(0.0025, 0.004, r);
		if (v_p.y > 0.03)
			c = mix(c, vec3(0.12, 0.04, 0.12), top);
		float mouth = 1.0 - smoothstep(0.008, 0.012, r);
		if (v_p.y < 0.02)
			c = mix(c, vec3(0.3, 0.2, 0.22), mouth);
		rough = 0.6;
	} else if (v_kind > 0.9) { // a spine: purple at its base, paler violet to its tip, finely ridged
		c = mix(mix(vec3(0.2, 0.03, 0.27), vec3(0.32, 0.3, 0.2), juvenile), mix(vec3(0.46, 0.17, 0.6), vec3(0.58, 0.6, 0.44), juvenile), pow(v_t, 1.2));
		c *= 0.9 + 0.2 * h21(vec2(floor(v_p.x * 3000.0), floor(v_p.z * 3000.0)));
		rough = 0.32;
	} else if (v_kind > 0.7) { // a tooth: white
		c = vec3(0.88, 0.86, 0.8);
		rough = 0.3;
	} else { // a tube foot: translucent, pinkish purple; its sucker darker
		c = mix(vec3(0.55, 0.32, 0.5), vec3(0.3, 0.12, 0.28), smoothstep(0.9, 0.95, v_t));
		sss = 0.6;
		rough = 0.25;
	}
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.5;
	SSS_STRENGTH = sss;
}
