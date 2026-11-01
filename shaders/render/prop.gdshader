shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Plain mesh props (trees, rocks): vertex colours for albedo, alpha marks
// foliage (lit through from behind), and the land's aerial perspective so
// they fade into the distance with it.

#include "res://shaders/render/aerial.gdshaderinc"

varying vec3 world_pos;
varying float foliage;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	foliage = COLOR.a;
}

void fragment() {
	ALBEDO = pow(COLOR.rgb, vec3(2.2)); // (vertex colours are sRGB)
	ROUGHNESS = mix(0.95, 0.8, foliage);
	SPECULAR = 0.3;
	BACKLIGHT = ALBEDO * 0.5 * foliage;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}
