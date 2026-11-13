class_name CanadaGoose
extends "res://scripts/creatures/thrush.gd"
## A Canada goose (Branta canadensis), life size: 95 cm long, 1.6 m across,
## the gander 4.5 kg, the goose 3.9 kg and a little smaller. The bird's
## make (Bird, Raptor's nesting, its young), its own body: deep and long,
## carried level; its neck long, an S standing; its head small and flat
## crowned, sloping into a broad flat bill; short legs set back, its feet
## webbed (Bird's web). Its head and neck black, a white chinstrap from
## under its chin up behind its eye; its back and wings brown, each feather
## edged pale; breast and flanks paler grey brown barred with the feathers'
## edges; white under its tail and over it (a white band on its rump); its
## tail black; its bill and legs black.
##
## Its ways (it lives by its water: water_y its surface, pond where it is):
## - grazing (forage, on land): a slow walk, its neck down, its bill to the
##   grass and nipping it (a bite taken only with its bill on the ground),
##   a jerk of its head as it tears it; its head up now and then, looking
##   round; then to the water
## - swimming: on the water floating, its belly a hand under; its feet
##   paddling beneath (its strokes); upending (its tail up, its head and
##   neck under, its feet working: the water's weeds); drinking (its bill
##   in the surface, then its head up to swallow); out again onto the bank
## - honking (call_out): its neck up, its bill opening on each ah-honk
## - threaten(at): its neck stretched out low and snaking, its bill open,
##   hissing, its wings out at the wrists, puffed; a charge at it; then off
## - flying (fly, fly_off): a run up first, its wings beating (on water
##   pattering along the surface, the spray thrown up); deep slow beats,
##   its neck straight out ahead, its feet tucked behind; honking; down onto
##   the water feet first, skiing in
## - skein(geese, to): a flock flying in a V behind its leader, each in the
##   slot off the one ahead's wingtip
## - courting (mate, on the water): head dipping, both, again and again;
##   then on her back; then his display, risen up, his wings half raised,
##   calling
## - nesting (lay): a bowl of grass on the ground by the water (its site the
##   world's), lined with down she plucks from her breast as she lays; five
##   cream white eggs; the gander guarding near, his head up
## - the goslings (young): yellow olive down; after her in a line, on land
##   and on the water; grazing by her; under her wings when she sits;
##   growing into juveniles
## - preening; asleep, its head turned back onto its back

var water_y := 0.0 ## (its water's surface)
var pond := Rect2() ## (where its water is: x, z)
var _mate: Node3D # (its mate: they pair for life)
var _lead: Node3D # (flying in a skein: the one ahead of it)
var _slot := 1.0 # (and on which side of it: -1, 1)
var _run_to := Vector3.INF # (a run up: where it's flying to)
var _graze_at := Vector3.INF
var _bites := 0 ## (grass bitten, in all)
var _dips := 0 # (courting: head dips)
var _dipped := false
var _guarding := Vector3.INF # (a gander: his mate's nest, watched over)
var _spray: CPUParticles3D


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.06 # (she the smaller)
	body_k = 1.9
	stand_pitch = 0.0
	flight_pitch = 0.0
	tail_rest = -0.12
	fold_pitch = -0.18
	feather_cm = 3.6
	walks = true
	cruise = 17.0
	top_speed = 22.0
	flaps_glide = false
	clutch = 5
	egg_size = Vector2(0.086, 0.058)
	egg_colors = [Color(0.94, 0.92, 0.84), Color(0.94, 0.92, 0.84)]
	grow_secs = 220.0
	eyas_scale = 1.0


func mass_of() -> Vector3:
	return Vector3(4.5, 1.6, 0.42) if male else Vector3(3.9, 1.55, 0.4)


