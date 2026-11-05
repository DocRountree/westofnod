class_name Turtle
extends Node3D
## An eastern box turtle (Terrapene carolina carolina), drawn at twice life
## size (modelled at life size, its shell about 14 cm long: MM), on a
## species' make (SPEC: SnappingTurtle has its own). Built from parts,
## posed every frame by hand (procedural: no clips).
##
## Its shell high and domed, a low keel down its middle, its rim flared a
## little behind: brown, each scute marked from its growth centre with
## radiating yellow and orange streaks and blotches, its growth rings fine;
## its plastron beneath hinged across, two lobes, tan with dark smudges: it
## shuts its shell tight, head, legs and tail in, both lobes pulled up
## against the carapace (withdraw()). Its head with a hooked upper beak;
## its skin dark brown, spotted orange and yellow (thickest on its head,
## neck and forelegs, their big scales); a male's eyes red, a female's
## brown; his hind claws thick and curved, his tail longer. Its feet
## stumpy, hardly webbed. A hatchling (Turtle.new(true)): small, its shell
## flatter, plainer; growing.
##
## What it does (each a method; its own ways when told none):
## - wander(centre, radius): walking slowly over the forest floor, stopping,
##   its head out and turning, on
## - bask(at): to a patch of sun, its legs stretched out behind, its neck up,
##   still
## - dive(): (soak) into the water (a puddle, a pond's shallows), sat in it
##   half under a while, out again
## - withdraw(): its alarm: head, legs and tail in, its shell shut
## - eat(food) (Turtle.food_of(): a mushroom, Turtle.weed_of(), a fly:
##   Frog.fly_of()): to it, its head down, bites torn off and gulped, gone
## - mate(her): (a male's) after her, nudging and biting at the rim of her
##   shell from behind; up onto her from behind, his hind claws hooked in
##   her plastron (she clamps them), leaning back till he's near upright;
##   then off, down
## - nest(): (a female's) to the bank, a hole dug with her hind feet, one
##   then the other; her eggs laid in it (Nest: leathery white, oval), the
##   earth pushed back over them and pressed down; off. hatch() (or a while
##   after) the hatchlings up out of it and away
##
## Its world: water_y (the water's surface), floor_y (its floor), pond
## (centre, half extents x, z: the water), height (the ground's y at x, z,
## outside it), bank (a point to nest at), basks (points: sunny spots).
## Steering (pilot.gd): go, go_to, face, stop, act (wander {centre, radius},
## bask {at}, dive, hide, eat {food}, mate {partner}, nest), behaviours,
## is_busy, action_finished.
## Its position is set every frame: put it under a node that isn't moved.

signal action_finished(name: String, ok: bool)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const MM := 0.002 ## m drawn per model mm (twice life size)

## The box turtle's make (mm, life size; x right, y up, z back; y 0 its
## plastron's underside):
const BOX := {
	"aquatic": false,
	# its carapace: length, width, height (its dome's top), the rim (its
	# marginals' edge, up from the plastron), the dome's shape [p, q], the
	# rear's flare (out, up), the front's notch, the rear's teeth, keels
	# [[x (of its half width), mm]], knobs (on its scutes), the lip (its
	# rim's thickness)
	"shell": {"len": 140.0, "wid": 104.0, "ht": 70.0, "rim": 15.0, "dome": [2.3, 0.55], "flare": [6.0, 4.0],
			"notch": 3.0, "teeth": 0.0, "keels": [[0.0, 3.0]], "knobs": 0.0, "lip": 4.0},
	# its plastron: hinged (two lobes) or a cross; how wide (of the shell's)
	"plastron": {"hinge": true, "cross": false, "wid": 0.4, "th": 5.0, "hinge_z": -16.0},
	# colours: the shell's ground, its streaks, its seams; the plastron's, its
	# smudges; the skin's, its spots (how many), beneath; the eyes (his, hers)
	"col": {"shell": Color(0.28, 0.18, 0.08), "ray": Color(0.86, 0.6, 0.16), "seam": Color(0.13, 0.08, 0.04),
			"plast": Color(0.66, 0.52, 0.26), "smudge": Color(0.2, 0.13, 0.06),
			"skin": Color(0.16, 0.11, 0.07), "spot": Color(0.9, 0.5, 0.12), "spots": 0.55, "under": Color(0.5, 0.36, 0.2),
			"eye_m": Color(0.78, 0.16, 0.06), "eye_f": Color(0.4, 0.24, 0.1), "algae": 0.0, "rays": 1.0, "bumps": 0.25},
	# its head (sections [z, half width, top, bottom] from its beak's tip back),
	# its jaw's, its eyes (at, radius); the neck (its root, in and out, its girth)
	"head": [[-34.0, 1.2, 3.0, -5.6], [-32.0, 4.2, 5.6, -5.0], [-27.0, 7.6, 8.2, -5.4], [-19.0, 10.2, 9.8, -6.0], [-10.0, 11.0, 10.0, -6.4], [0.0, 9.6, 8.6, -6.4]],
	"jaw": [[-31.0, 2.5, -4.6, -7.0], [-26.0, 6.4, -4.6, -8.4], [-16.0, 9.2, -5.2, -8.8], [-6.0, 9.4, -5.4, -7.6]],
	"jaw_at": Vector3(0.0, -1.0, -4.0),
	"eye": [Vector3(8.0, 4.4, -22.0), 3.4],
	"neck": {"root": Vector3(0.0, 20.0, -40.0), "in": Vector3(0.0, 17.0, -32.0), "out": Vector3(0.0, 21.0, -66.0), "reach": 22.0, "r": 9.0},
	# its legs: the hips (fore, hind), the reach out, the legs' girth, the feet,
	# the claws (how many, how long; a male's hind claws), how far it draws them in
	"fore": Vector3(33.0, 15.0, -40.0), "hind": Vector3(31.0, 13.0, 42.0),
	"leg_r": 9.0, "reach": 10.0, "foot": 8.0, "claws": 4, "claw": 5.0, "claw_m_hind": 8.0, "claw_m_fore": 5.0, "draw_in": 1.0,
	"stand": 6.0, # (its plastron up off the ground, walking)
	"tail": {"at": Vector3(0.0, 12.0, 62.0), "len": 14.0, "len_m": 24.0, "r": 5.0, "crest": 0},
	"young_size": 0.22, "walk": 0.02, "swim": 0.0,
}

var male := false
var young := false
var size := 1.0
var height: Callable
var water_y := 0.0
var floor_y := -0.3
var pond := [Vector3.ZERO, Vector2(0.6, 0.5)]
var bank := Vector3.INF
var basks: Array = []
var nests: Array[Node3D] = []
var S: Dictionary

var _pos := Vector3.ZERO
var _yaw := 0.0
var _pitch := 0.0
var _roll := 0.0
var _pivot_z := 0.0 # (mm: the point its pitch turns about, along it)
var _lift := 0.0 # (m: raised off the ground, mounted)
var _t := 0.0
var _st := 0.0
var _wait := 0.0
var _mode := "wander"
var _stage := 0
var _centre := Vector3.ZERO
var _radius := 0.4
var _target := Vector3.ZERO
var _speed := 0.0
var _depth := 0.0 # (in the water: how far under the surface, m)
var _depth_to := 0.0
var _neck := 0.0 # (0 in .. 1 out .. 1.6 stretched / shot out)
var _neck_to := 1.0
var _neck_rate := 2.0
var _limbs := 1.0 # (0 pulled in .. 1 out)
var _limbs_to := 1.0
var _jaw := 0.0
var _jaw_to := 0.0
var _dig := 0.0
var _rear := 0.0 # (up on its legs: a snapper's threat)
var _look := 0.0
var _food: Node3D
var _mate: Turtle
var _role := ""
var _mate_len := 12.0 # (how long a mating lasts, s)
var _pilot: PilotScript
var _piloting := false
var rng := RandomNumberGenerator.new()
# the parts
var _body: Node3D
var _shell_n: Node3D
var _head: Node3D
var _neck_n: Node3D
var _neck_mi: MeshInstance3D
var _jaw_n: Node3D
var _front_lobe: Node3D
var _rear_lobe: Node3D
var _legs: Array = [] # [hip, upper, lower, foot, fore?, side, claws]
var _tail_n: Node3D
var _tail_mi: MeshInstance3D
var _skin: ShaderMaterial

