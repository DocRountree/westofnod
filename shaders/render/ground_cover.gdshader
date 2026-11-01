shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;

// Grass and ferns (GroundCover): one small mesh (a clump of blades, or a
// fern) per cell of a grid that follows the camera. Everything about a
// clump comes from where its cell is in the world, here: whether anything
// grows there (the biome, the ground's slope, the litter), its jittered
// place, its height on the ground (terrain_height(), as drawn), its size,
// and its colour: the ground's own (ground.gdshaderinc) at the root,
// toward its tip a little lighter (forest) or green to blonde (prairie).
//
// With distance clumps thin out (a share kept, the rest shrinking into the
// ground one by one), and at the end of the layer's range the last ones
// shrink away, their colour gone over to the ground's: grass that is the
// ground's colour, a few centimetres tall, leaves nothing to notice.
//
// Mesh: VERTEX in units of the clump's height from the blade's (frond's)
// root, CUSTOM0 a blade's half width (m), UV2 the root's offset in the
// clump (m); UV.y 0 at the root, 1 at
// the tip; COLOR.r a brightness, COLOR.g a share of blonde.

#include "res://shaders/render/height_map.gdshaderinc"
#include "res://shaders/render/ground.gdshaderinc"
#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/wind.gdshaderinc"

uniform int kind = 0;                 // 0 grass, 1 fern
uniform float cell = 0.4;             // m: the grid the clumps stand on (GroundCover)
uniform int seed = 0;
uniform bool in_forest = true;
uniform bool in_prairie = true;
uniform vec2 forest_height = vec2(0.08, 0.16); // m (grass; ferns: their length)
uniform vec2 prairie_height = vec2(0.45, 0.85);
uniform float width_scale = 1.0;      // the clump's spread and the blades' width
uniform vec2 fade_in = vec2(0.0, 0.0);   // m: grows in over this (0: from the eye)
uniform vec2 fade_out = vec2(30.0, 40.0); // m: shrinks away over this
uniform float thin_from = 12.0;       // m: beyond this a share (thin_from / d)^1.5 is kept
uniform float cover = 1.0;            // the share of cells with a clump
uniform float grass_sway = 0.6;       // the tip's sway, in clump heights per m of the wind
uniform sampler2D frond_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 prairie_green = vec3(0.27, 0.43, 0.12);
uniform vec3 prairie_blonde = vec3(0.74, 0.64, 0.38);
uniform vec3 frond_mean = vec3(0.03, 0.07, 0.006); // linear: the frond texture's mean (GroundCover sets it)

varying vec3 world_pos;
varying vec3 root_col;   // linear
varying vec3 tip_col;    // linear
varying float frac;

float h2(ivec2 c, int k) {
	return hash(c * 3 + ivec2(seed * 7919 + k * 131, k * 977 - seed));
}

