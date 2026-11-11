class_name Otter
extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## The otters' ways in the water (RiverOtter, SeaOtter), on the hunters'
## make (Carnivore: plantigrade, its feet webbed): long, low, supple; at
## home in the water and quick in it, slow and a little clumsy out of it
## (the sea otter the more so). Its water: wet ((x, z) -> whether it's water
## there), water_y its surface, floor_y its bottom (m).
##
## In the water it swims low, its head and the line of its back showing,
## its forefeet tucked to its chest, its hind feet paddling (by turns, slow;
## together, fast), its body and tail rippling up and down; it dives (its
## nose down, its back arching over, its tail last) and swims along the
## bottom, and comes up again a way off. Or it floats on its back (the sea
## otter's way of life: resting, eating, grooming, asleep there), its
## forepaws on its chest, its hind feet out of the water. Its coat goes wet
## in the water (soaked: dark, glossy, in spiky locks: carnivore.gdshader's
## soak) and dries on land over a couple of minutes, the faster for rolling
## and rubbing it.
##
## - swim(centre, radius): about in its water, now and then a dive
## - dive(): under, along the bottom a while, up again
## - fish(school): (FishSchool: a pond's salmon or trout) into the water,
##   under, after the nearest fish, chasing it; caught in its jaws, up
##   with it; eaten as its kind eats (eat_held)
## - catch(prey): after anything in or by the water (a crayfish on the
##   bottom, a frog, a shrimp): under after it if it's under, in its jaws;
##   up with it, eaten as its kind eats
## - eat_held(food): held in its forepaws to its mouth, bitten and chewed,
##   piece by piece, head first (its kind: on the bank, or on its back)
## Steering (pilot.gd): act swim {centre, radius}, dive, fish {school},
## catch {prey}; and the hunters' own.

var wet: Callable ## (x, z) -> whether it's water there
var water_y := 0.0 ## its water's surface (m)
var floor_y := -1.0 ## its water's bottom (m), where it's deepest
var soaked := 0.0 ## its coat: 0 dry .. 1 just out of the water
var dry_secs := 120.0 ## how long its coat takes to dry, out of the water (rolling, grooming: a third)
var _in_water := false
var _dive := 0.0 # (0 at the surface .. 1 on the bottom)
var _dive_to := 0.0
var _dive_was := 0.0
var _under_t := 0.0 # (s left of a dive, swimming about)
var _float_t := 0.0 # (s left of a while floating on its back, swimming about)
var _paddle := 0.0
var _back := 0.0 # (0 belly down .. 1 on its back)
var _back_to := 0.0
var _spin := 0.0 # (rad: rolled over about its length, beyond being on its back)
var _food: Node3D # (held in its forepaws, eaten)
var _food_s := Vector3.ONE
var _food_secs := 12.0
var _school: Node3D
var _fish_i := -1
var _coats: Array[ShaderMaterial] = []
var _soak_shown := -1.0
var _rose := false # (back up from a dive with what it caught)


func _coat(part: int, along := 0.0) -> ShaderMaterial:
	var m := super(part, along)
	_coats.append(m)
	return m


# --- its water ----------------------------------------------------------------------

## Its body's half height (m).
func _half_h() -> float:
	var h := 0.0
	for k: Array in S.body:
		h = maxf(h, float(k[3]))
	return h * MM * size


## How far below the surface its middle rides, swimming at the surface (m;
## its kind's: on its back, higher).
func _surface_sink() -> float:
	return _half_h() * lerpf(0.55, 0.2, _back)


## The ground under (x, z): in its water, where its body floats (at the
## surface; diving, down toward the bottom, along it).
func _ground(x: float, z: float) -> float:
	var g := super(x, z)
	if wet.is_valid() and bool(wet.call(x, z)):
		var deep := maxf(water_y - floor_y - _half_h() * 1.3, 0.0)
		var sink := lerpf(_surface_sink(), maxf(deep, _surface_sink()), _dive)
		return maxf(water_y - sink - body_h * MM * size, g)
	return g


