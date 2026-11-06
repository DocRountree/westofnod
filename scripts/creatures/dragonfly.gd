class_name Dragonfly
extends Node3D
## A common green darner (Anax junius), drawn at twice life size (its parts
## modelled at life size, about 75 mm long, 100 mm across its wings: MM).
## Built from parts, posed every frame by hand (procedural: no clips).
##
## The adult: its head nearly all eye, the great compound eyes meeting on
## top, brown and green; its face yellow green, a dark "bullseye" on its
## brow; the thorax bright grass green; the abdomen long and slender, ten
## segments (the first two green; on from them sky blue in a male, a
## brownish violet in a female; a black stripe down its back), a male's
## claspers at its tip; four long clear wings, finely netted, each with its
## pterostigma (a small tan cell at its leading edge near the tip), held
## out flat at rest; six spiny legs, a basket held forward under it in
## flight. The nymph (Dragonfly.new(true)): a naiad, in the water, mottled
## olive brown; a broad head with big eyes and its hinged lower lip (the
## mask) folded under it, shot out to seize prey; wing pads on its back; a
## stout tapering abdomen; walking the pond's floor and its stems.
##
## What it does (each a method; its own ways when told none):
## - patrol(centre, radius): flying beats over the water and round,
##   darting, banking, hovering a moment, turning back
## - perch(at): to a stem's tip (or the one nearest), landing on it, its
##   wings out flat and drooped a little, its head turning after things
## - hunt(prey) (a small flying insect: a trigonalid wasp, say): out after it,
##   swept up in its legs' basket; to a perch (or on the wing), chewed
## - lay(): (a female's) to the pond's stems, hovering low by one, her
##   abdomen curled down into it below the water, her eggs put into the stem
##   (Eggs: a row of pale specks), along to another; then off
## - mate(her): (a male's) after her, seized: his claspers at the back of
##   her head, in tandem; to a perch, the wheel (she curls her abdomen
##   forward up under him to the base of his), a while; off again in
##   tandem, to the water, he holding her upright while she lays; let go
## - flee(from): a fast dart away, up and round
## The nymph's: crawl(centre, radius) about the pond's floor, strike(at)
## (the mask out and back, chewing), emerge(): to a stem, up it out of the
## water; still; its back splits, the adult out of it pale, its wings
## crumpled, swelling and hardening, its colour coming; the empty skin
## (the exuvia) left clinging to the stem; off.
##
## Its world: water_y (the pond's surface), floor_y (its floor), pond
## (centre, half extents x, z), stems (each [foot, tip]), perches (points);
## height (the ground's y at x, z, outside the pond).
## Steering (pilot.gd): go, go_to, face, stop, act (patrol {centre, radius},
## perch {at}, hunt {prey}, lay, mate {partner}, flee {from}; a nymph's
## crawl, strike {at}, emerge), behaviours, is_busy, action_finished.
## Its position is set every frame: put it under a node that isn't moved.

signal action_finished(name: String, ok: bool)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const MM := 0.002 ## m drawn per model mm (twice life size)
const BODY_H := 4.0 ## mm its thorax's middle over a perch
# the abdomen's segments: length, half width (mm)
const SEGS := [[3.2, 2.7], [4.0, 2.3], [5.5, 1.75], [5.5, 1.6], [5.5, 1.6], [5.3, 1.6], [5.0, 1.65], [4.5, 1.7], [3.6, 1.6], [3.0, 1.45]]
const N_SEGS := [[3.0, 3.4], [3.4, 4.2], [3.4, 4.6], [3.2, 4.6], [3.0, 4.2], [2.8, 3.4], [2.4, 2.5], [2.0, 1.6]] # (the nymph's: broad, tapering)
const LEG_HIPS := [Vector3(1.0, -3.2, -3.4), Vector3(1.3, -3.4, -1.2), Vector3(1.5, -3.4, 1.0)]
const LEG_LEN := [[5.5, 6.0], [6.5, 7.0], [8.0, 9.0]] # (femur, tibia: the hind longest)
const GREEN := Color(0.33, 0.62, 0.2)
const FACE := Color(0.62, 0.72, 0.28)
const BLUE := Color(0.25, 0.5, 0.86)
const VIOLET := Color(0.42, 0.33, 0.4)
const DARK := Color(0.06, 0.06, 0.07)

var male := false
var nymph := false
var size := 1.0
var height: Callable ## (x, z) -> the ground's y (outside the pond)
var water_y := 0.0
var floor_y := -0.1
var pond := [Vector3.ZERO, Vector2(0.5, 0.4)] ## [centre, half extents (x, z)]
var stems: Array = [] ## [foot, tip] each (world)
var perches: Array = [] ## points (world)
var eggs_laid: Array[Node3D] = []

var _pos := Vector3.ZERO
var _vel := Vector3.ZERO
var _yaw := 0.0
var _pitch := 0.0
var _roll := 0.0
var _t := 0.0
var _mode := "patrol"
var _stage := 0
var _st := 0.0
var _wait := 0.0
var _centre := Vector3.ZERO
var _radius := 1.0
var _target := Vector3.ZERO
var _speed := 1.2
var _perch := Vector3.INF
var _perched := false
var _prey: Node3D
var _held_prey: Node3D
var _meal: Node3D # (its prey, chewed up piece by piece: Meal)
const MealScript := preload("res://scripts/creatures/meal.gd")
var _mate: Dragonfly
var _role := "" # "male", "female" (mating)
var _held_by: Dragonfly # (a female in tandem or the wheel: carried)
var _hold_pose := "" # "tandem", "wheel", "lay"
var _from := Vector3.ZERO
var _look := Vector2.ZERO # (its head: yaw, pitch)
var _look_to := Vector2.ZERO
var _curl := 0.0 # (its abdomen curled: + down, - up)
var _curl_to := 0.0
var _beat := 1.0 # 0 still .. 1 beating
var _beat_to := 1.0
var _chew := 0.0
var _mask := 0.0 # (a nymph's lower lip out: 0 .. 1)
var _teneral := 1.0 # (just out: 0 pale and soft .. 1 hardened)
var _wings_out := 1.0 # (0 crumpled .. 1 spread)
var _climb := 0.0
var _stem: Array = []
var _pilot: PilotScript
var _piloting := false
var _p_done := false
# the parts
var _body: Node3D
var _head: Node3D
var _segs: Array[Node3D] = []
var _wings: Array[Node3D] = [] # (fore right, fore left, hind right, hind left)
var _legs: Array = [] # [hip node, femur mi, tibia mi] each
var _mask_n: Node3D
var _mask_stalk: MeshInstance3D
var _mands: Array[Node3D] = []
var _mats: Array = [] # [material, its hardened colour] (teneral: paler)
var rng := RandomNumberGenerator.new()

