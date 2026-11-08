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
// pattern 1: a monarch caterpillar's bands round each segment: white (a
//   fine black line through it), a broad black band, a yellow band in its
//   middle, black again; duskier beneath
// pattern 2: a hornworm's (the clearwing's): yellowish green, a pale yellow
//   line along each side of its back, a faint pale stripe slanting across,
//   a reddish spiracle ringed pale; granules: fine pale bumps all over
// pattern 3: a lady beetle larva's: blackish grey, bumpy, an orange patch
//   on its sides on the segments of spot_mask
// pattern 4: a grub's: creamy, a little see-through, finely creased
// pattern 5: a swallowtail caterpillar's: green, a broad black band round
//   each segment (band_a), a ring of orange spots in it (band_b)
// pattern 6: a luna caterpillar's: lime green, paler creases between its
//   segments, a pale line (line) low along each side, two pairs of small
//   magenta warts (band_b) across each segment's back
// The segments from tail_from on are `tail` (a June grub's dark rear).

uniform int pattern = 0;
uniform vec3 base : source_color = vec3(0.9, 0.88, 0.8);
uniform vec3 line : source_color = vec3(0.95, 0.9, 0.6);
uniform vec3 band_a : source_color = vec3(0.02);
uniform vec3 band_b : source_color = vec3(0.96, 0.82, 0.1);
uniform vec3 tail : source_color = vec3(0.4, 0.36, 0.3);
uniform bool spot = false;
uniform float gloss = 0.4;
uniform float wrinkle = 0.08; // (a grub's creases: how deep)
uniform float annulets = 4.0; // (a segment's folds)
uniform bool spiracles = false;
uniform bool granules = false; // (a hornworm's: fine pale bumps all over it)
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
		// white (a fine black line in it) | black | yellow | black | white,
		// a little wavy round it
		float w = z + 0.025 * sin(atan(o.y, o.x) * 4.0);
		c = vec3(0.95, 0.94, 0.9);
		if ((w > 0.07 && w < 0.1) || (w > 0.9 && w < 0.93)) c = band_a;
		if (w > 0.2 && w < 0.8) c = band_a;
		if (w > 0.31 && w < 0.69) c = band_b;
		if (w > 0.3 && w < 0.7 && o.y < -0.28) c = band_a; // (the yellow only over its back and sides)
		c *= mix(1.0, 0.6, 1.0 - smoothstep(-0.48, -0.3, o.y)); // (duskier beneath)
		if (spiracles) // (a black breathing hole low on each side, in the white)
			c = mix(c, band_a, (1.0 - smoothstep(0.03, 0.045, length(vec2(w - 0.15, (o.y + 0.06) * 1.3)))) * step(0.85, side));
	} else if (pattern == 2) {
		// a darker line down its back; a pale one along each side of it
		c *= 1.0 - 0.18 * (1.0 - smoothstep(0.06, 0.12, side)) * step(0.0, o.y);
		float dl = smoothstep(0.42, 0.47, side) * (1.0 - smoothstep(0.55, 0.6, side)) * step(0.0, o.y);
		float slant = smoothstep(0.03, 0.0, abs(o.z * 0.9 - o.y * 0.7 - 0.05)) * step(0.55, side) * step(o.y, 0.15);
		c = mix(c, line, max(dl, slant * 0.35));
		if (granules) { // (fine pale bumps, scattered all over it)
			float along = seg + o.z + 0.5;
			float round_ = atan(o.y, o.x) / 6.2832 + 0.5;
			vec2 g = vec2(along * 5.0, round_ * 28.0);
			vec2 cell = floor(g);
			float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
			vec2 jit = vec2(fract(h * 7.31), fract(h * 3.17)) - 0.5;
			float d = length(fract(g) - 0.5 - jit * 0.4);
			c = mix(c, vec3(0.93, 0.95, 0.82), (1.0 - smoothstep(0.13, 0.2, d)) * step(0.3, h) * 0.85);
		}
		// its spiracle: reddish brown, ringed pale
		float sd = length(vec2(o.z + 0.05, (o.y + 0.12) * 1.2));
		c = mix(c, vec3(0.95, 0.92, 0.7), (1.0 - smoothstep(0.065, 0.085, sd)) * step(0.8, side));
		c = mix(c, vec3(0.45, 0.13, 0.08), (1.0 - smoothstep(0.04, 0.06, sd)) * step(0.8, side));
	} else if (pattern == 3) {
		float bumps = 0.5 + 0.5 * sin(atan(o.y, o.x) * 6.0) * sin(o.z * 12.0);
		c *= 0.8 + 0.3 * bumps;
		if (spotted)
			c = mix(c, band_b, smoothstep(0.75, 0.85, side) * step(-0.1, o.y));
	} else if (pattern == 5) {
		float z = o.z + 0.5;
		float ang = atan(o.y, o.x); // (round the body)
		float blk = smoothstep(0.24, 0.27, z) * (1.0 - smoothstep(0.6, 0.63, z));
		c = mix(c, band_a, blk);
		// six orange spots round the band (none beneath)
		float k = floor((ang / 6.2832 + 0.5) * 8.0 + 0.5);
		float ca = (k / 8.0 - 0.5) * 6.2832;
		vec2 q = vec2(z - 0.43, (ang - ca) * 0.32);
		float dot_ = (1.0 - smoothstep(0.075, 0.095, length(q))) * step(-0.25, o.y);
		c = mix(c, band_b, dot_ * blk);
		c *= mix(1.0, 0.85, 1.0 - smoothstep(-0.48, -0.3, o.y));
	} else if (pattern == 6) {
		float z = o.z + 0.5;
		c *= 1.0 - 0.1 * (1.0 - smoothstep(0.0, 0.08, min(z, 1.0 - z))) ; // (the creases between segments)
		c = mix(c, c * 1.18 + 0.05, smoothstep(0.35, -0.3, o.y) * 0.3); // (paler, more yellow, low down)
		// the line low along each side
		c = mix(c, line, smoothstep(0.012, 0.0, abs(o.y + 0.16) - 0.025) * step(0.8, side));
		// the warts: two pairs across its back, magenta
		float w = 0.0;
		for (int i = 0; i < 2; i++) {
			float x = i == 0 ? 0.12 : 0.3;
			w = max(w, 1.0 - smoothstep(0.035, 0.05, length(vec2(abs(o.x) - x, z - 0.42))));
		}
		c = mix(c, band_b, w * step(0.15, o.y));
		if (spiracles) // (small, pale, ringed brown, low on each side)
			c = mix(c, vec3(0.45, 0.3, 0.15), (1.0 - smoothstep(0.03, 0.045, length(vec2(z - 0.25, (o.y + 0.05) * 1.3)))) * step(0.85, side));
	} else if (pattern == 4) {
		// creased across: each segment folded into annulets
		c *= 1.0 - wrinkle * (0.5 + 0.5 * cos((o.z + 0.5) * 6.2832 * annulets));
		if (spiracles) // (a brown breathing hole low on each side)
			c = mix(c, vec3(0.42, 0.25, 0.1), 1.0 - smoothstep(0.045, 0.07, length(vec2(o.z + 0.1, (o.y + 0.08) * 1.4))) * step(0.85, side) * 1.0);
		SSS_STRENGTH = 0.3;
	} else {
		c = mix(c, line, smoothstep(0.88, 0.93, side) * (1.0 - smoothstep(0.96, 1.0, side)) * step(0.0, o.y));
	}
	ALBEDO = c;
	ROUGHNESS = mix(0.8, 0.25, gloss);
	SPECULAR = 0.4;
}
