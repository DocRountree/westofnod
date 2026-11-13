class_name Finch
extends "res://scripts/creatures/thrush.gd"
## A finch (the American goldfinch, the house finch): the songbird's make
## (Thrush: perching, hopping, flying, nesting, its young raised) made
## small, its bill short, deep and conical (a seed cracker's), its head big
## and round, its tail notched. A seed eater; what's its own:
## - forage(): to the seed heads that are here (a coneflower's, a black-eyed
##   Susan's, an aster's, a fleabane's, a yampah's: SEEDS, its own liking for
##   each; a house finch's a berry bush's too): flown to, clinging beside the
##   head on its stem, swaying with it in the wind; leaning over it, its bill
##   to the disc, a seed picked out at a time (taken only with its bill on
##   the head), husked in its bill (its jaw working, the seed turned), the
##   husk dropped, the kernel swallowed; a dozen or so, then on to the next
##   head, or off. The plant itself never touched: a seed head's seeds, a
##   bush's berries, as they were. A berry pecked at, a bite of it taken
##   (the house finch's). None here: on the ground, hopping, pecking
## - bounding flight: a burst of beats, then its wings shut, swooping, and
##   again (the goldfinch's deep, a call on each rise: po-ta-to-chip)
## - song (call_out): a long run of quick notes, its bill opening on each
##   (the house finch's warble falling to a burry wheer at its end, the
##   goldfinch's twittering canary song)
## - display_flight(): a male's song flight (the goldfinch's butterfly
##   flight: slow, deep, exaggerated beats, circling, singing; the house
##   finch's up and singing, gliding down)
## - courting (mate): he to her, his wings drooped and quivering, his tail
##   raised and spread, puffed out, singing; then courtship feeding: she
##   crouches and begs as a nestling does, her wings fluttering, her bill
##   open; his bill in hers, seed brought up; then on her back
## - nesting (lay): her cup on its site (a goldfinch's a fork in a shrub,
##   its cup of plant fibres lined with thistle down; a house finch's a
##   ledge, as under eaves); she sits, he feeds her there; their young fed
##   seed brought up from their crops, bill in gape, its head pumping (no
##   insects: seeds)
##
## A species gives thrush_shape() its measures, _plumage(), mass_of() and
## its SEEDS.

const SEEDS_DEFAULT := {"coneflower": 1.0, "susan": 1.0, "aster": 0.8, "fleabane": 0.6, "yampah": 0.4}

var seeds := SEEDS_DEFAULT.duplicate() ## (the plants whose seeds it eats, by their kind: its liking for each)
var bound_secs := Vector2(0.45, 0.5) ## (its bounding flight: s of beats, s shut)
var bound_m := 0.3 ## (how far it dips on each)
var song_secs := 3.0 ## (a song's length)
var song_tail := 0.0 ## (its last note held, falling: the house finch's wheer)
var flight_hz := 1.0 ## (its song flight's wingbeat, of its own: the goldfinch's slow)
var crop := 0 ## (seeds held in its crop, for its young, its mate)
var eaten := 0 ## (seeds, bites, taken in all)
var _food: Node3D # (the plant it's at)
var _head := -1 # (which of its heads; -1 a berry)
var _berry: Node3D
var _cling := Vector3.INF # (where it holds on: on the stem by the head)
var _spot := Vector3.INF # (the parent's: its bill's mark on the head)
var _ride := 0.0 # (how much of the head's sway it rides)
var _ride_to := 0.0
var _ride_at := Vector3.ZERO
var _ride_k := 0.0
var _picked := 0
var _want_n := 10
var _bit: MeshInstance3D # (a seed, a bite, in its bill)
var _bit_mat: ShaderMaterial
var _song_flight := false
var _mate: Node3D # (its mate, once they've paired: fed on the nest, the young shared)
var _begging := false # (a female, courted, begging as a nestling does)
var _fed_mate := 0.0
var _visited: Array = [] # (plants just eaten at: let be a while)


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	walks = false
	pounces = false
	flaps_glide = false
	cruise = 8.0
	top_speed = 12.0
	nest_style = "cup"
	site_style = "fork"
	nest_height = 1.4
	nest_scale = 0.24
	clutch = 5
	eyas_scale = 0.38
	stand_pitch = 0.32
	grow_secs = 130.0
	feather_cm = 0.7
	tail_rest = -1.05
	song_notes = 24
	song_hz = 9.0
	head_blend = 0.5
	bill_lift = 0.55


