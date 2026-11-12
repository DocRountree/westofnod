class_name Raptor
extends "res://scripts/creatures/bird.gd" # (by path: found whether or not the editor has seen the class yet)
## A bird of prey, the make the species share (PeregrineFalcon,
## CoopersHawk), life size: Bird's body and motors, and the raptor's ways.
## The species say its shape (shape: the female's, at life size; the male
## smaller: male_size), its plumage (_plumage(stage, male): the shader's
## colours), how it flies and hunts, and its nest. Not yet in the game
## (tools/creatures/ecology_demo.tscn).
##
## Its stages: an adult; a juvenile (juvenile: its first year's plumage,
## brown, streaked); a chick (young: an eyas, downy white, in the nest,
## growing, feathering out, then fledging into a juvenile).
##
## Its ways (each a call; of its own accord it perches, watches, now and
## then moves perch or soars, and hunts what it sees when it's hungry):
## - perched (perch_at: a point it's standing on; perch_on(top): flying
##   there): upright, watching, its head turning, bobbing (judging a
##   distance), its tail flicked; rousing (every feather up, a shake, down
##   again); preening; feaking (its bill wiped on the perch); sleeping on
##   one leg, its head turned back; calling
## - the air: flying to a point and landing (a flare, its tail fanned, its
##   legs out); soaring (circling, wings spread, rising), the hawk's
##   flap-flap-glide; fly_off(from): alarmed, off its perch and away
## - hunting (hunt(prey)): the falcon's stoop (up high over it, then wings
##   drawn in, a dive, its feet thrown forward at the end, the strike); the
##   hawk's dash (low and fast off its perch, a twisting chase, its feet
##   thrust out); caught: down on it, its wings mantled over it; carried to
##   a perch (or its nest, if it's chicks to feed); plucked (tufts of fur or
##   down drifting off), torn, eaten; its bill wiped clean
## - courting (mate(female), a male's): the falcon's display flight
##   (swoops and dives about her, up and over), the hawk's sky dance (slow
##   deep beats, its white undertail fluffed, circling high); then down by
##   her; she leans forward, he's on her back, wings beating for balance; a
##   while; she's carrying eggs
## - nesting (lay(), a female's): to its nest site close by (the falcon's a
##   gravel ledge high on a pole, a scrape scratched in it; the hawk's a
##   stick nest), her clutch laid an egg at a time, sat on; hatch(): the
##   eyases, hers; brood(): sat over them; she feeds them (food carried
##   home: torn, offered bill to bill); they beg (heads up, bills open,
##   wings quivering), grow, feather out, flap on the nest's edge, and
##   fledge (fly down: juveniles)
## - die(): down (falling, from the air), on its back, its feet curled.
## Steering (pilot.gd): act hunt {prey}, eat, perch {at}, soar, preen,
## rouse, sleep, call, lay, mate {partner}, fly {at}.

const DISPLAY_SECS := 16.0

var juvenile := false
var male_size := 0.85 ## the male's size, the female's 1
var flight_pitch := 1.05 ## rad: its body tipped forward, flying (it stands upright)
var tail_rest := -1.1 ## rad: its tail in line with its body
var fold_pitch := 0.75 ## rad: its folded wings tipped down along its back
var cruise := 11.0 ## m/s
var top_speed := 18.0 ## m/s (flapping hard: a dash)
var stoop_speed := 0.0 ## m/s (0: it doesn't stoop)
var soar_height := 30.0
var flaps_glide := false ## (flap-flap-glide: an accipiter's)
var hunt_style := "stoop"
var nest_style := "scrape"
var nest_height := 2.6
var clutch := 4
var egg_size := Vector2(0.052, 0.041)
var egg_colors := [Color(0.62, 0.36, 0.25), Color(0.36, 0.14, 0.08)] ## ground, blotches
var feather_cm := 3.2 ## its body feathers' size
var prey_scripts := ["mouse.gd", "fox_squirrel.gd", "grey_squirrel.gd", "wild_turkey.gd"]
var grow_secs := 200.0 ## s an eyas takes to fledge
var hunger := 0.0 ## (0 fed .. 1 hunting)
var perch_at := Vector3.INF ## (where it's standing, up off the ground: its perch's top)
var home_perch := Vector3.INF
var nest: Node3D
var nest_top := Vector3.INF
var eggs_laid: Array[Node3D] = []
var young_ones: Array = []
var gravid := false

var _mode := "perch"
var _sub := ""
var _mt := 0.0
var _st := 0.0
var _n := 0
var _secs := -1.0
var _vel := Vector3.ZERO
var _yaw_prev := 0.0
var _prey: Node3D
var _carry: Node3D # (what it's caught: carried, eaten)
var _carry_kind := ""
var _carry_left := 0.0
var _plucks: CPUParticles3D
var _partner: Node3D
var _mother: Node3D
var _age := 0.0
var _beg := 0.0
var _then := ""


func _init(young_ := false, juvenile_ := false) -> void:
	super()
	young = young_
	juvenile = juvenile_ and not young_


func _build() -> void:
	if young:
		shape = _eyas()
		if size >= 0.99 or size <= 0.0:
			size = 0.22
		colors = _plumage("juvenile", male)
		colors["down"] = 1.0
		colors["iris"] = Color(0.06, 0.05, 0.05)
		colors["leg_color"] = Color(0.92, 0.86, 0.62)
		colors["cere_color"] = Color(0.8, 0.82, 0.78)
	else:
		shape = _shape()
		size = male_size if male else 1.0
		colors = _plumage("juvenile" if juvenile else "adult", male)
	colors["plumage"] = 1
	colors["bare_from"] = 2.0
	colors["feather_cm"] = feather_cm
	var m := mass_of()
	mass = m.x
	span = m.y
	wing_area = m.z
	walk_speed = 0.35
	run_speed = 1.2
	super()
	want.tail_up = tail_rest
	cur.tail_up = tail_rest
	want.fold_pitch = fold_pitch
	cur.fold_pitch = fold_pitch
	_plant_feet()


## Folded flat to its sides, drawn in against its body, down along its back.
func fold_wings() -> void:
	for s: String in ["l", "r"]:
		want["w%s_up" % s] = -1.58
		want["w%s_sweep" % s] = 0.0
		want["w%s_twist" % s] = 0.0
		want["w%s_spread" % s] = 0.0


func _mesh_key() -> String:
	return "%s:%s" % [(get_script() as Script).resource_path, young]


## (The species': its shape, its eyas's, its plumage, its weight.)
func _shape() -> Dictionary:
	return {}


