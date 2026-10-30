// Aerial perspective: the air between the eye and a surface scatters skylight
// into the view (mostly blue: Rayleigh scattering goes as 1/wavelength^4) and
// dims the light coming back. Written to FOG, so it applies after lighting:
// distant greens desaturate and turn blue, shadowed slopes turn blue too.
// The air thins with height, so the optical depth uses the mean height of the
// view ray; toward the sun the haze warms (forward scattering by haze).

uniform vec3 haze_blue = vec3(0.47, 0.62, 0.86);  // skylight scattered by the air
uniform vec3 haze_sun = vec3(0.92, 0.88, 0.80);   // forward-scattered sunlight
uniform float haze_distance = 6500.0;             // metres for 63% at sea level
uniform float haze_scale_height = 1400.0;
uniform vec3 haze_sun_dir = vec3(0.4, 0.6, 0.6);  // toward the sun
uniform bool underwater = false;                  // the camera is under water

vec4 aerial_fog(vec3 world_pos, vec3 cam) {
	vec3 ray = world_pos - cam;
	float d = length(ray);
	if (underwater) {
		return vec4(0.03, 0.17, 0.2, 1.0 - exp(-d / 9.0));
	}
	float h = max(0.5 * (world_pos.y + cam.y), 0.0);
	float tau = d / haze_distance * exp(-h / haze_scale_height);
	// Per-channel: blue scatters most, so it fills in first.
	vec3 amount = 1.0 - exp(-tau * vec3(0.75, 0.95, 1.25));
	float toward_sun = max(dot(ray / max(d, 1e-3), normalize(haze_sun_dir)), 0.0);
	vec3 colour = mix(haze_blue, haze_sun, pow(toward_sun, 6.0) * 0.6);
	// FOG blends with a single alpha: fold the per-channel amounts into the colour.
	float a = max(amount.b, 1e-4);
	return vec4(colour * amount / a, a);
}
