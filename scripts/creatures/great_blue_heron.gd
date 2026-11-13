class_name GreatBlueHeron
extends "res://scripts/creatures/thrush.gd"
## A great blue heron (Ardea herodias), life size: standing 1.2 m tall, 1.3
## m long with its bill, 1.9 m across its wings, 2.5 kg. The bird's make
## (Bird, Raptor's nesting, its young), its own body: slim and deep keeled,
## carried a little tipped up at the breast; its neck very long, in an S,
## its sixth vertebra hinged for the strike; its head long, its bill a
## straight yellow dagger, 13 cm; its legs long, bare far up the shin, its
## toes long and spread; its wings broad, deep fingered; its tail short.
##
## Blue grey above, its wings' flight feathers black; its face and crown
## white, a broad black stripe from over its eye back to the black plumes
## off the back of its head; its neck pale grey, its front white streaked
## black; long pale plumes hanging from the base of its neck over its
## breast, more down its back over its wings; a black and chestnut patch
## at the bend of its wing; its thighs chestnut; its belly streaked black
## and white; its bill yellow, darker along its ridge; its eye yellow; its
## lores bare, blue green; its legs grey brown.
##
## Its ways (it lives by its water: water_y its surface, pond where it is):
## - fishing (forage): wading the shallows, slowly, a step and a long
##   wait; still, its neck drawn back in an S, its eye on the water. What's
##   near (a fish of a school or of the mollies in its water, a frog, a
##   crayfish, a mouse on the bank): crouched, leaning, its neck drawn in
##   further; then the strike, its neck shot out, its bill into the water
##   (taken only with its bill on it; often missed); the fish held
##   crosswise, its head shaken, turned and swallowed head first, its neck
##   working. With young: swallowed all the same, brought up at the nest
## - its croak (call_out): frahnk, its neck up, its bill open
## - its threat (threaten): its wings spread and drooped, its plumes up, its
##   neck drawn back then stretched up, its bill open
## - flying (fly, fly_off): a couple of jumps, its legs pushing, its wings
##   beating; up, its neck folded back in an S into its shoulders, its legs
##   trailing straight out behind, its wings bowed, beating slow and deep;
##   a glide; down, its legs swung forward, its wings braking; a croak on
##   take-off
## - courting (mate): his stretch display, his bill pointed up, his neck
##   stretched, then bowed and his bill snapped shut; then on her back
## - nesting (lay): a broad platform of sticks high in a tree (its site the
##   world's); three to five pale blue eggs; its young fed fish brought up
##   on the nest floor, a nestling's bill clamped on its parent's first
## - preening, its plumes combed; asleep on one leg, its head sunk on its
##   shoulders; sunning, its wings spread and drooped

var water_y := 0.0 ## (its water's surface)
var pond := Rect2() ## (where its water is: x, z)
var wade_depth := 0.3 ## (how deep it'll wade, m)
var crop := 0 ## (fish swallowed, for its young)
var caught := 0 ## (taken, in all)
var _school: Node3D # (the school (or mollies) a fish of which it's after)
var _fish_i := -1
var _wait_at := Vector3.INF
var _fish: Node3D # (in its bill)
var _shake := 0.0
var _miss := 0
var _young_bill := 0.0


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.08
	body_k = 1.6
	stand_pitch = 0.0
	flight_pitch = 0.32
	tail_rest = -0.75
	fold_pitch = -0.05
	feather_cm = 3.0
	walks = true
	cruise = 9.0
	top_speed = 13.0
	flaps_glide = true
	nest_style = "sticks"
	site_style = "fork"
	nest_height = 4.0
	nest_scale = 1.15
	clutch = 4
	egg_size = Vector2(0.064, 0.045)
	egg_colors = [Color(0.64, 0.8, 0.8), Color(0.64, 0.8, 0.8)]
	eyas_scale = 0.8
	grow_secs = 260.0
	song_notes = 1
	song_hz = 1.0


func mass_of() -> Vector3:
	return Vector3(2.5, 1.9, 0.53) if male else Vector3(2.2, 1.8, 0.5)


