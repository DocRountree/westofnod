shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// The Milky Way as stars: every star from V 10.5 (where the real catalogue,
// starfield.gd, stops) to 17.5, generated on the sky from a hash, with counts
// per magnitude and per patch of sky from a star-count model of the Galaxy
// (milky_way.gd): a disc concentrated toward the galactic plane, brighter
// toward the centre, and the bulge in Sagittarius. No dust, no colour, no
// painted glow: only stars.
//
// The sky is split into cube-face cells, one grid per magnitude bin, fine
// enough that a cell holds about one star at most. Where a bin's cells are
// bigger than a pixel its stars are drawn one by one as points (the same
// profile as starfield.gdshader's). Where they are smaller, a pixel can't
// separate them, and it shows the summed light of the stars that fall in it:
// how many is drawn per sky patch about a pixel across (fixed to the sky, so
// it is grain, not a smooth glow), and magnifying resolves them into points.
// Mesh: a sphere around the camera in equatorial coordinates (the node is a
// child of the Starfield, which turns it into the local sky).

const int MAX_LEVELS = 8;
uniform int levels = 0;
uniform float lv_cells[MAX_LEVELS];   // cells per cube-face side
uniform float lv_mag[MAX_LEVELS];     // the bin's bright end (it is one magnitude wide)
uniform float lv_count[MAX_LEVELS];   // stars per steradian where the shape factor is 1
uniform vec4 lv_shape[MAX_LEVELS];    // disc amplitude, disc scale height (rad), bulge amplitude, normaliser
uniform float visibility = 0.0;
uniform float pixel_angle = 0.0012;   // radians per screen pixel
uniform float gain = 1.0;             // telescope light grasp
uniform float brightness = 2.4;       // = starfield.gd's
uniform float star_size_px = 2.7;     // = starfield.gd's
uniform float bulge_sigma = 0.17;     // rad (~10 degrees)
// The dark-adapted eye: far more sensitive to light spread over a patch of sky
// than to single points, so the band of unresolved stars shows as it does
// outdoors. Applies to the summed light of stars a pixel can't separate.
uniform float adaptation = 12.0;

varying vec3 eq_dir;
varying vec3 world_dir;

// J2000 equatorial to galactic.
const mat3 EQ_TO_GAL = mat3(
	vec3(-0.0548755604, 0.4941094279, -0.8676661490),
	vec3(-0.8734370902, -0.4448296300, -0.1980763734),
	vec3(-0.4838350155, 0.7469822445, 0.4559837762));

uvec3 pcg3(uvec3 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	v ^= v >> 16u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	return v;
}

vec3 hash3(uvec3 v) {
	return vec3(pcg3(v)) * (1.0 / 4294967296.0);
}

// Cube face (0-5) and its coordinates in [-1, 1] for a direction.
void cube(vec3 d, out int face, out vec2 uv) {
	vec3 a = abs(d);
	if (a.x >= a.y && a.x >= a.z) {
		face = d.x > 0.0 ? 0 : 1;
		uv = d.yz / a.x;
	} else if (a.y >= a.z) {
		face = d.y > 0.0 ? 2 : 3;
		uv = d.xz / a.y;
	} else {
		face = d.z > 0.0 ? 4 : 5;
		uv = d.xy / a.z;
	}
}

vec3 uncube(int face, vec2 uv) {
	vec3 d;
	if (face < 2)
		d = vec3(face == 0 ? 1.0 : -1.0, uv.x, uv.y);
	else if (face < 4)
		d = vec3(uv.x, face == 2 ? 1.0 : -1.0, uv.y);
	else
		d = vec3(uv.x, uv.y, face == 4 ? 1.0 : -1.0);
	return normalize(d);
}

// Relative star density (mean 1 over the sky) of bin k toward galactic (l, b).
float shape(int k, float l, float b) {
	vec4 s = lv_shape[k];
	float disc = s.x * (0.55 + 0.45 * cos(l)) * exp(-abs(b) / s.y);
	float bulge = s.z * exp(-(l * l + b * b) / (2.0 * bulge_sigma * bulge_sigma));
	return (1.0 + disc + bulge) / s.w;
}

