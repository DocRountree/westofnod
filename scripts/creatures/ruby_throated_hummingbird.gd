class_name RubyThroatedHummingbird
extends "res://scripts/creatures/thrush.gd"
## A ruby-throated hummingbird (Archilochus colubris), life size: 9 cm long
## with its bill, 10.5 cm across, 3.2 g; the female a little bigger. The
## songbird's make (Thrush: perching, nesting, its young raised) made tiny:
## its bill a long straight needle, its legs and feet small (it can perch,
## not walk), its wings long narrow blades (a short arm, a long hand), its
## tail forked (his) or rounded (hers).
##
## The male: his back and crown a glittering emerald green; his throat (the
## gorget) ruby red where it faces you, near black aside; black under his
## eye, a white collar below the gorget; grey white beneath, his flanks
## green; his wings dusky; his tail forked, dark. The female: green above,
## her throat and underparts whitish, her flanks buff; her tail rounded,
## its outer feathers banded black and tipped white.
##
## Its ways:
## - hovering (its own flight: hover_at): its body tipped up, its wings
##   beating some fifty times a second, their stroke a flat figure eight
##   (forward, back) before it; held where it means to be, its bill where it
##   means it; backing away; darting off fast
## - forage(): to the flowers that are here (their florets, heads), each
##   in turn: hovering before it, its bill in it (taken only with its bill
##   in the flower), its tongue licking in and out, a second or two, backing
##   off, to the next; swaying with the flower in the wind as it feeds
## - hawking: a small flying insect that's near (Diet's flier) darted at,
##   snapped up in its bill, swallowed
## - perching on a twig, upright, its tail flicked; preening
## - a male's: another male here chased off (display(rival)); for a female
##   (mate): his pendulum dives, a wide U swung back and forth before her,
##   then his shuttle, quick short arcs side to side close before her, his
##   gorget flared to her; then on her back, a moment
## - nesting (lay, hers alone): a tiny cup of plant down and spider silk,
##   lichen outside, saddled on a branch; two white eggs, pea sized; her
##   young fed nectar and insects brought up, her bill deep in each gape
## - torpor at night (sleep): puffed, still, its bill up

var hover_hz := 53.0 ## (its wingbeat, hovering)
var _hov := Vector3.INF # (where it's holding: its bill's tip, or itself)
var _hov_bill := false # (the target its bill's, not its body's)
var _face := Vector3.ZERO # (the way it faces, hovering)
var _flowers: Array = [] # (the plant it's feeding at: [plant, head index])
var _plant: Node3D
var _head := -1
var _sips := 0 ## (florets drunk from, in all)
var _ride := 0.0
var _ride_to := 0.0
var _ride_at := Vector3.ZERO
var _ride_k := 0.0
var _tongue: MeshInstance3D
var _rival: Node3D
var _show_to: Node3D # (his display: to her)
var _path_t := 0.0


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 0.93 # (she the bigger)
	body_k = 0.17
	walks = false
	pounces = false
	flaps_glide = false
	cruise = 11.0
	top_speed = 20.0
	nest_style = "cup"
	site_style = "fork"
	nest_height = 2.2
	nest_scale = 0.12
	clutch = 2
	egg_size = Vector2(0.013, 0.009)
	egg_colors = [Color(0.97, 0.96, 0.93), Color(0.97, 0.96, 0.93)]
	cup_colors = [Color(0.52, 0.58, 0.5), Color(0.9, 0.88, 0.82)] # (lichen; plant down)
	eyas_scale = 0.32
	stand_pitch = -0.1
	fold_pitch = 0.4
	fold_pitch = 0.4
	tail_rest = -0.55
	feather_cm = 0.35
	grow_secs = 120.0
	song_notes = 8
	song_hz = 12.0


func mass_of() -> Vector3:
	return Vector3(0.0032, 0.105, 0.0012) if male else Vector3(0.0036, 0.11, 0.0013)