## Its shape: thrush_shape's, its eye small and flush (no raised ring).
func finch_shape(S: Dictionary, eye_k := 0.8) -> Dictionary:
	S.erase("eye_ring")
	S.eye_r = float(S.eye_r) * eye_k
	S.eye = (S.eye as Vector3) + Vector3(0.12, 0.9, 0.15) * float(S.eye_r) # (up its big head's side, clear of its throat)
	return S


## Its diet's plants (Diet): what it looks for; it hunts nothing.
func _meal_kinds() -> Array:
	return []


func _build() -> void:
	super()
	_bit_mat = ShaderMaterial.new()
	_bit_mat.shader = preload("res://shaders/render/seed.gdshader")


# --- finding its food ------------------------------------------------------------------

## The best seed head or berry bush here for it (within r m): its diet's
## plant (Diet), of a kind whose seeds it takes (seeds), the nearest by its
## distance over its liking; or null.
func _find_food(r := 30.0) -> Node3D:
	var p := _pos
	var best: Node3D = null
	var bd := INF
	var diet := Diet.of(self)
	for o in get_parent().get_children():
		if not (o is Node3D) or o == self or o in _visited:
			continue
		var k := Diet.kind_of(o)
		if k == "" or not diet.has(k):
			continue
		var like := Diet.affinity(self, k)
		if k == "berries":
			if not (o as Node3D).find_children("berry*", "", false, false).size():
				continue
		else:
			var pk := String(o.get_meta("plant", ""))
			if not seeds.has(pk) or (o.get_meta("heads", []) as Array).is_empty():
				continue
			like *= float(seeds[pk])
		var d := Diet._at(o as Node3D).distance_to(p)
		if d < r and d / maxf(like, 0.05) < bd:
			bd = d / maxf(like, 0.05)
			best = o
	return best


## To forage: to the best food here, flown to and clung to; none, hopping on
## the ground, pecking.
func forage() -> void:
	if young or dead:
		return
	var f := _find_food()
	if f:
		feed_at(f)
		return
	super()


## (A plant's: eaten from where it grows.) Hunting it: feeding there.
func hunt(prey: Node3D) -> void:
	if prey and is_instance_valid(prey) and Diet.kind_of(prey) in ["forbs", "flowers", "berries"]:
		feed_at(prey)


## To plant (a seed head's clump, a berry bush): one of its heads (a berry)
## chosen, flown to, clung to by it.
func feed_at(plant: Node3D) -> void:
	if young or dead or plant == null or not is_instance_valid(plant):
		return
	_food = plant
	_picked = 0
	_want_n = rng.randi_range(8, 14)
	if not _pick_head():
		_food = null
		perch()
		return
	_to("seed", "go")
	_take_off("go", _cling, true)


## (Which head next, and where it'll cling: on the stem just under it, on
## the side it comes from; a berry's: in the bush beside it, a little under.)
func _pick_head() -> bool:
	if _food == null or not is_instance_valid(_food):
		return false
	var from := _pos
	var bk := body_k / 0.55
	if Diet.kind_of(_food) == "berries":
		var on := _food.find_children("berry*", "", false, false)
		if on.is_empty():
			return false
		on.sort_custom(func(a: Node, b: Node) -> bool: return _local(a as Node3D).distance_to(from) < _local(b as Node3D).distance_to(from))
		_berry = on[rng.randi() % mini(on.size(), 4)] as Node3D
		_head = -1
		var bp := _local(_berry) + Vector3(0.0, Thrush._mid_y(_berry), 0.0)
		var side := Vector3(from.x - bp.x, 0.0, from.z - bp.z)
		side = side.normalized() if side.length() > 0.01 else Vector3(cos(rng.randf() * TAU), 0.0, sin(rng.randf() * TAU))
		_cling = bp + side * 0.07 * bk - Vector3(0.0, 0.06 * bk, 0.0)
		_spot = bp
		_ride_k = 0.0
		return true
	var heads: Array = _food.get_meta("heads", [])
	if heads.is_empty():
		return false
	var order := range(heads.size())
	order.sort_custom(func(a: int, b: int) -> bool: return ((heads[a] as Array)[0] as Vector3).distance_to(from) < ((heads[b] as Array)[0] as Vector3).distance_to(from))
	var pick: int = order[0] if _head < 0 or order.size() < 2 else order[1 + rng.randi() % (order.size() - 1)]
	if pick == _head and order.size() > 1:
		pick = order[1]
	_head = pick
	var h: Array = heads[_head]
	var hp: Vector3 = h[0]
	var side := Vector3(from.x - hp.x, 0.0, from.z - hp.z)
	side = side.normalized() if side.length() > 0.01 else Vector3(cos(rng.randf() * TAU), 0.0, sin(rng.randf() * TAU))
	_cling = hp + side * 0.045 * bk - Vector3(0.0, 0.007, 0.0) # (on the head's rim, below its domed middle: the seeds before its feet, as the ground is when it pecks)
	_ride_at = hp
	_ride_k = float(h[2]) * float(h[2])
	_sub = "go" # (its spot on this head: from where it'll stand)
	_new_spot()
	return true


