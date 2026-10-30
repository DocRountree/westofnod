shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// Open sea, after DocRountree/game's ocean water.gdshader. Six Gerstner waves
// displace a camera-centred grid (UV.x carries the grid spacing; waves too
// short for it fade out). They read the sea floor from the height map and
// shrink as the water shoals (waves feel the bottom in water shallower than
// about a third of their length), gone at the shore, so swell never climbs
// onto land. Per pixel: the analytic Gerstner normal plus small waves (the
// flowing ripples of water_ripples.gdshaderinc, drifting with the wind
// instead of game's FFT cascades); the light coming up through the water
// (water_core.gdshaderinc: refraction, depth absorption) plus the body's own
// light and the crests lit through; Godot adds the sky and the sun, whose
// highlight is capped (light()). Without a readable depth buffer (MSAA) the
// thickness of water comes from the sea floor and the view angle.

#include "res://shaders/render/height_map.gdshaderinc"
#include "res://shaders/render/aerial.gdshaderinc"

uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6);
uniform vec3 sun_color = vec3(1.0, 0.95, 0.86);
uniform float amplitude = 0.6;
uniform float wind_angle = 0.35;
uniform float steepness = 0.8;
uniform vec3 deep_color = vec3(0.004, 0.03, 0.06);
uniform vec3 scatter_color = vec3(0.0, 0.13, 0.14);
uniform vec3 absorption = vec3(0.45, 0.09, 0.06); // per metre: red goes first
uniform float refraction = 0.03;
uniform float noise_scale = 0.6;
uniform float flow_period = 2.0;
uniform float wind_speed = 1.2;
uniform float glint_cap = 0.8;
#include "res://shaders/render/water_core.gdshaderinc"
#include "res://shaders/render/water_ripples.gdshaderinc"

const int NW = 6;
// direction offset from the wind (rad), wavelength (m), amplitude / wavelength, phase
const vec4 WAVE[NW] = vec4[](
	vec4(0.0, 61.0, 0.022, 0.0),
	vec4(-0.75, 37.0, 0.020, 1.7),
	vec4(0.5, 23.0, 0.018, 4.1),
	vec4(-1.35, 14.0, 0.015, 2.3),
	vec4(-0.2, 8.5, 0.012, 5.6),
	vec4(1.6, 5.3, 0.010, 0.9)
);

varying vec2 x0;
varying float spacing;
varying float crest;
varying float sea_depth;
varying float spec_cap;

float lod(float lambda, float sp) {
	return clamp((lambda - 3.0 * sp) / (3.0 * sp), 0.0, 1.0);
}

float shoal(float lambda, float depth) {
	return smoothstep(0.0, 0.35 * lambda, depth);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	x0 = world.xz;
	spacing = UV.x;
	sea_depth = -height_m(x0, clamp(int(log2(max(spacing, 1.0) / map_cell())), 0, 8));
	vec3 disp = vec3(0.0);
	for (int i = 0; i < NW; i++) {
		float ang = wind_angle + WAVE[i].x;
		vec2 d = vec2(cos(ang), sin(ang));
		float k = TAU / WAVE[i].y;
		float a = WAVE[i].z * WAVE[i].y * amplitude * lod(WAVE[i].y, spacing) * shoal(WAVE[i].y, sea_depth);
		float th = k * dot(d, x0) - sqrt(9.81 * k) * TIME + WAVE[i].w;
		disp.xz += steepness * a * d * cos(th);
		disp.y += a * sin(th);
	}
	crest = disp.y;
	VERTEX += disp;
}