## Its body (cm): deep and long, level; the neck long, an S standing; the
## head small, flat crowned, sloping into a broad flat bill, its nail at
## the tip; its legs short, set back, its feet webbed.
func _shape() -> Dictionary:
	return {
		"tilt_rings": false,
		"spine": [[34.0, 36.0, 1.2, 0.8, 0.0], [34.5, 31.0, 5.0, 3.0, 0.0], [33.5, 24.0, 10.5, 8.5, 0.0], [32.0, 13.0, 13.5, 12.0, 0.0], [32.0, 0.0, 14.5, 13.0, 0.0],
				[33.5, -10.0, 13.0, 12.0, 0.1], [37.5, -17.0, 9.5, 9.5, 0.4], [43.5, -21.0, 5.8, 6.2, 0.9], [50.5, -22.5, 4.3, 4.5, 1.6], [57.5, -22.0, 3.6, 3.8, 2.4],
				[63.5, -21.5, 3.3, 3.4, 3.2], [68.5, -22.5, 3.2, 3.3, 3.9], [71.5, -24.5, 3.5, 3.8, 4.4], [73.0, -27.5, 3.5, 3.7, 4.65], [72.6, -31.0, 2.9, 2.8, 4.88],
				[71.7, -33.2, 2.2, 1.6, 5.0], [71.1, -36.2, 1.85, 1.0, 5.4], [70.7, -38.3, 1.65, 0.85, 5.75], [70.4, -39.3, 1.3, 0.7, 5.9], [70.0, -39.9, 0.7, 0.45, 6.0]],
		"pivot": Vector3(0.0, 30.0, 6.0),
		"jaw": Vector3(0.0, 71.0, -32.8),
		"lower_bill": [[70.9, -34.0, 0.95], [70.4, -37.0, 0.8], [70.1, -39.0, 0.45]],
		"eye": Vector3(3.15, 73.4, -29.0), "eye_r": 0.6,
		"hip": Vector3(7.0, 27.0, 7.0), "knee": Vector3(8.0, 19.0, 2.0), "ankle": Vector3(7.5, 9.0, 4.0), "foot": Vector3(7.0, 1.4, 0.0),
		"thigh_r": [6.5, 3.6], "leg_r": 0.95, "toes": [9.0, 7.6, 2.0], "claw": 0.1, "claw_r": 0.55, "web": 0.93, "toe_spread": 0.5,
		"tuck": Vector3(-0.02, 0.04, 0.24), # (in flight its feet drawn back under its tail)
		"tail": Vector3(0.0, 34.0, 31.0),
		"shoulder": Vector3(13.8, 40.5, -8.0), "wing": Vector3(15.0, 16.0, 11.0), "coverts": [8.0, 14.0, 11.0, 6.0],
		"fold_fan": Vector3(0.1, 0.15, 0.0), "fold_tuck": 0.45, "fold_tuck_front": 0.5, "fold_chord": 0.15, "wing_thick": [3.0, 2.2, 1.4, 0.6],
		"primaries": [20.0, 22.0, 24.0, 26.0, 27.0, 28.0, 28.0, 27.0, 25.0, 22.0],
		"secondaries": [18, 17.0, 15.0], "tertials": [4, 18.0, 15.0], "feather_w": 5.0,
		"tail_feathers": [18, 15.0, 4.5], "tail_coverts": [[16, 12.0, 5.0, 0.5, 0.9]], "tail_grad": 0.12,
	}


func _plumage(stage: String, _male: bool) -> Dictionary:
	var brown := Color(0.34, 0.27, 0.21)
	var black := Color(0.035, 0.032, 0.03)
	return {
		"back_color": brown, "back_edge": Color(0.66, 0.58, 0.48), "back_bar": brown.darkened(0.3), "back_bars": 0.0, "back_from": 0.3, "back_from_hi": 0.24,
		"cap_color": black, "hood_u": 0.12, "hood_low": 0.0, "hood_nape": 1.0, "cheek": 0.0, "malar": 0.0,
		"chin_strap": Color(0.95, 0.94, 0.91, 1.0), "strap_at": Vector4(-0.018, 0.012, 0.03, 0.03),
		"under_color": Color(0.72, 0.66, 0.59), "breast_wash": Color(0.78, 0.73, 0.66), "wash_from": -1.0, "wash_to": 2.0, "vent_to": 0.215,
		"under_mark": Color(0.46, 0.38, 0.31), "under_pattern": 2, "under_bar_n": 1.0, "under_bar_w": 0.55, "throat_clean": 0.16, "mark_from": -0.5,
		"fl_top": Color(0.2, 0.17, 0.14), "fl_pale": Color(0.42, 0.38, 0.34), "fl_dark": Color(0.16, 0.14, 0.12), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"fl_prim_dark": 0.8, "fl_edge": Color(0.6, 0.52, 0.42, 0.35),
		"tail_color": black, "tail_band": black, "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": black, "tail_tip_w": 0.0, "tail_under": 0.0,
		"tail_cov": Color(0.96, 0.95, 0.93, 1.0),
		"cere_color": black, "bill_color": Color(0.05, 0.045, 0.045), "bill_tip": Color(0.03, 0.03, 0.03), "iris": Color(0.06, 0.04, 0.03),
		"leg_color": Color(0.07, 0.065, 0.065), "down_white": Color(0.84, 0.76, 0.42), "gape": Color(0.25, 0.25, 0.22), "young_legs": Color(0.32, 0.31, 0.3),
		"lid_color": black, "trouser": Color(0.6, 0.55, 0.5, 1.0),
	}


func _build() -> void:
	super()
	walk_speed = 0.45 * size
	run_speed = 2.2


# --- its water ---------------------------------------------------------------------------

func _water_at(x: float, z: float) -> bool:
	return pond.has_area() and pond.grow(-0.04).has_point(Vector2(x, z))


func in_water() -> bool:
	return not _air and _water_at(_pos.x, _pos.z)


## (How far below its water its feet's floor is, floating: its belly a hand under.)
func _float_depth() -> float:
	var belly := INF
	var top := -INF
	for r: Array in shape.get("spine", []):
		if float(r[4]) < 0.3:
			belly = minf(belly, float(r[0]) - float(r[3]))
			top = maxf(top, float(r[0]) + float(r[3]))
	if belly == INF:
		return 0.2 * size
	return (belly + (top - belly) * 0.32) * CM * size


func _ground(x: float, z: float) -> float:
	if _water_at(x, z) and not _air:
		return water_y - _float_depth()
	return super(x, z)


func _ground_step(dt: float) -> void:
	var y0 := _pos.y
	super(dt)
	if absf(_pos.y - y0) > 0.02 and not _air: # (into the water, out of it: eased, not dropped)
		_pos.y = lerpf(y0, _pos.y, 1.0 - exp(-6.0 * dt))


func _land(at: Vector3) -> void:
	var m := _mode
	super(at)
	if _water_at(at.x, at.z):
		perch_at = Vector3.INF
		_speed = 1.2 # (feet first, skiing in)
		_splash(at, 0.6)
	if m in ["fly", "run_up"] and not young:
		forage()


