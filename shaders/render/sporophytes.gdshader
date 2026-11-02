shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

// The moss's sporophytes (OakTree._sporophyte_multimesh): thin red stalks 1-2.2 cm
// tall standing straight up off the stumps' and logs' moss, still, a
// dark purple capsule (a spheroid, long along the stalk) on each one's
// top. Each is an instance of a MultiMesh (OakTree._sporophyte_multimesh)
// drawn on a log or stump near the player: every corner of the template at
// its origin, told apart by UV (UV.x the way round 0..1, UV.y up the stalk
// 0..1 or on the capsule, 2 its bottom .. 3 its top). The instance: its
// origin the foot, basis x the bark's normal there, y the stalk; its
// colour the bark's UV there (COLOR.rg);
// INSTANCE_CUSTOM.xyz the foot in the tree's own space, .w 2 on a cut end +
// a rank 0..1. They stand only on the green moss the bark shows there
// (moss_cover, read from moss.png where the bark reads it), more of them
// the thicker it is, each whole or not at all; within near_end m of the
// player only.

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lichen.gdshaderinc"

uniform float near_end = 4.0;   // m from the player
uniform vec3 player = vec3(0.0); // on the map (main.gd, each frame: OakTree.set_player)
uniform float stalk_r = 0.00045;  // m
uniform vec2 capsule_r = vec2(0.0015, 0.003); // m: round, along the stalk (longer that way)
uniform vec3 stalk_base : source_color = vec3(0.33, 0.17, 0.12);
uniform vec3 stalk_top : source_color = vec3(0.58, 0.37, 0.24);
uniform vec3 capsule : source_color = vec3(0.26, 0.19, 0.27);

varying vec3 world_pos;

void vertex() {
	vec3 foot = VERTEX; // (the template's corners are all at the origin: the foot)
	float grow = 0.0;
	vec3 tree = NODE_POSITION_WORLD + world_origin; // (on the map)
	bool cut_end = INSTANCE_CUSTOM.w > 1.5;
	float rank = INSTANCE_CUSTOM.w - (cut_end ? 2.0 : 0.0);
	if (moss_any_biome || growth_at(tree.xz).y > 0.0) {
		float d = distance(foot + world_origin, player);
		if (d < near_end) {
			vec3 obj = INSTANCE_CUSTOM.xyz + vec3(fract(tree.x * 0.0137), 0.0, fract(tree.z * 0.0137)) * 61.0;
			float up = normalize(MODEL_MATRIX[0].xyz).y;
			float m = moss_field(obj, up) * (cut_end ? moss_end : 1.0);
			// the moss the bark shows here (as bark.gdshader: its texture
			// read where the bark reads it)
			vec2 bark_off = fract(tree.xz * vec2(0.0419, 0.0283) + tree.zx * vec2(0.0157, 0.0233)) * vec2(1.0, 5.0);
			vec2 muv = cut_end ? obj.xz / 0.3 : COLOR.rg * 2.0 + bark_off;
			vec3 mc;
			float mh;
			// (the moss's texture blurred to its tufts, a couple of cm: read
			// sharp, its odd tall shoot stood up out of bare bark)
			float cover = moss_cover(obj, up, 1.0, textureLod(moss_tex, muv, 4.0), mc, mh) * (cut_end ? moss_end : 1.0);
			grow = step(0.6, cover) * step(0.55 + rank * 0.35, m); // (whole, or not there; only where it's thick)
		}
	}
	if (grow <= 0.0) {
		VERTEX = foot; // (none here: no pixels)
	} else {
		vec3 stalk = MODEL_MATRIX[1].xyz * grow;
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
