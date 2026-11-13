class_name Pigeon
extends "res://scripts/creatures/thrush.gd"
## A pigeon, a dove (Columbidae): the songbird's make (Thrush: walking,
## foraging, flying, nesting, its young raised) made a dove's, its ways
## the living doves' (the rock dove's, the mourning dove's, the band-tailed
## pigeon's). Its own:
## - a small round head on a short neck, a short bill soft at its root, a
##   plump breast, long pointed wings, short legs; its flight fast and
##   straight, wings beating steadily, no glides but its display's
## - forage(): a walk, its head nodding with each step, a peck as it goes;
##   seeds and nuts taken from the ground whole (acorns: swallowed whole),
##   now and then a grub, a caterpillar, a snail; its bill on each before
##   it's taken, swallowed whole in one gulp
## - drink(at): its bill put in the water and kept there, sucking (a
##   dove's, unlike other birds': no tipping back its head to swallow)
## - cooing (call_out): its bill shut, its throat and neck swelling with
##   each coo, its head bobbing a little, its tail flicked
## - courting (mate, a male's): to her, the bow-coo: his neck puffed out,
##   his tail fanned and dragged on the ground, bowing low and up again,
##   cooing, turning this way and that before her; then billing (her bill
##   inside his), then on her back
## - display_flight(): off with a clap of its wings over its back, up, and
##   a long glide down on wings held up in a V, its tail spread; every
##   take-off with a clatter of its wings (alarm: off and away)
## - sunbathe(secs): down on its belly, tipped onto one side, the upper
##   wing raised and spread to the sun, its tail fanned, eyes half shut
## - nesting (lay): a flimsy platform of a few twigs on its site (a tree's
##   fork, set_nest_site: the world's), its eggs white (a passenger
##   pigeon's one); its squab fed crop milk (feeding its young: the squab's
##   bill inside the parent's, the parent pumping it up), never carried
##   food in its bill
##
## A species gives thrush_shape() its measures, _plumage() and mass_of().

var _display := false
var _billed := false ## (their bills met: billing, before he mounts)
var _crop_t := 0.0


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	walks = true
	flaps_glide = false
	cruise = 15.0
	top_speed = 22.0
	nest_style = "sticks"
	site_style = "fork"
	nest_height = 2.4
	nest_scale = 0.22
	clutch = 2
	egg_size = Vector2(0.038, 0.028)
	egg_colors = [Color(0.96, 0.95, 0.92), Color(0.96, 0.95, 0.92)]
	grow_secs = 140.0
	eyas_scale = 0.65
	stand_pitch = 0.6
	tail_rest = -1.15
	fold_pitch = 0.9
	beat_amp = 1.1
	song_notes = 3
	song_hz = 1.6
	pounces = false


## (Pigeons don't carry food to their young: crop milk.)
func _seize() -> void:
	var yo := young_ones
	young_ones = []
	super()
	young_ones = yo


## Seeds and nuts too (its diet's all: Diet), not only what moves.
func _meal_kinds() -> Array:
	return Diet.of(self).filter(func(k: String) -> bool: return k not in ["berries", "forbs", "flowers", "sapling"])


# --- drinking ------------------------------------------------------------------------

var _drink_at := Vector3.INF


## Drinking at `at` (its parent's space: a point on the water's surface):
## walked to its edge, its bill put in and kept there, sucking.
func drink(at: Vector3, secs := 5.0) -> void:
	if young or dead:
		return
	_drink_at = at
	_to("drink", "go")
	_secs = secs


func _drink(_dt: float) -> void:
	if _drink_at == Vector3.INF:
		forage()
		return
	var to := Vector3(_drink_at.x - _pos.x, 0.0, _drink_at.z - _pos.z)
	var reach := 0.075 * body_k / 0.55
	match _sub:
		"go":
			if to.length() <= reach * 1.1:
				halt()
				turn_to(to)
				_sub = "drink"
				_st = 0.0
			elif to.length() < reach * 2.5: # (the last of the way: a shuffle, finer than a walk's)
				halt()
				turn_to(to)
				_pos += to.normalized() * minf(0.12 * body_k / 0.55 * _dt, to.length() - reach)
			elif arrived() or _st < 0.05:
				walk_to(_drink_at - to.normalized() * reach * 0.9, walk_speed)
			if _st > 15.0:
				forage()
		"drink": # (bill in, held there: sucking, its throat working)
			turn_to(to)
			want.pitch = 1.35
			want.crouch = 0.55
			rate["pitch"] = 8.0
			head_rate = 8.0
			head_point = get_parent().to_global(_drink_at + Vector3(0.0, -0.004, 0.0))
			want.puff = 0.15 + 0.1 * maxf(0.0, sin(_mt * 9.0))
			rate["puff"] = 20.0
			if _st > _secs:
				head_point = Vector3.INF
				_drink_at = Vector3.INF
				forage()


