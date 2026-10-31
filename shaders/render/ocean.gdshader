shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// The open sea, built on physical optics.
//
// Shape: a wind sea of NW Gerstner waves whose wavelengths step down
// geometrically from LMAX, with amplitudes following a Pierson-Moskowitz
// spectrum (equal steepness per band, rolled off above the peak) and
// directions spreading wider the shorter the wave, plus one long swell from
// its own direction. Waves feel the bottom in water shallower than about a
// third of their wavelength: they steepen, slow and die at the shore.
//
// Filtering: the vertices carry the waves the grid can hold (UV.x is the
// local spacing); the pixels carry the waves the pixel can resolve. Slope
// that is too fine to draw is not thrown away but becomes roughness (the
// slope variance of a GGX surface), so the far sea turns into a broad
// glittering sun path instead of aliasing or going mirror-flat.
//
// Long crests are bent by a drifting noise warp; detail under 8 m is not
// sines at all but animated 3D noise (chop()), so nothing lines up into a grid.
//
// Light: reflection (sky and sun) is Godot's GGX with water's F0 = 0.02;
// what comes up through the surface is the refracted scene, dimmed by
// Beer-Lambert absorption along the light's path down to the floor and back
// up to the eye, filled in with light scattered by the water itself, and
// light shining through the thin crests toward the sun. Foam sits where
// the surface folds over (the Gerstner Jacobian) and in the shore surf.

#include "res://shaders/render/height_map.gdshaderinc"
#include "res://shaders/render/aerial.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6);
uniform vec3 sun_color = vec3(1.0, 0.95, 0.86);
uniform float wind_angle = 0.35;
uniform float sea_state = 1.0;    // scales the wind sea
uniform float peak_length = 55.0; // m, wavelength of the spectral peak
uniform float swell_height = 0.7; // m, amplitude of the swell
uniform float swell_length = 160.0;
uniform float swell_angle = -0.6;
uniform float choppiness = 0.85;
// Clear tropical water: absorption per metre (red goes within metres, blue
// lasts tens of metres), and the colour it scatters back.
uniform vec3 absorption = vec3(0.42, 0.075, 0.035);
uniform vec3 scatter_color = vec3(0.006, 0.04, 0.11);
uniform vec3 crest_color = vec3(0.05, 0.32, 0.30);
uniform float refraction = 0.04;
// The world wraps (main.gd): crossing the map's east/west seam or a pole
// moves the player, and these move the sea's coordinates with them, so the
// waves carry on unbroken. Sea coordinates = sea_sign * world xz + sea_offset.
uniform vec2 sea_sign = vec2(1.0);
uniform vec2 sea_offset = vec2(0.0);

const int NW = 18;
const float LMAX = 140.0;   // longest wind wave (m)
const float RATIO = 0.85;   // each next wave this much shorter, down to ~8 m (finer: chop())
const int NCHOP = 6;        // octaves of chop, 8 m down to 0.25 m
const float STEEP = 0.034;  // k*a per band at the peak

varying vec2 x0; // the sea's own coordinates (sea_sign, sea_offset)
varying float spacing;
varying float sea_depth;
varying float height;

float hash1(float n) {
	return fract(sin(n * 12.9898 + 4.1414) * 43758.5453);
}

// Value noise, for the foam's texture and for bending the crests.
float vnoise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash1(dot(i, vec2(1.0, 157.0)));
	float b = hash1(dot(i + vec2(1.0, 0.0), vec2(1.0, 157.0)));
	float c = hash1(dot(i + vec2(0.0, 1.0), vec2(1.0, 157.0)));
	float e = hash1(dot(i + vec2(1.0, 1.0), vec2(1.0, 157.0)));
	return mix(mix(a, b, f.x), mix(c, e, f.x), f.y);
}

// A slowly drifting warp of the sea's coordinates. Bent by it, the crests
// of short waves curve and break up instead of running ruler-straight in a
// few directions (a grid); long waves, bent by a fraction of a wavelength,
// barely notice.
vec2 warp(vec2 p) {
	vec2 q = p * 0.045 + vec2(TIME * 0.03, -TIME * 0.02);
	vec2 w = vec2(vnoise2(q), vnoise2(q + vec2(31.7, 17.3))) - 0.5;
	q = p * 0.17 - vec2(TIME * 0.05, TIME * 0.04);
	w += 0.5 * (vec2(vnoise2(q + vec2(5.2, 71.9)), vnoise2(q + vec2(43.1, 3.7))) - 0.5);
	return w;
}


float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