func _eyas() -> Dictionary:
	return {
		"spine": [[10.0, 7.0, 1.0, 1.0, 0.0], [11.5, 5.5, 5.0, 4.5, 0.0], [14.5, 3.0, 8.5, 8.0, 0.0], [19.0, 1.0, 9.0, 9.0, 0.0], [23.0, 0.0, 7.5, 7.8, 0.0],
				[26.0, 0.0, 5.5, 5.8, 0.3], [28.0, -0.5, 4.6, 4.8, 1.2], [29.8, -1.2, 4.4, 4.6, 2.2], [31.4, -2.0, 4.6, 4.8, 3.2], [32.6, -3.3, 4.8, 5.0, 4.2],
				[32.9, -5.0, 4.5, 4.6, 4.6], [32.0, -7.2, 3.0, 3.2, 4.95], [31.0, -8.2, 1.5, 1.6, 5.0], [30.6, -8.8, 1.1, 1.1, 5.05], [30.0, -9.4, 0.7, 0.7, 5.5],
				[29.2, -9.7, 0.25, 0.25, 5.85], [28.6, -9.5, 0.08, 0.08, 6.0]],
		"pivot": Vector3(0.0, 17.0, 2.0),
		"jaw": Vector3(0.0, 30.4, -8.3),
		"lower_bill": [[30.3, -8.5, 0.9], [29.9, -9.1, 0.55], [29.5, -9.4, 0.15]],
		"eye": Vector3(2.9, 33.3, -6.2), "eye_r": 1.0,
		"cere": [Vector3(0.0, 31.6, -8.1), Vector3(1.1, 0.85, 0.7)],
		"hip": Vector3(4.5, 14.0, 3.0), "knee": Vector3(5.0, 10.0, -1.0), "ankle": Vector3(4.5, 5.0, 1.0), "foot": Vector3(4.5, 1.2, -0.5),
		"thigh_r": [4.5, 3.2], "leg_r": 0.9, "toes": [5.5, 4.0, 3.0], "claw": 0.25,
		"tail": Vector3(0.0, 10.5, 6.5),
		"shoulder": Vector3(8.0, 23.0, 2.0), "wing": Vector3(5.0, 5.0, 4.0), "coverts": [4.0, 4.0, 3.5, 2.0], "wing_thick": [2.5, 2.0, 1.5, 0.8],
		"primaries": [3.0, 3.0, 3.5, 3.5, 4.0, 4.0, 4.0], "secondaries": [6, 4.0, 3.5], "tertials": [0, 1.0, 1.0], "feather_w": 2.0,
		"tail_feathers": [6, 2.0, 1.5],
	}


func _plumage(_stage: String, _male: bool) -> Dictionary:
	return {}


## Its weight (kg), span (m), wings' area (m2), as it is.
func mass_of() -> Vector3:
	return Vector3(1.0, 1.0, 0.12)


func place(at: Vector3, yaw := 0.0) -> void:
	super(at, yaw)


func _ground(x: float, z: float) -> float:
	if perch_at != Vector3.INF and Vector2(x - perch_at.x, z - perch_at.z).length() < 0.35 * maxf(size, 0.5):
		return perch_at.y
	return super(x, z)


## Stood on `top` (its parent's space: a perch's top, a nest), now.
func set_perch(top: Vector3, yaw := NAN) -> void:
	perch_at = top
	if home_perch == Vector3.INF:
		home_perch = top
	place(top, _yaw if is_nan(yaw) else yaw)


# --- its ways -----------------------------------------------------------------------

func _to(mode: String, sub := "") -> void:
	if dead:
		return
	_mode = mode
	_sub = sub
	_mt = 0.0
	_st = 0.0
	_n = 0
	_secs = -1.0
	head_point = Vector3.INF
	look_yaw = 0.0
	foot_off[0] = Vector3.ZERO
	foot_off[1] = Vector3.ZERO
	lift_y = 0.0
	for k: String in ["pitch", "crouch", "drop", "roll", "jaw", "head_pitch", "eye_shut", "puff", "tail_yaw"]:
		want[k] = 0.0
	head_want = Vector3.ZERO
	head_rate = 7.0
	if not _air:
		fold_wings()
		want.tail_up = tail_rest
		want.tail_spread = 0.0
		want.fold_pitch = fold_pitch


## Perched (or stood), watching: its own ways.
func perch() -> void:
	_to("perch")


func wander(_c := Vector3.INF, _r := -1.0) -> void:
	_piloted = false
	perch()


func perch_on(top: Vector3) -> void:
	_to("fly")
	_take_off("go", top, true)


func soar(secs := 40.0) -> void:
	if young:
		return
	_to("soar")
	_secs = secs
	var c := _pos if perch_at == Vector3.INF else perch_at
	_take_off("soar", Vector3(c.x, _ground(c.x, c.z) + soar_height * rng.randf_range(0.6, 1.0), c.z), false)


func fly_off(from: Vector3) -> void:
	if young or dead:
		return
	var away := _pos - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else _fwd()
	var to := _pos + away * rng.randf_range(14.0, 22.0)
	_to("fly")
	_call()
	_take_off("go", Vector3(to.x, _ground(to.x, to.z), to.z), true)


func fly(to: Vector3) -> void:
	if young or dead:
		return
	_to("fly")
	_take_off("go", Vector3(to.x, _ground(to.x, to.z), to.z), true)


func preen(secs := 10.0) -> void:
	if _air:
		return
	_to("preen")
	_secs = secs


func rouse() -> void:
	if _air:
		return
	_to("rouse")


func sleep() -> void:
	if _air:
		return
	_to("sleep")


func call_out(secs := 3.0) -> void:
	if _air:
		return
	_to("call")
	_secs = secs


func _call() -> void: # (a short call, whatever it's doing: its bill opening, shutting)
	_beg = 1.0


## Hunting prey (a creature with die(), its _pos: the parent's space).
func hunt(prey: Node3D) -> void:
	if young or dead or prey == null or not is_instance_valid(prey):
		return
	_prey = prey
	_to("hunt")
	if hunt_style == "stoop" and stoop_speed > 0.0:
		var p := _prey_pos()
		_take_off("ring", p + Vector3(rng.randf_range(-8.0, 8.0), soar_height, rng.randf_range(-8.0, 8.0)), false)
	else:
		_take_off("dash", _prey_pos(), false)


func _prey_pos() -> Vector3:
	if _prey == null or not is_instance_valid(_prey):
		return _pos
	var p: Variant = _prey.get("_pos")
	var q: Vector3 = p if p is Vector3 else _prey.position
	return q


## (A male's.) Courting `female`: his display flight about her, then down
## by her, and on her back. False if they can't.
func mate(female: Node3D, secs := -1.0) -> bool:
	if not male or young or juvenile or dead or female == null or not is_instance_valid(female) or female == self:
		return false
	if female.get("male") or female.get("young") or female.get("dead") or female.get("gravid") or female.get("_mode") in ["nest", "incubate", "brood"]:
		return false
	_partner = female
	_secs = secs if secs > 0.0 else 8.0
	_to("court")
	var fp: Vector3 = female.get("_pos")
	_take_off("display", fp + Vector3(0.0, 8.0, 0.0), false)
	if female.get("_air"): # (in the air: she's called down to her perch first)
		female.call("perch_on", female.get("home_perch") if female.get("home_perch") != Vector3.INF else female.get("_pos"))
	else:
		female.call("_to", "courted")
	female.set("_partner", self)
	return true


