shader_type spatial;

// fur: shells (Hexapod._fur_shells), each a copy of the mesh a little further out
// along its normals (shell: 0 the skin .. 1 the hairs' tips), the hairs
// thinning to their tips, combed down and back (comb); fur_obj: the hairs'
// length, fur_dens: how many a unit, in the mesh's own units
instance uniform float shell = 0.0;
instance uniform float fur_obj = 0.0;
instance uniform float fur_dens = 1.0;
uniform vec3 comb = vec3(0.0, -0.35, 0.55);

// A snowshoe hare's summer coat (Hare): brown, grizzled (each hair banded),
// darker along the back, the belly and chin white; the big hind feet paler
// (pale: how far a part goes to cream). part 0 the body, head and legs, 1
// an ear (its tip black: ear_len, mm, its length up its own y; inside it
// thin furred, pinkish), 2 the tail (white beneath).

uniform float pale = 0.0;
uniform int part = 0;
uniform float ear_len = 75.0;
uniform vec3 brown : source_color = vec3(0.44, 0.33, 0.22);
uniform vec3 dark : source_color = vec3(0.3, 0.23, 0.16);
uniform vec3 white : source_color = vec3(0.92, 0.91, 0.88);
uniform vec3 cream : source_color = vec3(0.78, 0.7, 0.58);

varying vec3 o;
varying vec3 no;

void vertex() {
	o = VERTEX;
	no = NORMAL;
	if (shell > 0.0)
		VERTEX += (NORMAL + comb * shell) * fur_obj * shell;
}

float h31(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

float vn(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void fragment() {
	if (shell > 0.0) { // (a hair here, or none: thinning to its tip)
		vec3 q = o * fur_dens;
		vec3 f = fract(q) - 0.5;
		float hh = h31(floor(q));
		if (length(f) > 0.5 * (1.0 - shell * 0.8) || hh < shell * 0.45)
			discard;
	}
	float ny = normalize(no).y;
	vec3 c = mix(brown, dark, smoothstep(0.55, 0.95, ny));
	c *= 0.82 + 0.3 * vn(o * 0.9) * vn(o * 0.23 + 4.0); // (the hairs' bands)
	c = mix(c, cream, pale);
	float under = 1.0 - smoothstep(-0.55, -0.2, ny);
	if (part == 2)
		under = 1.0 - smoothstep(-0.2, 0.25, ny); // (the tail's white beneath)
	c = mix(c, white, under);
	if (part == 1) {
		c = mix(c, vec3(0.05, 0.045, 0.04), smoothstep(ear_len * 0.78, ear_len * 0.86, o.y)); // (the black tip)
		if (o.z < -0.5 && o.y < ear_len * 0.78)
			c = mix(c, vec3(0.78, 0.62, 0.58), 0.45); // (inside)
	}
	c *= mix(0.72, 1.1, shell) * (shell > 0.0 ? 1.0 : 0.85); // (the fur's depth: darker at its roots, lighter at its tips)
	ALBEDO = c;
	ROUGHNESS = 0.95;
	RIM = 0.7;
	RIM_TINT = 0.6;
	SPECULAR = 0.2;
}