static var _sphere: SphereMesh
static var _shell_sh: Shader
static var _skin_sh: Shader
static var _limbs_m := {} # (taper -> mesh)


func _spec() -> Dictionary:
	return BOX


func _init(young_ := false) -> void:
	young = young_
	S = _spec()
	size = float(S.young_size) if young_ else 1.0
	rng.randomize()


func _ready() -> void:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 16
		_sphere.rings = 8
	_body = Node3D.new()
	add_child(_body)
	_build()


func place(p: Vector3, yaw := 0.0) -> void:
	_pos = p
	_pos.y = _ground_at(p.x, p.z)
	_yaw = yaw
	_place()


# --- its model ----------------------------------------------------------------

func _mat(c: Color, rough := 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _part(at: Vector3, sz: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	mi.position = at
	mi.scale = sz
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _limb(mat: Material, parent: Node3D, taper := 0.24) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _limb_mesh(taper)
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## A limb's segment from a to b (its parent's mm), r thick (flat: its
## height's share of its width).
static func _seg_to(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float, flat := 1.0) -> void:
	var d := b - a
	var l := maxf(d.length(), 0.01)
	var z := d / l
	var x := z.cross(Vector3.UP if absf(z.y) < 0.9 else Vector3.RIGHT).normalized()
	var y := z.cross(x)
	mi.transform = Transform3D(Basis(x * r * 2.0, y * r * 2.0 * flat, z * (l + r * 0.6)), (a + b) * 0.5)


## A limb's segment (unit: along z from -0.5 to 0.5, 0.5 round): a rounded
## cylinder tapering by taper along it, its ends closed round.
static func _limb_mesh(taper: float) -> ArrayMesh:
	var key := snappedf(taper, 0.01)
	if _limbs_m.has(key):
		return _limbs_m[key]
	const AROUND := 14
	const ALONG := 14
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in ALONG + 1:
		var t := float(i) / ALONG
		var u := t * 2.0 - 1.0
		var r := 0.5 * pow(maxf(1.0 - pow(absf(u), 3.0), 0.0), 1.0 / 3.0) * (1.0 + taper * 0.5 - taper * t)
		for k in AROUND + 1:
			var ph := TAU * float(k) / AROUND
			st.set_uv(Vector2(float(k) / AROUND, t))
			st.add_vertex(Vector3(cos(ph) * r, sin(ph) * r, t - 0.5))
	for i in ALONG:
		for k in AROUND:
			var a := i * (AROUND + 1) + k
			st.add_index(a); st.add_index(a + AROUND + 2); st.add_index(a + 1)
			st.add_index(a); st.add_index(a + AROUND + 1); st.add_index(a + AROUND + 2)
	st.generate_normals()
	var m := st.commit()
	_limbs_m[key] = m
	return m


## A lofted shape through sections [z, half width, top, bottom] (mm, z
## from its front back): each section domed above (pw_top), fuller below
## (pw_bot), its ends closed.
static func _loft(secs: Array, pw_top := 2.0, pw_bot := 2.4, around := 24, along := 20) -> ArrayMesh:
	var at := func(z: float) -> Array:
		var j := 0
		while j < secs.size() - 2 and z > float(secs[j + 1][0]):
			j += 1
		var f := clampf((z - float(secs[j][0])) / (float(secs[j + 1][0]) - float(secs[j][0])), 0.0, 1.0)
		f = f * f * (3.0 - 2.0 * f) * 0.5 + f * 0.5
		var out := []
		for k in 4:
			out.append(lerpf(float(secs[j][k]), float(secs[j + 1][k]), f))
		return out
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z0 := float(secs[0][0])
	var z1 := float(secs[secs.size() - 1][0])
	for i in along + 1:
		var t := float(i) / along
		var sc: Array = at.call(lerpf(z0, z1, t))
		var mid := (float(sc[2]) + float(sc[3])) * 0.5
		var close := 1.0 if i > 0 and i < along else 0.0 # (its ends closed to a point)
		for k in around:
			var ph := TAU * float(k) / around
			var sn := sin(ph)
			var cs := cos(ph)
			var pw := pw_top if cs > 0.0 else pw_bot
			var x := signf(sn) * pow(absf(sn), 2.0 / pw) * float(sc[1]) * close
			var y := mid + signf(cs) * pow(absf(cs), 2.0 / pw) * ((float(sc[2]) - mid) if cs > 0.0 else (mid - float(sc[3])))
			y = lerpf(mid, y, close)
			st.set_uv(Vector2(float(k) / around, t))
			st.add_vertex(Vector3(x, y, float(sc[0])))
	for i in along:
		for k in around:
			var a := i * around + k
			var b := i * around + (k + 1) % around
			var c := (i + 1) * around + (k + 1) % around
			var d := (i + 1) * around + k
			st.add_index(a); st.add_index(b); st.add_index(c)
			st.add_index(a); st.add_index(c); st.add_index(d)
	st.generate_normals()
	return st.commit()


## The carapace's outline at angle a (0 its front, round to its right):
## its radius out (mm) in the plane: an ellipse, wider and flared behind,
## notched in front over its neck, toothed behind (a snapper's).
static func _outline(P: Dictionary, a: float) -> float:
	var hl := float(P.len) * 0.5
	var hw := float(P.wid) * 0.5
	var sa := sin(a)
	var ca := cos(a)
	var r := 1.0 / sqrt(pow(sa / hw, 2.0) + pow(ca / hl, 2.0))
	var back := smoothstep(0.2, -0.8, ca)
	r += float((P.flare as Array)[0]) * back
	var aw := wrapf(a, -PI, PI)
	r -= float(P.notch) * exp(-pow(aw / 0.16, 2.0))
	if float(P.teeth) > 0.0: # (its rear marginals each ending in a point)
		var tri := 1.0 - absf(fposmod(a / TAU * 24.0, 1.0) * 2.0 - 1.0)
		r += float(P.teeth) * pow(tri, 2.0) * smoothstep(-0.1, -0.6, ca)
	return r


## The carapace: its dome over the outline, the keels down it, knobs on its
## scutes; its rim's lip turned under, its underside closed (the body's).
static func _shell_mesh(P: Dictionary) -> ArrayMesh:
	const AROUND := 72
	const RINGS := 22
	var H := float(P.ht)
	var rim := float(P.rim)
	var dome: Array = P.dome
	var hw := float(P.wid) * 0.5
	var hl := float(P.len) * 0.5
	var lip := float(P.lip)
	var cen := _scute_centres()
	var height := func(a: float, r: float) -> Vector3:
		var R := _outline(P, a)
		var x := sin(a) * R * r
		var z := -cos(a) * R * r
		var y := rim + (H - rim) * pow(maxf(1.0 - pow(r, float(dome[0])), 0.0), float(dome[1]))
		var X := x / hw
		var Z := z / hl
		for kl: Array in P.keels:
			for sd: float in ([1.0] if float(kl[0]) == 0.0 else [-1.0, 1.0]):
				y += float(kl[1]) * exp(-pow((X - sd * float(kl[0])) / 0.12, 2.0)) * (1.0 - r * r)
		if float(P.knobs) > 0.0:
			for c: Vector2 in cen:
				y += float(P.knobs) * exp(-((Vector2(X, Z) - Vector2(c.x * 0.9, c.y)).length_squared()) / 0.012) * (1.0 - r * r * 0.6)
		var back := smoothstep(0.2, -0.8, cos(a))
		y += float((P.flare as Array)[1]) * back * smoothstep(0.8, 1.0, r) # (its rim flared up behind)
		return Vector3(x, y, z)
	# rows: the dome (r 0 .. 1), the lip down, under to the body
	var rows: Array = []
	for i in RINGS + 1:
		var r := pow(float(i) / RINGS, 0.8)
		var row: Array = []
		for k in AROUND:
			row.append(height.call(TAU * float(k) / AROUND, r))
		rows.append(row)
	var edge: Array = rows[RINGS]
	for f: float in [0.5, 1.0]: # (the lip: down)
		var row: Array = []
		for k in AROUND:
			var e: Vector3 = edge[k]
			row.append(Vector3(e.x * (1.0 + 0.01 * f), e.y - lip * f, e.z * (1.0 + 0.01 * f)))
		rows.append(row)
	for f: float in [0.9, 0.7, 0.35, 0.0]: # (under: the body's underside, closed)
		var row: Array = []
		for k in AROUND:
			var e: Vector3 = edge[k]
			row.append(Vector3(e.x * f, lerpf(rim * 0.35, e.y - lip, f), e.z * f))
		rows.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: Array in rows:
		for v: Vector3 in row:
			st.add_vertex(v)
	for i in rows.size() - 1:
		for k in AROUND:
			var a := i * AROUND + k
			var b := i * AROUND + (k + 1) % AROUND
			var c := (i + 1) * AROUND + (k + 1) % AROUND
			var d := (i + 1) * AROUND + k
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(a); st.add_index(d); st.add_index(c)
	st.generate_normals()
	return st.commit()


## Its scutes' centres (of the shell's half width, half length: x, z): the
## vertebrals down its middle, four costals either side.
static func _scute_centres() -> PackedVector2Array:
	var c := PackedVector2Array()
	for z: float in [-0.66, -0.34, -0.02, 0.3, 0.62]:
		c.append(Vector2(0.0, z))
	for sd: float in [-1.0, 1.0]:
		for z: float in [-0.48, -0.16, 0.16, 0.46]:
			c.append(Vector2(0.52 * sd, z))
	return c


## A plastron's lobe (or a snapper's cross): a plate from z0 to z1, th
## thick, its half width at z hw(z) (mm).
static func _plate(z0: float, z1: float, hw: Callable, th: float) -> ArrayMesh:
	const N := 16
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := func(z: float) -> Array:
		var w: float = hw.call(z)
		return [Vector3(-w, th, z), Vector3(w, th, z), Vector3(w * 0.96, 0.0, z), Vector3(-w * 0.96, 0.0, z)]
	var prev: Array = ring.call(z0)
	var quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
		st.add_vertex(a); st.add_vertex(c); st.add_vertex(d)
	quad.call(prev[0], prev[1], prev[2], prev[3]) # (its front edge)
	for i in range(1, N + 1):
		var cur: Array = ring.call(lerpf(z0, z1, float(i) / N))
		for k in 4:
			quad.call(prev[k], cur[k], cur[(k + 1) % 4], prev[(k + 1) % 4])
		prev = cur
	quad.call(prev[3], prev[2], prev[1], prev[0]) # (its back edge)
	st.generate_normals()
	return st.commit()


## The shell's paint (on its own mm: VERTEX): its scutes found from their
## centres (the marginals a ring round the rim), each seam dark; from each
## scute's growth centre (its areola) its pattern: radiating streaks and
## blotches (rays), growth rings; algae (a snapper's); its plastron (plast)
## tan, smudged dark along its seams; underneath, the body's skin.
static func _shell_shader() -> Shader:
	if _shell_sh == null:
		_shell_sh = Shader.new()
		_shell_sh.code = """shader_type spatial;
uniform vec3 ground : source_color;
uniform vec3 ray : source_color;
uniform vec3 seam : source_color;
uniform vec3 plast : source_color;
uniform vec3 smudge : source_color;
uniform vec3 under : source_color;
uniform float rays = 1.0;
uniform float algae = 0.0;
uniform float hw = 52.0;
uniform float hl = 70.0;
uniform float rim = 15.0;
uniform float bright = 1.0;
uniform bool plastron = false;
uniform float seed = 0.0;
uniform vec2 cen[13];
varying vec3 o;
varying vec3 on;
float h2(vec2 p) { return fract(sin(dot(p + seed, vec2(12.9898, 78.233))) * 43758.5453); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y); }
void vertex() { o = VERTEX; on = NORMAL; }
void fragment() {
	vec2 q = vec2(o.x / hw, o.z / hl);
	vec3 c;
	if (plastron) {
		// (tan, its seams across and down its middle smudged dark brown)
		float sz = abs(fract(o.z / 24.0 + 0.3) - 0.5);
		float mid = abs(o.x);
		float sm = (1.0 - smoothstep(0.0, 0.12, sz - 0.38)) * 0.0 + (1.0 - smoothstep(0.06, 0.16, 0.5 - sz)) + (1.0 - smoothstep(1.0, 2.5, mid));
		sm = clamp(sm, 0.0, 1.0) * (0.55 + 0.45 * vn(o.xz * 0.15));
		c = mix(plast, smudge, sm * 0.8) * (0.9 + 0.2 * vn(o.xz * 0.4));
		ALBEDO = c * bright;
		ROUGHNESS = 0.6;
	} else if (on.y < -0.3 && o.y < rim * 0.6) { // (beneath: the body's skin)
		ALBEDO = under;
		ROUGHNESS = 0.8;
	} else {
	float rr = length(q);
	float s = 0.0;
	vec2 rel;
	float ang = atan(q.x, -q.y);
	if (rr > 0.84 || o.y < rim + 1.0) { // (the marginals: a ring round its rim)
		float cell = ang / 6.2832 * 24.0 + 0.5;
		float f = fract(cell);
		s = 1.0 - smoothstep(0.0, 0.07, min(f, 1.0 - f));
		s = max(s, 1.0 - smoothstep(0.0, 0.025, abs(rr - 0.84)) * step(rim + 1.0, o.y));
		float ca = (floor(cell) + 0.5 - 0.5) / 24.0 * 6.2832;
		rel = (q - vec2(sin(ca), -cos(ca)) * 1.0) * vec2(1.0, 1.0);
	} else { // (the vertebrals and costals: whichever centre's nearest)
		float d1 = 9.0;
		float d2 = 9.0;
		vec2 best = vec2(0.0);
		for (int k = 0; k < 13; k++) {
			vec2 cc = cen[k];
			float d = length((q - cc) * (k < 5 ? vec2(1.25, 1.0) : vec2(1.0, 1.1)));
			if (d < d1) { d2 = d1; d1 = d; best = cc; } else if (d < d2) { d2 = d; }
		}
		s = 1.0 - smoothstep(0.0, 0.035, d2 - d1);
		vec2 are = best + (abs(best.x) > 0.1 ? vec2(-sign(best.x) * 0.12, 0.1) : vec2(0.0, 0.1)); // (its growth centre: behind, toward the middle)
		rel = q - are;
	}
	float dr = length(rel);
	float a = atan(rel.y, rel.x);
	c = ground * (0.85 + 0.3 * vn(q * 14.0));
	// (its streaks, out from its growth centre: irregular, some blotched)
	float st = sin(a * 5.0 + 4.0 * vn(q * 5.0 + 2.0) + h2(floor(q * 3.0)) * 6.0);
	float streak = smoothstep(0.5, 0.9, st) * smoothstep(0.03, 0.08, dr) * (1.0 - smoothstep(0.14, 0.3, dr + 0.12 * vn(q * 8.0)));
	streak *= smoothstep(0.35, 0.6, vn(q * 7.0 + vec2(a, 0.0))); // (some broken, some gone)
	float blot = (1.0 - smoothstep(0.03, 0.09, dr + 0.05 * (vn(q * 18.0) - 0.5))) * 0.9;
	blot = max(blot, smoothstep(0.72, 0.8, vn(q * 11.0 + 3.0)) * 0.7); // (flecks)
	vec3 rc = mix(ray, ray * vec3(1.0, 0.75, 0.5), vn(q * 4.0)); // (yellow to orange)
	c = mix(c, rc * bright, clamp(streak + blot, 0.0, 1.0) * rays * 0.85);
	// (its growth rings round its areola)
	float ring = abs(fract(dr * 34.0) - 0.5);
	c *= 1.0 - 0.12 * (1.0 - smoothstep(0.1, 0.25, ring));
	// (algae, in patches)
	c = mix(c, vec3(0.17, 0.19, 0.1) * (0.8 + 0.4 * vn(q * 30.0)), algae * smoothstep(0.5, 0.8, vn(q * 7.0 + 7.0)));
	c = mix(c, seam, s * 0.9);
	ALBEDO = c;
	ROUGHNESS = 0.68;
	SPECULAR = 0.4;
	}
}
"""
	return _shell_sh


## Its skin: its ground, spotted (spots: how many), paler beneath; its
## scales, bumped (bumps); in its own mm (turtle_inv: the spots stay on it).
static func _skin_shader() -> Shader:
	if _skin_sh == null:
		_skin_sh = Shader.new()
		_skin_sh.code = """shader_type spatial;
uniform vec3 base : source_color;
uniform vec3 spot : source_color;
uniform vec3 pale : source_color;
uniform float spots = 0.5;
uniform float bumps = 0.3;
uniform float scale = 1.0;
uniform mat4 turtle_inv;
varying vec3 wp;
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float cells(vec3 p) { // (distance to the nearest of its scattered points, 0 .. 1)
	vec3 i = floor(p);
	float best = 9.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 k = i + vec3(float(x), float(y), float(z));
		vec3 at = k + vec3(h3(k), h3(k + 1.3), h3(k + 2.7));
		best = min(best, length(p - at));
	}
	return best;
}
void vertex() { wp = (turtle_inv * (MODEL_MATRIX * vec4(VERTEX, 1.0))).xyz; }
void fragment() {
	vec3 n = (inverse(VIEW_MATRIX) * vec4(NORMAL, 0.0)).xyz;
	vec3 p = wp / scale;
	vec3 c = base * (0.85 + 0.3 * vn(p * 0.5));
	// (its spots: scattered, irregular, some run together)
	vec3 g = p / 4.5;
	vec3 gi = floor(g);
	float sp = 0.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 k = gi + vec3(float(x), float(y), float(z));
		if (h3(k + 5.1) > spots) continue;
		vec3 at = k + vec3(h3(k), h3(k + 1.3), h3(k + 2.7));
		float d = length(g - at) / (0.25 + 0.2 * h3(k + 3.3));
		sp = max(sp, 1.0 - smoothstep(0.85, 1.0, d + 0.25 * (vn(p * 1.2) - 0.5)));
	}
	c = mix(c, spot, sp);
	c = mix(pale, c, smoothstep(-0.55, -0.05, n.y));
	ALBEDO = c;
	// (its scales: bumped)
	float h = smoothstep(0.0, 1.0, 1.0 - cells(p / 2.4));
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);
	float dhx = dFdx(h);
	float dhy = dFdy(h);
	vec3 r1 = cross(dpy, NORMAL);
	vec3 r2 = cross(NORMAL, dpx);
	float det = dot(dpx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	float near = 1.0 - smoothstep(0.4, 1.6, length(VERTEX)); // (faded out far off, where they'd shimmer)
	NORMAL = normalize(abs(det) * NORMAL - grad * bumps * 1.4 * near);
	ROUGHNESS = 0.7;
	SPECULAR = 0.3;
}
"""
	return _skin_sh


func _build() -> void:
	var P: Dictionary = S.shell
	var C: Dictionary = S.col
	var bright := 1.2 if young else 1.0
	_shell_n = Node3D.new()
	_body.add_child(_shell_n)
	# the carapace
	var shell := ShaderMaterial.new()
	shell.shader = _shell_shader()
	for k: String in ["ground:shell", "ray:ray", "seam:seam", "plast:plast", "smudge:smudge", "under:under"]:
		var kv := k.split(":")
		shell.set_shader_parameter(kv[0], C[kv[1]] if kv[1] != "under" else C.skin)
	shell.set_shader_parameter("rays", float(C.rays) * (0.6 if young else 1.0))
	shell.set_shader_parameter("algae", C.algae)
	shell.set_shader_parameter("hw", float(P.wid) * 0.5)
	shell.set_shader_parameter("hl", float(P.len) * 0.5)
	shell.set_shader_parameter("rim", P.rim)
	shell.set_shader_parameter("bright", bright)
	shell.set_shader_parameter("seed", rng.randf() * 50.0)
	shell.set_shader_parameter("cen", _scute_centres())
	var sp := P.duplicate()
	if young: # (a hatchling's shell flatter, rounder)
		sp.ht = float(P.ht) * 0.75
		sp.wid = float(P.wid) * 1.08
	var cm := MeshInstance3D.new()
	cm.mesh = _shell_mesh(sp)
	cm.material_override = shell
	_shell_n.add_child(cm)
	# the plastron: hinged in two lobes, or a cross
	var Q: Dictionary = S.plastron
	var pm := shell.duplicate() as ShaderMaterial
	pm.set_shader_parameter("plastron", true)
	var hl := float(P.len) * 0.5
	var hw := float(P.wid) * 0.5
	var th := float(Q.th)
	var wid := float(Q.wid)
	if bool(Q.cross):
		var cross := func(z: float) -> float:
			var e := sqrt(maxf(1.0 - pow(z / (hl * 0.85), 2.0), 0.05))
			return hw * (0.62 if absf(z) < hl * 0.16 else wid) * e
		var mi := MeshInstance3D.new()
		mi.mesh = _plate(-hl * 0.78, hl * 0.66, cross, th)
		mi.material_override = pm
		_shell_n.add_child(mi)
	else:
		var lobe := func(z: float) -> float:
			return hw * wid * 2.0 * sqrt(maxf(1.0 - pow(z / (hl * 0.97), 2.0), 0.04)) * (1.0 - 0.15 * smoothstep(hl * 0.7, hl * 0.95, z))
		var hz := float(Q.hinge_z)
		_front_lobe = Node3D.new()
		_front_lobe.position = Vector3(0.0, th * 0.5, hz)
		_shell_n.add_child(_front_lobe)
		var fm := MeshInstance3D.new()
		fm.mesh = _plate(-hl * 0.95 - hz, -1.0, func(z: float) -> float: return lobe.call(z + hz), th)
		fm.position.y = -th * 0.5
		fm.material_override = pm
		_front_lobe.add_child(fm)
		_rear_lobe = Node3D.new()
		_rear_lobe.position = Vector3(0.0, th * 0.5, hz)
		_shell_n.add_child(_rear_lobe)
		var rm := MeshInstance3D.new()
		rm.mesh = _plate(1.0, hl * 0.94 - hz, func(z: float) -> float: return lobe.call(z + hz), th)
		rm.position.y = -th * 0.5
		rm.material_override = pm
		_rear_lobe.add_child(rm)
	# its skin
	_skin = ShaderMaterial.new()
	_skin.shader = _skin_shader()
	_skin.set_shader_parameter("base", C.skin)
	_skin.set_shader_parameter("spot", (C.spot as Color) * bright)
	_skin.set_shader_parameter("pale", C.under)
	_skin.set_shader_parameter("spots", C.spots)
	_skin.set_shader_parameter("bumps", C.bumps)
	_skin.set_shader_parameter("scale", float(P.len) / 140.0)
	# the neck and head
	var N: Dictionary = S.neck
	_neck_mi = _limb(_skin, _shell_n, 0.1)
	_neck_n = Node3D.new()
	_neck_n.position = N.out
	_shell_n.add_child(_neck_n)
	_head = Node3D.new()
	_neck_n.add_child(_head)
	var hm := MeshInstance3D.new()
	hm.mesh = _loft(S.head, 2.0, 2.6)
	hm.material_override = _skin
	_head.add_child(hm)
	_jaw_n = Node3D.new()
	_jaw_n.position = S.jaw_at
	_head.add_child(_jaw_n)
	var jm := MeshInstance3D.new()
	jm.mesh = _loft(S.jaw, 2.4, 2.4)
	jm.position = -(S.jaw_at as Vector3)
	jm.material_override = _skin
	_jaw_n.add_child(jm)
	var mouth := _mat(Color(0.75, 0.55, 0.45), 0.5)
	_part(Vector3(0.0, -4.5, -14.0) * float(P.len) / 140.0 - (S.jaw_at as Vector3), Vector3(12.0, 2.0, 22.0) * float(P.len) / 140.0, mouth, _jaw_n) # (its mouth's floor, its tongue)
	var E: Array = S.eye
	var em := _mat(C.eye_m if male else C.eye_f, 0.15)
	em.clearcoat_enabled = true
	em.clearcoat = 1.0
	for side: float in [-1.0, 1.0]:
		var at: Vector3 = E[0]
		var r := float(E[1])
		_part(Vector3(at.x * side, at.y, at.z), Vector3.ONE * r * 2.0, em, _head) # (its eye)
		_part(Vector3((at.x + r * 0.55) * side, at.y + 0.2, at.z - 0.2), Vector3(r * 0.9, r * 0.9, r * 0.9), _mat(Color(0.02, 0.02, 0.02), 0.1), _head) # (its pupil)
		_part(Vector3(at.x * side * 0.97, at.y + r * 0.55, at.z + 0.3), Vector3(r * 2.3, r * 0.8, r * 2.3), _skin, _head) # (its lid)
	_build_head_extra()
	# the legs: stumpy, scaled, clawed
	var claw := _mat(Color(0.3, 0.27, 0.2), 0.45)
	for fore: bool in [true, false]:
		for side: float in [-1.0, 1.0]:
			var hip := Node3D.new()
			var hp: Vector3 = S.fore if fore else S.hind
			hip.position = Vector3(hp.x * side, hp.y, hp.z)
			_shell_n.add_child(hip)
			var cl := []
			for k in int(S.claws):
				cl.append(_limb(claw, _shell_n, 0.8))
			_legs.append([hip, _limb(_skin, _shell_n, 0.2), _limb(_skin, _shell_n, 0.15), _limb(_skin, _shell_n, 0.1), fore, side, cl])
	# the tail
	var T: Dictionary = S.tail
	_tail_n = Node3D.new()
	_tail_n.position = T.at
	_shell_n.add_child(_tail_n)
	var tl := float(T.len_m if male else T.len)
	_tail_mi = _limb(_skin, _tail_n, 0.85)
	_seg_to(_tail_mi, Vector3.ZERO, Vector3(0.0, -tl * 0.15, tl), float(T.r))
	for k in int(T.crest): # (a snapper's: a saw of plates down its top)
		var f := (float(k) + 0.5) / float(T.crest)
		var c := _limb(_skin, _tail_n, 0.9)
		var at := Vector3(0.0, -tl * 0.15 * f + float(T.r) * (1.0 - f * 0.85) * 0.75, tl * f)
		_seg_to(c, at, at + Vector3(0.0, float(T.r) * (1.0 - f * 0.6) * 1.1, float(T.r) * 0.45), float(T.r) * 0.45 * (1.0 - f * 0.6), 2.4)


## (The species' own, on its head: a snapper's barbels.)
func _build_head_extra() -> void:
	pass


# --- what it does ---------------------------------------------------------------

func wander(centre: Vector3, radius := 0.4) -> void:
	_go_mode("wander")
	_centre = centre
	_radius = radius


func bask(at := Vector3.INF) -> void:
	_go_mode("bask")
	if at == Vector3.INF:
		at = basks[rng.randi() % basks.size()] if not basks.is_empty() else _pos
	_target = at


## (A box turtle's: a soak, sat in the water; a snapper's: down to the floor.)
func dive() -> void:
	_go_mode("dive")


func withdraw() -> void:
	_go_mode("hide")


func eat(food: Node3D) -> void:
	if food == null:
		return
	_go_mode("eat")
	_food = food


func nest() -> void:
	if male or young or bank == Vector3.INF:
		return
	_go_mode("nest")


func _go_mode(m: String) -> void:
	_mode = m
	_stage = 0
	_st = 0.0
	_wait = 0.0
	_neck_to = 1.0
	_neck_rate = 2.0
	_limbs_to = 1.0
	_jaw_to = 0.0
	_dig = 0.0
	_rear = 0.0


func mate(partner: Node3D, secs := 12.0) -> bool:
	if partner == null or not (partner is Turtle) or partner.get_script() != get_script() or not male or young or _role != "":
		return false
	var her := partner as Turtle
	if her.male or her.young or her._role != "":
		return false
	_mate = her
	_role = "male"
	her._mate = self
	her._role = "female"
	her._go_mode("courted")
	_go_mode("mate")
	_mate_len = secs
	return true


func _end_mate() -> void:
	var her := _mate
	_mate = null
	_role = ""
	_pitch = 0.0
	_pivot_z = 0.0
	_lift = 0.0
	if is_instance_valid(her):
		her._mate = null
		her._role = ""
		her.wander(her._pos, 0.4)
	wander(_pos, 0.4)


# --- the motor -------------------------------------------------------------------

func _in_water(p: Vector3) -> bool:
	var c: Vector3 = pond[0]
	var e: Vector2 = pond[1]
	return absf(p.x - c.x) < e.x and absf(p.z - c.z) < e.y


## Where it stands at x, z: the ground; in the water, its floor (a box
## turtle's: it doesn't swim, it wades and sits), or (a swimmer's) at the
## surface less how deep it's gone.
func _ground_at(x: float, z: float) -> float:
	if _in_water(Vector3(x, 0.0, z)):
		if not bool(S.aquatic):
			return floor_y
		return maxf(water_y - 0.03 * size - _depth, floor_y)
	return float(height.call(x, z)) if height.is_valid() else 0.0


func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	_t += dt
	_st += dt
	_wait -= dt
	if _pilot:
		_pilot.tick(dt)
	if not _piloting:
		_think(dt)
	_move(dt)
	_place()
	_pose(dt)


func _think(dt: float) -> void:
	match _mode:
		"wander":
			_wander_think(dt)
		"bask":
			match _stage:
				0: # (to it)
					_go_to(_target, float(S.walk) * 1.5)
					if Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.04:
						_stage = 1
						_st = 0.0
				1: # (still in the sun, its legs stretched out behind, its neck up)
					_speed = 0.0
					_neck_to = 1.35
					if _st > 25.0:
						wander(_pos, 0.4)
		"dive":
			_dive_think(dt)
		"hide":
			_hide_think(dt)
		"eat":
			_eat_think(dt)
		"courted": # (a female: still, her head half in)
			_speed = 0.0
			_neck_to = 0.5
			_limbs_to = 0.7
		"mate":
			_mate_think(dt)
		"nest":
			_nest_think(dt)


## Over the forest floor: slowly on, stopping, its head out and looking
## round; if it's come into the water, out (a box turtle's).
func _wander_think(_dt: float) -> void:
	if _wait <= 0.0 or Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.03:
		var a := rng.randf() * TAU
		_target = _centre + Vector3(cos(a), 0.0, sin(a)) * _radius * rng.randf()
		if _in_water(_target):
			_target = _pos
		_speed = float(S.walk)
		_wait = rng.randf_range(5.0, 11.0)
		if rng.randf() < 0.35:
			_target = _pos # (a stop: looking round)
	_look = sin(_t * 0.7) * 0.5 if _speed < 0.0005 or Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.03 else 0.0


## A soak: into the water, sat in its shallows half under, still; out.
func _dive_think(_dt: float) -> void:
	match _stage:
		0:
			var c: Vector3 = pond[0]
			var e: Vector2 = pond[1]
			var into := c + (Vector3(_pos.x - c.x, 0.0, _pos.z - c.z).normalized() * minf(e.x, e.y) * 0.4)
			_go_to(into, float(S.walk) * 1.2)
			if _in_water(_pos) and Vector2(_pos.x - into.x, _pos.z - into.z).length() < 0.05:
				_stage = 1
				_st = 0.0
		1:
			_speed = 0.0
			_neck_to = 0.8 + 0.2 * sin(_st * 0.3)
			if _st > 20.0:
				var c: Vector3 = pond[0]
				var e: Vector2 = pond[1]
				var a := atan2(_pos.z - c.z, _pos.x - c.x)
				wander(c + Vector3(cos(a) * (e.x + 0.3), 0.0, sin(a) * (e.y + 0.3)), 0.3)


## Its alarm: all in, its shell shut; a while, then its head out a little,
## looking; out.
func _hide_think(_dt: float) -> void:
	_speed = 0.0
	_neck_to = 0.0 if _st < 9.0 else 0.35
	_limbs_to = 0.0 if _st < 10.0 else 1.0
	if _st > 12.0:
		wander(_pos, 0.3)


## To it, its head down to it, bites torn off, gulped; gone.
func _eat_think(_dt: float) -> void:
	if not is_instance_valid(_food):
		wander(_pos, 0.3)
		return
	var fp := _food.global_position if _food.is_inside_tree() else _food.position
	var d := Vector3(fp.x - _pos.x, 0.0, fp.z - _pos.z)
	var reach := (absf(float((S.neck.out as Vector3).z)) + float(S.neck.reach)) * MM * size
	if d.length() > reach and _stage == 0:
		_go_to(fp - d.normalized() * reach * 0.9, float(S.walk) * 1.3)
		return
	_speed = 0.0
	_face(d)
	if _stage == 0:
		_stage = 1
		_st = 0.0
	_neck_to = 1.2 + 0.15 * sin(_st * 4.0)
	_look = -0.5 # (its head down to it)
	_jaw_to = 0.45 * maxf(sin(_st * 5.0), 0.0)
	if _st > 3.0 and is_instance_valid(_food):
		_food.queue_free()
		_food = null
	if _st > 3.8:
		wander(_pos, 0.3)


## (A box turtle's courting and mounting.) After her, behind her, nudging
## and biting at the rim of her shell; up onto her from behind, his hind
## claws hooked under the back of her plastron, his forefeet on her shell,
## leaning back till he's near upright; off.
func _mate_think(_dt: float) -> void:
	var her := _mate
	if not is_instance_valid(her):
		_end_mate()
		return
	var hb := Basis(Vector3.UP, her._yaw)
	var L := float(S.shell.len) * MM * size
	match _stage:
		0: # (to just behind her)
			var behind := her._pos + hb * Vector3(0.0, 0.0, L * 0.85)
			_go_to(behind, float(S.walk) * 1.5)
			if Vector2(_pos.x - behind.x, _pos.z - behind.z).length() < 0.03:
				_stage = 1
				_st = 0.0
		1: # (nudging her shell's rim, biting at it, circling a little)
			_speed = 0.0
			_face(her._pos - _pos)
			_neck_to = 1.0 + 0.3 * maxf(sin(_st * 3.0), 0.0)
			_jaw_to = 0.3 * maxf(sin(_st * 3.0 + 0.5), 0.0)
			if _st > _mate_len * 0.35:
				_stage = 2
				_st = 0.0
		2: # (up onto her from behind, leaning back)
			var onto := her._pos + hb * Vector3(0.0, 0.0, L * 0.62)
			_pos.x = lerpf(_pos.x, onto.x, 0.08)
			_pos.z = lerpf(_pos.z, onto.z, 0.08)
			_speed = 0.0
			_yaw = lerp_angle(_yaw, her._yaw, 0.1)
			_pivot_z = float(S.shell.len) * 0.45 # (about his shell's back edge, on the ground behind her)
			_pitch = lerpf(_pitch, 1.15 if _st > 2.0 else 0.6, 0.04) # (back, near upright)
			_neck_to = 1.1
			if _st > _mate_len * 0.55:
				_stage = 3
				_st = 0.0
		3: # (down off her)
			_pitch = lerpf(_pitch, 0.0, 0.08)
			if _st > 1.5:
				_end_mate()


func _nest_think(_dt: float) -> void:
	match _stage:
		0: # (to the bank)
			_go_to(bank, float(S.walk) * 2.0)
			if Vector2(_pos.x - bank.x, _pos.z - bank.z).length() < 0.04:
				_stage = 1
				_st = 0.0
		1: # (digging with her hind feet, one then the other; her shell tipped up in front)
			_speed = 0.0
			_dig = 1.0
			_pivot_z = 0.0
			_pitch = lerpf(_pitch, 0.15, 0.05)
			if _st > 8.0:
				_stage = 2
				_st = 0.0
		2: # (laying)
			_dig = 0.0
			if _st > 3.0:
				var n := Nest.new()
				n.maker = get_script()
				n.turtle = self
				n.at = _pos + Basis(Vector3.UP, _yaw) * Vector3(0.0, 0.0, float(S.shell.len) * 0.6 * MM * size)
				n.at.y = _ground_at(n.at.x, n.at.z)
				get_parent().add_child(n)
				nests.append(n)
				_stage = 3
				_st = 0.0
		3: # (the earth pushed back over them, pressed down)
			_dig = 0.6
			if _st > 4.0:
				_dig = 0.0
				_pitch = 0.0
				_stage = 4
		4: # (off)
			wander(pond[0] if bool(S.aquatic) else _pos, 0.4)


func _go_to(p: Vector3, speed: float) -> void:
	_target = p
	_speed = speed


func _face(d: Vector3) -> void:
	if Vector2(d.x, d.z).length() > 0.002:
		_yaw = lerp_angle(_yaw, atan2(-d.x, -d.z), 0.15)


func _move(dt: float) -> void:
	_depth = move_toward(_depth, _depth_to, dt * 0.05)
	var d := Vector3(_target.x - _pos.x, 0.0, _target.z - _pos.z)
	var swim := bool(S.aquatic) and _in_water(_pos)
	var sp := _speed * (float(S.swim) / maxf(float(S.walk), 1e-4) if swim and float(S.swim) > 0.0 else 1.0) * clampf(d.length() / 0.04, 0.0, 1.0) * size
	if sp > 0.0005 and _limbs > 0.5:
		var y := atan2(-d.x, -d.z)
		_yaw += clampf(wrapf(y - _yaw, -PI, PI), -1.0 * dt, 1.0 * dt)
		_pos += Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * sp * dt
	if _role != "male" or _stage < 2:
		_pos.y = lerpf(_pos.y, _ground_at(_pos.x, _pos.z), 1.0 - exp(-6.0 * dt))


# --- the pose -------------------------------------------------------------------

func _place() -> void:
	var b := Basis.from_euler(Vector3(_pitch, _yaw, _roll))
	var piv := Basis(Vector3.UP, _yaw) * Vector3(0.0, 0.0, _pivot_z * MM * size) # (its pitch about that point, on the ground)
	transform = Transform3D(b, _pos + piv - b * Vector3(0.0, 0.0, _pivot_z * MM * size) + Vector3(0.0, _lift, 0.0))
	if _body:
		_body.scale = Vector3.ONE * MM * size
		var inv := (global_transform if is_inside_tree() else transform).affine_inverse()
		var k := MM * size
		_skin.set_shader_parameter("turtle_inv", Projection(Transform3D(inv.basis / k, inv.origin / k)))


## (How far up its plastron is off the ground: walking, sat, shut.)
func _stand() -> float:
	return float(S.stand) * (0.25 + 0.75 * _limbs) * (1.0 + 0.8 * _rear) * (0.4 if _mode == "bask" and _stage == 1 else 1.0)


func _pose(dt: float) -> void:
	_neck = move_toward(_neck, _neck_to, dt * _neck_rate)
	_limbs = move_toward(_limbs, _limbs_to, dt * 2.5)
	_jaw = move_toward(_jaw, _jaw_to, dt * 6.0)
	var k := float(S.shell.len) / 140.0 # (its size's measure, mm)
	var stand := _stand()
	_shell_n.position = Vector3(0.0, stand, 0.0)
	var ground := -stand
	# the neck and head: out, in, stretched
	var N: Dictionary = S.neck
	var hin: Vector3 = N["in"]
	var hout: Vector3 = N.out
	var head_at := hin.lerp(hout, minf(_neck, 1.0)) + Vector3(0.0, 0.0, -float(N.reach) * maxf(_neck - 1.0, 0.0) / 0.6)
	if _mode == "bask" and _stage == 1:
		head_at.y += float(N.reach) * 0.4 # (its neck stretched up)
	_neck_n.position = head_at
	_neck_n.rotation = Vector3(-0.25 * _look + 0.1 * _rear, 0.35 * _look * sin(_t * 0.37) + (0.4 * sin(_t * 0.5) if _mode == "wander" and _speed < 0.0005 else 0.0), 0.0)
	var root: Vector3 = N.root
	_seg_to(_neck_mi, root, head_at + Vector3(0.0, -1.0, 4.0 * k), float(N.r) * lerpf(0.8, 1.0, minf(_neck, 1.0)), 0.85)
	_neck_mi.visible = _neck > 0.15
	_jaw_n.rotation.x = _jaw
	# the plastron's lobes: shut against the carapace as it draws in
	var shut := clampf(1.0 - _limbs * 1.4, 0.0, 1.0) * clampf(1.0 - _neck * 2.5, 0.0, 1.0)
	if _front_lobe:
		_front_lobe.rotation.x = 0.36 * shut
		_rear_lobe.rotation.x = -0.27 * shut
	# its legs
	var swimming := bool(S.aquatic) and _in_water(_pos) and _depth > 0.0 and not (_mode == "bask" and _stage == 1)
	var moving := _speed > 0.0005 and _limbs > 0.5
	var basking := _mode == "bask" and _stage == 1
	var mounted := _role == "male" and _stage == 2
	var din := float(S.draw_in)
	for L: Array in _legs:
		var hip: Vector3 = (L[0] as Node3D).position
		var fore: bool = L[4]
		var side: float = L[5]
		var ph := _t * (3.0 if swimming else 2.2) + (0.0 if (fore == (side > 0.0)) else PI) # (diagonal pairs together)
		var sw := sin(ph) if moving else 0.0
		var lift := maxf(cos(ph), 0.0) * 5.0 * k if moving and not swimming else 0.0
		var out := hip + Vector3(float(S.reach) * k * side, (ground - hip.y) * 0.4, ((-7.0 if fore else 7.0) + sw * 7.0) * k)
		var foot := Vector3(out.x + float(S.reach) * 0.3 * k * side, ground + lift, out.z + ((-5.0 if fore else 5.0) + sw * 6.0) * k)
		if swimming: # (paddling: out wide, the feet flat)
			foot = out + Vector3(12.0 * k * side, -2.0 * k, ((-6.0 if fore else 12.0) + sw * 10.0) * k)
		if basking and not fore: # (the hind legs stretched out behind)
			out = hip + Vector3(14.0 * k * side, (ground - hip.y) * 0.5, 22.0 * k)
			foot = Vector3(out.x + 4.0 * k * side, ground, out.z + 22.0 * k)
		if _dig > 0.0 and not fore: # (digging: one hind foot then the other, scooping)
			var dp := sin(_t * 3.0 + (0.0 if side > 0.0 else PI))
			out = hip + Vector3(8.0 * k * side, (ground - hip.y) * 0.4, 18.0 * k)
			foot = Vector3(out.x - 5.0 * k * side * maxf(dp, 0.0), ground - 6.0 * k * maxf(dp, 0.0), out.z + 8.0 * k)
		if mounted: # (his forefeet on her shell; his hind feet down behind, hooked under her)
			if fore:
				out = hip + Vector3(10.0 * k * side, 2.0 * k, -10.0 * k)
				foot = out + Vector3(4.0 * k * side, -4.0 * k, -12.0 * k)
			else:
				out = hip + Vector3(10.0 * k * side, -8.0 * k, -6.0 * k)
				foot = out + Vector3(2.0 * k * side, -10.0 * k, -12.0 * k)
		var ex := _pose_leg_extra(L, out, foot)
		out = ex[0]
		foot = ex[1]
		# drawn in: under the shell's rim
		var tuck := hip * Vector3(0.75, 1.0, 0.85)
		var lim := lerpf(1.0 - din, 1.0, _limbs)
		out = tuck.lerp(out, lim)
		foot = tuck.lerp(foot, lim)
		var r := float(S.leg_r)
		_seg_to(L[1], hip, out, r * (0.6 + 0.4 * lim))
		_seg_to(L[2], out, foot, r * 0.85 * (0.6 + 0.4 * lim), 0.8)
		var fdir := (foot - out).normalized()
		var fl := Vector3(fdir.x, 0.0, fdir.z).normalized() if absf(fdir.y) < 0.98 else Vector3(0.0, 0.0, -1.0 if fore else 1.0)
		var ftip := foot + fl * float(S.foot) * k
		_seg_to(L[3], foot, ftip, float(S.foot) * 0.5 * (0.6 + 0.4 * lim), 0.45) # (the foot, broad and flat)
		var cl: Array = L[6]
		var long_ := float(S.claw_m_hind if not fore else S.claw_m_fore) if male and not young else float(S.claw)
		for c in cl.size():
			var spread := (float(c) - (cl.size() - 1) * 0.5) * 0.35
			var cdir := Basis(Vector3.UP, spread) * fl
			var c0 := ftip - fl * 2.0 * k
			var curl := Vector3(0.0, -0.4, 0.0) if not fore and male else Vector3(0.0, -0.15, 0.0)
			_seg_to(cl[c], c0, c0 + (cdir + curl).normalized() * long_ * k * lim, 0.9 * k * (1.0 + long_ / 20.0))
		(L[3] as MeshInstance3D).visible = lim > 0.2
		for c in cl:
			(c as MeshInstance3D).visible = lim > 0.2
	_tail_n.scale = Vector3.ONE * lerpf(1.0 - float(S.draw_in) * 0.7, 1.0, _limbs)
	_tail_n.rotation.x = -0.15 + 0.1 * sin(_t * 0.6) if not mounted else 0.4


## (The species' own, on a leg's pose: [out, foot] (its shell's mm).)
func _pose_leg_extra(_L: Array, out: Vector3, foot: Vector3) -> Array:
	return [out, foot]


# --- steering (pilot.gd) -------------------------------------------------------

func _pl() -> PilotScript:
	if _pilot == null:
		_pilot = PilotScript.new(self)
		_pilot.finished = action_finished.emit
	return _pilot


func go(direction: Vector3, speed := -1.0, seconds := -1.0) -> void:
	_pl().go(direction, speed, seconds)


func go_to(point: Vector3, speed := -1.0) -> void:
	_pl().go_to(point, speed)


func face(direction: Vector3) -> void:
	_pl().face(direction)


func stop() -> void:
	_pl().stop()


func act(name: String, args := {}) -> bool:
	return _pl().act(name, args)


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func is_busy() -> bool:
	return _pilot != null and _pilot.busy()


func _p_here() -> Vector3:
	return _pos


func _p_heading() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func _p_steer(point: Vector3, speed: float) -> void:
	_piloting = true
	_limbs_to = 1.0
	_go_to(point, speed if speed > 0.0 else 0.03)


func _p_hold() -> void:
	_piloting = true
	_speed = 0.0


func _p_mobile() -> bool:
	return _mode != "hide"


func _p_speed() -> float:
	return 0.03


func _p_reach() -> float:
	return 0.03


func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["wander", "bask", "dive", "hide", "eat"])
	if not young:
		b.append("mate" if male else "nest")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	_piloting = false
	match name:
		"wander":
			wander(args.get("centre", _pos), float(args.get("radius", 0.4)))
		"bask":
			bask(args.get("at", Vector3.INF))
		"dive":
			dive()
		"hide":
			withdraw()
		"eat":
			if args.get("food") == null:
				return false
			eat(args.food)
		"mate":
			return mate(args.get("partner"), float(args.get("seconds", 12.0)))
		"nest":
			if male or young:
				return false
			nest()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"bask":
			return _mode == "bask" and _stage == 1
		"dive", "hide":
			return _mode == "wander"
		"eat":
			return _mode != "eat"
		"mate":
			return _role == ""
		"nest":
			return _mode != "nest"
	return false


func _p_act_secs(name: String) -> float:
	return 15.0 if name == "wander" else -1.0


# --- props -------------------------------------------------------------------------

## A strand of pondweed floating (its food, as much as small animals): at.
static func weed_of(at: Vector3) -> Node3D:
	var w := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.46, 0.18)
	for k in 5:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.material_override = m
		mi.scale = Vector3(0.008, 0.003, 0.03)
		mi.position = Vector3(0.006 * k - 0.012, 0.0, 0.004 * sin(k * 2.0))
		mi.rotation.y = 0.6 * sin(k * 1.7)
		w.add_child(mi)
	w.position = at
	return w


