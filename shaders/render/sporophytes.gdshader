shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

// The moss's sporophytes (OakTree.sporophytes): thin red stalks 1-2.2 cm
// tall standing straight up off the stumps' and logs' moss, still, a
// purple-brown capsule (a spheroid, long along the stalk) on each one's
// top. All of a sporophyte's corners are at its foot in the mesh:
// VERTEX/NORMAL the foot and the bark's normal there, CUSTOM1.xyz the foot
// in the tree's own space, CUSTOM0.xyz the stalk (the tree's own space),
// UV.x the way round (0..1), UV.y up the stalk (0..1) or on the capsule (2
// its bottom .. 3 its top), UV2 (1 on a cut end, a rank 0..1). They stand
// where the bark's moss is thick (moss_field, the same as bark.gdshader's),
// more of them the thicker it is, each whole or not at all; within
// near_end m of the player only.

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lichen.gdshaderinc"

uniform float near_end = 4.0;   // m from the player
uniform vec3 player = vec3(0.0); // (main.gd, each frame: OakTree.set_player)
uniform float stalk_r = 0.00045;  // m
uniform vec2 capsule_r = vec2(0.0015, 0.003); // m: round, along the stalk (longer that way)
uniform vec3 stalk_base : source_color = vec3(0.36, 0.1, 0.06);
uniform vec3 stalk_top : source_color = vec3(0.72, 0.3, 0.12);
uniform vec3 capsule : source_color = vec3(0.4, 0.22, 0.42);

varying vec3 world_pos;

void vertex() {
	vec3 foot = VERTEX;
	float grow = 0.0;
	if (growth_at(MODEL_MATRIX[3].xz).y > 0.0) {
		float d = distance(foot, player);
		if (d < near_end) {
			vec3 obj = CUSTOM1.xyz + vec3(fract(MODEL_MATRIX[3].x * 0.0137), 0.0, fract(MODEL_MATRIX[3].z * 0.0137)) * 61.0;
			float m = moss_field(obj, normalize(NORMAL).y) * (UV2.x > 0.5 ? moss_end : 1.0);
			grow = step(0.35 + UV2.y * 0.35, m); // (whole, or not there)
		}
	}
	if (grow <= 0.0) {
		VERTEX = foot; // (none here: no pixels)
	} else {
		vec3 stalk = mat3(MODEL_MATRIX) * CUSTOM0.xyz * grow;
		bool on_capsule = UV.y > 1.5;
		float t = on_capsule ? 1.0 : UV.y;
		vec3 at = foot + stalk * t;
		vec3 along = normalize(stalk);
		vec3 u = normalize(cross(along, abs(along.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
		vec3 v = cross(along, u);
		float a = UV.x * 6.2832;
		vec3 radial = u * cos(a) + v * sin(a);
		if (on_capsule) {
			float phi = (UV.y - 2.5) * 3.1416;
			vec2 r = capsule_r * grow;
			VERTEX = at + along * r.y + radial * cos(phi) * r.x + along * sin(phi) * r.y;
			NORMAL = normalize(radial * cos(phi) / r.x + along * sin(phi) / r.y);
		} else {
			VERTEX = at + radial * stalk_r * grow * (1.0 - 0.3 * t);
			NORMAL = radial;
		}
	}
	world_pos = VERTEX;
}

void fragment() {
	if (UV.y > 1.5) {
		ALBEDO = capsule;
		ROUGHNESS = 0.45;
		SPECULAR = 0.4;
	} else {
		ALBEDO = mix(stalk_base, stalk_top, UV.y);
		ROUGHNESS = 0.7;
		SPECULAR = 0.25;
	}
	ALBEDO *= 1.0 - 0.45 * night;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}
