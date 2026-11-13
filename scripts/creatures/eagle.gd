class_name Eagle
extends "res://scripts/creatures/raptor.gd"
## An eagle: a Raptor twice a hawk's size, heavy billed, its wings long and
## broad, its outer primaries fingers (emarginated: narrowed past a notch,
## spread apart soaring); its legs stout, its talons great. Soaring for
## hours on flat or lifted wings, slow deep beats between. What's its own:
## - fish(school) (a bald eagle's): a fish brought up near the surface, a
##   long low glide down at it, its feet swung forward at the last, the
##   fish snatched out of the water in its talons and carried off, head
##   first, to its perch, and eaten there
## - scavenge(carcass): down beside a dead animal (a Carcass), tearing at it
##   a long while, its wings half mantled over it now and then, looking up
## - calling (call_out): a bald eagle's head thrown back, its bill open,
##   chattering (head_back_call)
## - its nest a great platform of sticks (nest_scale), two eggs, its
##   eaglets grey down, growing to near its size (eyas_scale)
## Hungry, it goes for whatever's near: a fish school (if it fishes), a
## carcass, its prey (Diet).
##
## A species gives eagle_shape() its measures, _plumage() and mass_of().

var fishes := false ## (a bald eagle's)
var head_back_call := false
var _school: Node3D
var _fish_i := -1
var _carrion: Node3D


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	cruise = 12.0
	top_speed = 18.0
	soar_height = 45.0
	flaps_glide = false
	nest_style = "sticks"
	nest_height = 4.2
	nest_scale = 3.0
	eyas_scale = 2.1
	clutch = 2
	grow_secs = 280.0
	beat_amp = 0.8
	tail_rest = -0.95
	flight_pitch = 0.95
	fold_pitch = 0.95
	feather_cm = 5.5