func _shape() -> Dictionary:
	var S := thrush_shape(0.17, 1.25, 1.0, 1.0, 3.2, 1.0, 1.12, 1.0, -0.3 if male else 0.12)
	# its bill a fine straight needle: each of its rings drawn in, held level
	# from its root; its lower mandible closed up under it
	var bill_rings: Array = S.spine.filter(func(r: Array) -> bool: return float(r[4]) >= 5.0)
	var y0 := float((bill_rings[0] as Array)[0])
	for r: Array in bill_rings:
		var f := float(r[4]) - 5.0
		r[0] = lerpf(float(r[0]), y0, 0.85) - 0.03 * f - 0.12 * f * f # (a touch decurved at its tip)
		r[2] = float(r[2]) * 0.24
		r[3] = float(r[3]) * 0.26
	for r: Array in S.lower_bill:
		var z := float(r[1])
		var up: Array = bill_rings[0]
		for b: Array in bill_rings: # (the upper bill's ring nearest along it)
			if absf(float(b[1]) - z) < absf(float(up[1]) - z):
				up = b
		r[0] = float(up[0]) - float(up[3]) * 1.15
		r[2] = float(r[2]) * 0.24
	S.erase("eye_ring")
	S.eye_r = float(S.eye_r) * 0.85
	# its wings: a short arm, a long hand; its primaries long and stiff, few secondaries
	var k := 0.17
	S.wing = Vector3(3.0, 3.5, 8.5) * k
	S.primaries = [26.0, 27.0, 28.0, 28.5, 29.0, 29.0, 28.5, 28.0, 27.0, 25.0].map(func(x: float) -> float: return x * k)
	S.secondaries = [6, 5.0 * k, 4.5 * k] # (short, under its coverts: its wing nearly all hand)
	S.tertials = [0, 1.0 * k, 1.0 * k]
	S.coverts = [0.9 * k, 1.4 * k, 1.4 * k, 0.7 * k]
	S.wing_thick = [0.45 * k, 0.35 * k, 0.25 * k, 0.12 * k] # (thin: a blade, no box at its shoulder)
	S.fold_chord = 0.0
	S.fold_tuck = 0.3
	S.feather_w = 5.5 * k # (broad, overlapping: one blade)
	S.toes = [2.6 * k, 2.0 * k, 2.0 * k]
	S.leg_r = 0.25 * k
	S.thigh_r = [(S.thigh_r as Array)[0] * 0.3, (S.thigh_r as Array)[1] * 0.3] # (its legs short, tucked in its feathers)
	# (all of it but its feet let down onto them: it sits low, its legs all but hidden)
	var D := 8.0 * k
	for r: Array in S.spine:
		r[0] = float(r[0]) - D
	for r: Array in S.lower_bill:
		r[0] = float(r[0]) - D
	for key: String in ["pivot", "jaw", "eye", "tail", "shoulder", "hip"]:
		S[key] = (S[key] as Vector3) - Vector3(0.0, D, 0.0)
	S.tail_feathers = [10, 2.7, 1.9 * k] # (ten, stacked close: closed, a narrow wedge 1.5 cm across)
	S.tail_coverts = [[8, 1.6 * k, 1.5 * k, 0.2, 0.9]]
	S.tail_k = 0.08
	S.tail_root = 0.003 # (its tail's feathers from the very root of its tail, not out from it: a big bird's)
	S.knee = Vector3((S.knee as Vector3).x, 5.5 * k, (S.knee as Vector3).z)
	S.ankle = Vector3((S.ankle as Vector3).x, 2.8 * k, (S.ankle as Vector3).z)
	return S