func is_mating() -> bool:
	return _partner != null and is_instance_valid(_partner) and _mode in ["court", "mount"]


## (A female's.) Her eggs laid in her nest, close by (made, the first time).
func lay() -> void:
	if male or young or juvenile or dead or _mode in ["nest", "incubate", "brood"]:
		return
	_ensure_nest()
	_to("nest", "go")
	_take_off("go", nest_top, true)


func _ensure_nest() -> void:
	if nest != null and is_instance_valid(nest):
		return
	var base := (home_perch if home_perch != Vector3.INF else _pos)
	var a := rng.randf() * TAU
	var at := base + Vector3(cos(a), 0.0, sin(a)) * 3.0
	at.y = super._ground(at.x, at.z)
	nest = _make_nest_site()
	get_parent().add_child(nest)
	nest.position = at
	nest_top = at + Vector3(0.0, nest_height + (0.04 if nest_style == "sticks" else 0.03), 0.0)


## Her eggs opening: an eyas from each, hers.
func hatch() -> void:
	if eggs_laid.is_empty():
		return
	var par := get_parent()
	var k := 0
	for e in eggs_laid:
		if not is_instance_valid(e):
			continue
		var y: Raptor = (get_script() as GDScript).new(true)
		y.male = rng.randf() < 0.5
		y.height = height
		y.ground_y = ground_y
		par.add_child(y)
		var a := TAU * k / maxf(eggs_laid.size(), 1) + 0.3
		var at := nest_top + Vector3(cos(a), 0.0, sin(a)) * 0.09
		y.perch_at = nest_top
		y.nest_top = nest_top
		y.place(at, a + PI)
		y._mother = self
		y._to("eyas")
		young_ones.append(y)
		e.queue_free()
		k += 1
	eggs_laid.clear()
	brood(25.0)


func brood(secs := 25.0) -> void:
	if young_ones.is_empty() or nest_top == Vector3.INF:
		return
	if _air or perch_at.distance_to(nest_top) > 0.3:
		_to("nest", "home")
		_take_off("go", nest_top, true)
		return
	_to("brood")
	_secs = secs


func die() -> void:
	if dead:
		return
	if _carry:
		_drop_carry()
	_to("dead")
	dead = true
	_flap = 0.0
	halt()
	_speed = 0.0
	if _air: # (falling)
		_fly = {"kind": "fall", "hz": 1.0, "t": 0.0}
		set_wings(0.6, 0.0, 0.3, 0.7)
	else:
		_lie()


func _lie() -> void:
	_air = false
	want.roll = 2.6
	want.drop = 0.18 * (1.0 if not young else 0.6)
	want.pitch = 1.2
	want.eye_shut = 1.0
	want.tail_spread = 0.5
	want.legs_tuck = 0.6
	talon_open = 0.0
	set_wings(-0.5, 0.0, 0.2, 0.55)
	want.fold_pitch = 0.2
	head_want = Vector3(0.0, -0.06, 0.05)
	for k: String in ["roll", "drop", "pitch"]:
		rate[k] = 5.0


# --- each frame ---------------------------------------------------------------------

func _think(dt: float) -> void:
	_mt += dt
	_st += dt
	hunger = minf(hunger + dt / 180.0, 1.0)
	if _beg > 0.0: # (a call: its bill working)
		_beg -= dt
		want.jaw = 0.4 * maxf(0.0, sin(_mt * 22.0)) if _beg > 0.0 else 0.0
		rate["jaw"] = 30.0
	if young:
		_grow(dt)
	if _carry:
		_hold_carry()
	if _air:
		return
	if _piloted and _mode == "perch":
		return
	match _mode:
		"perch":
			_watch(dt)
		"preen":
			_preen(dt)
		"rouse":
			_rouse(dt)
		"sleep":
			want.puff = 0.6
			want.eye_shut = 1.0
			look_yaw = 2.6
			head_want = Vector3(0.012, -0.03, 0.05)
			want.head_pitch = 0.4
			foot_off[1] = Vector3(0.0, 0.05, -0.01) # (one foot drawn up into its belly feathers)
			want.drop = 0.01
		"call":
			want.head_pitch = -0.15
			head_want = Vector3(0.0, 0.0, -0.015)
			want.jaw = 0.45 * maxf(0.0, sin(_mt * 18.0))
			rate["jaw"] = 30.0
			if _mt > _secs:
				perch()
		"eat":
			_eat(dt)
		"mantle":
			_mantle(dt)
		"courted": # (a female, his display watched: turned to him, calling now and then)
			if _partner == null or not is_instance_valid(_partner) or _partner.get("_mode") not in ["court", "mount"]:
				_partner = null
				perch()
			else:
				var to: Vector3 = (_partner.get("_pos") as Vector3) - _pos
				look_yaw = clampf(wrapf(atan2(-to.x, -to.z) - _yaw, -PI, PI), -1.8, 1.8)
				want.head_pitch = -0.4 * clampf(to.y / maxf(Vector2(to.x, to.z).length(), 1.0), 0.0, 1.0)
				if fmod(_mt, 5.0) < 0.05:
					_call()
		"crouch": # (a female, solicited: leaning forward, tail up)
			want.pitch = 0.75
			want.tail_up = tail_rest + 0.9
			head_want = Vector3(0.0, -0.03, -0.02)
			if _partner == null or not is_instance_valid(_partner) or _partner.get("_mode") not in ["court", "mount"]:
				_partner = null
				perch()
		"mount":
			_mount(dt)
		"nest":
			_nest(dt)
		"incubate":
			want.drop = 0.12 * size
			want.puff = 0.4
			look_yaw = 0.6 * sin(_mt * 0.3)
			if fmod(_mt, 20.0) > 18.5: # (turning her eggs, her bill down among them)
				want.head_pitch = 0.9
				head_want = Vector3(0.0, -0.05, -0.04)
			else:
				want.head_pitch = 0.0
				head_want = Vector3.ZERO
		"brood":
			want.drop = 0.1 * size
			want.puff = 0.5
			set_wings(-1.3, 0.1, 0.1, 0.15)
			look_yaw = 0.5 * sin(_mt * 0.4)
			if _secs > 0.0 and _mt > _secs:
				perch()
		"feed_young":
			_feed_young(dt)
		"eyas":
			_eyas_ways(dt)
		"fledge":
			_fledge(dt)


