shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, skip_vertex_transform;
// (skip_vertex_transform: the vertex goes straight from its position (the
// map's, less world_origin: drawn near the origin, origin.gdshaderinc) to
// view space through the view matrix alone, the same for every patch.
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

uniform float night = 0.0; // 0 day .. 1 night (main.gd)
const float PRAIRIE_NIGHT_DIM = 0.5; // (also ground_cover.gdshader): at night it looks only half again as bright as the forest floor (by day ~2.8x)
uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6);

// Where it is as drawn (small numbers, near the origin): a varying of the
// map's own coordinates, tens of km, loses mm to the rasteriser's
// interpolation, differently as the view moves, so textures (the litter's
// tiles) swam. The map's is made from it per pixel.
varying vec3 local_pos;

void vertex() {
	int lod;
	float morph;
	vec2 wp = cdlod_xz(VERTEX, MODEL_MATRIX, INSTANCE_CUSTOM, lod, morph);
	float h = terrain_height(wp, max(lod - SUB, 0));
	if (morph > 0.0) {
		float hc = terrain_height(wp, max(lod + 1 - SUB, 0));
		h = morph >= 1.0 ? hc : mix(h, hc, morph); // (exactly the coarser level's where they meet)
	}
	VERTEX = (VIEW_MATRIX * vec4(wp.x - world_origin.x, h, wp.y - world_origin.z, 1.0)).xyz;
	NORMAL = mat3(VIEW_MATRIX) * terrain_normal(wp, max(lod - SUB, 0), map_cell() * exp2(float(max(lod - SUB, 0))) * 0.5);
	local_pos = vec3(wp.x - world_origin.x, h, wp.y - world_origin.z);
}

#include "res://shaders/render/ground.gdshaderinc"

// Fallen oak and maple leaves (tools/ground/bake_ground_textures.py), laid
// over the forest's litter near the eye: the litter's colour times the
// texture over its mean, so it fades out with distance without a change of
// colour.
uniform sampler2D litter_tex : filter_linear_mipmap_anisotropic, repeat_enable; // (sRGB values, as col; tileable every way round)
uniform float litter_tile = 1.6; // m
uniform vec3 litter_mean = vec3(0.372, 0.262, 0.153); // the texture's mean (GroundCover sets it)
uniform vec2 litter_fade = vec2(25.0, 45.0); // m
// Fallen pine needles (tools/ground/bake_ground_textures.py), laid over the
// taiga's needle duff near the eye, as the leaves over the forest's litter.
uniform sampler2D needle_tex : filter_linear_mipmap_anisotropic, repeat_enable; // (sRGB values; tileable every way round)
uniform float needle_tile = 0.8; // m
uniform vec3 needle_mean = vec3(0.4, 0.27, 0.16); // the texture's mean (GroundCover sets it)

// A litter texture at the pixel (its tiles tile m, from the origin's own
// tile: small, exact numbers), each tile turned a random quarter turn (the
// texture fits itself every way round) so its repeat doesn't show, the
// derivatives turned with it (no coarse mip at the seams); salt: another
// pattern of turns.
vec3 litter_sample(sampler2D tex, float tile_m, vec3 lp, ivec2 salt) {
	vec2 o_tiles = floor(world_origin.xz / tile_m);
	vec2 uv = (lp.xz + (world_origin.xz - o_tiles * tile_m)) / tile_m;
	vec2 tile = floor(uv);
	vec2 f = uv - tile;
	int turn = int(hash(ivec2(tile) + ivec2(o_tiles) + salt) * 4.0) & 3;
	vec2 dx = dFdx(uv), dy = dFdy(uv);
	for (int k = 0; k < turn; k++) {
		f = vec2(f.y, 1.0 - f.x);
		dx = vec2(dx.y, -dx.x);
		dy = vec2(dy.y, -dy.x);
	}
	return textureGrad(tex, f, dx, dy).rgb;
}