## (A seed's place on the head: on its disc, toward the bird's side.)
func _new_spot() -> void:
	if _head < 0:
		return
	var h: Array = (_food.get_meta("heads", []) as Array)[_head]
	var hp: Vector3 = h[0]
	var a := rng.randf() * TAU
	var r := rng.randf_range(0.0, 0.007)
	var back := Vector3(_pos.x - hp.x, 0.0, _pos.z - hp.z) if _mode == "seed" and _sub != "go" else Vector3(_cling.x - hp.x, 0.0, _cling.z - hp.z)
	back = back.normalized() if back.length() > 1e-4 else Vector3.RIGHT
	_spot = hp - back * 0.004 + Vector3(cos(a) * r, 0.0015, sin(a) * r) * 0.6 # (on the disc before its feet)


func _local(n: Node3D) -> Vector3:
	return get_parent().to_local(n.global_position)


# --- at it: picking, husking ----------------------------------------------------------

func _land(at: Vector3) -> void:
	var m := _mode
	var mt := _mt
	super(at)
	if m == "seed" and _food != null and is_instance_valid(_food):
		_to("seed", "reach")
		_ride_to = 1.0 if _head >= 0 else 0.0
		turn_to(_spot - _pos)
		_mt = mt
	elif m == "nest_feed":
		_to("nest_feed")


func _seed_step(dt: float) -> void:
	if _food == null or not is_instance_valid(_food) or (_head < 0 and (_berry == null or not is_instance_valid(_berry))):
		_leave()
		return
	var bk := body_k / 0.55
	var w: Vector3 = get_parent().to_global(_spot)
	turn_to(_spot - _pos)
	want.pitch = 1.0 # (tipped forward over it, its head down to it, as it pecks the ground)
	want.crouch = 0.3
	want.tail_up = tail_rest + 0.25
	want.tail_spread = 0.3
	rate["pitch"] = 8.0
	want.roll = 0.12 * sin(_mt * 1.1) * _ride # (holding on as it sways)
	match _sub:
		"reach": # (its bill down to the head, onto a seed)
			head_rate = 16.0
			head_point = w
			want.head_pitch = 0.55 if _head >= 0 else 0.2 # (its bill tipped down at the seed)
			want.pitch = 1.15 if _head >= 0 else 1.0
			want.jaw = 0.25
			rate["jaw"] = 20.0
			var miss: Vector3 = _spot - get_parent().to_local(bill_tip())
			if _st > 0.35 and miss.length() > 0.004: # (its grip shifted, sidling up or along the stem, till its bill's there)
				var step: Vector3 = miss.limit_length(0.05 * bk * dt)
				var np: Vector3 = _pos + step
				var anchor: Vector3 = _ride_at if _head >= 0 else _cling
				var near := Vector2(np.x - anchor.x, np.z - anchor.z).length() < (0.035 if _head >= 0 else 0.04 * bk) and (np.y - anchor.y > -0.01 and np.y - anchor.y < 0.004 if _head >= 0 else absf(np.y - anchor.y) < 0.04 * bk) # (on the head's disc; in the bush, by its berry)
				if near:
					_pos = np
					perch_at = _pos
			if bill_tip().distance_to(w) < 0.006 * maxf(bk, 0.7): # (its bill on it: a seed picked out; a bite of the berry)
				_take_bit()
				_sub = "husk"
				_st = 0.0
			elif _st > 3.0: # (not reached: another, or nearer)
				_n += 1
				if _n > 3:
					_leave()
					return
				_new_spot()
				_st = 0.0
		"husk": # (the seed turned in its bill, cracked, the husk dropped; the kernel swallowed)
			head_point = Vector3.INF
			want.head_pitch = -0.25
			head_want = Vector3(0.0, 0.004, 0.002) * bk
			want.jaw = 0.22 * maxf(0.0, sin(_st * 34.0))
			rate["jaw"] = 50.0
			if _st > (0.7 if _head >= 0 else 0.9):
				_swallow_bit()
				_picked += 1
				eaten += 1
				_n = 0
				hunger = maxf(hunger - 0.08, 0.0)
				if not _live_young().is_empty() or (male and _partner_sitting()):
					crop += 1
				_sub = "reach"
				_st = 0.0
				if _picked >= _want_n or (hunger <= 0.0 and crop >= 4):
					_leave()
					return
				if _picked % 5 == 0 and _head >= 0 and (_food.get_meta("heads", []) as Array).size() > 1: # (on to the next head on it)
					_to_next_head()
					return
				if _head < 0 and _picked % 3 == 0:
					_to_next_head()
					return
				_new_spot()