# perched, watching: its head turning, bobbing; its tail flicked; now and
# then a rouse, a preen, off to another perch, up to soar, or a hunt
func _watch(dt: float) -> void:
	var look := fmod(_mt, 5.0)
	look_yaw = lerpf(look_yaw, 0.9 * sin(floor(_mt / 2.5) * 2.7), 1.0 - exp(-6.0 * dt))
	if look > 4.3: # (bobbing: its head up and down, judging how far)
		head_want = Vector3(0.0, 0.012 * sin(_mt * 14.0), -0.006)
	else:
		head_want = Vector3.ZERO
	if flaps_glide: # (an accipiter's tail, flicked)
		want.tail_yaw = 0.18 * sin(_mt * 3.0) * float(fmod(_mt, 7.0) < 1.0)
		rate["tail_yaw"] = 18.0
	if young:
		return
	if _st > 6.0:
		_st = 0.0
		var r := rng.randf()
		if hunger > 0.6:
			var p := _find_prey()
			if p:
				hunt(p)
				return
		if r < 0.1:
			rouse()
		elif r < 0.18:
			preen(rng.randf_range(6.0, 12.0))
		elif r < 0.24:
			soar(rng.randf_range(25.0, 45.0))
		elif r < 0.3 and home_perch != Vector3.INF and perch_at.distance_to(home_perch) > 0.5:
			perch_on(home_perch)


func _find_prey() -> Node3D:
	var par := get_parent()
	if par == null:
		return null
	var best: Node3D = null
	var bd := 40.0
	for o in par.get_children():
		if o == self or not (o is Node3D) or o.get_script() == null or not o.has_method("die"):
			continue
		var path: String = (o.get_script() as Script).resource_path.get_file()
		if path not in prey_scripts or o.get("dead"):
			continue
		if path == "wild_turkey.gd" and not o.get("young"):
			continue
		if o.has_meta("hunted") and o.get_meta("hunted") != self and is_instance_valid(o.get_meta("hunted")):
			continue
		var q: Variant = o.get("_pos")
		var d: float = ((q if q is Vector3 else (o as Node3D).position) as Vector3).distance_to(_pos)
		if d < bd:
			bd = d
			best = o
	return best


func _preen(_dt: float) -> void:
	var k := int(_mt / 2.4) % 4
	var nib := 0.004 * sin(_mt * 16.0)
	want.puff = 0.35
	head_rate = 7.0
	match k:
		0, 2: # (a wing's feathers drawn through its bill)
			var s := -1.0 if k == 0 else 1.0
			look_yaw = -s * 2.2
			head_want = Vector3(s * 0.03, -0.04 + nib, 0.05)
			want.head_pitch = 0.7
			want["w%s_spread" % ("l" if s < 0.0 else "r")] = 0.15
		1: # (its breast)
			head_want = Vector3(0.0, -0.05 + nib, 0.01)
			want.head_pitch = 1.3
		3: # (its tail, reached round under)
			look_yaw = 2.6
			head_want = Vector3(0.02, -0.08, 0.06)
			want.head_pitch = 1.0
			want.tail_yaw = 0.3
	want.jaw = 0.12 + 0.1 * sin(_mt * 16.0)
	rate["jaw"] = 30.0
	if _mt > _secs:
		rouse()


func _rouse(_dt: float) -> void:
	# every feather up, a shake through it, smoothed down again
	var t := _mt
	want.puff = 1.0 if t < 1.4 else 0.0
	rate["puff"] = 10.0
	if t > 0.6 and t < 1.3:
		want.roll = 0.12 * sin(t * 40.0)
		rate["roll"] = 40.0
		want.tail_yaw = 0.2 * sin(t * 40.0 + 1.0)
		rate["tail_yaw"] = 40.0
	else:
		want.roll = 0.0
		want.tail_yaw = 0.0
	if t > 1.6 and t < 2.4: # (a feak: its bill wiped on the perch)
		want.head_pitch = 1.1
		head_want = Vector3(0.015 * sin(t * 14.0), -0.06, -0.03)
	else:
		want.head_pitch = 0.0
		head_want = Vector3.ZERO
	if t > 2.6:
		perch()


# --- the air -------------------------------------------------------------------------

## Off its perch (a drop and a few hard beats) on a flight of `kind` toward
## `to`; land: down onto it at the end.
func _take_off(kind: String, to: Vector3, land: bool) -> void:
	if dead:
		return
	var was_air := _air
	_air = true
	_fly = {"kind": kind, "to": to, "land": land, "t": 0.0, "hz": BirdFlight.wingbeat_hz(mass, span, wing_area), "climb": 0.0,
			"theta": rng.randf() * TAU, "phase": "go"}
	if not was_air:
		perch_at = Vector3.INF
		_vel = _fwd() * 2.0 + Vector3(0.0, 1.8, 0.0)
		_yaw_prev = _yaw
		want.legs_tuck = 1.0
		rate["legs_tuck"] = 4.0


