class_name WildTurkey
extends "res://scripts/creatures/bird.gd" # (by path: found whether or not the editor has seen the class yet)
## A wild turkey (Meleagris gallopavo, the eastern), life size. Bird: how
## it's made and moved. Not yet in the game (tools/creatures/
## ecology_demo.tscn).
##
## The tom (male set): about a metre long, dark, every body feather a band
## of metal (bronze, copper, green, turning with the light) edged black;
## the wings' flight feathers barred black and white, a coppery bar over
## them; the tail brown, finely barred, a black band below its buff tip,
## its coverts tipped chestnut; the head and upper neck bare, warty, red
## and blue, a snood over the bill, a wattle under it, caruncles at the bare
## neck's foot; a beard of black bristles from the breast; pink red legs,
## spurred. The hen: four fifths his size, duller, her feathers edged buff,
## her head greyer, feathered higher up her neck; no beard, no spurs. The
## poult (young_): a downy chick, buff, striped dark over its crown and
## back.
##
## Its ways (each a call; of its own accord it forages):
## - forage(centre, radius): walking slowly, its head bobbing, stopping to
##   look, pecking at the ground, scratching the litter back with a foot
##   and pecking where it scratched
## - eat(at): to a point and pecking there (then: a Callable, once it's
##   pecked, for what it's eaten)
## - strut() (a tom's display): tail raised and fanned, wings let down,
##   their tips dragging, every feather up, head drawn back onto its
##   shoulders, the snood let down long over the bill, the head's colours
##   up (white crown, blue face, scarlet wattles); slow steps, turning
##   itself broadside to the nearest hen; now and then a quiver and a quick
##   few steps (the "spit and drum")
## - gobble(): neck thrown out and up, bill open, wattles shaking
## - alert(): head up tall, still; flee(from): running, neck low; flush(from):
##   up and away on a burst of wings, a glide, a landing at a run
## - fly(to)
## - sit(), sleep() (sat, its head turned back under its shoulder feathers),
##   preen() (bill through wing, breast), dust() (down in the dust,
##   rolling, wings flicking it over itself, then up and a shake)
## - mate(hen) (a tom's): strutting to her; she crouches; he steps up onto
##   her back, treading, wings out for his balance; then off; she's
##   carrying eggs
## - lay() (a hen's): to a place close by, a scrape scratched in the
##   litter, sat in, an egg laid at a time (a dozen: clutch); then sat on
##   (incubating). hatch(): the eggs open, a poult from each, hers
## - a hen with poults (young_ones): leading them as she forages; brood():
##   sat, her wings a little out, the poults in under her
## - a poult: follows its mother (_mother), pecking as she does, running
##   to catch up; play(): chasing, hopping with a flutter of its wings;
##   growing (grow_secs: its down giving way to feathers)
## - die(): down on its side, still.
## Steering (pilot.gd): act eat {at}, strut, gobble, sit, sleep, preen,
## dust, flee {from}, fly {at}, lay, mate {partner}.

const CLUTCH := 11
const NEAR_HEN := 6.0
const BUSY_HEN := ["nest", "incubate", "brood", "dead", "fly"]

var young_ones: Array = [] ## her poults
var clutch_eggs: Array[Node3D] = [] ## her eggs (in nest)
var nest: Node3D
var gravid := false
var grow_secs := 240.0 ## s a poult takes to feather out

var _mode := "forage"
var _sub := ""
var _mt := 0.0 # (s in this mode)
var _st := 0.0 # (s in this part of it)
var _n := 0
var _centre := Vector3.INF
var _roam := 3.0
var _at := Vector3.ZERO
var _then := Callable()
var _mother: Node3D
var _partner: Node3D
var _secs := -1.0
var _gobble := 0.0
var _threat := Vector3.ZERO
var _age := 0.0
var _foot := 0
var _mate_secs := 7.0


func _init(young_ := false) -> void:
	super()
	young = young_
	shape = _tom()
	want.tail_up = -0.3
	cur.tail_up = -0.3


func _build() -> void:
	if young:
		shape = _poult()
		size = 0.15
		mass = 0.06
		span = 0.12
		wing_area = 0.004
		walk_speed = 0.35
		run_speed = 1.6
		colors["down"] = 1.0
		colors["bare_from"] = 2.0
		colors["feather_cm"] = 9.0
		colors["down_color"] = Color(0.8, 0.64, 0.4)
		colors["down_dark"] = Color(0.24, 0.15, 0.08)
		colors["bill_color"] = Color(0.55, 0.42, 0.3)
	else:
		shape = _tom()
		if not male:
			size = 0.8
			shape.erase("beard")
			shape.erase("spur")
			shape["snood_r"] = 0.55
			shape["wattle"] = [Vector3(0.0, 93.6, -37.4), Vector3(0.4, 2.6, 1.4)]
			shape["caruncles"] = [[3.0, 0.3, 0.6], [3.0, -0.3, 0.6], [3.2, 0.0, 0.5]]
			colors["hen"] = 1.0
			colors["bare_from"] = 0.6
			colors["tip_color"] = Color(0.5, 0.4, 0.27)
			colors["green"] = Color(0.24, 0.2, 0.11)
			colors["bronze"] = Color(0.3, 0.2, 0.11)
			colors["copper"] = Color(0.36, 0.2, 0.1)
		mass = 7.5 if male else 4.2
		span = 1.4 if male else 1.2
		wing_area = 0.42 if male else 0.3
		walk_speed = 0.8
		run_speed = 5.5
	super()
	_plant_feet()


