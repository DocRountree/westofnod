
// A snake's body (Snake): one smooth skin, a tube bent along its spine
// here: the mesh's VERTEX.xy the point's place round the body at full
// size (m), VERTEX.z where along the spine (its points at whole numbers,
// 0 the neck), NORMAL likewise in the body's frame; the spine's points
// and frames (sp, sx its right, sy its up) set each frame by the CPU. A
// swallowed meal a bulge travelling down it (bulge_s, bulge_r). Painted
// from UV: x along (0 the neck .. 1 the tail's tip), y round (0 and 1 the
// back, 0.5 the belly); `girths` how many times round it is long (its
// marks' scale: its length in its thicknesses), species 0 an eastern diamondback, 1 an eastern milk
// snake; young: the newborn's colours.

uniform vec3 sp[48];
uniform vec3 sx[48];
uniform vec3 sy[48];
uniform int count = 2;
uniform float size = 1.0;
uniform float bulge_s = -100.0;
uniform float bulge_r = 0.0;
uniform int species = 0;
uniform bool young = false;
uniform float girths = 20.0; // (its length over its thickness)
uniform float dull = 0.0; // (before it sheds: its skin dull, bluish grey, the old skin loosening)
uniform float fade = 1.0; // (a cast skin's: fading away)

varying vec2 b_uv;

void vertex() {
	float s = VERTEX.z;
	int i0 = clamp(int(floor(s)), 0, count - 2);
	int i1 = i0 + 1;
	float f = s - float(i0);
	vec3 p;
	if (f >= 0.0 && f <= 1.0) {
		vec3 a = sp[max(i0 - 1, 0)];
		vec3 b = sp[i0];
		vec3 c = sp[i1];
		vec3 d = sp[min(i1 + 1, count - 1)];
		p = 0.5 * (2.0 * b + (c - a) * f + (2.0 * a - 5.0 * b + 4.0 * c - d) * f * f + (3.0 * b - a - 3.0 * c + d) * f * f * f);
	} else {
		p = mix(sp[i0], sp[i1], f);
	}
	float k = clamp(f, 0.0, 1.0);
	vec3 x = normalize(mix(sx[i0], sx[i1], k));
	vec3 y = normalize(mix(sy[i0], sy[i1], k));
	vec3 z = normalize(cross(x, y));
	float swell = 1.0 + bulge_r * exp(-pow((s - bulge_s) / 1.8, 2.0));
	NORMAL = normalize(x * NORMAL.x + y * NORMAL.y + z * NORMAL.z);
	VERTEX = p + (x * VERTEX.x + y * VERTEX.y) * size * swell;
	b_uv = UV;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	float u = b_uv.x;
	float v = b_uv.y;
	float t = u * girths; // (along it, in its thicknesses)
	float top = min(v, 1.0 - v) * 2.0; // 0 the back's middle .. 1 the belly's
	vec3 c;
	float rough;
	if (species == 0) {
		// the diamondback: a row of dark diamonds down its back, their
		// centres lighter, edged in cream; the flanks olive brown, the
		// belly yellowish; the tail banded grey and black
		vec3 base = young ? vec3(0.55, 0.48, 0.34) : vec3(0.42, 0.35, 0.22);
		c = mix(base, base * 0.75, smoothstep(0.35, 0.6, top));
		float P = 0.6; // (about 30 diamonds down a grown one)
		float dx = abs(fract(t / P) - 0.5) * 2.0;
		float m = dx + top * 2.4;
		vec3 dark = vec3(0.12, 0.08, 0.05);
		vec3 centre = young ? vec3(0.5, 0.42, 0.28) : vec3(0.36, 0.28, 0.17);
		vec3 cream = vec3(0.85, 0.78, 0.55);
		if (m < 1.0) {
			c = m > 0.86 ? cream : (m > 0.48 ? dark : centre);
		}
		c = mix(c, vec3(0.78, 0.72, 0.5), smoothstep(0.62, 0.75, top)); // (the belly)
		if (u > 0.86) { // (the tail: banded)
			float band = step(0.5, fract(t * 0.8));
			c = mix(mix(vec3(0.42, 0.4, 0.36), vec3(0.08, 0.07, 0.06), band), c, smoothstep(0.62, 0.75, top) * 0.5);
		}
		rough = 0.68; // (keeled scales: dull)
	} else {
		// the milk snake: grey tan, big red-brown saddles down its back
		// edged black, smaller blotches alternating low on its sides; the
		// belly a black and white checkerboard; a pale V on its nape
		vec3 base = vec3(0.68, 0.64, 0.55);
		c = base;
		vec3 red = young ? vec3(0.78, 0.2, 0.1) : vec3(0.52, 0.2, 0.12);
		float P = 0.95; // (about 30 saddles)
		float sx_ = abs(fract(t / P) - 0.5) * 2.0; // 0 a saddle's middle
		float saddle = max(sx_ / 0.62, top / 0.42);
		if (saddle < 1.0)
			c = saddle > 0.82 ? vec3(0.05, 0.04, 0.04) : red;
		float g = fract(t / P);
		float lx = min(g, 1.0 - g) * 2.0; // 0 between saddles
		float lat = max(lx / 0.4, abs(top - 0.52) / 0.12);
		if (lat < 1.0)
			c = lat > 0.75 ? vec3(0.05, 0.04, 0.04) : red;
		if (top > 0.72) { // (the belly's checkerboard)
			float ch = mod(floor(t * 1.4) + floor(v * 10.0), 2.0);
			c = mix(vec3(0.92, 0.9, 0.85), vec3(0.06, 0.06, 0.06), ch * 0.85);
		}
		if (u < 0.03 && top < 0.4) { // (the pale V on its nape)
			float vv = abs(top - (0.03 - u) * 11.0);
			c = mix(c, vec3(0.88, 0.84, 0.72), 1.0 - smoothstep(0.06, 0.1, vv));
		}
		rough = 0.28; // (smooth scales: glossy)
	}
	// the scales: rows of them, their edges a little darker
	vec2 sc = vec2(t * 4.0, v * 28.0);
	sc.x += floor(sc.y) * 0.5;
	vec2 fs = abs(fract(sc) - 0.5);
	float edge = smoothstep(0.38, 0.5, max(fs.x * 1.1, fs.y));
	c *= 1.0 - 0.18 * edge;
	c *= 0.95 + 0.1 * h21(floor(sc));
	c = mix(c, c * 0.65 + vec3(0.1, 0.11, 0.14), dull); // (dulled, bluish: its old skin's lifting)
	rough = mix(rough, 0.85, dull);
#ifdef SHED
	// a cast skin: inside out, pale, papery, see-through, the pattern a
	// ghost of itself, the scales' edges drawn on it
	c = mix(vec3(0.9, 0.88, 0.82), c, 0.18) * (1.0 - 0.25 * edge);
	ALPHA = 0.55 * fade;
	rough = 0.6;
#endif
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.45;
}
