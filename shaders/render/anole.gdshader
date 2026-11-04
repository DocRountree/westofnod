shader_type spatial;

// A green anole's skin (Anole). Its body and tail one smooth skin bent
// along a spine (skinned: VERTEX.xy the point's place round the body, mm,
// VERTEX.z where along the spine, its points at whole numbers, 0 the neck;
// the spine's points and frames, sp, sx its right, sy its up, in the
// body's own mm, set each frame by the CPU); its head, legs and toes plain
// meshes in the same paint (skinned false). Bright leaf green above, paler
// down the sides, the belly and throat white; tiny granular scales (a
// fine pebbling, glinting); brown: the colour it turns, cold, or still a
// long while, or frightened (0 green .. 1 brown); young: a hatchling's
// duller, browner green; dark: a male's spot behind the eye (at its head).

uniform vec3 sp[40];
uniform vec3 sx[40];
uniform vec3 sy[40];
uniform int count = 2;
uniform bool skinned = false;
uniform float brown = 0.0;
uniform bool young = false;
uniform float belly_y = -0.35; // (where the white begins: the normal's y)

varying vec3 n_b;
varying vec3 p_b;

void vertex() {
	if (skinned) {
		float s = VERTEX.z;
		int i0 = clamp(int(floor(s)), 0, count - 2);
		int i1 = i0 + 1;
		float f = clamp(s - float(i0), 0.0, 1.0);
		vec3 a = sp[max(i0 - 1, 0)];
		vec3 b = sp[i0];
		vec3 c = sp[i1];
		vec3 d = sp[min(i1 + 1, count - 1)];
		vec3 p = 0.5 * (2.0 * b + (c - a) * f + (2.0 * a - 5.0 * b + 4.0 * c - d) * f * f + (3.0 * b - a - 3.0 * c + d) * f * f * f);
		vec3 x = normalize(mix(sx[i0], sx[i1], f));
		vec3 y = normalize(mix(sy[i0], sy[i1], f));
		vec3 z = normalize(cross(x, y));
		NORMAL = normalize(x * NORMAL.x + y * NORMAL.y + z * NORMAL.z);
		VERTEX = p + x * VERTEX.x + y * VERTEX.y;
	}
	n_b = NORMAL;
	p_b = VERTEX;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	float ny = normalize(n_b).y;
	vec3 green = young ? vec3(0.36, 0.45, 0.2) : vec3(0.3, 0.6, 0.16);
	vec3 side = young ? vec3(0.42, 0.48, 0.28) : vec3(0.48, 0.68, 0.3);
	vec3 tan = young ? vec3(0.4, 0.31, 0.2) : vec3(0.44, 0.33, 0.2);
	vec3 top = mix(green, tan, brown);
	vec3 c = mix(top, mix(side, tan * 1.15, brown), 1.0 - smoothstep(0.05, 0.6, ny)); // (paler down the sides)
	c = mix(c, vec3(0.9, 0.9, 0.82), 1.0 - smoothstep(belly_y - 0.12, belly_y + 0.12, ny)); // (the belly, the throat)
	// the granular scales: a fine pebbling, each its own shade
	vec2 g = vec2(p_b.x + p_b.z * 0.31, p_b.y + p_b.z) * 2.6;
	vec2 cell = floor(g);
	vec2 fr = fract(g) - 0.5;
	float bump = 1.0 - smoothstep(0.25, 0.5, length(fr));
	c *= 0.9 + 0.12 * h21(cell) + 0.05 * bump;
	ALBEDO = c;
	ROUGHNESS = 0.42 - 0.1 * bump;
	SPECULAR = 0.5;
}