func _shape() -> Dictionary:
	return {
		"tilt_rings": false,
		"face_taper": true, "eye_c": 4.62,
		"spine": [[62.0, 36.0, 1.4, 0.9, 0.0], [63.0, 31.0, 5.5, 4.5, 0.0], [65.0, 22.0, 10.0, 9.0, 0.0], [68.0, 11.0, 11.5, 11.0, 0.0], [71.0, 0.0, 11.5, 11.5, 0.0],
				[74.0, -8.0, 10.0, 10.5, 0.1], [78.0, -14.0, 7.5, 8.0, 0.4], [84.0, -17.0, 5.4, 5.8, 0.9], [91.0, -17.0, 4.3, 4.6, 1.5], [98.0, -14.0, 3.6, 3.8, 2.1],
				[105.0, -10.0, 3.2, 3.4, 2.7], [112.0, -9.5, 3.0, 3.2, 3.3], [118.0, -13.0, 2.9, 3.1, 3.9], [121.0, -19.0, 2.8, 3.0, 4.4], [121.0, -25.0, 2.6, 2.8, 4.62],
				[120.4, -29.0, 1.9, 2.0, 4.85], [119.8, -31.5, 1.1, 1.3, 5.0], [119.4, -36.0, 0.9, 1.0, 5.35], [119.0, -40.0, 0.6, 0.68, 5.65], [118.6, -44.0, 0.25, 0.28, 5.9],
				[118.4, -45.5, 0.05, 0.05, 6.0]],
		"pivot": Vector3(0.0, 69.0, 4.0),
		"jaw": Vector3(0.0, 119.0, -31.0),
		"lower_bill": [[118.95, -32.0, 0.9], [118.55, -38.0, 0.55], [118.25, -44.5, 0.12]],
		"eye": Vector3(2.1, 121.6, -27.0), "eye_r": 0.55,
		"hip": Vector3(7.0, 66.0, 8.0), "knee": Vector3(7.5, 57.0, 2.0), "ankle": Vector3(6.5, 31.0, 6.0), "foot": Vector3(6.0, 1.5, 0.0),
		"thigh_r": [4.2, 1.9], "shin_feathered": 0.3, "leg_r": 0.75, "leg_part": 8.0, "toes": [10.0, 8.0, 7.5], "claw": 0.15, "claw_r": 0.4,
		"tuck": Vector3(0.0, -0.04, 0.6), # (in flight its legs straight out behind)
		"tail": Vector3(0.0, 62.0, 32.0),
		"shoulder": Vector3(11.0, 77.0, -5.0), "wing": Vector3(20.0, 24.0, 15.0), "coverts": [10.0, 17.0, 14.0, 7.0],
		"fold_fan": Vector3(0.1, 0.15, 0.0), "fold_tuck": 0.45, "fold_tuck_front": 0.5, "fold_chord": 0.15, "wing_thick": [3.0, 2.2, 1.4, 0.6],
		"primaries": [26.0, 28.0, 30.0, 32.0, 34.0, 35.0, 35.0, 34.0, 32.0, 29.0],
		"secondaries": [19, 24.0, 22.0], "tertials": [4, 22.0, 18.0], "feather_w": 6.5,
		"tail_feathers": [12, 14.0, 4.5], "tail_coverts": [[10, 12.0, 4.0, 0.5, 0.9]], "tail_grad": 0.1,
		"plumes": [[Vector3(0.0, 82.0, -15.5), Vector3(0.0, -1.0, -0.25), 22.0, 22, 1, 7.0], # (its breast's, off the base of its neck)
				[Vector3(0.0, 121.5, -19.0), Vector3(0.0, -0.25, 1.0), 15.0, 3, 5, 0.8], # (off the back of its head: black)
				[Vector3(0.0, 80.0, 4.0), Vector3(0.0, -0.25, 1.0), 28.0, 16, 0, 12.0]], # (its back's, over its wings)
	}


