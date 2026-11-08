class_name Shrimp
extends "res://scripts/creatures/crayfish.gd" # (by path: found whether or not the editor has seen the class yet)
## A penaeid shrimp, drawn life size (about 15 cm), on the crayfish's motor
## and ways (Crayfish) but its own build: its body pressed in from the
## sides, high, the abdomen humped at its third segment; a long rostrum,
## toothed above, curving up a little; big black eyes on their stalks; its
## antennae thread-thin and twice its length or more, swept back over it;
## the antennal scales; its first three pairs of legs slender, with tiny
## pincers; long thin walking legs; big fringed swimmerets under the
## abdomen; a pointed telson between long uropods. Its shell glossy, half
## see-through. The species (_spec): WhiteShrimp (Litopenaeus setiferus),
## BrownShrimp (Farfantepenaeus aztecus), PinkShrimp (Farfantepenaeus
## duorarum). Salt water: in the sandbox's sea.
##
## Its own ways (the crayfish's otherwise):
## - wander / forage: over the bottom, picking at it; but in the water as
##   often swimming as walking: up off the bottom, forward, its legs tucked
##   and its swimmerets beating, its antennae streaming back; down again
## - flee: the tail flip, a run of them, backward through the water
## - burrow (bury): into the sand, the swimmerets and legs working it, the
##   body sinking into it till only its eyes and antennae show; a while;
##   then out
## - lay (spawn): no eggs carried (a penaeid's): she swims up off the
##   bottom and lets them go into the water, a cloud of them drifting down
##   and away; no hatch

const SEG := [11.0, 10.0, 10.0, 10.0, 11.0, 14.0] ## mm: its abdomen's segments
const SWIM_PACE := 0.17 ## m/s swimming
const TAIL_SHRIMP := [0.0, 0.1, 0.2, 0.24, 0.22, 0.12] ## its abdomen at rest: humped, bent down from its third segment

var _swimming := false
var _swim_to := 0.0 # (m: how high off the bottom it's swimming)
var _swim_t := 0.0


func _init(young_ := false) -> void:
	super(young_)
	body_h = 21.0
	walk_speed = 0.06
	stride = 12.0
	step_time = 0.14
	var lens := [[16.0, 16.0, 9.0], [18.0, 18.0, 10.0], [19.0, 19.0, 10.5], [18.0, 18.0, 10.0]]
	var hips := [Vector3(3.2, -9.0, -24.0), Vector3(3.6, -9.5, -17.0), Vector3(3.8, -9.5, -10.0), Vector3(3.6, -9.0, -3.0)]
	var homes := [Vector2(15.0, -32.0), Vector2(20.0, -20.0), Vector2(21.0, -6.0), Vector2(18.0, 8.0)]
	var L := []
	for p in 4:
		var l: Array = lens[p]
		L.append({"hip": hips[p], "f": l[0], "t": l[1], "s": l[2], "home": homes[p],
				"dangle": Vector3(12.0, -12.0, -20.0 + 8.0 * p), "pole": Vector3(0.4, 1.0, -0.2 + 0.15 * p), "r": 0.55, "femur_r": 0.8})
	legs = L


func _male_size() -> float:
	return 0.9 # (the females bigger)


