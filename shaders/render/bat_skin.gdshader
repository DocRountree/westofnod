shader_type spatial;
render_mode cull_disabled;

// A bat's bare skin: its wings' membranes and its tail's (kind 0: thin,
// rubbery, dark; finely wrinkled along its elastic strands, crumpled where
// it's folded: COLOR.r; opaque), its arms', fingers' and legs' (kind 1: UV.y
// 1 at a joint, paler over the bone), its ears' (kind 2: leathery, faintly
// ridged across).

uniform int kind = 0;
uniform vec3 skin_color = vec3(0.17, 0.135, 0.12);
uniform float pup = 0.0; // (a newborn's: pink grey)

varying vec3 lp;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnz(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec3 c = skin_color;
	float h = 0.0;
	float k = 0.0;
	float rough = 0.46;
	float spec = 0.38;
	if (kind == 0) {
		// (UV: cm along the bones, across between them)
		float fold = COLOR.r;
		float strands = vnz(UV * vec2(5.0, 40.0)) * 0.6 + vnz(UV * vec2(11.0, 90.0) + 3.0) * 0.4; // (fine, along it)
		float cross_ = vnz(UV * vec2(30.0, 5.0) + 9.0);
		float buckle = vnz(UV * vec2(1.6, 5.0) + 5.0);
		h = strands * 0.5 + cross_ * 0.25 + buckle * mix(0.6, 2.6, fold);
		k = mix(0.00007, 0.0002, fold);
		c *= 0.86 + 0.24 * vnz(UV * 2.3) - 0.1 * strands;
		c = mix(c, c * 1.25 + vec3(0.02, 0.012, 0.01), 0.15 * smoothstep(0.5, 0.9, vnz(UV * vec2(2.0, 14.0) + 20.0))); // (paler, thinner between its strands)
		rough = 0.5;
		spec = 0.32;
	} else if (kind == 1) {
		float joint = UV.y;
		h = vnz(UV.xx * vec2(40.0, 3.0)) * 0.6; // (rings round it, fine)
		k = 0.00012;
		c = mix(c * 1.12 + vec3(0.03, 0.015, 0.012), c * 1.3 + vec3(0.06, 0.035, 0.03), joint * 0.6); // (the bone's skin a little paler, pinker at its joints)
		rough = 0.4;
		spec = 0.42;
	} else {
		h = vnz(vec2(UV.x * 3.0, UV.y * 22.0)) * 0.7 + vnz(UV * 40.0) * 0.3; // (ridges across it)
		k = 0.00016;
		c *= 0.8 + 0.2 * vnz(UV * 6.0);
		c = mix(c, c * 1.35 + vec3(0.03, 0.015, 0.01), (1.0 - smoothstep(0.0, 0.5, UV.y)) * 0.4 * step(0.5, COLOR.g)); // (inside, toward its base: paler)
		rough = 0.5;
		spec = 0.34;
	}
	c = mix(c, vec3(0.5, 0.36, 0.36) * (0.9 + 0.15 * h), pup);
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);
	vec3 n = normalize(NORMAL);
	vec3 r1 = cross(dpy, n);
	vec3 r2 = cross(n, dpx);
	float det = dot(dpx, r1);
	NORMAL = normalize(abs(det) * n - sign(det) * (dFdx(h) * r1 + dFdy(h) * r2) * k);
	ALBEDO = pow(clamp(c, 0.0, 1.0), vec3(2.2));
	ROUGHNESS = rough;
	SPECULAR = spec;
}
