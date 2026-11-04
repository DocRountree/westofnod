shader_type spatial;

// The coats of the carnivores (Carnivore: RedFox, Bobcat), each part its own
// material, the species and the part saying how it's painted, by where on
// the part a point is (its object space: the body's and head's mm; a leg's,
// an ear's, a tail segment's own).
// species 0, a red fox: rufous orange above and down its sides, grizzled
//   darker along the back; its chin, throat, chest and belly white; its
//   lower legs black (its stockings); its ears' backs black; its tail
//   rufous, dark grizzled, its tip white
// species 1, a bobcat: tawny buff to grey brown, spotted and barred dark
//   (the legs barred), its belly white, spotted black; the face's ruff
//   barred; the ears' backs black, a white spot in each, their tufts black;
//   its bobbed tail barred, its tip black above, white beneath
// young: a fox kit's dark grey brown, fuzzy; a bobcat kitten's greyer,
//   spotted all over, bolder.
// part: 0 the body, 1 the head (its muzzle, cheeks: face), 2 a leg's upper,
// 3 its lower (and the metapodial), 4 a paw, 5 an ear (up its y: ear_len),
// 6 a tail segment (along: how far down the tail it is, 0..1), 7 a tuft.

uniform int species = 0;
uniform int part = 0;
uniform bool young = false;
uniform float along = 0.0;
uniform float ear_len = 80.0;

varying vec3 o;
varying vec3 no;

void vertex() {
	o = VERTEX;
	no = NORMAL;
}

float h31(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

float vn(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// (spots: dark where a cell's own point is near, each its own size)
float spots(vec3 p, float cell, float r) {
	vec3 c = floor(p / cell);
	float best = 9.0;
	for (int x = -1; x <= 1; x++)
		for (int y = -1; y <= 1; y++)
			for (int z = -1; z <= 1; z++) {
				vec3 q = c + vec3(float(x), float(y), float(z));
				vec3 at = (q + vec3(h31(q), h31(q + 7.1), h31(q + 3.3))) * cell;
				best = min(best, length(p - at) / (cell * (0.6 + 0.6 * h31(q + 1.9))));
			}
	return 1.0 - smoothstep(r * 0.7, r, best);
}

void fragment() {
	float ny = normalize(no).y;
	float grizzle = 0.84 + 0.28 * vn(o * 0.8) * vn(o * 0.21 + 2.0);
	float under = 1.0 - smoothstep(-0.55, -0.15, ny);
	vec3 c;
	vec3 white = vec3(0.92, 0.9, 0.86);
	if (species == 0) {
		vec3 red = young ? vec3(0.32, 0.27, 0.23) : vec3(0.72, 0.34, 0.13);
		vec3 back = young ? vec3(0.24, 0.2, 0.17) : vec3(0.48, 0.24, 0.12);
		c = mix(red, back, smoothstep(0.55, 0.95, ny) * 0.7) * grizzle;
		c = mix(c, young ? vec3(0.5, 0.45, 0.4) : white, under);
		if (part == 1) // (the muzzle's sides and the cheeks white)
			c = mix(c, white, (1.0 - smoothstep(-0.35, 0.05, ny)) * (young ? 0.3 : 1.0));
		if (part == 3 || part == 4) // (the stockings)
			c = young ? vec3(0.18, 0.15, 0.13) : vec3(0.08, 0.06, 0.05);
		if (part == 2)
			c = mix(c, vec3(0.1, 0.07, 0.05), smoothstep(0.0, 0.5, o.y) * (young ? 0.3 : 0.8)); // (darkening down to the knee)
		if (part == 5) { // (the ears: black behind, white furred within)
			c = o.z > 0.0 ? vec3(0.07, 0.05, 0.04) : mix(white * 0.9, vec3(0.08), smoothstep(ear_len * 0.85, ear_len, o.y));
		}
		if (part == 6) { // (the brush: grizzled, darker at its middle, its tip white)
			c = mix(red * 0.9, vec3(0.2, 0.12, 0.07), 0.35 * vn(o * 0.4)) * grizzle;
			c = mix(c, white, smoothstep(0.82, 0.92, along));
		}
	} else {
		vec3 buff = young ? vec3(0.55, 0.5, 0.44) : vec3(0.64, 0.51, 0.36);
		vec3 grey = young ? vec3(0.48, 0.45, 0.42) : vec3(0.52, 0.46, 0.38);
		c = mix(buff, grey, smoothstep(0.4, 0.95, ny) * 0.6) * grizzle;
		float sp = spots(o, young ? 22.0 : 28.0, 0.42);
		float on_side = 1.0 - smoothstep(0.7, 0.98, ny); // (fewer down the spine: there it's streaked)
		vec3 dark = vec3(0.12, 0.09, 0.07);
		c = mix(c, dark, sp * on_side * (young ? 0.9 : 0.75));
		c = mix(c, mix(c, dark * 1.5, 0.5), smoothstep(0.85, 1.0, ny) * step(0.5, fract(o.x * 0.06 + 0.5)) * 0.4);
		vec3 belly = mix(white, dark, spots(o, 36.0, 0.32) * 0.8);
		c = mix(c, belly, under);
		if (part == 1) { // (the ruff: barred; white about the eyes and muzzle)
			float bar = step(0.62, fract(o.y * 0.07 + o.z * 0.03));
			c = mix(c, dark, bar * smoothstep(0.0, 0.6, abs(normalize(no).x)) * 0.6);
			c = mix(c, white, (1.0 - smoothstep(-0.4, 0.0, ny)) * 0.8);
		}
		if (part == 2 || part == 3) { // (the legs: barred)
			float bar = step(0.7, fract(o.y * 3.5));
			c = mix(c, dark, bar * 0.6);
			c = mix(c, white * 0.9, (1.0 - smoothstep(-0.2, 0.2, no.x * sign(o.x + 1e-4))) * 0.3);
		}
		if (part == 4)
			c = mix(buff, white, 0.4);
		if (part == 5) // (the ears: black behind, a white spot; within, pale)
			c = o.z > 0.0 ? mix(vec3(0.05), white, 1.0 - smoothstep(9.0, 12.0, length(o.xy - vec2(0.0, ear_len * 0.45)))) : white * 0.85;
		if (part == 6) { // (barred, the tip black above, white beneath)
			float bar = step(0.65, fract(along * 4.0));
			c = mix(buff * grizzle, dark, bar * 0.7);
			c = mix(c, dark, smoothstep(0.75, 0.85, along) * smoothstep(-0.2, 0.3, ny));
			c = mix(c, white, (1.0 - smoothstep(-0.4, 0.0, ny)));
		}
	}
	if (part == 7)
		c = vec3(0.05, 0.04, 0.03);
	ALBEDO = c;
	ROUGHNESS = 0.92;
	RIM = young ? 0.85 : 0.65;
	RIM_TINT = 0.6;
	SPECULAR = 0.25;
}
