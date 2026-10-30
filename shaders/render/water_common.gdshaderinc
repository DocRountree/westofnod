// Shared by the ocean and the inland water: wave sums, and the light that comes
// up through the water. Godot's lighting adds the sky reflection and sun glints.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6); // toward the sun
uniform vec3 sun_color = vec3(1.0, 0.97, 0.92);
uniform vec3 deep_color : source_color = vec3(0.004, 0.03, 0.06);
uniform vec3 scatter_color = vec3(0.0, 0.13, 0.14);
uniform vec3 absorption = vec3(0.45, 0.09, 0.06); // per metre: red goes first
uniform float refraction = 0.03;

const float G = 9.81;

// Small analytic waves: slopes of 24 short deep-water waves around direction
// `base`, wavelengths 4 m .. 0.12 m (x scale), each faded by the pixel
// footprint fp so distant water averages out instead of sparkling.
vec2 small_waves(vec2 p, float t, float fp, float base, float spread, float scale, float steepness) {
	vec2 slope = vec2(0.0);
	float lambda = 4.0 * scale;
	for (int i = 0; i < 24; i++) {
		float ang = base + spread * sin(float(i) * 2.39996) * (0.4 + 0.6 * fract(float(i) * 0.618));
		vec2 d = vec2(cos(ang), sin(ang));
		float k = TAU / lambda;
		float st = steepness * clamp((lambda - 4.0 * fp) / (4.0 * fp), 0.0, 1.0);
		float th = k * dot(d, p) - sqrt(G * k + 0.074 * k * k * k) * t + float(i) * 1.913;
		slope += d * st * cos(th);
		lambda *= 0.86;
	}
	return slope;
}

float linear_depth(vec2 uv, float raw, mat4 inv_proj) {
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, raw, 1.0);
	return -v.z / v.w;
}

// Refracted background seen through the surface, the water body's own light,
// and how much water the view ray crosses. Returns the colour coming up.
vec3 water_body(vec2 screen_uv, vec3 vertex, vec2 slope, vec3 n_world, vec3 to_eye, float crest,
		mat4 inv_proj, vec3 extra_absorb, vec3 tint, float tint_amount, out float thickness) {
	float surf = -vertex.z;
	vec2 uv = screen_uv + slope * refraction / (1.0 + surf * 0.02);
	float scene = linear_depth(uv, texture(depth_tex, uv).r, inv_proj);
	if (scene < surf) { // the refracted sample lies in front of the water
		uv = screen_uv;
		scene = linear_depth(uv, texture(depth_tex, uv).r, inv_proj);
	}
	thickness = max(scene - surf, 0.0) * length(vertex) / max(surf, 1e-3);
	vec3 background = textureLod(screen_tex, uv, 0.0).rgb;
	vec3 transmit = exp(-(absorption + extra_absorb) * thickness);
	vec3 sun = normalize(sun_direction);
	float diffuse = max(dot(n_world, sun), 0.0);
	float toward_sun = max(dot(-to_eye, sun), 0.0); // light shining through crests
	float crest_t = clamp(crest * 0.5 + 0.3, 0.0, 1.0);
	crest_t *= crest_t;
	vec3 body = deep_color * (0.5 + 0.8 * diffuse)
			+ scatter_color * (0.25 + crest_t) * (0.35 + 1.5 * pow(toward_sun, 4.0)) * (0.5 + 0.5 * diffuse);
	body = mix(body, tint * (0.4 + 0.6 * diffuse), tint_amount);
	body *= 0.12 + 0.88 * sun_color;
	return background * transmit + body * (1.0 - transmit);
}

float schlick(vec3 n, vec3 v) {
	float c = clamp(dot(n, v), 0.0, 1.0);
	return 0.02 + 0.98 * pow(1.0 - c, 5.0);
}