## Where on the water to go (in its pond, clear of its edge; its feet's floor).
func _on_water(p: Vector3) -> Vector3:
	var x := clampf(p.x, pond.position.x + 0.25, pond.end.x - 0.25)
	var z := clampf(p.z, pond.position.y + 0.25, pond.end.y - 0.25)
	return Vector3(x, water_y - _float_depth(), z)


## (Out onto the bank: the nearest dry ground past the pond's edge.)
func _bank_from(p: Vector3) -> Vector3:
	var c := pond.get_center()
	var d := Vector2(p.x - c.x, p.z - c.y)
	if d.length() < 1e-3:
		d = Vector2(1.0, 0.0)
	var e := Vector2(p.x, p.z)
	var dx := pond.size.x * 0.5 - absf(d.x)
	var dz := pond.size.y * 0.5 - absf(d.y)
	if dx < dz:
		e.x = c.x + signf(d.x) * (pond.size.x * 0.5 + 0.5)
	else:
		e.y = c.y + signf(d.y) * (pond.size.y * 0.5 + 0.5)
	return Vector3(e.x, super._ground(e.x, e.y), e.y)


## (Thrown up from the water: its take-off, its landing.)
func _splash(at: Vector3, k := 1.0) -> void:
	if _spray == null:
		_spray = CPUParticles3D.new()
		_spray.one_shot = true
		_spray.amount = 40
		_spray.lifetime = 0.8
		_spray.explosiveness = 0.7
		_spray.direction = Vector3.UP
		_spray.spread = 55.0
		_spray.initial_velocity_min = 0.6
		_spray.initial_velocity_max = 1.8
		_spray.gravity = Vector3(0.0, -9.8, 0.0)
		_spray.scale_amount_min = 0.006
		_spray.scale_amount_max = 0.014
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 6
		sm.rings = 3
		_spray.mesh = sm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.85, 0.9, 0.95, 0.75)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.1
		_spray.material_override = m
		get_parent().add_child(_spray)
	_spray.position = Vector3(at.x, water_y + 0.02, at.z)
	_spray.amount = int(40 * k) + 4
	_spray.restart()
	_spray.emitting = true


# --- grazing, swimming ---------------------------------------------------------------------

## On the ground grazing, or on the water (its own choice; to the water now
## and then, out of it again).
func forage() -> void:
	if young or dead:
		return
	if _air:
		var to := _on_water(_pos) if pond.has_area() else Vector3(_pos.x, super._ground(_pos.x, _pos.z), _pos.z)
		_to("fly")
		_take_off("go", to, true)
		return
	_to("forage", "swim" if in_water() else "graze")


func _meal_kinds() -> Array:
	return []


func _forage(dt: float) -> void:
	hunger = minf(hunger + dt / 150.0, 1.0)
	if in_water():
		_swim(dt)
	else:
		_graze(dt)


func _graze(dt: float) -> void:
	var bk := size
	match _sub:
		"look": # (its head up, its neck tall, looking round)
			halt()
			want.pitch = 0.0
			head_point = Vector3.INF
			want.head_pitch = 0.0
			look_yaw = 1.2 * sin(_st * 1.3)
			if _st > 2.5:
				look_yaw = 0.0
				_sub = "graze"
				_st = 0.0
				_n += 1
				if _n > 3 and pond.has_area() and rng.randf() < 0.45: # (off to the water)
					_to("forage", "to_water")
					walk_to(_on_water(_pos), walk_speed)
		"to_water":
			head_point = Vector3.INF
			if in_water() or arrived():
				_sub = "swim"
				_st = 0.0
		_: # "graze": its bill down to the grass before its feet, nipping it, walking slowly on
			_sub = "graze"
			if _graze_at == Vector3.INF:
				var a := rng.randf_range(-0.5, 0.5)
				var g := _pos + (_fwd().rotated(Vector3.UP, a)) * 0.42 * bk
				_graze_at = Vector3(g.x, super._ground(g.x, g.z) + 0.01, g.z) # (the grass's blades, a little up off the ground)
			var w: Vector3 = get_parent().to_global(_graze_at)
			head_rate = 9.0
			head_point = w
			want.head_pitch = -0.05
			want.pitch = 0.3 # (tipped forward, its breast down, its neck down to the grass)
			rate["pitch"] = 4.0
			if bill_tip().distance_to(w) < 0.02 * maxf(bk, 0.5): # (its bill on the grass: a bite, a tear)
				want.jaw = 0.0 if fmod(_st, 0.3) < 0.15 else 0.35
				rate["jaw"] = 30.0
				if fmod(_st, 0.6) < dt * 1.5:
					_bites += 1
					hunger = maxf(hunger - 0.01, 0.0)
					head_want = Vector3(0.0, 0.02, 0.01) * bk # (torn: its head jerked up a little)
				else:
					head_want = Vector3.ZERO
				if _st > 1.8: # (on a step, another mouthful)
					_graze_at = Vector3.INF
					_st = 0.0
					var step := _pos + _fwd() * 0.12 * bk
					walk_to(step, walk_speed * 0.5)
					if rng.randf() < 0.18:
						_sub = "look"
			elif _st > 2.0: # (not reached: nearer to its feet)
				var g2 := _pos + _fwd() * 0.34 * bk
				_graze_at = Vector3(g2.x, super._ground(g2.x, g2.z) + 0.01, g2.z)
				_st = 0.0


