shader_type spatial;
render_mode diffuse_burley, cull_back;

// Trees, scattered by the forest mask (scatter.gdshaderinc). Size, lean and
// foliage colour vary per tree; the crowns sway in the wind.

#include "res://shaders/render/scatter.gdshaderinc"
#include "res://shaders/render/aerial.gdshaderinc"

varying vec3 w_pos;

uniform float density = 1.0;
uniform float size_scale = 1.0; // far crowns stand for more than one tree
uniform vec3 leaf_a : source_color = vec3(0.13, 0.27, 0.09);
uniform vec3 leaf_b : source_color = vec3(0.22, 0.34, 0.11);
uniform vec3 bark : source_color = vec3(0.25, 0.20, 0.15);

varying float part;

void vertex() {
	vec3 pos;
	mat3 basis;
	float r;
	float seed, fade;
	bool on = scatter(INSTANCE_ID, pos, basis, r, seed, fade);
	v_rand = seed;
	v_fade = fade;
	vec4 m = mask_at(pos.xz);
	on = on && r < m.b * density && pos.y > 2.0;
	float s = mix(0.7, 1.35, v_rand) * size_scale * (on ? 1.0 : 0.0);
	vec3 v = VERTEX * vec3(s, s * mix(0.85, 1.2, fract(v_rand * 7.3)), s);
	float sway = COLOR.g * COLOR.g * 0.25 * sin(TIME * 1.3 + pos.x * 0.1 + pos.z * 0.13);
	v.x += sway * s;
	VERTEX = basis * v + pos - MODEL_MATRIX[3].xyz;
	NORMAL = basis * NORMAL;
	part = COLOR.r;
	w_pos = pos + basis * v;
}

void fragment() {
	if (dithered_out(FRAGCOORD.xy, v_fade)) discard;
	vec3 leaves = mix(leaf_a, leaf_b, v_rand);
	ALBEDO = pow(mix(bark, leaves, part), vec3(2.2));
	ROUGHNESS = 0.85;
	FOG = aerial_fog(w_pos, CAMERA_POSITION_WORLD);
	SPECULAR = 0.2;
	// Light through the leaves.
	BACKLIGHT = leaves * 0.2 * part;
}
