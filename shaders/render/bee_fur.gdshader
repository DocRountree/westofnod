shader_type spatial;

// A bumble bee's pile (Bumblebee): its body's parts each drawn again in
// shells, a little further out each (shell 0 the skin under the hair, solid;
// 1 the hairs' tips), each shell keeping only the hairs that reach it: the
// body a round blur of dense, soft, short hair, darker at its roots, paler
// at its tips, catching the light at its edges. The part a unit sphere (or
// a Wasp's tergite), scaled: the hairs' cells laid round its middle.

#include "res://shaders/render/wind.gdshaderinc"

// swaying with a flower's head, as the wasp's chitin (wasp_chitin.gdshader)
uniform vec3 sway_at;
uniform float sway_k = 0.0;

uniform vec3 fur_color : source_color = vec3(0.9, 0.75, 0.2);
uniform float shell = 0.0; // 0 the skin .. 1 the tips
uniform float fur_len = 0.14; // (the part's own units: a unit sphere's)
uniform float density = 60.0; // hairs round its middle

varying vec3 lp;

void vertex() {
	lp = VERTEX;
	VERTEX += NORMAL * shell * fur_len;
	if (sway_k > 0.0)
		VERTEX += inverse(mat3(MODEL_MATRIX)) * wind_sway(sway_at + world_origin, TIME) / max(sway, 1e-3) * sway_k;
}

float hh(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 d = normalize(lp + vec3(1e-5));
	// (the cells: round it by its angle, along it by its height; each a hair)
	vec2 uv = vec2(atan(d.z, d.x) / 6.2832 * density * 2.0, acos(clamp(d.y, -1.0, 1.0)) / 3.1416 * density);
	vec2 c = floor(uv);
	vec2 f = fract(uv) - 0.5;
	float r = hh(c);
	if (shell > 0.0) {
		// (a hair reaches this shell if it's long enough; thinning to its tip,
		// and leaning a little, as hair lies)
		vec2 off = vec2(hh(c + 3.7), hh(c + 9.1)) - 0.5;
		float thick = 0.5 * (1.0 - shell * 0.6);
		if (r < shell * 0.7 || length(f - off * 0.4 * shell) > thick)
			discard;
	}
	vec3 col = fur_color * mix(0.72, 1.1, shell) * (0.85 + 0.3 * r);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.08;
	RIM = 0.5;
	RIM_TINT = 0.6;
	BACKLIGHT = fur_color * 0.15;
}
