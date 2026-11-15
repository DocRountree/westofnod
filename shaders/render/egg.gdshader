shader_type spatial;
// A bird's egg (Raptor._make_egg, and held: Items): its ground colour, its
// blotches (noise), its fine speckles (a turkey's); narrower toward its
// small end (+y).

uniform vec3 ground : source_color = vec3(0.93, 0.92, 0.86);
uniform vec3 blotch : source_color = vec3(0.93, 0.92, 0.86);
uniform float speckle = 0.0;  // (fine dots, a turkey's: how many)
uniform float half_len = 0.03; // (m: half its length, its small end's taper)
varying vec3 p;

float hash(vec3 q) { return fract(sin(dot(q, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 q) { vec3 i = floor(q); vec3 f = fract(q); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z); }

void vertex() {
	p = VERTEX;
	VERTEX.xz *= 1.0 - 0.15 * smoothstep(0.0, half_len, VERTEX.y);
}

void fragment() {
	float n = noise(p * 160.0) * 0.6 + noise(p * 420.0) * 0.4;
	float b = smoothstep(0.5, 0.62, n) * float(length(blotch - ground) > 0.05) * (1.0 - speckle);
	vec3 c = mix(ground, blotch, b);
	if (speckle > 0.0) {
		vec3 q = p * 700.0;
		float s = 0.0;
		for (int i = 0; i < 2; i++) {
			vec3 g = floor(q);
			float d = length(fract(q) - 0.5 - 0.3 * (vec3(hash(g), hash(g + 3.1), hash(g + 7.7)) - 0.5));
			s = max(s, (1.0 - smoothstep(0.08, 0.22, d)) * step(0.45, hash(g + 1.3)));
			q *= 0.55;
		}
		c = mix(c, blotch, s * 0.8 * speckle);
	}
	ALBEDO = c;
	ROUGHNESS = 0.55;
}
