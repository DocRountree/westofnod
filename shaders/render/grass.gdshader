shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled, shadows_disabled;

// Grass clumps near the camera, on open ground (not rock, sand, or under the
// forest canopy), bending in the wind. Toward the edge of the field the blades
// shrink into the ground rather than dither out; the terrain shader draws
// grass beyond, so the edge doesn't show. Matte: no specular, nothing to bloom.

#include "res://shaders/render/scatter.gdshaderinc"

uniform vec3 tip : source_color = vec3(0.50, 0.58, 0.27);
uniform vec3 root : source_color = vec3(0.20, 0.30, 0.10);

varying float hgt;

void vertex() {
	vec3 pos;
	mat3 basis;
	float r;
	float seed, fade;
	bool on = scatter(INSTANCE_ID, pos, basis, r, seed, fade);
	v_rand = seed;
	v_fade = fade;
	vec4 m = mask_at(pos.xz);
	float open = (1.0 - m.r) * (1.0 - m.a) * (1.0 - 0.6 * m.b);
	on = on && r < open * 0.9 && pos.y > 1.0;
	float s = mix(0.7, 1.4, v_rand) * (on ? 1.0 : 0.0) * v_fade;
	vec3 v = VERTEX * s;
	float w = sin(TIME * 2.1 + pos.x * 0.35 + pos.z * 0.27) * 0.12 + 0.06;
	v.x += w * COLOR.g * COLOR.g * s;
	VERTEX = basis * v + pos - MODEL_MATRIX[3].xyz;
	NORMAL = vec3(0.0, 1.0, 0.0);
	hgt = COLOR.g;
}

void fragment() {
	ALBEDO = pow(mix(root, tip, hgt) * mix(0.85, 1.1, v_rand), vec3(2.2));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
