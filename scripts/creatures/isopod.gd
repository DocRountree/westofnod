class_name Isopod
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A pill bug (Armadillidium vulgare), drawn at twice life size (about 30
## mm long): an oval, high domed, slate grey, glossy, mottled with pale
## spots; its back plates overlapping, head to tail: the head (its eyes,
## its long bent antennae feeling the ground ahead), seven big plates over
## the body, five small ones, the tail's triangle and its little
## uropods; seven pairs of short legs under it, walked in two alternating
## sets down the body. Young (mancae: Isopod.new(true)): small, pale, only
## six pairs of legs; growing. Not yet in the game
## (tools/creatures/life_cycle_demo.tscn).
##
## - wander(centre, radius): trundling about, its antennae tapping
## - eat(at): at the leaf litter there, head down, its mouthparts working
## - roll(seconds): rolled up into a ball (its plates curling down and
##   under from its middle, the legs and head tucked in), then open again
## - lay(): the female's brood pouch under her front filling, swelling with
##   eggs (pill bugs carry their eggs: no laying them out)
## - hatch(): the young out of the pouch, walking out from under her
## Steering (pilot.gd): act eat {at, seconds}, roll {seconds}, lay.

const SEGS := 14 # head, 7 pereon plates, 5 pleon plates, the telson
const LEN := 15.0 # mm, head to tail

var young := false
var mancae: Array[Node3D] = [] ## its young, out of its pouch
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.1
var _wait := 0.0
var _st := 0.0
var _at := Vector3.ZERO
var _roll := 0.0 # 0 open .. 1 rolled up
var _roll_to := 0.0
var _chew := 0.0
var _brood := 0.0 # 0 .. 1: the pouch's eggs
var _plates: Array[Node3D] = [] # the chain's joints (front ones, then back)
var _seg_z: Array[float] = []
var _head: Node3D
var _antennae: Array[Node3D] = []
var _pouch: MeshInstance3D
var _eggs: Array[MeshInstance3D] = []
var _hatching := 0


func _init(young_ := false) -> void:
	young = young_
	super(young_, 0.16 if young_ else 1.0)
	body_h = 2.1
	walk_speed = 0.02
	stride = 3.0
	step_time = 0.12
	var pairs := 6 if young_ else 7
	var L := []
	var gr := [[], []]
	for p in pairs:
		var z := -4.2 + p * 1.25
		L.append({"hip": Vector3(2.3, -1.0, z), "f": 1.9, "t": 2.0, "s": 1.3, "home": Vector2(4.3, z + 0.2),
				"dangle": Vector3(1.6, -1.6, z), "pole": Vector3(0.7, 1.0, 0.0), "r": 0.22})
		gr[p % 2].append(p * 2)
		gr[(p + 1) % 2].append(p * 2 + 1)
	legs = L
	tripod = gr


func _build() -> void:
	var grey := Color(0.36, 0.37, 0.4) if not young else Color(0.78, 0.76, 0.72)
	var plate := _banded(grey, 0.0, 0.0, 0.35, 0.75)
	var under := _mat(grey.darkened(0.3), 0.6)
	# the plates, a chain from the middle out both ways (each on the next
	# toward the middle: they curl round it to roll up)
	var mid := 5 # (the fifth plate, the body's middle: the chain's root)
	var root := Node3D.new()
	root.position = Vector3(0.0, 0.0, _plate_z(mid))
	_body.add_child(root)
	_seg_z.resize(SEGS)
	var nodes: Array = []
	nodes.resize(SEGS)
	nodes[mid] = root
	for k in range(mid - 1, -1, -1):
		var n := Node3D.new()
		n.position = Vector3(0.0, 0.0, _plate_z(k) - _plate_z(k + 1))
		(nodes[k + 1] as Node3D).add_child(n)
		n.set_meta("dir", -1.0)
		nodes[k] = n
	for k in range(mid + 1, SEGS):
		var n := Node3D.new()
		n.position = Vector3(0.0, 0.0, _plate_z(k) - _plate_z(k - 1))
		(nodes[k - 1] as Node3D).add_child(n)
		n.set_meta("dir", 1.0)
		nodes[k] = n
	for k in SEGS:
		var nd: Node3D = nodes[k]
		var w := _plate_w(k)
		var l := _plate_len(k)
		# a plate: a dome over the body, its back edge lapping the next
		_part(Vector3(0.0, 0.0, l * 0.15), Vector3(w, w * 0.55, l * 1.55), plate, nd)
		if k > 0 and k < 8:
			_part(Vector3(0.0, -0.6, 0.0), Vector3(w * 0.8, 0.8, l * 1.2), under, nd) # (its underside)
		if k != mid:
			_plates.append(nd)
	# the head (on the first plate): its eyes, its bent antennae
	_head = nodes[0]
	var eye := _mat(Color(0.05, 0.05, 0.05), 0.2)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.5 * side, 0.6, -0.4), Vector3(0.6, 0.6, 0.6), eye, _head)
		var an := Node3D.new()
		an.position = Vector3(1.0 * side, -0.2, -1.0)
		_head.add_child(an)
		var ac := _mat(grey.lightened(0.1), 0.5)
		_stick(Vector3.ZERO, Vector3(1.4 * side, -0.3, -1.6), 0.18, ac, an)
		_stick(Vector3(1.4 * side, -0.3, -1.6), Vector3(1.8 * side, -1.2, -3.4), 0.14, ac, an)
		an.set_meta("side", side)
		_antennae.append(an)
	# the uropods at the tail
	var tail: Node3D = nodes[SEGS - 1]
	for side: float in [-1.0, 1.0]:
		_part(Vector3(0.9 * side, -0.3, 0.6), Vector3(0.9, 0.6, 1.0), plate, tail)
	# the brood pouch (a female's), under her front: swelling with eggs
	if not young:
		var pm := _mat(Color(0.88, 0.85, 0.75, 0.75), 0.3)
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_pouch = _part(Vector3(0.0, -1.6, -1.8), Vector3(3.2, 1.2, 4.4), pm)
		_pouch.visible = false
		var em := _mat(Color(0.95, 0.93, 0.85), 0.3)
		for k in 10:
			var e := _part(Vector3(randf_range(-1.0, 1.0), -1.6, -1.8 + randf_range(-1.5, 1.5)), Vector3.ONE * 0.55, em)
			e.visible = false
			_eggs.append(e)
	_build_legs(_mat(grey.lightened(0.25), 0.5), _mat(grey.lightened(0.3), 0.5))


