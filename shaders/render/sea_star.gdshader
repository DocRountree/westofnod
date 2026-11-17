shader_type spatial;
render_mode cull_back;
// An ochre sea star (scripts/creatures/ochre_sea_star.gd): its five arms
// bent as its figures say (each: its tip lifted, a curl down along it, a
// bend to its side), its disc humped up (over a clam; on its arm tips to
// spawn); its tube feet stepping in waves down its arms, drawn in at rest;
// its skin: the reticulum of short white spines over its top, its eyespot
// red at each tip, its pale madreporite.
//
// CUSTOM0: x the arm (0..4), y out along it (0 the middle, 1 its tip), z a
// tube foot's way along it (0 its base, 1 its sucker; -1 the body), w a
// foot's phase (the body: how much it's its top, 0 beneath .. 1).

uniform float R = 0.12; // m: the middle to an arm's tip
uniform float rd = 0.03; // m: the disc's radius
uniform float foot_len = 0.008; // m: a tube foot, out

instance uniform vec4 arm0 = vec4(0.0); // lift (rad, its tip up +), curl (down along it), side bend, -
instance uniform vec4 arm1 = vec4(0.0);
instance uniform vec4 arm2 = vec4(0.0);
instance uniform vec4 arm3 = vec4(0.0);
instance uniform vec4 arm4 = vec4(0.0);
instance uniform float hump = 0.0; // m: its disc raised
instance uniform float feet = 0.5; // 0 drawn in, 1 out stepping
instance uniform float stride = 1.0; // its feet's stepping's pace
instance uniform vec3 body_col : source_color = vec3(0.86, 0.48, 0.14);
instance uniform float dead = 0.0;
instance uniform float seed = 0.0;

varying float v_foot;
varying float v_top;
varying float v_s;
varying vec3 v_rest;
varying float v_arm;

vec4 arm_of(int a) {
	if (a == 0) return arm0;
	if (a == 1) return arm1;
	if (a == 2) return arm2;
	if (a == 3) return arm3;
	return arm4;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// (Its reticulum: the spines along the edges of irregular cells.)
float cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 9.0;
	float d2 = 9.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash2(i + g), hash2(i + g + 17.0));
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return d2 - d1;
}

void vertex() {
	v_rest = VERTEX;
	int a = int(CUSTOM0.x + 0.5);
	float s = CUSTOM0.y;
	v_s = s;
	v_arm = CUSTOM0.x;
	v_foot = CUSTOM0.z;
	v_top = CUSTOM0.z < 0.0 ? CUSTOM0.w : 0.0;
	vec4 A = arm_of(a);
	float ang = 6.2831853 * float(a) / 5.0;
	vec3 ax = vec3(sin(ang), 0.0, -cos(ang)); // (the arm's way, from the middle)
	vec3 sd = vec3(cos(ang), 0.0, sin(ang));
	float u = clamp((s * R - rd) / (R - rd), 0.0, 1.0);
	if (CUSTOM0.z >= 0.0) { // a tube foot: out, stepping, or drawn in
		float t = CUSTOM0.z;
		float step = 0.5 + 0.5 * sin(TIME * 3.0 * stride - s * 14.0 + CUSTOM0.w * 6.2831853);
		float ext = mix(0.15, 0.6 + 0.4 * step, feet);
		VERTEX.y += (1.0 - ext) * foot_len * t; // (drawn in: shorter)
		VERTEX += ax * sin(TIME * 3.0 * stride - s * 14.0 + CUSTOM0.w * 6.2831853 + 1.57) * 0.25 * foot_len * feet * t; // (swung, stepping)
	}
	// the arm: its tip lifted, curled, bent aside; the disc humped
	float bend = A.x * u * u * (R - rd) * 0.6 + A.y * u * u * u * (R - rd) * -0.3;
	VERTEX.y += bend + hump * (1.0 - smoothstep(0.0, 0.85, u));
	VERTEX += sd * A.z * u * u * (R - rd) * 0.4;
	float tilt = atan(2.0 * A.x * u * 0.6 - 0.9 * A.y * u * u);
	NORMAL = normalize(NORMAL - ax * sin(tilt) * NORMAL.y);
	VERTEX = mix(VERTEX, VERTEX * vec3(1.0, 0.6, 1.0), dead * 0.4);
}

void fragment() {
	vec3 col = body_col;
	float rough = 0.6;
	if (v_foot >= 0.0) { // a tube foot: translucent, its sucker pale
		col = mix(body_col * 0.9 + vec3(0.12), vec3(0.95, 0.9, 0.78), smoothstep(0.85, 1.0, v_foot));
		rough = 0.3;
		SSS_STRENGTH = 0.5;
	} else {
		float top = smoothstep(0.25, 0.6, v_top);
		vec2 q = v_rest.xz / R * 26.0 + seed * 40.0;
		float c = cells(q);
		float spine = smoothstep(0.16, 0.0, c) * top;
		float dd = length(fract(q * 3.2) - 0.5);
		spine *= smoothstep(0.42, 0.22, dd); // (not lines: short spines, one by one, along them)
		float dots = step(0.9, hash2(floor(q * 3.0))) * top;
		col *= 0.85 + 0.25 * smoothstep(0.0, 0.5, c);
		col = mix(col, vec3(0.93, 0.92, 0.87), clamp(spine * 0.8 + dots * 0.5, 0.0, 1.0));
		// its underside: paler
		col = mix(col, mix(body_col, vec3(0.95, 0.8, 0.5), 0.6), 1.0 - smoothstep(0.1, 0.3, v_top));
		// the madreporite: between arms 0 and 1, off the middle
		vec2 mp = vec2(sin(0.6283), -cos(0.6283)) * R * 0.18;
		float md = length(v_rest.xz - mp) / R;
		col = mix(col, vec3(0.95, 0.85, 0.6), smoothstep(0.045, 0.03, md) * top);
		// its eyespots: red, at the tips
		col = mix(col, vec3(0.75, 0.08, 0.05), smoothstep(0.965, 0.995, v_s) * 0.9);
		rough = mix(0.65, 0.45, spine);
	}
	col = mix(col, vec3(0.62, 0.58, 0.52), dead * 0.75);
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
}