func _swim(dt: float) -> void:
	var bk := size
	want.pitch = 0.0
	match _sub:
		"upend": # (its tail up, its head and neck down under, its feet working)
			halt()
			want.pitch = 1.5
			rate["pitch"] = 4.0
			want.tail_up = tail_rest + 0.4
			var under := _pos + _fwd() * 0.15 * bk
			under.y = water_y - 0.3 * bk
			head_rate = 6.0
			head_point = get_parent().to_global(under)
			foot_off[0] = Vector3(0.0, 0.05 * sin(_st * 9.0), 0.08 * cos(_st * 9.0)) * bk
			foot_off[1] = Vector3(0.0, -0.05 * sin(_st * 9.0), -0.08 * cos(_st * 9.0)) * bk
			if bill_tip().y < get_parent().to_global(Vector3(0.0, water_y, 0.0)).y - 0.03: # (its bill down among the weeds)
				hunger = maxf(hunger - dt / 30.0, 0.0)
			if _st > rng.randf_range(3.0, 5.0):
				want.pitch = 0.0
				want.tail_up = tail_rest
				foot_off[0] = Vector3.ZERO
				foot_off[1] = Vector3.ZERO
				head_point = Vector3.INF
				_sub = "swim"
				_st = 0.0
		"drink": # (its bill in the surface; then its head up, tipped back, swallowing)
			halt()
			var at := _pos + _fwd() * 0.28 * bk
			at.y = water_y - 0.008
			if _st < 2.0:
				head_rate = 8.0
				head_point = get_parent().to_global(at)
				want.head_pitch = 0.4
				if bill_tip().distance_to(get_parent().to_global(at)) < 0.02 * maxf(bk, 0.5):
					_st = maxf(_st, 1.6)
			else:
				head_point = Vector3.INF
				want.head_pitch = -0.6
				head_want = Vector3(0.0, 0.03, 0.02) * bk
				if _st > 3.0:
					want.head_pitch = 0.0
					head_want = Vector3.ZERO
					_sub = "swim"
					_st = 0.0
		"ashore":
			head_point = Vector3.INF
			if not in_water() and arrived():
				_sub = "graze"
				_st = 0.0
		_: # "swim": paddling about, its feet's strokes under it
			_sub = "swim"
			head_point = Vector3.INF
			if arrived() or _st > 8.0:
				_st = 0.0
				var r := rng.randf()
				if r < 0.3:
					_sub = "upend"
				elif r < 0.45:
					_sub = "drink"
				elif r < 0.55 and hunger > 0.3:
					_sub = "ashore"
					walk_to(_bank_from(_pos), walk_speed)
				elif r < 0.62:
					call_out(rng.randf_range(3.0, 5.0))
				else:
					var a := rng.randf() * TAU
					walk_to(_on_water(_pos + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.6, 1.6)), walk_speed * 0.8)


# --- its honk; its threat ----------------------------------------------------------------

func _sing(_dt: float) -> void:
	# its neck up, its bill opening on each ah-honk, its throat working
	head_point = Vector3.INF
	want.head_pitch = -0.25
	head_want = Vector3(0.0, 0.04, -0.03) * size
	var ph := fmod(_mt, 1.3)
	var o := 0.0
	if ph < 0.15:
		o = 0.25 * sin(PI * ph / 0.15) # (ah)
	elif ph > 0.22 and ph < 0.55:
		o = 0.55 * sin(PI * (ph - 0.22) / 0.33) # (HONK)
	want.jaw = o
	rate["jaw"] = 30.0
	want.puff = 0.15 + o * 0.3
	if _mt > _secs:
		want.jaw = 0.0
		head_want = Vector3.ZERO
		forage()


## At at (its parent's space: a fox, a dog, someone come too near): its
## threat, a charge; then back to what it was doing.
func threaten(at: Vector3, secs := 6.0) -> void:
	if young or dead or _air:
		return
	_to("threat")
	_secs = secs
	_graze_at = at


func _threat(dt: float) -> void:
	var to := _graze_at - _pos
	to.y = 0.0
	turn_to(to)
	var bk := size
	# its neck out low before it, snaking, its bill open, hissing; its wings out at the wrists; puffed
	var low := _pos + to.normalized() * 0.5 * bk
	low.y = _pos.y + 0.28 * bk + 0.03 * sin(_mt * 5.0)
	low += _right() * 0.04 * bk * sin(_mt * 3.3)
	head_rate = 6.0
	head_point = get_parent().to_global(low)
	want.head_pitch = 0.1
	want.jaw = 0.5
	rate["jaw"] = 8.0
	want.puff = 0.8
	set_wings(-1.15, -0.35, 0.0, 0.25)
	want.fold_pitch = fold_pitch
	if to.length() > 0.7 * bk and _mt < _secs * 0.6: # (the charge)
		walk_to(_graze_at - to.normalized() * 0.65 * bk, run_speed * 0.5)
	else:
		halt()
	if _mt > _secs:
		head_point = Vector3.INF
		want.jaw = 0.0
		want.puff = 0.0
		fold_wings()
		_graze_at = Vector3.INF
		forage()


# --- flying: its run up; the skein ---------------------------------------------------------

