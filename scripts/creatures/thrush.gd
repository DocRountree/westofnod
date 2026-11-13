class_name Thrush
extends "res://scripts/creatures/raptor.gd"
## A thrush (the American robin, the eastern bluebird): a Raptor's make
## (perching, flying, nesting, its young raised: Raptor) made small, its
## bill thin and straight, its head round, its legs long, its wings short
## and rounded, its flight a quick flutter between glides. What's its own:
## - forage(): on the ground: a run (a hop), a stop, upright and still, its
##   head cocked to look down one eye at the ground (a robin's), a peck at
##   it; whatever it eats near enough, hunted. A bluebird's: from a low
##   perch, still, watching the ground; it drops down onto what moves
##   (pounce_from_perch), and back up
## - hunt(prey) (its diet, Diet: ants (a single copy of one at their nest:
##   the colony untouched), June beetles and their grubs, caterpillars,
##   spiders, snails): to it on the ground, running (from a perch, down
##   onto it first), stopped short of it, its head cocked; a stab of its
##   bill (taken only with its bill on it), a toss of its head, swallowed
##   whole in one gulp; with young in the nest, carried to them in its bill
##   instead, put whole into a nestling's gape (its bill to it), one a trip
## - singing (call_out): upright, its head up, its throat swelling, its bill
##   opening on each note, phrase after phrase (the robin's carolling
##   cheerily cheer-up, the bluebird's soft warble), a pause between
## - courting (mate): he to her on the ground, puffed out, his tail fanned
##   and dragged, his wings drooped and shivered, singing softly; on her back
## - nesting (lay): on its site (set_nest_site: the world's to give it; a
##   robin's a ledge, a fork; a bluebird's a nest box): a cup of dry grass
##   (the robin's walled with mud), its eggs sky blue, four; its nestlings
##   naked, grey downed, all gapes; fed insects bill to bill; fledging
##   spotted (the juvenile's speckled breast)
##
## A species gives thrush_shape() its measures, _plumage() and mass_of().

var pounces := false ## (a bluebird's: hunting from a perch, down onto it)
var song_notes := 4 ## (notes to a phrase)
var song_hz := 4.0 ## (notes a second)
var stand_pitch := 0.3 ## rad: its body tipped forward, standing (a hawk upright; a thrush leaning)
var walks := false ## (foraging at a walk, pecking as it goes: a pigeon's, a blackbird's; a thrush runs and stops)
var gapes := false ## (its bill pushed into the ground and opened, prying: a blackbird's)
var site_style := "shelf" ## (the nest site the world gives it: Raptor.nest_pole's style: "shelf", "box", "reeds", "" a branch)
var _hop_to := Vector3.INF
var _cock := 0.0


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	cruise = 8.0
	top_speed = 11.0
	stoop_speed = 0.0
	soar_height = 0.0
	flaps_glide = true
	hunt_style = "ground"
	nest_style = "cup"
	nest_height = 1.8
	nest_scale = 0.35
	eyas_scale = 0.5
	body_k = 0.55
	clutch = 4
	grow_secs = 150.0
	beat_amp = 1.0
	tail_rest = -1.0
	flight_pitch = 1.0
	fold_pitch = 0.8
	feather_cm = 1.6


