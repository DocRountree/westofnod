// The forest's canopy over its floor, in place of the trees' own shadows
// (Population.SHADOWLESS: none cast there): the floor shaded by crowns about
// a tree's width across, thrown along the sun's way from about their height,
// light coming through the gaps between them and in small flecks through the
// leaves; the canopy hiding much of the sky's light too. A factor for the
// floor's colour (terrain.gdshader; ground_cover.gdshader for the grass and
// ferns on it, so they shade alike). Include after aerial.gdshaderinc (it
// goes by haze_sun_dir, the way to the sun).

#ifndef CANOPY_INC
#define CANOPY_INC

const float CANOPY_COVER = 0.75; // how much of the forest's floor its crowns shade, at the most
const float CANOPY_HEIGHT = 12.0; // m up the crowns throw their shade from

float cn_hash(ivec2 c) {
	uint v = uint(c.x) * 1597334677u ^ uint(c.y) * 3812015801u;
	v = v * 747796405u + 2891336453u;
	v = ((v >> ((v >> 28u) + 4u)) ^ v) * 277803737u;
	return float((v >> 22u) ^ v) / 4294967295.0;
}

float cn_noise(vec2 p) {
	vec2 fi = floor(p);
	ivec2 i = ivec2(fi);
	vec2 f = p - fi;
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(cn_hash(i), cn_hash(i + ivec2(1, 0)), f.x), mix(cn_hash(i + ivec2(0, 1)), cn_hash(i + ivec2(1, 1)), f.x), f.y);
}

// The floor's colour's factor at p (the map's xz), h m up: forest, how much
// of it is the forest's (0..1); fp, m a pixel spans there (the pattern
// blurred to its mean once a pixel is too wide for it); night, 0 day .. 1.
float canopy_light(vec2 p, float h, float forest, float fp, float night_k) {
	float cover = clamp(forest, 0.0, 1.0) * CANOPY_COVER * (1.0 - smoothstep(575.0, 1150.0, h)); // (thinning up the mountains, as the trees)
	if (cover <= 0.0)
		return 1.0;
	vec3 sun = normalize(haze_sun_dir);
	float up = max(sun.y, 0.08);
	// (a point's shaded by the crown toward the sun from it: further off the
	// lower the sun is, within three crowns' height)
	vec2 off = sun.xz / up * CANOPY_HEIGHT;
	off *= min(1.0, 3.0 * CANOPY_HEIGHT / max(length(off), 1e-3));
	vec2 q = p + off;
	float crowns = cn_noise(q / 6.0) * 0.6 + cn_noise(q / 15.0 + vec2(7.3, -2.1)) * 0.4;
	float gaps = smoothstep(0.52, 0.7, crowns);
	float flecks = smoothstep(0.62, 0.8, cn_noise(q / 1.2 + vec2(3.1, 9.7))) * 0.75;
	float lit = max(gaps, flecks);
	lit = mix(lit, 0.35, smoothstep(1.0, 5.0, fp)); // (its mean, far off)
	float direct = smoothstep(0.0, 0.3, sun.y) * (1.0 - night_k); // (how much of the light is the sun's)
	float shade = mix(1.0, mix(0.5, 1.0, lit), cover * direct); // (its shade not too deep: the floor still to be seen)
	return shade * (1.0 - 0.15 * cover); // (and the sky's light, which the canopy hides some of)
}

#endif