// 3D value noise with its x/y derivatives: (value, d/dx, d/dy).
vec3 noised3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	vec3 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);
	float a = hash3(i), b = hash3(i + vec3(1, 0, 0)), c = hash3(i + vec3(0, 1, 0)), d = hash3(i + vec3(1, 1, 0));
	float e = hash3(i + vec3(0, 0, 1)), g = hash3(i + vec3(1, 0, 1)), h = hash3(i + vec3(0, 1, 1)), j = hash3(i + vec3(1, 1, 1));
	float k1 = b - a, k2 = c - a, k4 = a - b - c + d, k3 = e - a;
	float k5 = a - c - e + h, k6 = a - b - e + g, k7 = -a + b + c - d + e - g - h + j;
	float v = a + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z;
	vec2 dv = du.xy * vec2(k1 + k4 * u.y + k6 * u.z + k7 * u.y * u.z, k2 + k4 * u.x + k5 * u.z + k7 * u.x * u.z);
	return vec3(v, dv);
}

// The fine chop, as slope: random, evolving bumps, not sines (any sine
// repeats unchanged across the whole sea and reads as a grid of lines).
// Each octave drifts downwind at its waves' speed and boils in place at
// their frequency (noise in x, z and time). Octaves too fine for the pixel
// hand their slope variance to `lost`, to become roughness.
vec2 chop(vec2 x, float px, float depth, inout float lost) {
	vec2 slope = vec2(0.0);
	vec2 wd = vec2(cos(wind_angle), sin(wind_angle));
	float calm = smoothstep(0.0, 0.6, depth);
	float lambda = 8.0;
	for (int o = 0; o < NCHOP; o++) {
		float k = TAU / lambda;
		float s = 1.2 * sea_state * STEEP * calm; // rms slope of this octave
		float f = smoothstep(3.0 * px, 6.0 * px, lambda);
		lost += s * s * (1.0 - f * f);
		if (f > 0.0) {
			float ang = float(o) * 1.7;
			mat2 r = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang)));
			float cell = lambda * 0.5;
			vec2 q = r * (x - wd * sqrt(9.81 / k) * 0.6 * TIME) / cell;
			vec3 n = noised3(vec3(q, TIME * sqrt(9.81 * k) / TAU * 0.8 + float(o) * 7.3));
			slope += (transpose(r) * n.yz) / cell * (s * cell * 0.9) * f;
		}
		lambda *= 0.5;
	}
	return slope;
}

// Wave i: xy direction, z wavelength, w amplitude (before shoaling).
vec4 wave(int i) {
	float fi = float(i);
	float lambda = LMAX * pow(RATIO, fi);
	float spread = mix(2.8, 0.35, clamp(lambda / peak_length, 0.0, 1.0)); // short waves wander
	float ang = wind_angle + (hash1(fi) * 2.0 - 1.0) * spread;
	float pm = exp(-0.625 * pow(lambda / peak_length, 2.0)); // PM roll-off above the peak
	float a = sea_state * STEEP * pm * lambda / TAU;
	return vec4(cos(ang), sin(ang), lambda, a);
}

// Fades a wave out when it's shorter than `res` can hold.
float resolve(float lambda, float res) {
	return smoothstep(2.0 * res, 4.0 * res, lambda);
}

// Waves feel the bottom below ~lambda/3 and are gone at the shore.
float shoal(float lambda, float depth) {
	return smoothstep(0.0, 0.35 * lambda, depth) * smoothstep(0.0, 1.2, depth);
}

// Shallow-water dispersion: omega^2 = g k tanh(k h).
float omega(float k, float depth) {
	return sqrt(9.81 * k * tanh(k * max(depth, 0.3)));
}

float phase(float fi, vec2 d, float k, float depth, vec2 wp) {
	return k * dot(d, x0 + wp * min(2.2 / k, 4.0)) - omega(k, depth) * TIME + hash1(fi + 37.0) * TAU;
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	x0 = sea_sign * world.xz + sea_offset;
	spacing = UV.x;
	sea_depth = -height_m(world.xz, clamp(int(log2(max(spacing, 1.0) / map_cell())), 0, 8));
	vec3 disp = vec3(0.0);
	vec2 wp = warp(x0);
	for (int i = 0; i < NW; i++) {
		vec4 w = wave(i);
		float f = resolve(w.z, 2.0 * spacing); // (the ring grid aliases sooner than a square one)
		if (f <= 0.0)
			break; // (wavelengths only get shorter)
		float k = TAU / w.z;
		float a = w.w * f * shoal(w.z, sea_depth);
		float th = phase(float(i), w.xy, k, sea_depth, wp);
		disp.xz += choppiness * a * w.xy * cos(th);
		disp.y += a * sin(th);
	}
	{
		vec2 d = vec2(cos(swell_angle), sin(swell_angle));
		float k = TAU / swell_length;
		float a = swell_height * resolve(swell_length, 2.0 * spacing) * shoal(swell_length, sea_depth);
		float th = k * dot(d, x0) - omega(k, sea_depth) * TIME;
		disp.xz += 0.5 * a * d * cos(th);
		disp.y += a * sin(th);
	}
	height = disp.y;
	VERTEX += vec3(sea_sign.x * disp.x, disp.y, sea_sign.y * disp.z);
}