## The body: a Cooper's hawk's lines (cm) made over small (k: its length of
## the hawk's), plumper, its head rounder and bigger (head), its bill thin
## and straight (bill: its length of a robin's), its legs (legs) and tail
## (tail_len, cm at its size) its own, its wings shorter, rounded (wing).
##
## plump: its body's girth (a thrush's 1.12, a dove's sleek); bill_deep: its
## bill's depth at its root (a blackbird's conical, deep); tail_grad: its
## outer tail feathers that much shorter (a dove's pointed, graduated tail);
## snout: its forehead drawn forward and down (the hawk's cm), tapering
## smooth into the bill's root (a dove's: no round brow, head into bill in
## one line); neck: its neck that much longer; crown: its head's height
## (a dove's low and sleek).
func thrush_shape(k: float, head: float, bill: float, legs: float, tail_len: float, wing: float, plump := 1.12, bill_deep := 1.0, tail_grad := 0.07, snout := 0.0, neck := 1.0, crown := 1.0) -> Dictionary:
	var B := plump
	var hj := Vector2(36.5, -4.7) # (the hawk's head joint)
	var nl := (neck - 1.0) * 2.2 # (a longer neck: the head and the neck's top lifted, cm)
	var hawk := [[13.5, 13.0, 1.0, 1.0, 0.0], [14.6, 11.0, 3.8, 3.5, 0.0], [16.2, 8.0, 4.6, 5.8, 0.0], [19.2, 4.8, 5.1, 7.2, 0.0], [23.0, 2.0, 5.2, 7.3, 0.0],
			[27.0, 0.0, 4.8, 6.4, 0.0], [30.0, -1.0, 4.0, 5.0, 0.2], [32.0, -1.5, 3.4, 3.7, 1.0], [33.6, -2.0, 3.0, 3.2, 2.0], [34.9, -2.7, 2.8, 3.0, 3.0],
			[35.9, -3.6, 2.7, 2.9, 4.0], [36.5, -4.7, 2.5, 2.6, 4.5], [36.3, -6.2, 2.0, 2.1, 4.85]]
	var hp := func(y: float, z: float, c: float) -> Vector2:
		var q := Vector2(y, z)
		if c >= 4.5:
			q = hj + (q - hj) * head
		q.x += nl * clampf((c - 0.5) / 4.0, 0.0, 1.0)
		return q * k
	var spine := []
	if snout > 0.0: # (a dove's: no round face; the crown runs straight on down into the bill; the neck's turn into the head eased)
		hawk = hawk.slice(0, hawk.size() - 2)
		hawk.append([36.3, -4.15, 2.6, 2.75, 4.25])
		hawk.append([36.45, -4.75, 2.45, 2.5, 4.5])
	for e: Array in hawk:
		var c: float = e[4]
		var q: Vector2 = hp.call(e[0], e[1], c)
		var s := head if c >= 4.5 else B
		var hh := lerpf(1.0, crown, smoothstep(1.5, 4.5, c)) # (its crown, its throat: lower; eased in down the neck)
		var nk := 1.0 - (0.18 * smoothstep(0.5, 2.5, c) * (1.0 - smoothstep(4.0, 4.6, c)) if snout > 0.0 else 0.0) # (a dove's slender neck)
		spine.append([q.x, q.y, float(e[2]) * k * s * nk, float(e[3]) * k * s * hh * nk, c])
	# (a dove's forehead: drawn forward and down, tapering into the bill)
	var root: Vector2 = hp.call(36.0, -6.9, 4.9)
	if snout > 0.0: # (its forehead sloping down and forward from its crown into the bill; its chin rising to it)
		var run := 1.5 + snout
		for e: Array in [[0.2, 2.42, 2.5, 4.75], [0.42, 2.2, 2.25, 4.82], [0.62, 1.8, 1.8, 4.88], [0.8, 1.3, 1.3, 4.93], [0.93, 0.85, 0.9, 4.97], [1.0, 0.62, 0.7, 4.985]]:
			var f := float(e[0])
			var q: Vector2 = hp.call(36.5 - 0.3 * f, -4.7 - f * run, 4.9) # (down a little to the bill)
			spine.append([q.x, q.y, float(e[1]) * k * head, float(e[2]) * k * head * crown, e[3]])
		root = hp.call(36.5 - 0.34, -4.7 - run - 0.05, 4.9)
	# (its bill: thin, straight, a little down at its tip; from the face, cm at its size)
	var L := 1.9 * bill
	for b: Array in [[0.0, 0.0, 0.42, 0.4, 5.0], [0.12, -0.03, 0.34, 0.33, 5.05], [0.5, -0.1, 0.2, 0.19, 5.5], [0.85, -0.2, 0.09, 0.08, 5.85], [1.0, -0.26, 0.03, 0.03, 6.0]]:
		var dk := lerpf(bill_deep, 1.0, float(b[0])) # (deep at its root, to its point)
		var bw := float(b[2]) * L * 0.55 * dk
		var bh := float(b[3]) * L * 0.55 * dk
		if snout > 0.0: # (a dove's: the bill its forehead's taper carried on, never wider than it)
			var last: Array = spine[spine.size() - 1] if float((spine[spine.size() - 1] as Array)[4]) < 5.0 else []
			if not last.is_empty() or _snout_end.size() > 0:
				if not last.is_empty():
					_snout_end = [float(last[2]), float(last[3])]
				var t := float(b[2]) / 0.42 # (this ring's share of the root's)
				bw = minf(bw, float(_snout_end[0]) * 0.92 * t)
				bh = minf(bh, float(_snout_end[1]) * 0.92 * t)
		spine.append([root.x + float(b[1]) * L, root.y - float(b[0]) * L, bw, bh, b[4]])
	var lb := []
	for b: Array in [[0.1, -0.2, 0.17], [0.55, -0.22, 0.1], [0.92, -0.27, 0.03]]:
		var lw := float(b[2]) * L * 0.55 * lerpf(bill_deep, 1.0, float(b[0]))
		if snout > 0.0 and _snout_end.size() > 0:
			lw = minf(lw, float(_snout_end[0]) * 0.92 * float(b[2]) / 0.42)
		lb.append([root.x + float(b[1]) * L, root.y - float(b[0]) * L, lw])
	_snout_end = []
	var p3 := func(v: Vector3, c: float) -> Vector3:
		var q: Vector2 = hp.call(v.y, v.z, c)
		return Vector3(v.x * k * (head if c >= 4.5 else B), q.x, q.y)
	var S := {
		"tilt_rings": true,
		"spine": spine,
		"pivot": Vector3(0.0, 20.0, 4.0) * k,
		"jaw": Vector3(0.0, root.x - 0.12 * L, root.y - 0.02 * L),
		"lower_bill": lb,
		"eye": p3.call(Vector3(1.85, 36.4, -5.4), 4.6), "eye_r": 0.62 * k * head * 1.2, "eye_ring": 1.2,
		"hip": Vector3(2.9 * B, 16.5 * legs, 4.0) * k, "knee": Vector3(3.2 * B, 12.0 * legs, 0.5) * k, "ankle": Vector3(2.9 * B, 6.0 * legs, 1.0) * k, "foot": Vector3(2.9 * B, 1.0, 0.0) * k,
		"thigh_r": [3.0 * k * B, 1.9 * k * B], "leg_r": 0.38 * k, "toes": [3.6 * k, 2.6 * k, 2.4 * k], "claw": 0.28, "claw_r": 0.45,
		"tuck": Vector3(0.0, -0.05, 0.0),
		"tail": Vector3(0.0, 14.0, 12.0) * k,
		"shoulder": Vector3(5.2 * B, 25.5, 4.6) * k, "wing": Vector3(7.5, 9.0, 6.0) * k * wing, "coverts": [2.2 * k, 5.0 * k * wing, 4.0 * k * wing, 2.0 * k],
		"fold_fan": Vector3(0.1, 0.15, 0.0), "fold_tuck": 0.3, "fold_tuck_front": 3.0, "wing_thick": [1.1 * k, 0.8 * k, 0.55 * k, 0.25 * k],
		"primaries": [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 15.5, 15.5, 14.5, 12.5].map(func(x: float) -> float: return x * k * wing),
		"secondaries": [9, 12.0 * k * wing, 11.0 * k * wing], "tertials": [3, 9.0 * k * wing, 8.0 * k * wing], "feather_w": 4.2 * k * wing,
		"tail_feathers": [12, tail_len, 4.2 * k], "tail_coverts": [[10, 7.0 * k, 3.5 * k, 0.5, 0.9]], "tail_grad": tail_grad,
	}
	return S