func _plumage(stage: String, male_: bool) -> Dictionary:
	var m := male_ and stage != "juvenile"
	var green := Color(0.28, 0.46, 0.24)
	var d := {
		"back_color": green, "back_edge": green.lightened(0.1), "back_bar": green, "back_bars": 0.0, "back_from": 0.32, "back_from_hi": 0.22,
		"iridescence": 1.0, "gorget": 1.0 if m else 0.0,
		"cap_color": green, "hood_low": 0.0, "hood_nape": 1.0, "cheek": 1.0 if m else 0.0, "cheek_color": Color(0.03, 0.03, 0.03), "cap_lore": 0.0, "malar": 0.0,
		"under_color": Color(0.86, 0.86, 0.83) if m else Color(0.9, 0.89, 0.85), "breast_wash": Color(0.6, 0.63, 0.45) if m else Color(0.84, 0.79, 0.68), "wash_from": -0.5, "wash_to": 0.34, "mottle": 0.0,
		"under_mark": Color(0.4, 0.4, 0.4), "under_pattern": 0, "throat_clean": 0.9,
		"throat_color": Color(0.85, 0.07, 0.1, 1.0) if m else Color(0.93, 0.92, 0.88, 0.8), "throat_from": 0.6 if m else 0.66, "throat_streak": 0.0 if m else 0.25,
		"fl_top": Color(0.22, 0.2, 0.22), "fl_pale": Color(0.36, 0.34, 0.36), "fl_dark": Color(0.2, 0.19, 0.21), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"tail_color": Color(0.14, 0.15, 0.13) if m else green, "tail_band": Color(0.06, 0.06, 0.06), "tail_bands": 0.0 if m else 1.0, "tail_band_w": 0.0 if m else 0.25,
		"tail_tip_r": Color(0.14, 0.15, 0.13) if m else Color(0.96, 0.96, 0.94), "tail_tip_w": 0.0 if m else 0.12, "tail_under": 0.1,
		"tail_outer": Color(0.08, 0.08, 0.08, 0.0 if m else 0.6),
		"cere_color": Color(0.05, 0.05, 0.05), "bill_color": Color(0.05, 0.05, 0.05), "bill_tip": Color(0.03, 0.03, 0.03), "iris": Color(0.02, 0.02, 0.02),
		"leg_color": Color(0.1, 0.09, 0.09), "down_white": Color(0.4, 0.38, 0.36), "gape": Color(0.95, 0.85, 0.6), "young_legs": Color(0.3, 0.27, 0.25),
		"lid_color": Color(0.1, 0.1, 0.09), "trouser": Color(0.6, 0.64, 0.56, 1.0) if m else Color(0.82, 0.78, 0.68, 1.0),
	}
	return d


func _build() -> void:
	super()
	_tongue = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0002
	cm.bottom_radius = 0.0003
	cm.height = 1.0
	cm.radial_segments = 5
	cm.rings = 1
	_tongue.mesh = cm
	var tm := ShaderMaterial.new()
	tm.shader = preload("res://shaders/render/seed.gdshader")
	tm.set_shader_parameter("albedo", Color(0.85, 0.6, 0.6))
	_tongue.material_override = tm
	_tongue.visible = false
	add_child.call_deferred(_tongue)


# --- hovering -------------------------------------------------------------------------------

## Hovering at `at` (its parent's space): its bill's tip there (bill), or
## itself; facing `face`.
func hover_at(at: Vector3, face := Vector3.ZERO, bill := false) -> void:
	_hov = at
	_hov_bill = bill
	if face != Vector3.ZERO:
		_face = face
	if not _air:
		_air = true
		perch_at = Vector3.INF
		_vel = Vector3(0.0, 0.6, 0.0)
	_fly = {"kind": "hover", "t": 0.0, "hz": hover_hz, "to": at}


