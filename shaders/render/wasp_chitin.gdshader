shader_type spatial;

// A wasp's hard parts (Wasp): glossy chitin, a part's own colour, and on the
// gaster's segments the yellow band at each one's hind edge, wider at the
// sides (the part a unit sphere, scaled: its own z from -0.5 at its front to
// 0.5 behind).

#include "res://shaders/render/wind.gdshaderinc"

// swaying with a flower's head (Wasp.feed_on_flower): as
// ground_cover.gdshader sways the head at sway_at (the map's, still), by
// sway_k (its grass_sway * the clump's size * its height's share, squared)
uniform vec3 sway_at;
uniform float sway_k = 0.0;

uniform vec3 base_color : source_color = vec3(0.28, 0.13, 0.07);
uniform vec3 band_color : source_color = vec3(0.93, 0.75, 0.2);
uniform float band = 0.0; // the share of the part's length, behind, in band_color (0: none)
uniform float gloss = 0.65; // 0 matt .. 1 polished (the eyes)

varying vec3 lp;

void vertex() {
	lp = VERTEX;
	if (sway_k > 0.0)
		VERTEX += inverse(mat3(MODEL_MATRIX)) * wind_sway(sway_at + world_origin, TIME) / max(sway, 1e-3) * sway_k;
}

void fragment() {
	vec3 c = base_color;
	if (band > 0.0) {
		// wider at the sides than on the back, a little wavy
		float edge = 0.5 - band - 0.12 * smoothstep(0.15, 0.5, abs(lp.x)) + 0.015 * sin(lp.x * 40.0);
		c = mix(c, band_color, smoothstep(edge - 0.01, edge + 0.01, lp.z));
	}
	ALBEDO = c;
	ROUGHNESS = mix(0.7, 0.18, gloss);
	SPECULAR = mix(0.4, 0.7, gloss);
}