func _build() -> void:
	super()
	if _mat:
		_mat.set_shader_parameter("bill_cere", 0.0) # (no cere: the bill its own colour to its root)
	if not young:
		want.pitch = stand_pitch
		cur.pitch = stand_pitch
	walk_speed = 0.25 * body_k / 0.55
	run_speed = 1.6 * body_k / 0.55


# --- foraging on the ground ------------------------------------------------------------

## On the ground, foraging (down off its perch to it, if it's up).
func forage() -> void:
	if young or dead:
		return
	if perch_at != Vector3.INF or _air:
		var a := rng.randf() * TAU
		var at := _pos + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(2.0, 5.0)
		at.y = super._ground(at.x, at.z)
		_to("fly")
		_take_off("go", at, true)
		_then_forage = true
		return
	_to("forage")


var _then_forage := false
var _snout_end := [] # (thrush_shape's: the forehead taper's last ring, for the bill's root)


## What it goes for, foraging (its diet's: Diet; a thrush's its prey, a
## pigeon's its seeds too).
func _meal_kinds() -> Array:
	return Diet.prey_of(self)


## (A thrush doesn't soar: down to forage instead.)
func soar(_secs := 40.0) -> void:
	forage()


## Its prey (a creature, or a copy of one: Diet), hunted on the ground.
func hunt(prey: Node3D) -> void:
	if young or dead or prey == null or not is_instance_valid(prey):
		return
	_prey = prey
	prey.set_meta("hunted", self)
	var pp := _prey_pos()
	_to("hunt", "run")
	_tries = 0
	if perch_at != Vector3.INF or _air: # (down onto it: a bluebird's drop from its perch)
		var away := Vector3(_pos.x - pp.x, 0.0, _pos.z - pp.z).normalized() * 0.1 * body_k / 0.55
		_take_off("go", Vector3(pp.x, super._ground(pp.x, pp.z), pp.z) + away, true)


