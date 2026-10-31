shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// The moon as a lit sphere on a camera-facing disc. The phase is just the
// terminator where the sun's light falls on the sphere. Premultiplied
// blending: by day (alpha 0) it adds to the sky; at night (alpha 1) it covers
// the stars, its dark side faintly lit by earthshine.

uniform vec3 sun_local = vec3(1.0, 0.0, 0.0);   // sun direction in the disc's frame (x right, y up, z to the camera)
uniform float night = 0.0;                      // 0 by day, 1 at night
uniform float day_brightness = 0.35;
uniform float night_brightness = 1.6;
// The real surface (an albedo map, equirectangular, longitude 0 at the centre,
// east to the right), on the near side that always faces us, turned so lunar
// north points to the celestial pole (north_local: its direction in the disc).
uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 north_local = vec2(0.0, 1.0);

varying vec2 q;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	q = VERTEX.xy * 2.0;   // the quad spans -0.5..0.5
}

void fragment() {
	float r2 = dot(q, q);
	if (r2 > 1.0)
		discard;
	vec3 n = vec3(q, sqrt(1.0 - r2));
	float lit = smoothstep(-0.04, 0.06, dot(n, normalize(sun_local)));
	// the surface: sphere point in lunar axes (y north, x east as seen from here)
	vec2 nn = normalize(north_local);
	vec3 m = vec3(q.x * nn.y - q.y * nn.x, q.x * nn.x + q.y * nn.y, n.z);
	float lat = asin(clamp(m.y, -1.0, 1.0));
	float lon = atan(m.x, m.z);
	float albedo = texture(albedo_map, vec2(0.5 + lon / TAU, 0.5 - lat / PI)).r / 0.55;
	float limb = mix(0.78, 1.0, n.z);
	float edge = 1.0 - smoothstep(0.94, 1.0, r2);
	float brightness = mix(day_brightness, night_brightness, night);
	vec3 colour = vec3(1.0, 0.97, 0.92) * albedo * limb * (lit * brightness + 0.012 * night);
	ALBEDO = colour * edge;
	// The dark side blocks the stars behind it, but the twilight sky glows in
	// front of the moon, so it only blocks once the sky is fully dark
	ALPHA = edge * smoothstep(0.85, 1.0, night);
}
