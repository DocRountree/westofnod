shader_type spatial;

// A deer mouse's fur (Mouse): its back brown, grizzled (a juvenile's grey),
// darker along the spine; its belly white, the line between them sharp (the
// deer mice's); a newborn's all skin, pink, glossy, its fur coming in as it
// grows (fur 0..1). part 0: the body and head (the belly where the model's
// normal points down); part 1: the tail (dark above, white below, by the
// world's up, however it's bent).

uniform vec3 back : source_color = vec3(0.46, 0.33, 0.21);
uniform vec3 belly : source_color = vec3(0.92, 0.9, 0.86);
uniform vec3 skin : source_color = vec3(0.9, 0.6, 0.56);
uniform float fur = 1.0;
uniform int part = 0;
uniform float line_y = -0.28; // (the belly's edge: the normal's y there)

varying vec3 n_obj;
varying vec3 p_obj;

void vertex() {
	n_obj = NORMAL;
	p_obj = VERTEX;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	float ny = part == 1 ? (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y : normalize(n_obj).y;
	float under = 1.0 - smoothstep(line_y - 0.07, line_y + 0.07, ny);
	// (the hairs' tips: grizzled, finely)
	vec3 b = back * (0.86 + 0.24 * h21(floor(p_obj.xz * 2.5 + vec2(p_obj.y * 1.7))));
	if (part == 0)
		b *= mix(1.0, 0.78, smoothstep(0.6, 0.95, ny)); // (darker along the spine)
	vec3 c = mix(b, belly, under);
	c = mix(skin * (0.92 + 0.08 * ny), c, fur);
	ALBEDO = c;
	ROUGHNESS = mix(0.35, 0.92, fur);
	RIM = 0.55 * fur;
	RIM_TINT = 0.7;
}
