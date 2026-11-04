extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## The bears' ways (BlackBear, BrownBear), on the hunters' make (Carnivore),
## plantigrade: on the whole sole, the heel down, the claws out before the
## toes; heavy, its head carried low, its walk a rolling amble, its gallop a
## lumbering rush. Its coat its colour phase (phase; the black bear's
## sometimes a white blaze on its chest).
##
## - forage(centre, radius): ambling, its nose to the ground, sniffing;
##   stopping to dig (its forepaws raking the earth back by turns, its head
##   down in the hole, eating what it finds)
## - browse(bush) (Ursid.berry_bush()): at it, stripping the berries with
##   its lips, now and then up on its hind legs to the higher ones
## - stand(secs): up on its hind legs, tall, its forepaws hanging, its nose
##   up, sniffing the air
## - rub(at): its back to a tree (at: its trunk), up on its hind legs
##   against it, rubbing up and down (its mark)
## - hunt(prey): its rush at it, a swipe, pinned; eaten
## - birth(n, den) in its den (Ursid.den(): a hollow under a root mound):
##   the cubs born tiny, near naked, blind; nursed; growing; following her;
##   playing (up on their hind legs together, boxing, tumbling over)
## - mate(her): he follows her, sniffing; then on her from behind, his
##   forelegs round her waist, mouthing her neck now and then; a long while
## Steering (pilot.gd): act forage {centre, radius}, browse {bush}, stand
## {seconds}, rub {at}; and the hunters' own.

var phase := 0 ## its colour phase (the species')
var blaze := false ## (a black bear's white chest blaze)
var _stand := 0.0
var _stand_to := 0.0
var _dig := 0.0
var _hole: MeshInstance3D
var _bush: Node3D
var _rub_at := Vector3.ZERO
var _mats: Array[ShaderMaterial] = []


func _coat(part: int, along := 0.0) -> ShaderMaterial:
	var m := super(part, along)
	m.set_shader_parameter("phase", phase)
	m.set_shader_parameter("muzzle_z", float(S.get("muzzle_z", -120.0)))
	m.set_shader_parameter("blaze", blaze)
	_mats.append(m)
	return m


## Its colour phase now (and its cubs': their mother's).
func set_phase(p: int) -> void:
	phase = p
	for m in _mats:
		m.set_shader_parameter("phase", p)


func _build_extra() -> void:
	# the claws, out before the toes (the black bear's short and curved, the
	# brown bear's long, nearly straight, pale)
	var claw := _coat(7)
	var cl: float = S.get("claw", 30.0)
	for i in 4:
		var paw := _legx[i][1] as MeshInstance3D
		for k in 5:
			var x := (float(k) - 2.0) * 0.18
			var len_ := cl * (1.4 if i < 2 else 0.9) / 100.0
			_stick(Vector3(x, -0.1, 0.42), Vector3(x * 1.1, -0.35, 0.42 + len_), 0.035, claw, paw)
	for h: Array in S.get("hump", []): # (a brown bear's shoulder hump)
		_part(h[0], h[1], _coat(0), _body)


## A berry bush (a huckleberry's: about 80 cm, twiggy, small leaves, dark
## blue berries), for it to strip; its origin at its foot.
static func berry_bush() -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 8
	s.rings = 4
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	c.radial_segments = 5
	var twig := StandardMaterial3D.new()
	twig.albedo_color = Color(0.35, 0.28, 0.18)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.25, 0.42, 0.18)
	var berry := StandardMaterial3D.new()
	berry.albedo_color = Color(0.12, 0.12, 0.3)
	berry.roughness = 0.3
	for k in 14:
		var a := rng.randf() * TAU
		var top := Vector3(cos(a) * rng.randf_range(0.05, 0.35), rng.randf_range(0.35, 0.85), sin(a) * rng.randf_range(0.05, 0.35))
		var mi := MeshInstance3D.new()
		mi.mesh = c
		var d := top
		var y := d.normalized()
		var x := y.cross(Vector3.FORWARD).normalized()
		mi.transform = Transform3D(Basis(x * 0.012, d, x.cross(y) * 0.012), d * 0.5)
		mi.material_override = twig
		root.add_child(mi)
		for l in 9:
			var p := top * rng.randf_range(0.4, 1.0) + Vector3(rng.randf_range(-0.06, 0.06), rng.randf_range(-0.04, 0.04), rng.randf_range(-0.06, 0.06))
			var lf := MeshInstance3D.new()
			lf.mesh = s
			lf.position = p
			lf.scale = Vector3(0.04, 0.006, 0.025)
			lf.rotation = Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, 0.0)
			lf.material_override = leaf
			root.add_child(lf)
			if l % 3 == 0:
				var b := MeshInstance3D.new()
				b.mesh = s
				b.name = "berry"
				b.position = p + Vector3(0.0, -0.015, 0.0)
				b.scale = Vector3.ONE * 0.012
				b.material_override = berry
				root.add_child(b)
	return root