## Up and away to `to`: a run up first (on the water pattering, the spray thrown up).
func takeoff_to(to: Vector3) -> void:
	if young or dead:
		return
	if _air:
		_to("fly")
		_take_off("go", to, true)
		return
	_to("run_up")
	_run_to = to
	turn_to(to - _pos)
	walk_to(_pos + Vector3(to.x - _pos.x, 0.0, to.z - _pos.z).normalized() * 6.0, run_speed)
	if in_water():
		_splash(_pos, 0.5)


func fly(to: Vector3) -> void:
	var t := Vector3(to.x, super._ground(to.x, to.z), to.z)
	takeoff_to(_on_water(t) if _water_at(t.x, t.z) else t)


func fly_off(from: Vector3) -> void:
	if young or dead:
		return
	var away := _pos - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else _fwd()
	var to := _pos + away * rng.randf_range(16.0, 24.0)
	_beg = 1.0
	takeoff_to(Vector3(to.x, super._ground(to.x, to.z), to.z))


func _run_up(dt: float) -> void:
	# running, its wings beating, its neck out; off at speed
	_flap = 1.0
	_phase += TAU * BirdFlight.wingbeat_hz(mass, span, wing_area) * 1.1 * dt
	set_wings(0.1, 0.1, 0.1, 1.0)
	want.fold_pitch = 0.0
	want.pitch = -0.1
	head_want = Vector3(0.0, -0.12, -0.15) * size
	if in_water() and fmod(_st, 0.25) < dt:
		_splash(_pos, 0.25)
	if _st > (1.4 if in_water() else 0.9):
		var to := _run_to
		_run_to = Vector3.INF
		_to("fly")
		_take_off("go", to, true)
		_vel = _fwd() * 3.0 + Vector3(0.0, 1.5, 0.0)


## A flock (geese, the first its leader) off together to `to`, flying in a
## V: each in the slot behind and off the wingtip of the one ahead, sides
## alternating down its two arms.
static func skein(geese: Array, to: Vector3) -> void:
	if geese.is_empty():
		return
	var lead: CanadaGoose = geese[0]
	lead._lead = null
	lead.takeoff_to(to)
	for i in range(1, geese.size()):
		var g: CanadaGoose = geese[i]
		var side := 1.0 if i % 2 == 1 else -1.0
		var ahead: CanadaGoose = geese[maxi(i - 2, 0)]
		g._lead = ahead
		g._slot = side
		var a := float(i) * 0.4
		g.takeoff_to(to + Vector3(cos(a), 0.0, sin(a)) * 1.2 * i)


func _fly_step(dt: float) -> void:
	var lead := _lead
	var formation := lead != null and is_instance_valid(lead) and bool(lead.get("_air")) and String(_fly.get("kind", "")) == "go"
	if formation: # (its slot: behind the one ahead, out off its wingtip)
		var lp: Vector3 = lead.get("_pos")
		var lv: Vector3 = lead.get("_vel")
		var fw := Vector3(lv.x, 0.0, lv.z).normalized() if Vector2(lv.x, lv.z).length() > 0.5 else _fwd()
		var rt := fw.cross(Vector3.UP).normalized()
		var slot := lp - fw * 1.5 + rt * _slot * 1.3 + Vector3(0.0, 0.15, 0.0)
		_fly["to"] = slot + lv * 1.5
		_fly["land"] = false
	super(dt)
	if not _air or _fly.is_empty():
		return
	if formation:
		var lp2: Vector3 = lead.get("_pos")
		var lv2: Vector3 = lead.get("_vel")
		var fw2 := Vector3(lv2.x, 0.0, lv2.z).normalized() if Vector2(lv2.x, lv2.z).length() > 0.5 else _fwd()
		var slot2 := lp2 - fw2 * 1.5 + fw2.cross(Vector3.UP).normalized() * _slot * 1.3 + Vector3(0.0, 0.15, 0.0)
		_pos = _pos.lerp(slot2, 1.0 - exp(-1.5 * dt))
		_vel = _vel.lerp(lv2, 1.0 - exp(-2.0 * dt))
	elif lead != null and is_instance_valid(lead) and not bool(lead.get("_air")) and String(_fly.get("kind", "")) == "go" and not bool(_fly.get("land", true)): # (its leader's down: down by it)
		var lp3: Vector3 = lead.get("_pos")
		var a := rng.randf() * TAU
		var spot := lp3 + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.8, 1.6)
		_fly["to"] = _on_water(spot) if _water_at(spot.x, spot.z) else Vector3(spot.x, super._ground(spot.x, spot.z), spot.z)
		_fly["land"] = true
		_lead = null
	# its neck straight out ahead, its head level; its feet tucked behind
	var flare := float(want.legs_tuck) < 0.5
	head_want = Vector3(0.0, -0.31, -0.34) * size if not flare else Vector3(0.0, -0.18, -0.2) * size
	want.head_pitch = 0.0
	want.pitch = -atan2(_vel.y, maxf(Vector2(_vel.x, _vel.z).length(), 0.5)) * 0.5 - (0.5 if flare else 0.0)
	if fmod(float(_fly.get("t", 0.0)), 3.1) < dt and rng.randf() < 0.6: # (honking as it goes)
		_beg = 0.5
	if flare and _water_at(_pos.x, _pos.z): # (feet forward, skiing in)
		want.legs_tuck = 0.0
		air_foot = Vector3(0.0, 0.0, -0.15) * size


# --- courting, mating on the water ---------------------------------------------------------

