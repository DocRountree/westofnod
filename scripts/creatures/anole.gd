class_name Anole
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A green anole (Anolis carolinensis), life size (its model in mm, size
## 0.5 of the walker's doubled scale: an adult about 17 cm long, two thirds
## of it tail): slender, its head long and pointed, its eyes in their
## turrets, the ear openings behind them; bright leaf green above, paler
## down the sides, white beneath, its skin finely pebbled with tiny scales;
## turning brown (cold, still a long while, or frightened) and green again
## (shaders/render/anole.gdshader). Its body and tail one skin bent along a
## spine: its trunk swinging from side to side as it runs (the shoulders
## one way, the hips the other), its tail waving after it, lying along the
## ground (laid along where its hips have been, as a snake's body follows
## its head: not swung round with it as it turns); four sprawling legs (hexapod.gd's motor, trotting: the diagonals
## together), the knees and elbows up, long thin toes splayed (the hind
## foot's fourth longest). A male's dewlap: a fan of pink skin under his
## throat, flared to display (his, only: hers is none to see; otherwise the
## two the same). Young (Anole.new(true)): a hatchling, a third as long,
## duller and browner; growing. Not yet in the game
## (tools/creatures/life_cycle_demo.tscn).
##
## - wander(centre, radius): darting a little way, stopping, still, its
##   head turning; now and then bobbing its head (a male doing push-ups,
##   his dewlap flaring)
## - hunt(prey): turning to it, its head cocked; creeping nearer, then a
##   dash, a snap: in its jaws, chewed and swallowed (head jerks)
## - display(): head bobs and push-ups; a male's dewlap flared and folded
## - lay(at): (a female's) her snout pushed into the soil, digging a hole,
##   round, one egg (white, leathery) laid into it, round again, and the
##   soil pushed over it; hatching later (AnoleEgg.hatch: a slit, the
##   hatchling's head out, then out and away)
## - mate(her): he displays to her (push-ups, his dewlap flaring), then on
##   her, gripping the skin of her nape in his jaws, lying over her to one
##   side, his tail twisted down under hers; a while, and off
## Steering (pilot.gd): act hunt {prey}, display {seconds}, lay {at} (a
## female's), mate {partner}.

const SPINE := 32
const Z0 := -24.0 # mm: the neck (the spine's first point)
const Z1 := 130.0 # the tail's tip
const SEG := (Z1 - Z0) / (SPINE - 1)
const TAIL_BEND := 0.14 # rad: the most a tail joint bends (a segment's)
const TURN_IN_PLACE := 0.9 # rad/s: the most it turns standing (its tail swung round behind it)
const SHOULDER := -18.0
const PELVIS := 16.0
const VENT := 20.0
const FORE := {"hip": Vector3(4.5, -1.5, SHOULDER), "f": 9.0, "t": 8.5, "s": 5.0, "home": Vector2(17.0, -23.0), "dangle": Vector3(9.0, -6.0, -24.0), "pole": Vector3(0.3, 1.0, 0.6), "r": 1.2, "femur_r": 1.4}
const HIND := {"hip": Vector3(5.0, -1.5, PELVIS), "f": 13.0, "t": 12.0, "s": 8.0, "home": Vector2(20.0, 22.0), "dangle": Vector3(10.0, -6.0, 26.0), "pole": Vector3(0.3, 1.0, -0.5), "r": 1.5, "femur_r": 1.4}

var young := false
var eggs: Array[Node3D] = [] ## the eggs it's laid (in its parent)
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.2
var _wait := 0.0
var _st := 0.0
var _stage := 0
var _prey: Node3D
var _prey_s := Vector3.ONE
var _held := false
var _phase := 0.0 # the trunk's swing, with its stride
var _turn_rate := 0.0
var _last_yaw := 0.0
var _brown := 0.0
var _brown_to := 0.0
var _still := 0.0 # s it's been still
var _dew := 0.0 # 0 folded .. 1 flared (a male's)
var _dew_to := 0.0
var _bob := 0.0 # head bobbing (0..1: how much)
var _push := 0.0 # push-ups (0..1)
var _jaw_open := 0.0
var _lunge := 0.0 # mm the head shot forward, snapping
var _chew := 0.0
var _look_h := Vector2.ZERO # the head turned (yaw, pitch)
var _look_to := Vector2.ZERO
var _dig := 0.0
var _hole: MeshInstance3D
var _lay_at := Vector3.ZERO
var _twist := 0.0 # a male's tail twisted under hers
# the parts
var _skin: MeshInstance3D
var _skin_mat: ShaderMaterial
var _paint: ShaderMaterial
var _head: Node3D
var _jaw: Node3D
var _dewlap: Node3D
var _toes: Array[Node3D] = []
var _sp := PackedVector3Array()
var _sx := PackedVector3Array()
var _sy := PackedVector3Array()


func _init(young_ := false) -> void:
	young = young_
	super(young_, 0.17 if young_ else 0.5)
	legs = [FORE, HIND]
	tripod = [[0, 3], [1, 2]]
	body_h = 9.5
	walk_speed = 0.22
	stride = 28.0
	step_time = 0.07
	mate_secs = 20.0
	_sp.resize(SPINE)
	_sx.resize(SPINE)
	_sy.resize(SPINE)


## The body's half width and half height at z (mm along it).
static func _girth(z: float) -> Vector2:
	if z < SHOULDER:
		var k := (z - Z0) / (SHOULDER - Z0)
		return Vector2(lerpf(4.0, 5.4, k), lerpf(4.2, 5.2, k))
	if z < PELVIS:
		var k := (z - SHOULDER) / (PELVIS - SHOULDER)
		var bulge := sin(PI * k)
		return Vector2(5.4 + 1.6 * bulge, 5.2 + 1.0 * bulge)
	if z < VENT + 2.0:
		var k := (z - PELVIS) / (VENT + 2.0 - PELVIS)
		return Vector2(lerpf(5.4, 4.4, k), lerpf(5.2, 4.4, k))
	var t := (z - VENT - 2.0) / (Z1 - VENT - 2.0)
	var w := lerpf(4.4, 0.35, pow(t, 0.7))
	return Vector2(w, w * 1.05)


func _build() -> void:
	var shader: Shader = preload("res://shaders/render/anole.gdshader")
	_skin_mat = ShaderMaterial.new()
	_skin_mat.shader = shader
	_skin_mat.set_shader_parameter("skinned", true)
	_skin_mat.set_shader_parameter("count", SPINE)
	_skin_mat.set_shader_parameter("young", young)
	_paint = ShaderMaterial.new()
	_paint.shader = shader
	_paint.set_shader_parameter("young", young)
	_skin = MeshInstance3D.new()
	_skin.mesh = _tube()
	_skin.material_override = _skin_mat
	_skin.custom_aabb = AABB(Vector3(-400, -400, -400), Vector3(800, 800, 800))
	_body.add_child(_skin)
	# the head: long, pointed, flat-topped; the lower jaw hinged under it
	_head = Node3D.new()
	_body.add_child(_head)
	var hm := MeshInstance3D.new()
	hm.mesh = _loft([[1.5, 0.6, 4.2, 3.6], [-3.0, 1.2, 5.6, 3.9], [-8.0, 1.2, 5.0, 3.3], [-12.5, 0.6, 3.6, 2.4], [-15.8, 0.0, 2.0, 1.5], [-17.2, -0.2, 0.7, 0.7]], 2.2)
	hm.material_override = _paint
	_head.add_child(hm)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0.0, -1.6, -0.5)
	_head.add_child(_jaw)
	var jm := MeshInstance3D.new()
	jm.mesh = _loft([[1.0, -0.6, 4.0, 2.4], [-3.0, -0.8, 5.2, 2.6], [-8.0, -0.6, 4.6, 2.0], [-12.5, -0.3, 3.2, 1.4], [-15.6, 0.1, 1.7, 0.8], [-16.8, 0.3, 0.6, 0.4]], 2.2)
	jm.material_override = _paint
	_jaw.add_child(jm)
	var mouth := _mat(Color(0.75, 0.45, 0.45), 0.5) # (inside: pink, seen as it snaps)
	_part(Vector3(0.0, 0.2, -7.0), Vector3(6.0, 0.6, 14.0), mouth, _jaw)
	# the eyes in their turrets, the ear openings, the nostrils
	var turret := _paint
	var eye := _mat(Color(0.12, 0.08, 0.04), 0.08)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(3.5 * side, 1.9, -8.3), Vector3(2.6, 2.6, 3.0), turret, _head)
		_part(Vector3(4.55 * side, 2.0, -8.3), Vector3(0.9, 1.5, 1.5), eye, _head)
		_part(Vector3(4.4 * side, 0.2, -1.2), Vector3(0.5, 1.4, 1.1), _mat(Color(0.08, 0.07, 0.05), 0.6), _head) # (the ear opening)
		_part(Vector3(0.9 * side, 0.9, -16.0), Vector3(0.4, 0.4, 0.4), _mat(Color(0.05, 0.05, 0.04), 0.6), _head)
	# a male's dewlap: a fan of pink skin folded under his throat
	_dewlap = Node3D.new()
	_dewlap.position = Vector3(0.0, -3.4, -6.0)
	_head.add_child(_dewlap)
	if male and not young:
		var pink := _mat(Color(0.95, 0.36, 0.46), 0.5)
		var fan := _part(Vector3(0.0, -0.5, 1.5), Vector3(0.5, 1.0, 1.0), pink, _dewlap)
		fan.name = "fan"
		var rows := _mat(Color(0.98, 0.85, 0.8), 0.5) # (its rows of pale scales)
		for k in 3:
			var r := _part(Vector3(0.0, -0.5, 1.5), Vector3(0.6, 1.0, 1.0), rows, _dewlap)
			r.name = "row%d" % k
	_build_legs(_paint, _paint)
	# the toes: long, thin, splayed, padded (each foot's own node, set at it)
	for i in 4:
		var hind := i >= 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var t := Node3D.new()
		_body.add_child(t)
		for k in 5: # (the first the innermost)
			var a := deg_to_rad(-70.0 + 32.0 * k) * side
			var l := ([3.0, 5.0, 6.0, 7.5, 4.5][k] as float) if hind else ([2.5, 3.6, 4.2, 4.0, 3.0][k] as float)
			var d := Vector3(sin(a), 0.0, -cos(a))
			_stick(Vector3.ZERO, d * l, 0.32, _paint, t)
			_part(d * l, Vector3(0.75, 0.4, 0.9), _paint, t) # (its pad)
		_toes.append(t)
	_place()
	_spine(0.0)


