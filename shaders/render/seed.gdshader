shader_type spatial;

// A seed, a husk, a bite of fruit in a finch's bill (Finch): plain, a little
// glossy; swaying with the plant's head it was picked from as the bird
// clinging there does (bird.gdshader's ride: the plant's own wind).

#include "res://shaders/render/origin.gdshaderinc"

uniform vec3 albedo : source_color = vec3(0.2, 0.17, 0.12);
uniform float rough = 0.5;
uniform vec3 ride_at = vec3(0.0);
uniform float ride_k = 0.0;

void vertex() {
	if (ride_k > 0.0) {
		vec3 w = ride_at + world_origin;
		float ph = dot(w.xz, vec2(0.13, 0.09)) + w.y * 0.05;
		float gust = 0.55 + 0.45 * sin(TIME * 0.31 + dot(w.xz, vec2(0.011, 0.007)));
		vec3 sw = vec3(sin(TIME * 1.3 + ph), 0.25 * sin(TIME * 1.7 + ph * 1.9), cos(TIME * 1.05 + ph * 1.3)) * gust * ride_k;
		VERTEX += inverse(mat3(MODEL_MATRIX)) * sw;
	}
}

void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = rough;
	SPECULAR = 0.4;
}