## (A gander's.) With her on the water (to it first, both): head dipping,
## both, again and again; then on her back; then his display.
func mate(female: Node3D, secs := -1.0) -> bool:
	if not male or young or juvenile or dead or female == null or not is_instance_valid(female) or female == self:
		return false
	if female.get("male") or female.get("young") or female.get("dead") or female.get("gravid"):
		return false
	_partner = female
	female.set("_partner", self)
	_mate = female
	female.set("_mate", self)
	_secs = secs if secs > 0.0 else 10.0
	var meet := _on_water((_pos + (female.get("_pos") as Vector3)) * 0.5) if pond.has_area() else (female.get("_pos") as Vector3) + _right() * 0.5
	for g: Node3D in [self, female]:
		g.call("_to", "court_w", "go")
		g.set("_secs", _secs)
		var off := (Vector3(0.35, 0.0, 0.0) if g == self else Vector3(-0.35, 0.0, 0.0)) * size
		g.call("walk_to", meet + off, float(g.get("walk_speed")))
	return true


func is_mating() -> bool:
	return _partner != null and is_instance_valid(_partner) and _mode in ["court_w", "mount", "post"]


func _court_w(dt: float) -> void:
	var p := _partner
	if p == null or not is_instance_valid(p):
		forage()
		return
	var bk := size
	var to: Vector3 = (p.get("_pos") as Vector3) - _pos
	match _sub:
		"go":
			if arrived() and String(p.get("_sub")) in ["go", "dip"] and (p as Node3D).get("_going") == false:
				_sub = "dip"
				_st = 0.0
		"dip": # (its bill and head dipped into the water, up again, and again; facing each other)
			turn_to(to)
			var ph := fmod(_st + (0.0 if male else 0.6), 1.2)
			if ph < 0.6:
				var at := _pos + _fwd() * 0.25 * bk
				at.y = water_y - 0.04 * bk if in_water() else super._ground(at.x, at.z) + 0.01
				head_rate = 9.0
				head_point = get_parent().to_global(at)
				want.head_pitch = 0.5
				if bill_tip().y < get_parent().to_global(Vector3(0.0, water_y, 0.0)).y and not _dipped: # (its bill in the water: a dip)
					_dips += 1
					_dipped = true
			else:
				_dipped = false
				head_point = Vector3.INF
				want.head_pitch = -0.3
				head_want = Vector3(0.0, 0.03, 0.0) * bk
			if male and _mt > _secs and _dips >= 4: # (on her back)
				head_point = Vector3.INF
				head_want = Vector3.ZERO
				p.set("head_point", Vector3.INF)
				_to("mount")
				_secs = 4.0


func _mount(dt: float) -> void:
	var f := _partner
	if f == null or not is_instance_valid(f):
		forage()
		return
	if f.get("_mode") != "crouch":
		f.call("_to", "crouch")
		f.set("_partner", self)
	f.set("want", (f.get("want") as Dictionary).merged({"drop": 0.1 * size, "pitch": 0.15}, true)) # (she low in the water under him)
	var fp: Vector3 = f.get("_pos")
	var fy: float = f.get("_yaw")
	_pos = _pos.lerp(fp, 1.0 - exp(-5.0 * dt))
	_yaw = lerp_angle(_yaw, fy, 1.0 - exp(-5.0 * dt))
	lift_y = move_toward(lift_y, 0.22 * size, dt * 0.4)
	for i in 2:
		_feet[i] = _pos + _right() * (-0.07 if i == 0 else 0.07) * size + Vector3(0.0, lift_y, 0.0)
	want.pitch = 0.2
	set_wings(0.0, -0.1, 0.2, 0.6) # (his wings half out, balancing)
	want.fold_pitch = 0.0
	_flap = 0.25
	_phase += TAU * 2.5 * dt
	head_point = f.call("bill_tip") + Vector3(0.0, 0.25, 0.1) * size # (his bill at her nape)
	if _mt > _secs:
		f.set("gravid", true)
		f.call("forage")
		_flap = 0.0
		lift_y = 0.0
		head_point = Vector3.INF
		_plant_feet()
		_to("post")
		_secs = 3.0


func _post(_dt: float) -> void:
	# his display: risen up in the water, his breast out, his wings half raised, his neck up, calling
	want.pitch = -0.45
	rate["pitch"] = 5.0
	set_wings(-0.6, -0.1, 0.0, 0.45)
	want.fold_pitch = 0.0
	head_want = Vector3(0.0, 0.06, 0.02) * size
	want.head_pitch = -0.3
	want.jaw = 0.4 * maxf(0.0, sin(_mt * 8.0))
	rate["jaw"] = 25.0
	if _mt > _secs:
		want.pitch = 0.0
		fold_wings()
		head_want = Vector3.ZERO
		_partner = null
		forage()


# --- the nest, the eggs, the goslings -------------------------------------------------------

## (A goose's.) Her eggs laid in a bowl on the ground on her site (by the
## water: set_nest_site, the world's to give her), walked to.
func lay() -> bool:
	if male or young or juvenile or dead or _mode in ["nest", "incubate", "brood"]:
		return false
	if not _ensure_nest():
		return false
	_to("nest", "go")
	walk_to(nest_top, walk_speed)
	if _mate and is_instance_valid(_mate):
		_mate.call("guard", nest_top)
	return true


