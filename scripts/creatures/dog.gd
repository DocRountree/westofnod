class_name Dog
extends "res://scripts/creatures/canid.gd" # (by path: found whether or not the editor has seen the class yet)
## A domestic dog (Canis familiaris), life size: the wolf's make (Canid,
## Carnivore) cut to its breed: make_spec() takes the grey wolf's measures
## and makes them over (its size, its legs' length, its build, its muzzle's
## length; its head sculpted, its own (the breed's SculptHead profile: its
## skull's dome, its stop, its muzzle's depth and breadth, its lips); ears
## pricked or hanging, drop: Carnivore's ears; its tail's carriage), and its
## coat (carnivore.gdshader's dog: solid, black and tan,
## tricolour: S.coat). The breeds: GermanShepherd, LabradorRetriever,
## Beagle. A dog's ways, besides a wolf's (wandering, sniffing, marking,
## hunting what it can run down, grooming, sleeping curled, the tie;
## whelping its pups in a box, Dog.bed(), nursing them; the pups playing):
## - bark(at, secs): braced, facing it, ears up, tail up, a bark and
##   another, in bursts, its head jerking with each
## - fetch(ball): after a thrown ball (Dog.ball(): bouncing to rest), at a
##   gallop, its mouth to it, picked up; trotted back to where it was
##   thrown from, dropped there, and it sits, its tail wagging, waiting
## - play_bow(): its forequarters down, its rump up, tail wagging; then off
##   in a wide fast circle and another (the zoomies), and back
## - dig(secs): its forepaws scraping at the ground in turn, earth thrown
##   back between its hind legs, its nose down in the hole now and then; a
##   hole left
## - greet(other): to another dog, nose to nose, then round to sniff under
##   its tail, both tails wagging
## Steering (pilot.gd): act bark {at, seconds}, fetch {ball}, play_bow,
## dig {seconds}, greet {other}; and the wolf's.

const HOLE_SECS := 120.0
const WolfScript := preload("res://scripts/creatures/grey_wolf.gd")
const NOT_MM := ["species", "neck_pitch", "mouth", "point", "tilt_back", "spread", "drop", "carry", "wrap", "walk", "trot", "run",
		"stalk_from", "spring", "stalk_crouch", "stalk_neck", "eat_crouch", "sit_pitch", "tilt", "mate_secs", "howl", "yips",
		"pw", "almond", "slant", "look_fwd", "pupil", "color", "slit", "n", "socket", "lid", "coat"]

var _ball: Node3D
var _throw_at := Vector3.ZERO
var _bark_at := Vector3.INF
var _other: Node3D
var _hole: MeshInstance3D
var _dirt: CPUParticles3D


## (A breed sets S, then this.)
func _init(young_ := false) -> void:
	young = young_
	super(young_, 0.11 if young_ else 0.5)
	_setup()