static func _tom() -> Dictionary:
	return {
		"spine": [[55.0, 33.0, 1.5, 1.5, 0.0], [56.0, 26.0, 9.0, 8.0, 0.0], [57.0, 15.0, 15.0, 14.5, 0.0], [56.0, 3.0, 18.0, 18.0, 0.0],
				[55.5, -9.0, 18.5, 19.0, 0.0], [57.0, -20.0, 16.5, 18.0, 0.0], [62.5, -28.0, 12.5, 14.0, 0.1], [69.0, -31.5, 8.0, 9.0, 0.5],
				[75.5, -31.8, 5.2, 5.8, 1.2], [82.0, -29.8, 3.6, 4.1, 2.0], [88.0, -28.6, 2.8, 3.2, 2.8], [93.2, -29.8, 2.4, 2.8, 3.6],
				[96.8, -33.2, 2.3, 2.8, 4.5], [98.3, -36.6, 2.25, 2.7, 4.8], [98.1, -39.6, 1.95, 2.3, 5.0], [97.3, -41.7, 1.45, 1.6, 5.05],
				[96.2, -43.7, 0.95, 0.9, 5.5], [94.6, -45.2, 0.2, 0.2, 6.0]],
		"pivot": Vector3(0.0, 52.0, 5.0),
		"jaw": Vector3(0.0, 96.5, -40.5),
		"lower_bill": [[96.3, -40.8, 1.1], [95.8, -42.5, 0.72], [95.3, -44.0, 0.18]],
		"eye": Vector3(1.85, 98.7, -38.4), "eye_r": 0.68,
		"snood": Vector3(0.0, 99.7, -40.6),
		"wattle": [Vector3(0.0, 91.3, -36.6), Vector3(0.65, 5.4, 2.3)],
		"caruncles": [[2.1, 0.3, 1.25], [2.1, -0.3, 1.25], [2.3, 0.0, 1.1], [2.35, 0.8, 0.9], [2.35, -0.8, 0.9], [2.6, 0.3, 0.75], [2.6, -0.3, 0.75], [2.9, 0.0, 0.55]],
		"beard": [Vector3(0.0, 53.0, -37.5), 22.0],
		"hip": Vector3(8.5, 50.0, 6.0), "knee": Vector3(9.5, 41.0, -3.0), "ankle": Vector3(9.0, 19.0, 5.5), "foot": Vector3(9.0, 2.2, 1.5),
		"thigh_r": [8.5, 5.5], "leg_r": 1.3, "toes": [9.5, 7.0, 3.0], "spur": 2.8,
		"tail": Vector3(0.0, 56.0, 31.0),
		"shoulder": Vector3(18.5, 64.0, -14.0), "wing": Vector3(15.0, 16.0, 12.0), "coverts": [12.0, 13.0, 12.0, 6.0],
		"primaries": [24.0, 27.0, 29.0, 31.0, 32.0, 32.0, 31.0, 29.0, 26.0, 22.0], "secondaries": [16, 28.0, 22.0], "feather_w": 6.0,
		"tail_feathers": [18, 40.0, 9.0], "tail_coverts": [[14, 24.0, 7.5, 1.4, 0.93], [11, 15.0, 7.0, 2.6, 0.82]],
	}


