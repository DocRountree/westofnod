shader_type spatial;

// Ants (AntColony), and beetles (Beetles: the same parts, their own shapes
// and colours): every ant one instance of one mesh, posed here, in the
// vertex shader, from the clock and its own few numbers (INSTANCE_CUSTOM:
// x how fast it walks, 0..1; y how far into feeding, 0..1; z its own
// random 0..1, its gait's and its twitches' phase), so a colony costs a
// draw call; the CPU only moves each ant along.
//
// The mesh (AntColony.build_mesh) standing at rest, in metres, the thorax's
// middle at the origin, facing -z; CUSTOM0.x which part a vertex is of (0
// the body, 16 a shell over it (metallic: a beetle's); 1 the head, 2/3 its mandibles, 4/5 its antennae's scapes, 6/7
// their funiculi, 15 its eyes; 8-13 the legs, 14 the gaster), .y a leg's
// segment (0 coxa, 1 femur, 2 tibia, 3 tarsus), .z along an ellipsoid
// (-0.5 front .. 0.5 behind: the gaster's bands), .w 1 where it's banded.
// Each part turns about its joint (the pivots: uniforms, from the same
// build), the head's on the head as it turns:
// - walking: a tripod gait (two sets of three legs, each set swinging
//   forward lifted, knee bent, while the other sweeps back on the ground),
//   its rate and stride by its speed; the antennae sweeping ahead, left and
//   right in turn, dabbing down; the head bobbing
// - feeding: the head down, the mandibles working, the antennae drumming,
//   the front legs up and forward on the food, the gaster pumping

uniform vec3 hips[6];      // each leg's coxa, at the body
uniform vec3 knees[6];
uniform vec3 leg_dirs[6];  // across the ground from its hip to its foot
uniform vec3 sockets[2];   // the antennae's at the head
uniform vec3 elbows[2];    // between scape and funiculus
uniform vec3 mand_pivots[2];
uniform vec3 neck;
uniform vec3 petiole;      // the gaster's joint
uniform float stride_hz = 7.0; // steps a second (of each set) at full speed
uniform vec3 black : source_color = vec3(0.045, 0.038, 0.034);
uniform vec3 leg_color : source_color = vec3(0.1, 0.055, 0.04);
uniform vec3 band_color : source_color = vec3(0.36, 0.28, 0.16);
// a shell (part 16: a beetle's pronotum and wing cases), metallic, its
// colour going from shell_a facing you to shell_b at a glance (iridescent)
uniform vec3 shell_a : source_color = vec3(0.1, 0.45, 0.4);
uniform vec3 shell_b : source_color = vec3(0.75, 0.32, 0.1);
uniform float sweep = 1.0; // how much the antennae sweep and drum (an ant's 1)

varying flat int part;
varying float band_z;
varying flat float banded;

vec3 rot(vec3 v, vec3 a, float ang) {
	float c = cos(ang), s = sin(ang);
	return v * c + cross(a, v) * s + a * dot(a, v) * (1.0 - c);
}

// v (and its normal n) turned by ang about the axis a through pivot o
void turn(inout vec3 v, inout vec3 n, vec3 o, vec3 a, float ang) {
	v = rot(v - o, a, ang) + o;
	n = rot(n, a, ang);
}