## The wolf's measures made over (k its size of the wolf's; legs their
## length of its; build its girth; muzzle its length ahead of the eyes;
## head: its head's sculpting (SculptHead's P: the wolf's keys set over, in
## the wolf's mm, made over with the rest); more: keys set over the result,
## the ear's and the tail's merged).
static func make_spec(k: float, legs_: float, build: float, muzzle: float, more: Dictionary, head := {}) -> Dictionary:
	var W: Dictionary = WolfScript.SPEC.duplicate(true)
	(W.sculpt as Dictionary).merge(head, true)
	if head.has("eye"):
		var E0: Dictionary = W.eye
		E0.at = (head.eye as Vector3) + ((E0.at as Vector3) - ((WolfScript.SPEC.sculpt as Dictionary).eye as Vector3))
	var S: Dictionary = _sc(W, "", k)
	var eye_z: float = ((S.eye as Dictionary).at as Vector3).z
	var mz := func(z: float) -> float: return eye_z + (z - eye_z) * muzzle if z < eye_z else z
	for key: String in ["head", "jaw"]:
		for row: Array in S[key]:
			row[0] = mz.call(float(row[0]))
	var nose: Dictionary = S.nose
	nose.at = Vector3((nose.at as Vector3).x, (nose.at as Vector3).y, mz.call((nose.at as Vector3).z))
	var sc: Dictionary = S.sculpt
	var zs: Array = sc.z
	for i in zs.size():
		zs[i] = mz.call(float(zs[i]))
	if head.is_empty(): # (its head the wolf's, made broader with it; a breed's own sculpting its own)
		for key: String in ["w", "wl"]:
			var a: Array = sc[key]
			for i in a.size():
				a[i] = float(a[i]) * lerpf(1.0, build, 0.6)
	S.mouth_z = float(S.mouth_z) - (1.0 - muzzle) * 140.0 * k
	# (its build: its body broader and deeper)
	for row: Array in S.body:
		row[2] = float(row[2]) * build
		row[3] = float(row[3]) * lerpf(1.0, build, 0.6)
	S.body_w = float(S.body_w) * build
	# (its legs: shorter, the body let down on them)
	var leg_sum := 0.0
	for key: String in ["fore", "hind"]:
		var L: Dictionary = S[key]
		leg_sum = float(L.a) + float(L.b) + float(L.m)
		for q: String in ["a", "b", "m"]:
			L[q] = float(L[q]) * legs_
		L.hip = (L.hip as Vector3) * Vector3(build, 1.0, 1.0)
		L.home = (L.home as Vector2) * Vector2(build, 1.0)
		L.r = float(L.r) * lerpf(1.0, build, 0.7)
	S.body_h = float(S.body_h) - leg_sum * (1.0 - legs_) * 0.82
	S.sit_drop = float(S.sit_drop) * legs_
	S.lie_h = float(S.lie_h) * lerpf(1.0, build, 0.5)
	S.species = 17
	S.howl = false
	for key: String in more:
		if key in ["ear", "tail", "sculpt"] and S.has(key):
			(S[key] as Dictionary).merge(more[key], true)
		else:
			S[key] = more[key]
	return S


static func _sc(v: Variant, key: String, k: float) -> Variant:
	if key in NOT_MM:
		return v.duplicate(true) if v is Dictionary or v is Array else v
	if v is Dictionary:
		var d := {}
		for q: String in v:
			d[q] = _sc(v[q], q, k)
		return d
	if v is Array:
		var a := []
		for e: Variant in v:
			a.append(_sc(e, key, k))
		return a
	if v is float or v is int:
		return float(v) * k
	if v is Vector3 or v is Vector2:
		return v * k
	return v


func _coat(part: int, along := 0.0) -> ShaderMaterial:
	var m := super(part, along)
	var c: Dictionary = S.get("coat", {})
	for key: String in c:
		var v: Variant = c[key]
		m.set_shader_parameter(key, Vector3(v.r, v.g, v.b) if v is Color else v) # (its colours as given: linear)
	return m


# --- its own ways --------------------------------------------------------------------------

func bark(at := Vector3.INF, secs := 6.0) -> void:
	if young and size < 0.25:
		return
	_mode = "bark"
	_bark_at = at
	_st = 0.0
	_wait = secs
	_sit_to = 0.0
	_lie_to = 0.0


func fetch(ball_: Node3D) -> void:
	if ball_ == null or not is_instance_valid(ball_):
		return
	_ball = ball_
	_throw_at = _pos
	_mode = "fetch"
	_stage = 0
	_st = 0.0
	_sit_to = 0.0
	_lie_to = 0.0


func play_bow() -> void:
	_mode = "bow"
	_stage = 0
	_st = 0.0
	_throw_at = _pos
	_sit_to = 0.0
	_lie_to = 0.0


func dig(secs := 8.0) -> void:
	_mode = "dig"
	_st = 0.0
	_wait = secs
	_target = _pos
	_sit_to = 0.0
	_lie_to = 0.0


func greet(other: Node3D) -> void:
	if other == null or not is_instance_valid(other):
		return
	_other = other
	_mode = "greet"
	_stage = 0
	_st = 0.0


