// Lichen and moss on bark (bark.gdshader).
//
// Lichen: leafy rosettes and crusts from lichen_tex (tools/trees/
// bake_lichen.py: tileable, laid on the bark as its own texture is, one
// read a pixel), gathered in drifts here and there (lichen_amount: their
// share of the bark; a noise in the tree's own space, offset per tree).
// Moss (moss_amount; the stumps and logs): dark green cushions on whatever
// faces up, thinning down the sides; up from the ground in patches
// (moss_low); spilling over a stump's top here and there (moss_spill).
// Up close only (the tree within LICHEN_NEAR m): further off the lichen is
// gone and the moss is a plain share, no noise, nothing to shimmer.

#include "res://shaders/render/origin.gdshaderinc"

const float LICHEN_NEAR = 30.0;

uniform sampler2D lichen_tex : filter_linear_mipmap, repeat_enable;
uniform float lichen_amount = 0.35;
uniform float night = 0.0; // 0 day .. 1 night (main.gd): pale lichen glared under the night's wider exposure
uniform bool lichen_any_biome = false; // the same everywhere (dead wood), not by biome (growth_at)...
uniform float lichen_swamp = 1.0;      // ...save this much more in the swamp (dead oaks)
uniform float moss_amount = 0.0;
uniform float moss_low = 0.0;    // moss up the sides from the ground (the stumps)
uniform float moss_end = 0.5;    // moss on a cut or broken end's face (a stump's top), against the bark's
uniform float moss_spill = 0.0;  // the height (m, the tree's own) moss spills over from (a stump's top); 0 none
// (colours from a photograph of bark lichens)
uniform vec3 lichen_color : source_color = vec3(0.5, 0.57, 0.46);   // leafy, sage
uniform vec3 lichen_crust : source_color = vec3(0.6, 0.61, 0.56);   // crust, pale grey
uniform vec3 lichen_disc : source_color = vec3(0.3, 0.18, 0.12);    // the crust's fruiting discs
uniform vec3 lichen_yellow : source_color = vec3(0.52, 0.56, 0.3);  // powdery crust
// moss.png (tools/trees/bake_moss.py): a cushion of leafy shoots under
// red stalks and purple capsules, 0.3 m across; alpha its height
uniform sampler2D moss_tex : source_color, filter_linear_mipmap, repeat_enable;
// How much grows where: very little lichen and no moss on the prairie (its
// dry, open air), the most lichen in the swamp. Set by main.gd.
uniform sampler2D growth_biomes : filter_nearest, repeat_disable;
uniform vec2 growth_origin = vec2(-4096.0);
uniform float growth_domain = 8192.0;
uniform int prairie_biome = -1;
uniform int swamp_biome_ = -1;
const vec2 PRAIRIE_GROWTH = vec2(0.5, 0.0); // (lichen, moss) x: on the prairie, lichen very sparse, no moss
const vec2 SWAMP_GROWTH = vec2(1.8, 1.0);   // in the swamp's damp air, lichen thick

// How much lichen and moss grow at the map's xz (x lichen_amount, moss_amount).
vec2 growth_at(vec2 xz) {
	if (prairie_biome < 0)
		return vec2(1.0);
	ivec2 n = textureSize(growth_biomes, 0);
	ivec2 c = clamp(ivec2((xz - growth_origin) / growth_domain * vec2(n)), ivec2(0), n - 1);
	int b = int(texelFetch(growth_biomes, c, 0).r * 255.0 + 0.5);
	return b == prairie_biome ? PRAIRIE_GROWTH : (b == swamp_biome_ ? SWAMP_GROWTH : vec2(1.0));
}

