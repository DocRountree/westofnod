shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

// The moss's sporophytes (OakTree.sporophytes): thin red stalks a couple of
// cm tall standing up off the stumps' and logs' moss, a purple-brown capsule
// at each one's top, swaying (the tip, not the foot) in slow gusts. Each a
// little ribbon turned to the camera, all four corners at its foot in the
// mesh: VERTEX/NORMAL the foot and the bark's normal there, CUSTOM1.xyz the
// foot in the tree's own space, CUSTOM0 the stalk (xyz, the tree's own
// space; w a phase), UV (-1..1 across, 0..1 up), UV2 (1 on a cut end, a
// rank 0..1). They stand where the bark's moss is thick (moss_field, the
// same as bark.gdshader's), more of them the thicker it is; within near_end
// m only, shrinking away before that.

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lichen.gdshaderinc"

uniform float near_end = 12.0;
uniform float sway_tip = 0.006;  // m, the capsule's sway in a full gust
uniform float half_width = 0.0022; // m (the capsule's; the stalk a third of it)
uniform vec3 stalk_base : source_color = vec3(0.36, 0.1, 0.06);
uniform vec3 stalk_top : source_color = vec3(0.72, 0.3, 0.12);
uniform vec3 capsule : source_color = vec3(0.4, 0.22, 0.42);
uniform vec3 capsule_light : source_color = vec3(0.62, 0.48, 0.7);

varying vec3 world_pos;

void vertex() {
	vec3 foot = VERTEX;
	float grow = 0.0;
	if (growth_at(MODEL_MATRIX[3].xz).y > 0.0) {
		float d = distance(foot, CAMERA_POSITION_WORLD);
		if (d < near_end) {
			vec3 obj = CUSTOM1.xyz + vec3(fract(MODEL_MATRIX[3].x * 0.0137), 0.0, fract(MODEL_MATRIX[3].z * 0.0137)) * 61.0;
			float m = moss_field(obj, normalize(NORMAL).y) * (UV2.x > 0.5 ? moss_end : 1.0);
			grow = smoothstep(0.0, 0.1, m - 0.5 - UV2.y * 0.45) * (1.0 - smoothstep(near_end * 0.6, near_end, d));
		}
	}
	if (grow <= 0.0) {
		VERTEX = foot; // (none here: no pixels)
	} else {
		vec3 stalk = mat3(MODEL_MATRIX) * CUSTOM0.xyz * grow;
		float t = UV.y;
		float gust = 0.6 + 0.4 * sin(TIME * 0.37 + dot(foot.xz, vec2(0.21, 0.17)));
		vec3 sw = vec3(sin(TIME * 1.7 + CUSTOM0.w + dot(foot, vec3(3.1, 1.3, 2.7))), 0.0,
				cos(TIME * 1.3 + CUSTOM0.w * 0.7 + dot(foot, vec3(2.3, 2.9, 1.7)))) * sway_tip * gust * grow;
		vec3 at = foot + stalk * t + sw * t * t; // (bending from the foot)
		vec3 along = normalize(stalk + sw * 2.0 * t);
		vec3 to_cam = normalize(CAMERA_POSITION_WORLD - at);
		vec3 side = normalize(cross(along, to_cam));
		VERTEX = at + side * UV.x * half_width * grow;
		NORMAL = normalize(side * UV.x * 0.8 + to_cam * 0.6);
	}
	world_pos = VERTEX;
}

void fragment() {
	float x = UV.x, y = UV.y;
	float c = (y - 0.86) / 0.14; // the capsule: an oval at the top
	bool cap = x * x + c * c <= 1.0;
	if (!cap && (abs(x) > 0.33 || y > 0.86)) discard;
	if (cap) {
		float lit = clamp(0.55 - 0.5 * x + 0.3 * c, 0.0, 1.0);
		ALBEDO = mix(capsule, capsule_light, lit * lit);
		ROUGHNESS = 0.5;
		SPECULAR = 0.35;
	} else {
		ALBEDO = mix(stalk_base, stalk_top, y);
		ROUGHNESS = 0.7;
		SPECULAR = 0.25;
	}
	ALBEDO *= 1.0 - 0.45 * night;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}