func _plumage(stage: String, _male: bool) -> Dictionary:
	var juv := stage == "juvenile"
	var grey := Color(0.45, 0.5, 0.58)
	return {
		"back_color": grey, "back_edge": grey.lightened(0.12), "back_bar": grey.darkened(0.2), "back_bars": 0.0, "back_from": 0.28, "back_from_hi": 0.2,
		"cap_color": Color(0.05, 0.05, 0.06) if not juv else Color(0.12, 0.12, 0.13), "hood_low": -0.004, "hood_nape": 0.0, "cap_back": 1.0, "cap_lore": 0.0,
		"cheek": 1.0, "cheek_color": Color(0.94, 0.94, 0.92), "malar": 0.0,
		"nape_color": Color(0.6, 0.6, 0.64), "nape_iris": Color(0.6, 0.6, 0.64, 0.0), "nape_u": 0.18,
		"under_color": Color(0.5, 0.52, 0.58), "breast_wash": Color(0.66, 0.66, 0.69), "wash_from": 0.12, "wash_to": 0.9,
		"under_mark": Color(0.08, 0.08, 0.09), "under_pattern": 3, "throat_clean": 0.2, "mark_from": -0.5,
		"throat_color": Color(0.93, 0.93, 0.92, 1.0), "throat_from": 0.2, "throat_streak": 0.55,
		"patch_color": Color(0.06, 0.06, 0.07, 1.0 if not juv else 0.0), "patch_edge": Color(0.55, 0.3, 0.18, 1.0),
		"fl_top": Color(0.4, 0.44, 0.52), "fl_pale": Color(0.42, 0.45, 0.5), "fl_dark": Color(0.12, 0.12, 0.13), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"fl_prim_dark": 0.9, "fl_edge": Color(0.0, 0.0, 0.0, 0.0),
		"tail_color": grey.darkened(0.1), "tail_band": grey, "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": grey, "tail_tip_w": 0.0, "tail_under": 0.2,
		"cere_color": Color(0.42, 0.56, 0.55), "bill_color": Color(0.86, 0.68, 0.24) if not juv else Color(0.45, 0.42, 0.32), "bill_tip": Color(0.62, 0.5, 0.22),
		"iris": Color(0.95, 0.84, 0.18), "leg_color": Color(0.36, 0.31, 0.26), "down_white": Color(0.62, 0.62, 0.64), "gape": Color(0.85, 0.75, 0.5),
		"young_legs": Color(0.45, 0.42, 0.36), "lid_color": Color(0.42, 0.56, 0.55),
		"trouser": Color(0.56, 0.34, 0.22, 1.0),
		"plume_color": Color(0.82, 0.83, 0.85), "plume_dark": Color(0.04, 0.04, 0.05),
	}


func _build() -> void:
	super()
	walk_speed = 0.3
	run_speed = 1.6
	if _mat and not young: # (the black and chestnut patch at the bend of its folded wing)
		var sh: Vector3 = (shape.shoulder as Vector3) * 0.01
		_mat.set_shader_parameter("patch_at", sh + Vector3(0.0, -0.04, 0.03))
		_mat.set_shader_parameter("patch_r", Vector2(0.045, 0.035))


# --- its water -----------------------------------------------------------------------------

func _floor_depth(x: float, z: float) -> float:
	return water_y - super._ground(x, z)


func _wadeable(x: float, z: float) -> bool:
	return _floor_depth(x, z) < wade_depth


func in_water() -> bool:
	return not _air and _floor_depth(_pos.x, _pos.z) > 0.01


## A spot in its shallows (or on the bank's edge) near p.
func _shallows_near(p: Vector3) -> Vector3:
	var best := Vector3.INF
	var bd := INF
	for k in 40:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.0, 2.5)
		var q := p + Vector3(cos(a), 0.0, sin(a)) * r
		var d := _floor_depth(q.x, q.z)
		if d > 0.06 and d < wade_depth * 0.85 and q.distance_to(p) < bd:
			bd = q.distance_to(p)
			best = q
	if best == Vector3.INF:
		return Vector3(p.x, super._ground(p.x, p.z), p.z)
	return Vector3(best.x, super._ground(best.x, best.z), best.z)


# --- fishing -------------------------------------------------------------------------------

func _meal_kinds() -> Array:
	return []


## Wading its shallows, stalking, waiting; what's near struck at.
func forage() -> void:
	if young or dead:
		return
	if _air or perch_at != Vector3.INF:
		var to := _shallows_near(_pos if not pond.has_area() else Vector3(pond.get_center().x, 0.0, pond.get_center().y))
		_to("fly")
		_take_off("go", to, true)
		return
	_to("fish", "stalk")


