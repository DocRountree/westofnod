shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;

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
uniform int kind = 0;                 // 0 grass, 1 fern
uniform float width_scale = 1.0;      // the clump's spread and the blades' width
uniform vec2 fade_in = vec2(0.0, 0.0);   // m: grows in over this (0: from the eye)
uniform vec2 fade_out = vec2(30.0, 40.0); // m: shrinks away over this
uniform float thin_from = 12.0;       // m: beyond this a share (thin_from / d)^1.5 is kept
uniform float grass_sway = 0.3;       // the tip's sway, in clump heights per m of the wind
uniform sampler2D frond_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 prairie_green = vec3(0.27, 0.43, 0.12);
uniform vec3 prairie_blonde = vec3(0.74, 0.64, 0.38);
uniform float shadow_strength = 0.7;
uniform vec3 frond_mean = vec3(0.03, 0.07, 0.006); // linear: the frond texture's mean (GroundCover sets it)

varying vec3 world_pos;
varying vec3 root_col;   // linear
varying vec3 tip_col;    // linear
varying float frac;
varying float fade;  // 1 drawn, 0 gone: a clump coming or going dissolves (stippled)
varying float far;   // 0 its own colours, 1 all the ground's

float bayer4(vec2 frag) {
	ivec2 q = ivec2(mod(frag, 4.0));
	int i = q.x + q.y * 4;
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

void vertex() {
	vec2 anchor = MODEL_MATRIX[3].xz; // the cell's corner (the node * the instance)
	ivec2 c = ivec2(round(anchor / cell));
	ivec2 t = c - grid_origin;
	vec2 pos = cell_pos(c);
	float d = distance(CAMERA_POSITION_WORLD.xz, pos);
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
		size = a.b / 255.0 * SIZE_MAX * mix(0.6, 1.0, grow); // (coming in, it grows a little as it dithers in)
	}
	frac = COLOR.b;
	fade = grow;
	if (size <= 0.0) {
		VERTEX = vec3(0.0, -1e4, 0.0); // nothing here: no pixels
		world_pos = vec3(0.0);
		root_col = vec3(0.0);
		tip_col = vec3(0.0);
		far = 0.0;
	} else {
		float h = base_h - 512.0 + (round(a.r) * 256.0 + round(a.g)) / 64.0;
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
		// (all the ground's colour by the time it starts to go: ferns from
		// a few metres off, little by little; grass further out)
		far = kind == 1 ? smoothstep(3.0, fade_out.x, d) : smoothstep(fade_out.x * 0.4, fade_out.x, d);
		root_col = pow(ground, vec3(2.2));
		if (kind == 1) { // (a tint on the frond's texture, halfway to the ground's colour)
			tip_col = mix(vec3(COLOR.r), root_col / frond_mean, 0.5);
		} else {
			vec3 tip = mix(ground * vec3(1.12, 1.22, 1.05), // forest: the ground's, a little lighter
					mix(prairie_green, prairie_blonde, clamp(a.a / 255.0 + COLOR.g * 0.5 - 0.25, 0.0, 1.0)) * 0.85, // prairie
					prairie);
			tip_col = pow(tip * COLOR.r, vec3(2.2));
		}
	}
}

void fragment() {
	if (fade < bayer4(FRAGCOORD.xy))
		discard;
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
	ALBEDO = mix(c, root_col, far); // far off, exactly the ground's colour
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}

// Lit by hand: wrapped, light through the blades from behind, and a shadow
// dims it only part way (shadow_strength): blades a hair's breadth above
// the ground caught specks of its shadow, black at a low sun.
void light() {
	float a = mix(1.0, ATTENUATION, shadow_strength);
	float ndl = dot(NORMAL, LIGHT);
	DIFFUSE_LIGHT += (clamp(ndl * 0.7 + 0.3, 0.0, 1.0) + max(-ndl, 0.0) * 0.3) * a * LIGHT_COLOR / PI;
}