## (Hopped across to another head of the same plant, or another berry.)
func _to_next_head() -> void:
	head_point = Vector3.INF
	_drop_bit()
	_ride_to = 0.0
	if not _pick_head():
		_leave()
		return
	_to("seed", "go")
	_take_off("go", _cling, true)


func _take_bit() -> void:
	_drop_bit()
	_bit = MeshInstance3D.new()
	var sm := SphereMesh.new()
	var berry := _head < 0
	sm.radius = 0.0022 if berry else 0.0016
	sm.height = 0.004 if berry else 0.0045
	sm.radial_segments = 8
	sm.rings = 4
	_bit.mesh = sm
	var m := _bit_mat.duplicate() as ShaderMaterial
	var col := Color(0.22, 0.17, 0.12) # (a seed: dark, ridged)
	if berry:
		col = Color(0.15, 0.17, 0.42) if String(_food.get_meta("plant", "")).contains("blue") else Color(0.62, 0.08, 0.14)
	m.set_shader_parameter("albedo", col)
	_bit.material_override = m
	get_parent().add_child(_bit)
	_bit.global_position = bill_tip()


func _hold_bit() -> void:
	if _bit and is_instance_valid(_bit):
		_bit.global_position = bill_tip() + (bill_tip() - global_position).normalized() * -0.002
		var m := _bit.material_override as ShaderMaterial
		m.set_shader_parameter("ride_at", get_parent().to_global(_ride_at))
		m.set_shader_parameter("ride_k", _ride_k * _ride)


func _swallow_bit() -> void:
	if _bit and is_instance_valid(_bit) and _head >= 0: # (the husk: two halves, dropped, falling)
		for k in 2:
			_husk(_bit.global_position, k)
	_drop_bit()


func _drop_bit() -> void:
	if _bit and is_instance_valid(_bit):
		_bit.queue_free()
	_bit = null


## A husk's half, falling from its bill to the ground; gone a while after.
func _husk(at: Vector3, k: int) -> void:
	var h := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.0028, 0.0045, 0.0006)
	h.mesh = pm
	var m := _bit_mat.duplicate() as ShaderMaterial
	m.set_shader_parameter("albedo", Color(0.78, 0.72, 0.6) if k == 0 else Color(0.62, 0.56, 0.44))
	h.material_override = m
	get_parent().add_child(h)
	h.global_position = at
	var v := Vector3(rng.randf_range(-0.25, 0.25), 0.15, rng.randf_range(-0.25, 0.25))
	var spin := Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(-12.0, 12.0), 0.0)
	var t := 0.0
	var tree := get_tree()
	while is_instance_valid(h) and t < 8.0:
		await tree.process_frame
		var dt := minf(get_process_delta_time(), 0.05) if is_inside_tree() else 0.033
		t += dt
		var lp: Vector3 = h.position
		var gy := super._ground(lp.x, lp.z) if is_inside_tree() else 0.0
		if lp.y > gy + 0.001: # (fluttering down: light, slowed by the air)
			v.y = maxf(v.y - 9.8 * dt, -0.7)
			v.x *= 1.0 - 2.0 * dt
			v.z *= 1.0 - 2.0 * dt
			h.position += v * dt
			h.rotation += spin * dt
		else:
			h.position.y = gy + 0.0004
			h.rotation.x = PI * 0.5
	if is_instance_valid(h):
		h.queue_free()


