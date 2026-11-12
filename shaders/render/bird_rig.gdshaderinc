// A bird's joints, in the vertex shader (Bird; docs/birds.md): one layout
// for every bird, no Skeleton3D.
//
// The body's chain (its trunk, four neck joints, its head, its lower bill,
// its tail, each leg's thigh, shin, tarsus and toes: 16 joints) comes from
// the bird's motor as skin matrices (jm: three rows each), and a vertex
// follows one or two of them. The wings are worked out here, from four
// numbers each (wing[0] the left's, wing[1] the right's: how far raised,
// swept back, twisted, and spread: 0 folded .. 1 full): a wing's elbow and
// wrist fold together, as a real wing's do, so one number folds it; its
// flight feathers are cards rooted along its bones, swinging from "all
// pointing back, stacked" (folded) out to their own angle in the spread
// fan. The tail's feathers fan about its joint the same way (tail_spread).
//
// A vertex says which (CUSTOM1.x): 0 the chain's (.y, .z its joints, .w
// the second's share); 1 a wing's own surface (.y its bone: 0 upper arm, 1
// forearm, 2 hand; .z its side: -1 left, 1 right; CUSTOM2: along its bone,
// back from it, above it, m); 2 a wing feather (.y its bone, .z its side,
// .w its angle out from "back" in the spread fan, rad; CUSTOM2: its root
// along the bone, along the feather, across it, above it, m); 3 a tail
// feather (.w its place across the fan, -1 .. 1; .y how much of the spread
// it takes; CUSTOM2 as a wing feather's: its root's reach, along, across,
// above).

uniform vec4 jm[48];
uniform vec4 wing[2];
uniform vec3 shoulder;      // the right wing's root (the body at rest, m)
uniform vec3 wing_len;      // its bones' lengths
uniform vec3 tail_at;       // the tail's joint at rest
uniform float tail_spread = 0.2; // rad: the outermost feather's angle out
uniform float tail_arch = 0.0;   // the fan cupped forward (a strutting tom's)
uniform float feather_load = 0.0; // the flight feathers bent up by the air
uniform float wing_droop = 0.0;  // the primaries let down (strutting: dragging)
uniform float fold_chord = 0.3;  // folded, how much of its arm's and hand's coverts still show
uniform float fold_pitch = 0.0;
uniform float fold_tuck = 0.0; // folded, its tips drawn in toward each other over its tail (rad)
uniform vec3 fold_fan = vec3(0.0); // folded, each bone's feathers (tertials, secondaries, primaries) fanned down over the flank (rad)  // folded, the wing tipped down along the back (an upright bird's: a hawk's)

mat4 joint(int i) {
	vec4 a = jm[i * 3];
	vec4 b = jm[i * 3 + 1];
	vec4 c = jm[i * 3 + 2];
	return mat4(vec4(a.x, b.x, c.x, 0.0), vec4(a.y, b.y, c.y, 0.0), vec4(a.z, b.z, c.z, 0.0), vec4(a.w, b.w, c.w, 1.0));
}

mat3 rot_x(float a) { float c = cos(a), s = sin(a); return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c)); }
mat3 rot_y(float a) { float c = cos(a), s = sin(a); return mat3(vec3(c, 0.0, -s), vec3(0.0, 1.0, 0.0), vec3(s, 0.0, c)); }
mat3 rot_z(float a) { float c = cos(a), s = sin(a); return mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0)); }

// a wing bone's angle in the wing's own plane (from straight out, toward the tail)
float bone_angle(int k, float e) {
	if (k == 0) return mix(1.35, 0.17, e);
	if (k == 1) return mix(-1.25, -0.14, e);
	return mix(1.42, 0.3, e);
}

vec3 bone_root(int k, float e) {
	vec3 o = vec3(0.0);
	if (k >= 1) { float a = bone_angle(0, e); o += vec3(cos(a), 0.0, sin(a)) * wing_len.x; }
	if (k >= 2) { float a = bone_angle(1, e); o += vec3(cos(a), 0.0, sin(a)) * wing_len.y; }
	return o;
}