static var _sphere: SphereMesh
static var _cyl: CylinderMesh
static var _wing_sh: Shader


func _init(nymph_ := false) -> void:
	nymph = nymph_
	size = 0.35 if nymph_ else 1.0
	rng.randomize()


func _ready() -> void:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 16
		_sphere.rings = 8
		_cyl = CylinderMesh.new()
		_cyl.top_radius = 0.5
		_cyl.bottom_radius = 0.5
		_cyl.height = 1.0
		_cyl.radial_segments = 8
	_body = Node3D.new()
	add_child(_body)
	if nymph:
		_build_nymph()
	else:
		_build_adult()
	if nymph:
		_mode = "crawl"
		_centre = pond[0]
		_radius = 0.3


## Puts it at p (a nymph: on the pond's floor there).
func place(p: Vector3, yaw := 0.0) -> void:
	_pos = p
	if nymph:
		_pos.y = floor_y
	_yaw = yaw
	_place(0.0)


# --- its model ----------------------------------------------------------------

func _mat(c: Color, rough := 0.5, gloss := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if gloss > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = gloss
		m.clearcoat_roughness = 0.2
	return m


## A material that's paler while it's teneral (just out), its colour coming as it hardens.
func _tmat(c: Color, rough := 0.5, gloss := 0.0) -> StandardMaterial3D:
	var m := _mat(c, rough, gloss)
	_mats.append([m, c])
	return m


func _part(at: Vector3, sz: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	mi.position = at
	mi.scale = sz
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _bone(mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _cyl
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## An ellipsoid part stretched from a to b, r thick.
static func _seg_to_part(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var d := b - a
	var l := maxf(d.length(), 0.01)
	var z := d / l
	var x := z.cross(Vector3.UP if absf(z.y) < 0.9 else Vector3.RIGHT).normalized()
	var y := z.cross(x)
	mi.transform = Transform3D(Basis(x * r * 2.0, y * r, z * l), (a + b) * 0.5)


## A bone from a to b (its parent's mm), r thick.
static func _seg_to(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var d := b - a
	var l := maxf(d.length(), 0.01)
	var y := d / l
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	mi.transform = Transform3D(Basis(x * r * 2.0, y * l, z * r * 2.0), (a + b) * 0.5)


func _build_adult() -> void:
	var green := _tmat(GREEN, 0.4, 0.4)
	var dark := _mat(DARK, 0.4)
	# the thorax: bright green, deep, sloping back
	var th := _part(Vector3.ZERO, Vector3(8.0, 9.5, 12.0), green, _body)
	th.rotation.x = -0.25
	_part(Vector3(0.0, 2.2, -4.0), Vector3(6.0, 4.0, 4.0), green, _body) # (the prothorax, under its head)
	# the head: nearly all eye
	_head = Node3D.new()
	_head.position = Vector3(0.0, 1.8, -7.6)
	_body.add_child(_head)
	var eye := _tmat(Color(0.32, 0.4, 0.22), 0.2, 0.9)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(2.7 * side, 1.3, -0.6), Vector3(5.6, 6.4, 6.2), eye, _head)
	var face := _tmat(FACE, 0.45, 0.3)
	_part(Vector3(0.0, -1.4, -2.8), Vector3(6.2, 4.2, 3.4), face, _head) # (its face)
	_part(Vector3(0.0, 0.4, -3.9), Vector3(1.6, 1.4, 0.6), dark, _head) # (the bullseye on its brow)
	_part(Vector3(0.0, 0.4, -4.0), Vector3(0.7, 0.6, 0.4), face, _head)
	for side: float in [-1.0, 1.0]: # (its mandibles, under its lip)
		var m := Node3D.new()
		m.position = Vector3(1.0 * side, -3.4, -3.0)
		_head.add_child(m)
		_part(Vector3(0.0, -0.4, -0.3), Vector3(1.4, 1.3, 1.1), _mat(Color(0.45, 0.42, 0.18), 0.4), m)
		m.set_meta("side", side)
		_mands.append(m)
	for side: float in [-1.0, 1.0]: # (its antennae: tiny bristles)
		var a := _bone(dark, _head)
		_seg_to(a, Vector3(0.9 * side, 0.9, -3.4), Vector3(1.4 * side, 2.0, -4.6), 0.12)
	# the abdomen: ten segments in a chain, each its own node (it curls)
	var col := BLUE if male else VIOLET
	var prev: Node3D = _body
	var at := Vector3(0.0, 0.6, 5.2)
	for i in SEGS.size():
		var s: Array = SEGS[i]
		var n := Node3D.new()
		n.position = at
		prev.add_child(n)
		_segs.append(n)
		var c := GREEN if i < 2 else col
		var m := _tmat(c, 0.35, 0.5)
		_part(Vector3(0.0, 0.0, float(s[0]) * 0.5), Vector3(float(s[1]) * 2.0, float(s[1]) * 1.9, float(s[0]) * 1.12), m, n)
		if i >= 2: # (the black stripe down its back, rings at the joints)
			_part(Vector3(0.0, float(s[1]) * 0.72, float(s[0]) * 0.5), Vector3(float(s[1]) * 0.7, float(s[1]) * 0.55, float(s[0]) * 1.05), dark, n)
			_part(Vector3(0.0, 0.0, float(s[0]) * 0.97), Vector3(float(s[1]) * 2.05, float(s[1]) * 1.95, 0.6), dark, n)
		prev = n
		at = Vector3(0.0, 0.0, float(s[0]))
	# (its tip: a male's claspers; a female's short cerci)
	for side: float in [-1.0, 1.0]:
		var cl := _bone(dark, _segs[-1])
		_seg_to(cl, Vector3(0.5 * side, 0.3, 2.8), Vector3(0.7 * side, 0.1, 5.6 if male else 4.0), 0.3)
	if male:
		var cl2 := _bone(dark, _segs[-1])
		_seg_to(cl2, Vector3(0.0, -0.6, 2.6), Vector3(0.0, -0.2, 4.8), 0.3)
	# the wings: fore and hind, out from its back
	for k in 4:
		var hind := k >= 2
		var side := 1.0 if k % 2 == 0 else -1.0
		var h := Node3D.new()
		h.position = Vector3(1.6 * side, 4.2, 2.2 if hind else -2.0)
		_body.add_child(h)
		var w := MeshInstance3D.new()
		w.mesh = _wing_mesh(46.0 if hind else 48.0, 15.0 if hind else 10.5, hind)
		w.scale = Vector3(side, 1.0, 1.0)
		var wm := ShaderMaterial.new()
		wm.shader = _wing_shader()
		wm.set_shader_parameter("amber", 0.0 if male else 0.25)
		w.material_override = wm
		h.add_child(w)
		h.set_meta("side", side)
		h.set_meta("hind", hind)
		_wings.append(h)
	# the legs: six, dark, spiny, from under its thorax
	var lm := _mat(Color(0.12, 0.1, 0.08), 0.5)
	for p in 3:
		for side: float in [-1.0, 1.0]:
			var hp: Vector3 = LEG_HIPS[p]
			var hip := Node3D.new()
			hip.position = Vector3(hp.x * side, hp.y, hp.z)
			_body.add_child(hip)
			_legs.append([hip, _bone(lm, _body), _bone(lm, _body), p, side])


## A wing's outline (mm: out along +x, its leading edge -z): long, its
## root narrow, the hindwing's broad at its base.
static func _wing_mesh(len_: float, chord: float, hind: bool) -> ArrayMesh:
	const N := 14
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := []
	for i in N + 1:
		var t := float(i) / N
		var x := t * len_
		var lead := -chord * 0.28 * (1.0 - pow(t, 6.0)) * minf(t * 6.0 + 0.25, 1.0)
		var w := chord * (sin(PI * minf(t * 0.94 + 0.06, 1.0)) * 0.6 + 0.45 * (1.0 - t)) * (1.4 if hind and t < 0.35 else 1.0)
		var trail := lead + w * minf(t * 4.0 + 0.3, 1.0)
		if t >= 0.999:
			trail = lead
		pts.append([Vector3(x, 0.0, lead), Vector3(x, 0.0, trail), t])
	for i in N:
		var a: Array = pts[i]
		var b: Array = pts[i + 1]
		for v in [[a[0], a[2], 0.0], [b[0], b[2], 0.0], [b[1], b[2], 1.0], [a[0], a[2], 0.0], [b[1], b[2], 1.0], [a[1], a[2], 1.0]]:
			st.set_uv(Vector2(float(v[1]), float(v[2])))
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])
	return st.commit()


## The wings' membrane: clear, a little iridescent, finely netted, the
## veins darker toward the leading edge; the pterostigma tan; a female's
## faintly amber.
static func _wing_shader() -> Shader:
	if _wing_sh == null:
		_wing_sh = Shader.new()
		_wing_sh.code = """shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform float amber = 0.0;
uniform float blur = 0.0; // (beating: a haze)
void fragment() {
	float t = UV.x; // (root .. tip)
	float c = UV.y; // (leading .. trailing edge)
	vec2 g = fract(vec2(t * 70.0, c * 9.0 + t * 3.0));
	float vein = max(1.0 - smoothstep(0.0, 0.08, min(g.x, 1.0 - g.x)), 1.0 - smoothstep(0.0, 0.06, min(g.y, 1.0 - g.y)));
	float lead = 1.0 - smoothstep(0.0, 0.08, c);
	vec3 col = mix(vec3(0.85, 0.88, 0.9), vec3(0.88, 0.7, 0.4), amber * (1.0 - t * 0.6));
	col = mix(col, vec3(0.1, 0.1, 0.1), max(vein * 0.7, lead * 0.9));
	float stig = step(0.82, t) * step(t, 0.9) * (1.0 - smoothstep(0.1, 0.16, c));
	col = mix(col, vec3(0.5, 0.36, 0.18), stig);
	ALBEDO = col;
	float a = 0.1 + 0.55 * vein + 0.8 * lead + 0.9 * stig;
	ALPHA = clamp(mix(a, 0.12, blur), 0.0, 1.0);
	SPECULAR = 0.9;
	ROUGHNESS = 0.15;
	RIM = 0.5;
}
"""
	return _wing_sh


func _build_nymph() -> void:
	var olive := _mat(Color(0.33, 0.3, 0.17), 0.7)
	var olive_dk := _mat(Color(0.22, 0.2, 0.12), 0.7)
	var dark := _mat(DARK, 0.4)
	_part(Vector3(0.0, 0.0, 0.0), Vector3(7.5, 5.5, 9.0), olive, _body) # (its thorax)
	_head = Node3D.new()
	_head.position = Vector3(0.0, 0.4, -6.0)
	_body.add_child(_head)
	_part(Vector3(0.0, 0.0, -1.2), Vector3(8.5, 4.8, 5.0), olive, _head)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(3.0 * side, 1.0, -1.6), Vector3(3.2, 3.0, 3.6), _mat(Color(0.2, 0.18, 0.12), 0.3, 0.5), _head)
	# (the mask: its hinged lower lip, folded under its head, shot out)
	_mask_n = Node3D.new()
	_mask_n.position = Vector3(0.0, -2.2, 0.8)
	_head.add_child(_mask_n)
	_part(Vector3(0.0, 0.0, -2.2), Vector3(4.2, 1.0, 5.0), olive_dk, _mask_n)
	_mask_stalk = _part(Vector3(0.0, 0.0, 0.0), Vector3(1.6, 0.8, 1.0), olive_dk, _head) # (its stalk: the hinge out to it)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.4 * side, 0.2, -4.9), Vector3(1.2, 0.8, 1.6), dark, _mask_n) # (its palps' hooks)
	# its wing pads
	for side: float in [-1.0, 1.0]:
		var wp := _part(Vector3(1.6 * side, 2.6, 4.0), Vector3(2.6, 0.8, 9.0), olive_dk, _body)
		wp.rotation.y = 0.12 * side
	# its abdomen: broad, tapering, mottled
	var prev: Node3D = _body
	var at := Vector3(0.0, 0.0, 4.2)
	for i in N_SEGS.size():
		var s: Array = N_SEGS[i]
		var n := Node3D.new()
		n.position = at
		prev.add_child(n)
		_segs.append(n)
		_part(Vector3(0.0, 0.0, float(s[0]) * 0.5), Vector3(float(s[1]) * 2.0, float(s[1]) * 1.3, float(s[0]) * 1.15), olive if i % 2 == 0 else olive_dk, n)
		prev = n
		at = Vector3(0.0, 0.0, float(s[0]))
	for k in 3: # (the spines at its tip)
		var sp := _bone(dark, _segs[-1])
		_seg_to(sp, Vector3(0.0, 0.0, 1.8), Vector3((k - 1) * 0.9, 0.0, 4.0), 0.3)
	var lm := _mat(Color(0.28, 0.25, 0.15), 0.7)
	for p in 3:
		for side: float in [-1.0, 1.0]:
			var hip := Node3D.new()
			hip.position = Vector3(2.8 * side, -1.2, -2.0 + 2.2 * p)
			_body.add_child(hip)
			_legs.append([hip, _bone(lm, _body), _bone(lm, _body), p, side])


# --- what it does ---------------------------------------------------------------

func patrol(centre: Vector3, radius := 1.0) -> void:
	_go_mode("patrol")
	_centre = centre
	_radius = radius
	_take_off()


func perch(at := Vector3.INF) -> void:
	_go_mode("perch")
	_perch = at if at != Vector3.INF else _nearest_perch()
	if _perch == Vector3.INF:
		patrol(_pos, 0.8)


func hunt(prey: Node3D) -> void:
	if prey == null or nymph:
		return
	_go_mode("hunt")
	_prey = prey
	_take_off()


func lay() -> void:
	if male or nymph or stems.is_empty():
		return
	_go_mode("lay")
	_stem = stems[rng.randi() % stems.size()]
	_take_off()


func flee(from: Vector3) -> void:
	if nymph:
		_go_mode("crawl")
		var a := Vector3(_pos.x - from.x, 0.0, _pos.z - from.z).normalized()
		_target = _clamp_pond(_pos + a * 0.25)
		return
	_go_mode("flee")
	_from = from
	_take_off()


## A nymph's: about the pond's floor.
func crawl(centre: Vector3, radius := 0.3) -> void:
	_go_mode("crawl")
	_centre = centre
	_radius = radius


## A nymph's: the mask shot out at at (prey), and back, chewing.
func strike(at: Vector3) -> void:
	_go_mode("strike")
	_target = at


## A nymph's: up a stem out of the water, and the adult out of its skin.
func emerge() -> void:
	if not nymph or stems.is_empty():
		return
	_go_mode("emerge")
	size = maxf(size, 0.6) # (its last instar: full grown)
	var best: Array = stems[0]
	for s: Array in stems:
		if (s[0] as Vector3).distance_to(_pos) < (best[0] as Vector3).distance_to(_pos):
			best = s
	_stem = best


func _go_mode(m: String) -> void:
	if _held_prey and m != "eat":
		_held_prey.queue_free()
		_held_prey = null
	_mode = m
	_stage = 0
	_st = 0.0
	_wait = 0.0
	_curl_to = 0.0


func _take_off() -> void:
	if _perched:
		_perched = false
		_vel = Vector3.UP * 0.4


# --- mating ------------------------------------------------------------------------

## (A male's) mating with her: see the class. False if he can't.
func mate(partner: Node3D, secs := 12.0) -> bool:
	if partner == null or not (partner is Dragonfly) or nymph or not male or _role != "":
		return false
	var her := partner as Dragonfly
	if her.male or her.nymph or her._role != "":
		return false
	_mate = her
	_role = "male"
	her._mate = self
	her._role = "female"
	her._go_mode("courted")
	_go_mode("mate")
	_wait = secs
	_take_off()
	return true


func _end_mate() -> void:
	var her := _mate
	_mate = null
	_role = ""
	if is_instance_valid(her):
		her._mate = null
		her._role = ""
		her._held_by = null
		her._hold_pose = ""
		her._vel = Vector3(rng.randf_range(-0.3, 0.3), 0.3, rng.randf_range(-0.3, 0.3))
		her.patrol(pond[0] + Vector3(0.0, 0.5, 0.0), 1.0)
	patrol(pond[0] + Vector3(0.0, 0.6, 0.0), 1.1)


## (His) where his claspers are: its parent's space.
func _tip() -> Vector3:
	return _local(_segs[-1], Vector3(0.0, 0.2, 5.0))


func _local(n: Node3D, p: Vector3) -> Vector3:
	return (get_parent() as Node3D).global_transform.affine_inverse() * (n.global_transform * p) if get_parent() is Node3D else n.global_transform * p


## (Hers) carried: her head held at his tip, her body as the pose says.
func _carry(dt: float) -> void:
	var him := _held_by
	var hb := Basis.from_euler(Vector3(him._pitch, him._yaw, him._roll))
	var b: Basis
	match _hold_pose:
		"wheel":
			# (hanging under his abdomen, her body forward and down, her abdomen curled up to him)
			var fw := -hb.z
			var d := (fw * 1.0 - hb.y * 0.7).normalized() # (head to tail: forward under his abdomen)
			var up := (-hb.y - d * (-hb.y).dot(d)).normalized()
			b = Basis(up.cross(d).normalized(), up, d).orthonormalized()
			_curl_to = -0.55 # (up to the base of his)
		"lay":
			b = hb * Basis(Vector3.RIGHT, -0.35)
			_curl_to = 0.5
		_:
			b = hb * Basis(Vector3.RIGHT, -0.08)
			_curl_to = 0.05
	var e := b.get_euler()
	_pitch = lerp_angle(_pitch, e.x, 1.0 - exp(-8.0 * dt))
	_yaw = lerp_angle(_yaw, e.y, 1.0 - exp(-8.0 * dt))
	_roll = lerp_angle(_roll, e.z, 1.0 - exp(-8.0 * dt))
	var bb := Basis.from_euler(Vector3(_pitch, _yaw, _roll))
	_pos = him._tip() - bb * (Vector3(0.0, 2.2, -8.8) * MM * size) # (the back of her head at his claspers)
	_beat_to = 1.0 if not him._perched or _hold_pose == "lay" else 0.0
	_perched = him._perched


# --- the motor -------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	_t += dt
	_st += dt
	_wait -= dt
	if _pilot:
		_pilot.tick(dt)
	if is_instance_valid(_held_by) and _role == "female":
		_carry(dt)
	elif nymph:
		_think_nymph(dt)
	else:
		if not _piloting:
			_think(dt)
		_fly(dt)
	_place(dt)
	_pose(dt)


func _think(dt: float) -> void:
	match _mode:
		"patrol":
			_beat_to = 1.0
			if _wait <= 0.0 or _pos.distance_to(_target) < 0.08:
				# (a beat: out across and back; now and then a hover)
				var a := rng.randf() * TAU
				_target = _centre + Vector3(cos(a) * _radius * rng.randf_range(0.4, 1.0), rng.randf_range(0.25, 0.7), sin(a) * _radius * rng.randf_range(0.4, 1.0))
				_speed = rng.randf_range(0.8, 1.6)
				_wait = rng.randf_range(1.0, 3.0)
				if rng.randf() < 0.25:
					_target = _pos
					_wait = rng.randf_range(0.6, 1.4)
				if rng.randf() < 0.08 and not perches.is_empty() and _st > 6.0:
					perch()
		"perch":
			match _stage:
				0: # (to over it)
					_target = _perch + Vector3(0.0, 0.05, 0.0)
					_speed = 0.9
					if _pos.distance_to(_target) < 0.03:
						_stage = 1
				1: # (down onto it)
					_target = _perch + Vector3(0.0, BODY_H * MM, 0.0)
					_speed = 0.15
					if _pos.distance_to(_target) < 0.006:
						_perched = true
						_vel = Vector3.ZERO
						_stage = 2
						_st = 0.0
						_wait = rng.randf_range(6.0, 12.0)
				2: # (sitting: its head turning after things)
					_beat_to = 0.0
					if rng.randf() < dt * 0.7:
						_look_to = Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.3, 0.4))
					if _wait <= 0.0:
						_look_to = Vector2.ZERO
						patrol(_centre if _centre != Vector3.ZERO else pond[0], maxf(_radius, 0.8))
		"hunt":
			if not is_instance_valid(_prey):
				patrol(pond[0], 1.0)
				return
			# (to where it'll be: led a little)
			var pv: Variant = _prey.get("vel") if _prey.get("vel") != null else _prey.get("_vel") # (where it's going: led)
			var lead := (pv as Vector3) * 0.15 if pv is Vector3 else Vector3.ZERO
			_target = _prey.position + lead
			_speed = 2.2
			_look_to = Vector2(0.0, -0.2)
			if _pos.distance_to(_prey.position) < 0.035:
				# (swept up in its legs' basket, to its mouth)
				_held_prey = _prey
				_prey = null
				_held_prey.set("caught", true)
				MealScript.subdue(_held_prey) # (a live insect: still in its legs)
				var gx := _held_prey.global_transform
				_held_prey.get_parent().remove_child(_held_prey)
				_head.add_child(_held_prey)
				_held_prey.global_transform = gx
				_held_prey.position = Vector3(0.0, -4.0, -3.5)
				_held_prey.scale = Vector3.ONE / (MM * size) # (its own size still, under the head's mm)
				_meal = null
				_mode = "eat"
				_stage = 0
				_st = 0.0
				_wait = 5.0
				var near := _nearest_perch()
				_perch = near
		"eat":
			_chew = 1.0
			if _perch != Vector3.INF and _stage == 0:
				_target = _perch + Vector3(0.0, BODY_H * MM, 0.0)
				_speed = 0.8
				if _pos.distance_to(_target) < 0.01:
					_perched = true
					_vel = Vector3.ZERO
					_stage = 1
			elif _perch == Vector3.INF:
				_target = _pos # (eaten on the wing, hovering)
			if _perched:
				_beat_to = 0.0
			if is_instance_valid(_held_prey): # (chewed up, a piece at a time)
				if _meal == null:
					_meal = MealScript.of(_held_prey, 3)
					if _meal:
						_meal.set("held", true) # (in its mouth: the bite it's at drawn in to it)
				if _meal:
					_meal.call("tear", clampf(1.0 - (_wait - 0.4) / 4.4, 0.0, 1.0), _head.global_transform * Vector3(0.0, -2.5, -3.0))
			if _wait <= 0.0:
				_chew = 0.0
				if _held_prey:
					_held_prey.queue_free()
					_held_prey = null
				patrol(pond[0], 1.0)
		"lay":
			var foot: Vector3 = _stem[0]
			var by := Vector3(foot.x, water_y, foot.z) + Vector3(0.0, 0.0, 0.028)
			match _stage:
				0:
					_target = by + Vector3(0.0, 0.03, 0.0)
					_speed = 1.0
					if _pos.distance_to(_target) < 0.02:
						_stage = 1
						_st = 0.0
				1: # (hovering low by it, her abdomen down into it, under the water)
					_target = by + Vector3(0.0, 0.035, 0.0)
					_speed = 0.2
					_curl_to = 0.55 + 0.1 * sin(_st * 3.0)
					_face_to(foot)
					if _st > 2.4:
						_eggs_into(_stem)
						_curl_to = 0.0
						_stage = 2
						_st = 0.0
				2:
					if _st > 0.6:
						if rng.randf() < 0.6:
							_stem = stems[rng.randi() % stems.size()]
							_stage = 0
						else:
							patrol(pond[0], 1.0)
		"flee":
			var away := Vector3(_pos.x - _from.x, 0.0, _pos.z - _from.z).normalized()
			_target = _pos + away * 0.5 + Vector3(0.0, 0.3, 0.0)
			_speed = 3.0
			if _st > 1.5:
				patrol(pond[0], 1.2)
		"courted": # (a female, flying on, till he has her)
			_beat_to = 1.0
			if _perched:
				_take_off()
			if _target == Vector3.ZERO or _pos.distance_to(_target) < 0.05:
				var a := rng.randf() * TAU
				_target = pond[0] + Vector3(cos(a) * 0.6, 0.45, sin(a) * 0.6)
			_speed = 0.7
		"mate":
			_mate_think(dt)


