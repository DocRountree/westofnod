// Lichen and moss on bark (bark.gdshader). Patterns in the tree's own space
// (`p`, m, per instance offset by `seed`), so they stay put on the bark as
// it sways and differ tree to tree.
//
// Lichen: leafy lobes, crusts, gathered in drifts here and there
// (lichen_amount: their share of the bark). Moss (moss_amount; the stumps
// and logs): dark green cushions on whatever faces up, thinning down the
// sides, and (moss_low) up from the ground, in patches.
// Past a few tens of metres both give way to a faint average (no pattern
// to shimmer, and much cheaper: the pattern is only worked out up close).

uniform float lichen_amount = 0.35;
uniform float moss_amount = 0.0;
uniform float moss_low = 0.0;    // moss up the sides from the ground (the stumps)
uniform vec3 lichen_color : source_color = vec3(0.46, 0.52, 0.45);  // leafy, sage
uniform vec3 lichen_crust : source_color = vec3(0.55, 0.56, 0.52);  // crusts, pale grey
uniform vec3 lichen_yellow : source_color = vec3(0.5, 0.53, 0.32);
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

vec3 lc_hash3(vec3 p) {
	return vec3(lc_hash(p), lc_hash(p + 17.31), lc_hash(p + 41.77));
}

float lc_noise(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(lc_hash(i), lc_hash(i + vec3(1, 0, 0)), f.x),
			mix(lc_hash(i + vec3(0, 1, 0)), lc_hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(lc_hash(i + vec3(0, 0, 1)), lc_hash(i + vec3(1, 0, 1)), f.x),
			mix(lc_hash(i + vec3(0, 1, 1)), lc_hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// Lichen's share of the bark at p, 0..1, and its colour there. Leafy
// (foliose) lobes, sage to grey-green with paler, upturned rims and darker
// gaps; pale grey crusts; now and then a yellow-green crust. Shapes from
// warped noise, so no two patches alike.
float lichen_cover(vec3 p, float far, out vec3 col) {
	col = lichen_color;
	float drift = smoothstep(0.85 - lichen_amount, 1.1 - lichen_amount, lc_noise(p * 1.3));
	if (drift <= 0.0)
		return 0.0;
	float kind = lc_noise(p * 2.1 + 7.0);
	vec3 base = mix(lichen_crust, lichen_color, smoothstep(0.35, 0.55, kind));
	base = mix(base, lichen_yellow, smoothstep(0.8, 0.88, kind) * 0.8);
	if (far >= 1.0) {
		col = base;
		return drift * 0.04; // (a faint share of their colour: the patches' average)
	}
	vec3 q = p * 11.0; // patches a few cm across
	q += (lc_noise(q * 0.6) - 0.5) * vec3(1.7, -1.3, 1.1);
	float f1 = lc_noise(q);
	float f = f1 * 0.65 + lc_noise(q * 2.7) * 0.35;
	float t = 0.68 - drift * 0.08;
	float cover = smoothstep(t, t + 0.015, f);
	float rim = 1.0 - smoothstep(t + 0.01, t + 0.05, f);
	col = base * mix(0.8, 1.0, f1) * mix(1.0, 1.15, rim);
	col = mix(col, base, far);
	return mix(cover, drift * 0.04, far);
}

// Moss's share of the bark at p, facing `up` (the surface's world normal's
// y), and how light it is there.
float moss_cover(vec3 p, float up, float far, out float light) {
	light = 0.0;
	if (moss_amount <= 0.0)
		return 0.0;
	float n = lc_noise(p * 2.2);
	float side = max(smoothstep(-0.35, 0.7, up), moss_low * smoothstep(0.9, 0.1, p.y));
	float m = smoothstep(0.0, 0.1, n - 1.0 + moss_amount * side);
	if (far < 1.0) {
		float fuzz = lc_noise(p * 60.0);
		light = mix(fuzz, 0.5, far);
		m *= mix(smoothstep(0.0, 0.25, fuzz + m - 0.5), 1.0, far);
	} else {
		light = 0.5;
	}
	return m;
}
