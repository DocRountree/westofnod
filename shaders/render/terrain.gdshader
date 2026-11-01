shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, skip_vertex_transform;
// (skip_vertex_transform: the vertex goes straight from its world position
// to view space through the view matrix alone, the same for every patch.
// Otherwise each patch's model matrix is multiplied into the view in 32-bit
// floats, which rounds differently per patch tens of km out: shared edges
// land millimetres apart, hairline cracks that show the sky as dotted lines.)

// The terrain: CDLOD patches over one height map (no tiles, no near/far
// switch). Normals and materials are per pixel, from the finest mip the pixel
// can show, so detail fades smoothly with distance instead of popping.
//
// Materials by biome (biome_ground(): forest, mesa, prairie, swamp, tundra,
// taiga, plateau, volcano, mountains, island, coast), blended across their
// borders; within each, ground in broad patches and small clumps, bare rock
// on near-cliffs (banded red sandstone on the mesas and plateaus), snow high
// up in the north; then beaches, the damp line and the sea floor.

#include "res://shaders/render/height_map.gdshaderinc"
#include "res://shaders/render/aerial.gdshaderinc"

uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6);

varying vec3 world_pos;

void vertex() {
	int lod;
	float morph;
	vec2 wp = cdlod_xz(VERTEX, MODEL_MATRIX, INSTANCE_CUSTOM, lod, morph);
	float h = terrain_height(wp, max(lod - SUB, 0));
	if (morph > 0.0) {
		float hc = terrain_height(wp, max(lod + 1 - SUB, 0));
		h = morph >= 1.0 ? hc : mix(h, hc, morph); // (exactly the coarser level's where they meet)
	}
	VERTEX = (VIEW_MATRIX * vec4(wp.x, h, wp.y, 1.0)).xyz;
	NORMAL = mat3(VIEW_MATRIX) * terrain_normal(wp, max(lod - SUB, 0), map_cell() * exp2(float(max(lod - SUB, 0))) * 0.5);
	world_pos = vec3(wp.x, h, wp.y);
}

#include "res://shaders/render/ground.gdshaderinc"

// Fallen oak and maple leaves (tools/ground/bake_ground_textures.py), laid
// over the forest's litter near the eye: the litter's colour times the
// texture over its mean, so it fades out with distance without a change of
// colour.
uniform sampler2D litter_tex : filter_linear_mipmap_anisotropic, repeat_enable; // (sRGB values, as col)
uniform float litter_tile = 1.6; // m
uniform vec3 litter_mean = vec3(0.372, 0.262, 0.153); // the texture's mean (GroundCover sets it)
uniform vec2 litter_fade = vec2(25.0, 45.0); // m

void fragment() {
	vec2 p = world_pos.xz;
	float fp = max(length(fwidth(p)), 0.01);
	int pm = pixel_mip(fp);
	vec3 n = terrain_normal(p, pm, max(fp, 0.5) * 1.5 + map_cell() * exp2(float(pm)) * 0.25);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float h = world_pos.y;
	vec4 m = texture(mask_tex, map_uv(p));

	Shared sh = ground_shared(p, h, n, m, fp);
	float patches = sh.patches;

	// The biome here: the four nearest texels of the biome map blended by
	// distance (biome_grid(): the point jittered, so borders wander).
	vec2 bg = biome_grid(p);
	vec3 col = vec3(0.0);
	float rough = 0.0;
	float rocky = 0.0;
	float litter = 0.0;
	for (int k = 0; k < 4; k++) {
		float w;
		int b = biome_texel(bg, k, w);
		if (w <= 0.0)
			continue;
		float r_, k_, l_;
		col += biome_ground(b, sh, r_, k_, l_) * w;
		rough += r_ * w;
		rocky += k_ * w;
		litter += l_ * w;
	}
	// the fallen leaves, near
	float near = 1.0 - smoothstep(litter_fade.x, litter_fade.y, distance(world_pos, CAMERA_POSITION_WORLD));
	if (litter * near > 0.0) {
		vec3 leaves = texture(litter_tex, p / litter_tile).rgb / litter_mean;
		col *= mix(vec3(1.0), leaves, litter * near * (1.0 - rocky));
	}

	vec3 sand = mix(vec3(0.84, 0.80, 0.68), vec3(0.90, 0.86, 0.74), patches);
	vec3 seabed = mix(vec3(0.70, 0.68, 0.56), vec3(0.42, 0.44, 0.40), smoothstep(-2.0, -25.0, h));
	col = mix(col, sand, m.a * (1.0 - rocky * 0.7));
	col = mix(col, seabed, 1.0 - smoothstep(-1.0, 0.2, h));
	col *= mix(1.0, 0.78, (1.0 - smoothstep(0.0, 0.6, h)) * step(-0.3, h)); // damp line
	float fine = mix(0.5, vnoise(p * 0.7), 1.0 - smoothstep(0.4, 1.2, fp * 0.7));
	col *= 0.92 + 0.16 * fine;

	ALBEDO = pow(col, vec3(2.2));
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
	ROUGHNESS = rough;
	SPECULAR = 0.25;
}