func _mate_think(_dt: float) -> void:
	var her := _mate
	if not is_instance_valid(her):
		_end_mate()
		return
	match _stage:
		0: # (after her: up over and just ahead of her)
			var hb := Basis.from_euler(Vector3(her._pitch, her._yaw, her._roll))
			_target = her._pos + hb * (Vector3(0.0, 9.0, -58.0) * MM)
			_speed = 2.0
			if _pos.distance_to(_target) < 0.03 or _st > 8.0:
				her._held_by = self
				her._hold_pose = "tandem"
				her._mode = "held"
				_stage = 1
				_st = 0.0
				_perch = _nearest_perch()
		1: # (in tandem, to a perch)
			if _perch == Vector3.INF:
				_target = pond[0] + Vector3(0.0, 0.4, 0.0)
				if _st > 3.0:
					her._hold_pose = "wheel"
					_stage = 3
					_st = 0.0
				return
			_target = _perch + Vector3(0.0, 0.06, 0.0)
			_speed = 0.7
			if _pos.distance_to(_target) < 0.03:
				_stage = 2
		2:
			_target = _perch + Vector3(0.0, BODY_H * MM, 0.0)
			_speed = 0.12
			if _pos.distance_to(_target) < 0.006:
				_perched = true
				_vel = Vector3.ZERO
				her._hold_pose = "wheel"
				_stage = 3
				_st = 0.0
		3: # (the wheel, a while)
			_beat_to = 0.0 if _perched else 1.0
			_curl_to = 0.12
			if _st > maxf(_wait, 6.0):
				her._hold_pose = "tandem"
				_take_off()
				_stage = 4
				_st = 0.0
				_curl_to = 0.0
				_stem = stems[rng.randi() % stems.size()] if not stems.is_empty() else []
		4: # (in tandem to the water: she lays, held upright over her)
			if _stem.is_empty():
				_end_mate()
				return
			var foot: Vector3 = _stem[0]
			var hold := Vector3(foot.x, water_y, foot.z) + Vector3(0.0, 0.1, 0.06)
			_target = hold
			_speed = 0.6
			_face_to(foot)
			if _pos.distance_to(hold) < 0.025:
				her._hold_pose = "lay"
				if _st > 3.0:
					her._eggs_into(_stem)
					her._hold_pose = "tandem"
					_stage = 5
					_st = 0.0
			else:
				_st = 0.0
		5:
			if _st > 0.8:
				_end_mate()


