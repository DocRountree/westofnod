shader_type spatial;

// A spider's body (Spider), painted from where on it a point is (its
// object space, mm: x across, y up, z back; the cephalothorax ahead of
// z 0, the abdomen behind it), by species:
// 0 wolf spider (Hogna carolinensis): dark brown, the cephalothorax's pale
//   lines radiating from its middle, the abdomen a darker lance down its
//   front, faint chevrons; black beneath
// 1 six-spotted fishing spider (Dolomedes triton): olive brown, a cream
//   band down each side of the cephalothorax and the abdomen, pairs of
//   white spots down the abdomen
// 2 grass spider (Agelenopsis): pale brown, two dark bands down the
//   cephalothorax, the abdomen's dark middle stripe and chevrons
// 3 yellow garden spider (Argiope aurantia): the cephalothorax silver
//   white, the abdomen black with bold yellow patches in pairs, its front
//   edge yellow
// young: paler, the marks faint. abd_z: where the abdomen begins (mm).

uniform int species = 0;
uniform bool young = false;
uniform float abd_z = 0.5;
uniform float abd_len = 12.0;
uniform float half_w = 4.5;

varying vec3 o;

void vertex() {
	o = VERTEX;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	bool abd = o.z > abd_z;
	float t = abd ? (o.z - abd_z) / abd_len : 0.0; // (down the abdomen, 0..1)
	float ax = abs(o.x) / half_w; // (out from the middle line, 0..1)
	float under = smoothstep(-0.2, -1.5, o.y);
	vec3 c;
	float rough = 0.75;
	if (species == 0) {
		c = vec3(0.3, 0.22, 0.14);
		if (!abd) {
			float ang = atan(o.x, -o.z - 3.0);
			float rad = abs(fract(ang * 1.6) - 0.5);
			c = mix(c, vec3(0.5, 0.42, 0.3), (1.0 - smoothstep(0.04, 0.1, rad)) * 0.6);
			c = mix(c, vec3(0.45, 0.38, 0.26), 1.0 - smoothstep(0.12, 0.2, ax)); // (the pale middle band)
		} else {
			float lance = 1.0 - smoothstep(0.12 * (1.0 - t * 1.5), 0.2 * (1.0 - t * 1.5) + 0.02, ax);
			c = mix(c, vec3(0.13, 0.09, 0.06), lance * step(t, 0.55));
			float chev = 1.0 - smoothstep(0.03, 0.08, abs(fract(t * 6.0 - ax * 0.8) - 0.5));
			c = mix(c, vec3(0.18, 0.13, 0.08), chev * step(0.45, t) * 0.7);
		}
		c = mix(c, vec3(0.05, 0.04, 0.035), under);
	} else if (species == 1) {
		c = vec3(0.28, 0.25, 0.17);
		float side = smoothstep(0.62, 0.72, ax) * (1.0 - smoothstep(0.9, 0.98, ax)) * (1.0 - under);
		c = mix(c, vec3(0.86, 0.8, 0.62), side);
		if (abd) {
			for (int k = 0; k < 5; k++) {
				float tk = 0.15 + 0.16 * float(k);
				float d = length(vec2((ax - 0.3) * half_w, (t - tk) * abd_len));
				c = mix(c, vec3(0.9, 0.88, 0.8), 1.0 - smoothstep(0.45, 0.6, d));
			}
		}
		c = mix(c, vec3(0.6, 0.55, 0.42), under * 0.7);
	} else if (species == 2) {
		c = vec3(0.55, 0.45, 0.3);
		if (!abd) {
			float bands = smoothstep(0.18, 0.24, ax) * (1.0 - smoothstep(0.48, 0.56, ax));
			c = mix(c, vec3(0.22, 0.15, 0.09), bands);
		} else {
			c = vec3(0.42, 0.34, 0.24);
			c = mix(c, vec3(0.18, 0.13, 0.08), 1.0 - smoothstep(0.1, 0.16, ax));
			float chev = 1.0 - smoothstep(0.05, 0.1, abs(fract(t * 5.0 - ax * 0.9) - 0.5));
			c = mix(c, vec3(0.62, 0.52, 0.38), chev * smoothstep(0.15, 0.3, ax) * 0.8);
		}
		c = mix(c, vec3(0.3, 0.24, 0.16), under);
	} else {
		if (!abd) {
			c = vec3(0.82, 0.82, 0.78); // (silver hairs)
			rough = 0.45;
		} else {
			c = vec3(0.04, 0.04, 0.04);
			// the yellow patches in pairs down each side, the front edge yellow
			float edge = 1.0 - smoothstep(0.06, 0.1, t);
			c = mix(c, vec3(0.95, 0.75, 0.1), edge * (1.0 - under));
			for (int k = 0; k < 5; k++) {
				float tk = 0.18 + 0.16 * float(k);
				float d = length(vec2((ax - (0.45 + 0.12 * sin(float(k)))) * half_w * 0.9, (t - tk) * abd_len));
				c = mix(c, vec3(0.95, 0.72, 0.12), (1.0 - smoothstep(0.9, 1.2, d)) * (1.0 - under));
			}
			c = mix(c, vec3(0.08, 0.07, 0.04), under);
		}
	}
	if (young)
		c = mix(c, vec3(0.62, 0.56, 0.44), 0.45);
	c *= 0.94 + 0.12 * h21(floor(o.xz * 6.0)); // (the hairs' unevenness)
	ALBEDO = c;
	ROUGHNESS = rough;
	RIM = 0.4;
	RIM_TINT = 0.5;
}