## Its skin: rings along the spine (VERTEX.z its index), round each the
## body's oval, the belly flatter.
func _tube() -> ArrayMesh:
	const PER := 2
	const ROUND := 12
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := (SPINE - 1) * PER + 1
	var vert := func(k: int, a_i: int) -> Array:
		var s := float(k) / PER
		var z := Z0 + s * SEG
		var g := _girth(z)
		var a := TAU * float(a_i % ROUND) / ROUND
		var hy := 0.8 if cos(a) < 0.0 else 1.0 # (round = 0 its back: up; the belly flatter)
		var dg := (_girth(z + 0.5) - _girth(z - 0.5)).x
		var n := Vector3(sin(a) / maxf(g.x, 0.1), cos(a) * hy / maxf(g.y, 0.1), -dg / maxf(g.x, 0.1)).normalized()
		return [Vector3(sin(a) * g.x, cos(a) * g.y * hy, s), n]
	for k in rings - 1:
		for a_i in ROUND:
			var q := [vert.call(k, a_i), vert.call(k + 1, a_i), vert.call(k + 1, a_i + 1), vert.call(k, a_i + 1)]
			for tri: Array in [[0, 2, 1], [0, 3, 2]]:
				for c: int in tri:
					var v: Array = q[c]
					st.set_normal(v[1])
					st.add_vertex(v[0])
	return st.commit()


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0