## (What it'd go for, in reach of its strike: a fish of a school or of the
## mollies in its water, near the surface; a frog, a crayfish, a mouse.)
func _target_near(reach: float) -> Dictionary:
	var best := {}
	var bd := INF
	var diet := Diet.of(self)
	for o in get_parent().get_children():
		if not (o is Node3D) or o == self:
			continue
		var k := Diet.kind_of(o)
		if k == "" or not diet.has(k):
			continue
		if o.has_method("nearest") and o.has_method("take") and o.get("pos") is PackedVector3Array: # (a school: its nearest fish)
			var i: int = o.call("nearest", _pos)
			if i < 0:
				continue
			var fp: Vector3 = (o as Node3D).transform * (o.get("pos") as PackedVector3Array)[i]
			var hd := Vector2(fp.x - _pos.x, fp.z - _pos.z).length()
			if hd < reach and fp.y > water_y - 0.22 and hd / Diet.affinity(self, k) < bd:
				bd = hd / Diet.affinity(self, k)
				best = {"school": o, "i": i}
		elif not (o.get("dead") == true) and not o.has_meta("hunted"):
			var op := Diet._at(o as Node3D)
			var hd2 := Vector2(op.x - _pos.x, op.z - _pos.z).length()
			if hd2 < reach and op.y > water_y - 0.2 and hd2 / Diet.affinity(self, k) < bd:
				bd = hd2 / Diet.affinity(self, k)
				best = {"prey": o}
	return best


func _target_pos() -> Vector3:
	if _school and is_instance_valid(_school) and _fish_i >= 0:
		return (_school as Node3D).transform * (_school.get("pos") as PackedVector3Array)[_fish_i]
	if _prey and is_instance_valid(_prey):
		return Diet._at(_prey) + Vector3(0.0, Thrush._mid_y(_prey), 0.0)
	return Vector3.INF


## (A creature, or a school of fish: hunted, struck at.)
func hunt(prey: Node3D) -> void:
	if young or dead or prey == null or not is_instance_valid(prey):
		return
	if prey.has_method("take") and prey.has_method("nearest"):
		_school = prey
		_fish_i = prey.call("nearest", _pos)
		_prey = null
	else:
		_prey = prey
		_school = null
		prey.set_meta("hunted", self)
	var tp := _target_pos()
	if tp == Vector3.INF:
		return
	var to := Vector3(tp.x - _pos.x, 0.0, tp.z - _pos.z)
	var stand := tp - to.normalized() * 0.45
	stand = _shallows_near(stand) if pond.has_area() and not _wadeable(stand.x, stand.z) else Vector3(stand.x, super._ground(stand.x, stand.z), stand.z)
	_to("fish", "approach")
	walk_to(stand, walk_speed)