func _leave() -> void:
	head_point = Vector3.INF
	_drop_bit()
	_ride_to = 0.0
	if _food and is_instance_valid(_food):
		_visited.append(_food)
		if _visited.size() > 2:
			_visited.pop_front()
	_food = null
	if not _live_young().is_empty() and crop >= 4 and nest_top != Vector3.INF: # (home with it, to the young)
		_to("nest_feed", "go")
		_take_off("go", nest_top + Vector3(0.05, 0.0, 0.0) * body_k / 0.55, true)
		return
	if male and crop >= 3 and _partner_sitting(): # (to her on the nest, to feed her)
		_to("nest_feed", "go")
		var nt: Vector3 = _mate.get("nest_top")
		_take_off("go", nt + Vector3(0.05, 0.0, 0.0) * body_k / 0.55, true)
		return
	var f := _find_food()
	if f and rng.randf() < 0.6:
		feed_at(f)
	elif home_perch != Vector3.INF:
		perch_on(home_perch)
	else:
		super.forage()


func _partner_sitting() -> bool:
	return _mate != null and is_instance_valid(_mate) and String(_mate.get("_mode")) in ["incubate", "brood"] and _mate.get("nest_top") != Vector3.INF


# --- the young, its mate: fed seed brought up -----------------------------------------

## Her eggs hatched: the young theirs, his to feed as well as hers.
func hatch() -> void:
	super()
	if _mate and is_instance_valid(_mate):
		_mate.set("young_ones", young_ones)
		_mate.set("nest_top", nest_top)


func _live_young() -> Array:
	return young_ones.filter(func(y: Variant) -> bool: return is_instance_valid(y) and y.get("young"))


## (At the nest: each nestling's gape in turn, its bill into it, its head
## pumping, seed brought up from its crop; a male's to his mate sitting: hers.)
func _nest_feed(dt: float) -> void:
	var live := _live_young()
	var mate_: Node3D = _mate if _partner_sitting() and live.is_empty() else null
	if (live.is_empty() and mate_ == null) or crop <= 0:
		crop = 0
		head_point = Vector3.INF
		forage()
		return
	var who: Node3D = mate_ if mate_ else live[_fed % live.size()]
	var wp: Vector3 = who.get("_pos")
	var bk := body_k / 0.55
	var away := Vector3(_pos.x - wp.x, 0.0, _pos.z - wp.z)
	away = away.normalized() if away.length() > 0.005 else Vector3(cos(_fed * 2.0), 0.0, sin(_fed * 2.0))
	var stand := wp + away * (0.075 if mate_ else 0.07) * bk # (on the cup's rim, facing it)
	if Vector2(stand.x - _pos.x, stand.z - _pos.z).length() > 0.006:
		_pos += (Vector3(stand.x, _pos.y, stand.z) - _pos).normalized() * minf(0.12 * bk * dt, Vector2(stand.x - _pos.x, stand.z - _pos.z).length())
	turn_to(wp - _pos)
	want.pitch = stand_pitch + 0.5
	want.crouch = 0.25
	want.jaw = 0.25
	rate["jaw"] = 10.0
	var gape: Vector3 = who.call("bill_tip")
	head_rate = 10.0
	head_point = gape + Vector3(0.0, 0.002 + 0.002 * sin(_mt * 11.0), 0.0) # (into its gape, pumping)
	who.set("_beg", 0.4)
	if mate_:
		mate_.set("head_point", bill_tip()) # (her bill up to his)
	if bill_tip().distance_to(gape) < 0.008 * maxf(bk, 0.7): # (bill in its gape: fed)
		_fed_mate += dt
		if _fed_mate > 1.2:
			_fed_mate = 0.0
			crop -= 1 if mate_ else 2
			if not mate_:
				who.set("_age", float(who.get("_age")) + grow_secs * 0.04)
			else:
				mate_.set("hunger", maxf(float(mate_.get("hunger")) - 0.25, 0.0))
				mate_.set("head_point", Vector3.INF)
			_fed += 1
			_st = 0.0
	elif _st > 5.0:
		_fed += 1
		_st = 0.0


# --- song, flight ------------------------------------------------------------------------