## (A poult: drawn at the grown bird's scale, made small: size.)
static func _poult() -> Dictionary:
	return {
		"spine": [[50.0, 22.0, 1.0, 1.0, 0.0], [51.0, 16.0, 9.0, 8.0, 0.0], [52.0, 6.0, 14.0, 14.0, 0.0], [52.0, -5.0, 14.5, 15.0, 0.0],
				[55.0, -13.0, 12.0, 13.0, 0.1], [62.0, -17.0, 8.5, 9.0, 0.5], [68.0, -18.5, 7.0, 7.2, 1.5], [73.0, -19.0, 6.6, 6.8, 2.5],
				[78.0, -20.0, 6.6, 6.8, 3.5], [83.0, -22.0, 7.0, 7.5, 4.5], [85.0, -27.0, 6.8, 7.0, 5.0], [84.6, -30.6, 3.0, 2.6, 5.05],
				[83.6, -32.4, 1.6, 1.2, 5.5], [82.6, -33.8, 0.3, 0.2, 6.0]],
		"pivot": Vector3(0.0, 48.0, 3.0),
		"jaw": Vector3(0.0, 82.6, -30.3),
		"lower_bill": [[82.4, -30.5, 1.6], [82.1, -32.0, 1.0], [81.9, -33.1, 0.2]],
		"eye": Vector3(6.0, 86.0, -27.5), "eye_r": 1.7,
		"hip": Vector3(7.5, 44.0, 4.0), "knee": Vector3(8.5, 36.0, -3.0), "ankle": Vector3(8.0, 17.0, 5.0), "foot": Vector3(8.0, 2.5, 1.5),
		"thigh_r": [7.0, 4.5], "leg_r": 1.9, "toes": [11.0, 8.0, 3.0],
		"tail": Vector3(0.0, 50.0, 21.0),
		"shoulder": Vector3(13.5, 58.0, -8.0), "wing": Vector3(8.0, 8.0, 6.0), "coverts": [7.0, 7.0, 6.0, 3.0], "wing_thick": [3.0, 2.4, 1.6, 0.8],
		"primaries": [8.0, 9.0, 10.0, 10.0, 9.0, 8.0, 7.0], "secondaries": [6, 9.0, 8.0], "tertials": [0, 1.0, 1.0], "feather_w": 3.5,
		"tail_feathers": [6, 6.0, 3.0],
	}


func place(at: Vector3, yaw := 0.0) -> void:
	super(at, yaw)
	if _centre == Vector3.INF:
		_centre = _pos


# --- its ways ---------------------------------------------------------------------

func _to(mode: String, sub := "") -> void:
	if dead:
		return
	if _mode == "strut" and mode != "strut":
		_unstrut()
	_mode = mode
	_sub = sub
	_mt = 0.0
	_st = 0.0
	_n = 0
	head_point = Vector3.INF
	look_yaw = 0.0
	foot_off[0] = Vector3.ZERO
	foot_off[1] = Vector3.ZERO
	lift_y = 0.0
	want.pitch = 0.0
	want.crouch = 0.0
	want.drop = 0.0
	want.roll = 0.0
	want.jaw = 0.0
	want.head_pitch = 0.0
	want.eye_shut = 0.0
	head_want = Vector3.ZERO
	head_rate = 6.0
	if not _air:
		fold_wings()
		want.tail_up = -0.3
		want.tail_spread = 0.0


func forage(centre := Vector3.INF, radius := -1.0) -> void:
	if centre != Vector3.INF:
		_centre = centre
	if radius > 0.0:
		_roam = radius
	_piloted = false
	_to("forage", "look")


## (As the others': its own ways again.)
func wander(centre := Vector3.INF, radius := -1.0) -> void:
	forage(centre, radius)


func graze(centre := Vector3.INF, radius := -1.0) -> void:
	forage(centre, radius)


func eat(at: Vector3, then := Callable()) -> void:
	_to("eat", "go")
	_at = at
	_then = then
	walk_to(at - (at - _pos).normalized() * 0.4 * size, walk_speed * 1.6)


func strut(secs := -1.0) -> void:
	if not male or young:
		return
	_to("strut")
	_secs = secs


func gobble() -> void:
	if male and not young and not dead:
		_gobble = 1.2


func alert(secs := 4.0) -> void:
	_to("alert")
	_secs = secs
	halt()


func flee(from: Vector3) -> void:
	if _air:
		return
	_to("flee")
	_threat = from
	var away := _pos - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else _fwd()
	walk_to(_pos + away.rotated(Vector3.UP, rng.randf_range(-0.4, 0.4)) * rng.randf_range(7.0, 10.0), run_speed)
	_alarm_young(from)


func flush(from: Vector3) -> void:
	if young and size < 0.3:
		flee(from)
		return
	var away := _pos - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else _fwd()
	fly(_pos + away.rotated(Vector3.UP, rng.randf_range(-0.3, 0.3)) * rng.randf_range(14.0, 20.0))
	_alarm_young(from)


func _alarm_young(from: Vector3) -> void:
	for y in young_ones:
		if is_instance_valid(y) and y.get("_mode") != "flee":
			y.call("flee", from)


func fly(to: Vector3) -> void:
	if dead or (young and size < 0.3):
		return
	_to("fly")
	fly_to(to)


func sit(secs := -1.0) -> void:
	_to("sit")
	_secs = secs
	halt()


func sleep() -> void:
	_to("sleep")
	halt()


func preen(secs := 10.0) -> void:
	_to("preen")
	_secs = secs
	halt()


func dust(secs := 12.0) -> void:
	_to("dust")
	_secs = secs
	halt()


## (A tom's.) Courting hen, mounting her: false if they can't.
func mate(hen: Node3D, secs := -1.0) -> bool:
	if not male or young or dead or hen == null or not is_instance_valid(hen) or hen == self or hen.get("male") or hen.get("young") or hen.get("dead"):
		return false
	if hen.get("_mode") in BUSY_HEN or hen.get("gravid"): # (laying, sitting, brooding, or carrying eggs already)
		return false
	_to("strut")
	_secs = -1.0
	_partner = hen
	_sub = "court"
	_mate_secs = secs if secs > 0.0 else 7.0
	return true