## The body: a Cooper's hawk's lines (cm) made over twice as big, bulkier,
## its legs shorter and stouter, its wings longer and broader, fingered;
## bill and head its size of that (1: as big as the hawk's for the eagle's
## size), tail_len its tail (cm), feathered its legs to the toes (a golden
## eagle's).
func eagle_shape(bill: float, head: float, tail_len: float, feathered: bool) -> Dictionary:
	var K := 2.1
	var B := 1.12
	var legf := 0.74
	var dy := 16.5 * (legf - 1.0)
	var hj := Vector2(36.5, -4.7) # (the hawk's head joint)
	var br := Vector2(35.5, -7.2) # (its bill's root)
	var hawk := [[13.5, 13.0, 1.0, 1.0, 0.0], [14.6, 11.0, 3.6, 3.3, 0.0], [16.2, 8.0, 4.3, 5.5, 0.0], [19.2, 4.8, 4.7, 6.8, 0.0], [23.0, 2.0, 4.9, 7.0, 0.0],
			[27.0, 0.0, 4.6, 6.3, 0.0], [30.0, -1.0, 3.9, 5.0, 0.2], [32.0, -1.5, 3.4, 3.8, 1.0], [33.6, -2.0, 3.0, 3.3, 2.0], [34.9, -2.7, 2.7, 3.0, 3.0],
			[35.9, -3.6, 2.5, 2.8, 4.0], [36.5, -4.7, 2.3, 2.5, 4.5], [36.2, -6.2, 1.9, 2.2, 4.85], [35.5, -7.2, 1.25, 1.55, 5.0],
			[35.1, -7.75, 1.0, 1.2, 5.05], [34.6, -8.4, 0.7, 0.85, 5.5], [33.9, -8.8, 0.32, 0.4, 5.85], [33.2, -8.7, 0.08, 0.08, 6.0]]
	# (a point of the head: about the head joint by head, a point of the bill about its root by bill too)
	var hp := func(y: float, z: float, c: float) -> Vector2:
		var q := Vector2(y, z)
		if c >= 4.5:
			q = hj + (q - hj) * head
		if c >= 5.0:
			var r2 := hj + (br - hj) * head
			q = r2 + (q - r2) * bill
		var n := clampf(c / 4.5, 0.0, 1.0) # (its neck the longer, the head out further)
		return (q + Vector2(1.2 * n, -0.7 * n) + Vector2(dy, 0.0)) * K
	var spine := []
	for e: Array in hawk:
		var c: float = e[4]
		var q: Vector2 = hp.call(e[0], e[1], c)
		var s := (head * (bill if c >= 5.0 else 1.0)) if c >= 4.5 else B
		spine.append([q.x, q.y, float(e[2]) * K * s, float(e[3]) * K * s, c])
	var p3 := func(v: Vector3, c: float) -> Vector3:
		var q: Vector2 = hp.call(v.y, v.z, c)
		var sx := head * (bill if c >= 5.0 else 1.0)
		return Vector3(v.x * K * sx, q.x, q.y)
	var lb := []
	for e: Array in [[34.7, -7.6, 0.75], [34.3, -8.2, 0.5], [34.0, -8.55, 0.14]]:
		var q: Vector2 = hp.call(e[0], e[1], 5.2)
		lb.append([q.x, q.y, float(e[2]) * K * head * bill])
	var S := {
		"tilt_rings": true,
		"spine": spine,
		"pivot": Vector3(0.0, (20.0 + dy) * K, 4.0 * K),
		"jaw": p3.call(Vector3(0.0, 34.8, -7.3), 5.2),
		"lower_bill": lb,
		"eye": p3.call(Vector3(1.85, 36.3, -5.6), 4.6), "eye_r": 0.62 * K * 0.85 * head,
		"brow": [p3.call(Vector3(1.6, 36.9, -5.8), 4.6), Vector3(0.8, 0.36, 1.15) * K * head],
		"cere": [p3.call(Vector3(0.0, 35.8, -7.1), 5.1), Vector3(1.0, 0.75, 0.6) * K * head * bill],
		# (its legs short and stout: its trousers full; the tarsus bare, or feathered to its toes)
		"hip": Vector3(2.9 * B, 16.5 * legf, 4.0) * K, "knee": Vector3(3.3 * B, 12.5 * legf, 0.5) * K, "ankle": Vector3(2.9 * B, 6.5 * legf, 1.5) * K, "foot": Vector3(2.9 * B, 1.2, 0.0) * K,
		"thigh_r": [3.6 * K * B * 1.15, 2.4 * K * B * 1.25], "leg_r": 0.42 * K * 1.4 * (1.25 if feathered else 1.0), "toes": [4.6 * K * 0.95, 3.3 * K * 0.95, 2.6 * K * 0.95], "claw": 0.42, "claw_r": 0.62,
		"tuck": Vector3(0.0, -0.05, 0.0),
		"tail": Vector3(0.0, 14.0 + dy, 12.0) * K,
		"shoulder": Vector3(5.0 * B, 25.5 + dy, 4.6) * K, "wing": Vector3(7.5, 9.0, 6.0) * K * 1.1, "coverts": [3.0 * K * 1.3, 11.0 * K * 1.2, 8.0 * K * 1.2, 3.0 * K * 1.15], # (its coverts deep: half the arm's chord)
		"fold_fan": Vector3(0.3, 0.4, 0.08), "fold_tuck": 0.12, "fold_tuck_front": 3.0, "wing_thick": [1.7 * K, 1.5 * K, 1.0 * K, 0.4 * K], # (the coverts lying thick over the flight feathers' bases)
		"primaries": [12.0, 13.0, 14.5, 15.5, 16.5, 17.5, 18.0, 17.5, 16.5, 14.5].map(func(x: float) -> float: return x * K * 1.1), "fingers": 6,
		"secondaries": [13, 14.0 * K * 1.2, 12.5 * K * 1.2], "tertials": [3, 11.0 * K * 1.1, 9.0 * K * 1.1], "feather_w": 4.4 * K * 1.25,
		"tail_feathers": [12, tail_len, 4.0 * K * 1.15], "tail_coverts": [[10, 8.0 * K, 3.5 * K, 0.5, 0.9]],
	}
	if feathered:
		S["leg_part"] = 7.0
	return S


# --- fishing ---------------------------------------------------------------------------

## A fish of `school` (a FishSchool): brought up, snatched from the surface.
func fish(school: Node3D) -> void:
	if young or dead or school == null or not is_instance_valid(school):
		return
	var i: int = school.call("nearest", _pos)
	if i < 0:
		return
	_drop_carry() # (whatever it had, dropped)
	_school = school
	_fish_i = i
	school.call("rise", i)
	_prey = null
	_to("hunt")
	_take_off("snatch", _fish_pos(), false)


func _fish_pos() -> Vector3:
	var ps: PackedVector3Array = _school.get("pos")
	return (_school as Node3D).transform * ps[_fish_i]


func _fly_step(dt: float) -> void:
	if String(_fly.get("kind", "")) != "snatch":
		super(dt)
		return
	if _school == null or not is_instance_valid(_school):
		_give_up()
		return
	var fp := _fish_pos()
	var d := fp - _pos
	var hd := Vector2(d.x, d.z).length()
	# (a long low glide down at it, the last of it skimming)
	_fly.to = fp + Vector3(0.0, clampf(hd * 0.12, 0.0, 5.0) + 0.06, 0.0)
	super(dt)
	if hd < 7.0: # (its feet swung forward, talons open; wings up, braking)
		want.legs_tuck = 0.0
		air_foot = Vector3(0.0, 0.26, -0.08)
		talon_open = 1.0
		want.tail_spread = 0.9
		set_wings(0.4, 0.0, 0.3, 1.0)
		_flap = 0.0
	if hd < 0.45 and _pos.y < fp.y + 0.45:
		_snatch()
	elif float(_fly.t) > 20.0:
		_give_up()