var _tries := 0


func _prey_pos() -> Vector3:
	if _prey == null or not is_instance_valid(_prey):
		return _pos
	return Diet._at(_prey) + Vector3(0.0, _mid_y(_prey), 0.0)


## (A thing's middle above its origin, m: its meshes' bounds; what the bill
## goes to, its side, not the ground under it.)
static func _mid_y(n: Node) -> float:
	if n.has_meta("mid_y"):
		return float(n.get_meta("mid_y"))
	var lo := INF
	var hi := -INF
	if not (n is Node3D) or not n.is_inside_tree():
		return 0.0
	var parts: Array = n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D:
		parts.append(n)
	for c in parts:
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var b: AABB = mi.get_aabb()
		for k in 8:
			var y := (mi.global_transform * b.get_endpoint(k)).y - (n as Node3D).global_position.y
			lo = minf(lo, y)
			hi = maxf(hi, y)
	var m := 0.0 if lo == INF else clampf((lo + hi) * 0.5, 0.0, 0.05)
	n.set_meta("mid_y", m)
	return m


func _land(at: Vector3) -> void:
	var m := _mode
	var tf := _then_forage
	_then_forage = false
	var ms := _secs
	super(at)
	if m == "hunt" and _prey != null and is_instance_valid(_prey):
		_to("hunt", "run")
	elif m == "court_g":
		_to("court_g")
		_secs = ms
	elif tf:
		_to("forage")


func _think(dt: float) -> void:
	super(dt)
	if _air or dead or young:
		return
	match _mode:
		"forage":
			_forage(dt)
		"hunt":
			_hunt_ground(dt)
		"swallow":
			_swallow(dt)
		"call":
			_sing(dt)
		"court_g":
			_court(dt)