func is_mating() -> bool:
	return _partner != null and is_instance_valid(_partner) and (_mode == "mount" or (_mode == "strut" and _sub == "court") or _mode == "crouch")


## (A hen's.) Her nest scraped close by, her eggs laid in it, then sat on.
func lay() -> void:
	if male or young or dead or _mode in ["nest", "incubate"]:
		return
	if nest == null or not is_instance_valid(nest):
		var a := rng.randf() * TAU
		var at := _pos + Vector3(cos(a), 0.0, sin(a)) * 1.2
		at.y = _ground(at.x, at.z)
		nest = _make_nest()
		get_parent().add_child(nest)
		nest.position = at
	_to("nest", "go")
	walk_to(nest.position, walk_speed)


## Her eggs opening: a poult from each, hers to lead.
func hatch() -> void:
	if clutch_eggs.is_empty():
		return
	var par := get_parent()
	for e in clutch_eggs:
		if not is_instance_valid(e):
			continue
		var p: WildTurkey = (get_script() as GDScript).new(true)
		p.height = height
		p.ground_y = ground_y
		par.add_child(p)
		var at: Vector3 = nest.position + Vector3(rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.12, 0.12))
		p.place(at, rng.randf() * TAU)
		p.follow(self)
		young_ones.append(p)
		# (its shell left, broken open)
		e.scale = Vector3(1.0, 0.45, 1.0)
		e.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))
	clutch_eggs.clear()
	forage(nest.position, 2.5)


func brood(secs := 20.0) -> void:
	if male or young:
		return
	_to("brood")
	_secs = secs
	halt()
	for y in young_ones:
		if is_instance_valid(y):
			y.call("_to", "under")


func follow(hen: Node3D) -> void:
	_mother = hen
	_to("follow")


func play(secs := 15.0) -> void:
	if not young:
		return
	_to("play")
	_secs = secs


func die() -> void:
	if dead:
		return
	_to("dead")
	dead = true
	_air = false
	_flap = 0.0
	halt()
	_speed = 0.0
	want.roll = 1.45
	want.drop = 0.36
	want.eye_shut = 1.0
	want.tail_spread = 0.35
	want.tail_up = -0.1
	want.legs_tuck = 0.15
	want.wl_up = -1.45
	want.wl_spread = 0.25
	want.wr_up = -1.6
	want.wr_spread = 0.1
	want.jaw = 0.12
	head_want = Vector3(0.22, -0.34, -0.12)
	head_rate = 3.0
	for k: String in ["roll", "drop"]:
		rate[k] = 4.0


func _unstrut() -> void:
	for k: String in ["tail_arch", "puff", "flush", "snood", "droop"]:
		want[k] = 0.0


func _think(dt: float) -> void:
	_mt += dt
	_st += dt
	want.sway = 0.35 * sin(_t * 2.3) * clampf(_speed, 0.0, 1.0) + (0.9 * sin(_t * 38.0) if _gobble > 0.2 and _gobble < 0.9 else 0.0)
	rate["sway"] = 20.0
	if young:
		_grow(dt)
	if _air:
		return
	if _piloted and _mode in ["forage", "follow"]:
		if not is_busy() and arrived():
			pass
		return
	match _mode:
		"forage":
			_forage(dt)
		"eat":
			_eat(dt)
		"strut":
			_strut(dt)
		"alert":
			want.pitch = -0.2
			head_want = Vector3(0.0, 0.07, 0.04)
			look_yaw = 0.7 * sin(_mt * 1.9) * (1.0 if fmod(_mt, 2.0) < 1.2 else 0.3)
			if _secs > 0.0 and _mt > _secs:
				forage()
		"flee":
			head_want = Vector3(0.0, -0.16, -0.12)
			want.pitch = 0.15
			if arrived():
				alert(3.0)
		"fly":
			if not _air:
				alert(2.5)
		"sit", "sleep", "brood", "incubate":
			_sit(dt)
		"preen":
			_preen(dt)
		"dust":
			_dust(dt)
		"crouch":
			want.drop = 0.3
			want.pitch = 0.1
			head_want = Vector3(0.0, -0.28, -0.1)
			set_wings(-1.25, 0.1, 0.1, 0.12)
			if _partner == null or not is_instance_valid(_partner) or _partner.get("_partner") != self:
				_partner = null
				forage()
		"mount":
			_mount(dt)
		"nest":
			_nest(dt)
		"follow":
			_follow(dt)
		"under":
			_under(dt)
		"play":
			_play(dt)
	if _gobble > 0.0:
		_gobble -= dt
		var g := 1.2 - _gobble
		if g < 0.95: # (neck thrown out and up, bill open, a shake)
			head_want = Vector3(0.0, 0.02, -0.2)
			head_rate = 16.0
			want.head_pitch = -0.35
			want.jaw = 0.45
			rate["jaw"] = 20.0
			rate["head_pitch"] = 16.0
		else:
			want.jaw = 0.0
			want.head_pitch = 0.0
			head_rate = 6.0