func _face(p: Vector3) -> void:
	var d := p - _pos
	if Vector2(d.x, d.z).length() > 0.01:
		_turn_to = atan2(-d.x, -d.z)


func _mouth() -> Vector3:
	return _jaw.global_transform * Vector3(0.0, 8.0, float((S.jaw as Array)[(S.jaw as Array).size() - 1][0]) * 0.75)


func _think(dt: float) -> void:
	if _mode != "dig" and (_hole != null or _dirt != null): # (called off its digging: the earth settles, the hole's left)
		if _dirt:
			_dirt.queue_free()
			_dirt = null
		_settle(_hole)
		_hole = null
	if _mode not in ["bark", "fetch", "bow", "dig", "greet"]:
		super(dt)
		_hold_ball()
		return
	_wait -= dt
	_st += dt
	_ears_to = 0.6
	_jaw_to = 0.0
	_neck_to = Vector2.ZERO
	_look_to = Vector2.ZERO
	_tail_mode = "wag"
	var reach := absf(float(S.mouth_z)) * MM * size
	match _mode:
		"bark": # (braced, facing it; a bark, another, in bursts)
			_target = _pos
			_pace = -1.0
			if _bark_at != Vector3.INF:
				_face(_bark_at)
			_tail_mode = "out"
			_ears_to = 1.0
			var ph := fmod(_st, 3.0)
			var on := ph < 1.8 and fmod(ph, 0.45) < 0.16
			_jaw_to = 0.55 if on else 0.05
			_neck_to = Vector2(0.25 + (0.12 if on else 0.0), 0.0)
			_look_to = Vector2(-0.1 if on else 0.0, 0.0)
			if _wait <= 0.0:
				wander(_home_spot(), _radius)
		"fetch":
			if _ball == null or not is_instance_valid(_ball):
				wander(_home_spot(), _radius)
				return
			match _stage:
				0: # (after it, flat out)
					var bp := _ball.position
					_target = bp
					_pace = float(S.run) * 0.65 * lerpf(0.35, 1.0, size)
					_tail_mode = "out"
					_ears_to = 0.3
					if Vector2(bp.x - _pos.x, bp.z - _pos.z).length() < reach * 1.15 and not _ball.has_meta("flying"):
						_stage = 1
						_st = 0.0
						_pace = -1.0
				1: # (its mouth down to it, picked up)
					_target = _pos
					_neck_to = Vector2(-0.8, 0.0)
					_jaw_to = 0.35 if _st < 0.5 else 0.12
					if _st > 0.6:
						_ball.set_meta("held", self)
						_stage = 2
				2: # (trotted back)
					_target = _throw_at
					_pace = float(S.trot) * 0.8 * lerpf(0.35, 1.0, size)
					_jaw_to = 0.12
					if Vector2(_throw_at.x - _pos.x, _throw_at.z - _pos.z).length() < 0.4 * size / 0.5:
						_stage = 3
						_st = 0.0
						_pace = -1.0
				3: # (dropped; sitting, wagging, waiting)
					_target = _pos
					if _st > 0.4 and _ball.has_meta("held"):
						_ball.remove_meta("held")
						var g := _ball.position
						g.y = _ground(g.x, g.z) + 0.033
						_ball.position = g
					_sit_to = 1.0 if _st > 0.8 else 0.0
					_neck_to = Vector2(0.2, 0.0)
					if _st > 6.0:
						_sit_to = 0.0
						wander(_home_spot(), _radius)
		"bow": # (down in front, rump up, wagging; then the zoomies)
			if _stage == 0:
				_target = _pos
				_pace = -1.0
				_ears_to = 0.8
				_jaw_to = 0.18
				_neck_to = Vector2(0.15, 0.0)
				if _st > 1.8:
					_stage = 1
					_st = 0.0
			else:
				var r := 2.2 * size / 0.5
				var a := _st * 2.6 / maxf(r, 0.3)
				_target = _throw_at + Vector3(cos(a), 0.0, sin(a)) * r + Vector3(-r, 0.0, 0.0)
				_pace = float(S.run) * 0.55 * lerpf(0.35, 1.0, size)
				_tail_mode = "out"
				_ears_to = -0.4
				_jaw_to = 0.3
				if _st > 7.0:
					_pace = -1.0
					wander(_home_spot(), _radius)
		"dig": # (forepaws scraping in turn, nose to the hole now and then)
			_target = _pos
			_pace = -1.0
			_tail_mode = "wag"
			_neck_to = Vector2(-0.7, 0.0)
			_sniff = 1.0 if fmod(_st, 4.0) > 3.2 else 0.0
			if _hole == null:
				_hole = MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.5
				cm.bottom_radius = 0.3
				cm.height = 0.02
				_hole.mesh = cm
				var hm := StandardMaterial3D.new()
				hm.albedo_color = Color(0.2, 0.15, 0.1)
				hm.roughness = 1.0
				_hole.material_override = hm
				_hole.set_meta("prop", true)
				get_parent().add_child(_hole)
				var at := _pos + Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * reach * 0.8
				at.y = _ground(at.x, at.z) + 0.004
				_hole.position = at
				_hole.scale = Vector3.ONE * 0.02
				_dirt = CPUParticles3D.new()
				_dirt.amount = 24
				_dirt.lifetime = 0.8
				_dirt.direction = Vector3(0.0, 1.0, 1.0)
				_dirt.spread = 25.0
				_dirt.initial_velocity_min = 1.0
				_dirt.initial_velocity_max = 2.2
				_dirt.scale_amount_min = 0.4
				_dirt.scale_amount_max = 1.0
				var q := SphereMesh.new()
				q.radius = 0.008
				q.height = 0.016
				q.radial_segments = 4
				q.rings = 2
				_dirt.mesh = q
				_dirt.material_override = hm
				_dirt.local_coords = false
				add_child(_dirt)
			var g := minf(_st / 8.0, 1.0)
			_hole.scale = Vector3.ONE * lerpf(0.02, 0.2, g) * size / 0.5
			if _dirt:
				_dirt.position = Vector3(0.0, 0.05, -reach * 0.7) # (at its forepaws, flung back between its hind legs)
				_dirt.direction = Vector3(0.0, 0.7, 1.0)
				_dirt.emitting = true
			if _wait <= 0.0:
				if _dirt: # (its earth settled: the emitter gone after its last)
					_dirt.emitting = false
					var dd := _dirt
					get_tree().create_timer(1.0).timeout.connect(func() -> void: if is_instance_valid(dd): dd.queue_free())
					_dirt = null
				_settle(_hole)
				_hole = null
				wander(_home_spot(), _radius)
		"greet": # (nose to nose, then round to sniff under its tail)
			if _other == null or not is_instance_valid(_other):
				wander(_home_spot(), _radius)
				return
			var op: Vector3 = _other.get("_pos")
			var oy: float = _other.get("_yaw")
			var ofw := Vector3(-sin(oy), 0.0, -cos(oy))
			var to := op + ofw * reach * 2.0 if _stage == 0 else op - ofw * reach * 1.6
			_target = to
			_neck_to = Vector2(-0.2, 0.0)
			_sniff = 1.0
			if _pos.distance_to(to) < reach * 0.6:
				_face(op)
				if _st > 2.5:
					_stage += 1
					_st = 0.0
					if _stage >= 2:
						wander(_home_spot(), _radius)
	_hold_ball()


