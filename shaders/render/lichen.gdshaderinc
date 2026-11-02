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

const float LICHEN_NEAR = 30.0;

uniform sampler2D lichen_tex : filter_linear_mipmap, repeat_enable;
uniform float lichen_amount = 0.35;
uniform float moss_amount = 0.0;
uniform float moss_low = 0.0;    // moss up the sides from the ground (the stumps)
uniform float moss_end = 0.5;    // moss on a cut or broken end's face (a stump's top), against the bark's
uniform float moss_spill = 0.0;  // the height (m, the tree's own) moss spills over from (a stump's top); 0 none
// (colours from a photograph of bark lichens)
uniform vec3 lichen_color : source_color = vec3(0.5, 0.57, 0.46);   // leafy, sage
uniform vec3 lichen_crust : source_color = vec3(0.6, 0.61, 0.56);   // crust, pale grey
uniform vec3 lichen_disc : source_color = vec3(0.3, 0.18, 0.12);    // the crust's fruiting discs
uniform vec3 lichen_yellow : source_color = vec3(0.52, 0.56, 0.3);  // powdery crust
uniform vec3 moss_color : source_color = vec3(0.12, 0.2, 0.08);
uniform vec3 moss_light : source_color = vec3(0.22, 0.32, 0.13);
// Where they grow: not on the prairie (its dry, open air). Set by main.gd.
uniform sampler2D growth_biomes : filter_nearest, repeat_disable;
uniform vec2 growth_origin = vec2(-4096.0);
uniform float growth_domain = 8192.0;
uniform int prairie_biome = -1;

// 1 where lichen and moss grow at world xz, 0 on the prairie.
float growth_at(vec2 xz) {
	if (prairie_biome < 0)
		return 1.0;
	ivec2 n = textureSize(growth_biomes, 0);
	ivec2 c = clamp(ivec2((xz - growth_origin) / growth_domain * vec2(n)), ivec2(0), n - 1);
	return int(texelFetch(growth_biomes, c, 0).r * 255.0 + 0.5) == prairie_biome ? 0.0 : 1.0;
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
float lichen_cover(vec2 uv, vec3 p, float fade, out vec3 col, out float relief) {
	col = lichen_color;
	relief = 0.0;
	// how much lichen here: lichen_amount, more in some places, less in
	// others; shown as the rosettes and patches rarer than that, whole
	// (lichen.png's R: 0.52 + 0.48 x rarity), the big ones only where
	// there's most
	float dens = lichen_amount * 4.5 * smoothstep(0.15, 0.8, lc_noise(p * 1.1));
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
	col = base * (L.b / 0.75);
	relief = cover * L.g * 0.004; // (m: margins turned up)
	return cover;
}

// Moss's share of the bark at p, facing `up` (the surface's world normal's
// y), and how light it is there (fuzz: a fine 0..1 pattern). `near`: 0
// far off, a plain share.
float moss_cover(vec3 p, float up, float near, float fuzz, out float light) {
	light = 0.5;
	if (moss_amount <= 0.0)
		return 0.0;
	float top = smoothstep(-0.35, 0.7, up);
	if (near <= 0.0)
		return smoothstep(0.2, 0.8, moss_amount * top);
	float n = lc_noise(p * 2.2);
	float m = smoothstep(0.0, 0.1, n - 1.0 + moss_amount * top);
	if (moss_low > 0.0) { // up from the ground: in patches, fewer higher up
		float low = moss_low * smoothstep(0.8, 0.05, p.y);
		m = max(m, smoothstep(0.0, 0.06, fract(n * 7.31 + p.y * 0.7) * 0.4 + n * 0.6 - 0.88 + 0.42 * low));
	}
	if (moss_spill > 0.0) { // over a stump's rim, down its side, in tongues
		float below = moss_spill - p.y;
		float tongue = lc_noise(vec3(p.x * 7.0, p.y * 1.2, p.z * 7.0) + 9.0);
		m = max(m, smoothstep(0.0, 0.05, tongue - 0.45 - below * 1.6));
	}
	light = fuzz;
	m *= smoothstep(0.0, 0.25, fuzz + m - 0.5);
	return m;
}
