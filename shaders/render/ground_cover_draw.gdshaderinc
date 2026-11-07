// The body of ground_cover.gdshader (grass, reeds, cattails, marram,
// flowers) and ground_cover_fern.gdshader (ferns: FERN defined). Only the
// ferns' frond texture needs pixels thrown away (alpha scissor, and their
// stippled coming and going); the rest come and go by growing and
// shrinking, and their shader has no discard at all: a discard anywhere in
// it turns off the early depth test for every pixel it draws, and the
// prairie's head-high grass is many blades deep.
//
// Grass and ferns (GroundCover): one small mesh (a clump of blades, or a
// fern) per cell of a grid that follows the camera. What grows in a cell,
// its height on the ground, its size and the ground's colour there come
// from data_tex, which ground_cover_bake.gdshader works out once each time
// the grid moves; here each vertex only reads its cell's two texels, and
// places, sizes, colours and sways its clump.
//
// The clump's root is the ground's colour; toward its tip a little lighter
// (forest) or green to blonde (prairie). With distance clumps thin out (a
// share kept, the rest dissolving away, stippled, one by one), and at the
// end of the layer's range the last ones dissolve too; by then their colour
// has gone over to exactly the ground's (ferns little by little from a few
// metres off): nothing to notice coming or going.
//
// Mesh: VERTEX in units of the clump's height from the blade's (frond's)
// root, CUSTOM0 a blade's half width (m), UV2 the root's offset in the
// clump (m); COLOR.r a brightness, COLOR.g a share of blonde, COLOR.b how
// far along the blade (frond) from its root, 0..1.

#include "res://shaders/render/aerial.gdshaderinc"
#include "res://shaders/render/wind.gdshaderinc"
#include "res://shaders/render/ground_cover.gdshaderinc"

uniform sampler2D data_tex : filter_nearest, repeat_disable;
uniform ivec2 grid_origin; // the cell of data_tex's texel (0, 0)
uniform ivec2 grid_size = ivec2(0); // cells
uniform float base_h;
uniform int kind = 0;                 // 0 grass, 1 fern, 2 flowers (stems as grass; their heads: UV.x 3..5)
uniform float width_scale = 1.0;      // the clump's spread and the blades' width
uniform vec2 fade_in = vec2(0.0, 0.0);   // m: grows in over this (0: from the eye)
uniform vec2 fade_out = vec2(30.0, 40.0); // m: shrinks away over this
uniform float thin_from = 12.0;       // m: beyond this a share (thin_from / d)^1.5 is kept
uniform float grass_sway = 0.3;       // the tip's sway, in clump heights per m of the wind
uniform sampler2D frond_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 prairie_green = vec3(0.27, 0.43, 0.12);
uniform vec3 prairie_blonde = vec3(0.74, 0.64, 0.38);
// patches of a tint (the marram): in irregular patches a few metres
// across, a share patch_tints.x of them green (the green of the coast's
// floor, its clumps: ground.gdshaderinc, biome_ground), as many again (.y)
// a tad yellower (multiplying the tip's colour), the rest as they are
uniform vec2 patch_tints = vec2(0.0);
uniform vec3 tint_green = vec3(0.42, 0.46, 0.25);
uniform vec3 tint_yellow = vec3(1.04, 1.02, 0.82);
uniform vec3 head_color = vec3(0.075, 0.035, 0.017); // linear: a cattail's head (UV.x 2..3 marks it)
// the flowers' heads (sRGB): the rays (from petal_base at their base to
// petal_color; a share petal_alt_share of the stems petal_alt instead), the disc
uniform vec3 petal_color = vec3(1.0);
uniform vec3 petal_base = vec3(1.0);
uniform vec3 petal_alt = vec3(1.0);
uniform float petal_alt_share = 0.0;
// or (over 0) every head somewhere from petal_color to petal_alt, at random
// (to this power: more of them toward petal_color)
uniform float petal_mix = 0.0;
uniform vec3 disc_color = vec3(0.5);
// a head's size (m): once it's only a few pixels across it takes the
// stem's colour (a white speck that small sparkled over the grass)
uniform float head_size = 0.05;
uniform vec2 head_px = vec2(2.5, 6.0); // pixels across: its stem's colour below x, its own above y
uniform float shadow_strength = 0.7;
global uniform float night; // 0 day .. 1 night (main.gd: a global): the prairie's grass darker at night, as its ground
uniform vec3 frond_mean = vec3(0.03, 0.07, 0.006); // linear: the frond texture's mean (GroundCover sets it)