# --- cooing, courting --------------------------------------------------------------------

func _sing(_dt: float) -> void:
	# its bill shut, its throat swelling with each coo, a little bob of its head
	want.jaw = 0.0
	var phrase := song_notes / song_hz
	var ph := fmod(_mt, phrase + 1.8)
	var on := ph < phrase
	var note := fmod(ph * song_hz, 1.0)
	want.puff = 0.2 + (0.55 * sin(PI * note) if on else 0.0)
	rate["puff"] = 12.0
	want.head_pitch = (0.2 * sin(PI * note) if on else -0.1)
	head_want = Vector3(0.0, -0.004 * sin(PI * note) if on else 0.0, 0.0) * body_k / 0.55
	if ph < 0.15: # (a flick of its tail)
		want.tail_up = tail_rest + 0.25
	else:
		want.tail_up = tail_rest
	if _mt > _secs:
		want.puff = 0.0
		perch()


func _court(dt: float) -> void:
	# the bow-coo: puffed out, his tail fanned and dragged, bowing low and up,
	# cooing, turning half about before her; then billing; then on her back
	if _partner == null or not is_instance_valid(_partner):
		perch()
		return
	var to: Vector3 = (_partner.get("_pos") as Vector3) - _pos
	var bk := body_k / 0.55
	if _mt < _secs - 2.5 and not _billed:
		var ph := fmod(_mt, 1.4) / 1.4
		var bow := sin(PI * clampf(ph / 0.6, 0.0, 1.0)) # (down, and up again)
		want.puff = 0.9
		want.tail_spread = 1.0
		want.tail_up = tail_rest - 0.45
		want.droop = 0.5
		want.pitch = stand_pitch + 0.55 * bow
		want.head_pitch = 0.9 * bow
		head_want = Vector3(0.0, -0.02 * bow, -0.006 * bow) * bk
		rate["pitch"] = 8.0
		set_wings(-1.3, 0.0, 0.0, 0.2)
		_yaw += 1.4 * sin(_mt * 0.9) * dt # (turning half about, this way and that)
		if Vector2(to.x, to.z).length() > 0.25 * bk: # (driving: following her up)
			walk_to(_partner.get("_pos") as Vector3, walk_speed)
		else:
			halt()
	else: # (billing: face to face, her bill in his; his open, gently pumping)
		var fp: Vector3 = _partner.get("_pos")
		var gap := Vector2(to.x, to.z).length()
		turn_to(to)
		_partner.call("turn_to", -to)
		want.puff = 0.5
		want.pitch = stand_pitch
		want.tail_up = tail_rest
		want.tail_spread = 0.3
		want.droop = 0.0
		want.jaw = 0.3
		rate["jaw"] = 10.0
		if gap > 0.11 * bk: # (up close to her)
			_pos += Vector3(to.x, 0.0, to.z).normalized() * minf(0.15 * bk * dt, gap - 0.11 * bk)
		halt()
		var hers: Vector3 = _partner.call("bill_tip")
		var mid: Vector3 = (bill_tip() + hers) * 0.5
		head_rate = 8.0
		head_point = mid + Vector3(0.0, 0.002 * sin(_mt * 10.0), 0.0)
		_partner.set("head_point", bill_tip())
		if bill_tip().distance_to(hers) < 0.015 * bk:
			_billed = true
	if _mt > _secs and (_billed or _mt > _secs + 3.0): # (on her back once their bills have met)
		_billed = false
		_partner.set("head_point", Vector3.INF)
		head_point = Vector3.INF
		want.jaw = 0.0
		_to("mount")
		_secs = 3.0


# --- flight: the clatter of its take-off, its display -----------------------------------

## Off with a clap of its wings, up, and a long glide down on wings held up
## in a V, its tail spread.
func display_flight() -> void:
	if young or dead:
		return
	var a := rng.randf() * TAU
	var to := _pos + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(14.0, 22.0)
	to.y = super._ground(to.x, to.z)
	_to("fly")
	_take_off("go", to, true)
	_display = true


func _take_off(kind: String, to: Vector3, land: bool) -> void:
	super(kind, to, land)
	_fly["clap"] = 0.6 # (its wings clapped together over its back, clattering)


func _fly_step(dt: float) -> void:
	super(dt)
	if _fly.is_empty() or not _air:
		beat_amp = 1.1
		return
	var t := float(_fly.get("t", 0.0))
	beat_amp = 1.65 if t < float(_fly.get("clap", 0.0)) else 1.1 # (the clap: its beats up over its back, the wings meeting)
	if t < float(_fly.get("clap", 0.0)):
		_flap = 1.0
	if _display and t > 1.8: # (the glide: wings held up in a V, tail spread)
		var d := Vector3(_fly.to) - _pos if _fly.has("to") else Vector3.ZERO
		if Vector2(d.x, d.z).length() > 3.0:
			if t < 3.0:
				_vel.y = maxf(_vel.y, 1.5) # (up, before the glide)
			else:
				_flap = move_toward(_flap, 0.0, dt * 4.0)
				set_wings(0.6, 0.0, 0.0, 1.0)
				want.tail_spread = 1.0