void fragment() {
	// analytic Gerstner normal (GPU Gems 1, ch. 1)
	vec2 slope = vec2(0.0);
	float nz = 1.0;
	for (int i = 0; i < NW; i++) {
		float ang = wind_angle + WAVE[i].x;
		vec2 d = vec2(cos(ang), sin(ang));
		float k = TAU / WAVE[i].y;
		float a = WAVE[i].z * WAVE[i].y * amplitude * lod(WAVE[i].y, spacing) * shoal(WAVE[i].y, sea_depth);
		float th = k * dot(d, x0) - sqrt(9.81 * k) * TIME + WAVE[i].w;
		slope += d * k * a * cos(th);
		nz -= steepness * k * a * sin(th);
	}
	slope /= max(nz, 0.2);
	// small waves drifting with the wind, settling in very shallow water
	vec2 wind = vec2(cos(wind_angle), sin(wind_angle)) * wind_speed;
	vec3 rip = flowing_normal(x0, wind);
	slope += vec2(-rip.x, -rip.z) / max(rip.y, 0.2) * 0.35 * smoothstep(0.0, 0.5, sea_depth);
	vec3 n_world = normalize(vec3(-slope.x, 1.0, -slope.y));
	vec3 to_eye = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;
	if (to_eye.y < 0.0)
		n_world = reflect(n_world, vec3(0.0, 1.0, 0.0));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	vec3 view_world = normalize(to_eye);
	float thickness;
	vec3 background;
	if (water_has_depth(SCREEN_UV)) {
		background = water_background(SCREEN_UV, slope, refraction, -VERTEX.z, INV_PROJECTION_MATRIX, thickness);
	} else {
		thickness = max(sea_depth, 0.0) / max(abs(view_world.y), 0.05);
		background = texture(screen_tex, SCREEN_UV + slope * refraction * clamp(thickness * 0.5, 0.0, 1.0)).rgb;
	}
	vec3 transmit = exp(-absorption * thickness);
	vec3 sun = normalize(sun_direction);
	float diffuse = max(dot(n_world, sun), 0.0);
	float toward_sun = max(dot(-view_world, sun), 0.0); // light shining through crests
	float crest_t = clamp(crest * 0.5 + 0.3, 0.0, 1.0);
	crest_t *= crest_t;
	vec3 body = deep_color * (0.5 + 0.8 * diffuse)
			+ scatter_color * crest_t * (0.35 + 1.5 * pow(toward_sun, 4.0)) * (0.5 + 0.5 * diffuse);
	body *= 0.12 + 0.88 * sun_color;
	vec3 refracted = background * transmit + body * (1.0 - transmit);

	float px = max(length(dFdx(x0)), length(dFdy(x0)));
	float fresnel = water_fresnel(NORMAL, VIEW);
	ALBEDO = vec3(0.0);
	ROUGHNESS = clamp(0.03 + px * 0.3, 0.03, 0.6);
	SPECULAR = 0.5;
	spec_cap = glint_cap / (1.0 + px * 1.5);
	EMISSION = refracted * (1.0 - fresnel);
	FOG = aerial_fog((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz, CAMERA_POSITION_WORLD);
	// the very edge of the water fades in over its first 30 cm
	ALPHA = smoothstep(0.0, 0.3, thickness * max(abs(view_world.y), 0.05));
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR / PI;
	vec3 h = normalize(VIEW + LIGHT);
	float ndh = clamp(dot(NORMAL, h), 0.0, 1.0);
	float ndv = clamp(dot(NORMAL, VIEW), 1e-3, 1.0);
	float a = max(ROUGHNESS * ROUGHNESS, 0.002);
	float a2 = a * a;
	float dd = ndh * ndh * (a2 - 1.0) + 1.0;
	float dist = a2 / (PI * dd * dd);
	float fr = 0.02 + 0.98 * pow(1.0 - clamp(dot(VIEW, h), 0.0, 1.0), 5.0);
	float k = a * 0.5;
	float vis = 0.25 / ((ndl * (1.0 - k) + k) * (ndv * (1.0 - k) + k));
	SPECULAR_LIGHT += min(dist * fr * vis * ndl, spec_cap) * ATTENUATION * LIGHT_COLOR / PI;
}