## A bear's den: a hollow dug under a mound, roots over its mouth (-z). Its
## origin on the ground at its middle.
static func den(scale_ := 1.0) -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.36, 0.28, 0.2)
	earth.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.04, 0.035, 0.03)
	var root_m := StandardMaterial3D.new()
	root_m.albedo_color = Color(0.4, 0.32, 0.22)
	for p in [[Vector3(0.0, 0.0, 0.0), Vector3(2.6, 1.1, 2.2), earth], [Vector3(0.0, 0.25, -1.0), Vector3(0.9, 0.7, 0.3), dark]]:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = (p[0] as Vector3) * scale_
		mi.scale = (p[1] as Vector3) * scale_
		mi.material_override = p[2]
		root.add_child(mi)
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	c.radial_segments = 5
	for k in 7: # (roots arching over its mouth)
		var a := lerpf(-1.2, 1.2, float(k) / 6.0)
		var p0 := Vector3(sin(a) * 0.6, 0.0, -1.05) * scale_
		var p1 := Vector3(sin(a) * 0.3, 0.75, -0.95) * scale_
		var mi := MeshInstance3D.new()
		mi.mesh = c
		var d := p1 - p0
		var y := d.normalized()
		var x := y.cross(Vector3.FORWARD).normalized()
		mi.transform = Transform3D(Basis(x * 0.04 * scale_, d, x.cross(y) * 0.04 * scale_), (p0 + p1) * 0.5)
		mi.material_override = root_m
		root.add_child(mi)
	return root


# --- its own ways --------------------------------------------------------------------

func forage(centre: Vector3, radius: float) -> void:
	_mode = "forage"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_stage = 0


func browse(bush: Node3D) -> void:
	if bush == null or not is_instance_valid(bush):
		return
	_mode = "browse"
	_bush = bush
	_stage = 0
	_st = 0.0


func stand(secs := 5.0) -> void:
	_mode = "stand"
	_st = 0.0
	_wait = secs


func rub(at: Vector3) -> void:
	_mode = "rub"
	_rub_at = at
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	match _mode:
		"forage":
			_common(dt)
			_forage(dt)
			return
		"browse":
			_common(dt)
			_browse(dt)
			return
		"stand":
			_common(dt)
			_target = _pos
			_stand_to = 1.0
			_neck_to = Vector2(0.5, 0.0)
			_look_to = Vector2(0.35 + 0.1 * sin(_st * 0.9), 0.4 * sin(_st * 0.5))
			_sniff = 1.0
			_ears_to = 1.0
			if _wait <= 0.0:
				_stand_to = 0.0
				if _stand < 0.05:
					wander(_home_spot(), _radius)
			return
		"rub":
			_common(dt)
			_rub(dt)
			return
	_stand_to = 0.0 if _mode not in ["play"] else _stand_to
	super(dt)


