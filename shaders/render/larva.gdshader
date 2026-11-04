shader_type spatial;

// A larva's segment (Larva: each a squashed sphere, its own z from front
// -0.5 to back 0.5): its colour and pattern, painted from where on the
// segment a point is (object space).
// pattern 0: plain (base), a pale line along each side (line)
// pattern 1: a monarch caterpillar's bands: white, a broad black band, a
//   yellow band, black again, round each segment
// pattern 2: a hornworm's (the clearwing's): green, a pale yellow line
//   along each side, a pale stripe slanting across, a reddish spiracle
// pattern 3: a lady beetle larva's: blackish grey, rows of bumps, an orange
//   patch on its sides (spot: this segment's)
// pattern 4: a grub's: creamy, a little see-through (rim), creased across

uniform int pattern = 0;
uniform vec3 base : source_color = vec3(0.9, 0.88, 0.8);
uniform vec3 line : source_color = vec3(0.95, 0.9, 0.6);
uniform vec3 band_a : source_color = vec3(0.02);
uniform vec3 band_b : source_color = vec3(0.96, 0.82, 0.1);
uniform bool spot = false;
uniform float gloss = 0.4;

varying vec3 o;

void vertex() {
	o = VERTEX;
}

void fragment() {
	vec3 c = base;
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
		if (spot)
			c = mix(c, band_b, smoothstep(0.75, 0.85, side) * step(-0.1, o.y));
	} else if (pattern == 4) {
		c *= 0.9 + 0.1 * cos(o.z * 18.0); // (creased)
		SSS_STRENGTH = 0.3;
	} else {
		c = mix(c, line, smoothstep(0.88, 0.93, side) * (1.0 - smoothstep(0.96, 1.0, side)) * step(0.0, o.y));
	}
	ALBEDO = c;
	ROUGHNESS = mix(0.8, 0.25, gloss);
	SPECULAR = 0.4;
}
