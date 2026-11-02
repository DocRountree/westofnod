// Lichen and moss on bark (bark.gdshader). Patterns in the tree's own space
// (`p`, m, per instance offset by `seed`), so they stay put on the bark as
// it sways and differ tree to tree.
//
// Lichen: teal-grey crusts, rosettes a few cm across with lobed edges and
// paler rims, gathered in drifts here and there (lichen_amount: their
// share of the bark). Moss (moss_amount; the stumps and logs): soft green
// cushions on whatever faces up, thinning down the sides, in patches.
// Far off both give way to their average (lichen_mean), so they don't
// shimmer.

uniform float lichen_amount = 0.35;
uniform float moss_amount = 0.0;
uniform vec3 lichen_color : source_color = vec3(0.42, 0.58, 0.55);
uniform vec3 lichen_rim : source_color = vec3(0.6, 0.71, 0.67);
uniform vec3 moss_color : source_color = vec3(0.23, 0.33, 0.07);
uniform vec3 moss_light : source_color = vec3(0.38, 0.48, 0.12);

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

// The nearest rosette: (distance / its radius, its random 0..1). Each cell
// has one rosette of its own size; some cells none.
vec2 lc_rosette(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	float best = 9.0, id = 0.0;
	for (int z = -1; z <= 1; z++)
	for (int y = -1; y <= 1; y++)
	for (int x = -1; x <= 1; x++) {
		vec3 g = vec3(float(x), float(y), float(z));
		vec3 h = lc_hash3(i + g);
		float r = mix(0.3, 0.8, h.z);
		float d = length(g + h * 0.8 + 0.1 - f) / r;
		if (h.x < 0.8 && d < best) { best = d; id = h.y; }
	}
	return vec2(best, id);
}

// Lichen's share of the bark at p, 0..1 (rim: how much of it is the pale rim).
float lichen_cover(vec3 p, float far, out float rim) {
	rim = 0.0;
	float drift = smoothstep(0.75 - lichen_amount, 1.05 - lichen_amount, lc_noise(p * 0.9) * 0.7 + lc_noise(p * 2.7) * 0.3);
	if (drift <= 0.0 || lichen_amount <= 0.0)
		return 0.0;
	if (far >= 1.0)
		return drift * 0.55; // (the rosettes' average share)
	vec3 q = p * 6.0; // rosettes ~5-25 cm
	vec2 r = lc_rosette(q);
	float lobe = lc_noise(q * 3.1 + r.y * 13.0) * 0.45 + lc_noise(q * 7.3) * 0.15;
	float edge = r.x + lobe - 0.3;
	float cover = (1.0 - smoothstep(0.62, 0.7, edge)) * smoothstep(0.0, 0.3, drift);
	rim = smoothstep(0.42, 0.62, edge) * cover;
	return mix(cover, drift * 0.55, far);
}

// Moss's share of the bark at p, facing `up` (the surface's world normal's
// y), and how light it is there.
float moss_cover(vec3 p, float up, float far, out float light) {
	light = 0.0;
	if (moss_amount <= 0.0)
		return 0.0;
	float n = lc_noise(p * 1.6) * 0.6 + lc_noise(p * 5.0) * 0.4;
	float side = smoothstep(-0.35, 0.7, up);
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