func _fly_step(dt: float) -> void:
	var f := _fly
	f.t = float(f.get("t", 0.0)) + dt
	var kind: String = f.get("kind", "")
	if kind == "":
		super(dt)
		return
	if kind == "fall": # (dead, falling)
		_vel.y -= 9.8 * dt
		_vel.x *= 1.0 - dt
		_vel.z *= 1.0 - dt
		_pos += _vel * dt
		want.roll = move_toward(float(want.roll), 2.6, dt * 3.0)
		var gy := _ground(_pos.x, _pos.z)
		if _pos.y <= gy:
			_pos.y = gy
			_air = false
			_fly = {}
			_lie()
		return
	var to: Vector3 = f.to
	var hz: float = f.hz
	var speed := cruise
	var flap := 1.0
	var wings := Vector4(0.1, 0.12, 0.0, 1.0) # (glided: spread, a little swept)
	var tail_spread := 0.25
	var gy := super._ground(_pos.x, _pos.z)
	var aim := to
	want.legs_tuck = 1.0
	air_foot = Vector3.ZERO
	talon_open = 0.0
	match kind:
		"go":
			var d := to - _pos
			var hd := Vector2(d.x, d.z).length()
			# (up to a cruising height over the ground, down toward it at the end)
			var cruise_h := clampf(hd * 0.25, 1.5, 12.0)
			aim = to + Vector3(0.0, cruise_h * smoothstep(3.0, 12.0, hd), 0.0)
			if hd < 4.0:
				aim = to + Vector3(0.0, 0.25 * hd, 0.0)
			speed = lerpf(2.0, cruise, smoothstep(1.5, 9.0, d.length()))
			flap = 1.0 if (hd > 25.0 and fmod(float(f.t), 4.0) < 2.5) or d.y > 0.5 or hd < 3.0 or float(f.t) < 1.2 else (0.0 if not flaps_glide else float(fmod(float(f.t), 1.4) < 0.7))
			if hd < 3.0: # (the flare: up, wings high, tail fanned, legs out)
				wings = Vector4(0.55, -0.1, 0.45, 1.0)
				tail_spread = 0.9
				want.legs_tuck = 0.0
				air_foot = Vector3(0.0, 0.1, -0.02)
				talon_open = 0.6
			if d.length() < 0.12 + speed * dt * 1.5:
				_land(to)
				return
		"soar":
			# circling over its place, wings spread; rising; the hawk's few
			# beats and a glide
			var r := BirdFlight.turn_radius(cruise * 0.7, deg_to_rad(28.0))
			f.theta = float(f.theta) + cruise * 0.7 / maxf(r, 1.0) * dt
			aim = to + Vector3(cos(f.theta), 0.0, sin(f.theta)) * r + Vector3(0.0, sin(float(f.t) * 0.1) * 3.0, 0.0)
			speed = cruise * 0.7
			flap = float(_pos.y < to.y - 8.0) if not flaps_glide else float(fmod(float(f.t), 3.0) < 0.9)
			wings = Vector4(0.16, 0.0, 0.0, 1.0)
			tail_spread = 0.9
			if _secs > 0.0 and _mt > _secs:
				var back := home_perch if home_perch != Vector3.INF else Vector3(to.x, gy, to.z)
				f.kind = "go"
				f.to = back
				f.land = true
				return
		"ring": # (the falcon, up over its prey: climbing in circles)
			var r2 := 10.0
			f.theta = float(f.theta) + cruise / r2 * dt
			var pp := _prey_pos()
			aim = Vector3(pp.x, gy + soar_height, pp.z) + Vector3(cos(f.theta), 0.0, sin(f.theta)) * r2
			speed = cruise
			flap = float(_pos.y < gy + soar_height - 3.0)
			wings = Vector4(0.12, 0.05, 0.0, 1.0)
			if _pos.y > gy + soar_height * 0.85 and float(f.t) > 3.0:
				f.kind = "stoop"
				f.t = 0.0
				_call()
			if not _prey_ok():
				_give_up()
				return
		"stoop":
			# wings drawn in, a dive at it; its feet thrown forward at the end
			var pp := _prey_pos() + Vector3(0.0, 0.05, 0.0)
			var d := pp - _pos
			aim = pp
			speed = lerpf(cruise, stoop_speed, smoothstep(0.0, 2.0, float(f.t)))
			flap = 0.0
			wings = Vector4(-0.2, 0.85, 0.0, 0.18)
			tail_spread = 0.0
			if d.length() < 4.0:
				wings = Vector4(0.3, 0.1, 0.4, 1.0)
				tail_spread = 0.9
				want.legs_tuck = 0.0
				air_foot = Vector3(0.0, 0.2, -0.04)
				talon_open = 1.0
				speed = lerpf(5.0, speed, d.length() / 4.0)
			if d.length() < 0.25 or (_pos.y < gy + 0.1 and Vector2(d.x, d.z).length() < 0.6):
				_strike()
				return
			if not _prey_ok():
				_give_up()
				return
		"dash":
			# low and fast after it, its feet thrust out at the end
			var pp := _prey_pos() + Vector3(0.0, 0.05, 0.0)
			var d := pp - _pos
			var hd := Vector2(d.x, d.z).length()
			aim = pp + Vector3(0.0, clampf(hd * 0.08, 0.0, 1.2), 0.0)
			speed = top_speed * smoothstep(0.0, 1.2, float(f.t)) + 2.0
			flap = 1.0
			hz *= 1.2
			if hd < 3.0:
				wings = Vector4(0.45, 0.0, 0.35, 1.0)
				flap = 0.4
				tail_spread = 0.9
				want.legs_tuck = 0.0
				air_foot = Vector3(0.0, 0.2, -0.04)
				talon_open = 1.0
				speed = maxf(4.0, speed * hd / 3.0)
			if d.length() < 0.25:
				_strike()
				return
			if not _prey_ok() or float(f.t) > 12.0:
				_give_up()
				return
		"carry":
			# home with it in its feet
			var d := to - _pos
			var hd := Vector2(d.x, d.z).length()
			aim = to + Vector3(0.0, clampf(hd * 0.2, 0.0, 6.0) * smoothstep(2.0, 8.0, hd), 0.0)
			speed = cruise * 0.75
			flap = 1.0
			want.legs_tuck = 0.3
			if hd < 2.5:
				wings = Vector4(0.55, -0.1, 0.45, 1.0)
				tail_spread = 0.9
				air_foot = Vector3(0.0, 0.1, -0.02)
			if d.length() < 0.15 + speed * dt * 1.5:
				_land(to)
				return
		"display":
			# about her: the falcon's swoops and dives, up and over; the
			# hawk's slow deep beats, its undertail fluffed, circling high
			var fp: Vector3 = _partner.get("_pos") if _partner != null and is_instance_valid(_partner) else _pos
			var r3 := 9.0
			f.theta = float(f.theta) + (cruise * 0.8) / r3 * dt * (1.0 if hunt_style == "stoop" else 0.6)
			var swoop := (sin(float(f.t) * 0.9) * 5.0) if hunt_style == "stoop" else sin(float(f.t) * 0.5) * 1.5
			aim = fp + Vector3(cos(f.theta) * r3, 9.0 + swoop, sin(f.theta) * r3)
			speed = cruise * (0.9 if hunt_style == "stoop" else 0.5)
			flap = 1.0 if hunt_style != "stoop" else float(_vel.y > -0.5)
			if hunt_style != "stoop":
				hz *= 0.55 # (slow, exaggerated)
				want.puff = 0.6
			if float(f.t) > DISPLAY_SECS:
				f.kind = "go"
				f.to = Vector3(fp.x + 0.35, (_partner.get("perch_at") as Vector3).y if _partner != null and (_partner.get("perch_at") as Vector3) != Vector3.INF else super._ground(fp.x + 0.35, fp.z), fp.z)
				f.land = true
				return
	# steering: toward its aim at its speed, turning as a bird turns
	var want_v := (aim - _pos).normalized() * speed
	var accel := 6.0 + speed * 0.6
	_vel = _vel.move_toward(want_v, accel * dt)
	_pos += _vel * dt
	if _pos.y < gy + 0.05 and kind not in ["stoop", "dash", "go", "carry"]:
		_pos.y = gy + 0.05
		_vel.y = maxf(_vel.y, 0.0)
	_pos.y = maxf(_pos.y, gy)
	var hs := Vector2(_vel.x, _vel.z).length()
	if hs > 0.3:
		_yaw = atan2(-_vel.x, -_vel.z)
	var yaw_rate := wrapf(_yaw - _yaw_prev, -PI, PI) / dt
	_yaw_prev = _yaw
	var bank := clampf(atan(hs * yaw_rate / 9.8), -1.2, 1.2)
	want.roll = -bank
	rate["roll"] = 5.0 + 20.0 / maxf(span, 0.3) * 0.1
	var climb := atan2(_vel.y, maxf(hs, 0.5))
	var flare := float(want.legs_tuck) < 0.5
	want.pitch = flight_pitch - climb * 0.7 - (0.7 if flare else 0.0)
	want.head_pitch = -(flight_pitch - climb * 0.7) * 0.85 + (0.4 if flare else 0.0)
	head_want = Vector3(0.0, 0.0, 0.0)
	want.tail_up = tail_rest + 0.15 + (0.35 if flare else 0.0)
	want.tail_spread = tail_spread
	want.fold_pitch = 0.0
	for k: String in ["pitch", "head_pitch", "tail_up", "tail_spread"]:
		rate[k] = 6.0
	_flap = move_toward(_flap, flap, dt * 6.0)
	_phase += TAU * hz * dt
	_speed = hs
	set_wings(wings.x, wings.y, wings.z, wings.w)
	for k: String in ["wl_up", "wr_up", "wl_sweep", "wr_sweep", "wl_twist", "wr_twist", "wl_spread", "wr_spread"]:
		rate[k] = 8.0