# foraging: a few steps, a look about, pecks, a scratch
func _forage(dt: float) -> void:
	match _sub:
		"go":
			head_want = Vector3(0.0, -0.1, -0.03)
			if arrived() or _st > 12.0:
				_sub = ["look", "peck", "peck", "scratch"][rng.randi() % 4]
				_st = 0.0
				_n = rng.randi_range(2, 5)
		"look":
			head_want = Vector3(0.0, 0.02, 0.0)
			look_yaw = 0.6 * sin(_mt * 1.3)
			if _st > rng.randf_range(1.0, 2.6):
				_wander_on()
		"peck":
			if _peck(dt, _pos + _fwd() * 0.42 * size + _right() * 0.1 * size * sin(_n * 2.1)):
				_n -= 1
				if _n <= 0:
					_end_peck()
					_wander_on()
		"scratch":
			# one foot raked back through the litter, twice; then a step back and a peck
			want.pitch = 0.3
			head_want = Vector3(0.0, -0.3, -0.12)
			var ph := fmod(_st, 0.5) / 0.5
			foot_off[_foot] = Vector3(0.0, 0.05 * sin(PI * ph), lerpf(-0.1, 0.16, smoothstep(0.15, 0.6, ph)) if ph < 0.75 else lerpf(0.16, -0.1, (ph - 0.75) * 4.0))
			if _st > 1.5:
				foot_off[_foot] = Vector3.ZERO
				_foot = 1 - _foot
				_sub = "peck"
				_st = 0.0
				_n = rng.randi_range(2, 4)


func _wander_on() -> void:
	_sub = "go"
	_st = 0.0
	look_yaw = 0.0
	var lead: Vector3 = _centre
	if not young_ones.is_empty():
		_roam = maxf(_roam, 2.0)
	var a := rng.randf() * TAU
	var to := lead + Vector3(cos(a), 0.0, sin(a)) * _roam * sqrt(rng.randf())
	if to.distance_to(_pos) > 2.5:
		to = _pos + (to - _pos).normalized() * 2.5
	walk_to(to, walk_speed * rng.randf_range(0.5, 0.9))


## One peck at `at` (the world): true when its bill's back up.
func _peck(_dt: float, at: Vector3) -> bool:
	at.y = _ground(at.x, at.z) + 0.005
	var ph := _st / 0.55
	want.pitch = 0.78
	want.crouch = 0.35
	rate["pitch"] = 9.0
	head_rate = 18.0
	if ph < 0.45:
		head_point = at
		want.head_pitch = 0.9
		want.jaw = 0.25 if ph < 0.3 else 0.0
	else:
		head_point = at + Vector3(0.0, 0.1 * size, 0.0)
		want.head_pitch = 0.6
	rate["head_pitch"] = 16.0
	rate["jaw"] = 25.0
	if ph >= 1.0:
		_st = 0.0
		return true
	return false


func _end_peck() -> void:
	head_point = Vector3.INF
	want.pitch = 0.0
	want.crouch = 0.0
	want.head_pitch = 0.0
	want.jaw = 0.0
	head_rate = 6.0


func _eat(dt: float) -> void:
	if _sub == "go":
		head_want = Vector3(0.0, -0.1, -0.03)
		if arrived() or _st > 15.0:
			_sub = "peck"
			_st = 0.0
			_n = 5
			turn_to(_at - _pos)
	elif _peck(dt, _at):
		_n -= 1
		if _n == 4 and _then.is_valid():
			_then.call()
			_then = Callable()
		if _n <= 0:
			_end_peck()
			forage()


