shader_type spatial;

// A larva (Larva): its body one smooth skin, a tube bent along its spine
// here (skinned: the mesh's VERTEX.xy the point's place round the body at
// full size, VERTEX.z where along the spine (segment centres at whole
// numbers), NORMAL likewise in the body's frame; the spine's points and
// frames, sp, sx (its right), sy (its up), set each frame by the CPU), its
// creases between segments shallow; or (not skinned) a part on it (the
// head), its own object space. Painted from where on its segment a point
// is (o: across -0.5..0.5, along -0.5 front .. 0.5 back):
// pattern 0: plain (base), a pale line along each side (line)
// pattern 1: a monarch caterpillar's bands: white, a broad black band, a
//   yellow band, black again, round each segment
// pattern 2: a hornworm's (the clearwing's): green, a pale yellow line
//   along each side, a pale stripe slanting across, a reddish spiracle
// pattern 3: a lady beetle larva's: blackish grey, bumpy, an orange patch
//   on its sides on the segments of spot_mask
// pattern 4: a grub's: creamy, a little see-through, finely creased
// The segments from tail_from on are `tail` (a June grub's dark rear).

uniform int pattern = 0;
uniform vec3 base : source_color = vec3(0.9, 0.88, 0.8);
uniform vec3 line : source_color = vec3(0.95, 0.9, 0.6);
uniform vec3 band_a : source_color = vec3(0.02);
uniform vec3 band_b : source_color = vec3(0.96, 0.82, 0.1);
uniform vec3 tail : source_color = vec3(0.4, 0.36, 0.3);
uniform bool spot = false;
uniform float gloss = 0.4;
uniform bool skinned = false;
uniform vec3 sp[16];
uniform vec3 sx[16];
uniform vec3 sy[16];
uniform int count = 2;
uniform float size = 1.0;
uniform int spot_mask = 0;
uniform int tail_from = 99;

varying vec3 o;
varying flat float seg;

void vertex() {
	if (skinned) {
		float s = VERTEX.z;
		int i0 = clamp(int(floor(s)), 0, count - 2);
		int i1 = i0 + 1;
		float f = s - float(i0);
		vec3 p;
		if (f >= 0.0 && f <= 1.0) {
			// (through its neighbours too: Catmull-Rom, a smooth bend)
			vec3 a = sp[max(i0 - 1, 0)];
			vec3 b = sp[i0];
			vec3 c = sp[i1];
			vec3 d = sp[min(i1 + 1, count - 1)];
			p = 0.5 * (2.0 * b + (c - a) * f + (2.0 * a - 5.0 * b + 4.0 * c - d) * f * f + (3.0 * b - a - 3.0 * c + d) * f * f * f);
		} else {
			p = mix(sp[i0], sp[i1], f); // (past an end: on along it)
		}
		float k = clamp(f, 0.0, 1.0);
		vec3 x = normalize(mix(sx[i0], sx[i1], k));
		vec3 y = normalize(mix(sy[i0], sy[i1], k));
		vec3 z = normalize(cross(x, y));
		NORMAL = normalize(x * NORMAL.x + y * NORMAL.y + z * NORMAL.z);
		VERTEX = p + (x * VERTEX.x + y * VERTEX.y) * size;
		o = CUSTOM0.xyz;
		seg = CUSTOM0.w;
	} else {
		o = VERTEX;
		seg = -1.0;
	}
}

void fragment() {
	vec3 c = base;
	bool spotted = spot || (seg >= 0.0 && ((spot_mask >> int(seg)) & 1) == 1);
	if (seg >= float(tail_from))
		c = tail;
	float side = abs(o.x) / max(length(o.xy), 1e-4); // (0 top and bottom, 1 the sides)
	if (pattern == 1) {
		float z = o.z + 0.5;
		// white | black | yellow | black | white, a little wavy
		float w = z + 0.03 * sin(atan(o.y, o.x) * 4.0);
		c = vec3(0.95, 0.94, 0.9);
		if (w > 0.12 && w < 0.88) c = band_a;
		if (w > 0.36 && w < 0.64) c = band_b;
		if (w > 0.42 && w < 0.58 && o.y < -0.25) c = band_a; // (the underside darker)
	} else if (pattern == 2) {
		float lat = smoothstep(0.86, 0.9, side) * (1.0 - smoothstep(0.95, 0.99, side)) * step(0.0, o.y + 0.05);
		float slant = smoothstep(0.03, 0.0, abs(o.z * 0.9 - o.y * 0.7 - 0.05)) * step(0.4, side);
		c = mix(c, line, max(lat, slant * 0.7));
		float spir = 1.0 - smoothstep(0.05, 0.08, length(vec2(o.z + 0.05, o.y + 0.12)));
		c = mix(c, vec3(0.45, 0.12, 0.08), spir * step(0.8, side));
	} else if (pattern == 3) {
		float bumps = 0.5 + 0.5 * sin(atan(o.y, o.x) * 6.0) * sin(o.z * 12.0);
		c *= 0.8 + 0.3 * bumps;
		if (spotted)
			c = mix(c, band_b, smoothstep(0.75, 0.85, side) * step(-0.1, o.y));
	} else if (pattern == 4) {
		c *= 0.92 + 0.08 * cos(o.z * 25.0); // (finely creased across)
		SSS_STRENGTH = 0.3;
	} else {
		c = mix(c, line, smoothstep(0.88, 0.93, side) * (1.0 - smoothstep(0.96, 1.0, side)) * step(0.0, o.y));
	}
	ALBEDO = c;
	ROUGHNESS = mix(0.8, 0.25, gloss);
	SPECULAR = 0.4;
}