func _hover(dt: float) -> void:
	var f := _fly
	f.t = float(f.get("t", 0.0)) + dt
	var tgt := _hov
	if _hov_bill: # (its body where its bill's tip comes to the mark)
		tgt = _hov - (get_parent().to_local(bill_tip()) - _pos)
	var want_v := (tgt - _pos) * 6.0
	want_v = want_v.limit_length(3.5)
	_vel = _vel.move_toward(want_v, 30.0 * dt)
	_pos += _vel * dt
	# its face: turned to it; its body tipped up; leaning into its way
	if _face.length() > 0.01:
		var wy := atan2(-_face.x, -_face.z)
		_yaw = lerp_angle(_yaw, wy, 1.0 - exp(-8.0 * dt))
	var fwd_v := _vel.dot(_fwd())
	want.pitch = 0.25 + clampf(fwd_v * 0.15, -0.25, 0.4)
	want.roll = clampf(-_vel.dot(_right()) * 0.3, -0.5, 0.5)
	want.head_pitch = -0.2 - (float(want.pitch) - 0.25) * 0.6 # (its head level, its bill held out level)
	rate["pitch"] = 10.0
	rate["roll"] = 10.0
	want.legs_tuck = 1.0
	want.tail_up = tail_rest + 0.25
	want.tail_spread = 0.35 + 0.25 * sin(float(f.t) * 3.0)
	want.fold_pitch = 0.0
	head_want = Vector3.ZERO
	air_foot = Vector3.ZERO
	talon_open = 0.0
	_flap = 1.0
	beat_amp = 1.25
	_phase += TAU * hover_hz * dt
	_speed = Vector2(_vel.x, _vel.z).length()
	set_wings(0.0, 0.0, 0.25, 1.0)
	for k: String in ["wl_up", "wr_up", "wl_sweep", "wr_sweep", "wl_twist", "wr_twist", "wl_spread", "wr_spread"]:
		rate[k] = 20.0
	var gy := super._ground(_pos.x, _pos.z)
	_pos.y = maxf(_pos.y, gy + 0.02)


func _fly_step(dt: float) -> void:
	if String(_fly.get("kind", "")) in ["hover", "path"]:
		if String(_fly.kind) == "path":
			_path_step(dt)
		_hover(dt)
		return
	super(dt)
	if _air and not _fly.is_empty():
		_flap = 1.0 # (it never glides)
		beat_amp = 1.1
		_fly["hz"] = 42.0


func _land(at: Vector3) -> void:
	var m := _mode
	super(at)
	_ride_to = 0.0
	if m == "sip":
		forage()
	elif m == "feed_nest":
		_to("feed_nest", "at")


# --- feeding at the flowers ----------------------------------------------------------------

## To the flowers that are here: the nearest plant in flower (Diet's
## flowers, forbs), its heads one by one.
func forage() -> void:
	if young or dead:
		return
	var best: Node3D = null
	var bd := INF
	for o in get_parent().get_children():
		if not (o is Node3D) or o == _plant and _sips > 0 and rng.randf() < 0.5:
			continue
		var k := Diet.kind_of(o)
		if k not in ["flowers", "forbs"] or (o.get_meta("heads", []) as Array).is_empty():
			continue
		var d := Diet._at(o as Node3D).distance_to(_pos) / maxf(Diet.affinity(self, k), 0.05)
		if d < bd:
			bd = d
			best = o
	if best == null:
		var fl := Diet.find(self, 8.0, ["flier"])
		if fl and fl != self:
			hawk(fl as Node3D)
			return
		perch()
		return
	_plant = best
	_head = -1
	_next_flower()


func _next_flower() -> void:
	if _plant == null or not is_instance_valid(_plant):
		_leave_flowers()
		return
	var heads: Array = _plant.get_meta("heads", [])
	var order := range(heads.size())
	order.sort_custom(func(a: int, b: int) -> bool: return ((heads[a] as Array)[0] as Vector3).distance_to(_pos) < ((heads[b] as Array)[0] as Vector3).distance_to(_pos))
	var pick: int = order[0]
	if pick == _head and order.size() > 1:
		pick = order[1]
	_head = pick
	var h: Array = heads[_head]
	var hp: Vector3 = h[0]
	_ride_at = hp
	_ride_k = float(h[2]) * float(h[2])
	var side := Vector3(_pos.x - hp.x, 0.0, _pos.z - hp.z)
	side = side.normalized() if side.length() > 0.01 else Vector3.RIGHT
	_to("sip", "to")
	_face = -side
	hover_at(hp + side * 0.07 + Vector3(0.0, 0.02, 0.0), -side)