float lc_hash(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float lc_noise(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(lc_hash(i), lc_hash(i + vec3(1, 0, 0)), f.x),
			mix(lc_hash(i + vec3(0, 1, 0)), lc_hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(lc_hash(i + vec3(0, 0, 1)), lc_hash(i + vec3(1, 0, 1)), f.x),
			mix(lc_hash(i + vec3(0, 1, 1)), lc_hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// Lichen's share of the bark at uv (the bark texture's) and p (the tree's
// own space), its colour there and how far it stands off the bark (m).
// `fade`: 1 up close, to 0 at LICHEN_NEAR.
float lichen_cover(vec2 uv, vec3 p, float amount, float fade, out vec3 col, out float relief) {
	col = lichen_color;
	relief = 0.0;
	// how much lichen here: lichen_amount, more in some places, less in
	// others; shown as the rosettes and patches rarer than that, whole
	// (lichen.png's R: 0.52 + 0.48 x rarity), the big ones only where
	// there's most
	float dens = amount * 4.5 * smoothstep(0.15, 0.8, lc_noise(p * 1.1));
	if (dens * fade <= 0.0)
		return 0.0;
	vec4 L = texture(lichen_tex, uv);
	float thr = 1.0 - 0.48 * min(dens, 1.0);
	float cover = smoothstep(thr, thr + fwidth(L.r) + 0.004, L.r) * fade;
	if (cover <= 0.0)
		return 0.0;
	// the kind (lichen.png's alpha: 1 leafy, 0.7 crust, 0.45 disc, 0.2 yellow)
	float leafy = smoothstep(0.8, 0.9, L.a);
	float crust = smoothstep(0.57, 0.65, L.a) * (1.0 - leafy);
	float disc = smoothstep(0.3, 0.38, L.a) * (1.0 - leafy - crust);
	vec3 base = lichen_color * leafy + lichen_crust * crust + lichen_disc * disc
			+ lichen_yellow * (1.0 - leafy - crust - disc);
	// near a lobe's margin it's crisped, curling up off the bark in
	// ruffles, and paler (its underside); in the middle flatter, darker
	col = base * (L.b / 0.75) * (1.0 - 0.45 * night);
	relief = cover * L.g * 0.004; // (m: margins turned up)
	return cover;
}

// How much moss at p (0..1), facing `up` (as moss_cover; soft: the moss's
// own height makes the edge). The sporophytes (sporophytes.gdshader) stand
// where it's thick.
float moss_field(vec3 p, float up) {
	if (moss_amount <= 0.0)
		return 0.0;
	float top = smoothstep(-0.35, 0.7, up);
	float n = lc_noise(p * 2.2);
	float m = smoothstep(-0.25, 0.35, n - 1.0 + moss_amount * top);
	if (moss_low > 0.0) { // up from the ground: in patches, fewer higher up
		float low = moss_low * smoothstep(0.8, 0.05, p.y);
		m = max(m, smoothstep(-0.15, 0.2, fract(n * 7.31 + p.y * 0.7) * 0.4 + n * 0.6 - 0.88 + 0.42 * low));
	}
	if (moss_spill > 0.0) { // over a stump's rim, down its side, in tongues
		float below = moss_spill - p.y;
		float tongue = lc_noise(vec3(p.x * 7.0, p.y * 1.2, p.z * 7.0) + 9.0);
		m = max(m, smoothstep(-0.15, 0.2, tongue - 0.45 - below * 1.6));
	}
	return m;
}

// Moss's share of the bark at p, facing `up` (the surface's world normal's
// y), its colour there and how far it stands off the bark (m). M: moss.png
// read here. Where there's less of it, only its taller shoots and the
// capsules show, in tufts, not a green wash; at its fullest it covers
// all. `near`: 0 far off, a plain share in the moss's average colour.
float moss_cover(vec3 p, float up, float near, vec4 M, out vec3 col, out float relief) {
	col = vec3(0.0);
	relief = 0.0;
	if (moss_amount <= 0.0)
		return 0.0;
	float top = smoothstep(-0.35, 0.7, up);
	if (near <= 0.0) {
		col = textureLod(moss_tex, vec2(0.5), 10.0).rgb;
		relief = 0.004; // (for its shade, AO: about the average)
		return smoothstep(0.2, 0.8, moss_amount * top);
	}
	float m = moss_field(p, up);
	float h = (M.a - 0.04) / 0.96;
	float cover = smoothstep(0.0, 0.08, h + 0.06 - (1.0 - m) * 1.1);
	// thinner moss, a little yellower and paler; the gaps between shoots dark
	col = M.rgb * mix(vec3(1.12, 1.08, 0.9), vec3(1.0), m);
	relief = cover * h * 0.006; // (m)
	return cover;
}