func hunt(prey: Node3D) -> void:
	if prey == null or not is_instance_valid(prey):
		return
	_mode = "hunt"
	_prey = prey
	_prey_s = prey.scale
	_held = false
	_stage = 0
	_st = 0.0


func display() -> void:
	_mode = "display"
	_st = 0.0
	_target = _pos


## (A female's.) An egg laid at `at`: a hole dug with her snout, the egg
## into it, covered.
func lay(at: Vector3) -> void:
	if young or male:
		return
	_mode = "lay"
	_lay_at = at
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 3.0)
	_pace = -1.0
	_dew_to = 0.0
	_bob = move_toward(_bob, 0.0, dt * 2.0)
	_push = move_toward(_push, 0.0, dt * 2.0)
	match _mode:
		"wander":
			if _wait <= 0.0:
				var r := rng.randf()
				if r < 0.3: # (still, its head turning)
					_target = _pos
					_look_to = Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.1, 0.25))
					_wait = rng.randf_range(1.5, 5.0)
				elif r < 0.42 and not young: # (bobbing: a male's push-ups, his dewlap)
					display()
					return
				else: # (a dart, a little way)
					var a := rng.randf() * TAU
					_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
					_look_to = Vector2.ZERO
					_wait = rng.randf_range(1.0, 3.0)
			if _pos.distance_to(_target) > 0.01:
				_pace = walk_speed * 2.5 * lerpf(0.35, 1.0, size) # (darting)
		"display":
			_target = _pos
			_look_to = Vector2(0.0, 0.15)
			_display_pose(_st)
			if _st > 6.0:
				wander(_pos if _centre == Vector3.ZERO else _centre, _radius)
		"hunt":
			_hunt(dt)
		"lay":
			_lay(dt)