## (A gander's.) Near her nest, his head up, watching; at anything near: his threat.
func guard(at: Vector3) -> void:
	_guarding = at
	var a := rng.randf() * TAU
	_to("guard")
	walk_to(at + Vector3(cos(a), 0.0, sin(a)) * 1.2, walk_speed)


func _guard(_dt: float) -> void:
	head_point = Vector3.INF
	want.head_pitch = -0.1
	head_want = Vector3(0.0, 0.03, 0.0) * size
	look_yaw = 1.4 * sin(_mt * 0.5)
	var nest_mate := _mate != null and is_instance_valid(_mate) and String(_mate.get("_mode")) in ["nest", "incubate", "brood"]
	if not nest_mate and _mt > 20.0:
		_guarding = Vector3.INF
		forage()


func _make_nest() -> Node3D:
	# a wide low bowl of dry grass and reeds pulled in round her; its hollow
	# lined with her down (more as she lays)
	var n := Node3D.new()
	n.set_meta("prop", true)
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.6, 0.53, 0.38)
	grass.roughness = 1.0
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.13
	tm.outer_radius = 0.3
	tm.rings = 20
	tm.ring_segments = 10
	rim.mesh = tm
	rim.scale = Vector3(1.0, 0.45, 1.0)
	rim.position = Vector3(0.0, 0.03, 0.0)
	rim.material_override = grass
	n.add_child(rim)
	for k in 30: # (loose stems)
		var st := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.002
		sm.bottom_radius = 0.003
		sm.height = rng.randf_range(0.12, 0.22)
		sm.radial_segments = 4
		sm.rings = 1
		st.mesh = sm
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.17, 0.3)
		st.position = Vector3(cos(a) * r, 0.04, sin(a) * r)
		st.rotation = Vector3(PI * 0.5 + rng.randf_range(-0.3, 0.3), a + PI * 0.5 + rng.randf_range(-0.7, 0.7), 0.0)
		st.material_override = grass
		n.add_child(st)
	return n


## (A tuft of her down, plucked from her breast, into the nest's hollow.)
func _down_tuft() -> void:
	if nest == null or not is_instance_valid(nest):
		return
	var t := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = rng.randf_range(0.025, 0.04)
	sm.height = sm.radius * 1.1
	sm.radial_segments = 8
	sm.rings = 4
	t.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.77, 0.74).lerp(Color(0.6, 0.57, 0.54), rng.randf())
	m.roughness = 1.0
	t.material_override = m
	var a := rng.randf() * TAU
	var r := rng.randf_range(0.04, 0.12)
	t.position = (nest_top - nest.position) + Vector3(cos(a) * r, 0.01, sin(a) * r)
	nest.add_child(t)


func _arrange_eggs() -> void:
	for k in eggs_laid.size():
		var e := eggs_laid[k]
		if not is_instance_valid(e):
			continue
		var a := k * TAU / maxf(eggs_laid.size() - 1, 1.0)
		var r := 0.0 if k == 0 else 0.07
		e.position = (nest_top - nest.position) + Vector3(cos(a) * r, egg_size.y * 0.5, sin(a) * r)


func _nest_goose(dt: float) -> void:
	if _sub == "go":
		head_point = Vector3.INF
		if arrived() or Vector2(nest_top.x - _pos.x, nest_top.z - _pos.z).length() < 0.15:
			halt()
			_pos = _pos.lerp(nest_top, 0.5)
			_sub = "scrape"
			_st = 0.0
		return
	if _sub == "lay" and fmod(_st, 2.5) > 1.2 and fmod(_st, 2.5) < 2.2: # (between eggs: her bill to her breast, a tuft of down plucked, laid in)
		var br := _pos + _fwd() * 0.12 * size + Vector3(0.0, 0.3 * size, 0.0)
		head_rate = 8.0
		head_point = get_parent().to_global(br)
		if fmod(_st, 2.5) > 2.1 and fmod(_st, 2.5) - dt <= 2.1:
			_down_tuft()
	else:
		head_point = Vector3.INF
	_nest(dt)
	_arrange_eggs()


func hatch() -> void:
	super()
	for y in young_ones:
		if is_instance_valid(y):
			y.set("water_y", water_y)
			y.set("pond", pond)
			y.set("height", height)
	if _mate and is_instance_valid(_mate):
		_mate.set("young_ones", young_ones)