func _land(at: Vector3) -> void:
	_display = false
	beat_amp = 1.1
	super(at)


# --- sunbathing ----------------------------------------------------------------------------

func sunbathe(secs := 20.0) -> void:
	if _air or young or dead:
		return
	_to("sun")
	_secs = secs
	_cock = 1.0 if rng.randf() < 0.5 else -1.0


func _sun(_dt: float) -> void:
	# down on its belly, tipped onto one side, its upper wing raised and spread
	var bk := body_k / 0.55
	want.pitch = stand_pitch + 0.35 # (its body level, down on its belly)
	want.crouch = 0.7
	want.drop = 0.012 * bk
	want.roll = 0.5 * _cock
	for kk: String in ["pitch", "crouch", "drop", "roll"]:
		rate[kk] = 3.0
	want.puff = 0.6
	want.tail_spread = 0.8
	want.eye_shut = 0.6
	want.head_pitch = -0.2
	var up := "wr" if _cock > 0.0 else "wl"
	want[up + "_up"] = 0.15
	want[up + "_spread"] = 0.9
	want[up + "_sweep"] = 0.1
	want.fold_pitch = 0.2
	if _mt > _secs:
		fold_wings()
		want.fold_pitch = fold_pitch
		perch()


# --- the squabs: crop milk -------------------------------------------------------------------

func _think(dt: float) -> void:
	super(dt)
	if _air or dead or young:
		return
	match _mode:
		"drink":
			_drink(dt)
		"sun":
			_sun(dt)
		"crop":
			_crop(dt)
		"brood":
			_crop_t += dt
			if _crop_t > 8.0 and _live_young().size() > 0: # (now and then up off them to feed them)
				_crop_t = 0.0
				_to("crop")


func _live_young() -> Array:
	return young_ones.filter(func(y: Variant) -> bool: return is_instance_valid(y) and y.get("young"))


func _crop(dt: float) -> void:
	# a squab's bill inside its own, its head pumping: crop milk brought up
	var live := _live_young()
	if live.is_empty():
		perch()
		return
	var who: Node3D = live[_fed % live.size()]
	var wp: Vector3 = who.get("_pos")
	var bk := body_k / 0.55
	var away := Vector3(_pos.x - wp.x, 0.0, _pos.z - wp.z)
	away = away.normalized() if away.length() > 0.005 else Vector3(cos(_fed * 2.0), 0.0, sin(_fed * 2.0))
	var stand := wp + away * 0.1 * bk # (beside it on the platform, facing it)
	if Vector2(stand.x - _pos.x, stand.z - _pos.z).length() > 0.008:
		_pos += (Vector3(stand.x, _pos.y, stand.z) - _pos).normalized() * minf(0.12 * bk * dt, Vector2(stand.x - _pos.x, stand.z - _pos.z).length())
	turn_to(wp - _pos)
	who.call("turn_to", _pos - wp)
	want.pitch = stand_pitch + 0.45
	want.crouch = 0.25
	want.jaw = 0.35
	rate["jaw"] = 10.0
	var sb: Vector3 = who.call("bill_tip")
	head_rate = 10.0
	head_point = (bill_tip() + sb) * 0.5 + Vector3(0.0, 0.004 * sin(_mt * 8.0), 0.0) # (its head down to the squab's, pumping)
	who.set("head_point", bill_tip()) # (the squab's bill up into its)
	who.set("_beg", 0.3)
	if bill_tip().distance_to(who.call("bill_tip")) < 0.015 * maxf(bk, 0.7): # (bill in bill: fed)
		who.set("_age", float(who.get("_age")) + dt * grow_secs * 0.02)
	if _st > 6.0:
		who.set("head_point", Vector3.INF)
		_fed += 1
		if _fed % live.size() == 0:
			head_point = Vector3.INF
			want.jaw = 0.0
			brood(15.0)
		else:
			_st = 0.0


func _to(mode: String, sub := "") -> void:
	if _mode == "crop" and mode != "crop":
		for y in young_ones:
			if is_instance_valid(y):
				y.set("head_point", Vector3.INF)
	if _mode == "sun" and mode != "sun":
		fold_wings()
	super(mode, sub)


func test_mode(mode: String) -> void:
	if mode.contains("sun"):
		sunbathe(60.0)
	elif mode.contains("display"):
		display_flight()
	else:
		super(mode)
