shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;

// Water surface: ocean, lakes and rivers.
//
// Geometry: a sum of Gerstner (trochoidal) waves displaces the mesh. Each wave
// fades out where it is too short for the local mesh spacing, so nothing aliases.
// Per pixel: the analytic Gerstner normal plus a few dozen small analytic waves
// (a deep-water spectrum spread around the wind, standing in for an FFT ocean),
// each faded by the pixel footprint so distant water averages out instead of
// sparkling. Godot's lighting supplies the sky reflection and sun glints; this
// shader supplies the light coming up through the water: the refracted
// background, absorbed with depth (red first), plus light scattered in the
// water body and through thin crests.
//
// Rivers: UV carries the flow (direction x speed, 0..1). Their waves run
// downstream and are carried by the current: the pattern is advected along the
// flow with two copies half a cycle apart, each reset before it stretches too
// far, and cross-faded, so the water visibly moves the right way everywhere.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;

group_uniforms waves;
uniform float amplitude = 1.0;     // multiplies every wave's steepness
uniform float length_scale = 1.0;  // multiplies every wavelength
uniform float wind_angle = 0.35;
uniform float mesh_spacing = 0.0;  // grid spacing (m); 0: the camera-centred ocean grid
uniform float detail_strength = 1.0;
uniform float river_speed = 1.4;   // m/s at full flow
uniform float near_cutoff = 0.0;   // far LOD water hides near the camera

group_uniforms light;
uniform vec3 sun_direction = vec3(0.4, 0.6, 0.6); // toward the sun
uniform vec3 sun_color = vec3(1.0, 0.97, 0.92);

group_uniforms water;
uniform vec3 deep_color : source_color = vec3(0.004, 0.03, 0.06);
uniform vec3 scatter_color = vec3(0.0, 0.13, 0.14);
uniform vec3 absorption = vec3(0.45, 0.09, 0.06); // per metre
uniform float refraction = 0.03;
uniform float murk = 0.0;          // extra turbidity (rivers carry silt)
uniform vec3 silt_color = vec3(0.09, 0.08, 0.05);

const float G = 9.81;

const int NW = 6;
// direction offset from the wind (rad), wavelength (m), steepness, phase
const vec4 WAVE[NW] = vec4[](
	vec4(0.0, 61.0, 0.16, 0.0),
	vec4(-0.75, 37.0, 0.14, 1.7),
	vec4(0.5, 23.0, 0.12, 4.1),
	vec4(-1.35, 14.0, 0.10, 2.3),
	vec4(-0.2, 8.5, 0.08, 5.6),
	vec4(1.6, 5.3, 0.06, 0.9)
);
const int ND = 24; // small waves, per pixel

varying vec2 x0;        // undisplaced world xz
varying float spacing;  // mesh spacing here (m)
varying float crest;    // height above rest
varying float pinch;    // horizontal convergence of the Gerstner waves (foam)
varying vec2 vflow;

float wave_angle(int i, float base, bool river) {
	return base + WAVE[i].x * (river ? 0.35 : 1.0);
}

float lod(float lambda, float sp) {
	return clamp((lambda - 3.0 * sp) / (3.0 * sp), 0.0, 1.0);
}

// Gerstner displacement at p, time t. Rivers fan their waves tightly around the
// flow and give them the current's speed.
vec3 gerstner(vec2 p, float t, float sp, vec2 flow, out vec2 slope, out float jac) {
	bool river = dot(flow, flow) > 1e-4;
	float base = river ? atan(flow.y, flow.x) : wind_angle;
	vec3 disp = vec3(0.0);
	slope = vec2(0.0);
	float nz = 1.0;
	float jxx = 1.0, jzz = 1.0, jxz = 0.0;
	for (int i = 0; i < NW; i++) {
		float ang = wave_angle(i, base, river);
		vec2 d = vec2(cos(ang), sin(ang));
		float lambda = WAVE[i].y * length_scale;
		float k = TAU / lambda;
		float steep = WAVE[i].z * amplitude * lod(lambda, sp);
		float a = steep / k;
		float th = k * dot(d, p) - sqrt(G * k) * t + WAVE[i].w;
		float c = cos(th);
		float s = sin(th);
		disp.xz += d * a * c;
		disp.y += a * s;
		slope += d * steep * c;
		nz -= steep * s;
		jxx -= d.x * d.x * steep * s;
		jzz -= d.y * d.y * steep * s;
		jxz -= d.x * d.y * steep * s;
	}
	slope /= max(nz, 0.2);
	jac = jxx * jzz - jxz * jxz;
	return disp;
}