func _common(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	_sniff = move_toward(_sniff, 0.0, dt * 2.0)
	_ears_to = 0.0
	_jaw_to = 0.0
	_neck_to = Vector2.ZERO
	_tail_mode = "carry"
	_lie_to = 0.0
	_sit_to = 0.0


func _forage(dt: float) -> void:
	match _stage:
		0: # (ambling, its nose to the ground)
			_neck_to = Vector2(-0.6, 0.15 * sin(_st * 1.3))
			_sniff = 1.0
			_pace = float(S.walk) * 0.5 * lerpf(0.35, 1.0, size)
			if _wait <= 0.0:
				if rng.randf() < 0.45:
					_stage = 1 # (a dig)
					_st = 0.0
					_target = _pos
				else:
					var a := rng.randf() * TAU
					_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
					_wait = rng.randf_range(3.0, 6.0)
		1: # digging: its forepaws raking the earth back by turns, its head down
			_target = _pos
			_pace = -1.0
			_dig = minf(_dig + dt / 6.0, 1.0)
			_neck_to = Vector2(-0.95, 0.0)
			var hole := _out(Vector3(0.0, -body_h, float(S.mouth_z) * 0.85))
			if _hole == null:
				_hole = MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.5
				cm.bottom_radius = 0.5
				cm.height = 1.0
				_hole.mesh = cm
				_hole.material_override = _mat(Color(0.2, 0.15, 0.1), 1.0)
				get_parent().add_child(_hole)
				_hole.position = Vector3(hole.x, _ground(hole.x, hole.z) + 0.002, hole.z)
			_hole.scale = Vector3(0.35, 0.004, 0.35) * maxf(_dig, 0.05) * size / 0.5
			if _st > 6.0: # (eating what it's found)
				_chew = 1.0
				_dig = 0.0
				if _st > 9.0:
					_hole = null
					_stage = 0
					_wait = 0.0
					_st = 0.0


func _browse(dt: float) -> void:
	if not is_instance_valid(_bush):
		wander(_home_spot(), _radius)
		return
	var p := _bush.global_position
	var to := p - _pos
	to.y = 0.0
	var reach := -float(S.mouth_z) * MM * size * 0.85
	match _stage:
		0:
			_target = p - to.normalized() * reach
			if to.length() < reach * 1.15 and _speed < 0.05:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
		1: # stripping the berries with its lips; up for the higher ones
			_target = _pos
			_chew = 1.0
			_jaw_to = 0.12 * maxf(sin(_st * 7.0), 0.0)
			var high := fmod(_st, 10.0) > 6.0
			_stand_to = 0.55 if high else 0.0
			_neck_to = Vector2(-0.2 if not high else 0.3, 0.3 * sin(_st * 0.6))
			if fmod(_st, 1.5) < dt: # (a berry gone)
				for b in _bush.get_children():
					if b.name.begins_with("berry") and (b as Node3D).visible:
						(b as Node3D).visible = false
						break
			if _st > 18.0:
				_stand_to = 0.0
				wander(_home_spot(), _radius)


func _rub(dt: float) -> void:
	var to := _rub_at - _pos
	to.y = 0.0
	match _stage:
		0: # (to just before the tree, its back to it)
			var spot := _rub_at - to.normalized() * float(S.body_len) * 0.35 * MM * size
			_target = spot
			if Vector2(spot.x - _pos.x, spot.z - _pos.z).length() < 0.1 and _speed < 0.05:
				_target = _pos
				_turn_to = atan2(to.x, to.z) # (facing away from it)
				_stage = 1
				_st = 0.0
		1: # (up against it, rubbing up and down, its back, its shoulders)
			_target = _pos
			if _turn_to == INF:
				_stand_to = 0.85
				_look_to = Vector2(0.2, 0.0)
				_neck_to = Vector2(0.3, 0.0)
				if _st > 10.0:
					_stand_to = 0.0
					if _stand < 0.05:
						wander(_home_spot(), _radius)


## (Up on its hind legs: the body upright, its forepaws hanging; rubbing,
## swaying up and down.)
func _pose(dt: float) -> void:
	super(dt)
	_stand = move_toward(_stand, _stand_to, dt * 0.9)
	if _stand <= 0.001 or airborne:
		return
	var k := _stand * _stand * (3.0 - 2.0 * _stand)
	var rubbing := _mode == "rub" and _stage == 1
	var hip_y := float((legs[1] as Dictionary).hip.y)
	var hip_z := float((legs[1] as Dictionary).hip.z)
	var up_pitch := 1.3 * k
	# (the origin raised so the hips stay where the hind legs hold them)
	var leg_h := (float(S.hind.a) + float(S.hind.b)) * 0.85
	var hip_drop := -(hip_y * cos(up_pitch) - hip_z * sin(up_pitch)) # (how far under the origin the hips go)
	_pitch = up_pitch
	_lift = lerpf(_lift, (leg_h + hip_drop) - body_h + (sin(_t * 1.6) * 40.0 if rubbing else 0.0), k)
	_roll = 0.06 * sin(_t * 0.8) * k if rubbing else _roll
	var to_world := transform * _body.transform
	var inv := to_world.affine_inverse()
	var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	for i in 4:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var hw := to_world * Vector3(hp.x * side, hp.y, hp.z)
		if i >= 2: # (the hind feet flat under its hips, toes forward)
			var f := hw + fwd * float(L.s) * 0.6
			f.y = _ground(f.x, f.z)
			_pose_foot[i] = inv * f
		else: # (the forepaws hanging before it, loose; boxing, a cub's)
			var hang := hw + Vector3.DOWN * float(L.f) * 0.75 * MM * size + fwd * float(L.f) * 0.5 * MM * size
			if _mode == "play":
				hang += fwd * sin(_t * 8.0 + side) * float(L.f) * 0.5 * MM * size + Vector3.UP * float(L.f) * 0.4 * MM * size
			_pose_foot[i] = inv * hang


## The hunt's end: its rush, a swipe of a forepaw, and on it.
func _attack(_dt: float, p: Vector3, d: float) -> bool:
	var reach := 0.7 * size / 0.5
	if d > reach:
		_target = p
		_pace = float(S.run) * 0.7 * lerpf(0.35, 1.0, size)
		_ears_to = -0.4
		return false
	_pace = -1.0
	_leap(p, 0.25)
	return true


## (Cubs at play: up on their hind legs together, boxing, then over.)
func _play(dt: float) -> void:
	if not is_instance_valid(_sib):
		wander(_pos, 0.6)
		return
	var p: Vector3 = _sib.get("_pos")
	var to := p - _pos
	to.y = 0.0
	match _stage:
		0:
			_target = p - to.normalized() * 0.25 * size / 0.5
			if to.length() < 0.3 * size / 0.5 + 0.05:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
		1: # (up, boxing, mouthing)
			_target = _pos
			_stand_to = 0.8
			_jaw_to = 0.25 * maxf(sin(_st * 5.0), 0.0)
			if _st > 3.5:
				_stand_to = 0.0
				_stage = 2
				_st = 0.0
		2: # (over, tumbling, and up)
			_target = _pos
			_roll = lerpf(_roll, PI * 0.7 * sin(_st * 3.0), 1.0 - exp(-5.0 * dt)) if _st < 1.6 else lerpf(_roll, 0.0, 1.0 - exp(-5.0 * dt))
			if _st > 2.4:
				_roll = 0.0
				_mode = "follow" if is_instance_valid(_mother) else "wander"


func _young_one() -> void:
	super()
	var y := young_ones[young_ones.size() - 1]
	if is_instance_valid(y):
		y.call("set_phase", phase)


func _court_secs() -> float:
	return 6.0


func _mount() -> Dictionary:
	# on her from behind, his forelegs round her waist; mouthing her neck
	var inv := (transform * _body.transform).affine_inverse()
	var free := {}
	for i: int in [2, 3]:
		var side := 1.0 if i % 2 == 1 else -1.0
		var w: Vector3 = _mate.call("_out", Vector3(float(S.body_w) * 0.8 * side, -body_h, float(S.body_len) * 0.62))
		w.y = _ground(w.x, w.z)
		free[i] = inv * w
	var bite := fmod(_mate_t, 7.0) < 1.6
	_neck_to = Vector2(-0.7 if bite else -0.2, 0.0)
	_jaw_to = 0.3 if bite else 0.0
	return {"at": Vector3(0.0, float(S.body_h) * 0.5, float(S.body_len) * 0.42), "basis": Basis(Vector3.RIGHT, 0.5), "grips": {
		0: Vector3(-float(S.body_w) * 0.95, -40.0, 120.0), 1: Vector3(float(S.body_w) * 0.95, -40.0, 120.0)}, "free": free}


func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["forage", "browse", "stand", "rub"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"forage":
			forage(args.get("centre", _pos), float(args.get("radius", 2.0)))
		"browse":
			var bsh: Node3D = args.get("bush")
			if bsh == null:
				return false
			browse(bsh)
		"stand":
			stand(float(args.get("seconds", 5.0)))
		"rub":
			rub(args.get("at", _pos + _p_heading()))
		_:
			return super(name, args)
	return true


func _p_act_done(name: String) -> bool:
	if name in ["forage", "browse", "stand", "rub"]:
		return _mode != name
	return super(name)


func _p_act_secs(name: String) -> float:
	return 15.0 if name == "forage" else super(name)