func _build() -> void:
	var shell := _paint(S.shell, 0.22)
	var dark := _paint(S.dark, 0.3)
	var tail := _paint(S.tail, 0.22)
	var fan := _paint(S.fan, 0.25)
	var fan_edge := _paint(S.fan_edge, 0.3)
	var leg := _paint(S.leg, 0.3)
	var ant := _paint(S.antenna, 0.4)
	var pale := _paint((S.leg as Color).lightened(0.2), 0.4)
	var eye := _mat(Color(0.02, 0.02, 0.02), 0.05)
	eye.clearcoat_enabled = true
	eye.clearcoat = 1.0
	# the carapace: high, pressed in from the sides
	var car := [[-44.0, 4.0, 2.2, 2.8], [-38.0, 3.0, 5.0, 7.0], [-28.0, 2.0, 6.6, 9.5], [-14.0, 1.5, 7.2, 10.2], [-2.0, 1.5, 7.0, 10.0], [4.0, 1.0, 6.6, 9.4]]
	_mesh_on(_loft(car, 2.0), shell, _body)
	# the rostrum: a blade, curving up, toothed above; the crest behind it
	# down the carapace (the brown's and pink's grooved either side)
	var rp := [Vector3(0.0, 9.0, -38.0), Vector3(0.0, 8.0, -48.0), Vector3(0.0, 8.0, -58.0), Vector3(0.0, 10.5, -67.0)]
	for k in 3:
		_stick(rp[k], rp[k + 1], lerpf(1.3, 0.4, float(k) / 2.0), shell)
	for k in 8:
		var f := float(k) / 7.0
		var at := Vector3(0.0, lerpf(9.4, 8.6, f) + 0.6, lerpf(-36.0, -55.0, f))
		_stick(at, at + Vector3(0.0, 0.9, 0.5), 0.26, shell)
	_stick(Vector3(0.0, 11.0, -30.0), Vector3(0.0, 11.6, -4.0), 0.5, shell)
	if S.get("grooves", false):
		for side: float in [-1.0, 1.0]:
			_stick(Vector3(1.2 * side, 10.8, -30.0), Vector3(1.4 * side, 11.0, -6.0), 0.25, dark)
	# the eyes, big, on their stalks
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(2.0 * side, 5.5, -40.0), Vector3(5.0 * side, 6.5, -45.5), 1.4, shell)
		_part(Vector3(5.6 * side, 6.8, -46.5), Vector3(5.2, 5.2, 5.4), eye)
	# the antennae: the peduncle, the scale, the long thin whip swept back
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(3.2 * side, 0.5, -42.0), Vector3(4.2 * side, 1.0, -50.0), 1.0, shell)
		var sc := _part(Vector3(5.5 * side, 1.5, -54.0), Vector3(3.2, 0.6, 18.0), shell)
		sc.rotation = Vector3(0.12, 0.08 * side, 0.0)
		var root := Node3D.new()
		root.position = Vector3(4.2 * side, 1.0, -50.0)
		_body.add_child(root)
		var at := Vector3.ZERO
		var dir := Vector3(0.35 * side, 0.3, -1.0).normalized()
		var n := 40
		for k in n:
			var nx := at + dir * 8.0
			_stick(at, nx, lerpf(0.42, 0.1, float(k) / (n - 1)), ant, root)
			at = nx
			# (out forward, then curving out and round, back past its body)
			dir = dir.rotated(Vector3.UP, (-0.09 if k < 22 else -0.03) * side).rotated(Vector3.RIGHT, -0.012)
		root.set_meta("side", side)
		_antennae.append(root)
		# the antennules: short, forked
		var au := Node3D.new()
		au.position = Vector3(1.4 * side, 3.0, -44.0)
		_body.add_child(au)
		_stick(Vector3.ZERO, Vector3(0.6 * side, 0.6, -9.0), 0.55, shell, au)
		for f: float in [-1.0, 1.0]:
			_stick(Vector3(0.6 * side, 0.6, -9.0), Vector3((0.6 + 1.4 * f) * side, 1.6, -22.0), 0.18, ant, au)
		au.set_meta("side", side)
		_antennules.append(au)
		# the third maxillipeds: long, leg-like, forward
		var mx := Node3D.new()
		mx.position = Vector3(1.6 * side, -8.0, -34.0)
		_body.add_child(mx)
		_stick(Vector3.ZERO, Vector3(0.6 * side, -2.0, -14.0), 0.55, leg, mx)
		mx.set_meta("side", side)
		_maxillipeds.append(mx)
	# the first legs: slender, a tiny pincer at each (as the crayfish's claws are posed)
	for side: float in [-1.0, 1.0]:
		_claws.append(_slender_claw(side, leg, pale))
	# the abdomen: six segments, high and narrow, humped at the third; the
	# pleura hanging down over the swimmerets; the swimmerets, long, fringed
	var hws := [6.4, 6.2, 5.8, 5.2, 4.4, 3.2]
	var hhs := [9.6, 9.8, 9.6, 8.6, 7.0, 4.8]
	var ups := [0.0, 0.6, 1.2, 0.4, -0.6, -1.4]
	var parent: Node3D = _body
	for k in 6:
		var sn := Node3D.new()
		sn.position = Vector3(0.0, -0.5, 5.0) if k == 0 else Vector3(0.0, 0.0, SEG[k - 1])
		parent.add_child(sn)
		var l: float = SEG[k]
		var hw: float = hws[k]
		var hh: float = hhs[k]
		var hw0: float = hws[maxi(k - 1, 0)] if k > 0 else 6.6
		var hh0: float = hhs[maxi(k - 1, 0)] if k > 0 else 9.4
		var u0: float = ups[maxi(k - 1, 0)] if k > 0 else 0.0
		var u1: float = ups[k]
		_mesh_on(_loft([[-1.8, u0, hw0 * 0.97, hh0 * 0.97], [l * 0.45, u1, hw, hh], [l + 1.0, u1, (hw + float(hws[mini(k + 1, 5)])) * 0.5, (hh + float(hhs[mini(k + 1, 5)])) * 0.5]], 2.0), tail, sn)
		if k >= 3: # (a keel down its back, the last segments)
			_stick(Vector3(0.0, u1 + hh * 0.97, 0.5), Vector3(0.0, u1 + hh * 0.97, l), 0.35, tail, sn)
		for e in 4: # (its back edge, lapping the next)
			var a0 := lerpf(-1.4, 1.4, e / 4.0)
			var a1 := lerpf(-1.4, 1.4, (e + 1) / 4.0)
			_stick(Vector3(hw * sin(a0), u1 + hh * cos(a0), l + 0.5), Vector3(hw * sin(a1), u1 + hh * cos(a1), l + 0.5), 0.18, dark, sn)
		if S.get("spot", false) and k == 3: # (the pink's dark spot, on its side)
			for s2: float in [-1.0, 1.0]:
				_part(Vector3(hw * 0.92 * s2, u1 - 1.0, l * 0.1), Vector3(1.0, 4.0, 4.5), dark, sn)
		if S.get("bands", false): # (the brown's darker bands)
			_part(Vector3(0.0, u1 + hh * 0.55, l * 0.75), Vector3(hw * 2.02, hh * 0.9, 2.0), dark, sn)
		if k < 5:
			for s2: float in [-1.0, 1.0]:
				var sw := Node3D.new()
				sw.position = Vector3(hw * 0.4 * s2, u1 - hh * 0.8, l * 0.5)
				sn.add_child(sw)
				_stick(Vector3.ZERO, Vector3(0.8 * s2, -6.0, 1.0), 0.5, pale, sw)
				for r: float in [-1.0, 1.0]: # (its two branches, fringed)
					_stick(Vector3(0.8 * s2, -6.0, 1.0), Vector3((0.8 + 1.0 * r) * s2, -12.0, 3.0), 0.3, pale, sw)
				_swimmerets.append(sw)
		_tail.append(sn)
		parent = sn
	var tel := Node3D.new()
	tel.position = Vector3(0.0, ups[5], SEG[5])
	parent.add_child(tel)
	_mesh_on(_loft([[0.0, 0.0, 2.6, 1.6], [8.0, -0.3, 1.8, 1.1], [17.0, -0.6, 0.3, 0.3]], 2.0), fan, tel)
	for side: float in [-1.0, 1.0]:
		for k in 2: # (the inner and outer uropods, long, fanned; their tips coloured)
			var u := Node3D.new()
			u.position = Vector3((1.5 + 1.8 * k) * side, -0.4 - 0.3 * k, 0.5)
			tel.add_child(u)
			_part(Vector3(0.0, 0.0, 8.0), Vector3(4.8, 0.9, 16.0 - k * 1.5), fan, u)
			_part(Vector3(0.0, 0.05, 15.0 - k), Vector3(4.2, 0.95, 3.0), fan_edge, u)
			u.set_meta("side", side)
			u.set_meta("k", k)
			_uropods.append(u)
	_tail.append(tel)
	# the walking legs, long and thin; the first ones' pincers
	_build_legs(leg, leg)
	for i in 4:
		var c := Node3D.new()
		_body.add_child(c)
		if i < 2:
			for f: float in [-1.0, 1.0]:
				_stick(Vector3.ZERO, Vector3(0.3 * f, 0.0, 1.8), 0.16, pale, c)
		_pincers.append(c)
	# (no eggs carried: a penaeid lets hers go. The crayfish's eggs node, empty)
	_eggs = MultiMeshInstance3D.new()
	_eggs.multimesh = MultiMesh.new()
	_body.add_child(_eggs)
	_eggs.visible = false
	_colour()