# the strut: all its feathers up, tail fanned, wings dragging; slow steps,
# broadside to a hen; now and then the quiver and a quick few steps
func _strut(dt: float) -> void:
	want.tail_up = 1.5
	want.tail_spread = 1.62
	want.tail_arch = 0.22
	want.puff = 1.0
	want.flush = 1.0
	want.snood = 1.0
	want.droop = 1.0
	want.pitch = -0.1
	want.head_pitch = 0.3
	head_want = Vector3(0.0, -0.07, 0.11)
	set_wings(-1.3, 0.12, 0.2, 0.25)
	for k: String in ["tail_up", "tail_spread", "puff", "flush", "snood", "droop"]:
		rate[k] = 3.0
	var hen := _partner if _partner != null and is_instance_valid(_partner) else _nearest_hen()
	if _sub == "court" and (hen == null or hen.get("_mode") in BUSY_HEN):
		_sub = ""
		_partner = null
	# the drum: a shiver through its wings and its fan, then on
	var drum := fmod(_mt, 7.0)
	if drum > 6.2:
		var q := sin(_t * 55.0)
		want.droop = 1.0 + 0.25 * q
		rate["droop"] = 40.0
		want.tail_yaw = 0.05 * q
		rate["tail_yaw"] = 40.0
		want.puff = 1.15
	else:
		want.tail_yaw = 0.07 * sin(_mt * 0.5)
		rate["tail_yaw"] = 2.0
	if _sub == "court":
		var d := Vector2(hen.position.x - _pos.x, hen.position.z - _pos.z).length()
		if d > 1.3 * size:
			if arrived() or _st > 2.0:
				_st = 0.0
				walk_to(hen.position, 0.45)
		else:
			# (she crouches for him; then up onto her back)
			halt()
			if hen.get("_mode") != "crouch":
				hen.call("_to", "crouch")
				hen.set("_partner", self)
				hen.call("halt")
			if _st > 3.0:
				_to("mount")
				_partner = hen
		return
	if arrived() and _st > 1.5:
		_st = 0.0
		var to := _pos + Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized() * rng.randf_range(0.4, 0.9)
		if hen != null:
			# (round her, keeping its side and its fan to her)
			var off := _pos - hen.position
			off.y = 0.0
			var r := clampf(off.length(), 1.6, 3.0)
			to = hen.position + off.normalized().rotated(Vector3.UP, 0.5) * r
		walk_to(to, 0.3 if drum < 6.2 else 0.9)
	if rng.randf() < dt * 0.06:
		gobble()
	if _secs > 0.0 and _mt > _secs:
		forage()


func _nearest_hen() -> Node3D:
	var best: Node3D = null
	var par := get_parent()
	if par == null:
		return null
	for o in par.get_children():
		if o is WildTurkey and o != self and not o.male and not o.young and not o.dead:
			var d: float = (o as Node3D).position.distance_to(_pos)
			if d < NEAR_HEN and (best == null or d < best.position.distance_to(_pos)):
				best = o
	return best


func _mount(dt: float) -> void:
	var hen := _partner
	if hen == null or not is_instance_valid(hen):
		forage()
		return
	var back := 0.4 * float(hen.get("size"))
	_pos = _pos.lerp(Vector3(hen.position.x, _pos.y, hen.position.z), 1.0 - exp(-4.0 * dt))
	_yaw = lerp_angle(_yaw, hen.rotation.y, 1.0 - exp(-4.0 * dt))
	lift_y = move_toward(lift_y, back, dt * 0.8)
	for i in 2:
		_feet[i] = _pos + _right() * (-0.07 if i == 0 else 0.07) + Vector3(0.0, lift_y, 0.0)
		foot_off[i] = Vector3(0.0, maxf(0.0, 0.035 * sin(_mt * 9.0 + i * PI)), 0.0)
	want.crouch = 0.6
	want.tail_up = -0.7
	want.tail_spread = 0.5
	want.puff = 0.3
	want.droop = 0.0
	want.pitch = 0.1
	head_want = Vector3(0.0, -0.1, -0.05)
	set_wings(-0.55 + 0.12 * sin(_mt * 7.0), 0.2, 0.2, 0.4)
	if _mt > _mate_secs:
		hen.set("gravid", true)
		hen.set("_partner", null)
		hen.call("forage")
		_partner = null
		lift_y = 0.0
		_pos += _fwd() * 0.5
		_plant_feet()
		forage()


func _sit(_dt: float) -> void:
	want.drop = 0.345
	rate["drop"] = 3.0
	want.pitch = 0.05
	match _mode:
		"sleep":
			look_yaw = 2.5
			head_want = Vector3(0.1, -0.2, 0.26)
			want.head_pitch = 0.5
			want.eye_shut = 1.0
			want.puff = 0.4
		"brood":
			set_wings(-1.1, 0.1, 0.1, 0.18)
			want.puff = 0.5
			head_want = Vector3(0.0, -0.12, 0.04)
			look_yaw = 0.5 * sin(_mt * 0.7)
		"incubate":
			head_want = Vector3(0.0, -0.2, 0.06)
			look_yaw = 0.4 * sin(_mt * 0.4)
			want.puff = 0.3
		_:
			head_want = Vector3(0.0, -0.1, 0.04)
			look_yaw = 0.5 * sin(_mt * 0.8)
	if _secs > 0.0 and _mt > _secs and _mode in ["sit", "brood"]:
		if _mode == "brood":
			for y in young_ones:
				if is_instance_valid(y):
					y.call("follow", self)
		want.puff = 0.0
		forage()


func _preen(_dt: float) -> void:
	# its bill drawn through its wing's feathers, one side, then its breast, then the other
	var k := int(_mt / 2.6) % 3
	var nib := 0.012 * sin(_mt * 16.0)
	want.puff = 0.35
	head_rate = 7.0
	if k == 1:
		head_want = Vector3(0.0, -0.3 + nib, 0.07)
		want.head_pitch = 1.2
		look_yaw = 0.0
	else:
		var s := -1.0 if k == 0 else 1.0
		look_yaw = -s * 2.3
		head_want = Vector3(s * 0.15, -0.2 + nib, 0.3)
		want.head_pitch = 0.5
		want["w%s_spread" % ("l" if s < 0.0 else "r")] = 0.12
	want.jaw = 0.1 + 0.1 * sin(_mt * 16.0)
	rate["jaw"] = 30.0
	if _mt > _secs:
		want.puff = 0.0
		forage()


