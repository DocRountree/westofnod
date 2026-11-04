shader_type spatial;
render_mode cull_disabled, depth_draw_never, unshaded;

// Spider silk (Spider's webs and egg sacs): white, faint, glinting where the
// light catches it; drawn only as far as it's been spun: each vertex's
// order (UV.x) against `built` (sheets: their distance from where the
// spinning began, UV.x, against `built`; their threads a fine hatching,
// sheet true).

uniform float built = 1e9;
uniform bool sheet = false;
uniform float opacity = 0.75;
uniform vec3 tint : source_color = vec3(0.95, 0.95, 0.93);

varying float order;
varying vec3 w;

void vertex() {
	order = UV.x;
	w = VERTEX;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	if (order > built)
		discard;
	float a = opacity;
	if (sheet) {
		// a sheet: threads crossing every way, laid thick and thin
		vec2 p = w.xz * 900.0;
		float l1 = 1.0 - smoothstep(0.0, 0.12, abs(fract(p.x * 0.7 + p.y * 0.3 + h21(floor(p * 0.05)) * 3.0) - 0.5));
		float l2 = 1.0 - smoothstep(0.0, 0.12, abs(fract(p.x * -0.4 + p.y * 0.8) - 0.5));
		float l3 = 1.0 - smoothstep(0.0, 0.14, abs(fract(p.y * 0.9 + p.x * 0.1 + 0.3) - 0.5));
		a = opacity * clamp(0.12 + 0.55 * max(max(l1, l2), l3), 0.0, 1.0);
	}
	ALBEDO = tint;
	ALPHA = a;
}
