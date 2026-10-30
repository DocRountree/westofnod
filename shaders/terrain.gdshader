shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Far LOD tiles hide themselves where the detailed near chunks take over.
uniform float near_cutoff = 0.0;

varying vec3 wpos;
varying vec3 wnorm;
varying vec4 attr; // r: alluvium/6m, g: gully/10m, b: channel/2m, a: dug/3m

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = NORMAL;
	attr = COLOR;
}

void fragment() {
	if (near_cutoff > 0.0 && distance(wpos.xz, CAMERA_POSITION_WORLD.xz) < near_cutoff) {
		discard;
	}
	vec3 n = normalize(wnorm);
	float h = wpos.y;
	float n1 = vnoise(wpos.xz * 0.05);
	float n2 = vnoise(wpos.xz * 0.6);
	float n3 = vnoise(wpos.xz * 3.7);

	float alluvium = attr.r * 6.0;
	float gully = attr.g * 10.0;
	float channel = attr.b * 2.0;
	float dug = attr.a * 3.0;

	vec3 grass = mix(vec3(0.26, 0.43, 0.13), vec3(0.38, 0.52, 0.18), n1) * (0.9 + 0.2 * n2);
	vec3 meadow = mix(vec3(0.24, 0.47, 0.14), vec3(0.33, 0.52, 0.16), n2) * (0.92 + 0.12 * n3);
	vec3 silt = mix(vec3(0.45, 0.40, 0.29), vec3(0.37, 0.33, 0.24), n3);
	vec3 dirt = vec3(0.42, 0.30, 0.19) * (0.85 + 0.3 * n3);
	vec3 rock = mix(vec3(0.43, 0.41, 0.38), vec3(0.56, 0.54, 0.50), n2) * (0.85 + 0.3 * n3);
	vec3 sand = mix(vec3(0.80, 0.74, 0.53), vec3(0.89, 0.83, 0.63), n2);
	vec3 seabed = mix(vec3(0.58, 0.54, 0.40), vec3(0.42, 0.40, 0.33), n1);
	vec3 gravel = mix(vec3(0.46, 0.44, 0.41), vec3(0.62, 0.60, 0.55), n3);

	vec3 col = grass;
	// Floodplain / fan sediments: greener meadow, silty patches along their margins.
	col = mix(col, meadow, smoothstep(0.3, 2.0, alluvium));
	col = mix(col, silt, smoothstep(0.6, 0.9, n2) * smoothstep(0.5, 1.5, alluvium) * 0.5);
	// Gully floors and moderately steep ground show soil.
	col = mix(col, dirt, clamp(smoothstep(0.88, 0.74, n.y) * 0.7 + smoothstep(2.0, 9.0, gully) * 0.55, 0.0, 1.0));
	col *= 1.0 - 0.25 * smoothstep(2.0, 12.0, gully); // shadowed gully floors
	// Steep slopes and high ground are bare rock (matches surface_material()).
	float rocky = 1.0 - smoothstep(0.66, 0.74, n.y);
	rocky = max(rocky, smoothstep(95.0, 130.0, h + n1 * 25.0) * smoothstep(0.98, 0.82, n.y));
	rocky = max(rocky, smoothstep(0.6, 1.0, n2) * smoothstep(0.84, 0.76, n.y) * 0.8);
	col = mix(col, rock, rocky);
	// River beds.
	col = mix(col, gravel, smoothstep(0.25, 0.5, channel));
	// Beach, then sea floor.
	col = mix(col, sand, 1.0 - smoothstep(1.0, 1.5, h + (n2 - 0.5) * 0.4));
	col = mix(col, seabed, 1.0 - smoothstep(-2.0, 0.0, h));
	// Dug ground: soil, then stone deeper down.
	if (dug > 0.05 && h >= 1.25) {
		col = mix(col, dirt, smoothstep(0.1, 0.3, dug));
	}
	col = mix(col, rock, smoothstep(1.8, 2.2, dug));

	ALBEDO = pow(col, vec3(2.2)); // palette above is authored in sRGB
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;
}
