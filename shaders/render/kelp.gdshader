shader_type spatial;
render_mode cull_disabled;
// Giant kelp (scripts/creatures/giant_kelp.gd). COLOR: r its height up the
// water, g 1 afloat in the canopy, b its part (0 holdfast/stipe, 0.5 a
// float, 1 a blade), a along a blade. CUSTOM0: x a frond's phase, y across a
// blade.

uniform float depth = 1.0;
uniform float phase = 0.0;

varying float v_part;
varying float v_along;
varying float v_across;
varying float v_h;

void vertex() {
	float h = COLOR.r;
	float ph = CUSTOM0.x + phase;
	v_part = COLOR.b;
	v_along = COLOR.a;
	v_across = CUSTOM0.y;
	v_h = h;
	// the swell: the whole plant leaning to and fro, more the higher up; the
	// canopy drifting on the surface (never under it)
	float sway = pow(h, 1.4);
	vec3 off = vec3(sin(TIME * 0.42 + phase), 0.0, cos(TIME * 0.33 + phase * 1.3)) * 0.08 * depth * sway;
	off += vec3(sin(TIME * 0.9 + ph + h * 4.0), 0.0, cos(TIME * 0.8 + ph * 1.7 + h * 3.0)) * 0.012 * sway;
	if (v_part > 0.9) { // a blade: fluttering, more to its tip
		float t = v_along;
		off += NORMAL * sin(TIME * 1.6 + ph * 3.0 + t * 5.0) * 0.012 * t;
	}
	VERTEX += off;
}

void fragment() {
	// golden brown, darker down at the holdfast; a blade paler at its edges,
	// its fine teeth, its wrinkles; the floats glossy
	vec3 c = mix(vec3(0.13, 0.09, 0.035), vec3(0.27, 0.19, 0.06), smoothstep(0.0, 0.15, v_h));
	float rough = 0.55;
	float sss = 0.3;
	if (v_part > 0.9) {
		float edge = smoothstep(0.7, 1.0, abs(v_across));
		c = mix(vec3(0.3, 0.21, 0.06), vec3(0.42, 0.31, 0.1), edge * 0.6);
		c *= 0.9 + 0.15 * sin(v_along * 90.0 + v_across * 3.0); // (its wrinkles)
		c = mix(c, vec3(0.2, 0.14, 0.04), smoothstep(0.85, 1.0, v_along) * 0.5);
		sss = 0.6;
	} else if (v_part > 0.4) {
		c = vec3(0.34, 0.25, 0.08);
		rough = 0.25;
	}
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.4;
	SSS_STRENGTH = sss;
	SSS_TRANSMITTANCE_COLOR = vec4(0.8, 0.6, 0.2, 1.0);
	SSS_TRANSMITTANCE_DEPTH = 0.2;
}