void fragment() {
	vec3 world_pos = local_pos + world_origin; // (the map's)
	vec2 p = world_pos.xz;
	float fp = max(length(fwidth(p)), 0.01);
	int pm = pixel_mip(fp);
	vec3 n = terrain_normal(p, pm, max(fp, 0.5) * 1.5 + map_cell() * exp2(float(pm)) * 0.25);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float h = world_pos.y;
	vec4 m = texture(mask_tex, map_uv(p));

	Shared sh = ground_shared(p, h, n, m, fp);
	float patches = sh.patches;

	// The biome here: the sixteen nearest texels of the biome map blended
	// (biome_grid(): the point jittered, so borders wander), the two with
	// most of it worked out (biome_top()), by their shares
	vec2 bg = biome_grid(p);
	int b1, b2;
	float w1, w2;
	biome_top(bg, b1, w1, b2, w2);
	float r_, k_, l_;
	vec3 col = biome_ground(b1, sh, r_, k_, l_) * w1;
	float rough = r_ * w1;
	float rocky = k_ * w1;
	// litter: the forest's fallen leaves; needles: the taiga's fallen needles
	float litter = b1 == 5 ? 0.0 : l_ * w1;
	float needles = b1 == 5 ? l_ * w1 : 0.0;
	if (w2 > 0.002) {
		col += biome_ground(b2, sh, r_, k_, l_) * w2;
		rough += r_ * w2;
		rocky += k_ * w2;
		if (b2 == 5)
			needles += l_ * w2;
		else
			litter += l_ * w2;
	} else {
		w2 = 0.0;
	}
	// (the shares of a few: the prairie and coast dim at night, the forest
	// and taiga carry the distant canopy)
	float prairie = (b1 == 2 ? w1 : 0.0) + (b2 == 2 ? w2 : 0.0);
	float coast = (b1 == 10 ? w1 : 0.0) + (b2 == 10 ? w2 : 0.0);
	float forest = (b1 == 0 ? w1 : 0.0) + (b2 == 0 ? w2 : 0.0);
	float taiga = (b1 == 5 ? w1 : 0.0) + (b2 == 5 ? w2 : 0.0);
	// the fallen leaves, near
	float near = 1.0 - smoothstep(litter_fade.x, litter_fade.y, distance(world_pos, CAMERA_POSITION_WORLD + world_origin));
	if (litter * near > 0.0) {
		vec3 leaves = litter_sample(litter_tex, litter_tile, local_pos, ivec2(911, -373)) / litter_mean;
		col *= mix(vec3(1.0), leaves, litter * near * (1.0 - rocky));
	}
	// and the fallen needles (the same: over their mean, fading out with
	// distance without a change of colour)
	if (needles * near > 0.0) {
		vec3 nd = litter_sample(needle_tex, needle_tile, local_pos, ivec2(-517, 263)) / needle_mean;
		col *= mix(vec3(1.0), nd, needles * near * (1.0 - rocky));
	}

	vec3 sand = mix(vec3(0.84, 0.80, 0.68), vec3(0.90, 0.86, 0.74), patches);
	vec3 seabed = mix(vec3(0.70, 0.68, 0.56), vec3(0.42, 0.44, 0.40), smoothstep(-2.0, -25.0, h));
	col = mix(col, sand, m.a * (1.0 - rocky * 0.7));
	// the pale grounds (the prairie's, the coast's, the beaches' sand) a
	// little darker at night (main.gd: night), as the leaves are
	col *= 1.0 - PRAIRIE_NIGHT_DIM * night * clamp(prairie + coast + m.a * (1.0 - rocky * 0.7), 0.0, 1.0);
	col = mix(col, seabed, 1.0 - smoothstep(-1.0, 0.2, h));
	col *= mix(1.0, 0.78, (1.0 - smoothstep(0.0, 0.6, h)) * step(-0.3, h)); // damp line
	// past where the trees are drawn (OakTree.VIEW, 600 m), their canopy
	// painted on the ground, as much of it as the trees there would cover
	// (from their density by biome: oak.tres, as Population places them): crowns lit on top, shadow between, fading to their mean
	// once a pixel is wider than a crown
	float far_trees = smoothstep(520.0, 640.0, distance(world_pos, CAMERA_POSITION_WORLD + world_origin));
	if (far_trees > 0.0) {
		float cover = (forest * 0.46 + taiga * 0.04 + prairie * 0.03) * (1.0 - rocky) * (1.0 - m.a) * step(0.4, h)
				* (1.0 - smoothstep(575.0, 1150.0, h)); // (the oaks thinning up the mountains: oak.tres, Population)
		float crowns = vnoise(p / 5.0) * 0.55 + vnoise(p / 13.0 + 4.1) * 0.45;
		crowns = mix(crowns, 0.5, smoothstep(2.0, 8.0, fp));
		vec3 canopy = mix(vec3(0.05, 0.07, 0.035), vec3(0.17, 0.25, 0.09), smoothstep(0.3, 0.7, crowns));
		canopy *= 1.0 - 0.5 * night; // (as the leaves: leaves.gdshader NIGHT_DIM)
		float c = clamp(cover * 1.6, 0.0, 1.0) * far_trees;
		col = mix(col, canopy, c);
		rough = mix(rough, 1.0, c);
	}
	float fine = mix(0.5, vnoise(p * 0.7), 1.0 - smoothstep(0.4, 1.2, fp * 0.7));
	col *= 0.92 + 0.16 * fine;

	ALBEDO = pow(col, vec3(2.2));
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD + world_origin);
	ROUGHNESS = rough;
	// matte where it's rough (dry ground: no sheen, even at a glancing
	// look), glossy only where it's smooth (standing water)
	SPECULAR = mix(0.5, 0.03, smoothstep(0.3, 0.8, rough));
	SPECULAR *= 1.0 - 0.65 * night; // (the swamp's pools: the moon and night sky's glints, under the night's wider exposure, were too bright)
}