func _fish_step(dt: float) -> void:
	hunger = minf(hunger + dt / 200.0, 1.0)
	var bk := 1.0
	match _sub:
		"stalk": # (a slow step or two through the shallows, its neck out, peering)
			head_point = Vector3.INF
			want.pitch = 0.15
			head_want = Vector3(0.0, -0.08, -0.1) * bk
			want.head_pitch = 0.25
			if _wait_at == Vector3.INF or arrived():
				if _wait_at != Vector3.INF:
					_sub = "wait"
					_st = 0.0
					_wait_at = Vector3.INF
					return
				var a := _yaw + rng.randf_range(-0.8, 0.8)
				var q := _pos + Vector3(-sin(a), 0.0, -cos(a)) * rng.randf_range(0.3, 0.9)
				var seen := _target_near(4.0) # (fish seen further off: a step or two toward them)
				if not seen.is_empty():
					var sp: Vector3 = (seen.school as Node3D).transform * (seen.school.get("pos") as PackedVector3Array)[int(seen.i)] if seen.has("school") else Diet._at(seen.prey)
					var tw := Vector3(sp.x - _pos.x, 0.0, sp.z - _pos.z)
					q = _pos + tw.normalized() * minf(tw.length() - 0.45, rng.randf_range(0.4, 0.9))
				_wait_at = _shallows_near(q) if pond.has_area() else Vector3(q.x, super._ground(q.x, q.z), q.z)
				walk_to(_wait_at, walk_speed * 0.6)
			var t := _target_near(0.75)
			if not t.is_empty():
				_aim(t)
		"wait": # (still: its neck drawn back in an S, its bill tipped down, watching)
			halt()
			want.pitch = 0.1
			head_want = Vector3(0.0, -0.16, 0.05) * bk
			want.head_pitch = 0.35
			look_yaw = 0.25 * sin(_st * 0.4)
			var t2 := _target_near(0.75)
			if not t2.is_empty():
				_aim(t2)
				return
			if _st > rng.randf_range(5.0, 9.0):
				_sub = "stalk"
				_st = 0.0
				if rng.randf() < 0.1:
					call_out(2.0)
				elif rng.randf() < 0.12:
					preen(rng.randf_range(4.0, 8.0))
		"approach":
			head_point = Vector3.INF
			want.pitch = 0.15
			head_want = Vector3(0.0, -0.1, -0.08) * bk
			if arrived() or _st > 10.0:
				_sub = "crouch"
				_st = 0.0
		"crouch": # (leaning toward it, crouched, its neck drawn in further: coiled)
			halt()
			var tp := _target_pos()
			if tp == Vector3.INF:
				_lost()
				return
			turn_to(tp - _pos)
			want.pitch = 0.5
			want.crouch = 0.3
			rate["pitch"] = 4.0
			var back := Vector3(tp.x - _pos.x, 0.0, tp.z - _pos.z).normalized()
			var coil := Vector3(_pos.x, 0.0, _pos.z) + back * 0.4 # (its head drawn back over its breast, its bill aimed down at it: the neck coiled)
			coil.y = maxf(tp.y, water_y) + 0.55
			head_point = get_parent().to_global(coil)
			want.head_pitch = 0.6
			head_rate = 5.0
			if _st > 0.8:
				_sub = "strike"
				_st = 0.0
				if _school and is_instance_valid(_school) and _school.has_method("scatter") and rng.randf() < 0.4: # (the fish startled as it strikes: off)
					_school.call("scatter", _pos)
		"strike": # (its neck shot out, its bill at it, into the water)
			var tp2 := _target_pos()
			if tp2 == Vector3.INF:
				_lost()
				return
			want.pitch = 0.95
			want.crouch = 0.45
			rate["pitch"] = 18.0
			want.head_pitch = 1.2
			head_rate = 40.0
			head_point = get_parent().to_global(tp2)
			want.jaw = 0.12
			rate["jaw"] = 30.0
			if bill_tip().distance_to(get_parent().to_global(tp2)) < 0.025: # (its bill on it: taken)
				_take_it()
			elif _st > 0.45: # (missed)
				head_point = Vector3.INF
				_miss += 1
				_lost()
		"hold": # (held crosswise, its head shaken; turned; swallowed head first, its neck working)
			head_point = Vector3.INF
			want.pitch = 0.2
			want.crouch = 0.0
			rate["pitch"] = 4.0
			head_want = Vector3(0.0, -0.05, -0.05) * bk
			want.head_pitch = -0.2 if _st < 1.4 else -0.75
			look_yaw = 0.35 * sin(_st * 22.0) if _st < 1.0 else 0.0
			want.jaw = 0.25 if _st < 1.4 else 0.4
			if _st > 2.2:
				_swallow_it()


func _aim(t: Dictionary) -> void:
	if t.has("school"):
		_school = t.school
		_fish_i = t.i
		_prey = null
	else:
		_prey = t.prey
		_school = null
		_prey.set_meta("hunted", self)
	_sub = "crouch"
	_st = 0.0


func _lost() -> void:
	if _prey and is_instance_valid(_prey):
		_prey.remove_meta("hunted")
	_prey = null
	_school = null
	_fish_i = -1
	head_point = Vector3.INF
	_sub = "wait"
	_st = 0.0


func _take_it() -> void:
	var f: Node3D = null
	if _school and is_instance_valid(_school):
		f = _school.call("take", _fish_i)
		_school = null
		_fish_i = -1
	elif _prey and is_instance_valid(_prey):
		Meal.subdue(_prey)
		f = _prey
		_prey = null
	if f == null:
		_lost()
		return
	var sc := f.global_transform.basis.get_scale()
	var holder := Node3D.new()
	add_child(holder)
	f.reparent(holder, false)
	f.transform = Transform3D(Basis(Vector3.UP, PI * 0.5).scaled(sc), Vector3.ZERO) # (crosswise in its bill)
	_fish = holder
	caught += 1
	head_point = Vector3.INF
	_sub = "hold"
	_st = 0.0


func _swallow_it() -> void:
	if _fish and is_instance_valid(_fish):
		_fish.queue_free()
	_fish = null
	hunger = maxf(hunger - 0.35, 0.0)
	want.jaw = 0.0
	if not _live_young().is_empty() and nest_top != Vector3.INF:
		crop += 1
		if crop >= 2: # (to the nest, to bring it up for them)
			_to("fly")
			_take_off("go", nest_top + Vector3(0.25, 0.0, 0.0), true)
			_mode = "to_nest"
			return
	_sub = "wait"
	_st = 0.0