func _sip(dt: float) -> void:
	if _plant == null or not is_instance_valid(_plant) or _head < 0:
		_leave_flowers()
		return
	var h: Array = (_plant.get_meta("heads", []) as Array)[_head]
	var fl: Vector3 = (h[0] as Vector3) + Vector3(0.0, 0.004, 0.0) # (into its florets)
	var w: Vector3 = get_parent().to_global(fl)
	match _sub:
		"to": # (hovering before it)
			_ride_to = 1.0
			if _pos.distance_to(_hov) < 0.02 or _st > 2.0:
				_sub = "in"
				_st = 0.0
		"in": # (its bill into the flower)
			hover_at(fl, _face, true)
			if bill_tip().distance_to(w) < 0.003:
				_sub = "lick"
				_st = 0.0
			elif _st > 2.5:
				_sub = "back"
				_st = 0.0
		"lick": # (its tongue in and out, drinking)
			hover_at(fl, _face, true)
			hunger = maxf(hunger - dt / 6.0, 0.0)
			if _st > rng.randf_range(1.0, 1.8):
				_sips += 1
				_sub = "back"
				_st = 0.0
		"back": # (backing off, and on to the next)
			_tongue.visible = false
			hover_at(fl - _face * 0.08 + Vector3(0.0, 0.02, 0.0), _face)
			if _st > 0.4:
				if not _live_young().is_empty() and _sips % 3 == 2 and nest_top != Vector3.INF: # (to the nest, with nectar for them)
					_tongue.visible = false
					_ride_to = 0.0
					_plant = null
					_to("feed_nest", "go")
					_take_off("go", nest_top + Vector3(0.025, 0.0, 0.0), true)
				elif _sips % 4 == 3 or hunger <= 0.0:
					_leave_flowers()
				else:
					_next_flower()


func _leave_flowers() -> void:
	_tongue.visible = false
	_ride_to = 0.0
	_plant = null
	if home_perch != Vector3.INF:
		perch_on(home_perch)
	else:
		var a := rng.randf() * TAU
		var to := _pos + Vector3(cos(a), 0.0, sin(a)) * 2.0
		to.y = super._ground(to.x, to.z)
		_to("fly")
		_take_off("go", to, true)


## Its tongue: out of its bill's tip, licking in and out (into the flower).
func _lick() -> void:
	if _tongue == null:
		return
	var on := _mode == "sip" and _sub == "lick"
	_tongue.visible = on
	if not on:
		return
	var tip := bill_tip()
	var hw: Vector3 = global_transform * (_g[J_HEAD].origin * size)
	var dir := (tip - hw).normalized()
	var ln := 0.006 + 0.008 * (0.5 + 0.5 * sin(_mt * 80.0)) # (in and out, a dozen times a second)
	_tongue.global_transform = Transform3D(SkinScript_along(tip, tip + dir * ln), tip + dir * ln * 0.5)
	var m := _tongue.material_override as ShaderMaterial
	m.set_shader_parameter("ride_at", get_parent().to_global(_ride_at))
	m.set_shader_parameter("ride_k", _ride_k * _ride)


static func SkinScript_along(a: Vector3, b: Vector3) -> Basis:
	var y := (b - a)
	var l := y.length()
	y = y.normalized() if l > 1e-6 else Vector3.UP
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	return Basis(x, y * l, z)


# --- the young: fed, her bill deep in each gape ------------------------------------------

func _live_young() -> Array:
	return young_ones.filter(func(y: Variant) -> bool: return is_instance_valid(y) and y.get("young"))


var _fed_n := 0
var _in_gape := 0.0


func _feed_nest(dt: float) -> void:
	var live := _live_young()
	if live.is_empty():
		perch()
		return
	if _sub == "go":
		return
	var who: Node3D = live[_fed_n % live.size()]
	var wp: Vector3 = who.get("_pos")
	turn_to(wp - _pos)
	var gape: Vector3 = who.call("bill_tip")
	var hw: Vector3 = global_transform * (_g[J_HEAD].origin * size)
	var dir := (gape - hw).normalized()
	head_rate = 10.0
	head_point = gape + dir * 0.006 + Vector3(0.0, 0.0015 * sin(_mt * 18.0), 0.0) # (her bill deep in its gape, pumping)
	want.pitch = stand_pitch + 0.5
	who.set("_beg", 0.4)
	if bill_tip().distance_to(gape) < 0.009:
		_in_gape += dt
		if _in_gape > 1.2:
			_in_gape = 0.0
			who.set("_age", float(who.get("_age")) + grow_secs * 0.05)
			_fed_n += 1
			if _fed_n % live.size() == 0:
				head_point = Vector3.INF
				forage()
	elif _st > 5.0:
		_fed_n += 1
		_st = 0.0