func _prey_ok() -> bool:
	return _prey != null and is_instance_valid(_prey) and not _prey.get("dead")


func _give_up() -> void:
	_prey = null
	var back := home_perch if home_perch != Vector3.INF else Vector3(_pos.x, super._ground(_pos.x, _pos.z), _pos.z)
	_fly.kind = "go"
	_fly.to = back
	_fly.land = true
	_mode = "fly"


func _land(at: Vector3) -> void:
	_air = false
	_fly = {}
	_flap = 0.0
	_vel = Vector3.ZERO
	var gy := super._ground(at.x, at.z)
	perch_at = at if at.y > gy + 0.05 else Vector3.INF
	_pos = at
	_speed = 0.0
	halt()
	_plant_feet()
	air_foot = Vector3.ZERO
	talon_open = 0.0
	want.legs_tuck = 0.0
	want.roll = 0.0
	want.pitch = 0.0
	want.head_pitch = 0.0
	want.puff = 0.0
	fold_wings()
	want.fold_pitch = fold_pitch
	want.tail_up = tail_rest
	want.tail_spread = 0.0
	match _mode:
		"court":
			_to("mount")
		"nest":
			if _carry:
				_to("feed_young")
			elif young_ones.is_empty():
				_sub = "scrape"
				_st = 0.0
			else:
				_to("brood")
				_secs = 25.0
		"carrying":
			if not young_ones.is_empty() and nest_top != Vector3.INF and at.distance_to(nest_top) < 0.3:
				_to("feed_young")
			else:
				_to("eat")
		"fledge":
			_to("perch")
		_:
			_to("courted" if _partner != null and is_instance_valid(_partner) and not male else "perch")


# --- the kill, the meal ----------------------------------------------------------------

func _strike() -> void:
	var prey := _prey
	_prey = null
	if prey == null or not is_instance_valid(prey):
		_give_up()
		return
	var kind := "mammal"
	var path: String = (prey.get_script() as Script).resource_path.get_file() if prey.get_script() else ""
	if path == "wild_turkey.gd":
		kind = "bird"
	var sz := 0.09
	match path:
		"fox_squirrel.gd", "grey_squirrel.gd":
			sz = 0.22
		"wild_turkey.gd":
			sz = 0.07 + 0.2 * float(prey.get("size"))
		"mouse.gd":
			sz = 0.08
	var col := Color(0.45, 0.37, 0.28)
	match path:
		"fox_squirrel.gd":
			col = Color(0.6, 0.4, 0.22)
		"grey_squirrel.gd":
			col = Color(0.46, 0.44, 0.42)
		"wild_turkey.gd":
			col = Color(0.62, 0.5, 0.32)
	var at := _prey_pos()
	if prey.has_method("die"):
		prey.call("die")
	prey.queue_free()
	_carry = _make_carry(kind, sz, col)
	_carry_kind = kind
	_carry_left = 1.0
	add_child(_carry)
	# down on it: its wings mantled over it, then off home with it
	_land(Vector3(at.x, super._ground(at.x, at.z), at.z))
	_to("mantle")
	hunger = 0.0


func _make_carry(kind: String, sz: float, col: Color) -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.scale = Vector3(sz * 0.42, sz * 0.36, sz)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.95
	mi.material_override = m
	n.add_child(mi)
	if kind == "mammal": # (its tail)
		var t := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = sz * (0.06 if sz > 0.15 else 0.02)
		cm.bottom_radius = sz * (0.1 if sz > 0.15 else 0.025)
		cm.height = sz * 0.9
		t.mesh = cm
		t.material_override = m
		t.rotation = Vector3(PI * 0.5 - 0.3, 0.0, 0.0)
		t.position = Vector3(0.0, sz * 0.12, sz * 0.8)
		n.add_child(t)
	_plucks = CPUParticles3D.new()
	_plucks.emitting = false
	_plucks.one_shot = true
	_plucks.amount = 14
	_plucks.lifetime = 2.5
	_plucks.explosiveness = 0.8
	_plucks.direction = Vector3(0.0, 1.0, 0.0)
	_plucks.spread = 70.0
	_plucks.initial_velocity_min = 0.3
	_plucks.initial_velocity_max = 0.8
	_plucks.gravity = Vector3(0.0, -0.6, 0.0)
	_plucks.damping_min = 1.5
	_plucks.damping_max = 3.0
	_plucks.scale_amount_min = 0.6
	_plucks.scale_amount_max = 1.3
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.018)
	_plucks.mesh = q
	var pm := StandardMaterial3D.new()
	pm.albedo_color = col.lightened(0.25)
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_plucks.material_override = pm
	_plucks.local_coords = false
	n.add_child(_plucks)
	return n


## (What it's caught: in its feet, or under them.)
func _hold_carry() -> void:
	if _carry == null:
		return
	var l: Transform3D = _g[J_LEG[0] + 3]
	var r: Transform3D = _g[J_LEG[1] + 3]
	var mid := (l.origin + r.origin) * 0.5 * size
	_carry.position = mid + Vector3(0.0, -0.02, -0.02)
	_carry.rotation = Vector3(0.0, 0.0, 0.0)
	_carry.scale = Vector3.ONE * clampf(0.35 + 0.65 * _carry_left, 0.2, 1.0)


func _drop_carry() -> void:
	if _carry:
		_carry.queue_free()
	_carry = null
	_plucks = null


func _mantle(_dt: float) -> void:
	# over it, wings spread down round it, tail fanned, looking about
	set_wings(-0.55, -0.2, 0.35, 0.9)
	want.fold_pitch = 0.0
	want.pitch = 0.6
	want.tail_spread = 0.8
	want.tail_up = tail_rest + 0.4
	want.puff = 0.5
	want.crouch = 0.3
	look_yaw = 0.8 * sin(_mt * 2.0)
	head_want = Vector3(0.0, -0.03, -0.02)
	if _mt > 2.5:
		var home := nest_top if not young_ones.is_empty() and nest_top != Vector3.INF else home_perch
		if home != Vector3.INF and home.distance_to(_pos) > 0.6:
			_to("carrying")
			_take_off("carry", home, true)
		else:
			_to("eat")