func _snatch() -> void:
	var f: Node3D = _school.call("take", _fish_i)
	var sc := f.global_transform.basis.get_scale().x
	_school = null
	var holder := Node3D.new()
	add_child(holder)
	f.reparent(holder, false)
	f.transform = Transform3D(Basis.from_scale(Vector3.ONE * sc), Vector3(0.0, -0.03, 0.0)) # (head first, as it carries it)
	_carry = holder
	_carry_kind = "fish"
	_carry_left = 1.0
	hunger = 0.0
	_call()
	var home := nest_top if not young_ones.is_empty() and nest_top != Vector3.INF else home_perch
	if home == Vector3.INF:
		var a := rng.randf() * TAU
		home = _pos + Vector3(cos(a), 0.0, sin(a)) * 12.0
		home.y = super._ground(home.x, home.z)
	_mode = "carrying"
	_fly.kind = "carry"
	_fly.to = home
	_fly.land = true
	_fly.t = 0.0


# --- carrion ---------------------------------------------------------------------------

## Down beside a carcass (a dead animal: Carcass), eating at it.
func scavenge(carcass: Node3D) -> void:
	if young or dead or carcass == null or not is_instance_valid(carcass):
		return
	_drop_carry() # (whatever it had, dropped)
	_carrion = carcass
	var c := carcass.position
	var a := rng.randf() * TAU
	var at := c + Vector3(cos(a), 0.0, sin(a)) * 0.8
	at.y = super._ground(at.x, at.z)
	_to("carrion")
	if _air:
		_fly.kind = "go"
		_fly.to = at
		_fly.land = true
	else:
		_take_off("go", at, true)


func _land(at: Vector3) -> void:
	var m := _mode
	super(at)
	if m == "carrion" and _carrion != null and is_instance_valid(_carrion):
		_to("carrion")
		_secs = rng.randf_range(25.0, 40.0)
		var to := _carrion.position - _pos
		turn_to(Vector3(to.x, 0.0, to.z))


func _think(dt: float) -> void:
	super(dt)
	if _air or dead:
		return
	match _mode:
		"call":
			if head_back_call: # (its head thrown back, bill open, chattering)
				want.head_pitch = -1.1
				head_want = Vector3(0.0, 0.03, 0.05) * size
				want.jaw = 0.25 + 0.3 * maxf(0.0, sin(_mt * 26.0))
				want.puff = 0.3
		"carrion":
			if _carrion == null or not is_instance_valid(_carrion):
				perch()
				return
			var ph := fmod(_mt, 1.6) / 1.6
			want.pitch = 0.7
			want.tail_up = tail_rest + 0.5
			head_rate = 12.0
			if ph < 0.5: # (down to it, tearing)
				want.head_pitch = 1.1
				head_want = Vector3(0.02 * sin(_mt * 7.0), -0.18, -0.12) * size
				want.jaw = 0.3 * float(ph > 0.3)
			else: # (up, swallowing, looking round)
				want.head_pitch = -0.1
				head_want = Vector3.ZERO
				want.jaw = 0.0
				look_yaw = 0.7 * sin(_mt * 0.7)
			if fmod(_mt, 12.0) > 10.0: # (mantling over it a moment: its own)
				set_wings(-0.55, -0.2, 0.35, 0.8)
				want.puff = 0.5
			else:
				fold_wings()
				want.puff = 0.0
			if _mt > _secs:
				hunger = 0.0
				_carrion = null
				if home_perch != Vector3.INF:
					perch_on(home_perch)
				else:
					perch()


## Hungry: whatever of its diet's here (Diet: a fish school with fish in it,
## a carcass, its prey; the best by how near and how much it likes each).
func _find_prey() -> Node3D:
	var kinds := Diet.of(self)
	var f := Diet.find(self, 60.0, kinds)
	if f and f.has_method("nearest") and int(f.call("nearest", _pos)) < 0: # (a school with no fish left in it: the rest)
		f = Diet.find(self, 60.0, kinds.filter(func(k: String) -> bool: return k != "fish"))
	return f as Node3D if f != self else null


func hunt(prey: Node3D) -> void:
	if prey != null and is_instance_valid(prey):
		if prey.get_script() != null and (prey.get_script() as Script).resource_path.get_file() == "fish_school.gd":
			fish(prey)
			return
		if prey.has_meta("carcass"):
			scavenge(prey)
			return
	super(prey)