# --- insects, rivals, displays ---------------------------------------------------------------

## A small flying insect darted at, snapped up (only with its bill on it), swallowed.
func hawk(prey: Node3D) -> void:
	if young or dead or prey == null or not is_instance_valid(prey):
		return
	_prey = prey
	prey.set_meta("hunted", self)
	_to("hawk")
	hover_at(Diet._at(prey), Vector3.ZERO, true)


func hunt(prey: Node3D) -> void:
	var k := Diet.kind_of(prey)
	if k in ["flowers", "forbs"]:
		_plant = prey
		_head = -1
		_next_flower()
	else:
		hawk(prey)


func _hawk(_dt: float) -> void:
	if _prey == null or not is_instance_valid(_prey) or _prey.get("dead") == true:
		_prey = null
		forage()
		return
	var pp := Diet._at(_prey)
	_face = Vector3(pp.x - _pos.x, 0.0, pp.z - _pos.z)
	hover_at(pp, _face, true)
	want.jaw = 0.3
	if bill_tip().distance_to(get_parent().to_global(pp)) < 0.006: # (snapped up)
		Meal.subdue(_prey)
		_prey.queue_free()
		_prey = null
		hunger = maxf(hunger - 0.15, 0.0)
		want.jaw = 0.0
		forage()
	elif _st > 6.0:
		_prey.remove_meta("hunted")
		_prey = null
		forage()


## (A male's.) A rival male here: flown at, chased off; none: a buzz about his perch.
func display(rival: Node3D = null) -> void:
	if young or dead or not male:
		return
	if rival and is_instance_valid(rival) and rival != self and not rival.get("dead"):
		_rival = rival
		_to("chase")
		var rp: Vector3 = rival.get("_pos")
		hover_at(rp, rp - _pos)
		if rival.has_method("fly_off"):
			rival.call("fly_off", _pos)
	else:
		call_out(3.0)


func _chase(_dt: float) -> void:
	if _rival == null or not is_instance_valid(_rival) or _st > 4.0:
		_rival = null
		perch_on(home_perch) if home_perch != Vector3.INF else forage()
		return
	var rp: Vector3 = _rival.get("_pos")
	hover_at(rp + (_pos - rp).normalized() * 0.25, rp - _pos)


## (A male's.) To her: his pendulum dives, then his shuttle; then on her back.
func mate(female: Node3D, secs := -1.0) -> bool:
	if not male or young or juvenile or dead or female == null or not is_instance_valid(female) or female == self:
		return false
	if female.get("male") or female.get("young") or female.get("dead") or female.get("gravid"):
		return false
	_partner = female
	_show_to = female
	female.set("_partner", self)
	if not bool(female.get("_air")):
		female.call("_to", "courted")
	_to("display")
	_secs = secs if secs > 0.0 else 10.0
	_path_t = 0.0
	hover_at(female.get("_pos") as Vector3 + Vector3(0.0, 1.0, 0.0), Vector3.ZERO)
	_fly["kind"] = "path"
	return true


func is_mating() -> bool:
	return _partner != null and is_instance_valid(_partner) and _mode in ["display", "mount"]


