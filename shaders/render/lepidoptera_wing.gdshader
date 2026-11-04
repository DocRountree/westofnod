shader_type spatial;
render_mode cull_disabled;

// A butterfly's or a moth's wing (Lepidoptera): its outline and pattern
// painted here, on a plain quad. UV.x along the wing from its hinge (0) to
// its tip (1), UV.y across from its leading edge (0) to its trailing (1).
// The upper side is the front face, the underside the back.
//
// pattern 0: a monarch (Danaus plexippus): orange cells between black
// veins, a black border with two rows of white dots, the forewing's tip
// black with orange and white spots; beneath paler, the hindwing yellowish
// with bolder veins.
// pattern 1: a hummingbird moth (Hemaris thysbe): clear, glassy cells, the
// veins and a broad border reddish brown, the base olive and scaly.
//
// blur: the stroke of wings beating too fast to see (Lepidoptera: the
// hummingbird moth's, ~40 a second): a fan round the hinge, UV.x out from
// it, UV.y round the stroke; faint, a little more at its two ends.

uniform int pattern = 0;
uniform bool hind = false;
uniform bool blur = false;
uniform float opacity = 1.0;

const vec3 ORANGE = vec3(0.92, 0.42, 0.04);
const vec3 BLACK = vec3(0.025, 0.02, 0.02);
const vec3 WHITE = vec3(0.92, 0.9, 0.85);
const vec3 BROWN = vec3(0.36, 0.13, 0.08);
const vec3 OLIVE = vec3(0.42, 0.42, 0.18);

// how far across the wing reaches at u (0..1 of its length), its outline
float breadth(float u) {
	if (hind)
		return 0.95 * sqrt(max(1.0 - pow(u, 2.2), 0.0)) * mix(0.55, 1.0, smoothstep(0.0, 0.35, u));
	if (pattern == 1) // (the moth's forewing narrow, pointed)
		return mix(0.42, 0.9, smoothstep(0.0, 0.55, u)) * (1.0 - smoothstep(0.82, 1.0, u) * 0.75);
	return mix(0.38, 0.95, smoothstep(0.0, 0.6, u)) * (1.0 - smoothstep(0.86, 1.0, u) * 0.55);
}

// white dots in a row along the border: s along it, d into it (0 at the edge)
float dots(float s, float d, float n, float at, float r) {
	float c = abs(fract(s * n) - 0.5) / n; // across a dot, along the row (in s)
	return 1.0 - smoothstep(r * 0.7, r, length(vec2(c * 2.2, d - at)));
}

void fragment() {
	float u = UV.x, v = UV.y;
	vec3 c;
	float a = 1.0;
	if (blur) {
		float ends = pow(abs(v * 2.0 - 1.0), 4.0);
		a = mix(0.08, 0.22, ends) * smoothstep(1.0, 0.85, u) * smoothstep(0.05, 0.2, u);
		c = pattern == 1 ? mix(BROWN, OLIVE, 0.4) : ORANGE;
	} else {
		float b = breadth(u);
		if (v > b || u > 1.0)
			discard;
		float across = v / max(b, 1e-3); // 0 leading edge .. 1 trailing
		// how far in from the outline (the trailing edge and the tip), 0 at it
		float edge = min(b - v, (1.0 - u) * 0.8);
		// veins fanning out from the hinge, and a cross vein closing the cell
		float fan = abs(fract(across * (hind ? 6.0 : 5.0) + 0.5) - 0.5);
		float cell = abs(u - (hind ? 0.42 : 0.48)) * step(0.2, across) * step(across, 0.85);
		if (pattern == 0) {
			bool under = !FRONT_FACING;
			vec3 base = under ? (hind ? vec3(0.9, 0.62, 0.2) : vec3(0.93, 0.5, 0.1)) : ORANGE;
			float vw = under && hind ? 0.07 : 0.045; // (beneath the hindwing's veins bolder)
			float vein = (1.0 - smoothstep(vw, vw + 0.02, fan)) * smoothstep(0.08, 0.2, u);
			vein = max(vein, 1.0 - smoothstep(0.008, 0.016, cell));
			vein = max(vein, 1.0 - smoothstep(0.04, 0.07, v)); // (the leading edge)
			c = mix(base, BLACK, vein);
			// the black border, its two rows of white dots
			float border = 1.0 - smoothstep(0.1, 0.13, edge);
			c = mix(c, BLACK, border);
			float s = hind ? atan(v, u) : u + across * 0.3;
			float w = max(dots(s, edge, 9.0, 0.035, 0.014), dots(s + 0.05, edge, 9.0, 0.08, 0.012)) * border;
			c = mix(c, WHITE, w);
			if (!hind) {
				// the forewing's tip black, with a few orange and white spots
				float apex = smoothstep(0.66, 0.74, u) * (1.0 - smoothstep(0.55, 0.7, across));
				c = mix(c, BLACK, apex);
				vec2 p = vec2(u, across);
				float spot = 0.0;
				spot = max(spot, 1.0 - smoothstep(0.018, 0.026, distance(p, vec2(0.8, 0.22))));
				spot = max(spot, 1.0 - smoothstep(0.015, 0.022, distance(p, vec2(0.86, 0.36))));
				spot = max(spot, 1.0 - smoothstep(0.013, 0.02, distance(p, vec2(0.76, 0.42))));
				float wspot = 1.0 - smoothstep(0.012, 0.018, distance(p, vec2(0.9, 0.15)));
				c = mix(c, vec3(0.95, 0.55, 0.12), spot * apex);
				c = mix(c, WHITE, wspot * apex);
			}
			c *= 0.95 + 0.05 * sin(u * 120.0) * sin(v * 90.0); // (the scales' sheen, faintly)
			ROUGHNESS = 0.7;
			SPECULAR = 0.25;
		} else {
			// clear cells, the veins and a broad border reddish brown, the base olive
			float vein = (1.0 - smoothstep(0.02, 0.04, fan)) * smoothstep(0.1, 0.25, u);
			vein = max(vein, 1.0 - smoothstep(0.006, 0.012, cell));
			vein = max(vein, 1.0 - smoothstep(0.03, 0.05, v));
			float border = 1.0 - smoothstep(0.08, 0.11, edge) ;
			float scaly = 1.0 - smoothstep(0.12, 0.22, u);
			float solid = clamp(max(max(vein, border), scaly), 0.0, 1.0);
			c = mix(vec3(0.75, 0.72, 0.6), mix(BROWN, OLIVE, scaly), solid);
			a = mix(0.12, 1.0, solid);
			ROUGHNESS = mix(0.15, 0.6, solid); // (the clear cells glassy)
			SPECULAR = mix(0.7, 0.3, solid);
		}
	}
	ALBEDO = c;
	ALPHA = a * opacity;
}
