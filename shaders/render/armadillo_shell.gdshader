shader_type spatial;
render_mode cull_disabled;
// A nine-banded armadillo's carapace (Armadillo): bone under horn, in
// scutes. UV: x along it (its body's mm, nose to tail), y round it (mm
// of arc from its spine). Its shoulder shield before (a mosaic of small
// rounded scutes, rosettes, each a little domed, a pit or two in it); the
// nine bands across its middle (each a row of long scutes, their rear ends
// pointed, the band's rear edge over the next; the skin between them pale,
// pinkish, folded, a few bristles); its hip shield behind (as the shoulder
// shield, down over its rump). Greyish tan, pinkish where the horn's thin;
// the grooves between darker. Its edge a row of small scutes.

uniform float band_from = -35.0;
uniform float band_w = 14.4;
uniform float bands = 9.0;
uniform vec3 horn = vec3(0.62, 0.56, 0.5);
uniform vec3 pink = vec3(0.82, 0.7, 0.64);
uniform vec3 groove = vec3(0.27, 0.23, 0.21);
uniform bool young = false;

varying vec2 sh; // (its own: along, round)
varying float edge; // (how near its free edge, 0..1)

void vertex() {
	sh = UV;
	edge = UV2.x;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 h22(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }

// (cells: the distance to the nearest centre, to the second; and the
// nearest's id)
vec3 cells(vec2 p) {
	vec2 i = floor(p);
	float d1 = 9.0;
	float d2 = 9.0;
	float id = 0.0;
	for (int x = -1; x <= 1; x++)
		for (int y = -1; y <= 1; y++) {
			vec2 q = i + vec2(float(x), float(y));
			vec2 c = q + 0.2 + 0.6 * h22(q);
			float d = length(p - c);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = h21(q);
			} else if (d < d2) {
				d2 = d;
			}
		}
	return vec3(d1, d2, id);
}

void fragment() {
	float z = sh.x;
	float u = sh.y;
	float band_to = band_from + band_w * bands;
	float h = 0.0; // (its height: domed scutes, sunk grooves)
	vec3 c = horn;
	float joint = 0.0;
	if (z > band_from && z < band_to) {
		// the bands: each a row of long scutes, pointed behind
		float bz = (z - band_from) / band_w;
		float f = fract(bz);
		float bi = floor(bz);
		float row = u / 6.5 + bi * 0.5;
		float col = fract(row);
		float tip = 0.5 + 0.5 * f; // (their sides drawn in toward the back: a point)
		float side = abs(col - 0.5) * 2.0;
		float scute = 1.0 - smoothstep(tip - 0.25, tip, side + (f > 0.88 ? (f - 0.88) * 6.0 : 0.0));
		joint = 1.0 - smoothstep(0.0, 0.16, f); // (the skin at the band's front, out from under the one before)
		h = scute * (0.6 + 0.4 * sin(f * 3.14159)) - joint * 0.5;
		c = mix(groove, horn * (0.92 + 0.16 * h21(vec2(bi, floor(row)))), scute);
		c = mix(c, pink * 0.95, joint * 0.85);
	} else {
		// the shields: a mosaic of rosettes, small round scutes ringed by
		// smaller ones
		vec2 p = vec2(z, u) / 8.5;
		vec3 cl = cells(p);
		float g = smoothstep(0.0, 0.14, cl.y - cl.x); // (0 in the grooves)
		vec3 cs = cells(p * 2.2 + 3.1);
		float small = smoothstep(0.0, 0.12, cs.y - cs.x);
		float dome = 1.0 - smoothstep(0.0, 0.5, cl.x);
		h = g * (0.4 + 0.6 * dome) * mix(1.0, small, 0.5);
		c = mix(groove, horn * (0.88 + 0.22 * cl.z), g * mix(1.0, small, 0.45));
		c = mix(c, pink, dome * 0.25); // (pinkish where it's thin, at each one's crown)
		float pit = 1.0 - smoothstep(0.05, 0.11, length(fract(p * 1.0 + cl.z) - 0.5)); // (a pit in it)
		c = mix(c, groove, pit * 0.35 * g);
	}
	// (its edge: a row of small scutes, darker)
	c = mix(c, groove * 1.4, smoothstep(0.82, 1.0, edge) * 0.5);
	if (young)
		c = mix(c, pink * 1.05, 0.45); // (a young one's: soft, leathery, pink grey)
	if (!FRONT_FACING)
		c = vec3(0.2, 0.17, 0.15); // (its underside: dark, in shadow)
	ALBEDO = pow(clamp(c, 0.0, 1.0), vec3(2.2));
	// (bump: its height's slope across the screen)
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	vec3 n = normalize(NORMAL);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dFdx(h) * r1 + dFdy(h) * r2);
	float vis = 1.0 - smoothstep(0.4, 1.4, length(fwidth(vec2(z, u) / 7.0)));
	NORMAL = normalize(abs(det) * n - grad * 0.0015 * vis);
	ROUGHNESS = mix(0.5, 0.75, joint);
	SPECULAR = 0.35;
}
