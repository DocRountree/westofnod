shader_type spatial;
// An eccentric sand dollar (scripts/creatures/sand_dollar.gd): alive,
// velvet with its tiny spines, purple brown to grey, its five petals (the
// rows of pores its gill feet come through) set off its middle toward its
// back, faint under the spines; beneath, its food grooves branching from
// the mouth; its spines stirring. Dead, its test: bleached white, the
// petals plain, its surface beaded.
// UV: across it (-1..1, its back +y); COLOR.r 1 its top, 0 beneath.

instance uniform float dead = 0.0;
instance uniform float seed = 0.0;
instance uniform float stir = 0.3; // its spines moving
instance uniform float juvenile = 0.0;

varying float v_top;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1, 0)), f.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	v_top = COLOR.r;
}

// (Its petals: how much p (its uv) is on a row of their pores, and in one.)
vec2 petals(vec2 p) {
	vec2 apex = vec2(0.0, 0.22);
	float rows = 0.0;
	float inside = 0.0;
	for (int k = 0; k < 5; k++) {
		float a = 6.2831853 * float(k) / 5.0;
		vec2 d = vec2(sin(a), -cos(a));
		vec2 sdir = vec2(-d.y, d.x);
		// (how far to its rim that way: the petal three quarters of it)
		float b = dot(apex, d);
		float to_rim = -b + sqrt(max(b * b - dot(apex, apex) + 1.0, 0.0));
		float L = 0.72 * to_rim;
		vec2 q = p - apex;
		float along = dot(q, d);
		float across = dot(q, sdir);
		if (along > 0.05 && along < L) {
			float u = (along - 0.05) / (L - 0.05);
			float w = 0.2 * L * pow(sin(3.14159 * u), 0.75) + 0.01;
			float edge = abs(abs(across) - w);
			float pores = smoothstep(0.35, 0.15, abs(fract(along * 48.0) - 0.5));
			rows = max(rows, smoothstep(0.022, 0.006, edge) * pores);
			inside = max(inside, smoothstep(0.0, -0.01, abs(across) - w));
		}
	}
	return vec2(rows, inside);
}

void fragment() {
	vec2 p = UV;
	float r = length(p);
	vec2 pt = petals(p);
	float fuzz = vnoise(p * 140.0 + seed * 50.0 + vec2(TIME * stir * 0.6, 0.0));
	vec3 live = mix(vec3(0.17, 0.11, 0.13), vec3(0.27, 0.19, 0.21), fuzz);
	live = mix(live, vec3(0.62, 0.55, 0.5), juvenile * 0.6);
	vec3 test = vec3(0.9, 0.88, 0.82) * (0.92 + 0.08 * step(0.75, hash2(floor(p * 90.0))));
	vec3 col;
	if (v_top > 0.5) {
		live = mix(live, live * 1.25, pt.y * 0.35) * (1.0 - 0.25 * pt.x);
		test = mix(test, vec3(0.78, 0.74, 0.66), pt.x * 0.8) * (1.0 - 0.05 * pt.y);
		col = mix(live, test, dead);
	} else { // beneath: the mouth in the middle, its food grooves out from it
		float th = atan(p.x, -p.y);
		float g = abs(sin(2.5 * (th + 0.15 * sin(r * 22.0 + float(int(th * 0.8))))));
		float groove = smoothstep(0.08, 0.0, g * r) * smoothstep(0.02, 0.08, r);
		float mouth = smoothstep(0.06, 0.04, r);
		live = mix(live, live * 0.6, groove * 0.7 + mouth);
		test = mix(test, test * 0.8, groove * 0.5 + mouth * 0.6);
		col = mix(live, test, dead);
	}
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.75, dead);
	SPECULAR = 0.2;
	RIM = (1.0 - dead) * 0.3; // (its velvet)
	RIM_TINT = 0.6;
}