## Bobbing: three bobs and a pause, push-ups with them; a male's dewlap
## flared on each.
func _display_pose(t: float) -> void:
	var cyc := fmod(t, 2.4)
	var on := cyc < 1.5
	_bob = 1.0 if on else 0.0
	_push = 1.0 if on else 0.3
	if male and not young:
		_dew_to = 1.0 if cyc > 0.3 and cyc < 1.8 else 0.0
	_brown_to = 0.0


func _hunt(dt: float) -> void:
	if not is_instance_valid(_prey):
		_held = false
		wander(_pos, 0.15)
		return
	var p := _prey.position
	var to := p - _pos
	to.y = 0.0
	var d := to.length()
	var mouth := (24.0 + 17.0) * MM * size # (its middle to its snout's tip)
	match _stage:
		0: # turned to it, its head cocked, watching
			_target = _pos
			_turn_to = atan2(-to.x, -to.z)
			_look_to = Vector2(0.0, -0.2) + Vector2(0.2 * sin(_st * 2.0), 0.0)
			if _st > 1.2:
				_stage = 1
				_st = 0.0
		1: # creeping nearer
			_target = p - to.normalized() * mouth * 2.2
			_pace = walk_speed * 0.25
			_look_to = Vector2(0.0, -0.25)
			if d < mouth * 2.5 or _st > 8.0:
				_stage = 2
				_st = 0.0
		2: # the dash, and the snap
			_target = p - to.normalized() * mouth * 0.95
			_pace = walk_speed * 3.0
			_jaw_open = minf(_jaw_open + dt * 8.0, 1.0)
			if d < mouth * 1.15 or _st > 1.0:
				_lunge = 4.0
				_jaw_open = 0.0
				_held = true
				_stage = 3
				_st = 0.0
		3: # chewing it, swallowing, the head jerking
			_target = _pos
			_chew = 1.0
			_look_to = Vector2(0.15 * sin(_st * 9.0), -0.1 + 0.15 * maxf(sin(_st * 4.0), 0.0))
			_prey.scale = _prey_s * maxf(1.0 - _st / 4.0, 0.05)
			if _st > 4.0:
				_prey.queue_free()
				_prey = null
				_held = false
				wander(_pos, 0.15)


func _lay(dt: float) -> void:
	match _stage:
		0: # to the spot
			_target = _lay_at
			if _pos.distance_to(_lay_at) < 0.006 and _speed < 0.01:
				_stage = 1
				_st = 0.0
		1: # her snout into the soil, digging, nodding
			_target = _pos
			_look_to = Vector2(0.0, -0.75 + 0.2 * sin(_st * 7.0))
			_dig = clampf(_st / 4.0, 0.0, 1.0)
			_hole_at(_out(Vector3(0.0, -body_h, Z0 - 14.0)))
			if _st > 4.0:
				_stage = 2
				_st = 0.0
				_turn_to = _yaw + PI
		2: # round, her vent over it
			_target = _pos
			_look_to = Vector2.ZERO
			if _turn_to == INF:
				var h := _hole.position if _hole else _pos
				var vent := _out(Vector3(0.0, -body_h, VENT))
				_target = _pos + (h - vent) * Vector3(1.0, 0.0, 1.0)
				if Vector2(h.x - vent.x, h.z - vent.z).length() < 0.004 or _st > 3.0:
					_stage = 3
					_st = 0.0
		3: # the egg out, into it
			_target = _pos
			_crouch = minf(_crouch + dt, 0.6)
			if _st > 2.0:
				var e := AnoleEgg.new()
				e.maker = get_script()
				get_parent().add_child(e)
				var h := _hole.position if _hole else _pos
				e.position = h + Vector3.DOWN * 0.002
				e.rotation.y = _yaw
				eggs.append(e)
				_stage = 4
				_st = 0.0
				_turn_to = _yaw + PI
		4: # round again, and the soil pushed over it
			_crouch = move_toward(_crouch, 0.0, dt)
			_target = _pos
			if _turn_to == INF:
				_look_to = Vector2(0.45 * sin(_st * 5.0), -0.6)
				_dig = clampf(1.0 - _st / 3.0, 0.0, 1.0)
				if _st > 3.5:
					if _hole:
						_hole.queue_free()
						_hole = null
					_dig = 0.0
					wander(_pos, 0.15)


func _hole_at(p: Vector3) -> void:
	if _hole == null:
		_hole = MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.5
		c.bottom_radius = 0.5
		c.height = 1.0
		c.radial_segments = 10
		_hole.mesh = c
		_hole.material_override = _mat(Color(0.22, 0.16, 0.1), 0.95)
		get_parent().add_child(_hole)
		_hole.position = Vector3(p.x, _ground(p.x, p.z) + 0.0002, p.z)
	_hole.scale = Vector3(0.014, 0.0004, 0.014) * maxf(_dig, 0.05)


