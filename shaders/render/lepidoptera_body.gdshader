shader_type spatial;

// A butterfly's or a moth's body parts (Lepidoptera._part, _stick): a part's
// own colour, soft (its scales, its hairs: rim, the light catching them at
// its edges).

#include "res://shaders/render/wind.gdshaderinc"

// swaying with the flower it's on (or at): as the flower's own shader sways
// its head at sway_at, by sway_k (the clump's sway * its height's share,
// squared): the whole of it moved as the head is, on the GPU, with it
uniform vec3 sway_at;
uniform float sway_k = 0.0;

uniform vec3 albedo : source_color = vec3(0.5);
uniform float roughness = 0.7;
uniform float rim = 0.0;
uniform float rim_tint = 0.6;

void vertex() {
	if (sway_k > 0.0)
		VERTEX += inverse(mat3(MODEL_MATRIX)) * wind_sway(sway_at + world_origin, TIME) / max(sway, 1e-3) * sway_k;
}

void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = roughness;
	RIM = rim;
	RIM_TINT = rim_tint;
}
