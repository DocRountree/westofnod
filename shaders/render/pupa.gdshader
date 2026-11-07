shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled;

// A lepidopteran's pupa (Pupa): its shell one smooth loft, painted here
// from where on it a point is: along (UV.x: 0 its top (the monarch's: the
// stalk's end) or head (the clearwing's) .. 1 its other end), round
// (UV.y: 0..1, 0 and 1 its back, 0.5 its front).
// kind 0, the monarch's chrysalis: jade, glossy; a black band round its
//   front two thirds where the abdomen meets the wing cases, gold dots
//   along its lower edge and above it, gold spots on the wing cases and
//   near the top; the wing cases' outline a paler green.
// kind 1, the clearwing's: mahogany, glossy, the abdomen's segments
//   ringed, the wing cases' outline, the tongue's sheath down the front,
//   a row of spiracles along each side.
// ripe 0..1: going dark and clear, the wings inside showing through (the
// monarch's orange and black). empty: split, left behind: pale, see-
// through, a slit open where it came out.
// dead 0..1 (the monarch's, parasitized: a trigonalid wasp in it, not a
// butterfly): going dull, brown to black, its gold gone dim, no wings
// showing; holed: the little round hole the wasp chewed out of it, on its
// front (left hanging so, dead, dark, whole but for that).

uniform int kind = 0;
uniform float ripe = 0.0;
uniform bool empty = false;
uniform float dead = 0.0;
uniform bool holed = false;

float dot_at(vec2 p, vec2 c, float r) {
	return 1.0 - smoothstep(r * 0.7, r, length(p - c));
}

void fragment() {
	float v = UV.x; // along
	float u = UV.y; // round: 0.5 the front
	float fr = 1.0 - abs(u - 0.5) * 2.0; // 1 the front's middle .. 0 the back
	vec3 c;
	float metal = 0.0;
	float rough = 0.18;
	float a = 1.0;
	if (kind == 0) {
		c = mix(vec3(0.38, 0.66, 0.42), vec3(0.47, 0.73, 0.5), smoothstep(0.4, 0.9, v));
		// the wing cases' outline, paler, on the front below the band
		float pad = smoothstep(0.42, 0.45, v) * (1.0 - smoothstep(0.93, 0.96, v)) * smoothstep(0.25, 0.3, fr);
		float edge = pad * (1.0 - smoothstep(0.0, 0.03, abs(fr - 0.32 - (v - 0.45) * 0.3)));
		c = mix(c, vec3(0.62, 0.82, 0.6), edge * 0.7);
		// the crown: a black band, gold along its lower edge and above
		float band = smoothstep(0.345, 0.355, v) * (1.0 - smoothstep(0.372, 0.382, v)) * smoothstep(0.1, 0.2, fr);
		c = mix(c, vec3(0.02), band);
		float gold = 0.0;
		vec2 p = vec2(u * 9.0, v * 26.0); // (about mm round and along)
		for (int k = 0; k < 9; k++) {
			float cu = (float(k) + 0.5) / 9.0;
			if (abs(cu - 0.5) < 0.38) {
				gold = max(gold, dot_at(p, vec2(cu * 9.0, 0.392 * 26.0), 0.32));
				if (k % 2 == 0)
					gold = max(gold, dot_at(p, vec2(cu * 9.0, 0.318 * 26.0), 0.28));
			}
		}
		gold = max(gold, dot_at(p, vec2(0.38 * 9.0, 0.78 * 26.0), 0.4));
		gold = max(gold, dot_at(p, vec2(0.62 * 9.0, 0.78 * 26.0), 0.4));
		gold = max(gold, dot_at(p, vec2(0.32 * 9.0, 0.6 * 26.0), 0.3));
		gold = max(gold, dot_at(p, vec2(0.68 * 9.0, 0.6 * 26.0), 0.3));
		gold = max(gold, dot_at(p, vec2(0.45 * 9.0, 0.12 * 26.0), 0.3));
		gold = max(gold, dot_at(p, vec2(0.55 * 9.0, 0.12 * 26.0), 0.3));
		c = mix(c, vec3(0.95, 0.75, 0.28), gold);
		metal = gold;
		// ripe: dark and clear, the wings showing through on the front
		vec3 dark = vec3(0.05, 0.04, 0.04);
		float wings = pad;
		float vein = smoothstep(0.86, 0.95, abs(sin((fr * 7.0 + v * 4.0) * 3.1416)));
		float rim = smoothstep(0.86, 0.9, v); // (the wings' black border, at their tips)
		vec3 wing = mix(vec3(0.85, 0.36, 0.05), dark, max(vein, rim));
		vec3 ripe_c = mix(dark, wing, wings);
		c = mix(c, ripe_c, smoothstep(0.0, 1.0, ripe) * (1.0 - gold * 0.6));
		// dead: dulled through brown to near black, the gold gone dim
		vec3 dead_c = mix(vec3(0.24, 0.16, 0.07), vec3(0.06, 0.045, 0.03), smoothstep(0.3, 1.0, dead));
		c = mix(c, dead_c * (1.0 + gold * 0.6), smoothstep(0.0, 1.0, dead));
		metal *= 1.0 - 0.7 * dead;
		if (holed && fr > 0.9 && length(vec2((1.0 - fr) * 4.0, (v - 0.42) * 26.0)) < 0.7)
			discard; // (the wasp's way out)
	} else {
		c = vec3(0.27, 0.14, 0.07);
		// the abdomen's rings (the back half of it), darker in the joints
		float ring = smoothstep(0.55, 0.6, v) * (1.0 - smoothstep(0.08, 0.14, abs(fract(v * 14.0) - 0.5)));
		c *= 1.0 - 0.35 * ring;
		// the wing cases' outline, down each side of the front
		float wcase = (1.0 - smoothstep(0.0, 0.025, abs(fr - 0.45 - v * 0.3))) * step(v, 0.55);
		c = mix(c, vec3(0.15, 0.07, 0.03), wcase);
		// the tongue's sheath, down the front's middle
		float sheath = (1.0 - smoothstep(0.0, 0.06, 1.0 - fr)) * step(v, 0.5);
		c = mix(c, vec3(0.2, 0.1, 0.05), sheath * 0.7);
		// the spiracles, a row along each side
		float sp = 0.0;
		for (int k = 0; k < 6; k++) {
			float vk = 0.52 + float(k) * 0.065;
			sp = max(sp, 1.0 - smoothstep(0.006, 0.012, length(vec2((abs(u - 0.5) - 0.26) * 0.6, v - vk))));
		}
		c = mix(c, vec3(0.06, 0.03, 0.02), sp);
		// ripe: darker, the moth's olive and burgundy faintly through
		c = mix(c, mix(vec3(0.08, 0.06, 0.03), vec3(0.18, 0.17, 0.07), step(v, 0.45)), ripe);
	}
	if (empty) {
		// left behind: pale, see-through; open along the front where it came out
		c = mix(vec3(0.86, 0.85, 0.78), vec3(0.62, 0.52, 0.4), float(kind));
		a = 0.45;
		rough = 0.35;
		metal = 0.0;
		bool slit = kind == 0 ? (v > 0.5 && fr > 0.82) : (v < 0.3 && fr > 0.6);
		if (slit)
			discard;
	}
	ALBEDO = c;
	METALLIC = metal;
	ROUGHNESS = mix(rough, 0.25, metal);
	SPECULAR = 0.6;
	ALPHA = a;
}
