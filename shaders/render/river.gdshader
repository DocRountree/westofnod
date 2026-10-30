shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

// River water on the ribbon meshes (RiverMeshes). Ported from DocRountree/game's
// river.gdshader, without its falls, islands, FFT slopes and wakes (this world
// has none of them): the optics of water_core.gdshaderinc (refraction,
// Beer-Lambert absorption, the body's own colour, Fresnel); the bed showing
// through, never more than bed_visibility of it; clear water high up, silty
// low down, turning into sea water as it comes down to the sea; a flowing
// fractal of value noise after P_Malin's "Adrift" (shadertoy.com/view/ldjfDD)
// for the small waves, carried downstream by the current in two phases half a
// period apart, crossfaded so the flow never visibly resets; the current
// fastest mid-channel; gloss falling away with distance and the sun's
// highlight capped (light()), so far water never turns into a glinting blob.
// Where the depth buffer can't be read (with MSAA it can't) the water's
// thickness comes from the channel's own depth and the viewing angle.
//
// Mesh: COLOR.rg downstream direction (x, z), b speed (0..1), a width / 60 m;
// UV.x 0..1 across the ribbon (which is OVERLAP x the channel), UV.y metres
// downstream.

#include "res://shaders/render/aerial.gdshaderinc"

uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6);
uniform vec3 sun_color = vec3(1.0, 0.95, 0.86);
uniform float max_speed = 2.0;        // m/s at COLOR.b = 1
uniform float overlap = 1.25;         // ribbon half width / channel half width (RiverMeshes.OVERLAP)
uniform float bed_visibility = 0.82;
uniform vec3 bed_tint = vec3(0.86, 0.96, 0.9);
uniform float refraction = 0.03;
uniform vec3 sea_deep_color = vec3(0.004, 0.03, 0.06);
uniform vec3 sea_scatter_color = vec3(0.0, 0.13, 0.14);
uniform vec3 sea_absorption = vec3(0.45, 0.09, 0.06);
uniform float noise_scale = 2.0;
uniform float flow_period = 1.0;
uniform float glint_cap = 0.6;
uniform vec3 absorb_clear = vec3(0.32, 0.075, 0.07);
uniform vec3 deep_clear = vec3(0.006, 0.04, 0.045);
uniform vec3 scatter_clear = vec3(0.02, 0.11, 0.1);
uniform vec3 absorb_silty = vec3(0.3, 0.32, 0.45);
uniform vec3 deep_silty = vec3(0.025, 0.045, 0.03);
uniform vec3 scatter_silty = vec3(0.07, 0.115, 0.065);
uniform vec2 clear_heights = vec2(40.0, 160.0);
#include "res://shaders/render/water_core.gdshaderinc"
#include "res://shaders/render/water_ripples.gdshaderinc"

varying float speed;
varying float depth;
varying float hw;
varying float across_v;
varying vec2 dir;
varying vec3 wpos;
varying float spec_cap;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	dir = normalize(COLOR.rg * 2.0 - 1.0 + vec2(1e-6));
	speed = COLOR.b * max_speed;
	float width = COLOR.a * 60.0;
	hw = width * 0.5;
	depth = 0.5 + 0.08 * width;
	across_v = (UV.x * 2.0 - 1.0) * overlap; // in channel half widths
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	float across = abs(across_v);
	float px = max(length(dFdx(wpos)), length(dFdy(wpos)));
	vec2 flow = dir * speed * (1.0 - 0.6 * min(across * across, 1.0)); // fastest mid-channel
	vec3 n_world = flowing_normal(wpos.xz, flow);
	vec3 to_eye = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;
	if (to_eye.y < 0.0)
		n_world = reflect(n_world, vec3(0.0, 1.0, 0.0)); // seen from below
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	vec3 view_world = normalize(to_eye);
	float thickness;
	vec3 background;
	if (water_has_depth(SCREEN_UV)) {
		background = water_background(SCREEN_UV, n_world.xz, refraction, -VERTEX.z, INV_PROJECTION_MATRIX, thickness);
	} else {
		thickness = depth * max(1.0 - across * across, 0.0) / max(abs(view_world.y), 0.1);
		background = texture(screen_tex, SCREEN_UV + n_world.xz * refraction * clamp(thickness * 0.5, 0.0, 1.0)).rgb;
	}
	background = min(background, vec3(4.0));
	float clear = smoothstep(clear_heights.x, clear_heights.y, wpos.y);
	vec3 absorb = mix(absorb_silty, absorb_clear, clear);
	vec3 deep_color = mix(deep_silty, deep_clear, clear);
	vec3 scatter_color = mix(scatter_silty, scatter_clear, clear);
	vec3 transmit = exp(-absorb * thickness) * bed_visibility;
	if (to_eye.y < 0.0)
		transmit = vec3(0.0);
	vec3 sun = normalize(sun_direction);
	float sun_dot_v = dot(sun, -view_world);
	float diffuse = max(dot(n_world, sun), 0.0);
	vec3 body = deep_color * (0.5 + 0.8 * diffuse) + scatter_color * 0.45 * (0.5 + 0.5 * diffuse) * (1.0 + 0.5 * sun_dot_v);
	float sea = 1.0 - smoothstep(0.5, 3.5, wpos.y);
	transmit = mix(transmit, exp(-sea_absorption * thickness), sea);
	body = mix(body, sea_deep_color * (0.5 + 0.8 * diffuse) + sea_scatter_color * 0.04 * (0.5 + 0.5 * diffuse), sea);
	body *= 0.12 + 0.88 * sun_color;
	vec3 refracted = background * transmit * mix(bed_tint, vec3(1.0), sea) + body * (1.0 - transmit);

	float fresnel = water_fresnel(NORMAL, VIEW);
	float gloss = 1.0 - clamp(0.07 + px * 0.3, 0.07, 0.6);
	ALBEDO = vec3(0.0);
	ROUGHNESS = clamp(1.0 - gloss, 0.02, 0.6);
	SPECULAR = 0.5;
	spec_cap = glint_cap / (1.0 + px * 1.5);
	EMISSION = refracted * (1.0 - fresnel);
	FOG = aerial_fog(wpos, CAMERA_POSITION_WORLD);
	// whole across the channel (the banks cut its edge), a soft fringe at the
	// ribbon's very edge, and the shore soft over its first 30 cm
	ALPHA = 1.0 - smoothstep(1.0, overlap, across);
	ALPHA *= smoothstep(0.0, 0.3, thickness * max(abs(view_world.y), 0.05));
}

// The sun on the water: a GGX highlight, capped (lower far off), so a calm
// reach turned to the sun shines rather than blooms.
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