## (Its height eased, in and out of the water: not jumping as it goes from
## the bank to floating.)
func _walk(dt: float) -> void:
	var was := _pos.y
	super(dt)
	if absf(_pos.y - was) < 1.0:
		_pos.y = lerpf(was, _pos.y, 1.0 - exp(-5.0 * dt))


func _nearest_water() -> Vector3:
	if not wet.is_valid():
		return _pos
	if bool(wet.call(_pos.x, _pos.z)):
		return _pos
	for r in [0.3, 0.6, 1.0, 1.5, 2.2, 3.0, 4.5, 6.0]:
		for k in 16:
			var a := TAU * k / 16.0
			var p := _pos + Vector3(cos(a), 0.0, sin(a)) * float(r)
			if bool(wet.call(p.x, p.z)):
				return p + Vector3(cos(a), 0.0, sin(a)) * 0.35
	return _pos


## The nearest dry ground to it (out of the water: the bank), a little up it.
func _nearest_bank() -> Vector3:
	if not wet.is_valid() or not bool(wet.call(_pos.x, _pos.z)):
		return _pos
	for r in [0.2, 0.4, 0.7, 1.0, 1.5, 2.2, 3.0, 4.5, 6.0]:
		for k in 16:
			var a := TAU * k / 16.0 + _yaw
			var p := _pos + Vector3(cos(a), 0.0, sin(a)) * float(r)
			if not bool(wet.call(p.x, p.z)):
				return p + Vector3(cos(a), 0.0, sin(a)) * (float(S.body_len) * MM * size * 0.6)
	return _pos


## A point in its water within radius of centre (or where it is).
func _water_point(centre: Vector3, radius: float) -> Vector3:
	for tries in 12:
		var a := rng.randf() * TAU
		var t := centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * radius
		if not wet.is_valid() or bool(wet.call(t.x, t.z)):
			return t
	return _pos


## Its coat wet in the water; drying out of it.
func _soak(dt: float) -> void:
	if _in_water:
		soaked = minf(soaked + dt * 2.0, 1.0)
	elif not dead:
		soaked = maxf(soaked - dt / dry_secs * (3.0 if _mode in ["groom", "roll"] else 1.0), 0.0)
	if absf(soaked - _soak_shown) > 0.02 or (soaked == 0.0 and _soak_shown != 0.0):
		_soak_shown = soaked
		for m in _coats:
			m.set_shader_parameter("soak", soaked)


# --- its ways -----------------------------------------------------------------------

func swim(centre: Vector3, radius: float) -> void:
	_mode = "swim"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_sit_to = 0.0
	_lie_to = 0.0


func dive() -> void:
	_mode = "dive"
	_stage = 0
	_st = 0.0
	_sit_to = 0.0
	_lie_to = 0.0


func fish(school_: Node3D) -> void:
	if not is_instance_valid(school_):
		return
	_mode = "fish"
	_school = school_
	_fish_i = -1
	_stage = 0
	_st = 0.0
	_sit_to = 0.0
	_lie_to = 0.0


func catch(prey: Node3D) -> void:
	if not is_instance_valid(prey):
		return
	_mode = "catch"
	_prey = prey
	_prey_s = prey.scale
	_held = false
	_stage = 0
	_st = 0.0
	_sit_to = 0.0
	_lie_to = 0.0


func eat_held(food: Node3D) -> void:
	if not is_instance_valid(food):
		return
	_mode = "eat_held"
	_prey = food
	_prey_s = food.scale
	_held = true
	_stage = 0
	_st = 0.0


## (Its kind's: how it goes about in the water, each new leg of its swim:
## a dive now and then, a roll onto its back.)
func _swim_leg() -> void:
	if rng.randf() < 0.3:
		_under_t = rng.randf_range(3.0, 6.0)


