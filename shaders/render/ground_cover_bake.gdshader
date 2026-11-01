shader_type canvas_item;
render_mode blend_disabled;

// Works out, once per cell, what grows in it (GroundCover renders this into
// a small texture when its grid moves, and ground_cover.gdshader reads it):
// the clump's height on the ground (terrain_height(), as drawn), its size
// (0: nothing: the biome, the ground's slope, the shore, the litter, the
// ferns' drifts), the ground's colour there (ground.gdshaderinc, as the
// terrain), and on the prairie how blonde. Doing it here, once, rather
// than in every vertex of every clump every frame, is what keeps grass
// cheap. Packing: ground_cover.gdshaderinc.

#include "res://shaders/render/height_map.gdshaderinc"
#include "res://shaders/render/ground.gdshaderinc"
#include "res://shaders/render/ground_cover.gdshaderinc"

uniform ivec2 grid_origin; // the cell of texel (0, 0)
uniform ivec2 grid_size;   // cells
uniform float base_h;      // m: heights are stored from this
uniform vec3 eye;          // the camera, when baked (for the colour's detail)
uniform int kind = 0;      // 0 grass, 1 fern
uniform bool in_forest = true;
uniform bool in_prairie = true;
uniform vec2 forest_height = vec2(0.08, 0.16); // m (grass; ferns: their length)
uniform vec2 prairie_height = vec2(0.45, 0.85);
uniform float cover = 1.0; // the share of cells with a clump
uniform float clear = 0.2; // m kept clear round a log or stump, past its radius
// fallen logs and stumps (Population.walk_near()): segments over the ground
// (ax, az, bx, bz) and their radii; nothing grows through them
uniform vec4 logs[128];
uniform float log_r[128];
uniform int log_count = 0;

// Under (or through) a log or stump.
bool under_log(vec2 p) {
	for (int i = 0; i < log_count; i++) {
		vec2 a = logs[i].xy;
		vec2 ab = logs[i].zw - a;
		float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
		if (distance(p, a + ab * t) < log_r[i] + clear)
			return true;
	}
	return false;
}
// the terrain's levels of detail (Cdlod): a level-0 patch's size, a
// level's range in patch sizes, where in it morphing starts
uniform float cd_leaf = 16.0;
uniform float cd_range_factor = 2.4;
uniform float cd_morph_start = 0.6;

// The ground's height at p as the terrain draws it from the eye, not as it
// is: further off it's drawn from coarser levels (Cdlod, cdlod_xz()), a
// grid of vertices further apart, from coarser mips of the map, morphing
// into the next level, and a clump stood on the true height would float
// over a hollow or sink into a rise. (The level is the one the point's own
// distance asks for; the quadtree may draw a finer one a little nearer,
// where the levels agree as they morph.)
float cd_dist(vec2 p) {
	return length(vec2(distance(p, eye.xz), max(eye.y, 0.0) * 0.5));
}

float drawn_height(vec2 p) {
	int lod = 0;
	while (lod < 16 && cd_dist(p) >= cd_leaf * exp2(float(lod)) * cd_range_factor)
		lod++;
	float range = cd_leaf * exp2(float(lod)) * cd_range_factor;
	float step = cd_leaf * exp2(float(lod)) / GRID;
	vec2 g = (p - map_origin) / step;
	vec2 g0 = floor(g);
	vec2 f = g - g0;
	float hv[4];
	for (int i = 0; i < 4; i++) {
		vec2 k = g0 + vec2(float(i & 1), float(i >> 1));
		float morph = clamp((cd_dist(map_origin + k * step) - range * cd_morph_start) / max(range - cd_leaf * 0.3 - range * cd_morph_start, 1e-3), 0.0, 1.0);
		k -= fract(k * 0.5) * 2.0 * morph; // (odd vertices slide onto the coarser grid)
		vec2 wp = map_origin + k * step;
		float hh = terrain_height(wp, max(lod - SUB, 0));
		if (morph > 0.0) {
			float hc = terrain_height(wp, max(lod + 1 - SUB, 0));
			hh = morph >= 1.0 ? hc : mix(hh, hc, morph);
		}
		hv[i] = hh;
	}
	return mix(mix(hv[0], hv[1], f.x), mix(hv[2], hv[3], f.x), f.y);
}

