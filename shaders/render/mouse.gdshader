shader_type spatial;

// fur: shells (Hexapod._fur_shells), each a copy of the mesh a little further out
// along its normals (shell: 0 the skin .. 1 the hairs' tips), the hairs
// thinning to their tips, combed down and back (comb); fur_obj: the hairs'
// length, fur_dens: how many a unit, in the mesh's own units
instance uniform float shell = 0.0;
instance uniform float fur_obj = 0.0;
instance uniform float fur_dens = 1.0;
uniform vec3 comb = vec3(0.0, -0.35, 0.55);
uniform vec3 bare_a = vec3(0.0, -1e6, 0.0); // (bare round these: the eyes)
uniform vec3 bare_b = vec3(0.0, -1e6, 0.0);
uniform float bare_r = 0.0;

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
	if (shell > 0.0)
		VERTEX += (NORMAL + comb * shell) * fur_obj * shell;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float fh31(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

void fragment() {
	if (shell > 0.0 && shell > fur * 1.01) // (a newborn's bare: its fur coming in)
		discard;
	if (shell > 0.0 && (length(p_obj - bare_a) < bare_r || length(p_obj - bare_b) < bare_r)) // (no fur over its eyes)
		discard;
	if (shell > 0.0) { // (a hair here, or none: thinning to its tip)
		vec3 q = p_obj * fur_dens;
		vec3 f = fract(q) - 0.5;
		float hh = fh31(floor(q));
		if (length(f) > 0.5 * (1.0 - shell * 0.8) || hh < shell * 0.45)
			discard;
	}
	float ny = part == 1 ? (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y : normalize(n_obj).y;
	float under = 1.0 - smoothstep(line_y - 0.07, line_y + 0.07, ny);
	// (the hairs' tips: grizzled, finely)
	vec3 b = back * (0.86 + 0.24 * h21(floor(p_obj.xz * 2.5 + vec2(p_obj.y * 1.7))));
	if (part == 0)
		b *= mix(1.0, 0.78, smoothstep(0.6, 0.95, ny)); // (darker along the spine)
	vec3 c = mix(b, belly, under);
	c = mix(skin * (0.92 + 0.08 * ny), c, fur);
	if (part == 1) // (the tail's rings of fine scales)
		c *= 0.88 + 0.12 * smoothstep(0.35, 0.5, abs(fract(p_obj.y * 9.0) - 0.5));
	c *= mix(0.72, 1.1, shell) * (shell > 0.0 ? 1.0 : 0.85); // (the fur's depth: darker at its roots, lighter at its tips)
	ALBEDO = c;
	ROUGHNESS = mix(0.35, 0.92, fur);
	RIM = 0.55 * fur;
	RIM_TINT = 0.7;
}