# --- mating -------------------------------------------------------------------

func _mate_approach() -> Vector3:
	return Vector3(26.0, -body_h, -6.0) # (beside her, to her right, where she can see him)


func _mate_leave() -> Vector3:
	return Vector3(40.0, -body_h, 10.0)


func _court_secs() -> float:
	return 6.0


func _mount_secs() -> float:
	return 0.6


func _mount() -> Dictionary:
	# on her, to her right, his jaws on the skin of her nape, his legs over
	# her; his tail's twisted under hers (_spine)
	return {"at": Vector3(3.5, 8.0, 3.0), "basis": Basis(Vector3.UP, 0.1) * Basis(Vector3.BACK, -0.28), "grips": {
		0: Vector3(-5.5, 1.0, -15.0), 1: Vector3(6.5, -2.5, -14.0), 2: Vector3(-6.0, 0.5, 13.0), 3: Vector3(7.0, -3.0, 15.0)}}


func _mating(dt: float) -> void:
	super(dt)
	_pace = -1.0
	if _mate_role == "male" and _mate_stage == "court":
		_display_pose(_mate_t)
	elif _mate_role == "female" and _mate_stage == "wait":
		_bob = 0.4 * maxf(sin(_mate_t * 2.0), 0.0) # (nodding back)
		_dew_to = 0.0
	if _mate_role == "male" and _mate_stage in ["mount", "joined"]:
		_look_to = Vector2(-0.15, -0.5) # (down to her nape)
		_jaw_open = 0.35
		_dew_to = 0.0


func _after_mate() -> void:
	_twist = 0.0
	_jaw_open = 0.0
	wander(_pos, 0.15)


# --- the motor: its walk, its turns no tighter than its tail can follow ---------

func _walk(dt: float) -> void:
	var to := _target - _pos
	to.y = 0.0
	var d := to.length()
	var want := 0.0
	# (going, it turns only as its tail can follow: at most TAIL_BEND a
	# tail segment's length gone; standing, slowly, its tail swinging round)
	var can := maxf(TAIL_BEND / maxf(SEG * MM * size, 1e-5) * _speed * 0.9, TURN_IN_PLACE) * dt
	if _turn_to != INF:
		var tt := wrapf(_turn_to - _yaw, -PI, PI)
		_yaw += clampf(tt, -can, can)
		if absf(tt) < 0.02:
			_turn_to = INF
	elif d > 0.002 * size:
		var a := atan2(-to.x, -to.z)
		var turn := wrapf(a - _yaw, -PI, PI)
		_yaw += clampf(turn, -can, can)
		var pace := _pace if _pace > 0.0 else walk_speed * lerpf(0.35, 1.0, size)
		want = minf(pace, d * 4.0) * clampf(1.0 - absf(turn) / 1.6, 0.0, 1.0)
	_speed = move_toward(_speed, want, dt * 2.0)
	_pos += Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * _speed * dt
	ground_y = _ground(_pos.x, _pos.z)
	_pos.y = ground_y


# --- the pose -----------------------------------------------------------------