float flux(float m) {
	return brightness * pow(10.0, -0.4 * (m - 1.0)) * gain;
}

void vertex() {
	eq_dir = VERTEX;
	world_dir = (MODEL_MATRIX * vec4(VERTEX, 0.0)).xyz;
}

void fragment() {
	if (visibility <= 0.0 || world_dir.y < 0.0)
		discard;
	vec3 d = normalize(eq_dir);
	vec3 g = EQ_TO_GAL * d;
	float l = atan(g.y, g.x);
	float b = asin(clamp(g.z, -1.0, 1.0));
	int face;
	vec2 uv;
	cube(d, face, uv);
	float stretch = 1.0 + dot(uv, uv); // cube-face cells shrink by this^1.5 in solid angle
	float sigma_px = star_size_px * 0.5 / sqrt(5.0); // the point's profile, as in starfield.gdshader
	float light = 0.0;
	for (int k = 0; k < MAX_LEVELS; k++) {
		if (k >= levels)
			break;
		float n_sr = lv_count[k] * shape(k, l, b);           // stars per steradian here
		float mean_b = flux(lv_mag[k]) * 0.7071;               // mean flux over a one-magnitude bin
		if (mean_b < 1e-5)
			continue;                                          // too faint to show at this power
		float cell_angle = 2.0 / lv_cells[k] / stretch;        // ~ angular size of a cell here
		float resolved = smoothstep(1.2, 2.4, cell_angle / pixel_angle);
		if (resolved < 1.0) {
			// unresolved: the summed light of the stars in a patch about a pixel across
			float ng = exp2(floor(log2(2.0 / pixel_angle)));    // grain cells per face side (fixed steps)
			vec2 gc = floor((uv * 0.5 + 0.5) * ng);
			float omega = pow(2.0 / ng, 2.0) / pow(stretch, 1.5);
			float expect = n_sr * omega;                        // stars expected in the patch
			vec3 h = hash3(uvec3(uvec2(gc), uint(face) * 16u + uint(k) + 7919u));
			float noise = (h.x + h.y + h.z - 1.5) * 2.0;        // ~unit variance
			float count = max(expect + noise * sqrt(expect), 0.0);
			float per_px = count / omega * pixel_angle * pixel_angle;
			light += (1.0 - resolved) * per_px * mean_b * 2.0 * PI * sigma_px * sigma_px * adaptation;
		}
		if (resolved > 0.0) {
			// resolved: each star a point, from this cell and its neighbours
			vec2 cpos = (uv * 0.5 + 0.5) * lv_cells[k];
			ivec2 c0 = ivec2(floor(cpos));
			for (int j = -1; j <= 1; j++) {
				for (int i = -1; i <= 1; i++) {
					ivec2 c = c0 + ivec2(i, j);
					if (c.x < 0 || c.y < 0 || float(c.x) >= lv_cells[k] || float(c.y) >= lv_cells[k])
						continue;
					vec3 h = hash3(uvec3(uvec2(c), uint(face) * 16u + uint(k)));
					vec2 cuv = (vec2(c) + 0.5) / lv_cells[k] * 2.0 - 1.0;
					float omega = pow(2.0 / lv_cells[k], 2.0) / pow(1.0 + dot(cuv, cuv), 1.5);
					float expect = n_sr * omega;
					int n = int(floor(expect)) + int(h.x < fract(expect));
					for (int s = 0; s < 3; s++) {
						if (s >= n)
							break;
						vec3 r = hash3(uvec3(uvec2(c), uint(face) * 16u + uint(k) + 101u * uint(s + 1)));
						vec2 suv = (vec2(c) + r.xy) / lv_cells[k] * 2.0 - 1.0;
						float dist = length(uncube(face, suv) - d) / pixel_angle; // px
						float m = lv_mag[k] + r.z;
						light += resolved * flux(m) * exp(-dist * dist / (2.0 * sigma_px * sigma_px));
					}
				}
			}
		}
	}
	ALBEDO = vec3(min(light, 6.0) * visibility);
	ALPHA = 1.0;
}
