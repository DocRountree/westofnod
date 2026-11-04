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
// their funiculi, 15 its eyes; 8-13 the legs, 14 the gaster; 17/18 marks
// on the body or the shell, mark_a's and mark_b's colours (a lady beetle's
// spots, its pronotum's white), 19/20 the same on the head; a beetle's
// flying parts: 21/22 its wing cases (elytra, left and right: the shell's
// colour; closed, the two halves of one dome, unbroken), 23/24 marks on
// them (mark_a), 25/26 its hind wings (folded away under the elytra, not
// drawn, till it flies)), .y a leg's
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
// - flying (a beetle: INSTANCE_CUSTOM.w, 0..1): the elytra raised and
//   spread (elytra_open: roll out, pitch up, yaw out, rad), the hind wings
//   unfolding from under them and beating (fly_hz; drawn stippled, a blur),
//   the legs tucked (fly_tuck: back, in)

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
uniform float iridescence = 1.0; // how far the shell goes to shell_b at a glance
uniform float shell_metal = 0.75; // (a dogbane beetle's metallic; a June bug's, a lady beetle's lacquered: 0)
uniform float shell_gloss = 0.9;
uniform vec3 mark_a : source_color = vec3(0.02);
uniform vec3 mark_b : source_color = vec3(0.9, 0.88, 0.84);
uniform float sweep = 1.0;
// the cuticle: rugose (0 smooth .. 1: the head and the mesosoma finely
// ridged lengthwise, a harvester's), the gaster's own tint and gloss
uniform float rugose = 0.0;
uniform vec3 gaster_tint = vec3(1.0);
uniform float gaster_gloss = 0.45;
uniform vec3 elytra_pivots[2]; // their hinges, at their bases
uniform vec3 wing_pivots[2];
uniform vec3 elytra_open = vec3(0.9, -0.35, 0.3);
uniform vec2 fly_tuck = vec2(0.7, 0.5);
uniform float fly_hz = 22.0; // (drawn: a real beat's too fast to see)
uniform vec3 wing_color : source_color = vec3(0.45, 0.35, 0.25); // how much the antennae sweep and drum (an ant's 1)

varying flat int part;
varying vec3 rest; // where it is on the ant at rest (m): for its sculpture
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
	rest = VERTEX;
	int seg = int(round(CUSTOM0.y));
	band_z = CUSTOM0.z;
	banded = CUSTOM0.w;
	float walk = INSTANCE_CUSTOM.x;
	float feed = INSTANCE_CUSTOM.y;
	float seed = INSTANCE_CUSTOM.z;
	float fly = INSTANCE_CUSTOM.w;
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
		// flying: drawn back and in under the body
		if (fly > 0.0) {
			turn(v, n, hips[i], vec3(1.0, 0.0, 0.0), -fly_tuck.x * fly);
			turn(v, n, hips[i], vec3(0.0, 0.0, 1.0), -fly_tuck.y * fly * side);
		}
	}
	// a beetle's flight: the elytra up and out, the hind wings out and beating
	float beat = smoothstep(0.6, 1.0, fly);
	float fph = t * fly_hz * 6.2832;
	if (part >= 21 && part <= 24) {
		int s = (part - 21) % 2;
		float side = s == 1 ? 1.0 : -1.0;
		vec3 o = elytra_pivots[s];
		float shiver = 0.04 * beat * sin(fph + 0.6); // (shaken by the wings' beat)
		turn(v, n, o, vec3(0.0, 0.0, 1.0), (elytra_open.x * fly + shiver) * side);
		turn(v, n, o, vec3(1.0, 0.0, 0.0), elytra_open.y * fly);
		turn(v, n, o, up, elytra_open.z * fly * side);
	}
	if (part == 25 || part == 26) {
		int s = part - 25;
		float side = s == 1 ? 1.0 : -1.0;
		vec3 o = wing_pivots[s];
		// unfolding: out from under the elytra (grown from the hinge)
		float unfold = smoothstep(0.25, 0.85, fly);
		v = o + (v - o) * vec3(unfold, 1.0, mix(0.3, 1.0, unfold));
		// beating: up and down through a wide stroke, twisting
		float stroke = beat * (0.25 + 0.95 * sin(fph));
		turn(v, n, o, vec3(1.0, 0.0, 0.0), 0.3 * beat * cos(fph));
		turn(v, n, o, vec3(0.0, 0.0, 1.0), stroke * side);
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
	if ((part >= 1 && part <= 7) || part == 15 || part == 19 || part == 20) {
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
	if (part == 14) {
		c *= gaster_tint;
		gloss = gaster_gloss;
	}
	if (rugose > 0.0 && (part == 0 || part == 1)) {
		// fine ridges running lengthwise, wavering, fading where they'd
		// be finer than a pixel
		float k = rest.x * 22000.0 + sin(rest.z * 5000.0) * 1.2 + sin(rest.y * 9000.0) * 0.6;
		float fade = clamp(1.0 - fwidth(k) / 2.5, 0.0, 1.0);
		c *= 1.0 - rugose * 0.3 * fade * (0.5 + 0.5 * sin(k));
		gloss = mix(gloss, 0.2, rugose);
	}
	if (banded > 0.5) // (the gaster's segments edged with their fine golden hairs)
		c = mix(c, band_color, smoothstep(0.33, 0.37, band_z));
	float metal = 0.0;
	if (part == 16) {
		float glance = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		c = mix(shell_a, shell_b, smoothstep(0.15, 0.85, glance) * iridescence);
		gloss = shell_gloss;
		metal = shell_metal;
	}
	if (part == 21 || part == 22) { // (the elytra: the shell's, as 16)
		float glance = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		c = mix(shell_a, shell_b, smoothstep(0.15, 0.85, glance) * iridescence);
		gloss = shell_gloss;
		metal = shell_metal;
	}
	if ((part >= 17 && part <= 20) || part == 23 || part == 24) {
		c = (part == 17 || part == 19 || part >= 23) ? mark_a : mark_b;
		gloss = shell_gloss;
	}
	if (part == 25 || part == 26) {
		// the hind wings: thin, brownish, see-through; beating, a blur
		// (stippled: half the pixels gone)
		ivec2 q = ivec2(mod(FRAGCOORD.xy, 4.0));
		int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
		if ((float(m[q.x + q.y * 4]) + 0.5) / 16.0 > 0.45)
			discard;
		c = wing_color;
		gloss = 0.8;
	}
	ALBEDO = c;
	METALLIC = metal;
	ROUGHNESS = mix(0.7, 0.18, gloss);
	SPECULAR = mix(0.4, 0.7, gloss);
}