## (A first leg: thin, a tiny pincer at its end: [shoulder, elbow, wrist,
## dactyl], posed as the crayfish's claws are.)
func _slender_claw(side: float, leg: Material, pale: Material) -> Array:
	var sh := Node3D.new()
	sh.position = Vector3(3.0 * side, -9.0, -30.0)
	_body.add_child(sh)
	_stick(Vector3.ZERO, Vector3(0.0, 0.0, -12.0), 0.7, leg, sh)
	var el := Node3D.new()
	el.position = Vector3(0.0, 0.0, -12.0)
	sh.add_child(el)
	_stick(Vector3.ZERO, Vector3(0.0, 0.0, -9.0), 0.6, leg, el)
	var wr := Node3D.new()
	wr.position = Vector3(0.0, 0.0, -9.0)
	el.add_child(wr)
	_stick(Vector3.ZERO, Vector3(0.0, 0.0, -4.0), 0.75, leg, wr)
	_stick(Vector3(0.3 * side, 0.0, -4.0), Vector3(0.2 * side, 0.0, -6.5), 0.3, pale, wr)
	var dc := Node3D.new()
	dc.position = Vector3(-0.4 * side, 0.0, -4.0)
	wr.add_child(dc)
	_stick(Vector3.ZERO, Vector3(0.1 * side, 0.0, -2.5), 0.28, pale, dc)
	return [sh, el, wr, dc]