func _pose(dt: float) -> void:
	# its colour: green, active; brown, still a long while
	_still = _still + dt if _speed < 0.005 and _mode != "display" else 0.0
	if _still > 20.0:
		_brown_to = 0.8
	elif _speed > 0.02 or _mode in ["display", "hunt"] or _mate_role != "":
		_brown_to = 0.0
	_brown = move_toward(_brown, _brown_to, dt * 0.08)
	_skin_mat.set_shader_parameter("brown", _brown)
	_paint.set_shader_parameter("brown", _brown)
	# push-ups: the front up and down on straightened forelegs
	var pu := _push * maxf(sin(_t * 9.0), 0.0)
	if not (_mate_role == "male" and _mate_stage in ["mount", "joined", "part"]):
		_pitch = 0.18 * pu
		_lift = 2.5 * pu
	# the trunk's swing with its stride; turning, the body curved
	var yd := wrapf(_yaw - _last_yaw, -PI, PI)
	_last_yaw = _yaw
	_turn_rate = lerpf(_turn_rate, yd / maxf(dt, 1e-4), 1.0 - exp(-6.0 * dt))
	_phase += _speed * dt / maxf(stride * MM * size, 1e-4) * PI
	var joined := _mate_role == "male" and _mate_stage in ["mount", "joined"]
	_twist = move_toward(_twist, 1.0 if joined else 0.0, dt * 1.5)
	_spine(dt)
	# the head: on the neck, turning, bobbing, snapping, chewing
	_look_h = _look_h.lerp(_look_to, 1.0 - exp(-8.0 * dt))
	_lunge = move_toward(_lunge, 0.0, dt * 12.0)
	var bob := 0.22 * _bob * sin(_t * 11.0)
	var hb := Basis(_sx[0], _sy[0], _sx[0].cross(_sy[0]))
	_head.transform = Transform3D(hb * Basis.from_euler(Vector3(_look_h.y + bob, _look_h.x, 0.0)), _sp[0] - hb.z * _lunge)
	if not (_mode == "hunt" and _stage == 2) and not joined:
		_jaw_open = move_toward(_jaw_open, 0.0, dt * 3.0)
	_jaw.rotation.x = 0.45 * _jaw_open + 0.12 * _chew * (0.5 + 0.5 * sin(_t * 14.0))
	# the dewlap, flared and folded
	_dew = move_toward(_dew, _dew_to, dt * 4.0)
	for c in _dewlap.get_children():
		var mi := c as MeshInstance3D
		var k := float(String(mi.name).substr(3).to_int()) if String(mi.name).begins_with("row") else -1.0
		var r := lerpf(1.2, 11.0, _dew)
		if k < 0.0:
			mi.scale = Vector3(0.5, r * 1.9, r * 2.0)
			mi.position = Vector3(0.0, -r * 0.85, 2.5 * _dew)
		else:
			var rr := r * (0.45 + 0.18 * k)
			mi.scale = Vector3(0.6, maxf(rr * 0.12, 0.05), rr * 1.6)
			mi.position = Vector3(0.0, -r * (0.35 + 0.3 * k) * 1.4, 2.5 * _dew)
		mi.visible = _dew > 0.03 or k < 0.0
	# the prey in its jaws
	if _held and is_instance_valid(_prey):
		_prey.global_position = _body.global_transform * (_head.transform * Vector3(0.0, -1.0, -15.5))


## Its spine (the body's mm): the neck to the tail's tip, the trunk
## swinging from side to side with its stride (the shoulders one way, the
## hips the other), curved into a turn, the tail waving after it and lying
## along the ground; a male's tail, joined, twisted down under hers.
func _spine(_dt: float) -> void:
	var moving := clampf(_speed / 0.05, 0.0, 1.0)
	var A := 3.2 * moving
	var curve := clampf(_turn_rate, -4.0, 4.0) * 0.0009
	var to_world := transform * _body.transform
	var inv := to_world.affine_inverse()
	var mid := (SHOULDER + PELVIS) * 0.5
	var L := PELVIS - SHOULDER
	# (where its hips have been: the trail its tail lies along; not while
	# it's carried on her, mating, nor in the air)
	var trailing := _twist <= 0.01 and not airborne and not (_mate_role == "male" and _mate_stage in ["mount", "joined", "part"])
	var vent := to_world * Vector3(A * sin(_phase) * sin(PI * (VENT - mid) / L), 0.0, VENT)
	if trailing:
		_lay_trail(vent, to_world)
	else:
		_trail.clear()
	for i in SPINE:
		var z := Z0 + i * SEG
		var x := 0.0
		var y := 0.0
		if z <= VENT:
			x = A * sin(_phase) * sin(PI * (z - mid) / L)
		else:
			var base := A * sin(_phase) * sin(PI * (VENT - mid) / L)
			var u := (z - VENT) / (Z1 - VENT)
			x = base + (2.5 + 9.0 * moving) * u * sin(_phase * 0.5 - u * TAU * 1.2 + 0.4 * sin(_t * 0.7)) + 2.0 * sin(_t * 0.5 + u * 4.0) * u
		x -= curve * (z - mid) * absf(z - mid) # (curved into its turn: the tail swung out)
		if z > VENT:
			# (its tail down off its hips to lie along the ground)
			y = lerpf(0.0, -body_h + _girth(z).y * 0.9, smoothstep(VENT, VENT + 30.0, z))
			if _twist > 0.0: # (twisted down under hers, to her side)
				var bell := exp(-pow((z - 32.0) / 12.0, 2.0)) * _twist
				x -= 6.0 * bell
				y -= 6.5 * bell
		var p := Vector3(x, y, z)
		# (its tail laid along where its hips have been, on the ground, as a
		# snake's body follows its head: not swung round with it as it
		# turns; a little wave along it, swimming its way)
		if z > VENT and trailing:
			var d := (z - VENT) * MM * size
			var tr := _along_trail(d)
			var q: Vector3 = tr[0]
			var way: Vector3 = tr[1]
			var side := way.cross(Vector3.UP).normalized()
			var u := (z - VENT) / (Z1 - VENT)
			q += side * (1.5 + 3.0 * moving) * u * sin(_phase * 0.5 - u * TAU * 1.2) * MM * size
			q.y = _ground(q.x, q.z) + _girth(z).y * 0.9 * MM * size
			var w := smoothstep(VENT, VENT + 22.0, z)
			p = p.lerp(inv * q, w)
		elif z > VENT + 20.0 and _twist <= 0.5:
			var q := to_world * p
			var g := _ground(q.x, q.z) + _girth(z).y * 0.9 * MM * size
			q.y = lerpf(q.y, g, smoothstep(VENT + 20.0, VENT + 45.0, z))
			p = inv * q
		_sp[i] = p
	# no tail joint bent more than TAIL_BEND: each segment laid on from the
	# one before it, its way turned no further than that from that one's (so
	# it curves smoothly from its hips, never kinked; as a caterpillar's)
	var iv := int(ceil((VENT - Z0) / SEG))
	var tway := Vector2(_sp[iv - 1].x - _sp[iv - 2].x, _sp[iv - 1].z - _sp[iv - 2].z)
	tway = tway.normalized() if tway.length() > 1e-5 else Vector2(0.0, 1.0)
	for i in range(iv, SPINE):
		var d := _sp[i] - _sp[i - 1]
		var dn := Vector2(d.x, d.z)
		dn = dn.normalized() if dn.length() > 1e-5 else tway
		var ang := tway.angle_to(dn)
		if absf(ang) > TAIL_BEND:
			dn = tway.rotated(signf(ang) * TAIL_BEND)
		var dy := clampf(d.y, -SEG * 0.95, SEG * 0.95)
		var flat := sqrt(maxf(SEG * SEG - dy * dy, 0.0))
		_sp[i] = Vector3(_sp[i - 1].x + dn.x * flat, _sp[i - 1].y + dy, _sp[i - 1].z + dn.y * flat)
		tway = dn
	for i in SPINE:
		var back := (_sp[mini(i + 1, SPINE - 1)] - _sp[maxi(i - 1, 0)]).normalized()
		var xr := Vector3.UP.cross(back)
		xr = xr.normalized() if xr.length() > 1e-4 else Vector3.RIGHT
		_sx[i] = xr
		_sy[i] = back.cross(xr).normalized()
	_skin_mat.set_shader_parameter("sp", _sp)
	_skin_mat.set_shader_parameter("sx", _sx)
	_skin_mat.set_shader_parameter("sy", _sy)