## A gosling: yellow olive down, round, its neck short, its head big, its bill small and dark.
func _eyas() -> Dictionary:
	return {
		"tilt_rings": false,
		"spine": [[14.0, 15.0, 1.0, 1.0, 0.0], [14.0, 12.0, 5.0, 4.0, 0.0], [14.0, 6.0, 8.5, 7.5, 0.0], [14.0, -1.0, 9.0, 8.5, 0.0], [15.5, -6.0, 7.0, 7.0, 0.2],
				[18.0, -9.0, 4.6, 4.7, 0.6], [21.0, -10.0, 3.7, 3.8, 1.5], [24.0, -10.0, 3.5, 3.6, 2.6], [26.5, -10.5, 3.7, 3.9, 3.6], [28.0, -11.5, 4.4, 4.7, 4.3],
				[28.6, -13.5, 4.4, 4.5, 4.6], [28.0, -16.0, 3.4, 3.3, 4.85], [27.0, -17.3, 1.8, 1.3, 5.0], [26.6, -19.0, 1.4, 0.8, 5.5], [26.3, -20.0, 0.8, 0.5, 6.0]],
		"pivot": Vector3(0.0, 13.0, 2.0),
		"jaw": Vector3(0.0, 26.6, -17.4),
		"lower_bill": [[26.3, -17.8, 0.75], [26.0, -19.2, 0.55], [25.9, -19.9, 0.3]],
		"eye": Vector3(3.4, 29.3, -14.6), "eye_r": 0.75,
		"hip": Vector3(4.5, 12.0, 3.0), "knee": Vector3(5.0, 8.0, 0.0), "ankle": Vector3(4.5, 4.2, 1.5), "foot": Vector3(4.5, 0.8, 0.0),
		"thigh_r": [4.0, 2.6], "leg_r": 0.7, "toes": [4.5, 3.8, 1.0], "claw": 0.1, "web": 0.9, "toe_spread": 0.5,
		"tail": Vector3(0.0, 14.0, 15.0),
		"shoulder": Vector3(8.5, 18.0, -3.0), "wing": Vector3(3.0, 3.0, 2.0), "coverts": [2.5, 2.5, 2.0, 1.0], "wing_thick": [2.0, 1.6, 1.2, 0.6],
		"primaries": [1.0, 1.0, 1.0, 1.0], "secondaries": [4, 1.0, 1.0], "tertials": [0, 1.0, 1.0], "feather_w": 1.0,
		"tail_feathers": [6, 1.0, 1.0],
	}


func _grow(dt: float) -> void:
	_age += dt
	var g := clampf(_age / grow_secs, 0.0, 1.0)
	size = lerpf(0.5, 1.0, g) * eyas_scale


func _fledge_now() -> void:
	young = false
	juvenile = true
	_rebuild()
	var mom := _mother
	if mom and is_instance_valid(mom):
		(mom.get("young_ones") as Array).erase(self)
	forage()


## (A gosling.) After its mother in a line, on land and on the water; by her
## grazing (pecking at the grass too); under her wings when she sits.
func _eyas_ways(dt: float) -> void:
	var mom := _mother
	if mom == null or not is_instance_valid(mom) or mom.get("dead"):
		_graze(dt)
		return
	var sibs: Array = mom.get("young_ones")
	var rank := maxi(sibs.find(self), 0)
	var mp: Vector3 = mom.get("_pos")
	var my: float = mom.get("_yaw")
	var mf := Vector3(-sin(my), 0.0, -cos(my))
	var mmode := String(mom.get("_mode"))
	if _age >= grow_secs:
		_fledge_now()
		return
	if mmode in ["brood", "incubate"]: # (under her wings: in against her, tucked)
		var a := float(rank) * 1.3
		var at := mp + Vector3(cos(a), 0.0, sin(a)) * 0.12
		walk_to(at, walk_speed * 1.2)
		want.drop = 0.04 * size
		want.eye_shut = 1.0 if arrived() else 0.0
		head_point = Vector3.INF
		return
	want.eye_shut = 0.0
	want.drop = 0.0
	var moving := float(mom.get("_speed")) > 0.08
	if moving: # (in a line behind her)
		var mr: Vector3 = mom.call("_right")
		var at2: Vector3 = mp - mf * (0.45 + 0.22 * rank) * float(mom.get("size")) + mr * 0.04 * sin(_mt * 2.0 + rank)
		walk_to(at2, maxf(float(mom.get("_speed")) * 1.3, walk_speed))
		head_point = Vector3.INF
	else: # (about her, pecking at the grass)
		var a2 := float(rank) * 2.1 + 0.6
		var home := mp + Vector3(cos(a2), 0.0, sin(a2)) * 0.45 * float(mom.get("size"))
		if Vector2(home.x - _pos.x, home.z - _pos.z).length() > 0.25:
			walk_to(home, walk_speed * 1.3)
			head_point = Vector3.INF
		elif not in_water():
			_graze(dt)
		else:
			halt()


# --- the rest -----------------------------------------------------------------------------

func _think(dt: float) -> void:
	super(dt)
	if _air or dead:
		return
	if young:
		return
	match _mode:
		"threat":
			_threat(dt)
		"run_up":
			_run_up(dt)
		"court_w":
			_court_w(dt)
		"post":
			_post(dt)
		"guard":
			_guard(dt)
		"nest":
			_nest_goose(dt)
		"sleep": # (its head turned back onto its back, its bill under its wing's coverts)
			head_want = Vector3(0.07, -0.25, 0.24) * size
			look_yaw = 2.8
			want.head_pitch = 0.6
		"incubate":
			_arrange_eggs()


func _watch(_dt: float) -> void:
	if young:
		return
	forage()


func _to(mode: String, sub := "") -> void:
	if mode != "forage":
		_graze_at = Vector3.INF
	foot_off[0] = Vector3.ZERO
	foot_off[1] = Vector3.ZERO
	super(mode, sub)
	if mode not in ["nest"]:
		want.pitch = 0.0


func test_mode(mode: String) -> void:
	if mode.contains("swim") or mode.contains("graze"):
		forage()
	elif mode.contains("threat"):
		threaten(_pos + _fwd() * 2.0, 60.0)
	elif mode.contains("honk"):
		call_out(60.0)
	elif mode.contains("sleep"):
		sleep()
	elif mode.contains("fly"):
		takeoff_to(_pos + _fwd() * 60.0)
	else:
		super(mode)