func _forage(dt: float) -> void:
	# a run (a bluebird's, hops), a stop: upright and still, its head cocked,
	# looking down one eye at the ground; a peck; on
	hunger = minf(hunger + dt / 120.0, 1.0)
	var bk := body_k / 0.55
	if walks:
		_forage_walk(dt)
		return
	match _sub:
		"", "look": # (still, its head cocked, looking)
			halt()
			look_yaw = 0.0
			want.roll = 0.18 * _cock
			want.head_pitch = 0.3
			head_want = Vector3(0.004 * _cock, 0.004, 0.0) * bk
			if _st > 1.0 and hunger > 0.15: # (what it eats, near enough: run to it)
				var f := Diet.find_one(self, 3.0, _meal_kinds())
				if f and f != self:
					hunt(f)
					return
			if _st > 1.5:
				_sub = "peck" if rng.randf() < 0.5 else "run"
				_st = 0.0
				want.roll = 0.0
		"peck": # (a peck at the ground before it)
			var at := _pos + _fwd() * 0.05 * bk
			at.y = super._ground(at.x, at.z)
			head_rate = 18.0
			head_point = get_parent().to_global(at) if _st < 0.3 else Vector3.INF
			if _st > 0.6:
				_sub = "run"
				_st = 0.0
		"run": # (on, a few quick steps)
			if _hop_to == Vector3.INF:
				var a := _yaw + rng.randf_range(-1.2, 1.2)
				_hop_to = _pos + Vector3(-sin(a), 0.0, -cos(a)) * rng.randf_range(0.25, 0.8) * bk
				walk_to(_hop_to, run_speed)
			if arrived() or _st > 2.5:
				_hop_to = Vector3.INF
				halt()
				_cock = -_cock if _cock != 0.0 else 1.0
				_sub = "look"
				_st = 0.0
				_n += 1
				if _n > 6 and rng.randf() < 0.25: # (now and then up to a perch, or a song)
					_n = 0
					if home_perch != Vector3.INF and rng.randf() < 0.5:
						perch_on(home_perch)
					else:
						call_out(rng.randf_range(5.0, 9.0))


func _forage_walk(dt: float) -> void:
	# a slow walk, its head nodding with each step, a peck every few steps
	# (a blackbird's bill pushed into the ground and opened, prying); now
	# and then a look round; what it eats near enough, gone for
	var bk := body_k / 0.55
	if _hop_to == Vector3.INF or arrived():
		var a := _yaw + rng.randf_range(-0.9, 0.9)
		_hop_to = _pos + Vector3(-sin(a), 0.0, -cos(a)) * rng.randf_range(0.3, 1.0) * bk
		walk_to(_hop_to, walk_speed)
	var ph := fmod(_st, 1.6)
	if ph > 1.15: # (a peck at the ground before it)
		var at := _pos + _fwd() * 0.06 * bk
		at.y = super._ground(at.x, at.z)
		head_rate = 18.0
		head_point = get_parent().to_global(at)
		if gapes and ph > 1.3: # (prying: its bill opened in the ground)
			want.jaw = 0.7
			rate["jaw"] = 20.0
	else:
		head_point = Vector3.INF
		want.jaw = 0.0
	if _st > 1.6:
		_st = 0.0
		_n += 1
		if hunger > 0.15:
			var f := Diet.find_one(self, 3.0, _meal_kinds())
			if f and f != self:
				hunt(f)
				return
		if _n > 8 and rng.randf() < 0.2: # (now and then up to a perch, or a call)
			_n = 0
			if home_perch != Vector3.INF and rng.randf() < 0.5:
				perch_on(home_perch)
			else:
				call_out(rng.randf_range(4.0, 8.0))
	hunger = minf(hunger + dt / 120.0, 1.0)