func _dust(_dt: float) -> void:
	# down in the dust, rolling side to side, its wings flicking it up over itself
	want.drop = 0.35
	want.puff = 0.8
	want.roll = 0.4 * sin(_mt * 1.7)
	rate["roll"] = 5.0
	var flick := maxf(0.0, sin(_mt * 6.0))
	want.wl_up = -1.1 + 0.5 * flick * maxf(0.0, sin(_mt * 1.7))
	want.wr_up = -1.1 + 0.5 * flick * maxf(0.0, -sin(_mt * 1.7))
	want.wl_spread = 0.25
	want.wr_spread = 0.25
	for k: String in ["wl_up", "wr_up"]:
		rate[k] = 25.0
	head_want = Vector3(0.1 * sin(_mt * 1.7), -0.22, 0.02)
	foot_off[0] = Vector3(0.0, 0.0, 0.08 * sin(_mt * 5.0))
	if _mt > _secs:
		want.puff = 0.0
		alert(1.5)


func _nest(dt: float) -> void:
	match _sub:
		"go":
			if arrived() or _st > 10.0:
				_pos = Vector3(nest.position.x, _pos.y, nest.position.z)
				_plant_feet()
				_sub = "scrape"
				_st = 0.0
		"scrape":
			want.pitch = 0.25
			var ph := fmod(_st, 0.5) / 0.5
			foot_off[_foot] = Vector3(0.0, 0.04 * sin(PI * ph), lerpf(-0.08, 0.14, ph))
			_yaw += 0.5 * dt
			if _st > 3.0:
				foot_off[_foot] = Vector3.ZERO
				_plant_feet()
				_sub = "lay"
				_st = 0.0
				_n = CLUTCH - clutch_eggs.size()
		"lay":
			want.drop = 0.3
			want.pitch = -0.12
			want.tail_up = 0.25
			head_want = Vector3(0.0, -0.14, 0.03)
			if _st > 2.2:
				_st = 0.0
				if _n > 0:
					_n -= 1
					var e := _make_egg()
					nest.add_child(e)
					var k := clutch_eggs.size()
					var a := k * 2.4
					var r := 0.035 * sqrt(float(k))
					e.position = Vector3(cos(a) * r, 0.022, sin(a) * r)
					e.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, PI * 0.5 + rng.randf_range(-0.3, 0.3))
					clutch_eggs.append(e)
				else:
					gravid = false
					_to("incubate")


func _follow(_dt: float) -> void:
	var hen := _mother
	if hen == null or not is_instance_valid(hen) or hen.get("dead"):
		_mother = null
		forage(_pos, 1.0)
		return
	var d := Vector2(hen.position.x - _pos.x, hen.position.z - _pos.z).length()
	if d > 0.75 or (arrived() and _st > rng.randf_range(1.5, 4.0)):
		if arrived() or d > 1.2:
			_end_peck()
			_sub = "go"
			_st = 0.0
			var a := rng.randf() * TAU
			walk_to(hen.position + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.25, 0.5), walk_speed * (1.0 if d < 1.0 else 3.5))
	elif arrived():
		if _sub != "peck":
			_sub = "peck"
			_st = 0.0
			_n = 3
		if _peck(_dt, _pos + _fwd() * 0.42 * size):
			_n -= 1
			if _n <= 0:
				_end_peck()
				_sub = ""


func _under(_dt: float) -> void:
	var hen := _mother
	if hen == null or not is_instance_valid(hen):
		forage(_pos, 1.0)
		return
	if _sub == "":
		_sub = "go"
		var a := rng.randf() * TAU
		walk_to(hen.position + Vector3(cos(a), 0.0, sin(a)) * 0.13, walk_speed * 2.5)
	elif arrived():
		want.drop = 0.25
		head_want = Vector3(0.0, -0.08, 0.02)


func _play(dt: float) -> void:
	# chasing about, hopping with a flutter of its wings
	if arrived() or _st > 2.0:
		_st = 0.0
		var a := rng.randf() * TAU
		var c: Vector3 = _mother.position if _mother != null and is_instance_valid(_mother) else _centre
		walk_to(c + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.4, 1.2), run_speed * 0.8)
	var hop := fmod(_mt, 1.3)
	if hop < 0.35:
		lift_y = 0.5 * size * sin(PI * hop / 0.35)
		_flap = 1.0
		_phase += TAU * 14.0 * dt
	else:
		lift_y = 0.0
		_flap = 0.0
	if _mt > _secs:
		lift_y = 0.0
		_flap = 0.0
		if _mother != null and is_instance_valid(_mother):
			follow(_mother)
		else:
			forage()