## Its eggs put into a stem under the water (a row of pale specks).
func _eggs_into(stem: Array) -> void:
	var e := Eggs.new()
	e.maker = get_script()
	e.at = Vector3((stem[0] as Vector3).x, water_y - 0.012, (stem[0] as Vector3).z)
	e.dragonfly = self
	get_parent().add_child(e)
	eggs_laid.append(e)


func _face_to(p: Vector3) -> void:
	var d := Vector3(p.x - _pos.x, 0.0, p.z - _pos.z)
	if d.length() > 0.005:
		_yaw = lerp_angle(_yaw, atan2(-d.x, -d.z), 0.08)


func _nearest_perch() -> Vector3:
	var best := Vector3.INF
	for p: Vector3 in perches:
		if best == Vector3.INF or p.distance_to(_pos) < best.distance_to(_pos):
			best = p
	return best


## In the air: toward _target at up to _speed, quick to turn and stop
## (it can hover), banking into its turns; perched, still.
func _fly(dt: float) -> void:
	if _perched:
		_vel = Vector3.ZERO
		return
	var to := _target - _pos
	var d := to.length()
	var want := to / maxf(d, 1e-4) * _speed * clampf(d / 0.15, 0.0, 1.0)
	var acc := 9.0
	var dv := (want - _vel).limit_length(acc * dt)
	_vel += dv
	# (a hover's jitter)
	_vel += Vector3(sin(_t * 7.3), sin(_t * 5.1) * 0.6, cos(_t * 6.7)) * 0.04 * dt * 60.0 * (1.0 - clampf(_vel.length() / 0.5, 0.0, 1.0)) * 0.02
	_pos += _vel * dt
	var ground := _ground_at(_pos.x, _pos.z) + 0.03
	_pos.y = maxf(_pos.y, ground)
	var hs := Vector2(_vel.x, _vel.z).length()
	if hs > 0.12 and _mode != "lay" and not (_mode == "mate" and _stage == 4):
		var y := atan2(-_vel.x, -_vel.z)
		var turn := wrapf(y - _yaw, -PI, PI)
		_yaw += clampf(turn, -6.0 * dt, 6.0 * dt)
		_roll = lerpf(_roll, clampf(-turn * 1.2, -0.7, 0.7), 1.0 - exp(-5.0 * dt))
	else:
		_roll = lerpf(_roll, 0.0, 1.0 - exp(-4.0 * dt))
	_pitch = lerpf(_pitch, clampf(-hs * 0.12 + _vel.y * 0.3, -0.3, 0.4), 1.0 - exp(-5.0 * dt))