func _hunt_ground(_dt: float) -> void:
	if _prey == null or not is_instance_valid(_prey):
		_give_up_ground()
		return
	var pp := _prey_pos()
	var to := Vector3(pp.x - _pos.x, 0.0, pp.z - _pos.z)
	var reach := 0.09 * body_k / 0.55 # (its feet to its bill's tip, leaning down to the ground)
	match _sub:
		"run": # (to it, at a run; stopped short of it)
			if to.length() <= reach * 1.15:
				halt()
				turn_to(to)
				_sub = "cock"
				_st = 0.0
			elif to.length() < reach * 2.5: # (the last steps: short, its own; finer than a walk's)
				halt()
				var turn := wrapf(atan2(-to.x, -to.z) - _yaw, -PI, PI)
				_yaw += clampf(turn, -4.0 * _dt, 4.0 * _dt)
				if absf(turn) < 0.6: # (a shuffle nearer: its feet stepping after it)
					_pos += to.normalized() * minf(0.15 * body_k / 0.55 * _dt, maxf(to.length() - reach, 0.0))
					_pos.y = super._ground(_pos.x, _pos.z)
			elif arrived() or Vector2(_goal.x - (pp.x - to.normalized().x * reach * 0.8), _goal.z - (pp.z - to.normalized().z * reach * 0.8)).length() > 0.03:
				walk_to(pp - to.normalized() * reach * 0.8, run_speed if to.length() > reach * 3.0 else walk_speed)
			if _st > 12.0:
				_give_up_ground()
		"cock": # (its head cocked, looking down at it)
			turn_to(to)
			look_yaw = 0.0
			want.roll = 0.2
			want.head_pitch = 0.4
			if _st > 0.4:
				want.roll = 0.0
				_sub = "stab"
				_st = 0.0
		"stab": # (a stab of its bill: tipped forward, down, its bill to it)
			want.pitch = 1.05
			want.crouch = 0.35
			rate["pitch"] = 14.0
			head_rate = 24.0
			var w: Vector3 = get_parent().to_global(pp)
			head_point = w
			if bill_tip().distance_to(w) < 0.012 * maxf(body_k / 0.55, 0.7): # (its bill on it)
				_seize()
			elif _st > 0.8: # (short: a step closer, again)
				head_point = Vector3.INF
				_tries += 1
				if _tries > 4:
					_give_up_ground()
				else:
					_sub = "run"
					_st = 0.0
					walk_to(pp - to.normalized() * reach * 0.5, walk_speed)
		_:
			_sub = "run"


func _give_up_ground() -> void:
	if _prey and is_instance_valid(_prey):
		_prey.remove_meta("hunted")
	_prey = null
	head_point = Vector3.INF
	forage()


# (it held in its bill: to its young, if it has them; else swallowed whole)
func _seize() -> void:
	var p := _prey
	_prey = null
	head_point = Vector3.INF
	Meal.subdue(p)
	_carry = p
	_carry_kind = "insect"
	_carry_left = 1.0
	hunger = 0.0
	if not young_ones.is_empty() and nest_top != Vector3.INF:
		_to("carrying")
		_take_off("carry", nest_top, true)
	else:
		_to("swallow")


func _swallow(_dt: float) -> void:
	# held in its bill, a toss of its head, and down in one gulp
	if _carry == null or not is_instance_valid(_carry):
		_carry = null
		forage()
		return
	head_rate = 18.0
	if _st < 0.35: # (its head up, its bill tipped back)
		want.head_pitch = -0.6
		head_want = Vector3(0.0, 0.008, 0.004) * body_k / 0.55
		want.jaw = 0.25
	else: # (gulped: gone)
		want.jaw = 0.0
		_carry.queue_free()
		_carry = null
		head_want = Vector3.ZERO
		forage()


## (What it's caught: in its bill.)
func _hold_carry() -> void:
	if _carry == null or not is_instance_valid(_carry):
		return
	_carry.global_position = bill_tip() # (in its bill, whole: swallowed in one gulp)


func _drop_carry() -> void:
	if _carry and is_instance_valid(_carry):
		_carry.queue_free()
	_carry = null
	_plucks = null


