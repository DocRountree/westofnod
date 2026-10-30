// Aerial perspective, written to FOG (so it applies after lighting). The air
// between the eye and a surface scatters skylight into the view, blue far more
// than red (Rayleigh: ~1/wavelength^4, so roughly 0.3 : 0.55 : 1 for red,
// green, blue), and dims what lies behind. At middle distance the blue has
// filled in and the red hardly at all, so green hills turn blue; far away
// every channel saturates and the land fades into the horizon's colour. The
// air thins with height; toward the sun the haze warms (forward scattering).

uniform vec3 haze_horizon = vec3(0.45, 0.6, 0.86); // what infinitely deep air looks like
uniform vec3 haze_sun = vec3(0.95, 0.88, 0.75);    // forward-scattered sunlight
uniform float haze_distance = 2600.0;              // m for 63% of the blue at sea level
uniform float haze_scale_height = 1200.0;
uniform vec3 haze_sun_dir = vec3(0.4, 0.6, 0.6);   // toward the sun
uniform bool underwater = false;

const vec3 HAZE_SPECTRUM = vec3(0.3, 0.55, 1.0);

vec4 aerial_fog(vec3 world_pos, vec3 cam) {
	vec3 ray = world_pos - cam;
	float d = length(ray);
	if (underwater) {
		return vec4(0.03, 0.17, 0.2, 1.0 - exp(-d / 9.0));
	}
	float h = max(0.5 * (world_pos.y + cam.y), 0.0);
	float tau = d / haze_distance * exp(-h / haze_scale_height);
	vec3 scattered = 1.0 - exp(-tau * HAZE_SPECTRUM); // per channel
	float toward_sun = max(dot(ray / max(d, 1e-3), normalize(haze_sun_dir)), 0.0);
	vec3 colour = mix(haze_horizon, haze_sun, pow(toward_sun, 8.0) * 0.5);
	// FOG mixes with one alpha: take the blue's (the most), and let the colour
	// carry the other channels' smaller share.
	float a = max(scattered.b, 1e-4);
	return vec4(colour * scattered / a, a);
}
