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
uniform vec3 lichen_color : source_color = vec3(0.47, 0.54, 0.43);  // leafy, sage
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

// Lichen's share of the bark at p, 0..1, and its colour there. Mostly
// leafy (foliose) rosettes: a patch of crowded lobes with scalloped, rounded
// ends, split by narrow dark gaps, pale along their raised edges; sometimes
// pale grey crust, cracked into plates, dotted with small cups (rimmed,
// darker inside); now and then yellow-green. Gathered in drifts.
float lichen_cover(vec3 p, float far, out vec3 col, out float relief) {
	col = lichen_color;
	relief = 0.0;
	float drift = smoothstep(0.88 - lichen_amount, 1.08 - lichen_amount, lc_noise(p * 1.3));
	if (drift <= 0.0)
		return 0.0;
	float kind = lc_noise(p * 2.1 + 7.0);
	float crust = 1.0 - smoothstep(0.3, 0.36, kind);
	vec3 base = mix(lichen_color, lichen_crust, crust);
	base = mix(base, lichen_yellow, smoothstep(0.8, 0.86, kind) * 0.7);
	if (far >= 1.0) {
		col = base;
		return drift * 0.04; // (a trace of their colour: far off they all but vanish)
	}
	vec3 q = p * 8.0;
	q += (lc_noise(q * 0.4) - 0.5) * vec3(1.9, -1.4, 1.2);
	float lobes = lc_noise(q * 2.6);  // lobe-sized
	float fine = lc_noise(q * 6.0);   // the scallops of their ends
	float patch = lc_noise(q * 0.55) * 0.52 + lobes * 0.28 + fine * 0.2;
	float t = 0.69 - drift * 0.06;
	float inside = patch - t;
	float cover = smoothstep(0.0, 0.012, inside);
	// leafy: the gaps between lobes (where `lobes` crosses the middle),
	// opening toward the rosette's rim; crust: thin cracks between plates
	float ridge = abs(lobes - 0.5);
	float gap_w = mix(0.045 + 0.06 * smoothstep(0.08, 0.0, inside), 0.012, crust);
	float gap = 1.0 - smoothstep(gap_w, gap_w + 0.01, ridge);
	cover *= 1.0 - gap * (1.0 - crust);
	// raised edges, paler: along the rim and beside the gaps
	float edge = 1.0 - smoothstep(0.0, 0.035, min(inside, (ridge - gap_w) * 0.8));
	col = base * mix(0.88, 1.0, fine) * mix(1.0, 1.25, edge * (1.0 - crust))
			* mix(1.0, 0.88, smoothstep(gap_w, gap_w + 0.2, ridge) * (1.0 - crust)); // (each lobe a little darker down its middle)
	col = mix(col, base * 0.55, gap * crust); // the crust's cracks
	// the crust's cups: a pale rim round a darker, browner middle
	float cup = smoothstep(0.76, 0.79, fine) * crust;
	col = mix(col, mix(base * 1.15, base * vec3(0.55, 0.45, 0.38), smoothstep(0.81, 0.84, fine)), cup);
	// how far it stands off the bark (m): lobes domed, crust flat
	relief = cover * mix(smoothstep(gap_w, gap_w + 0.1, ridge) * smoothstep(0.0, 0.05, inside) * 0.004, 0.0008, crust) * (1.0 - far);
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
