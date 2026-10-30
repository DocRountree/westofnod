shader_type spatial;
render_mode diffuse_burley;

// Procedural 16x16 "pixel" textures per block type (type id in COLOR.r).

varying vec3 wpos;
varying vec3 wnorm;
varying flat float btype;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = NORMAL;
	btype = floor(COLOR.r * 255.0 + 0.5);
}

void fragment() {
	vec3 n = normalize(wnorm);
	vec3 inside = wpos - n * 0.001;
	vec3 cell = floor(inside);
	vec3 local = inside - cell;
	bool top = n.y > 0.5;
	bool bottom = n.y < -0.5;
	vec2 uv = abs(n.y) > 0.5 ? local.xz : (abs(n.x) > 0.5 ? vec2(local.z, local.y) : local.xy);
	vec2 px = floor(uv * 16.0);
	float r = hash(px + cell.xz * 17.0 + cell.y * 3.1 + btype * 7.0);
	float r2 = hash(px.yx * 1.7 + btype);
	int t = int(btype);
	vec3 col = vec3(1.0, 0.0, 1.0);
	float alpha = 1.0;

	vec3 dirt = mix(vec3(0.42, 0.29, 0.18), vec3(0.55, 0.40, 0.26), r);
	vec3 grass = mix(vec3(0.30, 0.52, 0.17), vec3(0.40, 0.64, 0.22), r);
	if (t == 1) {
		col = dirt;
	} else if (t == 2) {
		if (top) col = grass;
		else if (bottom) col = dirt;
		else col = (px.y > 12.0 - floor(r2 * 3.0)) ? grass : dirt;
	} else if (t == 3) {
		col = mix(vec3(0.45, 0.45, 0.45), vec3(0.6, 0.6, 0.6), r) * (r2 > 0.9 ? 0.8 : 1.0);
	} else if (t == 4) {
		col = mix(vec3(0.84, 0.78, 0.55), vec3(0.93, 0.87, 0.66), r);
	} else if (t == 5) {
		col = mix(vec3(0.40, 0.38, 0.36), vec3(0.68, 0.64, 0.6), r * r2 * 1.6);
	} else if (t == 6) {
		if (top || bottom) {
			float d = length(uv - 0.5) * 16.0;
			col = mix(vec3(0.62, 0.48, 0.28), vec3(0.50, 0.37, 0.20), step(0.5, fract(d * 0.33))) ;
			if (d > 6.5) col = vec3(0.36, 0.26, 0.14);
		} else {
			float stripe = hash(vec2(px.x, cell.x + cell.z));
			col = mix(vec3(0.30, 0.21, 0.11), vec3(0.42, 0.31, 0.17), stripe * 0.7 + r * 0.3);
		}
	} else if (t == 7) {
		float plank = floor(px.y / 4.0);
		float seam = (mod(px.y, 4.0) == 3.0) ? 0.7 : 1.0;
		col = mix(vec3(0.62, 0.47, 0.27), vec3(0.74, 0.58, 0.35), hash(vec2(plank, cell.y)) * 0.5 + r * 0.5) * seam;
	} else if (t == 8) {
		col = mix(vec3(0.13, 0.33, 0.10), vec3(0.24, 0.50, 0.16), r);
		if (r2 > 0.85) col *= 0.6;
	} else if (t == 9) {
		bool frame = px.x == 0.0 || px.y == 0.0 || px.x == 15.0 || px.y == 15.0;
		bool streak = (px.x - px.y == 3.0 || px.x - px.y == 4.0) && px.x < 9.0;
		col = vec3(0.85, 0.95, 1.0);
		alpha = (frame || streak) ? 1.0 : 0.0;
	}
	ALBEDO = pow(col, vec3(2.2)); // palette above is authored in sRGB
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = t == 9 ? 0.1 : 0.9;
}