// The vertex and its normal, posed (the bird's own space).
void bird_pose(vec4 c1, vec4 c2, inout vec3 v, inout vec3 n) {
	int kind = int(round(c1.x));
	if (kind == 0) {
		mat4 a = joint(int(round(c1.y)));
		mat4 b = joint(int(round(c1.z)));
		vec3 va = (a * vec4(v, 1.0)).xyz;
		vec3 vb = (b * vec4(v, 1.0)).xyz;
		v = mix(va, vb, c1.w);
		n = normalize(mix(mat3(a) * n, mat3(b) * n, c1.w));
		return;
	}
	if (kind == 3) {
		float ang = c1.w * tail_spread * c1.y;
		vec3 along = vec3(sin(ang), 0.0, cos(ang));
		vec3 across = vec3(cos(ang), 0.0, -sin(ang));
		vec3 up = vec3(0.0, 1.0, 0.0);
		// (cupped: the outer feathers leaning forward)
		float lean = tail_arch * abs(c1.w) * c1.y;
		along = normalize(along + up * lean);
		// (closed: the feathers pitched like a roof, the outer ones lower)
		float tent = 0.55 * (1.0 - smoothstep(0.25, 0.9, tail_spread));
		across = normalize(across - up * tent * c1.w);
		up = normalize(cross(along, across));
		if (up.y < 0.0) up = -up;
		c2.w -= tent * abs(c1.w) * 0.02;
		vec3 p = along * (c2.x + c2.y) + across * c2.z + up * c2.w;
		vec3 nn = across * n.x + up * n.y + along * n.z;
		mat4 t = joint(7);
		v = (t * vec4(tail_at + p, 1.0)).xyz;
		n = normalize(mat3(t) * nn);
		return;
	}
	float side = c1.z;
	vec4 w = side < 0.0 ? wing[0] : wing[1];
	float e = clamp(w.w, 0.0, 1.0);
	int k = int(round(c1.y));
	float a = bone_angle(k, e);
	vec3 dir = vec3(cos(a), 0.0, sin(a));
	vec3 perp = vec3(-sin(a), 0.0, cos(a));
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 q;
	vec3 nn;
	if (kind == 1) {
		// (folded, the upper arm's and the hand's coverts drawn in: the forearm's are the folded wing's face)
		float chord = c2.y * (k == 1 ? 1.0 : mix(fold_chord, 1.0, e));
		q = bone_root(k, e) + dir * c2.x + perp * chord + up * c2.z;
		nn = dir * n.x + up * n.y + perp * n.z;
	} else {
		// a flight feather: from pointing back, stacked (folded), out to
		// its own angle in the fan; bent up toward its tip by the air; the
		// primaries let down, strutting
		float th = mix(1.5708 + 0.05 * c1.w - fold_fan[k], 1.5708 - c1.w, smoothstep(0.0, 1.0, e));
		vec3 along = vec3(cos(th), 0.0, sin(th));
		vec3 across = vec3(sin(th), 0.0, -cos(th));
		float l = c2.y;
		float bend = feather_load * l * l * 1.6 - wing_droop * (k == 2 ? 1.0 : 0.25) * l * 0.9;
		q = bone_root(k, e) + dir * c2.x + along * l + across * c2.z + up * (c2.w + bend);
		nn = across * n.x + up * n.y + along * n.z;
	}
	mat3 r = rot_y(-fold_tuck * (1.0 - e)) * rot_x(fold_pitch * (1.0 - e)) * rot_y(-w.y) * rot_z(w.x) * rot_x(w.z); // (swept about the body's upright: back in flight, its tip tucked in, folded)
	q = r * q;
	nn = r * nn;
	q.x *= side;
	nn.x *= side;
	mat4 body = joint(0);
	v = (body * vec4(vec3(shoulder.x * side, shoulder.y, shoulder.z) + q, 1.0)).xyz;
	n = normalize(mat3(body) * nn);
}