varying vec3 world_pos;
varying vec3 root_col;   // linear
varying vec3 tip_col;    // linear
varying float frac;
varying float fade;  // 1 drawn, 0 gone: a clump coming or going dissolves (stippled)
varying float far;   // 0 its own colours, 1 all the ground's
varying float dim;   // the night's dimming (the prairie's)
// which part of the clump (from UV.x, the vertex's own, exact): 0 a blade
// or leaf, 1 a round stalk, 2 a cattail's head, 3 a flower's rays, 4 its
// disc. Flat: not from UV.x in the pixel, which multisampling reads at the
// pixel's middle, off a blade thinner than the pixel, far beyond its 0..1
// (it read as a ray, white: specks glittering all over the grass).
varying flat int part;
varying flat float pick; // a head's (stem's) own random 0..1: the mesh's, shifted per clump

float bayer4(vec2 frag) {
	ivec2 q = ivec2(mod(frag, 4.0));
	int i = q.x + q.y * 4;
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

void vertex() {
	vec2 anchor = MODEL_MATRIX[3].xz + world_origin.xz; // the cell's corner (the node * the instance), on the map
	ivec2 c = ivec2(round(anchor / cell));
	ivec2 t = c - grid_origin;
	vec2 pos = cell_pos(c);
	float d = distance(CAMERA_POSITION_WORLD.xz + world_origin.xz, pos);
	// how much of it shows: the layer's range, the thinning
	float keep = clamp(pow(thin_from / max(d, 0.01), 1.5), 0.0, 1.0);
	float vis = keep * (1.0 - smoothstep(fade_out.x, fade_out.y, d));
	if (fade_in.y > 0.0)
		vis *= smoothstep(fade_in.x, fade_in.y, d);
	float grow = clamp((vis * 1.15 - h2(c, 3)) / 0.15, 0.0, 1.0);
	float size = 0.0;
	vec4 a = vec4(0.0);
	vec3 ground = vec3(0.0);
	float prairie = 0.0;
	if (grow > 0.0 && t.x >= 0 && t.y >= 0 && t.x < grid_size.x && t.y < grid_size.y) {
		a = texelFetch(data_tex, ivec2(t.x * 2, t.y), 0) * 255.0;
		vec4 gt = texelFetch(data_tex, ivec2(t.x * 2 + 1, t.y), 0);
		ground = gt.rgb;
		prairie = gt.a;
#ifdef FERN
		size = a.b / 255.0 * SIZE_MAX * mix(0.6, 1.0, grow); // (coming in, it grows a little as it dithers in)
#else
		size = a.b / 255.0 * SIZE_MAX * smoothstep(0.0, 1.0, grow); // (coming and going, it grows and shrinks)
#endif
	}
	frac = COLOR.b;
	pick = 0.0;
	part = UV.x > 4.0 ? 4 : (UV.x > 3.0 ? 3 : (UV.x > 1.5 ? 2 : (UV.x > 1.1 ? 1 : 0)));
	fade = grow;
	if (size <= 0.0) {
		VERTEX = vec3(0.0, -1e4, 0.0); // nothing here: no pixels
		world_pos = vec3(0.0);
		root_col = vec3(0.0);
		tip_col = vec3(0.0);
		far = 0.0;
		dim = 1.0;
	} else {
		float h = base_h - 512.0 + (round(a.r) * 256.0 + round(a.g)) / 64.0;
		float spin = h2(c, 8) * 6.2832;
		pick = fract(COLOR.g + h2(c, 9));
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
		world_pos = w; // (the map's)
		VERTEX = (VIEW_MATRIX * vec4(w - world_origin, 1.0)).xyz; // (drawn near the origin)
		vec3 nrm = NORMAL;
		nrm.xz = rot * nrm.xz;
		// lit mostly as the ground under it is (and the shadow map read
		// above it: thin blades caught speckles of the ground's own shadow)
		NORMAL = normalize(mat3(VIEW_MATRIX) * normalize(mix(nrm, vec3(0.0, 1.0, 0.0), kind == 1 ? 0.5 : (part >= 2 ? (part >= 3 ? 0.35 : 0.2) : (part == 1 ? 0.35 : 0.85))))); // (a cattail's head and stalk: round, lit as round)
		// colours: the ground's at the root; toward the tip lighter
		// (forest), green to blonde (prairie); all the ground's far off
		// (all the ground's colour by the time it starts to go: ferns from
		// a few metres off, little by little; grass further out)
		far = kind == 1 ? smoothstep(3.0, fade_out.x, d) : smoothstep(fade_out.x * 0.4, fade_out.x, d);
		dim = 1.0 - 0.5 * night * prairie;

		ground *= dim;
		root_col = pow(ground, vec3(2.2));
		if (kind == 1) { // (a tint on the frond's texture, halfway to the ground's colour)
			tip_col = mix(vec3(COLOR.r), root_col / frond_mean, 0.5);
		} else {
			vec3 tip = mix(ground * vec3(1.12, 1.22, 1.05), // forest: the ground's, a little lighter
					mix(prairie_green, prairie_blonde, clamp(a.a / 255.0 + COLOR.g * 0.5 - 0.25, 0.0, 1.0)) * 0.85, // prairie
					prairie);
			if (patch_tints.x + patch_tints.y > 0.0) {
				// the patches: cells 7 m across, their edges wavering
				vec2 q = pos + vec2(sin(pos.y * 0.37) + sin(pos.y * 0.11 + 1.3), sin(pos.x * 0.41) + sin(pos.x * 0.13 + 2.1)) * 2.0;
				float t = gc_hash(ivec2(floor(q / 7.0)) + ivec2(577, -211));
				if (t < patch_tints.x) // (the green, keeping the clump's own lighter and darker)
					tip = tint_green * tip / (mix(prairie_green, prairie_blonde, 0.5) * 0.85);
				else if (t < patch_tints.x + patch_tints.y)
					tip *= tint_yellow;
			}
			tip_col = pow(tip * COLOR.r * (1.0 - 0.5 * night * prairie), vec3(2.2));
		}
	}
}

void fragment() {
#ifdef FERN
	if (fade < bayer4(FRAGCOORD.xy))
		discard;
#endif
	if (!FRONT_FACING)
		NORMAL = -NORMAL; // (both faces lit alike: the normal leans up)
	vec3 c;
#ifdef FERN
	vec4 t = texture(frond_tex, UV);
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	c = t.rgb * tip_col * mix(0.6, 1.0, smoothstep(0.0, 0.5, frac));
#else
	{
		c = mix(root_col, tip_col, smoothstep(0.0, 0.7, frac)) * mix(0.75, 1.0, frac);
		// a flower's head darker at dusk and night than the grass (pale
		// petals glowed under the night's wider exposure)
		float head_dim = 1.0 - 0.8 * night;
		if (part == 4) // a flower's disc
			c = pow(disc_color, vec3(2.2)) * COLOR.r * head_dim;
		else if (part == 3) // its rays
			c = pow(petal_mix > 0.0 ? mix(petal_color, petal_alt, pow(pick, petal_mix))
					: (pick < petal_alt_share ? petal_alt : mix(petal_base, petal_color, smoothstep(0.0, 0.45, clamp(UV.y, 0.0, 1.0)))), vec3(2.2)) * COLOR.r * head_dim;
		else if (part == 2)
			c = head_color * COLOR.r;
	}
#endif
	// far off, exactly the ground's colour (a flower's head its own: it
	// dissolves away)
	// a flower's head: its own colours, or its stem's once it's only a few
	// pixels across (the metres a pixel spans at its distance)
	float head_k = 1.0;
	if (part >= 3) {
		float mpp = 2.0 * max(-VERTEX.z, 0.01) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
		head_k = smoothstep(head_px.x, head_px.y, head_size / max(mpp, 1e-6));
		c = mix(tip_col * 0.9, c, head_k);
	}
	ALBEDO = mix(c, root_col, part >= 3 ? far * (1.0 - head_k) : far);
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD + world_origin);
}

// Lit by hand: wrapped, light through the blades from behind, and a shadow
// dims it only part way (shadow_strength): blades a hair's breadth above
// the ground caught specks of its shadow, black at a low sun.
void light() {
	float a = mix(1.0, ATTENUATION, shadow_strength);
	float ndl = dot(NORMAL, LIGHT);
	DIFFUSE_LIGHT += (clamp(ndl * 0.7 + 0.3, 0.0, 1.0) + max(-ndl, 0.0) * 0.3) * a * LIGHT_COLOR / PI;
}
