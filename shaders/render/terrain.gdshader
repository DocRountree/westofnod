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

global uniform float night; // 0 day .. 1 night (main.gd: a global)
const float PRAIRIE_NIGHT_DIM = 0.5; // (also ground_cover.gdshader): at night it looks only half again as bright as the forest floor (by day ~2.8x)
uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6);

// Where it is as drawn (small numbers, near the origin): a varying of the
// map's own coordinates, tens of km, loses mm to the rasteriser's
// interpolation, differently as the view moves, so textures (the litter's
// tiles) swam. The map's is made from it per pixel.
varying vec3 local_pos;
// How far the ground here is raised as the woods' canopy (m): past where
// the trees are drawn, the forest's top, not the ground under it, is what's
// seen (its outline along the ridges).
varying float canopy_lift;

#include "res://shaders/render/ground.gdshaderinc"

// The woods, past where the trees are drawn (OakTree.VIEW, 600 m): how
// much of the ground their crowns cover seen from above (0..1), and how
// much of that is conifers (conifer). From where Population puts them
// (data/population/props/: their densities by biome, their height ranges,
// none on ground steeper than they stand on): the forest's broadleaves
// (oaks, maples, walnuts, tulip trees: thinning up the mountains), the
// prairie's few, the swamp's sycamores; the taiga's lodgepoles and
// cypresses (to 1350 m) and spruces (thinning out from 650 m, none past
// 1050). ny: the ground's normal's y.
float woods_cover(vec2 p, float h, float ny, out float conifer) {
	int b1, b2;
	float w1, w2;
	biome_top(biome_grid(p), b1, w1, b2, w2);
	float forest = (b1 == 0 ? w1 : 0.0) + (b2 == 0 && b2 != b1 ? w2 : 0.0);
	float prairie = (b1 == 2 ? w1 : 0.0) + (b2 == 2 && b2 != b1 ? w2 : 0.0);
	float swamp = (b1 == 3 ? w1 : 0.0) + (b2 == 3 && b2 != b1 ? w2 : 0.0);
	float taiga = (b1 == 5 ? w1 : 0.0) + (b2 == 5 && b2 != b1 ? w2 : 0.0);
	float broad = (forest * 0.62 + prairie * 0.06 + swamp * 0.05) * (1.0 - smoothstep(575.0, 1150.0, h));
	float con = taiga * (0.4 * (1.0 - smoothstep(675.0, 1350.0, h)) + 0.25 * (1.0 - smoothstep(650.0, 1050.0, h)));
	conifer = con / max(broad + con, 1e-4);
	return clamp((broad + con) * 1.6, 0.0, 1.0) * smoothstep(0.68, 0.84, ny) * step(0.4, h);
}

// The canopy's height there (m), where it's whole.
const float CANOPY_BROAD = 15.0;
const float CANOPY_CONIFER = 17.0;
// From how far (m) it's raised (OakTree.VIEW: the last trees drawn), fully by the second.
const vec2 CANOPY_LIFT = vec2(600.0, 900.0);