var _trail: Array[Vector3] = [] # (where its hips have been: its parent's space, the newest first)


## Its hips' trail: begun straight out behind it; a point more each time
## they've gone a little way.
func _lay_trail(vent: Vector3, to_world: Transform3D) -> void:
	var step := SEG * MM * size * 0.5
	if not _trail.is_empty() and _trail[0].distance_to(vent) > (Z1 - VENT) * MM * size: # (put somewhere new: begun again)
		_trail.clear()
	if _trail.is_empty():
		var back := (to_world.basis * Vector3.BACK).normalized()
		back.y = 0.0
		back = back.normalized()
		for k in int((Z1 - VENT) / (SEG * 0.5)) + 4:
			_trail.append(vent + back * step * k)
		return
	if _trail[0].distance_to(vent) > step:
		_trail.push_front(vent)
		while _trail.size() > int((Z1 - VENT) / (SEG * 0.5)) + 8:
			_trail.pop_back()


## The point d (m) back along the trail from its hips, and the way it runs
## there (toward the tail).
func _along_trail(d: float) -> Array:
	var vent: Vector3 = (transform * _body.transform) * Vector3(0.0, 0.0, VENT)
	var prev := vent
	var left := d
	var way := (transform.basis * Vector3.BACK).normalized()
	for q: Vector3 in _trail:
		var l := prev.distance_to(q)
		if l > 1e-7:
			way = (q - prev) / l
		if l >= left and l > 1e-7:
			return [prev.lerp(q, left / l), way]
		left -= l
		prev = q
	return [prev + way * left, way]


## A point along the spine at z (the body's mm), and its frame's right.
func _spine_at(z: float) -> Array:
	var s := clampf((z - Z0) / SEG, 0.0, SPINE - 1.001)
	var i := int(s)
	var f := s - i
	return [_sp[i].lerp(_sp[i + 1], f), _sx[i].lerp(_sx[i + 1], f).normalized(), _sy[i].lerp(_sy[i + 1], f).normalized()]


