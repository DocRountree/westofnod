shader_type spatial;
render_mode cull_disabled, depth_draw_never;

// A wasp's wing (Wasp): a thin membrane, smoky amber, with its veins and the
// dark stigma near the leading edge's middle. UV.x along the wing from its
// hinge (0) to its tip (1), UV.y across from the leading edge (0) to the
// trailing (1).
//
// blur: instead the stroke's blur while the wings beat (far too fast to
// see, ~150 a second): a fan round the hinge, UV.x out from it, UV.y round
// the stroke from front to back, the wing seen most where it turns at
// either end.

#include "res://shaders/render/wind.gdshaderinc"

// swaying with a flower's head (Wasp.feed_on_flower): as
// ground_cover.gdshader sways the head at sway_at (the map's, still), by
// sway_k (its grass_sway * the clump's size * its height's share, squared)
uniform vec3 sway_at;
uniform float sway_k = 0.0;

uniform bool blur = false;
uniform float opacity = 1.0;
uniform vec3 membrane : source_color = vec3(0.5, 0.36, 0.2);
uniform vec3 vein : source_color = vec3(0.22, 0.13, 0.06);

void vertex() {
	if (sway_k > 0.0)
		VERTEX += inverse(mat3(MODEL_MATRIX)) * wind_sway(sway_at, TIME) / max(sway, 1e-3) * sway_k;
}

void fragment() {
	vec2 uv = UV;
	float a;
	vec3 c;
	if (blur) {
		float ends = pow(abs(uv.y * 2.0 - 1.0), 4.0);
		a = mix(0.06, 0.2, ends) * smoothstep(1.0, 0.82, uv.x) * smoothstep(0.04, 0.2, uv.x);
		c = mix(membrane, vein, 0.3);
	} else {
		float x = uv.x, y = uv.y;
		// the outline: narrow at the hinge, broadest past the middle, the tip round
		float w = 0.42 * mix(0.45, 1.0, smoothstep(0.0, 0.5, x));
		float cy = 0.08 + w;
		float e = pow((x - 0.52) / 0.5, 2.0) + pow((y - cy) / w, 2.0);
		if (e > 1.0)
			discard;
		a = 0.3;
		c = membrane;
		float v = 0.0;
		// the costa, along the leading edge, and the stigma on it
		float lead = cy - w * sqrt(max(1.0 - pow((x - 0.52) / 0.5, 2.0), 0.0));
		v = max(v, 1.0 - smoothstep(0.03, 0.06, y - lead) * step(x, 0.72));
		v = max(v, step(0.56, x) * step(x, 0.68) * step(y - lead, 0.11));
		// veins along it, fading out toward the tip, and a few across
		float along = abs(fract((y - 0.12 * x) * 4.5 + 0.35) - 0.5);
		v = max(v, (1.0 - smoothstep(0.02, 0.05, along)) * (1.0 - smoothstep(0.55, 0.75, x)));
		v = max(v, (1.0 - smoothstep(0.006, 0.014, abs(x - 0.34))) * step(y, cy + w * 0.6));
		v = max(v, (1.0 - smoothstep(0.006, 0.014, abs(x - 0.5 - 0.1 * y))) * step(y, cy + w * 0.3));
		// the edge itself a little darker
		v = max(v, 0.5 * smoothstep(0.85, 1.0, e));
		c = mix(c, vein, v);
		a = mix(a, 0.9, v);
	}
	ALBEDO = c;
	ALPHA = a * opacity;
	ROUGHNESS = 0.2;
	SPECULAR = 0.6;
}