## A mushroom on the forest floor (a box turtle's favourite; berries, worms,
## slugs too): its cap and stalk, at.
static func food_of(at: Vector3) -> Node3D:
	var w := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var cap := StandardMaterial3D.new()
	cap.albedo_color = Color(0.72, 0.42, 0.18)
	var stalk := StandardMaterial3D.new()
	stalk.albedo_color = Color(0.9, 0.86, 0.76)
	var st := MeshInstance3D.new()
	st.mesh = s
	st.material_override = stalk
	st.scale = Vector3(0.012, 0.04, 0.012)
	st.position = Vector3(0.0, 0.018, 0.0)
	w.add_child(st)
	var cp := MeshInstance3D.new()
	cp.mesh = s
	cp.material_override = cap
	cp.scale = Vector3(0.05, 0.02, 0.05)
	cp.position = Vector3(0.0, 0.038, 0.0)
	w.add_child(cp)
	w.position = at
	return w


## Her nest: a patch of earth pressed down over her eggs (six, leathery,
## white, oval: shown till they're covered); hatch() (or a while after) the
## hatchlings up out of it and away to the water.
class Nest extends Node3D:
	var maker: Script
	var turtle: Node3D
	var at := Vector3.ZERO
	var left := 70.0
	var _done := false
	var _eggs: Array[MeshInstance3D] = []
	var _t := 0.0

	func _ready() -> void:
		position = at # (where it is: its parts about it)
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		var dirt := StandardMaterial3D.new()
		dirt.albedo_color = Color(0.4, 0.32, 0.2)
		var d := MeshInstance3D.new()
		d.mesh = s
		d.material_override = dirt
		d.scale = Vector3(0.1, 0.012, 0.09)
		d.position = Vector3(0.0, 0.002, 0.0)
		add_child(d)
		var em := StandardMaterial3D.new()
		em.albedo_color = Color(0.93, 0.9, 0.84)
		for k in 6:
			var e := MeshInstance3D.new()
			e.mesh = s
			e.material_override = em
			e.scale = Vector3(0.012, 0.012, 0.018) * 1.6
			e.position = Vector3(randf_range(-0.02, 0.02), 0.008, randf_range(-0.02, 0.02))
			add_child(e)
			_eggs.append(e)

	func _process(dt: float) -> void:
		_t += dt
		if _t > 7.0: # (covered)
			for e in _eggs:
				e.visible = false
		left -= dt
		if left <= 0.0 and not _done:
			hatch()

	func hatch(n := 4) -> void:
		if _done or maker == null:
			return
		_done = true
		var tt := turtle as Turtle
		for k in n:
			var y: Node3D = maker.new(true)
			if is_instance_valid(tt):
				for p in ["water_y", "floor_y", "pond", "height", "basks"]:
					y.set(p, tt.get(p))
			get_parent().add_child(y)
			y.call("place", at + Vector3(randf_range(-0.03, 0.03), 0.0, randf_range(-0.03, 0.03)), randf() * TAU)
			var c: Vector3 = (y.get("pond") as Array)[0]
			y.call("wander", c, 0.3) # (off to the water)
		queue_free()