func _sing(_dt: float) -> void:
	# upright, its head up, its throat swelling: a long run of quick notes,
	# each its own length, its bill opening on each; its last held, falling
	want.head_pitch = -0.4
	head_want = Vector3(0.0, 0.005, -0.002) * body_k / 0.55
	var cyc := song_secs + 2.5
	var ph := fmod(_mt, cyc)
	var o := 0.0
	if ph < song_secs:
		var i := floorf(ph * song_hz)
		var r := fmod(sin(i * 12.9898 + floorf(_mt / cyc) * 7.0) * 43758.5453, 1.0)
		var note := fmod(ph * song_hz, 1.0)
		o = (0.2 + 0.25 * absf(r)) * sin(PI * clampf(note / (0.55 + 0.4 * absf(r)), 0.0, 1.0))
	elif ph < song_secs + song_tail: # (its burry wheer: held open, falling)
		o = 0.42 * (1.0 - (ph - song_secs) / song_tail * 0.6)
	want.jaw = o
	want.puff = 0.3 + o * 0.6
	rate["jaw"] = 45.0
	rate["puff"] = 20.0
	if _mt > _secs:
		want.jaw = 0.0
		want.puff = 0.0
		perch()


## (A male's.) His song flight: up, and about, singing (see the class).
func display_flight() -> void:
	if young or dead or _air:
		return
	_to("fly")
	_secs = 12.0
	_mt = 0.0
	var c := _pos if perch_at == Vector3.INF else perch_at
	_take_off("soar", Vector3(c.x, super._ground(c.x, c.z) + rng.randf_range(6.0, 10.0), c.z), false)
	_song_flight = true


func _fly_step(dt: float) -> void:
	var bt := _ride
	super(dt)
	if _fly.is_empty() or not _air:
		return
	var t := float(_fly.get("t", 0.0))
	var kind := String(_fly.get("kind", ""))
	if _song_flight:
		if kind != "soar":
			_song_flight = false
		else:
			_fly["hz"] = BirdFlight.wingbeat_hz(mass, span, wing_area) * flight_hz
			beat_amp = 1.45
			_flap = 1.0 if flight_hz < 0.8 or fmod(t, 3.0) < 1.6 else move_toward(_flap, 0.0, dt * 4.0)
			want.jaw = 0.3 * maxf(0.0, sin(t * song_hz * PI)) # (singing as it goes)
			rate["jaw"] = 40.0
			if _mt > _secs:
				_fly["kind"] = "go"
				_fly["to"] = home_perch if home_perch != Vector3.INF else Vector3(_pos.x, super._ground(_pos.x, _pos.z), _pos.z)
				_fly["land"] = true
				_song_flight = false
			return
	beat_amp = 1.0
	if kind != "go":
		return
	var to: Vector3 = _fly.to
	var hd := Vector2(to.x - _pos.x, to.z - _pos.z).length()
	if hd < 2.5 or t < 0.5:
		return
	# (bounding: a burst of beats, rising; its wings shut, swooping)
	var per := bound_secs.x + bound_secs.y
	var ph := fmod(t - 0.5, per)
	var ph0 := fmod(maxf(t - 0.5 - dt, 0.0), per)
	var up := ph < bound_secs.x
	var y := (sin(PI * 0.5 * ph / bound_secs.x) if up else cos(PI * 0.5 * (ph - bound_secs.x) / bound_secs.y)) * bound_m
	var y0 := (sin(PI * 0.5 * ph0 / bound_secs.x) if ph0 < bound_secs.x else cos(PI * 0.5 * (ph0 - bound_secs.x) / bound_secs.y)) * bound_m
	_pos.y += (y - y0) * smoothstep(2.5, 5.0, hd)
	if up:
		_flap = 1.0
		if ph0 > ph and bound_m > 0.25: # (each rise: its call)
			_beg = 0.35
	else:
		_flap = 0.0
		set_wings(-1.5, 0.0, 0.0, 0.0) # (shut, against its sides)
		rate["wl_up"] = 30.0
		rate["wr_up"] = 30.0
	_ride = bt


# --- courting: his display, her begging, courtship feeding --------------------------------