func _ground_at(x: float, z: float) -> float:
	var c: Vector3 = pond[0]
	var e: Vector2 = pond[1]
	if absf(x - c.x) < e.x and absf(z - c.z) < e.y:
		return water_y
	return float(height.call(x, z)) if height.is_valid() else 0.0


func _clamp_pond(p: Vector3) -> Vector3:
	var c: Vector3 = pond[0]
	var e: Vector2 = pond[1]
	return Vector3(clampf(p.x, c.x - e.x * 0.9, c.x + e.x * 0.9), p.y, clampf(p.z, c.z - e.y * 0.9, c.z + e.y * 0.9))


# --- the nymph ---------------------------------------------------------------------

func _think_nymph(dt: float) -> void:
	_beat_to = 0.0
	size = move_toward(size, 0.62, dt / 240.0) # (growing, moult by moult)
	var spd := 0.02
	match _mode:
		"crawl":
			if _wait <= 0.0 or Vector2(_pos.x - _target.x, _pos.z - _target.z).length() < 0.01:
				var a := rng.randf() * TAU
				_target = _clamp_pond(_centre + Vector3(cos(a), 0.0, sin(a)) * _radius * rng.randf())
				_wait = rng.randf_range(3.0, 7.0)
				if rng.randf() < 0.35:
					_target = _pos
			_walk(dt, Vector3(_target.x, floor_y, _target.z), spd)
		"strike":
			_face_to(_target)
			var k := _st
			_mask = clampf(k / 0.08, 0.0, 1.0) if k < 0.3 else clampf(1.0 - (k - 0.3) / 0.25, 0.0, 1.0)
			_chew = 1.0 if k > 0.55 else 0.0
			if k > 3.5:
				_chew = 0.0
				crawl(_pos, 0.25)
		"emerge":
			var foot: Vector3 = _stem[0]
			var tip: Vector3 = _stem[1]
			match _stage:
				0: # (to the stem's foot)
					var at := Vector3(foot.x, floor_y, foot.z + 0.012)
					_walk(dt, at, spd * 1.5)
					if Vector2(_pos.x - at.x, _pos.z - at.z).length() < 0.006:
						_stage = 1
						_climb = 0.0
				1: # (up it, out of the water)
					var top := minf(water_y + 0.06, tip.y - 0.02)
					_climb = move_toward(_climb, 1.0, dt * 0.08)
					_pos = Vector3(foot.x, lerpf(floor_y, top, _climb), foot.z + 0.012)
					_pitch = lerpf(_pitch, -PI * 0.5 + 0.15, 1.0 - exp(-3.0 * dt)) # (head up the stem)
					if _climb >= 1.0:
						_stage = 2
						_st = 0.0
				2: # (still, drying)
					if _st > 3.0:
						_split()


