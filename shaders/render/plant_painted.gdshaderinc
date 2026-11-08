// A plant built whole (PlantMesh: the desert's), painted by its vertices'
// colours, as PlantMesh.painted() draws it, but drawn over its level of
// detail's span only, stippled into the next (lod_fade.gdshaderinc), and
// hazed far off as the trees are (aerial.gdshaderinc). Included by
// plant_painted.gdshader (its back faces culled) and
// plant_painted_two_sided.gdshader (not: petals, thin leaves).

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/lod_fade.gdshaderinc"

uniform float roughness_v = 0.7;
uniform float rim_v = 0.0; // (PlantMesh.painted: sheen)

varying vec3 world_pos;

void vertex() {
	lod_f = lod_vertex(CAMERA_POSITION_WORLD, MODEL_MATRIX, PROJECTION_MATRIX);
	if (lod_gone(lod_f))
		VERTEX = vec3(0.0);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (lod_hidden(FRAGCOORD.xy, lod_f)) discard;
	ALBEDO = COLOR.rgb;
	ROUGHNESS = roughness_v;
	RIM = rim_v;
	RIM_TINT = 0.3;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}
