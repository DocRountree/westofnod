class_name Mantis
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A Carolina mantis (Stagmomantis carolina), drawn at twice life size (an
## adult female about 110 mm long): grey-green to brown, mottled; the
## prothorax long and narrow, held raised; the head a triangle that turns
## to look, big eyes at its corners, fine antennae; the raptorial forelegs
## folded up before it (coxa, a spined femur, the tibia closing back on it
## like a jackknife); four long thin walking legs; the abdomen broad, flat,
## the forewings over it (shorter than it: a female's), a dark spot on
## each, the hindwings smoky under them. A nymph (Mantis.new(true, size)):
## wingless, slender, its abdomen held curled up over its back; growing.
## Not yet in the game (tools/creatures/ecology_demo.tscn).
##
## - stalk(centre, radius): stepping slowly about, rocking side to side
##   like a leaf in the wind, stopping to watch, the head turning
## - watch(point): still, its head following point
## - strike(target, prey): turning to it, up within reach, drawing back,
##   and the forelegs shooting out and snapping shut; prey (a Node3D:
##   an insect: a grasshopper nymph, say) caught, held to its mouth and
##   eaten; then grooming
## - groom(): drawing each foreleg through its mouth, cleaning it
## - fly(to): the forewings up, the hindwings out and whirring, off and
##   down at `to` (the adult's)
## - lay(at): an egg case (an ootheca: Ootheca) built at `at` (a point on a
##   stem behind it, low): the abdomen's tip on it, working side to side,
##   the foam growing; later hatching (Ootheca.hatch): nymphs out along
##   its seam, each let down on a thread, and off
## - mate(her) (a male's: Mantis.new() with male set): he creeps up behind
##   her, freezes, swaying, then leaps onto her back, his forelegs clasping
##   her, his abdomen curled down round to hers; done, he slips off beside
##   her and stands a moment too long: she turns on him, strikes, seizes
##   him in her forelegs, wrenches his head off and eats it, then eats the
##   rest of him, from the neck back; then grooms. A male (smaller,
##   slimmer: his abdomen narrow, his forewings covering it; otherwise as
##   she is)

const LEGS := [
	# (the forelegs: raptorial, posed by hand, not walked: these unused)
	{"hip": Vector3(1.3, -0.8, -12.0), "f": 4.0, "t": 4.0, "s": 2.0, "home": Vector2(4.0, -16.0), "dangle": Vector3(2.0, -3.0, -14.0), "walks": false, "r": 0.3},
	{"hip": Vector3(1.6, -0.9, -3.0), "f": 12.0, "t": 11.0, "s": 6.0, "home": Vector2(15.0, -6.0), "dangle": Vector3(6.0, -7.0, -4.0), "pole": Vector3(0.45, 1.0, -0.2), "r": 0.38},
	{"hip": Vector3(1.8, -0.9, -0.5), "f": 14.0, "t": 13.0, "s": 7.0, "home": Vector2(14.0, 10.0), "dangle": Vector3(6.0, -7.0, 8.0), "pole": Vector3(0.5, 1.0, 0.25), "r": 0.38},
]

var oothecae: Array[Node3D] = [] ## the egg cases it's built (in its parent)
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.2
var _wait := 0.0
var _st := 0.0
var _stage := 0
var _at := Vector3.ZERO
var _look := Vector3.INF # (its parent's space)
var _prey: Node3D
var _held := false # (no longer: its prey's never moved, pinned where it was struck)
var _seized_it := false
var _bite_pitch := 0.2 # (its prothorax's pitch, eating: its mouth to the next bite)
const PIN := Vector3(0.8, 0.6, 2.8) # (its forelegs reached out, the tibiae snapped shut: pinning its prey where it is)
# a mantis (a male) as her prey: his head torn off (0..1)
var _rip := 0.0
var _meal: Node3D # (its prey, eaten piece by piece: Meal)
const MealScript := preload("res://scripts/creatures/meal.gd")
var _pro: Node3D # the prothorax (raised)
var _head: Node3D
var _jaws: Array[Node3D] = []
var _antennae: Array[Node3D] = []
var _abdomen: Node3D
var _teg: Array[Node3D] = []
var _hind: Array[Node3D] = []
var _fore: Array = [] # each side: [coxa, femur, tibia] pivots
# the forelegs' pose (rad, each joint on the last, forward from straight
# down; the prothorax raised _pro_pitch under them all: the coxa, the femur
# from it, the tibia closed back on the femur), each side, what's asked and
# as it is. At rest: the coxae hanging nearly straight down from the
# prothorax's front, the femurs angled forward and up under the head, the
# tibiae folded back along them
const FORE_REST := Vector3(-0.25, 1.95, 2.8)
var _ask := [FORE_REST, FORE_REST]
var _now := [FORE_REST, FORE_REST]
var _fore_rate := 8.0
var _pro_pitch := 0.5
var _chew := 0.0
var _wings := 0.0
var _ooth: Node3D
var _sw := 0.0


func _init(nymph_ := false, size_ := 1.0) -> void:
	super(nymph_, size_)
	legs = LEGS
	tripod = [[2, 5], [3, 4]]
	body_h = 7.5
	walk_speed = 0.02
	stride = 9.0
	step_time = 0.2


func _build() -> void:
	var green := Color(0.47, 0.5, 0.3) if not nymph else Color(0.55, 0.5, 0.36)
	var body := _banded(green, 0.0, 0.0, 0.35, 0.4) # (mottled)
	var pale := _banded(green.lightened(0.15), 0.0, 0.0, 0.25, 0.4)
	var eye := _mat(Color(0.55, 0.6, 0.42), 0.15)
	# the prothorax, long and narrow, raised from its joint
	_pro = Node3D.new()
	_pro.position = Vector3(0.0, 0.8, -4.0)
	_body.add_child(_pro)
	_pro.add_child(_mesh(_loft([[0.6, 0.0, 0.4, 0.4], [0.0, 0.0, 1.6, 1.4], [-2.0, 0.0, 1.8, 1.5], [-4.5, 0.1, 1.15, 1.1], [-10.0, 0.2, 1.0, 1.0], [-14.0, 0.2, 1.5, 1.25], [-16.5, 0.2, 1.0, 0.9], [-17.2, 0.2, 0.3, 0.3]]), body))
	# the head: a triangle, the eyes at its corners; it turns to look
	_head = Node3D.new()
	_head.position = Vector3(0.0, 0.6, -17.0)
	_pro.add_child(_head)
	# (a triangle, point down: a broad crown between the eyes, the face
	# narrowing below it to the mouth; three simple eyes between the
	# antennae)
	_part(Vector3(0.0, 1.5, -1.0), Vector3(6.4, 2.3, 2.6), body, _head)
	_part(Vector3(0.0, 0.1, -1.4), Vector3(4.2, 3.0, 2.3), body, _head)
	_part(Vector3(0.0, -1.5, -1.8), Vector3(2.4, 2.0, 1.7), pale, _head)
	var amber := _mat(Color(0.6, 0.42, 0.15), 0.2)
	for p in [Vector3(0.0, 2.5, -1.9), Vector3(0.65, 2.15, -2.05), Vector3(-0.65, 2.15, -2.05)]:
		_part(p, Vector3.ONE * 0.5, amber, _head)
	for side: float in [-1.0, 1.0]:
		# the eyes bulging out at the crown's corners
		_part(Vector3(3.1 * side, 1.3, -1.0), Vector3(2.3, 3.0, 2.6), eye, _head)
		_stick(Vector3(0.75 * side, -2.0, -2.2), Vector3(1.0 * side, -3.6, -2.6), 0.18, pale, _head) # (a palp)
		var j := Node3D.new()
		j.position = Vector3(0.5 * side, -2.4, -2.2)
		_head.add_child(j)
		_part(Vector3(0.0, -0.3, -0.2), Vector3(0.9, 1.0, 0.8), _mat(Color(0.2, 0.15, 0.08), 0.4), j)
		j.set_meta("side", side)
		_jaws.append(j)
		var an := Node3D.new()
		an.position = Vector3(0.6 * side, 1.7, -2.4)
		_head.add_child(an)
		var p := Vector3.ZERO
		var d := Vector3(0.35 * side, 0.6, -0.72).normalized()
		for k in 10:
			var q := p + d * (1.7 if not nymph else 1.2)
			_stick(p, q, 0.13, _mat(Color(0.35, 0.3, 0.2), 0.5), an)
			p = q
			d = (d + Vector3(0.02 * side, -0.02, 0.03)).normalized()
		_antennae.append(an)
	# the raptorial forelegs, from the prothorax's front: coxa, femur (its
	# spines), tibia (its hook), tarsus
	for side: float in [-1.0, 1.0]:
		var cx := Node3D.new()
		cx.position = Vector3(1.2 * side, -1.0, -14.0)
		_pro.add_child(cx)
		_part(Vector3(0.0, -4.3, 0.0), Vector3(1.5, 9.0, 2.1), body, cx) # (the coxa: long, flattened)
		var fm := Node3D.new()
		fm.position = Vector3(0.0, -8.0, 0.0)
		cx.add_child(fm)
		_part(Vector3(0.0, -5.5, 0.3), Vector3(1.3, 11.5, 2.6), body, fm) # (the femur: a blade, deep and flat)
		var spine := _mat(Color(0.2, 0.16, 0.1), 0.4)
		for k in 6: # (its spines, two rows along its inner edge, the groove the tibia shuts into between)
			for row: float in [-0.45, 0.45]:
				var sp := Vector3(row, -1.5 - k * 1.65, 1.5)
				_stick(sp, sp + Vector3(row * 0.3, -0.4, 0.9), 0.1, spine, fm)
		var tb := Node3D.new()
		tb.position = Vector3(0.0, -11.0, 0.0)
		fm.add_child(tb)
		_part(Vector3(0.0, -3.0, 0.2), Vector3(0.9, 6.2, 1.3), body, tb)
		_stick(Vector3(0.0, -6.0, 0.2), Vector3(0.0, -5.9, 1.6), 0.22, spine, tb) # (its hook)
		for k in 4: # (its spines)
			var sp := Vector3(0.0, -1.2 - k * 1.2, 0.7)
			_stick(sp, sp + Vector3(0.0, -0.3, 0.6), 0.08, spine, tb)
		_stick(Vector3(0.0, -5.0, 0.0), Vector3(0.0, -8.5, -1.5), 0.2, body, tb) # (the tarsus)
		_fore.append([cx, fm, tb])
	# the thorax behind it, the abdomen broad and flat (a nymph's curled up)
	_part(Vector3(0.0, 0.3, -1.6), Vector3(3.6, 3.0, 8.0), body)
	_abdomen = Node3D.new()
	_abdomen.position = Vector3(0.0, 0.3, 2.0)
	_body.add_child(_abdomen)
	var ab := [[0.0, 0.0, 0.6, 0.6], [1.0, 0.0, 2.8, 2.0], [6.0, 0.1, 3.6, 2.4], [12.0, 0.1, 3.6, 2.4], [18.0, -0.1, 2.8, 2.0], [23.0, -0.3, 1.6, 1.2], [25.5, -0.3, 0.4, 0.4]]
	if male and not nymph: # (a male's slender)
		ab = [[0.0, 0.0, 0.5, 0.5], [1.0, 0.0, 2.0, 1.6], [6.0, 0.1, 2.3, 1.8], [12.0, 0.1, 2.3, 1.8], [18.0, 0.0, 1.9, 1.5], [22.5, -0.2, 1.2, 0.9], [24.5, -0.2, 0.4, 0.4]]
	if nymph:
		ab = [[0.0, 0.0, 0.5, 0.5], [1.0, 0.0, 1.8, 1.6], [6.0, 0.1, 2.2, 1.8], [12.0, 0.1, 2.0, 1.7], [17.0, 0.0, 1.3, 1.1], [19.5, 0.0, 0.3, 0.3]]
	_abdomen.add_child(_mesh(_loft(ab), _banded(green.lightened(0.1), 3.2, 1.0, 0.3, 0.4))) # (its segments, mottled)
	var tip: Array = ab[ab.size() - 1]
	for side: float in [-1.0, 1.0]: # (the cerci)
		_stick(Vector3(0.4 * side, float(tip[1]), float(tip[0]) - 0.6), Vector3(1.2 * side, float(tip[1]) + 0.5, float(tip[0]) + 2.2), 0.18, body, _abdomen)
	# the wings: the adult's forewings flat over the abdomen, a dark spot on
	# each; the hindwings, smoky, folded away under them
	if not nymph:
		for side: float in [-1.0, 1.0]:
			var h := Node3D.new()
			h.position = Vector3(0.7 * side, 2.0, -4.5)
			_body.add_child(h)
			h.set_meta("side", side)
			var wl := 1.22 if male else 1.0 # (a male's: over all his abdomen)
			_part(Vector3(1.1 * side, 0.0, 10.5 * wl), Vector3(4.2 if male else 4.6, 0.3, 21.0 * wl), _mat(Color(0.5, 0.5, 0.33), 0.5), h)
			_part(Vector3(1.6 * side, 0.2, 7.5), Vector3(1.3, 0.35, 1.5), _mat(Color(0.18, 0.15, 0.1), 0.5), h)
			_teg.append(h)
			var hw := Node3D.new()
			hw.position = Vector3(0.7 * side, 1.6, -3.5)
			_body.add_child(hw)
			hw.set_meta("side", side)
			var mem := _mat(Color(0.42, 0.36, 0.3, 0.55), 0.3)
			mem.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mem.cull_mode = BaseMaterial3D.CULL_DISABLED
			_part(Vector3(11.0 * side, 0.0, 8.0), Vector3(22.0, 0.15, 19.0), mem, hw)
			_hind.append(hw)
	_build_legs(body, body)
	for i in [0, 1]: # (the unused walking forelegs: hidden)
		for m: MeshInstance3D in _leg_mesh[i]:
			m.visible = false


func _mesh(m: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	return mi


# --- what it does --------------------------------------------------------------

func stalk(centre: Vector3, radius: float) -> void:
	_mode = "stalk"
	_centre = centre
	_radius = radius
	_wait = 0.0


func watch(point: Vector3) -> void:
	_mode = "watch"
	_look = point
	_target = _pos


func strike(target: Vector3, prey: Node3D = null) -> void:
	_mode = "strike"
	_at = target
	_prey = prey
	_held = false
	_seized_it = false
	_rip = 0.0
	_meal = null
	_stage = 0
	_st = 0.0


func groom() -> void:
	_mode = "groom"
	_st = 0.0
	_target = _pos


func fly(to: Vector3) -> void:
	if nymph:
		return
	_mode = "fly"
	_at = to
	_stage = 0
	_st = 0.0


func lay(at: Vector3) -> void:
	if nymph:
		return
	_mode = "lay"
	_at = at
	_stage = 0
	_st = 0.0


## (Its mouth: where what it eats goes in (the world's).)
func _mouth() -> Vector3:
	return _head.global_transform * Vector3(0.0, -1.5, -1.6)


func _rest_fore() -> void:
	_ask = [FORE_REST, FORE_REST]
	_fore_rate = 8.0


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = 0.0
	var moving := _speed > 0.003
	# rocking like a leaf in the wind as it goes (and a little standing)
	_sw += dt * (2.2 if moving else 0.8)
	_sway = sin(_sw) * (0.09 if moving else 0.025)
	match _mode:
		"stalk":
			_rest_fore()
			if _wait <= 0.0:
				var a := rng.randf() * TAU
				if rng.randf() < 0.45:
					_target = _pos
					_look = _pos + Vector3(cos(a), 0.0, sin(a)) * 0.1 + Vector3.UP * rng.randf_range(0.0, 0.05)
				else:
					_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
					_look = Vector3.INF
				_wait = rng.randf_range(2.5, 6.0)
		"watch":
			_rest_fore()
			_target = _pos
		"strike":
			var reach := 20.0 * MM * size # (from its middle, the forelegs out)
			match _stage:
				0: # turning to it, up within reach, watching it
					_look = _at
					var to := _at - _pos
					to.y = 0.0
					_target = _at - to.normalized() * reach if to.length() > reach * 1.1 else _pos
					if to.length() <= reach * 1.15 and _speed < 0.004:
						_turn_to = atan2(-to.x, -to.z)
						_stage = 1
						_st = 0.0
				1: # drawing back, ready
					_pro_pitch = 0.3
					_lift = -1.0
					_ask = [Vector3(-0.35, 2.25, 2.9), Vector3(-0.35, 2.25, 2.9)] # (drawn up and back, ready)
					if _st > 0.5:
						_stage = 2
						_st = 0.0
				2: # out! (a tenth of a second)
					_fore_rate = 40.0
					_pro_pitch = 0.1
					_lift = 1.5
					_ask = [Vector3(0.9, 0.4, 0.4), Vector3(0.9, 0.4, 0.4)] # (shot out forward and down, open)
					if _st > 0.09:
						_stage = 3
						_st = 0.0
				3: # snapped shut on it, pinning it where it is (not drawn in)
					_ask = [PIN, PIN]
					_fore_rate = 18.0
					_lift = 0.0
					_pro_pitch = 0.2
					_bite_pitch = 0.2
					if _prey and not _seized_it and _st > 0.05:
						_seized_it = true
						if _prey.has_method("_seized"): # (a mantis: limp in her grip)
							_prey.call("_seized")
						else: # (a live insect: still in her grip)
							MealScript.subdue(_prey)
					if _st > 0.6:
						_stage = 4 if _prey else 5
						_st = 0.0
				4: # eating it where it is, pinned under its forelegs: its head down onto each next bite
					_chew = 1.0
					_look = Vector3.INF
					var whole := is_instance_valid(_prey) and _prey.has_method("_hang") # (a mantis)
					var meal := 32.0 if whole else 9.0
					_ask = [PIN, PIN]
					_fore_rate = 8.0
					if is_instance_valid(_prey):
						if _meal == null:
							_meal = MealScript.of(_prey, 9 if whole else 3)
						if _meal:
							var m := _mouth()
							var na: Vector3 = _meal.call("next_at")
							# (its front raised or lowered till its mouth's on it; a step to it)
							_bite_pitch = clampf(_bite_pitch + clampf((na.y - m.y) * 120.0, -1.5, 1.5) * dt, -0.6, 1.2)
							_pro_pitch = _bite_pitch
							var off := Vector3(na.x - m.x, 0.0, na.z - m.z)
							if off.length() > 0.001:
								_pos += off.limit_length(0.015 * size * dt)
								_target = _pos
							_meal.call("tear", clampf((_st - 0.5) / (meal - 1.5), 0.0, 1.0), m)
					if _st > meal:
						if is_instance_valid(_prey):
							_prey.queue_free()
						_prey = null
						_held = false
						_seized_it = false
						groom()
				5:
					_rest_fore()
					stalk(_pos, 0.15)
		"doomed": # (a male, just off her: still, watching her, a moment too long)
			_rest_fore()
			_target = _pos
			var her := _was_with
			if is_instance_valid(her):
				_look = her.call("_out", Vector3(0.0, 0.0, -18.0))
			if _st > 12.0 or not is_instance_valid(her) or her.get("_prey") != self: # (let be: off)
				stalk(_pos, 0.2)
		"groom":
			# each foreleg drawn through the mouth in turn
			var side_i := 0 if fmod(_st, 6.0) < 3.0 else 1
			_ask = [FORE_REST, FORE_REST]
			_ask[side_i] = Vector3(0.4, 1.7, 2.6 + 0.2 * sin(_st * 5.0)) # (brought up to its mouth)
			_chew = 0.7
			if _st > 12.0:
				stalk(_pos, 0.15)
		"fly":
			match _stage:
				0:
					_wings = minf(_wings + dt * 3.0, 1.0)
					if _st > 0.5:
						_steer = Vector3(_at.x, ground_y + 0.12, _at.z)
						_steer_speed = 0.6
						airborne = true
						_alt = 0.002
						_stage = 1
				1:
					var d := Vector2(_at.x - _pos.x, _at.z - _pos.z).length()
					_steer = Vector3(_at.x, ground_y + clampf(d * 0.5, 0.0, 0.15), _at.z)
					if d < 0.04:
						_steer = Vector3.INF
						_slow_fall = true
						_stage = 2
		"lay":
			match _stage:
				0: # to stand with its back to the stem, its abdomen's tip on it
					var back := 26.0 * MM * size
					var away := _pos - _at
					away.y = 0.0
					away = away.normalized() if away.length() > 1e-4 else Vector3.FORWARD
					_target = _at + away * back
					if _pos.distance_to(_target) < 0.004 and _speed < 0.004:
						_turn_to = atan2(-away.x, -away.z) # (its head away from the stem, its tail to it)
						_stage = 1
						_st = 0.0
				1: # the abdomen's tip down on it, working side to side, the foam growing
					_abdomen.rotation.y = 0.18 * sin(_st * 3.0)
					if _ooth == null:
						_ooth = Ootheca.new()
						_ooth.maker = get_script()
						get_parent().add_child(_ooth)
						_ooth.position = _at
						_ooth.rotation.y = _yaw
						oothecae.append(_ooth)
					_ooth.set("built", clampf(_st / 8.0, 0.02, 1.0))
					if _st > 8.0:
						_abdomen.rotation.y = 0.0
						_ooth = null
						stalk(_pos, 0.15)


func _on_landed() -> void:
	_steer = Vector3.INF
	_wings = 0.0
	if _mode == "fly":
		stalk(_pos, 0.15)


# --- steering (pilot.gd): its behaviours --------------------------------------------

## strike {at, prey}, watch {at, seconds}, groom, fly {at} and lay {at}
## (the adult's).
func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["strike", "watch", "groom"]) if nymph else PackedStringArray(["strike", "watch", "groom", "fly", "lay", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	var prey: Node3D = args.get("prey")
	match name:
		"strike":
			var at: Vector3 = args.get("at", prey.position if prey else _pos + _p_heading() * 0.04)
			strike(at, prey)
		"watch":
			watch(args.get("at", _pos + _p_heading() * 0.2))
		"groom":
			groom()
		"fly":
			fly(args.get("at", _pos + _p_heading() * 0.4))
		"lay":
			lay(args.get("at", _pos - _p_heading() * 0.03))
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"strike", "groom", "fly", "lay":
			return _mode != name
	return false


func _p_act_secs(name: String) -> float:
	return 4.0 if name == "watch" else -1.0


func _piloted() -> void:
	_mode = "piloted"
	_look = Vector3.INF
	_rest_fore()


# --- mating ------------------------------------------------------------------------

func _male_size() -> float:
	return 0.82


func _mate_approach() -> Vector3:
	return Vector3(0.0, -body_h, 46.0) # (behind her, out of her sight)


func _mate_leave() -> Vector3:
	return Vector3(16.0, -body_h, 10.0) # (slipped off beside her)


func _court_secs() -> float:
	return 5.0


func _mount() -> Dictionary:
	# on her back, a little behind her thorax's middle, his middle legs
	# gripping her flanks under her wings, his hind legs further back
	return {"at": Vector3(0.0, 4.2, 2.5), "basis": Basis(Vector3.RIGHT, -0.06), "grips": {
		2: Vector3(-2.4, -0.4, -2.5), 3: Vector3(2.4, -0.4, -2.5),
		4: Vector3(-2.8, -0.6, 9.0), 5: Vector3(2.8, -0.6, 9.0)}}


var _was_with: Node3D # (the one it last mated)


func _on_mate_start() -> void:
	_was_with = _mate


func _mating(dt: float) -> void:
	super(dt)
	_look = Vector3.INF
	_rest_fore()
	if _mate_role == "male":
		# creeping up, then frozen, swaying, watching her
		_pro_pitch = 0.35
		if _mate_stage == "court":
			_sw += dt * 0.8
			_sway = sin(_sw) * 0.05
			_look = _mate.call("_out", Vector3(0.0, 0.0, -18.0))


func _after_mate() -> void:
	_rest_fore()
	if not male:
		stalk(_pos, 0.15)


## He's off her: she turns on him (he's her next meal).
func _on_parted() -> void:
	if not male:
		return
	var her := _was_with
	if is_instance_valid(her) and not bool(her.get("dead")):
		_mode = "doomed"
		_st = 0.0
		_target = _pos
		her.call("strike", _out(_pro.position + Vector3(0.0, 0.0, -9.0)), self) # (at his thorax)
	else:
		stalk(_pos, 0.2)


## (A male, seized by her: limp in her grip from now on, posed by her
## (_hang), not moving himself.)
func _seized() -> void:
	die()
	set_process(false)
	_pro.rotation = Vector3(0.1, 0.0, 0.0)
	_abdomen.rotation = Vector3(0.15, 0.0, 0.0)
	_rest_fore()
	for s in 2:
		var parts: Array = _fore[s]
		(parts[0] as Node3D).rotation.x = FORE_REST.x + 0.5
		(parts[1] as Node3D).rotation.x = FORE_REST.y - 0.6
		(parts[2] as Node3D).rotation.x = FORE_REST.z - 0.8
	for i in legs.size() * 2: # (the legs drawn in, loose)
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var f: float = L.f
		_pose_foot[i] = Vector3(hp.x * side + side * f * 0.6, hp.y - f * 0.6, hp.z + f * 0.3)
	_pose_legs()


## (A male in her forelegs, his neck at h (world), her heading yaw: facing
## her, his body hanging away from her down toward the ground; his head
## torn off (rip). Eaten piece by piece (Meal): the pieces follow him.)
func _hang(h: Vector3, yaw: float, rip: float) -> void:
	var neck := _pro.position + Vector3(0.0, 0.2, -16.5) # (his body mm)
	_body.scale = Vector3.ONE * MM * size
	var length := 47.0 * MM * size
	var over := h.y - _ground(h.x, h.z) # (his neck over the ground: his tail down to it)
	var b := Basis(Vector3.UP, yaw + PI) * Basis(Vector3.RIGHT, asin(clampf(over / length, 0.1, 0.95))) * Basis(Vector3.BACK, 0.35)
	transform = Transform3D(b, Vector3.ZERO)
	transform.origin = h - transform * (_body.transform * neck)
	_head.position = Vector3(0.0, 0.6 + 1.6 * rip, -17.0 - 5.0 * rip) # (pulled from his neck, into her jaws)
	_head.rotation = Vector3(0.7 * rip, 0.0, 1.3 * rip) # (wrenched round)


## Let down from p on a thread (a hatchling, from its egg case): falling
## slowly, its legs out.
func drop(p: Vector3) -> void:
	_pos = Vector3(p.x, ground_y, p.z)
	_alt = maxf(p.y - ground_y - body_h * MM * size, 0.001)
	airborne = true
	_slow_fall = true
	_vel = Vector3.ZERO
	_place()


func _pose(dt: float) -> void:
	_pro.rotation = Vector3(_pro_pitch, 0.0, 0.0) # (raised: its front up)
	_pro_pitch = lerpf(_pro_pitch, 0.5, 1.0 - exp(-2.0 * dt)) if _mode != "strike" else _pro_pitch
	# the head following what it watches
	var yaw_to := 0.0
	var pitch_to := 0.0
	if _look != Vector3.INF:
		var hp := _out(_pro.position + Vector3(0.0, 0.0, -17.0))
		var d := _look - hp
		var local := transform.basis.inverse() * d
		yaw_to = clampf(atan2(-local.x, -local.z), -1.2, 1.2)
		pitch_to = clampf(atan2(local.y, Vector2(local.x, local.z).length()), -0.9, 0.6)
	# (the head held level on the raised prothorax, its face forward, a
	# little down; down to its food as it eats)
	_head.rotation = _head.rotation.lerp(Vector3(pitch_to - _pro_pitch * 0.85 - 0.12 - 0.3 * _chew, yaw_to, 0.0), 1.0 - exp(-6.0 * dt))
	for j in _jaws:
		var side: float = j.get_meta("side")
		j.rotation.y = side * 0.4 * _chew * (0.5 + 0.5 * sin(_t * 11.0))
	for k in _antennae.size():
		_antennae[k].rotation = Vector3(0.1 * sin(_t * 1.1 + k * 2.0), 0.12 * sin(_t * 0.7 + k), 0.0)
	# the forelegs, easing to what's asked
	for s in 2:
		var now: Vector3 = _now[s]
		now = now.lerp(_ask[s], 1.0 - exp(-_fore_rate * dt))
		_now[s] = now
		var parts: Array = _fore[s]
		(parts[0] as Node3D).rotation.x = now.x
		(parts[1] as Node3D).rotation.x = now.y
		(parts[2] as Node3D).rotation.x = now.z
	# the prey, held in the forelegs at its mouth (a mantis: by his neck,
	# between them)
	if _held and is_instance_valid(_prey):
		var tb: Node3D = _fore[0][2]
		if _prey.has_method("_hang"):
			var h := (tb.global_transform * Vector3(0.0, -3.5, 0.0) + (_fore[1][2] as Node3D).global_transform * Vector3(0.0, -3.5, 0.0)) * 0.5
			_prey.call("_hang", h, _yaw, _rip)
		else:
			_prey.global_position = tb.global_transform * Vector3(0.0, -3.5, 0.0)
	# the abdomen: a nymph's curled up over its back
	_abdomen.rotation.x = -0.75 if nymph else 0.0
	if _mode != "lay" or _mate_role != "":
		_abdomen.rotation.y = 0.0
	_abdomen.rotation.z = 0.0
	if _mate_role == "male" and _mate_stage in ["joined", "part"]:
		# (curled down and round to one side, to the tip of hers, pumping)
		var pump := 0.04 * sin(_t * 2.5)
		_abdomen.rotation = Vector3(0.62 + pump, 0.22, 0.12)
		_ask = [Vector3(0.05, 1.1, 2.4), Vector3(0.05, 1.1, 2.4)] # (clasping her)
		_pro_pitch = 0.15
	# the wings
	var beat := sin(_t * TAU * 20.0)
	for h in _teg:
		var side: float = h.get_meta("side")
		h.rotation = Vector3(-0.5 * _wings, 0.0, side * 1.1 * _wings)
	for h in _hind:
		var side: float = h.get_meta("side")
		h.scale = Vector3(lerpf(0.05, 1.0, _wings), 1.0, lerpf(0.5, 1.0, _wings))
		h.rotation = Vector3(0.0, 0.0, side * (0.2 + 0.8 * beat) * _wings)
		h.visible = _wings > 0.02


## A mantis's egg case (an ootheca), built by lay() on a stem: a rounded
## block of tan foam, ridged across, a seam down its front (built: how far
## along, 0..1). hatch(): the nymphs out along the seam one after another,
## each let down on a silk thread, and off stalking, small, to grow.
class Ootheca extends Node3D:
	const MM := 0.002
	var maker: Script # (the mantis's script: its nymphs)
	var built := 1.0
	var nymphs: Array[Node3D] = []
	var _parts: Array[MeshInstance3D] = []
	var _left := 0
	var _t := 0.0
	var _threads: Array = [] # [nymph, thread mesh, from]

	func _ready() -> void:
		var foam := StandardMaterial3D.new()
		foam.albedo_color = Color(0.72, 0.62, 0.45)
		foam.roughness = 0.95
		var ridge := StandardMaterial3D.new()
		ridge.albedo_color = Color(0.62, 0.52, 0.37)
		ridge.roughness = 0.95
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = 12
		s.rings = 7
		# (laid up the stem from its foot: built upward, y)
		var body := MeshInstance3D.new()
		body.mesh = s
		body.material_override = foam
		add_child(body)
		_parts.append(body)
		for k in 7:
			var r := MeshInstance3D.new()
			r.mesh = s
			r.material_override = ridge
			add_child(r)
			_parts.append(r)
		var seam := MeshInstance3D.new()
		seam.mesh = s
		seam.material_override = ridge
		add_child(seam)
		_parts.append(seam)
		_shape()

	func _shape() -> void:
		var h := 22.0 * built
		_parts[0].scale = Vector3(13.0, h, 10.0) * MM
		_parts[0].position = Vector3(0.0, h * 0.5 + 2.0, 0.0) * MM
		for k in 7:
			var y := (2.0 + h * (k + 0.5) / 7.0)
			_parts[1 + k].scale = Vector3(13.6, 0.9, 10.5) * MM * (0.0 if (k + 0.5) / 7.0 > built + 0.05 else 1.0)
			_parts[1 + k].position = Vector3(0.0, y, 0.0) * MM
		_parts[8].scale = Vector3(2.0, h * 0.95, 1.0) * MM
		_parts[8].position = Vector3(0.0, h * 0.5 + 2.0, -4.8) * MM

	## Hatching: n nymphs out along its seam, one by one, let down on threads.
	func hatch(n := 8) -> void:
		if _left > 0 or maker == null:
			return
		_left = n
		_t = 0.0

	func _process(dt: float) -> void:
		_shape()
		_t += dt
		if _left > 0 and _t > 0.6:
			_t = 0.0
			_left -= 1
			var parent := get_parent() as Node3D
			var ny: Node3D = maker.new(true, 0.18)
			parent.add_child(ny)
			var from := global_transform * (Vector3(randf_range(-1.0, 1.0), 6.0 + randf() * 14.0, -5.5) * MM)
			from = parent.to_local(from)
			ny.set("ground_y", position.y)
			ny.call("place", Vector3(from.x, position.y, from.z), randf() * TAU)
			ny.call("drop", from)
			ny.call("stalk", Vector3(from.x, position.y, from.z), 0.12)
			ny.call("grow", 0.6, 90.0)
			nymphs.append(ny)
			var th := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.5
			cyl.bottom_radius = 0.5
			cyl.height = 1.0
			cyl.radial_segments = 3
			th.mesh = cyl
			var silk := StandardMaterial3D.new()
			silk.albedo_color = Color(0.95, 0.95, 0.95, 0.6)
			silk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			th.material_override = silk
			parent.add_child(th)
			_threads.append([ny, th, from])
		# the threads, from the seam down to each falling nymph, gone once it's down
		for k in range(_threads.size() - 1, -1, -1):
			var e: Array = _threads[k]
			var ny: Node3D = e[0]
			var th: MeshInstance3D = e[1]
			if not is_instance_valid(ny) or not bool(ny.get("airborne")):
				th.queue_free()
				_threads.remove_at(k)
				continue
			var a: Vector3 = e[2]
			var b := ny.position
			var d := b - a
			th.transform = Transform3D(Basis(Vector3(0.0003, 0.0, 0.0), d if d.length() > 1e-5 else Vector3(0.0, 1e-5, 0.0), Vector3(0.0, 0.0, 0.0003)), (a + b) * 0.5)