## Walking (a nymph: on the floor), toward at at speed.
func _walk(dt: float, at: Vector3, spd: float) -> void:
	var d := Vector3(at.x - _pos.x, 0.0, at.z - _pos.z)
	if d.length() > 0.004:
		var y := atan2(-d.x, -d.z)
		_yaw += clampf(wrapf(y - _yaw, -PI, PI), -2.0 * dt, 2.0 * dt)
		_pos += Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * spd * dt * clampf(d.length() / 0.02, 0.2, 1.0)
		_vel = Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * spd
	else:
		_vel = Vector3.ZERO
	_pos.y = floor_y
	_pitch = lerpf(_pitch, 0.0, 1.0 - exp(-4.0 * dt))


## Its back splits: the empty skin left on the stem; the adult out of it.
func _split() -> void:
	var skin := _body
	var gx := skin.global_transform
	remove_child(skin)
	var ex := Node3D.new() # (the exuvia: its parts, papery tan, translucent)
	get_parent().add_child(ex)
	ex.global_transform = Transform3D.IDENTITY
	ex.add_child(skin)
	skin.global_transform = gx
	var pm := _mat(Color(0.62, 0.52, 0.34, 0.7), 0.7)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mi in skin.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = pm
	ex.set_meta("exuvia", true)
	# the adult: soft, pale, its wings crumpled, clinging over the skin
	nymph = false
	size = 1.0
	_segs.clear()
	_legs.clear()
	_wings.clear()
	_mands.clear()
	_mats.clear()
	_body = Node3D.new()
	add_child(_body)
	male = rng.randf() < 0.5
	_build_adult()
	_teneral = 0.0
	_wings_out = 0.15
	_pos += Vector3(0.0, 0.025, -0.006)
	_perched = true
	_vel = Vector3.ZERO
	_mode = "teneral"
	_st = 0.0