## Its legs, a lizard's: each from its shoulder or hip (where the swinging
## spine has it) out sideways, the knee up, down to the foot; the toes
## splayed at it.
func _pose_legs() -> void:
	var inv := (transform * _body.transform).affine_inverse()
	var up := (inv.basis * Vector3.UP).normalized()
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var at: Array = _spine_at(hp.z)
		var hip: Vector3 = (at[0] as Vector3) + (at[1] as Vector3) * hp.x * side + (at[2] as Vector3) * hp.y
		var foot: Vector3
		if _pose_foot[i] != null:
			foot = _pose_foot[i]
		elif airborne:
			var dg: Vector3 = L.dangle
			foot = Vector3(dg.x * side, dg.y, dg.z)
		else:
			foot = inv * _feet[i]
		var out := foot - hip
		out -= up * out.dot(up)
		out = out.normalized() if out.length() > 1e-4 else Vector3(side, 0.0, 0.0)
		var s: float = L.s
		var ankle := foot + (-out * 0.8 + up * 0.6).normalized() * s
		var pl: Vector3 = L.pole
		var knee := _knee(hip, ankle, L.f, L.t, Vector3(pl.x * side, pl.y, pl.z))
		var r: float = L.r
		var m: Array = _leg_mesh[i]
		(m[0] as MeshInstance3D).transform = _seg(hip, knee, r * float(L.femur_r))
		(m[1] as MeshInstance3D).transform = _seg(knee, ankle, r * 0.8)
		(m[2] as MeshInstance3D).transform = _seg(ankle, foot, r * 0.55)
		(m[3] as MeshInstance3D).transform = Transform3D(Basis().scaled(Vector3.ONE * r * 1.25), knee)
		# its toes, splayed forward and out from the foot, flat on the ground
		var fwd := Vector3(0.0, 0.0, -1.0)
		var way := (fwd * 0.75 + out * 0.65 * (1.0 if i < 2 else 1.2)).normalized()
		var right := way.cross(up).normalized()
		var tb := Basis(right, up, -way)
		_toes[i].transform = Transform3D(tb, foot)


# --- steering (pilot.gd): its behaviours ----------------------------------------

## hunt {prey}, display {seconds}, lay {at} (a female's), mate {partner}.
func _p_behaviours() -> PackedStringArray:
	if young:
		return PackedStringArray(["hunt"])
	return PackedStringArray(["hunt", "display", "mate"]) if male else PackedStringArray(["hunt", "display", "lay", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"hunt":
			var prey: Node3D = args.get("prey")
			if prey == null:
				return false
			hunt(prey)
		"display":
			display()
		"lay":
			if young or male:
				return false
			lay(args.get("at", _pos))
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"hunt", "lay", "display":
			return _mode != name
	return false


func _p_act_secs(name: String) -> float:
	return 6.0 if name == "display" else -1.0


func _piloted() -> void:
	if _mode in ["wander", "idle", "display"]:
		_mode = "piloted"


## An anole's egg (lay()): white, leathery, about 1 cm, half in the soil.
## hatch(): it rocks, a slit opens at one end, the hatchling's head out a
## while, then out and away, small, growing.
class AnoleEgg extends Node3D:
	var maker: Script
	var hatchling: Node3D
	var _shell: MeshInstance3D
	var _slit: MeshInstance3D
	var _t := -1.0

	func _ready() -> void:
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = 12
		s.rings = 7
		_shell = MeshInstance3D.new()
		_shell.mesh = s
		_shell.scale = Vector3(0.0075, 0.0068, 0.0115)
		_shell.position.y = 0.0028
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.94, 0.92, 0.85)
		m.roughness = 0.8
		_shell.material_override = m
		add_child(_shell)
		_slit = MeshInstance3D.new()
		_slit.mesh = s
		_slit.scale = Vector3(0.004, 0.0012, 0.003)
		_slit.position = Vector3(0.0, 0.0055, -0.0045)
		var dk := StandardMaterial3D.new()
		dk.albedo_color = Color(0.1, 0.08, 0.06)
		_slit.material_override = dk
		_slit.visible = false
		add_child(_slit)

	## Hatching: see the class.
	func hatch() -> void:
		if _t >= 0.0 or maker == null:
			return
		_t = 0.0

	func _process(dt: float) -> void:
		if _t < 0.0:
			return
		_t += dt
		_shell.rotation.z = sin(_t * 9.0) * 0.08 * clampf(1.0 - _t / 2.0, 0.0, 1.0)
		_slit.visible = _t > 1.0
		if _t > 2.5 and hatchling == null:
			var h: Node3D = maker.new(true)
			get_parent().add_child(h)
			var fwd := (global_transform.basis * Vector3.FORWARD)
			h.call("place", position + Vector3(fwd.x, 0.0, fwd.z).normalized() * 0.012, atan2(-fwd.x, -fwd.z))
			h.call("grow", 0.5, 240.0)
			h.call("wander", position, 0.12)
			hatchling = h
		if _t > 4.0: # (the empty shell, collapsing)
			_shell.scale.y = lerpf(_shell.scale.y, 0.0015, 1.0 - exp(-dt * 0.6))
