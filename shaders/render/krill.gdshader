shader_type spatial;
render_mode cull_disabled;

// Antarctic krill (Krill): every one an instance of one mesh, posed here in
// the vertex shader (as the ants and mollies are), from the clock and its
// own four numbers, so a swarm of hundreds is a draw call; the CPU only
// moves each along. INSTANCE_CUSTOM: x how fast it swims (0..1), y how far
// into feeding (0..1: its basket working), z its own random 0..1 (its
// beat's phase), w its tail flicked under (0..1: its escape).
//
// The mesh (Krill.build_mesh) at rest, life size, in metres, facing -z.
// CUSTOM0: x the part (0 the body, 1 an eye, 2 a swimmeret, 3 a thoracic
// leg, 4 an antenna, 5 a photophore, 6 the tail fan), y the way out along
// its limb (0 its base .. 1 its tip), z its index (a swimmeret's, a leg's:
// 0 .. 1 from the front); UV its limb's base (z, y).
// - the swimmerets beating, always (krill swim all the time to stay up),
//   in a wave from the back pair to the front, faster swimming
// - the thoracic legs: folded under, still; feeding, thrown forward and
//   open, swept back shut, again and again (the basket)
// - the antennae trailing, swaying
// - the abdomen and tail fan flicked under: the escape

uniform float z_hinge = -0.003;
uniform float z_tail = 0.025;
uniform vec3 shell : source_color = vec3(0.9, 0.42, 0.34);
uniform vec3 fleck : source_color = vec3(0.72, 0.06, 0.04);
uniform vec3 gut : source_color = vec3(0.35, 0.6, 0.18);
uniform vec3 limb : source_color = vec3(0.94, 0.52, 0.42);
uniform vec3 glow : source_color = vec3(0.3, 0.9, 1.0);
global uniform float night;

varying float v_part;
varying vec3 v_rest;
varying float v_out;

void rot(inout vec3 v, inout vec3 n, vec3 o, vec3 axis, float a) {
	vec3 k = normalize(axis);
	float c = cos(a);
	float s = sin(a);
	vec3 p = v - o;
	v = o + p * c + cross(k, p) * s + k * dot(k, p) * (1.0 - c);
	n = n * c + cross(k, n) * s + k * dot(k, n) * (1.0 - c);
}

float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }

void vertex() {
	int part = int(round(CUSTOM0.x));
	float out_ = CUSTOM0.y;
	float idx = CUSTOM0.z;
	vec2 base = UV;
	float swim = INSTANCE_CUSTOM.x;
	float feed = INSTANCE_CUSTOM.y;
	float t = TIME + INSTANCE_CUSTOM.z * 37.0;
	float curl = INSTANCE_CUSTOM.w;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	v_rest = VERTEX;
	v_part = float(part);
	v_out = out_;
	if (part == 2) { // (a swimmeret: its beat, a wave from the back pair forward)
		float ph = t * mix(9.0, 15.0, swim) + idx * 2.4;
		rot(v, n, vec3(v.x, base.y, base.x), vec3(1.0, 0.0, 0.0), (0.55 + 0.25 * swim) * sin(ph) * out_);
	}
	if (part == 3) { // (a thoracic leg: still, or the basket: thrown forward, swept back)
		float sweep = 0.5 + 0.5 * sin(t * 4.0 - idx * 1.5);
		rot(v, n, vec3(v.x, base.y, base.x), vec3(1.0, 0.0, 0.0), feed * (-0.9 * sweep) * out_);
	}
	if (part == 4) { // (the antennae, trailing, swaying)
		rot(v, n, vec3(v.x, base.y, base.x), vec3(0.0, 1.0, 0.0), 0.12 * sin(t * 0.9 + idx * 2.0) * out_);
	}
	// the escape: the abdomen and the fan flicked under, about its hinge,
	// more toward the tail
	if (curl > 0.0 && v_rest.z > z_hinge) {
		float along = clamp((v_rest.z - z_hinge) / (z_tail - z_hinge), 0.0, 1.0);
		rot(v, n, vec3(0.0, 0.0, z_hinge), vec3(1.0, 0.0, 0.0), -curl * 1.3 * along);
	}
	VERTEX = v;
	NORMAL = n;
}

void fragment() {
	int part = int(round(v_part));
	vec3 c = shell;
	float rough = 0.35;
	vec3 emit = vec3(0.0);
	if (part == 1) {
		c = vec3(0.02);
		rough = 0.1;
	} else if (part == 5) {
		c = mix(shell, glow, 0.5);
		emit = glow * mix(0.6, 3.0, night);
	} else if (part == 2 || part == 3 || part == 4) {
		c = mix(limb, fleck, 0.25 * step(0.78, h3(floor(v_rest * 2500.0))));
	} else {
		// the red flecks (chromatophores), scattered, thicker on the back
		// (small round flecks, a few to a cell of half a millimetre)
		vec3 q = v_rest * 2200.0;
		vec3 cq = fract(q) - 0.5;
		float f = step(0.66 - 0.12 * smoothstep(0.0, 0.003, v_rest.y), h3(floor(q))) * (1.0 - smoothstep(0.22, 0.34, length(cq)));
		c = mix(shell, fleck, f * 0.85);
		// the gut showing green through the carapace, behind the head
		float g = smoothstep(-0.019, -0.016, v_rest.z) * (1.0 - smoothstep(-0.008, -0.005, v_rest.z)) * smoothstep(0.0, 0.002, v_rest.y);
		c = mix(c, gut, g * 0.75);
		if (part == 6) c = mix(shell, fleck, 0.35);
	}
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.5;
	EMISSION = emit;
	// (see-through: a soft rim of light round it)
	RIM = 0.4;
	RIM_TINT = 0.5;
}