func _teneral_think(dt: float) -> void:
	_beat_to = 0.0
	_wings_out = move_toward(_wings_out, 1.0, dt / 14.0)
	if _wings_out >= 1.0:
		_teneral = move_toward(_teneral, 1.0, dt / 8.0)
	if _teneral >= 1.0:
		patrol(pond[0], 1.0)


# --- the pose -------------------------------------------------------------------

func _place(_dt: float) -> void:
	var b := Basis.from_euler(Vector3(_pitch, _yaw, _roll))
	transform = Transform3D(b, _pos)
	if _body:
		_body.scale = Vector3.ONE * MM * size


func _pose(dt: float) -> void:
	if _mode == "teneral":
		_teneral_think(dt)
	_beat = move_toward(_beat, _beat_to, dt * 6.0)
	_curl = lerpf(_curl, _curl_to, 1.0 - exp(-4.0 * dt))
	_look = _look.lerp(_look_to, 1.0 - exp(-6.0 * dt))
	_head.rotation = Vector3(_look.y, _look.x, 0.0)
	# the abdomen: each joint bent its share (+ down, - up)
	var n := _segs.size()
	for i in n:
		var share := 0.0 if i < 2 else float(i - 1) / float(n - 1)
		_segs[i].rotation.x = -_curl * share * 0.9 - (0.03 if not nymph else 0.0)
	# the wings: beating (fore and hind a little out of step), or out flat
	var ph := _t * TAU * 28.0
	for w in _wings:
		var side: float = w.get_meta("side")
		var hind: bool = w.get_meta("hind")
		var flap := sin(ph + (1.3 if hind else 0.0)) * 0.75 * _beat
		var droop := -0.12 * (1.0 - _beat)
		var sweep := (0.18 if not hind else -0.05) * (1.0 - _beat) # (at rest: the forewings a little forward)
		var crump := lerpf(0.25, 1.0, _wings_out)
		w.transform.basis = Basis(Vector3.UP, sweep * side) * Basis(Vector3.BACK, (flap + droop) * side) * Basis.from_scale(Vector3(crump, 1.0, lerpf(0.5, 1.0, _wings_out)))
		var wm := (w.get_child(0) as MeshInstance3D).material_override as ShaderMaterial
		wm.set_shader_parameter("blur", _beat * 0.6)
	# the legs: a basket held forward under it in flight; perched, gripping
	for L: Array in _legs:
		var hip: Node3D = L[0]
		var p: int = L[3]
		var side: float = L[4]
		var a := hip.position
		var knee: Vector3
		var foot: Vector3
		if nymph:
			var sw := sin(_t * 9.0 + p * 2.1 + (PI if side > 0.0 else 0.0)) * clampf(_vel.length() / 0.01, 0.0, 1.0)
			knee = a + Vector3(3.5 * side, 2.0, (p - 1) * 2.0)
			foot = Vector3(a.x + 7.0 * side, -3.5 + maxf(sw, 0.0) * 1.2, a.z + (p - 1) * 3.0 + sw * 1.5)
		elif _perched:
			knee = a + Vector3(2.4 * side, 1.5, (p - 1) * 2.4)
			foot = Vector3(0.9 * side, -BODY_H - 0.3, -2.0 + p * 1.6)
		else:
			var l: Array = LEG_LEN[p]
			knee = a + Vector3(1.2 * side, -0.8, -float(l[0]) * 0.85)
			foot = knee + Vector3(0.6 * side, -2.5, float(l[1]) * 0.5)
		_seg_to(L[1], a, knee, 0.5)
		_seg_to(L[2], knee, foot, 0.35)
	for m in _mands:
		var side: float = m.get_meta("side")
		m.rotation.y = side * 0.35 * _chew * maxf(sin(_t * 12.0), 0.0)
	if _mask_n:
		_mask_n.position = Vector3(0.0, -2.2, 0.8 - _mask * 10.0)
		_mask_n.rotation.x = -0.4 * _mask
		_seg_to_part(_mask_stalk, Vector3(0.0, -2.4, 0.4), _mask_n.position + Vector3(0.0, 0.0, 0.4), 0.8)
	# (teneral: pale, its colour coming)
	if _teneral < 1.0:
		for mc: Array in _mats:
			(mc[0] as StandardMaterial3D).albedo_color = (Color(0.85, 0.84, 0.72) as Color).lerp(mc[1], _teneral)


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
	if nymph:
		_mode = "crawl"
		_target = point
		_wait = 999.0
		return
	_take_off()
	_target = point
	_speed = speed if speed > 0.0 else 1.0