void vertex() {
	part = int(round(CUSTOM0.x));
	int seg = int(round(CUSTOM0.y));
	band_z = CUSTOM0.z;
	banded = CUSTOM0.w;
	float walk = INSTANCE_CUSTOM.x;
	float feed = INSTANCE_CUSTOM.y;
	float seed = INSTANCE_CUSTOM.z;
	float t = TIME + seed * 37.0;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	vec3 up = vec3(0.0, 1.0, 0.0);
	// the legs
	if (part >= 8 && part <= 13) {
		int i = part - 8;
		float side = i % 2 == 1 ? 1.0 : -1.0;
		int pair = i / 2;
		bool first_set = i == 0 || i == 3 || i == 4;
		float p = fract(t * stride_hz * mix(0.55, 1.0, walk) + (first_set ? 0.0 : 0.5));
		float a = 0.3 * walk;
		float sw = clamp(p * 2.0, 0.0, 1.0);
		float ang = p < 0.5 ? mix(-a, a, smoothstep(0.0, 1.0, sw)) : mix(a, -a, (p - 0.5) * 2.0);
		float lift = p < 0.5 ? sin(PI * sw) * walk : 0.0;
		// (the hind legs reach back, the front forward: each its own way)
		if (pair == 0) {
			ang += 0.4 * feed;
			lift += 0.6 * feed + 0.15 * feed * sin(t * 9.0 + side);
		}
		vec3 across = normalize(cross(up, leg_dirs[i]));
		if (seg >= 2) // (the knee bent as it lifts)
			turn(v, n, knees[i], across, -0.6 * lift);
		turn(v, n, hips[i], across, -0.3 * lift);
		turn(v, n, hips[i], up, ang * side);
	}
	// the antennae: the funiculus about its elbow, then the whole about its socket
	if (part >= 4 && part <= 7) {
		int s = (part - 4) % 2;
		float side = s == 1 ? 1.0 : -1.0;
		float ph = t * 9.5 + (s == 1 ? PI : 0.0);
		float twitch = 0.12 * sin(t * 3.1 + seed * 20.0 + float(s) * 2.3) + 0.08 * sin(t * 7.3 + float(s));
		float yaw = 0.3 * sweep * walk * sin(ph) + twitch * (1.0 - walk);
		float pitch = -sweep * walk * (0.15 + 0.2 * max(sin(ph + 1.2), 0.0)) - 0.35 * feed + twitch * 0.6;
		if (part >= 6) // (dabbing, drumming)
			turn(v, n, elbows[s], vec3(1.0, 0.0, 0.0), -0.4 * sweep * feed * (0.5 + 0.5 * sin(t * 34.0 + float(s) * 1.7)) - 0.15 * walk * max(sin(ph + 2.0), 0.0));
		turn(v, n, sockets[s], vec3(1.0, 0.0, 0.0), pitch);
		turn(v, n, sockets[s], up, yaw * side);
	}
	// the mandibles: working as it feeds
	if (part == 2 || part == 3) {
		float side = part == 3 ? 1.0 : -1.0;
		float open = feed * (0.5 + 0.5 * sin(t * 22.0));
		turn(v, n, mand_pivots[part - 2], up, -0.55 * open * side);
	}
	// the head and all on it: down to the food, nodding as it chews; bobbing as it walks
	if ((part >= 1 && part <= 7) || part == 15) {
		float pitch = -0.4 * feed + 0.06 * feed * sin(t * 16.0) + 0.04 * walk * sin(t * stride_hz * 6.2832 * 2.0);
		turn(v, n, neck, vec3(1.0, 0.0, 0.0), pitch);
		turn(v, n, neck, up, 0.08 * walk * sin(t * 2.7));
	}
	// the gaster: pumping as it feeds
	if (part == 14)
		turn(v, n, petiole, vec3(1.0, 0.0, 0.0), 0.05 * feed * sin(t * 7.0) + 0.03 * sin(t * 1.3));
	// the body bobbing with its steps
	v.y += 0.00012 * walk * sin(t * stride_hz * 6.2832 * 2.0);
	VERTEX = v;
	NORMAL = normalize(n);
}

void fragment() {
	vec3 c = black;
	float gloss = 0.45;
	if (part >= 6 && part <= 13)
		c = leg_color;
	if (part == 2 || part == 3)
		c = vec3(0.12, 0.06, 0.04);
	if (part == 15) {
		c = vec3(0.03);
		gloss = 1.0;
	}
	if (banded > 0.5) // (the gaster's segments edged with their fine golden hairs)
		c = mix(c, band_color, smoothstep(0.33, 0.37, band_z));
	float metal = 0.0;
	if (part == 16) {
		float glance = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		c = mix(shell_a, shell_b, smoothstep(0.15, 0.85, glance));
		gloss = 0.9;
		metal = 0.75;
	}
	ALBEDO = c;
	METALLIC = metal;
	ROUGHNESS = mix(0.7, 0.18, gloss);
	SPECULAR = mix(0.4, 0.7, gloss);
}