## (At the nest, what it's brought: into the gape of one nestling, the next
## time the next's; and off again for more.)
func _feed_young(_dt: float) -> void:
	var live: Array = young_ones.filter(func(y: Variant) -> bool: return is_instance_valid(y) and y.get("young"))
	if _carry == null or not is_instance_valid(_carry) or live.is_empty():
		_drop_carry()
		forage()
		return
	var who: Node3D = live[_fed % live.size()]
	var gape: Vector3 = who.call("bill_tip")
	var wp: Vector3 = who.get("_pos")
	var away := Vector3(_pos.x - wp.x, 0.0, _pos.z - wp.z)
	away = away.normalized() if away.length() > 0.005 else -Vector3(-sin(float(who.get("_yaw"))), 0.0, -cos(float(who.get("_yaw"))))
	var stand := wp + away * 0.09 * body_k / 0.55 # (beside it, leaning over to its gape)
	if Vector2(stand.x - _pos.x, stand.z - _pos.z).length() > 0.01 and _sub != "at":
		walk_to(stand, walk_speed)
		if _st > 2.0:
			_pos = _pos.lerp(stand, 0.2) # (shuffled over on the nest's rim)
		return
	_sub = "at"
	halt()
	turn_to(wp - _pos)
	want.pitch = 0.95 # (tipped forward, down over it: its gape low in the cup)
	want.crouch = 0.3
	rate["pitch"] = 8.0
	head_rate = 10.0
	head_point = gape + Vector3(0.0, 0.003, 0.0)
	who.set("_beg", 0.5)
	if bill_tip().distance_to(gape) < 0.012 * maxf(body_k / 0.55, 0.7): # (bill to its gape: taken, swallowed whole)
		who.set("_age", float(who.get("_age")) + grow_secs * 0.05)
		_drop_carry()
		_fed += 1
		head_point = Vector3.INF
		forage()
	elif _st > 4.0: # (not reached it: nearer, again)
		_sub = ""
		_st = 0.0


var _fed := 0


# --- song ------------------------------------------------------------------------------

func _sing(_dt: float) -> void:
	# upright, its head up, its throat swelling, its bill opening on each note
	want.head_pitch = -0.35
	head_want = Vector3(0.0, 0.006, -0.002) * body_k / 0.55
	var phrase := song_notes / song_hz
	var ph := fmod(_mt, phrase + 1.1)
	var on := ph < phrase
	var note := fmod(ph * song_hz, 1.0)
	want.jaw = (0.35 * sin(PI * note) if on else 0.0)
	want.puff = 0.25 + (0.25 * sin(PI * note) if on else 0.0)
	rate["jaw"] = 40.0
	rate["puff"] = 20.0
	if _mt > _secs:
		want.jaw = 0.0
		want.puff = 0.0
		perch()


# --- its own ways, perched -------------------------------------------------------------

func _watch(dt: float) -> void:
	if young:
		super(dt)
		return
	if perch_at == Vector3.INF: # (on the ground: foraging)
		_to("forage")
		return
	look_yaw = lerpf(look_yaw, 1.0 * sin(floor(_mt / 1.6) * 2.7), 1.0 - exp(-10.0 * dt)) # (quick looks about)
	want.tail_yaw = 0.0
	if fmod(_mt, 4.0) < 0.3: # (its tail flicked, its wings flicked)
		want.tail_up = tail_rest + 0.3 * sin(_mt * 30.0)
		rate["tail_up"] = 25.0
	if _st > 4.0:
		_st = 0.0
		hunger = minf(hunger + 0.06, 1.0)
		var r := rng.randf()
		if pounces and hunger > 0.3: # (watching the ground below: down onto what's there)
			var f := Diet.find_one(self, 8.0, _meal_kinds())
			if f and f != self:
				f.set_meta("hunted", self)
				hunt(f)
				return
		if r < 0.22:
			call_out(rng.randf_range(6.0, 12.0))
		elif r < 0.3:
			preen(rng.randf_range(4.0, 8.0))
		elif r < 0.36:
			rouse()
		elif r < (0.5 if pounces else 0.62):
			forage()