func _p_hold() -> void:
	_piloting = true
	_target = _pos


func _p_mobile() -> bool:
	return _mode != "teneral" and _role != "female"


func _p_speed() -> float:
	return 0.02 if nymph else 1.0


func _p_reach() -> float:
	return 0.01 if nymph else 0.04


func _p_behaviours() -> PackedStringArray:
	if nymph:
		return PackedStringArray(["crawl", "strike", "emerge"])
	var b := PackedStringArray(["patrol", "perch", "hunt", "flee", "mate"])
	if not male:
		b.append("lay")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	_piloting = false
	match name:
		"patrol":
			patrol(args.get("centre", pond[0]), float(args.get("radius", 1.0)))
		"perch":
			perch(args.get("at", Vector3.INF))
		"hunt":
			if args.get("prey") == null:
				return false
			hunt(args.prey)
		"lay":
			if male or stems.is_empty():
				return false
			lay()
		"flee":
			flee(args.get("from", _pos + Vector3.FORWARD))
		"mate":
			return mate(args.get("partner"), float(args.get("seconds", 12.0)))
		"crawl":
			crawl(args.get("centre", _pos), float(args.get("radius", 0.25)))
		"strike":
			strike(args.get("at", _pos + _p_heading() * 0.02))
		"emerge":
			if not nymph:
				return false
			emerge()
		_:
			return false
	_p_done = false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"perch":
			return _perched and _mode == "perch"
		"hunt":
			return _mode not in ["hunt", "eat"]
		"lay":
			return _mode != "lay"
		"mate":
			return _role == ""
		"strike":
			return _mode != "strike"
		"emerge":
			return not nymph and _mode != "teneral"
	return false


func _p_act_secs(name: String) -> float:
	match name:
		"patrol", "crawl":
			return 12.0
	return -1.0


# --- props -------------------------------------------------------------------------

## Eggs put into a stem under the water: a row of pale specks; hatch()
## (or a while after) the nymphs out onto the pond's floor.
class Eggs extends Node3D:
	var maker: Script
	var dragonfly: Node3D
	var at := Vector3.ZERO
	var left := 45.0
	var _done := false

	func _ready() -> void:
		position = at # (where it is: its parts about it)
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.86, 0.82, 0.62)
		for k in 6:
			var e := MeshInstance3D.new()
			e.mesh = s
			e.material_override = m
			e.scale = Vector3(0.0012, 0.0026, 0.0012)
			e.position = Vector3(0.0035, -0.004 * k, 0.0)
			add_child(e)

	func _process(dt: float) -> void:
		left -= dt
		if left <= 0.0 and not _done:
			hatch()

	func hatch(n := 3) -> void:
		if _done or maker == null:
			return
		_done = true
		var d := dragonfly as Dragonfly
		for k in n:
			var ny: Node3D = maker.new(true)
			if is_instance_valid(d):
				for p in ["water_y", "floor_y", "pond", "stems", "perches", "height"]:
					ny.set(p, d.get(p))
			get_parent().add_child(ny)
			var a := randf() * TAU
			ny.call("place", at + Vector3(cos(a), 0.0, sin(a)) * 0.04, randf() * TAU)
			ny.call("crawl", at, 0.25)
		queue_free()
