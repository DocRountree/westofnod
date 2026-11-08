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
// shedding (Anole.shed): its old skin loosened in pale, papery patches
// (shed: how much of it), pulled off and eaten bit by bit (peeled: how
// much of that gone); on the body's own surface (its rest place: r_b),
// so they ride on it as it moves
uniform float shed = 0.0;
uniform float peeled = 0.0;

varying vec3 n_b;
varying vec3 p_b;
varying vec3 r_b;

void vertex() {
	r_b = VERTEX;
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
float h31(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
// (smooth value noise, 0..1)
float vn3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

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
	float rough = 0.42 - 0.1 * bump;
	if (shed > 0.0) {
		// patches: two scales of noise on its rest surface, those under
		// shed's share loose; peeled's share of them (another noise's) gone
		vec3 q = vec3(r_b.x * 0.16, r_b.y * 0.16, r_b.z * 0.55);
		float n = vn3(q) * 0.65 + vn3(q * 2.3 + 7.1) * 0.35;
		float gone = vn3(q * 1.7 + 13.0);
		float cut = shed * 0.47;
		float patch_ = (1.0 - smoothstep(cut - 0.03, cut + 0.01, n)) * step(peeled * 1.05, gone);
		float rim = patch_ * (1.0 - smoothstep(0.0, 0.03, abs(n - cut))); // (its lifted edge, a little dark)
		c = mix(c, vec3(0.84, 0.86, 0.78), patch_ * 0.7);
		c *= 1.0 - 0.3 * rim;
		rough = mix(rough, 0.85, patch_);
	}
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.5;
}