// Small waves: slopes of ND short waves, wavelengths 4 m .. 0.12 m (scaled), with
// directions spread around the base direction by a golden-angle sequence.
// Faded by the pixel footprint fp.
vec2 detail(vec2 p, float t, float fp, float base, bool river) {
	vec2 slope = vec2(0.0);
	float lambda = 4.0 * length_scale;
	for (int i = 0; i < ND; i++) {
		float spread = river ? 0.9 : 1.4;
		float ang = base + spread * sin(float(i) * 2.39996) * (0.4 + 0.6 * fract(float(i) * 0.618));
		vec2 d = vec2(cos(ang), sin(ang));
		float k = TAU / lambda;
		float steep = 0.075 * amplitude * clamp((lambda - 4.0 * fp) / (4.0 * fp), 0.0, 1.0);
		float th = k * dot(d, p) - sqrt(G * k + 0.074 * k * k * k) * t + float(i) * 1.913;
		slope += d * steep * cos(th);
		lambda *= 0.86;
	}
	return slope;
}

// Two-phase advection along the flow: returns the cross-fade weight and the two
// offsets to sample at.
vec3 advect(float t) {
	float ph0 = fract(t * 0.25);
	float ph1 = fract(t * 0.25 + 0.5);
	return vec3(ph0, ph1, abs(ph0 - 0.5) * 2.0);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	x0 = world.xz;
	vflow = UV;
	float dist = distance(world.xz, CAMERA_POSITION_WORLD.xz);
	spacing = mesh_spacing > 0.0 ? mesh_spacing : max(0.5, dist * 0.035);
	vec2 sl;
	float jac;
	vec3 disp;
	if (dot(vflow, vflow) > 1e-4) {
		vec2 u = vflow * river_speed;
		vec3 ph = advect(TIME);
		float jac1;
		vec3 d0 = gerstner(x0 - u * ph.x * 4.0, TIME, spacing, vflow, sl, jac);
		vec3 d1 = gerstner(x0 - u * ph.y * 4.0 + vec2(13.1, 7.7), TIME, spacing, vflow, sl, jac1);
		disp = mix(d0, d1, ph.z);
		jac = mix(jac, jac1, ph.z);
	} else {
		disp = gerstner(x0, TIME, spacing, vflow, sl, jac);
	}
	crest = disp.y;
	pinch = clamp(1.0 - jac, 0.0, 1.0);
	VERTEX += disp;
}

float schlick(vec3 n, vec3 v) {
	float c = clamp(dot(n, v), 0.0, 1.0);
	return 0.02 + 0.98 * pow(1.0 - c, 5.0);
}

float linear_depth(vec2 uv, float raw, mat4 inv_proj) {
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, raw, 1.0);
	return -v.z / v.w;
}

