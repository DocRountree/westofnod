// Small waves for every body of water: a flowing fractal of value noise after
// P_Malin's "Adrift" (shadertoy.com/view/ldjfDD), as DocRountree/game's
// river.gdshader has it, carried along a flow in two phases half a period
// apart and crossfaded (so it never visibly resets), and flattened where a
// pixel spans too much water to show it (so far water doesn't sparkle).
// Needs `noise_scale` and `flow_period` uniforms.

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Value noise with its derivatives: (d/dx, d/dy, value).
vec3 smooth_noise_dxy(vec2 o) {
	vec2 p = floor(o);
	vec2 f = fract(o);
	float a = hash12(p);
	float b = hash12(p + vec2(1.0, 0.0));
	float c = hash12(p + vec2(0.0, 1.0));
	float d = hash12(p + vec2(1.0, 1.0));
	vec2 f2 = f * f;
	vec2 t = 3.0 * f2 - 2.0 * f2 * f;
	vec2 dt = 6.0 * f - 6.0 * f2;
	float res = a + (b - a) * t.x + (c - a) * t.y + (a - b + d - c) * t.x * t.y;
	float dx = (b - a) * dt.x + (a - b + d - c) * dt.x * t.y;
	float dy = (c - a) * dt.y + (a - b + d - c) * t.x * dt.y;
	return vec3(dx, dy, res);
}

const mat2 TURN = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));

// The flowing fractal: each octave carried by the flow, the next the other way
// at 3/4 of it, and warped up its own gradient (df); each octave turned from
// the last, the derivatives turned back to the world's.
vec3 fbm_dxy(vec2 p, vec2 flow, float ps, float df) {
	vec3 f = vec3(0.0);
	float tot = 0.0;
	float a = 1.0;
	mat2 m = mat2(1.0);
	for (int i = 0; i < 4; i++) {
		p += flow;
		flow *= -0.75;
		vec3 v = smooth_noise_dxy(p);
		f += vec3(transpose(m) * v.xy, v.z) * a;
		p += v.xy * df;
		p = TURN * p * 2.0;
		flow = TURN * flow;
		m = TURN * m;
		tot += a;
		a *= ps;
	}
	return f / tot;
}

vec3 water_normal(vec2 p, vec2 flow_offset, float mag, float filter_width) {
	float scale = 1.0 / (1.0 + filter_width * filter_width * 2000.0);
	vec3 dxy = fbm_dxy(p * noise_scale, flow_offset * noise_scale, 0.75, 0.25);
	return normalize(mix(vec3(0.0, 1.0, 0.0), normalize(vec3(dxy.x, mag, dxy.y)), scale));
}

// Two phases of the flowing surface, half a period apart and crossfaded: the
// pattern is looked up upstream by the distance the water has come.
vec3 flowing_normal(vec2 p, vec2 flow) {
	float mag = 2.5 / (1.0 + dot(flow, flow) * 0.05);
	vec2 fw = max(abs(dFdx(p)), abs(dFdy(p))) * noise_scale / 20.0;
	float filter_width = max(fw.x, fw.y);
	float t = TIME / flow_period;
	float t0 = fract(t);
	float t1 = fract(t + 0.5);
	vec3 n0 = water_normal(p, -flow * flow_period * (t0 - 0.5), mag, filter_width);
	vec3 n1 = water_normal(p + vec2(17.3, 5.1), -flow * flow_period * (t1 - 0.5), mag, filter_width);
	return normalize(mix(n0, n1, abs(t0 - 0.5) * 2.0));
}