# --- its ways ---------------------------------------------------------------------

func burrow(at: Vector3) -> void:
	_begin("bury")
	_at = at


func lay() -> void:
	if young or male:
		return
	_begin("spawn")


func _begin(m: String) -> void:
	super(m)
	_swimming = false


func _think(dt: float) -> void:
	super(dt)
	if _tail_ask == TAIL_REST:
		_tail_ask = TAIL_SHRIMP
	match _mode:
		"bury":
			_bury(dt)
		"spawn":
			_spawn(dt)
	# (swimming: the antennae streaming back)
	if _swim_h > 0.002:
		_sweep = 0.0


## In the water, as often swimming as walking: up off the bottom, forward,
## its legs tucked, its swimmerets beating; down again.
func _roam(dt: float) -> void:
	var wet := water_y < INF and _pos.y < water_y - 0.01
	if _swimming:
		_swim_t -= dt
		_swim_want = _swim_to
		_pace = SWIM_PACE
		_stage = 0
		_pitch = lerpf(_pitch, -0.05 * signf(_swim_to - _swim_h), 1.0 - exp(-2.0 * dt))
		if _swim_t <= 0.0 or Vector2(_target.x - _pos.x, _target.z - _pos.z).length() < 0.03:
			_swimming = false
			_pace = -1.0
			_wait = 0.0
		return
	if wet and _stage == 0 and _wait <= 0.0 and rng.randf() < 0.45:
		var a := rng.randf() * TAU
		_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * maxf(_radius, 0.4)
		_swim_to = rng.randf_range(0.03, 0.12) * maxf(size / ADULT, 0.3)
		_swim_t = rng.randf_range(3.0, 7.0)
		_swimming = true
		return
	super(dt)