func _plate_z(k: int) -> float:
	# (the head small, the pereon's seven plates long, the pleon's short)
	var z := -LEN * 0.5
	for j in k:
		z += _plate_len(j)
	return z + _plate_len(k) * 0.5


func _plate_len(k: int) -> float:
	if k == 0:
		return 1.4
	if k <= 7:
		return 1.45
	return 0.65 if k < 13 else 0.9


func _plate_w(k: int) -> float:
	var t := float(k) / (SEGS - 1)
	return 7.2 * (0.62 + 0.38 * sin(PI * clampf(t * 1.05 + 0.08, 0.0, 1.0))) * (0.85 if k == 0 else 1.0)


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_roll_to = 0.0


func eat(at: Vector3) -> void:
	_mode = "eat"
	_at = at
	_roll_to = 0.0


func roll(seconds := 5.0) -> void:
	_mode = "roll"
	_roll_to = 1.0
	_st = 0.0
	_wait = seconds
	_target = _pos


func lay() -> void:
	if young or _pouch == null:
		return
	_mode = "lay"
	_st = 0.0
	_target = _pos


## The young out of the pouch, walking out from under her.
func hatch() -> void:
	if _pouch == null or _brood < 0.5:
		return
	_hatching = 10
	_st = 0.0
	_mode = "hatch"
	_target = _pos


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	match _mode:
		"wander":
			if _wait <= 0.0:
				var a := rng.randf() * TAU
				_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius if rng.randf() < 0.75 else _pos
				_wait = rng.randf_range(2.0, 6.0)
		"eat":
			var away := _pos - _at
			away.y = 0.0
			away = away.normalized() if away.length() > 1e-4 else Vector3.BACK
			_target = _at + away * 8.0 * MM * size
			if _pos.distance_to(_target) < 0.003 and _speed < 0.003:
				_chew = 1.0
		"roll":
			_target = _pos
			if _wait <= 0.0 and _roll_to > 0.0:
				_roll_to = 0.0
				_st = 0.0
			elif _roll_to == 0.0 and _roll < 0.05:
				_mode = "idle"
		"lay": # (the eggs into her pouch: it swells)
			_brood = clampf(_st / 6.0, 0.0, 1.0)
			if _st > 6.0:
				_mode = "idle"
		"hatch":
			if _hatching > 0 and fmod(_st, 0.5) < dt and _st > 0.5:
				_hatching -= 1
				var parent := get_parent() as Node3D
				var y: Node3D = (get_script() as Script).new(true)
				parent.add_child(y)
				var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
				y.call("place", _pos + fwd * 0.004, _yaw + rng.randf_range(-1.2, 1.2))
				var a := rng.randf() * TAU
				y.call("wander", _pos + Vector3(cos(a), 0.0, sin(a)) * 0.05, 0.05)
				y.call("grow", 0.6, 120.0)
				mancae.append(y)
				_brood = float(_hatching) / 10.0
			if _hatching == 0:
				_brood = 0.0
				_mode = "idle"