## (Its kind's: whether it eats what it's caught ashore, on the bank.)
func _eats_ashore() -> bool:
	return true


## (Its kind's own modes: true if it's seen to this one.)
func _own_think(_dt: float) -> bool:
	return false


func _think(dt: float) -> void:
	_in_water = wet.is_valid() and bool(wet.call(_pos.x, _pos.z))
	_dive_was = _dive
	_dive = move_toward(_dive, _dive_to if _in_water else 0.0, dt * 0.55)
	_back = move_toward(_back, _back_to if _in_water else 0.0, dt * 0.9)
	_soak(dt)
	if young and size < 0.2:
		super(dt)
		return
	if _own_think(dt):
		return
	match _mode:
		"swim":
			_common(dt)
			_swim(dt)
			return
		"dive":
			_common(dt)
			_dive_about(dt)
			return
		"fish":
			_common(dt)
			_fish(dt)
			return
		"catch":
			_common(dt)
			_catch(dt)
			return
		"eat_held":
			_common(dt)
			_eat_held(dt)
			return
		"ashore":
			_common(dt)
			_ashore(dt)
			return
	super(dt)
	_back_to = 0.0
	if _in_water and _mode == "wander": # (wandering into its water: swimming about it)
		swim(_pos, maxf(_radius, 1.2))