func _hold_fish() -> void:
	if _fish == null or not is_instance_valid(_fish):
		return
	var turned := clampf((_st - 1.2) / 0.4, 0.0, 1.0) if _sub == "hold" else 0.0
	var hb: Basis = global_transform.basis.orthonormalized() * Basis(Vector3.UP, look_yaw)
	_fish.global_transform = Transform3D(hb * Basis(Vector3.UP, PI * 0.5 * turned), bill_tip() - global_transform.basis.orthonormalized() * Vector3(0.0, 0.0, -0.025))


# --- calls, threat ---------------------------------------------------------------------------

func _sing(_dt: float) -> void:
	# frahnk: its neck up, its bill opened wide, once or twice
	head_point = Vector3.INF
	want.head_pitch = -0.3
	head_want = Vector3(0.0, 0.05, 0.0)
	var ph := fmod(_mt, 1.4)
	want.jaw = 0.45 * sin(PI * clampf(ph / 0.5, 0.0, 1.0)) if ph < 0.5 else 0.0
	rate["jaw"] = 25.0
	if _mt > _secs:
		want.jaw = 0.0
		head_want = Vector3.ZERO
		forage()


## At at: its wings spread and drooped, its plumes up, its neck drawn back
## then stretched up and out, its bill open; then back to its fishing.
func threaten(at: Vector3, secs := 6.0) -> void:
	if young or dead or _air:
		return
	_to("threat")
	_secs = secs
	_wait_at = at


func _threat(_dt: float) -> void:
	turn_to(_wait_at - _pos)
	want.puff = 0.9
	set_wings(-0.35, -0.2, 0.2, 0.75) # (spread, drooped)
	want.fold_pitch = 0.0
	want.pitch = -0.15
	var k := clampf((_mt - 0.8) / 0.6, 0.0, 1.0)
	head_want = Vector3(0.0, -0.12 + 0.2 * k, 0.12 - 0.3 * k)
	want.head_pitch = -0.4 * k
	want.jaw = 0.4 * k
	if _mt > _secs:
		want.puff = 0.0
		want.jaw = 0.0
		fold_wings()
		want.fold_pitch = fold_pitch
		head_want = Vector3.ZERO
		_wait_at = Vector3.INF
		forage()


# --- flight: its jumps up, its neck folded, its legs trailing --------------------------------

func fly(to: Vector3) -> void:
	if young or dead:
		return
	_to("fly")
	_beg = 0.6 # (a croak)
	var t := Vector3(to.x, super._ground(to.x, to.z), to.z)
	_take_off("go", _shallows_near(t) if pond.has_area() and pond.grow(1.0).has_point(Vector2(t.x, t.z)) else t, true)


func fly_off(from: Vector3) -> void:
	if young or dead:
		return
	var away := _pos - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else _fwd()
	fly(_pos + away * rng.randf_range(18.0, 26.0))


func _fly_step(dt: float) -> void:
	super(dt)
	if not _air or _fly.is_empty():
		return
	var t := float(_fly.get("t", 0.0))
	var flare := float(want.legs_tuck) < 0.5
	if t < 0.7: # (its jumps up: its legs pushing, dangling)
		want.legs_tuck = smoothstep(0.2, 0.7, t)
		head_want = Vector3(0.0, -0.1, -0.05)
	elif flare: # (down: its neck out a little, its legs swung forward)
		head_want = Vector3(0.0, -0.18, 0.0)
	else: # (its neck folded back in an S into its shoulders)
		head_want = Vector3(0.0, -0.36, 0.1)
	want.head_pitch = -0.1
	_fly["hz"] = BirdFlight.wingbeat_hz(mass, span, wing_area) * 0.8 # (slow, deep)
	beat_amp = 1.15


func _land(at: Vector3) -> void:
	var m := _mode
	super(at)
	head_want = Vector3.ZERO
	if m == "to_nest":
		_to("feed_nest")
	elif m in ["fly", "fish"] and not young:
		forage()


# --- courting --------------------------------------------------------------------------------

