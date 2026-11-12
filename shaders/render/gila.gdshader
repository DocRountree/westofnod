shader_type spatial;

uniform vec3 sp[40];
uniform vec3 sx[40];
uniform vec3 sy[40];
uniform int count = 2;
uniform bool skinned = false;
uniform bool young = false;
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

uniform float brown = 0.0; // (unused: the anole's)
uniform float zn = -24.0;    // (its frame, mm: the neck; each spine point's spacing; the vent)
uniform float seg = 5.0;
uniform float zv = 46.0;
uniform float zt = 90.0;
uniform int part = 0;        // 0 its body's skin, 1 its head, 2 its legs, 3 its toes

// A Gila monster's skin (GilaMonster): its whole hide beaded, rounded
// scales like little stones set close (osteoderms under them), each one
// its own colour: black, or pink, salmon, orange; the colour in a
// reticulated net of blotches over its back and sides, broken; the tail
// ringed, black bands between pink; the head black, mottled pink on top;
// the belly dark, marbled; the toes and claws black. A hatchling's paler,
// brighter, banded clean across.
void fragment() {
	vec3 q = skinned ? vec3(r_b.x, r_b.y, zn + r_b.z * seg) : r_b;
	float ny = normalize(n_b).y;
	// the beads: rows staggered round it, each a dome
	float bs = part == 1 ? 1.1 : (part >= 2 ? 0.9 : 1.45); // (mm: smaller on its head and legs)
	vec2 g = vec2(atan(q.x, q.y + 2.0) * 7.0 / bs, q.z / bs);
	if (part != 0)
		g = vec2(q.x + q.z * 0.5, q.y * 1.2 + q.z) / bs;
	float row = floor(g.y);
	g.x += 0.5 * mod(row, 2.0);
	vec2 cell = floor(g);
	vec2 fr = fract(g) - 0.5;
	float r = length(fr * vec2(1.0, 1.1));
	float dome = 1.0 - smoothstep(0.32, 0.5, r);
	// its colour: by bead, from where the bead's centre is
	vec3 cc = vec3((cell.x + 0.5 - 0.5 * mod(row, 2.0)) * bs, 0.0, (row + 0.5) * bs);
	vec3 wq = part == 0 ? vec3(q.x, q.y, q.z) : q;
	float n = vn3(vec3(wq.x * 0.3, wq.y * 0.3, wq.z * 0.2) + 3.0) * 0.55 + vn3(wq * 0.6 + 9.0) * 0.45; // (a net of blotches, broken)
	n += 0.12 * (h21(cell + 0.37) - 0.5); // (each bead its own)
	float pink = smoothstep(0.53, 0.58, n); // (black the more of it)
	if (part == 0 && q.z > zv + 4.0) { // (the tail: ringed)
		float t = (q.z - zv) / max(zt - zv, 1.0);
		float band = fract(t * 4.2 + 0.06 * (vn3(q * 0.3) - 0.5));
		pink = max(pink * 0.4, smoothstep(0.08, 0.14, band) * (1.0 - smoothstep(0.52, 0.6, band)));
	}
	if (young && part == 0 && q.z <= zv + 4.0) { // (a hatchling's: banded clean across its back)
		float band = fract((q.z - zn) / 15.0 + 0.1 * (vn3(q * 0.4) - 0.5));
		pink = max(pink * 0.5, smoothstep(0.1, 0.18, band) * (1.0 - smoothstep(0.55, 0.65, band)));
	}
	if (part == 1) // (its head black, a little pink on top behind)
		pink *= 0.8 * smoothstep(0.2, 0.7, ny) * smoothstep(-12.0, -5.0, q.z) * step(0.45, h21(cell + 9.0)); // (black, speckled peach over its crown)
	if (part == 2) // (its legs: black, spotted pink)
		pink = step(0.62, h21(cell + 4.1)) * 0.9;
	if (part == 3)
		pink = 0.0;
	pink *= mix(0.35, 1.0, smoothstep(-0.5, 0.0, ny)); // (darker beneath)
	vec3 black = vec3(0.035, 0.03, 0.028) * (0.85 + 0.3 * h21(cell + 5.1));
	vec3 pk = mix(vec3(0.86, 0.6, 0.46), vec3(0.9, 0.52, 0.36), h21(cell + 2.3)) * (young ? 1.05 : 1.0); // (peach, salmon, a few orange)
	vec3 c = mix(black, pk, pink);
	c *= 0.65 + 0.45 * dome; // (the crevices between the beads dark)
	ALBEDO = c;
	ROUGHNESS = mix(0.75, 0.45, dome);
	SPECULAR = 0.45;
	// (each bead rounded: the normal tipped out from its centre)
	vec3 t1 = normalize(dFdx(VERTEX));
	vec3 t2 = normalize(dFdy(VERTEX));
	NORMAL = normalize(NORMAL + (fr.x * t1 - fr.y * t2) * dome * 0.9);
}