func _pose(dt: float) -> void:
	_roll = move_toward(_roll, _roll_to, dt * 1.6)
	var k := _roll * _roll * (3.0 - 2.0 * _roll)
	# rolled: every joint bent down, so the plates close round into a ball
	for n in _plates:
		var d: float = n.get_meta("dir")
		n.rotation.x = d * 0.47 * k # (the front ones head down and under, the back ones tail down and under)
	# (a ball: up off its legs a little, settled on its round)
	_lift = -body_h * 0.2 * k
	# the legs tucked in, hidden, rolled
	for i in _leg_mesh.size():
		for m: MeshInstance3D in _leg_mesh[i]:
			m.visible = k < 0.6
	# the head down to eat, the antennae tapping the ground ahead
	_head.rotation.x = -0.47 * k - 0.2 * _chew * (0.5 + 0.5 * sin(_t * 7.0))
	for an in _antennae:
		var side: float = an.get_meta("side")
		an.rotation = Vector3(0.25 * sin(_t * 3.0 + side) - 0.6 * k, 0.2 * sin(_t * 1.7 + side * 2.0) * (1.0 - k), 0.0)
		an.visible = k < 0.8
	# the pouch, swelling with eggs
	if _pouch:
		_pouch.visible = _brood > 0.02 and k < 0.6
		_pouch.scale = Vector3(3.2, 0.4 + 1.0 * _brood, 4.4) * maxf(_brood, 0.3)
		for e in _eggs.size():
			_eggs[e].visible = _pouch.visible and float(e) / _eggs.size() < _brood


# --- steering (pilot.gd): its behaviours -------------------------------------------

## eat {at, seconds}, roll {seconds}, lay (the female's).
func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["eat", "roll"]) if young else PackedStringArray(["eat", "roll", "lay"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"eat":
			eat(args.get("at", _pos + _p_heading() * 0.012))
		"roll":
			roll(float(args.get("seconds", 5.0)))
		"lay":
			if young:
				return false
			lay()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"roll", "lay":
			return _mode != name
	return false


func _p_act_secs(name: String) -> float:
	return 8.0 if name == "eat" else -1.0


func _p_mobile() -> bool:
	return _roll < 0.1


func _piloted() -> void:
	if _mode in ["wander", "idle", "eat"]:
		_mode = "piloted"