func _eat(dt: float) -> void:
	# plucked (tufts drifting), torn and swallowed; its feet on it
	if _carry == null:
		rouse()
		return
	want.pitch = 0.75
	want.crouch = 0.2
	want.tail_up = tail_rest + 0.5
	var ph := fmod(_mt, 1.1) / 1.1
	head_rate = 16.0
	if ph < 0.35: # (down to it)
		want.head_pitch = 1.1
		head_want = Vector3(0.0, -0.09 * size, -0.05 * size)
	elif ph < 0.6: # (a tug: a mouthful torn off, or a pluck)
		want.head_pitch = 0.5
		head_want = Vector3(0.012 * sin(_mt * 9.0), -0.04 * size, -0.03 * size)
		want.jaw = 0.25
	else: # (up, swallowing, looking round)
		want.head_pitch = -0.1
		head_want = Vector3.ZERO
		want.jaw = 0.0
		look_yaw = 0.5 * sin(_mt)
	rate["jaw"] = 25.0
	if ph < 0.4 and ph + dt / 1.1 >= 0.4:
		if _plucks and _carry_left > 0.5:
			_plucks.restart()
			_plucks.emitting = true
		_carry_left -= 0.05
	if _carry_left <= 0.0:
		_drop_carry()
		rouse()


# --- courting, mating ----------------------------------------------------------------------

func _mount(dt: float) -> void:
	var f := _partner
	if f == null or not is_instance_valid(f):
		perch()
		return
	if f.get("_air"): # (not down yet: waited for)
		return
	if f.get("_mode") != "crouch":
		f.call("_to", "crouch")
		f.set("_partner", self)
	var fp: Vector3 = f.get("_pos")
	var fy: float = f.get("_yaw")
	_pos = _pos.lerp(fp, 1.0 - exp(-5.0 * dt))
	_yaw = lerp_angle(_yaw, fy, 1.0 - exp(-5.0 * dt))
	lift_y = move_toward(lift_y, 0.17 * float(f.get("size")), dt * 0.6)
	for i in 2:
		_feet[i] = _pos + _right() * (-0.04 if i == 0 else 0.04) + Vector3(0.0, lift_y, 0.0)
	want.pitch = 0.4
	want.tail_up = tail_rest - 0.2
	set_wings(0.3, -0.1, 0.3, 0.9)
	want.fold_pitch = 0.0
	_flap = 0.45
	_phase += TAU * 7.0 * dt
	if _mt > _secs:
		f.set("gravid", true)
		f.set("_partner", null)
		f.call("perch")
		_partner = null
		_flap = 0.0
		lift_y = 0.0
		var off := _pos + _right() * 0.3
		off.y = _ground(off.x, off.z)
		perch_at = Vector3.INF if off.y < super._ground(off.x, off.z) + 0.05 else perch_at
		_to("fly")
		_take_off("go", home_perch if home_perch != Vector3.INF else off + _fwd() * 3.0, true)


# --- the nest, the eggs, the young -----------------------------------------------------

func _nest(_dt: float) -> void:
	match _sub:
		"scrape": # (a hollow worked in it: leaning forward, her feet kicking back)
			want.pitch = 0.6
			want.drop = 0.04 * size
			var ph := fmod(_st, 0.45) / 0.45
			foot_off[int(_st / 0.45) % 2] = Vector3(0.0, 0.02 * sin(PI * ph), lerpf(-0.03, 0.05, ph))
			_yaw += 0.7 * _dt
			if _st > 4.0:
				foot_off[0] = Vector3.ZERO
				foot_off[1] = Vector3.ZERO
				_plant_feet()
				_sub = "lay"
				_st = 0.0
				_n = clutch - eggs_laid.size()
		"lay":
			want.drop = 0.1 * size
			want.pitch = -0.05
			want.tail_up = tail_rest + 0.3
			if _st > 2.5:
				_st = 0.0
				if _n > 0:
					_n -= 1
					var e := _make_egg()
					nest.add_child(e)
					var k := eggs_laid.size()
					var a := k * 2.4
					var r := 0.032 * sqrt(float(k))
					e.position = (nest_top - nest.position) + Vector3(cos(a) * r, egg_size.y * 0.5 - 0.01, sin(a) * r)
					e.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, PI * 0.5 + rng.randf_range(-0.3, 0.3))
					eggs_laid.append(e)
				else:
					gravid = false
					_to("incubate")


func _feed_young(_dt: float) -> void:
	# tearing it, a morsel offered to each chick in turn, bill to bill
	if _carry == null or young_ones.is_empty():
		_drop_carry()
		brood(20.0)
		return
	want.pitch = 0.7
	want.drop = 0.03 * size
	var live: Array = []
	for y in young_ones:
		if is_instance_valid(y) and y.get("young"):
			live.append(y)
	if live.is_empty():
		_drop_carry()
		perch()
		return
	var who: Node3D = live[int(_mt / 2.2) % live.size()]
	var ph := fmod(_mt, 2.2) / 2.2
	head_rate = 12.0
	if ph < 0.4: # (down to the meal, a morsel torn off)
		want.head_pitch = 1.1
		head_want = Vector3(0.0, -0.09 * size, -0.04 * size)
		look_yaw = 0.0
	else: # (turned to the chick, down to its bill)
		var to: Vector3 = (who.get("_pos") as Vector3) - _pos
		look_yaw = clampf(wrapf(atan2(-to.x, -to.z) - _yaw, -PI, PI), -1.6, 1.6)
		want.head_pitch = 0.7
		head_want = Vector3(0.0, -0.06 * size, -0.03 * size)
		who.set("_beg", 0.6)
	if ph < 0.4 and ph + _dt / 2.2 >= 0.4:
		_carry_left -= 0.08
		if _plucks:
			_plucks.restart()
			_plucks.emitting = true
		who.set("_age", float(who.get("_age")) + grow_secs * 0.04)
	if _carry_left <= 0.0:
		_drop_carry()
		brood(20.0)


func _eyas_ways(dt: float) -> void:
	# sat in the nest, wobbly; begging when a parent's there with food;
	# sleeping in a heap; flapping its wings as they grow
	want.drop = 0.07
	want.pitch = 0.1
	var mom := _mother
	var fed: bool = mom != null and is_instance_valid(mom) and mom.get("_mode") == "feed_young"
	if fed or _beg > 0.0:
		want.head_pitch = -0.5
		head_want = Vector3(0.0, 0.03, -0.02)
		want.jaw = 0.5
		set_wings(-1.0 + 0.2 * sin(_mt * 25.0), 0.0, 0.0, 0.4)
		want.fold_pitch = 0.3
		if fed:
			var to: Vector3 = (mom.get("_pos") as Vector3) - _pos
			turn_to(to)
	else:
		want.jaw = 0.0
		fold_wings()
		var nap := fmod(_mt + float(get_instance_id() % 7), 14.0) > 9.0
		want.eye_shut = 1.0 if nap else 0.0
		head_want = Vector3(0.0, -0.04 if nap else 0.01 * sin(_mt * 1.3), 0.0)
		want.head_pitch = 0.5 if nap else 0.0
		look_yaw = 0.0 if nap else 0.7 * sin(_mt * 0.6 + float(get_instance_id() % 5))
		if size > 0.6 and fmod(_mt, 9.0) < 1.5: # (exercising its wings)
			set_wings(0.2, 0.0, 0.2, 1.0)
			want.fold_pitch = 0.0
			_flap = 0.8
			_phase += TAU * 6.0 * dt
		else:
			_flap = 0.0
	if _age >= grow_secs:
		_fledge_now()