func _common(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	_lick = move_toward(_lick, 0.0, dt * 2.0)
	_sniff = move_toward(_sniff, 0.0, dt * 2.0)
	_ears_to = 0.0
	_jaw_to = 0.0
	_neck_to = Vector2.ZERO
	_look_to = _look_to.lerp(Vector2.ZERO, 1.0 - exp(-1.0 * dt))
	_tail_mode = "carry"
	_lie_to = 0.0
	_sit_to = 0.0
	_pace = -1.0
	_back_to = 0.0
	_spin = move_toward(_spin, 0.0, dt * 2.0) if absf(_spin) < 0.5 else _spin


## (About in its water: each leg of it to a new point, now and then under.)
func _swim(dt: float) -> void:
	if not _in_water:
		_target = _nearest_water()
		_pace = float(S.run) * 0.6
		if _target == _pos:
			wander(_pos, 1.0)
		return
	if _wait <= 0.0 or _pos.distance_to(_target) < 0.15:
		_target = _water_point(_centre, _radius)
		_wait = rng.randf_range(3.0, 7.0)
		_swim_leg()
	_under_t -= dt
	_float_t -= dt
	_dive_to = 0.85 if _under_t > 0.0 else 0.0
	_pace = float(S.swim) * (1.3 if _under_t > 0.0 else 1.0)
	if _float_t > 0.0 and _under_t <= 0.0: # (on its back, paddling slow, or still)
		_back_to = 1.0
		_pace = float(S.swim) * 0.3
	_neck_to = Vector2(0.25 if _under_t <= 0.0 else -0.1, 0.0) # (its head up out of the water)
	if _back_to > 0.5:
		_neck_to = Vector2(-1.0, 0.0) # (on its back: its head raised off the water, looking down along itself)
	if _speed < 0.05 and rng.randf() < dt * 0.4:
		_look_to = Vector2(rng.randf_range(-0.1, 0.2), rng.randf_range(-0.8, 0.8))


## (Under, along the bottom a while, up again a way off.)
func _dive_about(dt: float) -> void:
	if not _in_water:
		_target = _nearest_water()
		_pace = float(S.run) * 0.6
		if _target == _pos:
			wander(_pos, 1.0)
		return
	match _stage:
		0:
			_dive_to = 1.0
			if _st < dt * 1.5 or _pos.distance_to(_target) < 0.2:
				_target = _water_point(_pos, 1.5)
			_pace = float(S.swim) * 1.3
			_neck_to = Vector2(-0.15, 0.0)
			if _st > 6.0:
				_stage = 1
				_st = 0.0
		1:
			_dive_to = 0.0
			_pace = float(S.swim)
			if _dive < 0.05:
				swim(_pos, 1.5)


## (A fish of its school: under after it, chasing it; caught, up with it.)
func _fish(dt: float) -> void:
	if not is_instance_valid(_school):
		swim(_pos, 1.5)
		return
	match _stage:
		0: # (to its water, and in)
			if not _in_water:
				_target = _nearest_water()
				_pace = float(S.run) * 0.7
				if _target == _pos:
					wander(_pos, 1.0)
				return
			_stage = 1
			_st = 0.0
		1: # (under, after the nearest fish)
			if _fish_i < 0 or fmod(_st, 2.0) < dt:
				_fish_i = int(_school.call("nearest", _mouth_local()))
			if _fish_i < 0:
				swim(_pos, 1.5)
				return
			var fp := _fish_at(_fish_i)
			_target = Vector3(fp.x, _pos.y, fp.z)
			_dive_to = clampf((water_y - fp.y) / maxf(water_y - floor_y, 0.05), 0.2, 1.0)
			_pace = float(S.swim) * 1.6
			_ears_to = 1.0
			_neck_to = Vector2(clampf((fp.y - _mouth().y) * 6.0, -0.6, 0.4), 0.0)
			if _st > 7.0: # (wearing it out: it slows, held by the bottom near it)
				_school.call("hold", _fish_i, _school.to_local(get_parent().to_global(_pos + Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * 0.3)))
			var m := _mouth()
			var fw := (_school as Node3D).global_transform * ((_school.get("pos") as PackedVector3Array)[_fish_i])
			if m.distance_to(fw) < 0.16 * size / 0.5 + 0.05 or _st > 12.0:
				var f: Node3D = _school.call("take", _fish_i)
				_fish_i = -1
				if f:
					_prey = f
					_prey_s = f.global_basis.get_scale()
					_held = true
					_stage = 2
					_st = 0.0
				else:
					swim(_pos, 1.5)
		2: # (up with it)
			_dive_to = 0.0
			_pace = float(S.swim) * 0.8
			_neck_to = Vector2(0.3, 0.0)
			if _dive < 0.05:
				_after_catch()


## (Its mouth, in its parent's space.)
func _mouth_local() -> Vector3:
	var par := get_parent() as Node3D
	return par.to_local(_mouth()) if par else _mouth()


## (Fish i of its school, in its parent's space.)
func _fish_at(i: int) -> Vector3:
	var ps: PackedVector3Array = _school.get("pos")
	if i < 0 or i >= ps.size():
		return _pos
	var w := (_school as Node3D).global_transform * ps[i]
	var par := get_parent() as Node3D
	return par.to_local(w) if par else w


## (After anything by its water: under after it if it's under; in its jaws;
## up with it.)
func _catch(dt: float) -> void:
	if not is_instance_valid(_prey):
		_held = false
		if _in_water:
			swim(_pos, 1.5)
		else:
			wander(_pos, 1.0)
		return
	var p := _prey.global_position
	var lp: Vector3 = get_parent().to_local(p) if get_parent() is Node3D else p
	var under := lp.y < water_y - 0.04
	var to := Vector3(lp.x - _pos.x, 0.0, lp.z - _pos.z)
	match _stage:
		0: # (to it: swimming, diving to it if it's under; or along the bank)
			_target = Vector3(lp.x, _pos.y, lp.z) - to.normalized() * absf(float(S.mouth_z)) * MM * size * 0.8
			_pace = float(S.swim) * 1.4 if _in_water else float(S.trot)
			_ears_to = 1.0
			if _in_water and under:
				_dive_to = clampf((water_y - lp.y) / maxf(water_y - floor_y, 0.05), 0.2, 1.0)
			_neck_to = Vector2(clampf((lp.y - _mouth().y) * 6.0, -0.9, 0.4), 0.0)
			var m := _mouth()
			if m.distance_to(p) < 0.1 * size / 0.5 + 0.04 or (to.length() < absf(float(S.mouth_z)) * MM * size * 1.1 and _st > 4.0) or _st > 14.0:
				MealScript.subdue(_prey)
				_held = true
				_stage = 1
				_st = 0.0
		1: # (up with it)
			_dive_to = 0.0
			_neck_to = Vector2(0.3, 0.0)
			if _dive < 0.05 or not _in_water:
				_after_catch()


## (Caught: eaten as its kind eats it.)
func _after_catch() -> void:
	var f := _prey
	_mode = "eat_held"
	_stage = 0
	_st = 0.0
	_prey = f


## (Ashore, then on with its next: to the nearest bank, out.)
var _then := Callable()


func ashore(then: Callable) -> void:
	_mode = "ashore"
	_then = then
	_stage = 0
	_st = 0.0


func _ashore(dt: float) -> void:
	_dive_to = 0.0
	if _in_water:
		if _st <= dt * 1.5 or _pos.distance_to(_target) < 0.1:
			_target = _nearest_bank()
		_pace = float(S.swim)
		_neck_to = Vector2(0.25, 0.0)
		if _st > 25.0:
			_st = 0.0
			_target = _nearest_bank()
		return
	if _then.is_valid():
		var t := _then
		_then = Callable()
		t.call()
	else:
		wander(_pos, 1.0)


## (Eating what it's caught, held in its forepaws, head first, bite by
## bite; its kind ashore, or on its back.)
func _eat_held(dt: float) -> void:
	match _stage:
		0: # (ashore with it, if its kind eats ashore; it in its jaws)
			if not is_instance_valid(_prey):
				wander(_pos, 1.0)
				return
			_held = true
			if _eats_ashore() and _in_water:
				_dive_to = 0.0
				if _st <= dt * 1.5 or _pos.distance_to(_target) < 0.1:
					_target = _nearest_bank()
				_pace = float(S.swim)
				_neck_to = Vector2(0.3, 0.0)
				if _st < 25.0:
					return
			if _eats_ashore() and not _in_water and _st < 25.0 and Vector2(_pos.x - _target.x, _pos.z - _target.z).length() > 0.1:
				_pace = float(S.walk) # (out, and on up the bank a little)
				_neck_to = Vector2(0.3, 0.0)
				return
			_target = _pos
			_food = _prey
			_food_s = _prey_s
			_prey = null
			_held = false
			_food_secs = clampf(PersonalSpace._dims(_food).x / 0.25 * 14.0, 6.0, 30.0) if _food is Node3D else 10.0
			_stage = 1
			_st = 0.0
		1: # (eating: bite, chew, a tug at it; it drawn down as it goes)
			if not is_instance_valid(_food):
				_stage = 2
				return
			_target = _pos
			_eat_pose(dt)
			var k := clampf(_st / _food_secs, 0.0, 1.0)
			_food.scale = _food_s * lerpf(1.0, 0.25, k)
			_chew = 1.0
			_jaw_to = 0.3 * maxf(sin(_st * 7.0), 0.0)
			if _st > _food_secs:
				_food.queue_free()
				_food = null
				_stage = 2
				_st = 0.0
		2:
			_food = null
			groom()


## (Its kind's way of holding its food to eat it: the body's pose.)
func _eat_pose(_dt: float) -> void:
	_lie_to = 1.0
	_neck_to = Vector2(-0.25, 0.0)
	_look_to = Vector2(0.0, 0.0)


# --- its pose ----------------------------------------------------------------------

## (Its mouth in its body's mm, about: where its food's held to it.)
func _mouth_mm() -> Vector3:
	var hk: Array = S.head
	var tip := float(hk[hk.size() - 1][0])
	return _neck.transform * (_head.transform * Vector3(0.0, float(hk[hk.size() - 1][1]) - 20.0, tip + 25.0))


func _pose(dt: float) -> void:
	super(dt)
	var rolled := _in_water or _back > 0.001 or absf(_spin) > 0.001
	if _in_water:
		_swim_pose(dt)
	# (its food held in its forepaws, at its mouth)
	if is_instance_valid(_food) and _mode == "eat_held":
		_hold_food(dt)
	if rolled:
		var e := _back * _back * (3.0 - 2.0 * _back)
		_roll = PI * e + _spin


## Swimming: its forefeet tucked to its chest, its hind feet paddling (by
## turns, slow; together, fast), its body pitching as it dives and rises,
## rippling as it goes; on its back, its forepaws on its chest, its hind
## feet out of the water.
func _swim_pose(dt: float) -> void:
	var fast := clampf(_speed / maxf(float(S.swim), 0.1), 0.0, 1.5)
	_paddle += dt * (2.5 + 5.0 * fast)
	var dd := (_dive - _dive_was) / maxf(dt, 1e-4)
	_pitch = lerpf(_pitch, clampf(-dd * 1.6, -0.75, 0.6) + 0.05 * sin(_paddle) * fast * (1.0 - _back), 1.0 - exp(-4.0 * dt))
	var together := fast > 0.9
	for i in 4:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		if i < 2:
			_pose_foot[i] = Vector3(hp.x * side * 0.75, hp.y - float(L.f) * 0.7, hp.z + float(L.f) * 0.5)
		else:
			var ph := _paddle + (0.0 if together or side > 0.0 else PI)
			_pose_foot[i] = Vector3(hp.x * side * 1.15, hp.y - float(L.f) * 0.75 + float(L.f) * 0.35 * sin(ph), hp.z + float(L.f) * 1.2 + float(L.f) * 0.7 * cos(ph))
	_lift = 0.0
	_crouch = 0.0


## (Its food in its forepaws, at its mouth: there, as it's eaten.)
func _hold_food(_dt: float) -> void:
	var m := _mouth_mm()
	for i: int in [0, 1]:
		var side := 1.0 if i == 1 else -1.0
		_pose_foot[i] = m + Vector3(float(S.body_w) * 0.32 * side, -float(S.body_w) * 0.35, float(S.body_w) * 0.25)
	var jt := _jaw.global_transform
	var b := jt.basis.orthonormalized()
	_food.global_transform = Transform3D(b * Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(_food.scale), _out(m + Vector3(0.0, -float(S.body_w) * 0.3, float(S.body_w) * 0.2)))


func _pose_tail(dt: float) -> void:
	super(dt)
	if not _in_water:
		return
	# (in the water: out behind it, rippling up and down as it swims)
	var fast := clampf(_speed / maxf(float(S.swim), 0.1), 0.0, 1.5)
	var n := _tail.size()
	for k in n:
		var u := float(k) / maxf(n - 1, 1)
		var r: Vector3 = _tail[k].rotation
		var a := (-0.12 if k == 0 else 0.0) + 0.22 * fast * sin(_paddle - float(k) * 0.8) * (0.3 + 0.7 * u) * (1.0 - _back)
		_tail[k].rotation = Vector3(lerpf(r.x, a, 0.7), lerpf(r.y, 0.0, 0.5), 0.0)


# --- steering (pilot.gd) -----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["swim", "dive", "fish", "catch"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"swim":
			swim(args.get("centre", _pos), float(args.get("radius", 1.5)))
		"dive":
			dive()
		"fish":
			if not args.has("school"):
				return false
			fish(args.school)
		"catch":
			if not args.has("prey"):
				return false
			catch(args.prey)
		_:
			return super(name, args)
	return true


func _p_act_done(name: String) -> bool:
	if name in ["swim", "dive", "fish", "catch"]:
		return _mode != name
	return super(name)