void fragment() {
	if (near_cutoff > 0.0 && distance(x0, CAMERA_POSITION_WORLD.xz) < near_cutoff) {
		discard;
	}
	bool river = dot(vflow, vflow) > 1e-4;
	float fp = max(length(fwidth(x0)), 0.002);

	// ---- normal: Gerstner + small waves (advected on rivers)
	vec2 slope;
	float jac;
	vec2 dslope;
	if (river) {
		vec2 u = vflow * river_speed;
		vec3 ph = advect(TIME);
		float base = atan(vflow.y, vflow.x);
		vec2 s0, s1;
		float j1;
		gerstner(x0 - u * ph.x * 4.0, TIME, spacing, vflow, s0, jac);
		gerstner(x0 - u * ph.y * 4.0 + vec2(13.1, 7.7), TIME, spacing, vflow, s1, j1);
		slope = mix(s0, s1, ph.z);
		vec2 e0 = detail(x0 - u * ph.x * 4.0, TIME, fp, base, true);
		vec2 e1 = detail(x0 - u * ph.y * 4.0 + vec2(13.1, 7.7), TIME, fp, base, true);
		dslope = mix(e0, e1, ph.z) * (0.6 + 0.8 * length(vflow));
	} else {
		gerstner(x0, TIME, spacing, vflow, slope, jac);
		dslope = detail(x0, TIME, fp, wind_angle, false);
	}
	slope += dslope * detail_strength;
	vec3 n_world = normalize(vec3(-slope.x, 1.0, -slope.y));
	if (!FRONT_FACING) n_world = -n_world;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	// ---- light coming up through the water
	float surf = -VERTEX.z;
	vec2 off = slope * refraction / (1.0 + surf * 0.02);
	vec2 ruv = SCREEN_UV + off;
	float scene = linear_depth(ruv, texture(depth_tex, ruv).r, INV_PROJECTION_MATRIX);
	if (scene < surf) { // refracted sample lies in front of the water: don't refract
		ruv = SCREEN_UV;
		scene = linear_depth(ruv, texture(depth_tex, ruv).r, INV_PROJECTION_MATRIX);
	}
	// Path length through the water, from view distances.
	float thickness = max(scene - surf, 0.0) * length(VERTEX) / max(surf, 1e-3);
	vec3 background = textureLod(screen_tex, ruv, 0.0).rgb;
	vec3 transmit = exp(-(absorption + murk) * thickness);

	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 to_eye = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 sun = normalize(sun_direction);
	float diffuse = max(dot(n_world, sun), 0.0);
	float toward_sun = max(dot(-to_eye, sun), 0.0); // light shining through crests
	float crest_t = clamp(crest * 0.5 + 0.3, 0.0, 1.0);
	crest_t *= crest_t;
	vec3 body = deep_color * (0.5 + 0.8 * diffuse)
			+ scatter_color * (0.25 + crest_t) * (0.35 + 1.5 * pow(toward_sun, 4.0)) * (0.5 + 0.5 * diffuse);
	body = mix(body, silt_color * (0.4 + 0.6 * diffuse), clamp(murk * 2.0, 0.0, 1.0));
	body *= 0.12 + 0.88 * sun_color;
	vec3 refracted = background * transmit + body * (1.0 - transmit);

	// ---- foam: breaking crests (where the waves pinch) and the swash line,
	// broken up by the small waves themselves rather than a texture.
	float breakup = clamp(0.5 + 2.5 * dot(dslope, vec2(0.7, 0.7)), 0.0, 1.0);
	float foam = smoothstep(0.25, 0.6, 1.0 - jac) * breakup;
	foam = max(foam, (1.0 - smoothstep(0.0, 0.35, thickness)) * smoothstep(0.3, 0.7, breakup) * 0.8);
	if (river) {
		// White water over riffles: fast, shallow flow.
		foam = max(foam, smoothstep(0.6, 1.0, length(vflow)) * (1.0 - smoothstep(0.1, 0.6, thickness)) * breakup);
	}

	float fresnel = schlick(n_world, to_eye);
	ALBEDO = vec3(0.85) * foam;
	ROUGHNESS = mix(0.03, 0.6, foam);
	SPECULAR = 0.5;
	EMISSION = refracted * (1.0 - fresnel) * (1.0 - foam);
	// Feather the waterline so the surface meets the ground without a seam.
	ALPHA = smoothstep(0.0, 0.12, thickness);
	if (!FRONT_FACING) {
		// From below: total internal reflection outside the Snell window.
		EMISSION = mix(deep_color + scatter_color * 0.5, background, smoothstep(0.65, 0.8, abs(dot(n_world, to_eye))));
		ALBEDO = vec3(0.0);
		ALPHA = 1.0;
	}
}