## (A hole it dug: left a while, then filled in, gone.)
func _settle(h: Node3D) -> void:
	if h == null or not is_instance_valid(h):
		return
	var tw := h.create_tween()
	tw.tween_interval(HOLE_SECS)
	tw.tween_property(h, "scale", Vector3(0.001, 1.0, 0.001) * h.scale, 8.0)
	tw.tween_callback(h.queue_free)


func _pose(dt: float) -> void:
	super(dt)
	if _mode == "bow" and _stage == 0: # (its forequarters down, rump up)
		var k := smoothstep(0.0, 0.5, _st)
		_pitch -= 0.38 * k
		_lift -= 40.0 * k * size / 0.5
	if _mode == "dig": # (each forepaw scraping down and back in turn)
		for i in 2:
			var L: Dictionary = legs[0]
			var side := 1.0 if i == 1 else -1.0
			var hm: Vector2 = L.home
			var ph := fmod(_st * 3.2 + 0.5 * i, 1.0)
			var z := hm.y - 60.0 + 150.0 * ph
			var y := -(body_h + _lift) + (40.0 * sin(PI * ph) if ph > 0.7 else 0.0) + 20.0 * (1.0 - smoothstep(0.0, 0.2, ph))
			_pose_foot[i] = Vector3(hm.x * side * 0.6, y, z)
		_pitch -= 0.12