func _grow(dt: float) -> void:
	_age += dt
	var g := clampf(_age / grow_secs, 0.0, 1.0)
	size = lerpf(0.15, 0.42, g)
	walk_speed = lerpf(0.35, 0.7, g)
	run_speed = lerpf(1.6, 4.0, g)
	if _mat:
		_mat.set_shader_parameter("down", 1.0 - smoothstep(0.35, 0.9, g))


func _landed() -> void:
	if _mode == "fly":
		alert(2.5)


# --- the nest, the eggs -----------------------------------------------------------

func _make_nest() -> Node3D:
	var n := Node3D.new()
	n.set_meta("prop", true)
	var mi := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# a shallow scrape, a rim of dead leaves round it
	for i in 24:
		var a0 := TAU * i / 24.0
		var a1 := TAU * (i + 1) / 24.0
		var prof := [[0.0, -0.004], [0.1, 0.0], [0.17, 0.022], [0.23, 0.012], [0.27, 0.0]]
		for k in prof.size() - 1:
			for q: Array in [[a0, k], [a1, k], [a1, k + 1], [a0, k], [a1, k + 1], [a0, k + 1]]:
				var pr: Array = prof[q[1]]
				var wob := 1.0 + 0.12 * sin(float(q[0]) * 5.0 + float(q[1]))
				st.set_normal(Vector3.UP)
				st.set_color(Color(0.3, 0.2, 0.11).lerp(Color(0.45, 0.33, 0.18), 0.5 + 0.5 * sin(float(q[0]) * 9.0 + float(q[1]) * 2.0)))
				st.add_vertex(Vector3(cos(q[0]) * float(pr[0]) * wob, float(pr[1]) + 0.003, sin(q[0]) * float(pr[0]) * wob))
	st.generate_normals()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	n.add_child(mi)
	return n


static var _egg_mat: ShaderMaterial


## An egg: 6 cm, cream, speckled brown.
func _make_egg() -> Node3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.0225
	sm.height = 0.063
	sm.radial_segments = 14
	sm.rings = 8
	mi.mesh = sm
	if _egg_mat == null:
		var sh := Shader.new()
		sh.code = """shader_type spatial;
varying vec3 p;
float hash(vec3 q) { return fract(sin(dot(q, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
void vertex() { p = VERTEX; VERTEX.xz *= 1.0 - 0.18 * smoothstep(0.0, 0.0315, VERTEX.y); }
void fragment() {
	vec3 c = vec3(0.86, 0.8, 0.66);
	vec3 q = p * 700.0;
	float s = 0.0;
	for (int i = 0; i < 2; i++) {
		vec3 g = floor(q);
		float d = length(fract(q) - 0.5 - 0.3 * (vec3(hash(g), hash(g + 3.1), hash(g + 7.7)) - 0.5));
		s = max(s, (1.0 - smoothstep(0.08, 0.22, d)) * step(0.45, hash(g + 1.3)));
		q *= 0.55;
	}
	ALBEDO = mix(c, vec3(0.42, 0.26, 0.14), s * 0.8);
	ROUGHNESS = 0.6;
}"""
		_egg_mat = ShaderMaterial.new()
		_egg_mat.shader = sh
	mi.material_override = _egg_mat
	return mi


# --- steering (pilot.gd) ----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["eat", "strut", "gobble", "sit", "sleep", "preen", "dust", "flee", "fly", "lay"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"eat":
			eat(args.get("at", _pos + _fwd() * 0.5))
		"strut":
			if not male or young:
				return false
			strut(float(args.get("seconds", 15.0)))
		"gobble":
			gobble()
		"sit":
			sit(float(args.get("seconds", 10.0)))
		"sleep":
			sleep()
		"preen":
			preen(float(args.get("seconds", 10.0)))
		"dust":
			dust(float(args.get("seconds", 12.0)))
		"flee":
			flee(args.get("from", _pos + _fwd()))
		"fly":
			fly(args.get("at", _pos + _fwd() * 15.0))
		"lay":
			if male or young:
				return false
			lay()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"gobble":
			return _gobble <= 0.0
		"lay":
			return _mode == "incubate"
		"sleep":
			return false
	return _mode == "forage" or _mode == "alert"


## (The render tests': a pose by name.)
func test_mode(mode: String) -> void:
	for m: String in ["strut", "sleep", "preen", "dust", "sit", "die", "lay", "alert", "gobble"]:
		if mode.contains(m):
			call(m)
	if mode.contains("gobble"):
		_to("alert")
	if mode.contains("peck"):
		eat(_pos + _fwd() * 0.45)
	if mode.contains("walk"):
		_to("forage", "go")
		walk_to(_pos + _fwd() * 30.0, walk_speed)
	if mode.contains("run"):
		flee(_pos - _fwd())
	if mode.contains("fly"):
		fly(_pos + _fwd() * 18.0)
