shader_type spatial;
render_mode diffuse_burley;

// Boulders, scattered by the rock mask, half sunk into the ground, stretched
// and turned so no two match.

#include "res://shaders/render/scatter.gdshaderinc"

uniform float density = 0.6;

void vertex() {
	vec3 pos;
	mat3 basis;
	float r;
	float seed, fade;
	bool on = scatter(INSTANCE_ID, pos, basis, r, seed, fade);
	v_rand = seed;
	v_fade = fade;
	vec4 m = mask_at(pos.xz);
	on = on && r < m.r * density;
	float s = mix(0.6, 2.8, v_rand * v_rand) * (on ? 1.0 : 0.0);
	vec3 st = vec3(1.0, mix(0.6, 1.3, fract(v_rand * 5.7)), mix(0.7, 1.4, fract(v_rand * 3.1)));
	VERTEX = basis * (VERTEX * st * s) + pos - vec3(0.0, 0.25 * s, 0.0) - MODEL_MATRIX[3].xyz;
	NORMAL = basis * NORMAL;
}

void fragment() {
	if (dithered_out(FRAGCOORD.xy, v_fade)) discard;
	vec3 c = mix(vec3(0.32, 0.31, 0.29), vec3(0.45, 0.43, 0.40), v_rand);
	ALBEDO = pow(c, vec3(2.2));
	ROUGHNESS = 0.9;
}