## Into the sand: the swimmerets and legs working it, its body sinking into
## it till only its eyes and antennae show; a while; then out.
func _bury(dt: float) -> void:
	_target = _pos
	match _stage:
		0: # (working down into it)
			_tuck(1.4)
			_fan = 1.0
			_lift = move_toward(_lift, -body_h - 3.0, dt * 6.0)
			if _lift <= -body_h - 2.9:
				_stage = 1
				_st = 0.0
		1: # (under, its eyes up)
			_tuck(1.4)
			_cl_ask = [CL_FLIP, CL_FLIP]
			if _st > 25.0:
				_stage = 2
				_st = 0.0
		2: # (out)
			_lift = move_toward(_lift, 0.0, dt * 12.0)
			if _lift >= -0.1:
				wander(_pos, 0.3)


var _cloud: MultiMeshInstance3D
var _cloud_v: PackedVector3Array


## Her spawning: up off the bottom, her eggs let go into the water in a
## cloud, drifting down and away; down again.
func _spawn(dt: float) -> void:
	_target = _pos
	_swim_want = 0.1 * maxf(size / ADULT, 0.3)
	match _stage:
		0:
			if _swim_h > _swim_want * 0.8 or _st > 6.0:
				_release()
				_stage = 1
				_st = 0.0
		1:
			_fan = 1.0
			if _st > 4.0:
				wander(_pos, 0.3)


func _release() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	if is_instance_valid(_cloud):
		_cloud.queue_free()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _dots_mesh()
	mm.instance_count = 220
	_cloud = MultiMeshInstance3D.new()
	_cloud.multimesh = mm
	var m := _mat(S.get("egg", Color(0.85, 0.8, 0.6)), 0.3)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.75
	_cloud.material_override = m
	_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(_cloud)
	_cloud.global_position = _out(Vector3(0.0, -10.0, 25.0))
	_cloud_v = PackedVector3Array()
	for k in 220:
		_cloud_v.append(Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.6, 0.6), rng.randf_range(-1.0, 1.0)) * 0.02)
		mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ONE * 0.0012), Vector3.ZERO))
	_cloud.set_meta("t", 0.0)


func _process(dt: float) -> void:
	super(dt)
	if is_instance_valid(_cloud): # (the eggs drifting down, spreading, gone)
		var t: float = float(_cloud.get_meta("t")) + dt
		_cloud.set_meta("t", t)
		var mm := _cloud.multimesh
		var floor_y := _cloud.global_position.y
		for k in mm.instance_count:
			var v := _cloud_v[k]
			var p := v * t * (1.0 + 0.3 * sin(float(k))) + Vector3(0.0, -0.006 * t, 0.0)
			mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ONE * 0.0012), p))
		(_cloud.material_override as StandardMaterial3D).albedo_color.a = clampf(0.75 * (1.0 - t / 25.0), 0.0, 1.0)
		if t > 25.0 or floor_y < -100.0:
			_cloud.queue_free()
			_cloud = null


func _pose(dt: float) -> void:
	super(dt)
	if _mode == "bury" and _stage == 0: # (its swimmerets working the sand away)
		for k in _swimmerets.size():
			_swimmerets[k].rotation.x = 0.5 * sin(_t * 14.0 + k)
	if _swim_h > 0.002: # (swimming: its swimmerets beating hard, its antennae streaming back)
		for k in _swimmerets.size():
			_swimmerets[k].rotation.x = 0.6 * sin(_t * 16.0 - k * 0.9)
		for a in _antennae:
			var side: float = a.get_meta("side")
			a.rotation = Vector3(-0.1, side * 0.35, 0.0)


func _exit_tree() -> void:
	super()
	if is_instance_valid(_cloud):
		_cloud.queue_free()


func _p_behaviours() -> PackedStringArray:
	var out := PackedStringArray(["forage", "eat", "hunt", "flee", "burrow", "moult"])
	if not young:
		out.append("mate")
		if not male:
			out.append("lay")
	return out


func _p_act_done(name: String) -> bool:
	match name:
		"burrow":
			return _mode != "bury"
		"lay":
			return _mode != "spawn"
	return super(name)
