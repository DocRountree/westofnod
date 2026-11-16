class_name SchoolBody
extends "res://scripts/creatures/creature.gd"
## A school of fish as one animal: for FaunaSim (a record: the school; its
## body: this, a FishSchool under it) and its brain, which steer it as
## they'd steer a deer. spec: [kind, variant, how many] (FishSchool's).
## go_to: the school swims there; act "feed" {at}, "flee" {from} (scatter),
## "rise". where(): the school's middle. Its hunters take a fish of it
## (school: the FishSchool itself, what they're told to hunt), not it.

var spec: Array = ["chinook", "ocean", 24]
var school: FishSchool
var young := false
var _lo := Vector3(-8.0, -3.0, -8.0)
var _hi := Vector3(8.0, 0.0, 8.0)
var _mid := Vector3.ZERO
var _mid_t := 0.0
var _goal := Vector3.INF
var _doing := ""
var _t := 0.0


func _init(young_ := false) -> void:
	young = young_


## Its water (its parent's space): the bottom's corner, the surface's.
func set_water(lo: Vector3, hi: Vector3) -> void:
	_lo = lo
	_hi = hi
	if school:
		school.tank_min = lo - position
		school.tank_max = hi - position


func place(at: Vector3, _yaw := 0.0) -> void:
	position = at
	if school == null:
		school = FishSchool.new(String(spec[0]), String(spec[1]), young)
		school.tank_min = _lo - at
		school.tank_max = _hi - at
		add_child(school)
		var deep := clampf((_hi.y - _lo.y) * 0.4, 0.3, 6.0)
		school.setup(int(spec[2]), Vector3(0.0, _hi.y - at.y - deep, 0.0), 1.5)
	_mid = at


func where() -> Vector3:
	return _mid


func tick(dt: float) -> void:
	_t += dt
	if _pilot:
		_pilot.tick(dt)
	_mid_t -= dt
	if _mid_t <= 0.0 and school != null and not school.pos.is_empty(): # (its middle: now and then)
		_mid_t = 0.4
		var s := Vector3.ZERO
		for p in school.pos:
			s += p
		_mid = position + s / school.pos.size()


func _p_here() -> Vector3:
	return _mid


func _p_heading() -> Vector3:
	return Vector3.FORWARD


func _p_steer(point: Vector3, _speed: float) -> void:
	if school and point != _goal:
		_goal = point
		var d := clampf((_hi.y - _lo.y) * 0.4, 0.3, 6.0)
		school.swim_to(Vector3(point.x - position.x, _hi.y - position.y - d, point.z - position.z))


func _p_hold() -> void:
	_goal = Vector3.INF


func _p_mobile() -> bool:
	return school != null


func _p_speed() -> float:
	return float(school.K.cruise) if school else 1.0


func _p_reach() -> float:
	return 2.5


func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["feed", "flee", "rise"])


func _p_act(name: String, args: Dictionary) -> bool:
	if school == null:
		return false
	_doing = name
	_t = 0.0
	match name:
		"feed":
			var at: Vector3 = args.get("at", _mid)
			school.feed(at - position)
		"flee":
			var from: Vector3 = args.get("from", _mid)
			school.scatter(from - position)
		"rise":
			for i in mini(4, school.pos.size()):
				school.rise(randi() % school.pos.size())
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	return _t > (8.0 if name == "feed" else 3.0)