func _grow(dt: float) -> void:
	_age += dt
	var g := clampf(_age / grow_secs, 0.0, 1.0)
	size = lerpf(0.22, 0.85, g)
	if _mat:
		_mat.set_shader_parameter("down", 1.0 - smoothstep(0.45, 0.95, g))


## Grown: its first feathers (a juvenile), off the nest.
func _fledge_now() -> void:
	young = false
	juvenile = true
	_flap = 0.0
	_rebuild()
	_to("fledge")
	var mom := _mother
	var a := rng.randf() * TAU
	var to := _pos + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(4.0, 8.0)
	to.y = super._ground(to.x, to.z)
	_take_off("go", to, true)
	if mom and is_instance_valid(mom):
		(mom.get("young_ones") as Array).erase(self)


func _fledge(_dt: float) -> void:
	perch()


# --- the nest site, the eggs --------------------------------------------------------------

static var _wood: StandardMaterial3D


## Its nest site: a pole (a cliff's ledge, a tree's crotch, stood in for),
## the falcon's gravel ledge or the hawk's stick nest on its top.
func _make_nest_site() -> Node3D:
	var n := Node3D.new()
	n.set_meta("prop", true)
	if _wood == null:
		_wood = StandardMaterial3D.new()
		_wood.albedo_color = Color(0.36, 0.3, 0.24)
		_wood.roughness = 0.95
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.07
	cm.bottom_radius = 0.1
	cm.height = nest_height
	pole.mesh = cm
	pole.material_override = _wood
	pole.position = Vector3(0.0, nest_height * 0.5, 0.0)
	n.add_child(pole)
	if nest_style == "scrape":
		var tray := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.6, 0.06, 0.5)
		tray.mesh = bm
		tray.material_override = _wood
		tray.position = Vector3(0.0, nest_height, 0.0)
		n.add_child(tray)
		var gravel := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.54, 0.008, 0.44)
		gravel.mesh = gm
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.58, 0.54, 0.48)
		gmat.roughness = 1.0
		gravel.material_override = gmat
		gravel.position = Vector3(0.0, nest_height + 0.032, 0.0)
		n.add_child(gravel)
	else:
		# a platform of sticks, crisscrossed, a cup in the middle
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var stick := CylinderMesh.new()
		stick.top_radius = 0.007
		stick.bottom_radius = 0.009
		stick.height = 1.0
		stick.radial_segments = 5
		stick.rings = 1
		var sa := stick.get_mesh_arrays()
		for k in 70:
			var a := rng.randf() * TAU
			var r := rng.randf_range(0.04, 0.26)
			var c := Vector3(cos(a) * r, rng.randf_range(0.0, 0.08) + (0.04 if r > 0.15 else 0.0), sin(a) * r)
			var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, PI * 0.5 + rng.randf_range(-0.25, 0.25)) * Basis.from_scale(Vector3(1.0, rng.randf_range(0.3, 0.6), 1.0))
			var vs: PackedVector3Array = sa[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = sa[Mesh.ARRAY_NORMAL]
			for i: int in sa[Mesh.ARRAY_INDEX]:
				st.set_normal((b * ns[i]).normalized())
				st.set_color(Color(0.33, 0.27, 0.2).lerp(Color(0.5, 0.43, 0.34), rng.randf()))
				st.add_vertex(b * vs[i] + c)
		var nm := MeshInstance3D.new()
		nm.mesh = st.commit()
		var sm := StandardMaterial3D.new()
		sm.vertex_color_use_as_albedo = true
		sm.roughness = 0.95
		nm.material_override = sm
		nm.position = Vector3(0.0, nest_height - 0.04, 0.0)
		n.add_child(nm)
	return n


static var _egg_mats := {}


func _make_egg() -> Node3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = egg_size.y * 0.5
	sm.height = egg_size.x
	sm.radial_segments = 14
	sm.rings = 8
	mi.mesh = sm
	var key := "%s" % [egg_colors]
	if not _egg_mats.has(key):
		var sh := Shader.new()
		sh.code = """shader_type spatial;
uniform vec3 ground : source_color;
uniform vec3 blotch : source_color;
varying vec3 p;
float hash(vec3 q) { return fract(sin(dot(q, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 q) { vec3 i = floor(q); vec3 f = fract(q); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z); }
void vertex() { p = VERTEX; VERTEX.xz *= 1.0 - 0.15 * smoothstep(0.0, 0.03, VERTEX.y); }
void fragment() {
	float n = noise(p * 160.0) * 0.6 + noise(p * 420.0) * 0.4;
	float b = smoothstep(0.5, 0.62, n);
	ALBEDO = mix(ground, blotch, b * float(length(blotch - ground) > 0.05));
	ROUGHNESS = 0.55;
}"""
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("ground", egg_colors[0])
		m.set_shader_parameter("blotch", egg_colors[1])
		_egg_mats[key] = m
	mi.material_override = _egg_mats[key]
	return mi


# --- steering (pilot.gd) ----------------------------------------------------------

func _p_mobile() -> bool:
	return not dead and not _air and not young


func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["hunt", "perch", "soar", "preen", "rouse", "sleep", "call", "fly", "lay"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"hunt":
			var p: Variant = args.get("prey")
			if p == null:
				p = _find_prey()
			if p == null:
				return false
			hunt(p)
		"perch":
			perch_on(args.get("at", home_perch if home_perch != Vector3.INF else _pos))
		"soar":
			soar(float(args.get("seconds", 30.0)))
		"preen":
			preen(float(args.get("seconds", 10.0)))
		"rouse":
			rouse()
		"sleep":
			sleep()
		"call":
			call_out(float(args.get("seconds", 3.0)))
		"fly":
			fly(args.get("at", _pos + _fwd() * 15.0))
		"lay":
			if male or young or juvenile:
				return false
			lay()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"sleep":
			return false
		"lay":
			return _mode == "incubate"
	return _mode == "perch" and not _air


## (The render tests': a pose by name.)
func test_mode(mode: String) -> void:
	for m: String in ["preen", "rouse", "sleep", "soar", "die"]:
		if mode.contains(m):
			call(m)
	if mode.contains("call"):
		call_out(30.0)
	if mode.contains("fly"):
		fly(_pos + _fwd() * 25.0)
	if mode.contains("mantle") or mode.contains("eat"):
		_carry = _make_carry("mammal", 0.09, Color(0.45, 0.37, 0.28))
		_carry_left = 1.0
		add_child(_carry)
		_to("mantle" if mode.contains("mantle") else "eat")
		_mt = -60.0