void vertex() {
	vec2 anchor = MODEL_MATRIX[3].xz; // the cell's corner (the node * the instance)
	ivec2 c = ivec2(round(anchor / cell));
	vec2 pos = anchor + vec2(h2(c, 1), h2(c, 2)) * cell;
	float d = distance(CAMERA_POSITION_WORLD.xz, pos);
	// how much of it shows: the layer's range, the thinning, then the ground
	float keep = clamp(pow(thin_from / max(d, 0.01), 1.5), 0.0, 1.0);
	float vis = keep * (1.0 - smoothstep(fade_out.x, fade_out.y, d));
	if (fade_in.y > 0.0)
		vis *= smoothstep(fade_in.x, fade_in.y, d);
	float rank = h2(c, 3);
	float grow = clamp((vis * 1.15 - rank) / 0.15, 0.0, 1.0) * step(h2(c, 4), cover);
	float size = 0.0;
	vec3 ground = vec3(0.0);
	float h = 0.0;
	bool prairie = false;
	if (grow > 0.0) {
		// the biome: one of the four nearest texels, by their weights (the
		// terrain blends them; a clump is one or the other)
		vec2 g = biome_grid(pos);
		float pick = h2(c, 5);
		int b = 255;
		float acc = 0.0;
		float in_b[3] = float[](0.0, 0.0, 0.0); // how much forest, -, prairie
		for (int k = 0; k < 4; k++) {
			float w;
			int bk = biome_texel(g, k, w);
			acc += w;
			if (b == 255 && pick < acc)
				b = bk;
			if (bk == 0 || bk == 2)
				in_b[bk] += w;
		}
		bool forest = b == 0 && in_forest;
		prairie = b == 2 && in_prairie;
		if (forest || prairie) {
			h = terrain_height(pos, 0);
			float e = 1.0;
			float hx = height_m(pos + vec2(e, 0.0), 0) - height_m(pos - vec2(e, 0.0), 0);
			float hz = height_m(pos + vec2(0.0, e), 0) - height_m(pos - vec2(0.0, e), 0);
			vec3 n = normalize(vec3(-hx, 2.0 * e, -hz));
			vec4 m = textureLod(mask_tex, map_uv(pos), 0.0);
			// (the footprint of a pixel of the ground there, as the terrain
			// sees it: longer the more glancing the view)
			float fp = 0.0016 * d * max(1.0, d / max(CAMERA_POSITION_WORLD.y - h, 0.5));
			Shared sh = ground_shared(pos, h, n, m, max(fp, 0.01));
			float rough, rocky, litter;
			ground = biome_ground(b, sh, rough, rocky, litter);
			// the sand and the shore, as the terrain has them
			float bare = max(rocky, m.a) + (1.0 - smoothstep(0.3, 1.2, h));
			float here = forest ? (1.0 - litter * (kind == 1 ? 0.6 : 0.9)) : 1.0;
			if (kind == 1) // ferns in drifts, and only well inside the forest
				here *= smoothstep(0.38, 0.55, vnoise(pos / 7.0 + 13.0) * 0.7 + vnoise(pos / 2.3) * 0.3) * smoothstep(0.75, 0.95, in_b[0]);
			if (h2(c, 6) < here * (1.0 - clamp(bare * 2.0, 0.0, 1.0))) {
				vec2 hr = forest ? forest_height : prairie_height;
				// taller and shorter in patches, and from clump to clump
				size = mix(hr.x, hr.y, vnoise(pos / 5.0) * 0.6 + h2(c, 7) * 0.4) * grow;
			}
		}
	}
	frac = UV.y;
	if (size <= 0.0) {
		VERTEX = vec3(0.0, -1e4, 0.0); // nothing here: no pixels
		world_pos = vec3(0.0);
		root_col = vec3(0.0);
		tip_col = vec3(0.0);
	} else {
		float spin = h2(c, 8) * 6.2832;
		mat2 rot = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin)));
		// survivors of the thinning spread wider, to cover for the rest
		float spread = width_scale * inversesqrt(max(keep, 0.15));
		vec3 v = VERTEX;
		v.xz = rot * v.xz;
		vec3 across = CUSTOM0.xyz;
		across.xz = rot * across.xz;
		vec2 root = rot * UV2 * spread;
		vec3 w = vec3(pos.x + root.x, h, pos.y + root.y) + v * size + across * spread;
		w += wind_sway(w, TIME) / max(sway, 1e-3) * grass_sway * size * frac * frac;
		world_pos = w;
		VERTEX = (VIEW_MATRIX * vec4(w, 1.0)).xyz;
		vec3 nrm = NORMAL;
		nrm.xz = rot * nrm.xz;
		// lit mostly as the ground under it is (and the shadow map read
		// above it: thin blades caught speckles of the ground's own shadow)
		NORMAL = normalize(mat3(VIEW_MATRIX) * normalize(mix(nrm, vec3(0.0, 1.0, 0.0), kind == 1 ? 0.5 : 0.85)));
		// colours: the ground's at the root; toward the tip lighter
		// (forest), green to blonde (prairie); all the ground's far off
		float far = smoothstep(fade_out.x * 0.4, fade_out.y, d);
		root_col = pow(ground, vec3(2.2));
		vec3 tip;
		if (kind == 1) // (a tint on the frond's texture)
			tip = mix(vec3(COLOR.r), root_col / frond_mean, far);
		else if (prairie)
			tip = mix(prairie_green, prairie_blonde, clamp(vnoise(pos / 9.0) * 0.9 + COLOR.g * 0.5 - 0.3, 0.0, 1.0)) * 0.85;
		else
			tip = ground * vec3(1.12, 1.22, 1.05);
		if (kind == 1) {
			tip_col = tip;
		} else {
			tip = mix(tip * COLOR.r, ground, far);
			tip_col = pow(tip, vec3(2.2));
		}
	}
}

void fragment() {
	if (!FRONT_FACING)
		NORMAL = -NORMAL; // (both faces lit alike: the normal leans up)
	vec3 c;
	if (kind == 1) {
		vec4 t = texture(frond_tex, UV);
		ALPHA = t.a;
		ALPHA_SCISSOR_THRESHOLD = 0.5;
		c = t.rgb * tip_col * mix(0.6, 1.0, smoothstep(0.0, 0.5, frac));
	} else {
		c = mix(root_col, tip_col, smoothstep(0.0, 0.7, frac)) * mix(0.75, 1.0, frac);
	}
	ALBEDO = c;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	BACKLIGHT = c * 0.4;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}
