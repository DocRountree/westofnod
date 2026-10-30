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

// Gradient noise with its analytic derivative (Quilez): returns (value, d/dx, d/dy).
vec2 wgrad(ivec2 c) {
	uint v = uint(c.x) * 1597334677u ^ uint(c.y) * 3812015801u;
	v = v * 747796405u + 2891336453u;
	v = ((v >> ((v >> 28u) + 4u)) ^ v) * 277803737u;
	float a = float((v >> 22u) ^ v) / 4294967295.0 * TAU;
	return vec2(cos(a), sin(a));
}

vec3 noise_d(vec2 p) {
	vec2 fi = floor(p);
	ivec2 i = ivec2(fi);
	vec2 f = p - fi;
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	vec2 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);
	vec2 ga = wgrad(i), gb = wgrad(i + ivec2(1, 0)), gc = wgrad(i + ivec2(0, 1)), gd = wgrad(i + ivec2(1, 1));
	float va = dot(ga, f), vb = dot(gb, f - vec2(1, 0)), vc = dot(gc, f - vec2(0, 1)), vd = dot(gd, f - vec2(1, 1));
	float v = va + u.x * (vb - va) + u.y * (vc - va) + u.x * u.y * (va - vb - vc + vd);
	vec2 d = ga + u.x * (gb - ga) + u.y * (gc - ga) + u.x * u.y * (ga - gb - gc + gd)
			+ du * (u.yx * (va - vb - vc + vd) + vec2(vb, vc) - va);
	return vec3(v, d);
}

// Small waves: slopes of five octaves of noise ripples, each stretched across
// its own direction (so crests are elongated, as on real water), turned by an
// irregular angle from the last, drifting at its own deep-water speed, and
// faded by the pixel footprint fp so distant water averages instead of
// sparkling. Noise, not a sum of sines: no interference patterns.
vec2 small_waves(vec2 p, float t, float fp, float base, float spread, float scale, float steepness) {
	vec2 slope = vec2(0.0);
	float lambda = 3.0 * scale;
	float ang = base;
	const float TURN[5] = float[](0.0, 0.83, -1.21, 0.47, -0.66);
	for (int i = 0; i < 5; i++) {
		ang = base + TURN[i] * spread;
		vec2 d = vec2(cos(ang), sin(ang));
		vec2 e = vec2(-d.y, d.x);
		float k = TAU / lambda;
		float speed = sqrt(G / k + 0.074 * k);
		// Coordinates along / across the travel direction, stretched across.
		vec2 q = vec2(dot(p, d) - speed * t, dot(p, e) * 0.45) / lambda;
		vec3 n = noise_d(q + vec2(float(i) * 17.3, float(i) * 5.9));
		vec2 g = (d * n.y + e * n.z * 0.45) / lambda; // back to world gradient
		float fade = clamp((lambda - 3.0 * fp) / (3.0 * fp), 0.0, 1.0);
		slope += g * steepness * lambda * fade;
		lambda *= 0.52;
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