void fragment() {
	float px = max(length(dFdx(x0)), length(dFdy(x0))); // metres per pixel
	vec2 slope = vec2(0.0);
	vec2 wp = warp(x0);
	float lost = 0.0;            // slope variance too fine to draw
	vec3 jac = vec3(0.0);        // Gerstner Jacobian terms (xx, zz, xz)
	for (int i = 0; i < NW; i++) {
		vec4 w = wave(i);
		float k = TAU / w.z;
		float a = w.w * shoal(w.z, sea_depth);
		float f = resolve(w.z, 1.6 * px);
		float ka = k * a;
		lost += 0.5 * ka * ka * (1.0 - f * f);
		if (f <= 0.0)
			continue;
		float th = phase(float(i), w.xy, k, sea_depth, wp);
		slope += w.xy * ka * f * cos(th);
		float s = choppiness * ka * f * sin(th);
		jac += vec3(w.x * w.x, w.y * w.y, w.x * w.y) * s;
	}
	{
		vec2 d = vec2(cos(swell_angle), sin(swell_angle));
		float k = TAU / swell_length;
		float a = swell_height * shoal(swell_length, sea_depth);
		float th = k * dot(d, x0) - omega(k, sea_depth) * TIME;
		slope += d * k * a * cos(th);
	}
	slope += chop(x0, px, sea_depth, lost);
	float folding = (1.0 - jac.x) * (1.0 - jac.y) - jac.z * jac.z; // < 1 where the surface bunches up
	slope /= max(1.0 - jac.x - jac.y, 0.25);
	slope *= sea_sign; // back to world axes
	vec3 n_world = normalize(vec3(-slope.x, 1.0, -slope.y));

	vec3 to_eye = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;
	bool below = to_eye.y < 0.0;
	if (below)
		n_world = reflect(n_world, vec3(0.0, 1.0, 0.0));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
	vec3 view_world = normalize(to_eye);
	vec3 sun = normalize(sun_direction);

	// ---- foam: whitecaps where the waves fold, surf along the shore
	float grain = vnoise2(x0 * 0.9 + TIME * 0.15) * 0.6 + vnoise2(x0 * 3.1 - TIME * 0.2) * 0.4;
	float whitecap = smoothstep(0.55, 0.15, folding) * smoothstep(0.25, 0.6, grain);
	float surf_band = 0.5 + 0.5 * sin(sea_depth * 2.2 + TIME * 1.3 + grain * 2.0);
	float surf = smoothstep(2.0, 0.2, sea_depth) * smoothstep(0.35, 0.9, surf_band * grain + 0.25 * smoothstep(0.6, 0.0, sea_depth));
	float foam = clamp(max(whitecap, surf), 0.0, 1.0) * (1.0 - smoothstep(0.5, 6.0, px)); // too fine to see far off

	// ---- light coming up through the surface
	float cos_v = max(abs(view_world.y), 0.04);
	float depth = max(sea_depth, 0.0);
	float path = depth / cos_v; // eye ray through the water
	vec2 offset = slope * refraction * clamp(path * 0.3, 0.0, 1.0);
	vec3 floor_seen = texture(screen_tex, SCREEN_UV + offset).rgb;
	// sunlight went down `depth` to light the floor, then `path` back up to us
	vec3 transmit = exp(-absorption * (path + depth));
	// light scattered back by the water column, saturating with depth
	vec3 column = 1.0 - exp(-absorption * (path + depth) * 0.5);
	vec3 inscatter = scatter_color * column * (0.35 + 0.65 * max(sun.y, 0.0)) * sun_color;
	// thin crests lit from behind, seen against the sun
	float toward_sun = pow(max(dot(-view_world, normalize(vec3(sun.x, 0.0, sun.z) + vec3(0.0, 0.25, 0.0))), 0.0), 3.0);
	float crest = clamp(height * 0.6 + 0.4, 0.0, 1.5);
	vec3 sss = crest_color * crest * crest * (0.12 + 0.9 * toward_sun) * (1.0 - smoothstep(1.0, 4.0, spacing)) * (1.0 - smoothstep(1.0, 30.0, px)) * sun_color;
	vec3 under = floor_seen * transmit + inscatter + sss * clamp(depth * 0.3, 0.0, 1.0);

	// Godot reflects the sky and the sun; the rest is what comes through
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = 0.02 + 0.98 * pow(1.0 - ndv, 5.0);
	if (below) // looking up: total internal reflection past ~48 degrees
		fresnel = ndv < 0.67 ? 1.0 : fresnel;
	SPECULAR = 0.25; // F0 = 0.08 * SPECULAR = 0.02, water's
	ROUGHNESS = clamp(sqrt(sqrt(2.0 * lost + 0.0004)), 0.02, 0.7) * (1.0 - foam) + foam * 0.9;
	ALBEDO = vec3(0.85, 0.88, 0.88) * foam;
	EMISSION = under * (1.0 - fresnel) * (1.0 - foam);
	FOG = aerial_fog((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz, CAMERA_POSITION_WORLD);
	// the very edge of the water fades in over its first 20 cm
	ALPHA = max(smoothstep(0.0, 0.2, depth), foam);
}