## (His display's path: the U of his pendulum dives, then the quick short arcs of his shuttle, before her.)
func _path_step(dt: float) -> void:
	var her := _show_to
	if her == null or not is_instance_valid(her):
		_fly["kind"] = "hover"
		return
	_path_t += dt
	var hp: Vector3 = her.get("_pos")
	var side := Vector3(1.0, 0.0, 0.0)
	var dive := _path_t < _secs * 0.65
	if dive: # (a U, 2.5 m wide, 1.2 m deep, swung each way in a second and a half)
		var th := sin(_path_t * TAU / 3.0) * 1.2
		_hov = hp + side * sin(th) * 1.25 + Vector3(0.0, 1.5 - cos(th) * 1.2, 0.0)
		_face = (hp - _pos) * Vector3(1, 0, 1)
	else: # (the shuttle: short quick arcs side to side close before her, his gorget to her)
		var s := sin(_path_t * TAU * 2.2)
		_hov = hp + Vector3(0.0, 0.12, 0.3) + side * s * 0.15 + Vector3(0.0, 0.03 * absf(s), 0.0)
		_face = Vector3(0.0, 0.0, -1.0)
	_hov_bill = false
	if _path_t > _secs:
		_fly["kind"] = "hover"
		_to("mount_go")
		hover_at(hp + Vector3(0.0, 0.06, 0.0), _face)


func _mount_go(_dt: float) -> void:
	var her := _partner
	if her == null or not is_instance_valid(her):
		perch()
		return
	var hp: Vector3 = her.get("_pos")
	hover_at(hp + Vector3(0.0, 0.04, 0.0), _face)
	if _pos.distance_to(hp + Vector3(0.0, 0.04, 0.0)) < 0.02 or _st > 3.0:
		_air = false
		_fly = {}
		_pos = hp
		_to("mount")
		_secs = 1.5


# --- the rest ------------------------------------------------------------------------------

func _think(dt: float) -> void:
	_ride = move_toward(_ride, _ride_to, dt * 3.0)
	super(dt)
	if _mat:
		_mat.set_shader_parameter("ride_at", get_parent().to_global(_ride_at) if get_parent() else _ride_at)
		_mat.set_shader_parameter("ride_k", _ride_k * _ride)
	if dead or young:
		return
	match _mode:
		"sip":
			_sip(dt)
		"hawk":
			_hawk(dt)
		"chase":
			_chase(dt)
		"mount_go":
			_mount_go(dt)
		"feed_nest":
			_feed_nest(dt)
		"display":
			if _show_to and is_instance_valid(_show_to):
				want.puff = 0.4 # (his gorget flared)
		"sleep": # (torpor: puffed, still, its bill up)
			head_want = Vector3(0.0, 0.002, 0.0)
			look_yaw = 0.0
			want.head_pitch = -0.5
			want.puff = 0.9
			foot_off[1] = Vector3.ZERO


func _watch(dt: float) -> void:
	if young:
		super(dt)
		return
	if perch_at == Vector3.INF and not _air: # (it doesn't stand on the ground: up to a perch, or to the flowers)
		forage()
		return
	look_yaw = lerpf(look_yaw, 1.2 * sin(floor(_mt / 0.9) * 2.7), 1.0 - exp(-14.0 * dt)) # (quick looks about)
	if fmod(_mt, 2.5) < 0.2: # (its tail flicked)
		want.tail_up = tail_rest + 0.25 * sin(_mt * 40.0)
		rate["tail_up"] = 30.0
	if _st > 3.0:
		_st = 0.0
		hunger = minf(hunger + 0.1, 1.0)
		var r := rng.randf()
		if hunger > 0.3 and r < 0.6:
			forage()
		elif r < 0.75:
			preen(rng.randf_range(3.0, 6.0))


func _sing(_dt: float) -> void:
	# its chips: quick, its bill opening a little on each
	want.jaw = 0.15 * maxf(0.0, sin(_mt * 40.0)) if fmod(_mt, 0.8) < 0.3 else 0.0
	rate["jaw"] = 50.0
	if _mt > _secs:
		want.jaw = 0.0
		perch()


func _process(dt: float) -> void:
	super(dt)
	_lick()


func _to(mode: String, sub := "") -> void:
	if mode not in ["sip"]:
		_ride_to = 0.0
		if _tongue:
			_tongue.visible = false
	super(mode, sub)


func test_mode(mode: String) -> void:
	if mode.contains("hover"):
		hover_at(_pos + Vector3(0.0, 0.25, 0.0), _fwd())
		_to("hovering")
	else:
		super(mode)
