shader_type spatial;
// A dragonfly's abdomen (scripts/creatures/dragonfly.gd): one smooth tube
// down its ten segments, not ten pieces, curled here as its segment nodes
// are (each joint bent its share), the bend eased across each joint so
// it's one long body; the first two segments green, on from them its
// colour, a black stripe down its back and a dark ring at each joint.
//
// UV.x along its segment (0..1), UV.y round it (0..1, its back 0.25);
// UV2.x which segment. VERTEX: the rest shape in its segment's own frame
// (z from its joint).

uniform float seg_len[10];
uniform vec3 base = vec3(0.0, 0.6, 5.2); // its first joint (the body's space)
uniform vec3 green : source_color = vec3(0.33, 0.62, 0.2);
uniform vec3 colour : source_color = vec3(0.25, 0.5, 0.86);
uniform vec3 dark : source_color = vec3(0.06, 0.06, 0.06);
instance uniform float curl = 0.0; // (+ down, - up)
instance uniform float hard = 1.0; // teneral: 0 pale, just out .. 1 its colour

varying float v_seg;
varying vec2 v_uv;

mat3 rx(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c));
}

// each joint's bend: as dragonfly.gd's _pose bends its nodes
float ang(int j) {
	if (j > 9) {
		return 0.0;
	}
	float share = j < 2 ? 0.0 : float(j - 1) / 9.0;
	return -curl * share * 0.9 - 0.03;
}

void vertex() {
	int i = int(UV2.x + 0.5);
	float u = UV.x;
	v_seg = float(i);
	v_uv = UV;
	mat3 r_prev = mat3(1.0);
	mat3 r = mat3(1.0);
	vec3 o = base;
	for (int j = 0; j < 10; j++) {
		if (j > 0) {
			o += r * vec3(0.0, 0.0, seg_len[j - 1]);
		}
		r_prev = r;
		r = r * rx(ang(j));
		if (j == i) {
			break;
		}
	}
	float len = seg_len[i];
	vec3 p = VERTEX;
	mat3 m;
	if (u < 0.5) { // (eased from half the joint's bend behind it)
		m = r_prev * rx(ang(i) * (0.5 + 0.5 * smoothstep(0.0, 0.3, u)));
		VERTEX = o + m * p;
	} else { // (and into half the next's)
		m = r * rx(ang(i + 1) * 0.5 * smoothstep(0.7, 1.0, u));
		VERTEX = o + r * vec3(0.0, 0.0, len) + m * (p - vec3(0.0, 0.0, len));
	}
	NORMAL = normalize(m * NORMAL);
}

void fragment() {
	float u = v_uv.x;
	float round_ = v_uv.y;
	vec3 col = v_seg < 1.5 ? green : colour;
	if (v_seg > 1.5) {
		// the stripe down its back (and its edges soft)
		float d = abs(fract(round_ - 0.25 + 0.5) - 0.5);
		col = mix(col, dark, smoothstep(0.07, 0.045, d));
		// the ring at each joint
		col = mix(col, dark, smoothstep(0.9, 0.94, u) * (v_seg < 8.5 ? 1.0 : 0.0));
	} else if (v_seg > 0.5) { // (green into its colour: the ring between them)
		col = mix(col, dark, smoothstep(0.88, 0.95, u) * 0.8);
	}
	ALBEDO = mix(vec3(0.85, 0.84, 0.72), col, hard);
	ROUGHNESS = 0.35;
	CLEARCOAT = 0.5;
	CLEARCOAT_ROUGHNESS = 0.2;
}