void vertex() {
	int lod;
	float morph;
	vec2 wp = cdlod_xz(VERTEX, MODEL_MATRIX, INSTANCE_CUSTOM, lod, morph);
	// (the height by terrain_height() itself, as the neighbouring patches
	// work theirs out, to the last bit: no cracks; the slope apart)
	float h = terrain_height(wp, max(lod - SUB, 0));
	vec2 slope;
	terrain_height_grad(wp, max(lod - SUB, 0), map_cell() * exp2(float(max(lod - SUB, 0))) * 0.5, slope);
	if (morph > 0.0) {
		float hc = terrain_height(wp, max(lod + 1 - SUB, 0));
		h = morph >= 1.0 ? hc : mix(h, hc, morph); // (exactly the coarser level's where they meet)
	}
	// the canopy: raised by the woods there, from where the trees are no
	// longer drawn (as everything here: from the map and the camera alone,
	// the slope from a mip fixed for every level, so neighbouring patches
	// raise their shared vertices alike)
	canopy_lift = 0.0;
	float far = distance(wp, view_pos.xz) / lod_zoom;
	if (far > CANOPY_LIFT.x) {
		const float SPAN = 70.0;
		float gx = height_m(wp + vec2(SPAN, 0.0), 2) - height_m(wp - vec2(SPAN, 0.0), 2);
		float gz = height_m(wp + vec2(0.0, SPAN), 2) - height_m(wp - vec2(0.0, SPAN), 2);
		float ny = 2.0 * SPAN / length(vec3(gx, 2.0 * SPAN, gz));
		float con;
		float cov = woods_cover(wp, h, ny, con);
		canopy_lift = cov * mix(CANOPY_BROAD, CANOPY_CONIFER, con) * smoothstep(CANOPY_LIFT.x, CANOPY_LIFT.y, far);
		h += canopy_lift;
	}
	VERTEX = (VIEW_MATRIX * vec4(wp.x - world_origin.x, h, wp.y - world_origin.z, 1.0)).xyz;
	NORMAL = mat3(VIEW_MATRIX) * slope_normal(slope); // (the shadow passes' normal bias: the colour pass works its own out per pixel)
	local_pos = vec3(wp.x - world_origin.x, h, wp.y - world_origin.z);
}


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
// The player's footprints near (Footprints: R pressed in, B the rim pushed
// up, G mud carried), over print_window (its corner on the map, x and z;
// its size, m; 0: none): pressed into the mud (forest's, prairie's), the
// mud carried onto the forest's floor.
uniform sampler2D print_tex : filter_linear, repeat_disable;
uniform vec3 print_window = vec3(0.0);
uniform float print_depth = 0.04; // m: a boot pressed in all the way
// Bare rock (tools/ground/bake_rock_texture.py: RG its slopes, B cavity, A
// brightness), laid on the rock from the three sides it faces
// (triplanar), at two scales (rock_tile, and a turned copy ~6.7 times as
// big, so neither's repeat shows): its facets and cracks catch the light.
uniform sampler2D rock_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float rock_tile = 6.0; // m
const float ROCK_BIG = 6.666667; // (x rock_tile: 40 m)
const vec3 FOREST_MUD = vec3(0.11, 0.085, 0.06); // (as ground.gdshaderinc's)

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
	vec2 slope;
	terrain_height_grad(p, pm, max(fp, 0.5) * 1.5 + map_cell() * exp2(float(pm)) * 0.25, slope);
	vec3 n = slope_normal(slope);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float h = world_pos.y - canopy_lift; // (the ground's, under any canopy)
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
	float r_, k_, l_, f_, s_;
	vec3 col = biome_ground_face(b1, sh, r_, k_, l_, f_, s_) * w1;
	float rough = r_ * w1;
	float rocky = k_ * w1;
	float face = f_ * w1; // (the rock itself, for its texture)
	// litter: the forest's fallen leaves; needles: the taiga's fallen needles
	float litter = b1 == 5 ? 0.0 : l_ * w1;
	float needles = b1 == 5 ? l_ * w1 : 0.0;
	if (w2 > 0.002) {
		col += biome_ground_face(b2, sh, r_, k_, l_, f_, s_) * w2;
		rough += r_ * w2;
		rocky += k_ * w2;
		face += f_ * w2;
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
	float swamp = (b1 == 3 ? w1 : 0.0) + (b2 == 3 ? w2 : 0.0);
	// the rock's texture (where's there's rock): from the three sides, each
	// as much as the rock faces that way; its slopes into the normal
	// (added in each side's plane), its cavity and brightness into the colour
	{
		vec3 q = local_pos + vec3(mod(world_origin.x, rock_tile * ROCK_BIG * 6.0), 0.0, mod(world_origin.z, rock_tile * ROCK_BIG * 6.0)); // (small, exact numbers)
		vec3 qx = dFdx(q) / rock_tile, qy = dFdy(q) / rock_tile;
		if (face > 0.003) {
			vec3 tw = pow(abs(n), vec3(4.0));
			tw /= tw.x + tw.y + tw.z;
			vec3 u = q / rock_tile;
			const mat2 TURN = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) / ROCK_BIG; // (the big one: turned, so their grains cross)
			vec4 ax = textureGrad(rock_tex, u.zy, qx.zy, qy.zy) * 0.6 + textureGrad(rock_tex, TURN * u.zy + 0.31, TURN * qx.zy, TURN * qy.zy) * 0.4;
			vec4 ay = textureGrad(rock_tex, u.xz, qx.xz, qy.xz) * 0.6 + textureGrad(rock_tex, TURN * u.xz + 0.57, TURN * qx.xz, TURN * qy.xz) * 0.4;
			vec4 az = textureGrad(rock_tex, u.xy, qx.xy, qy.xy) * 0.6 + textureGrad(rock_tex, TURN * u.xy + 0.13, TURN * qx.xy, TURN * qy.xy) * 0.4;
			vec4 a = ax * tw.x + ay * tw.y + az * tw.z;
			vec2 tx = ax.rg * 2.0 - 1.0, ty = ay.rg * 2.0 - 1.0, tz = az.rg * 2.0 - 1.0;
			vec3 bump = vec3(0.0, tx.y, tx.x) * tw.x + vec3(ty.x, 0.0, ty.y) * tw.y + vec3(tz.x, tz.y, 0.0) * tw.z;
			n = normalize(n + bump * 1.6 * face);
			NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
			col *= mix(1.0, 2.0 * a.a * (0.7 + 0.6 * a.b), face);
		}
	}
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
	// (from their density by biome: data/population/props/, as Population
	// places them: the forest's oaks, maples, walnuts and tulip trees, the taiga's pines and
	// cypresses, the prairie's few, the swamp's sycamores): crowns lit on
	// top, shadow between, fading to their mean once a pixel is wider than
	// a crown
	float far_trees = smoothstep(520.0, 640.0, distance(world_pos, CAMERA_POSITION_WORLD + world_origin));
	if (far_trees > 0.0) {
		float conifer;
		float top = woods_cover(p, h, n.y, conifer) * (1.0 - rocky) * (1.0 - m.a);
		// seen at a slant, the trees hide more of the ground between them
		// (their sides, not only their tops): nearly all of it toward the
		// horizon
		vec3 eye = normalize(CAMERA_POSITION_WORLD + world_origin - world_pos);
		float slant = clamp(dot(eye, n), 0.04, 1.0);
		// (in clumps and glades, tens of metres across: not an even
		// carpet; and their edges ragged)
		float clumps = vnoise(p / 31.0 + 7.7) * 0.6 + vnoise(p / 93.0 - 3.1) * 0.4;
		top *= smoothstep(0.18, 0.62, clumps + (top - 0.5) * 0.5);
		float seen = 1.0 - pow(1.0 - min(top, 0.97), 1.0 / mix(0.3, 1.0, slant));
		// the crowns, one to a cell of a jittered grid (the trees' spacing
		// where they're thick), there as often as the woods are thick; each
		// a dome (broadleaves) or a steep cone (conifers), wider the more
		// slanting the view (their sides), lit by the sun as they face;
		// between them shade. Their mean once smaller than a pixel.
		float cs = mix(7.0, 4.5, conifer);
		vec2 g = p / cs;
		vec2 gi = floor(g);
		float best = 9.0;
		vec2 bq = vec2(0.0);
		float tint = 1.0;
		float rr = 0.6 * (1.0 + 0.5 * (1.0 - slant));
		for (int k = 0; k < 9; k++) {
			vec2 c = gi + vec2(float(k % 3 - 1), float(k / 3 - 1));
			ivec2 ic = ivec2(c);
			if (hash(ic + ivec2(71, 13)) > seen * 1.2)
				continue;
			vec2 at = c + 0.2 + 0.6 * vec2(hash(ic), hash(ic + ivec2(5, 9)));
			float r = rr * (0.75 + 0.5 * hash(ic + ivec2(-3, 17)));
			vec2 q = (g - at) / r;
			float d = length(q);
			if (d < best) {
				best = d;
				bq = q;
				tint = 0.82 + 0.36 * hash(ic + ivec2(31, -7));
			}
		}
		float detail = 1.0 - smoothstep(cs * 0.2, cs * 0.6, fp);
		float inside = smoothstep(1.0, 0.8, best);
		vec3 leaf = mix(vec3(0.2, 0.33, 0.11), vec3(0.17, 0.26, 0.11), conifer) * 0.85; // (the leaves' and needles' own colours: their textures' means, in their own shade)
		vec3 canopy = mix(leaf * 0.32, leaf * tint, inside);
		// (past where crowns can be told apart: their mean, lighter and
		// darker in patches as stands of lit and shaded crowns are)
		float stands = 0.8 + 0.4 * vnoise(p / 17.0 - 2.3);
		canopy = mix(leaf * mix(0.32, 1.0, min(seen * 1.1, 1.0)) * stands, canopy, detail);
		canopy *= 1.0 - 0.5 * night; // (as the leaves: leaves.gdshader NIGHT_DIM)
		float c = smoothstep(0.02, 0.5, seen) * far_trees;
		col = mix(mix(col, col * 0.7, smoothstep(0.0, 0.2, seen) * far_trees), canopy, c); // (the ground at the woods' edge in their shade)
		rough = mix(rough, 1.0, c);
		// the crown's own slope for the light: a dome, or a steep cone
		float k = mix(1.1, 2.4, conifer);
		vec3 nc = normalize(vec3(bq.x * k, 1.0, bq.y * k) + vec3(n.x, 0.0, n.z));
		n = normalize(mix(n, nc, inside * detail * c));
		NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	}
	// the footprints: one read a pixel near; only where there's a print the
	// mud here and the print's slopes worked out
	vec2 puv = (p - print_window.xy) / max(print_window.z, 1e-3);
	if (print_window.z > 0.0 && puv.x > 0.0 && puv.y > 0.0 && puv.x < 1.0 && puv.y < 1.0) {
		vec4 pr = textureLod(print_tex, puv, 0.0);
		if (pr.r + pr.g + pr.b > 0.004) {
			float pud;
			float mud = (b1 == 0 || b1 == 2 ? biome_mud(b1, sh, pud) * w1 : 0.0) + (b2 == 0 || b2 == 2 ? biome_mud(b2, sh, pud) * w2 : 0.0);
			if (mud > 0.0) {
				// pressed in: the print's height (down in it, up round it), its
				// slopes bending the normal
				float e = 1.0 / float(textureSize(print_tex, 0).x);
				vec4 px = textureLod(print_tex, puv + vec2(e, 0.0), 0.0);
				vec4 pz = textureLod(print_tex, puv + vec2(0.0, e), 0.0);
				float h0 = pr.b * 0.35 - pr.r;
				vec2 g = vec2(px.b * 0.35 - px.r - h0, pz.b * 0.35 - pz.r - h0) * print_depth * mud / (print_window.z * e);
				n = normalize(n - vec3(g.x, 0.0, g.y));
				NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
				col *= 1.0 - 0.3 * clamp(pr.r, 0.0, 1.0) * mud; // (wetter down in it)
				rough = mix(rough, 0.7, 0.5 * clamp(pr.r, 0.0, 1.0) * mud);
			}
			// the mud carried on the boots, left on the forest's floor
			col = mix(col, FOREST_MUD, clamp(pr.g, 0.0, 1.0) * (1.0 - mud) * forest * 0.85);
		}
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