func _court(dt: float) -> void:
	# his stretch display: his bill pointed up, his neck stretched up, his
	# plumes raised; then bowed, his bill snapped shut; again
	if _partner == null or not is_instance_valid(_partner):
		perch()
		return
	var to: Vector3 = (_partner.get("_pos") as Vector3) - _pos
	turn_to(to)
	var ph := fmod(_mt, 3.2)
	if ph < 1.6:
		var k := sin(PI * ph / 1.6)
		want.head_pitch = -1.3 * k
		head_want = Vector3(0.0, 0.1 * k, 0.06 * k)
		want.pitch = -0.2 * k
		want.puff = 0.7 * k
		want.jaw = 0.0
	else:
		var k2 := sin(PI * (ph - 1.6) / 1.6)
		want.head_pitch = 0.9 * k2
		head_want = Vector3(0.0, -0.2 * k2, -0.1 * k2)
		want.pitch = 0.4 * k2
		want.puff = 0.3
		want.jaw = 0.3 * maxf(0.0, sin(_mt * 18.0)) # (bill snapped)
	rate["jaw"] = 30.0
	if Vector2(to.x, to.z).length() > 0.7:
		walk_to(_partner.get("_pos"), walk_speed)
	else:
		halt()
	if _mt > _secs:
		want.puff = 0.0
		head_want = Vector3.ZERO
		_to("mount")
		_secs = 4.0


# --- the young ------------------------------------------------------------------------------

func _live_young() -> Array:
	return young_ones.filter(func(y: Variant) -> bool: return is_instance_valid(y) and y.get("young"))




## (At the nest: a nestling's bill clamped crosswise on its own, tugged; then
## the fish brought up onto the nest's floor before it, its bill down to it.)
func _feed_nest(dt: float) -> void:
	var live := _live_young()
	if live.is_empty() or crop <= 0:
		crop = 0
		forage()
		return
	var who: Node3D = live[_fed % live.size()]
	var wp: Vector3 = who.get("_pos")
	turn_to(wp - _pos)
	want.pitch = 0.6
	want.head_pitch = 0.7
	var meet := (bill_tip() + (who.call("bill_tip") as Vector3)) * 0.5
	head_rate = 6.0
	head_point = meet + Vector3(0.0, 0.01 * sin(_mt * 6.0), 0.0) # (tugged)
	who.set("head_point", bill_tip())
	who.set("_beg", 0.5)
	if bill_tip().distance_to(who.call("bill_tip")) < 0.03:
		_young_bill += dt
		if _young_bill > 1.5: # (brought up: fed)
			_young_bill = 0.0
			crop -= 1
			who.set("_age", float(who.get("_age")) + grow_secs * 0.06)
			who.set("head_point", Vector3.INF)
			_fed += 1
			_st = 0.0
	elif _st > 6.0:
		_fed += 1
		_st = 0.0


# --- the rest -------------------------------------------------------------------------------

func _think(dt: float) -> void:
	super(dt)
	if _air or dead or young:
		return
	match _mode:
		"fish":
			_fish_step(dt)
		"threat":
			_threat(dt)
		"feed_nest":
			_feed_nest(dt)
		"sleep": # (on one leg, its head sunk on its shoulders)
			head_want = Vector3(0.0, -0.4, 0.12)
			want.head_pitch = 0.2
			foot_off[1] = Vector3(0.0, 0.25, 0.05)
			want.drop = 0.0


func _watch(_dt: float) -> void:
	if young:
		return
	if perch_at != Vector3.INF and nest_top != Vector3.INF and perch_at.distance_to(nest_top) < 0.5 and not _live_young().is_empty():
		return
	forage()


func _process(dt: float) -> void:
	super(dt)
	_hold_fish()


func _to(mode: String, sub := "") -> void:
	if mode != "fish" and _fish and is_instance_valid(_fish):
		_fish.queue_free()
		_fish = null
	foot_off[0] = Vector3.ZERO
	foot_off[1] = Vector3.ZERO
	super(mode, sub)
	want.pitch = 0.0


func test_mode(mode: String) -> void:
	if mode.contains("wait"):
		_to("fish", "wait")
		_secs = 1e9
		_st = -1e9
	elif mode.contains("strike"):
		_to("fish", "crouch")
	elif mode.contains("threat"):
		threaten(_pos + _fwd() * 2.0, 60.0)
	elif mode.contains("court"):
		_to("court_g")
		_partner = self
		_secs = 60.0
	elif mode.contains("fly"):
		fly(_pos + _fwd() * 60.0)
	else:
		super(mode)