void fragment() {
	ivec2 px = ivec2(floor(UV * vec2(grid_size * ivec2(2, 1))));
	ivec2 c = grid_origin + ivec2(px.x / 2, px.y);
	vec2 pos = cell_pos(c);
	float h = terrain_height(pos, 0);
	float e = 1.0;
	float hx = height_m(pos + vec2(e, 0.0), 0) - height_m(pos - vec2(e, 0.0), 0);
	float hz = height_m(pos + vec2(0.0, e), 0) - height_m(pos - vec2(0.0, e), 0);
	vec3 n = normalize(vec3(-hx, 2.0 * e, -hz));
	vec4 m = textureLod(mask_tex, map_uv(pos), 0.0);
	// (the footprint of a pixel of the ground there, as the terrain sees
	// it: longer the more glancing the view)
	float d = distance(eye.xz, pos);
	float fp = 0.0016 * d * max(1.0, d / max(eye.y - h, 0.5));
	Shared sh = ground_shared(pos, h, n, m, max(fp, 0.01));
	// the biomes here blended as the terrain blends them (the four nearest
	// texels by their weights): the ground's colour, and how much is
	// forest, how much prairie; across a border the clumps go from the one
	// to the other, short to tall, by degrees
	vec2 g = biome_grid(pos);
	vec3 ground = vec3(0.0);
	float rocky = 0.0, litter = 0.0, mud = 0.0, fw = 0.0, pw = 0.0;
	for (int k = 0; k < 4; k++) {
		float w;
		int bk = biome_texel(g, k, w);
		if (w <= 0.0)
			continue;
		float r_, k_, l_, pud;
		ground += biome_ground(bk, sh, r_, k_, l_) * w;
		rocky += k_ * w;
		litter += l_ * w;
		mud += biome_mud(bk, sh, pud) * w;
		if (bk == 0)
			fw += w;
		else if (bk == 2)
			pw += w;
	}
	float grows = (in_forest ? fw : 0.0) + (in_prairie ? pw : 0.0);
	float prairie = pw / max(fw + pw, 1e-4); // 0 forest .. 1 prairie
	if (!in_prairie)
		prairie = 0.0;
	if (!in_forest)
		prairie = 1.0;
	float size = 0.0;
	if (h2(c, 5) < grows && h2(c, 4) < cover && !under_log(pos)) {
		// not on rock, sand, mud or the shore; nothing on the forest's litter
		float bare = max(max(rocky, m.a), mud * 3.0) + (1.0 - smoothstep(0.3, 1.2, h));
		float here = mix(smoothstep(0.3, 0.05, litter / max(fw, 1e-4)), 1.0, prairie);
		if (kind == 1) // ferns in drifts, and only well inside the forest
			here *= smoothstep(0.24, 0.4, vnoise(pos / 7.0 + 13.0) * 0.7 + vnoise(pos / 2.3) * 0.3) * smoothstep(0.75, 0.95, fw);
		if (h2(c, 6) < here * (1.0 - clamp(bare * 2.0, 0.0, 1.0))) {
			vec2 hr = mix(forest_height, prairie_height, prairie);
			// taller and shorter in patches, and from clump to clump
			size = mix(hr.x, hr.y, vnoise(pos / 5.0) * 0.6 + h2(c, 7) * 0.4);
		}
	}
	float blonde = clamp(vnoise(pos / 9.0) * 0.9 - 0.05, 0.0, 1.0);
	if ((px.x & 1) == 0) {
		float u = clamp((drawn_height(pos) - base_h + 512.0) * 64.0, 0.0, 65535.0);
		float hi = floor(u / 256.0);
		float lo = floor(u - hi * 256.0);
		float s = size > 0.0 ? max(round(size / SIZE_MAX * 255.0), 1.0) : 0.0;
		COLOR = vec4(hi, lo, s, round(blonde * 255.0)) / 255.0;
	} else {
		COLOR = vec4(clamp(ground, 0.0, 1.0), prairie);
	}
}
