shader_type spatial;
render_mode cull_disabled;

// The creature demos' flowers (DemoFlowers): the game's flower clumps
// (GroundCover.flower_mesh), but placed, sized and coloured once on the CPU
// (no grid, no data texture): their colours in COLOR (sRGB), how far up its
// stem a vertex is in UV2.x. sway_k: the wind's sway at the top, as the
// ground cover's (grass_sway * the clump's size * how far up, squared); 0
// still.

#include "res://shaders/render/wind.gdshaderinc"

uniform float sway_k = 0.0;

void vertex() {
	if (sway_k > 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + world_origin;
		VERTEX += wind_sway(w, TIME) / max(sway, 1e-3) * sway_k * UV2.x * UV2.x;
	}
}

void fragment() {
	if (!FRONT_FACING)
		NORMAL = -NORMAL; // (both faces lit alike)
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	ALBEDO = COLOR.rgb; // (its vertex colours already made linear there)
#else
	ALBEDO = pow(COLOR.rgb, vec3(2.2));
#endif
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}

// (lit as the ground cover is: wrapped, a little light through from behind)
void light() {
	float ndl = dot(NORMAL, LIGHT);
	DIFFUSE_LIGHT += (clamp(ndl * 0.7 + 0.3, 0.0, 1.0) + max(-ndl, 0.0) * 0.3) * ATTENUATION * LIGHT_COLOR / PI;
}