# --- courting ------------------------------------------------------------------------------

## (A male's.) To her where she is, his display on the ground, then on her
## back. False if they can't.
func mate(female: Node3D, secs := -1.0) -> bool:
	if not male or young or juvenile or dead or female == null or not is_instance_valid(female) or female == self:
		return false
	if female.get("male") or female.get("young") or female.get("dead") or female.get("gravid") or female.get("_mode") in ["nest", "incubate", "brood"]:
		return false
	_partner = female
	female.call("_to", "courted")
	female.set("_partner", self)
	var fp: Vector3 = female.get("_pos")
	var to := fp + Vector3(0.12, 0.0, 0.08) * body_k / 0.55
	to.y = super._ground(to.x, to.z) if (female.get("perch_at") as Vector3) == Vector3.INF else (female.get("perch_at") as Vector3).y
	_to("court_g")
	_secs = secs if secs > 0.0 else 6.0
	if Vector2(to.x - _pos.x, to.z - _pos.z).length() > 0.5 or absf(to.y - _pos.y) > 0.2:
		_take_off("go", to, true)
	return true


func is_mating() -> bool:
	return _partner != null and is_instance_valid(_partner) and _mode in ["court_g", "court", "mount"]


func _court(dt: float) -> void:
	# puffed out, his tail fanned and pressed down, his wings drooped and shivering, singing softly, turning before her
	if _partner == null or not is_instance_valid(_partner):
		perch()
		return
	var to: Vector3 = (_partner.get("_pos") as Vector3) - _pos
	turn_to(to)
	want.puff = 0.8
	want.tail_spread = 0.9
	want.tail_up = tail_rest - 0.35
	set_wings(-1.25, 0.0, 0.0, 0.25 + 0.1 * sin(_mt * 40.0))
	want.droop = 0.6
	want.jaw = 0.15 * maxf(0.0, sin(_mt * 12.0))
	rate["jaw"] = 30.0
	_yaw += 0.6 * sin(_mt * 1.5) * dt # (turning this way and that before her)
	if _mt > _secs:
		_to("mount")
		_secs = 4.0


func _to(mode: String, sub := "") -> void:
	_hop_to = Vector3.INF
	want.droop = 0.0
	super(mode, sub)
	if not _air and mode not in ["incubate", "brood", "eyas", "dead"]:
		want.pitch = stand_pitch


func test_mode(mode: String) -> void:
	if mode.contains("forage"):
		forage()
	elif mode.contains("sing"):
		call_out(60.0)
	elif mode.contains("court"):
		_to("court_g")
		_partner = self
		_secs = 60.0
	else:
		super(mode)


## A songbird's nestling: the hawk's eyas's body, its bill short and wide,
## all gape, its yellow flanges at its corners.
func _eyas() -> Dictionary:
	var e := super()
	var sp: Array = (e.spine as Array).filter(func(r: Array) -> bool: return float(r[4]) < 4.96)
	for r: Array in [[31.8, -7.9, 1.9, 1.0, 5.0], [31.6, -8.8, 1.6, 0.8, 5.3], [31.4, -9.7, 1.0, 0.5, 5.7], [31.3, -10.3, 0.35, 0.25, 6.0]]:
		sp.append(r)
	e.spine = sp
	e.jaw = Vector3(0.0, 31.6, -7.7)
	e.lower_bill = [[31.0, -8.3, 1.8], [30.8, -9.4, 0.9], [30.7, -10.1, 0.3]]
	e.erase("cere")
	e.claw = 0.12
	return e


func _process(dt: float) -> void:
	super(dt)
	_hold_carry() # (again, its pose solved: in its bill this frame, not the last)