func _hold_ball() -> void:
	if _ball != null and is_instance_valid(_ball) and _ball.has_meta("held") and _ball.get_meta("held") == self:
		_ball.global_position = _mouth()


## A ball, thrown from `from` to land at `to` (in parent's space), bouncing
## to rest.
static func ball(parent: Node3D, from: Vector3, to: Vector3) -> Node3D:
	var b := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.033
	sm.height = 0.066
	b.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.82, 0.9, 0.2)
	m.roughness = 0.9
	b.material_override = m
	b.set_meta("prop", true)
	b.set_meta("flying", true)
	parent.add_child(b)
	b.position = from + Vector3(0.0, 1.2, 0.0)
	var tw := b.create_tween()
	var land := to + Vector3(0.0, 0.033, 0.0)
	var t := 1.1
	tw.tween_method(func(f: float) -> void: b.position = (from + Vector3(0.0, 1.2, 0.0)).lerp(land, f) + Vector3(0.0, 3.0 * f * (1.0 - f) * 1.6, 0.0), 0.0, 1.0, t)
	var on := land + (land - from) * Vector3(1.0, 0.0, 1.0) * 0.12
	tw.tween_method(func(f: float) -> void: b.position = land.lerp(on, f) + Vector3(0.0, 0.5 * sin(PI * f), 0.0), 0.0, 1.0, 0.45)
	tw.tween_callback(func() -> void: b.remove_meta("flying"))
	return b


## A whelping box: low sides, a blanket in it. Its origin on the ground at its middle.
static func bed(scale_ := 1.0) -> Node3D:
	var root := Node3D.new()
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.6, 0.48, 0.32)
	wood.roughness = 0.8
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.36, 0.42, 0.55)
	cloth.roughness = 1.0
	var w := 1.0 * scale_
	var d := 0.8 * scale_
	var h := 0.22 * scale_
	for p: Array in [[Vector3(0.0, 0.01, 0.0), Vector3(w, 0.02, d), wood], [Vector3(0.0, 0.03, 0.0), Vector3(w * 0.94, 0.03, d * 0.92), cloth],
			[Vector3(w * 0.5, h * 0.5, 0.0), Vector3(0.025, h, d), wood], [Vector3(-w * 0.5, h * 0.5, 0.0), Vector3(0.025, h, d), wood],
			[Vector3(0.0, h * 0.5, d * 0.5), Vector3(w, h, 0.025), wood], [Vector3(0.0, h * 0.25, -d * 0.5), Vector3(w, h * 0.5, 0.025), wood]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = p[1]
		mi.mesh = bm
		mi.position = p[0]
		mi.material_override = p[2]
		root.add_child(mi)
	return root


func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(["bark", "fetch", "play_bow", "dig", "greet"])
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"bark":
			bark(args.get("at", Vector3.INF), float(args.get("seconds", 6.0)))
			return true
		"fetch":
			fetch(args.get("ball"))
			return true
		"play_bow":
			play_bow()
			return true
		"dig":
			dig(float(args.get("seconds", 8.0)))
			return true
		"greet":
			greet(args.get("other"))
			return true
	return super(name, args)


func _p_act_done(name: String) -> bool:
	if name in ["bark", "fetch", "play_bow", "dig", "greet"]:
		return _mode != {"bark": "bark", "fetch": "fetch", "play_bow": "bow", "dig": "dig", "greet": "greet"}[name]
	return super(name)