func _court(dt: float) -> void:
	if _partner == null or not is_instance_valid(_partner):
		perch()
		return
	var to: Vector3 = (_partner.get("_pos") as Vector3) - _pos
	var bk := body_k / 0.55
	if _mt < _secs - 3.0: # (his display: wings drooped and quivering, his tail raised and spread, puffed, singing, hopping about her)
		turn_to(to)
		want.puff = 0.8
		want.tail_spread = 0.9
		want.tail_up = tail_rest + 0.5
		set_wings(-1.25, 0.0, 0.0, 0.3 + 0.12 * sin(_mt * 45.0))
		want.droop = 0.7
		want.head_pitch = -0.35
		want.jaw = 0.3 * maxf(0.0, sin(_mt * song_hz * PI))
		rate["jaw"] = 40.0
		_yaw += 0.8 * sin(_mt * 1.7) * dt
		lift_y = 0.01 * bk * maxf(0.0, sin(_mt * 6.0)) # (little hops)
	else: # (courtship feeding: face to face, his bill in hers, his head pumping; she begging)
		lift_y = 0.0
		want.puff = 0.3
		want.droop = 0.0
		want.tail_up = tail_rest
		want.tail_spread = 0.2
		fold_wings()
		turn_to(to)
		_partner.call("turn_to", -to)
		_partner.set("_begging", true)
		var hers: Vector3 = _partner.call("bill_tip")
		var miss: Vector3 = get_parent().to_local(hers) - get_parent().to_local(bill_tip())
		var gap := Vector2(to.x, to.z).length()
		if miss.length() > 0.004 and gap > 0.03 * bk: # (in to her, till his bill's at hers)
			_pos += Vector3(miss.x, 0.0, miss.z).limit_length(0.08 * bk * dt)
		halt()
		head_rate = 9.0
		want.pitch = stand_pitch + 0.45 # (leaning down to her, into her raised bill)
		want.crouch = 0.2
		rate["pitch"] = 6.0
		head_point = hers + Vector3(0.0, 0.003 + 0.002 * sin(_mt * 11.0), 0.0) # (his head pumping, seed brought up)
		want.jaw = 0.2
		_partner.set("head_point", bill_tip())
		if bill_tip().distance_to(hers) < 0.008 * maxf(bk, 0.7):
			_fed_mate += dt
	if _mt > _secs and (_fed_mate > 1.0 or _mt > _secs + 8.0): # (on her back once she's been fed)
		_fed_mate = 0.0
		_mate = _partner
		_partner.set("_mate", self)
		_partner.set("_begging", false)
		_partner.set("head_point", Vector3.INF)
		head_point = Vector3.INF
		want.jaw = 0.0
		_to("mount")
		_secs = 3.0


func _beg_pose() -> void:
	# (as a nestling begs: crouched, her wings fluttering, her bill open, calling)
	want.crouch = 0.25
	want.pitch = stand_pitch
	want.head_pitch = -0.4 # (her bill raised to him)
	set_wings(-1.25, 0.0, 0.0, 0.25 + 0.15 * sin(_mt * 40.0))
	want.jaw = 0.45
	rate["jaw"] = 20.0
	var by: Node3D = _partner if _partner != null and is_instance_valid(_partner) else _mate
	if by == null or not is_instance_valid(by) or String(by.get("_mode")) not in ["court_g", "nest_feed"]:
		_begging = false
		head_point = Vector3.INF
		fold_wings()


func _think(dt: float) -> void:
	_ride = move_toward(_ride, _ride_to, dt * 2.0)
	super(dt)
	if _mat:
		_mat.set_shader_parameter("ride_at", get_parent().to_global(_ride_at) if get_parent() else _ride_at)
		_mat.set_shader_parameter("ride_k", _ride_k * _ride)
	if _air or dead or young:
		return
	match _mode:
		"seed":
			_seed_step(dt)
		"nest_feed":
			_nest_feed(dt)
		"incubate", "brood":
			if _mate and is_instance_valid(_mate) and String(_mate.get("_mode")) == "nest_feed": # (fed on the nest: up to him, begging)
				want.jaw = 0.4
				head_rate = 9.0
	if _begging:
		_beg_pose()


func _watch(dt: float) -> void:
	super(dt)
	if young or _mode != "perch":
		return
	if _st < 0.05 and hunger > 0.35 and rng.randf() < 0.5: # (hungry: off to the seed heads)
		forage()


func _to(mode: String, sub := "") -> void:
	if mode != "seed":
		_drop_bit()
		if mode != "fly":
			_ride_to = 0.0
	if _mode == "court_g" and mode != "court_g":
		lift_y = 0.0
	super(mode, sub)


func _process(dt: float) -> void:
	super(dt)
	_hold_bit()


func test_mode(mode: String) -> void:
	if mode.contains("feed"):
		_to("court_g")
		_partner = self
		_secs = 0.0
	elif mode.contains("display"):
		display_flight()
	else:
		super(mode)
