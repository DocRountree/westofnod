shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// The figure's hair (CharacterParts: its head's, its beard's, its brows'):
// sheets of it, the strands running along UV.y, streaked lighter and darker
// strand by strand; curl (0 straight .. 3 coily): the streaks broken into
// waves, then into tufts.

#include "res://shaders/render/aerial.gdshaderinc"

uniform vec3 color : source_color = vec3(0.1, 0.07, 0.05);
uniform float curl = 0.0;
uniform float strands = 90.0; // across the sheet
global uniform float night;

varying vec3 world_pos;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise2(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float wave = sin(UV.y * (10.0 + 14.0 * curl)) * 0.012 * curl;
	float fine = vnoise2(vec2((UV.x + wave) * strands, UV.y * 2.5));
	float lock = vnoise2(vec2((UV.x + wave) * strands * 0.18, UV.y * 1.2 + 7.0));
	float tuft = vnoise2(UV * vec2(strands * 0.45, 26.0)); // (coily: no strands to follow, a nap)
	float k = mix(fine * 0.6 + lock * 0.4, tuft, smoothstep(1.5, 3.0, curl));
	float px = length(fwidth(UV * vec2(strands, 3.0)));
	k = mix(k, 0.5, smoothstep(0.6, 2.0, px)); // (far off: its mean)
	vec3 col = color * (0.62 + 0.76 * k);
	if (!FRONT_FACING) {
		col *= 0.6;
		NORMAL = -NORMAL;
	}
	ALBEDO = col * (1.0 - 0.35 * night);
	ROUGHNESS = mix(0.6, 0.85, smoothstep(0.0, 3.0, curl));
	SPECULAR = 0.2;
	FOG = aerial_fog(world_pos, CAMERA_POSITION_WORLD);
}
