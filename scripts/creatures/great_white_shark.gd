class_name GreatWhiteShark
extends Node3D
## A great white shark (Carcharodon carcharias), life size: a grown female
## 4.6 m (the mesh's), about 1,100 kg; a male smaller (3.8 m), his claspers
## under him; a pup born 1.3 m, its pectorals black tipped beneath.
##
## Its body (build: one mesh, posed in shark.gdshader): a deep spindle, its
## snout a blunt cone, the mouth a crescent under it, its rows of
## triangular serrated teeth (the upper broad, the lower narrow), black
## eyes, five gill slits each side ahead of the long sickle pectorals, the
## big triangular first dorsal, the tiny second dorsal and anal, the
## pelvics (a male's claspers from them), the keels each side of its tail
## stalk, the tail a near-symmetric crescent. Grey above, white below, the
## border ragged, dipping under the eye to the mouth's corner and down
## behind the pelvics; a black spot behind each pectoral's root; the
## pectorals' undersides white, their trailing edges and tips dark; old
## scars; its skin's fine denticles. Its ways:
## - swimming: always (it breathes by the water through its mouth: it never
##   stops), a lamnid's beat all in its tail, its body stiff; patrolling the
##   water, a slow cruise, the mouth a little open, now and then up toward
##   the surface, looking; turning before the walls
## - hunting (hunt): its prey (Diet: a tuna, a salmon at sea) stalked from
##   deep below and behind, unseen against the dark; then the rush, straight
##   up at it, fast; the bite: its snout lifted, its lower jaw dropped, its
##   upper jaw thrown forward, its eyes rolled back white (it has no
##   nictitating membrane); the jaws shut on it. At the surface, the rush
##   carries it clean out of the water (breach), falling back in a crash of
##   spray. Its prey held, shaken, swallowed
## - investigating (investigate): circling something new, closer each time,
##   then mouthing it: a test bite, gently, and off (a sea otter's let go)
## - spyhopping (spyhop): its head up out of the water, looking about
## - gaping (gape), a tail slap at the surface (tail_slap): its displays to
##   another shark
## - rubbing on the bottom (chafe), rolled on its side; resting (rest): a
##   slow glide near the bottom, its mouth open
## - mating (mate): the male after her, biting her pectoral fin to hold
##   her, the two rolled belly to belly, one of his claspers swung forward
##   into her; her scars from his bites
## - giving birth (give_birth): her pups, live (she carries them a year),
##   born one by one, each swimming off at once; none cared for
## - its young (GreatWhiteShark.new(true)): a pup, on its own, growing

const SHADER := preload("res://shaders/render/shark.gdshader")
const TL := 4.6 ## m: the mesh's length, snout to tail tip (a grown female's)
## the body: [z, its middle's height, half width, height above its middle,
## below] (m, the mesh's, facing -z)
const BODY := [
	[-2.30, -0.02, 0.0, 0.0, 0.0], [-2.275, -0.02, 0.045, 0.036, 0.028], [-2.21, -0.022, 0.1, 0.085, 0.065],
	[-2.10, -0.025, 0.17, 0.145, 0.115], [-1.94, -0.03, 0.245, 0.215, 0.18], [-1.76, -0.035, 0.31, 0.285, 0.245],
	[-1.55, -0.04, 0.37, 0.355, 0.32], [-1.30, -0.04, 0.43, 0.42, 0.39], [-1.0, -0.035, 0.475, 0.47, 0.44],
	[-0.6, -0.025, 0.495, 0.495, 0.46], [-0.2, -0.01, 0.47, 0.47, 0.42], [0.2, 0.0, 0.39, 0.39, 0.33],
	[0.6, 0.015, 0.27, 0.27, 0.21], [0.95, 0.025, 0.17, 0.165, 0.13], [1.2, 0.03, 0.115, 0.1, 0.085],
	[1.35, 0.03, 0.098, 0.072, 0.062], [1.47, 0.03, 0.088, 0.062, 0.052],
]
const Z_SNOUT := -2.3
const GAPE_A := 1.95 ## (rad round from its back's middle: the gape's line along each side)
const Z_STALK := 1.45
const MOUTH := Vector3(0.0, -0.13, -2.0) ## (the mesh's: its mouth's middle)
const CLOACA := Vector3(0.0, -0.22, 0.7)
const NOSE := Vector3(0.0, -0.02, -2.3)

var male := false
var young := false
var size := 1.0 ## (the node's scale: 1 a grown female's 4.6 m)
var tank_min := Vector3(-8.0, -3.4, -5.0) ## the water (its parent's space): the bottom's corner
var tank_max := Vector3(8.0, -0.03, 5.0) ## and the surface's
var hunger := 0.5
var dead := false
var pups: Array[Node3D] = []
var mother: Node3D
var grow_secs := 900.0 ## (a pup's: to a juvenile's size)

var _pos := Vector3.ZERO
var _fwd := Vector3.FORWARD
var _spd := 1.0
var _want := 1.0
var _roll := 0.0
var _roll_to := 0.0
var _phase := 0.0
var _bend := 0.0
var _mode := "patrol"
var _t := 0.0
var _goal := Vector3.ZERO
var _goal_t := 0.0
var _vel := Vector3.ZERO # (in the air: breaching)
var _air := false
var _prey: Node3D # (a school, or a creature)
var _prey_i := -1 # (a school's fish)
var _held: Node3D
var _target: Node3D # (investigated)
var _target_at := Vector3.INF
var _partner: Node3D
var _born := 0
var _to_bear := 0
var _bite_t := -1.0 # (its bite's clock: -1 none)
var _bite_soft := false
var _then := ""
var _secs := 0.0
var _age := 0.0
var _mi: MeshInstance3D
var _mat: ShaderMaterial
var _pose := {"jaw": 0.06, "protrude": 0.0, "snout": 0.0, "eye_roll": 0.0, "gill": 0.0, "pec": 0.1, "clasp": 0.0, "arch": 0.0}
var _pose_to := {}
var rng := RandomNumberGenerator.new()
static var _built := {}


func _init(young_ := false) -> void:
	young = young_
	rng.randomize()


func _ready() -> void:
	size = (0.28 if young else (0.83 if male else 1.0))
	if young and mother == null:
		size = rng.randf_range(0.28, 0.42)
	var key := "male" if male and not young else "female"
	if not _built.has(key):
		_built[key] = build(male and not young)
	var B: Array = _built[key]
	_mi = MeshInstance3D.new()
	_mi.mesh = B[0]
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("pec_root", B[1])
	_mat.set_shader_parameter("pec_axis", B[2])
	_mat.set_shader_parameter("pup", 1.0 if young else 0.0)
	_mat.set_shader_parameter("scars", 0.0 if young else rng.randf_range(0.3, 1.0))
	_mat.set_shader_parameter("seed", rng.randf())
	var g := rng.randf_range(-0.04, 0.04) # (each its own grey: slate, a little brown)
	_mat.set_shader_parameter("dorsal_color", Color(0.4 + g, 0.43 + g * 0.6, 0.45 + g * 0.2))
	_mi.material_override = _mat
	_mi.custom_aabb = AABB(Vector3(-1.6, -1.2, -2.6), Vector3(3.2, 2.6, 5.4))
	add_child(_mi)
	scale = Vector3.ONE * size
	_pos = position
	_goal = _pos
	_pose_to = _pose.duplicate()
	_spd = _cruise()


func place(at: Vector3, yaw := 0.0) -> void:
	_pos = at
	position = at
	_fwd = Vector3(-sin(yaw), 0.0, -cos(yaw))
	_goal = at


## The water it lives in (its parent's space): its bottom's corner, its
## surface's.
func set_water(lo: Vector3, hi: Vector3) -> void:
	tank_min = lo
	tank_max = hi


func _cruise() -> float:
	return (0.75 if young else 1.0) * clampf(size * 1.2, 0.6, 1.2)


func _len() -> float:
	return TL * size


## (A point of its mesh, where it is now: its parent's space.)
func _at(local: Vector3) -> Vector3:
	return _pos + basis * local


func mouth() -> Vector3:
	return _at(MOUTH)


# --- its ways -------------------------------------------------------------------------------

func _to(mode: String) -> void:
	_mode = mode
	_t = 0.0
	_roll_to = 0.0
	_pose_to.arch = 0.0
	_pose_to.pec = 0.1
	_pose_to.clasp = 0.0
	if mode != "feed":
		_pose_to.jaw = 0.06


func patrol() -> void:
	_prey = null
	_target = null
	_to("patrol")
	_goal_t = 0.0


func wander() -> void:
	patrol()


## Its prey (a school of tuna or salmon: the fish of it nearest; a creature):
## stalked from below, rushed, seized.
func hunt(prey: Node3D) -> void:
	if dead or _air or prey == null or not is_instance_valid(prey):
		return
	_prey = prey
	_prey_i = -1
	if prey.has_method("nearest"):
		_prey_i = int(prey.call("nearest", _pos))
		if _prey_i < 0:
			_prey = null
			return
	_to("stalk")


func investigate(target: Node3D = null, at := Vector3.INF) -> void:
	if dead or _air:
		return
	_target = target
	_target_at = at
	_to("circle")


func breach() -> void:
	if dead or _air:
		return
	_prey = null
	_to("rush_up")


func spyhop() -> void:
	if dead or _air:
		return
	_to("spyhop")


func gape(secs := 3.0) -> void:
	if dead or _air:
		return
	_to("gape")
	_secs = secs


func tail_slap() -> void:
	if dead or _air:
		return
	_to("slap")


func chafe() -> void:
	if dead or _air:
		return
	_to("chafe")


func rest(secs := 30.0) -> void:
	if dead or _air:
		return
	_to("rest")
	_secs = secs


## (A male's.) After her, her pectoral bitten to hold her, the two rolled
## belly to belly, one clasper swung forward into her.
func mate(female: Node3D, _secs_ := -1.0) -> bool:
	if not male or young or dead or female == null or not is_instance_valid(female) or female == self:
		return false
	if female.get("male") or female.get("young") or female.get("dead"):
		return false
	_partner = female
	female.set("_partner", self)
	female.call("_to", "courted")
	_to("court")
	return true


## (A female's.) Her pups born, live, one by one; each swims off at once.
func give_birth(n := -1) -> void:
	if male or young or dead or _air:
		return
	_to_bear = n if n > 0 else rng.randi_range(2, 6)
	_born = 0
	_to("birth")


func die() -> void:
	if dead:
		return
	dead = true
	_to("dead")


func flee(from: Vector3) -> void:
	if dead or _air:
		return
	var away := _pos - from
	away.y = 0.0
	_goal = _inside(_pos + (away.normalized() if away.length() > 0.1 else _fwd) * 8.0)
	_to("flee")


# --- the motor --------------------------------------------------------------------------------

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	if _mi == null:
		return
	_t += dt
	_age += dt
	if young and size < 0.6: # (a pup growing)
		size = minf(size + dt * 0.25 / grow_secs, 0.6)
		scale = Vector3.ONE * size
	hunger = minf(hunger + dt / 400.0, 1.0)
	if _air:
		_fly(dt)
	else:
		_think(dt)
		_swim(dt)
	_pose_step(dt)
	# its body turned to its way, rolled
	var f := _fwd.normalized()
	var up := Vector3.UP if absf(f.y) < 0.97 else Vector3.BACK
	var b := Basis.looking_at(f, up)
	_roll = move_toward(_roll, _roll_to, dt * 1.5)
	b = Basis(f, -_roll) * b
	transform = Transform3D(b.scaled(Vector3.ONE * size), _pos)
	# the beat: faster and wider the faster it swims
	var sp := clampf(_spd / maxf(_cruise() * 4.0, 0.1), 0.0, 1.0)
	_phase += dt * TAU * (0.45 + 1.6 * sp) / pow(maxf(size, 0.2), 0.35) * (1.0 if not _air else 0.4)
	_mat.set_shader_parameter("phase", _phase)
	_mat.set_shader_parameter("amp", (0.1 + 0.12 * sp) * (2.6 if _mode == "slap" and _t > 0.8 else 1.0) * (0.4 if _mode == "dead" else 1.0))
	_mat.set_shader_parameter("bend", _bend)
	for k: String in _pose:
		_mat.set_shader_parameter(k, _pose[k])


## Each frame: its way and its pace from what it's doing.
func _think(dt: float) -> void:
	var lo := tank_min
	var hi := tank_max
	var L := _len()
	match _mode:
		"patrol":
			_want = _cruise()
			_goal_t -= dt
			if _goal_t <= 0.0 or _pos.distance_to(_goal) < L * 0.6:
				_goal_t = rng.randf_range(6.0, 14.0)
				var up := rng.randf() < 0.25 # (now and then up toward the surface, looking)
				_goal = _inside(Vector3(rng.randf_range(lo.x, hi.x), lerpf(lo.y, hi.y, rng.randf_range(0.6, 0.85) if up else rng.randf_range(0.2, 0.6)), rng.randf_range(lo.z, hi.z)))
			_pose_to.jaw = 0.07 + 0.03 * sin(_t * 0.7) # (its mouth a little open: the water through it)
			_pose_to.gill = 0.05 + 0.05 * sin(_t * 1.3)
			if young: # (a pup keeps away from the grown ones: they eat their own)
				for o in get_parent().get_children():
					if o is GreatWhiteShark and o != self and not o.young and not o.dead and (o as Node3D).position.distance_to(_pos) < 6.0:
						_goal = _inside(_pos + (_pos - (o as Node3D).position).normalized() * 6.0)
		"stalk": # (deep below and behind it, unseen against the dark: then the rush)
			var pp := _prey_pos()
			if pp == Vector3.INF:
				patrol()
				return
			var deep := lo.y + 0.45 * L * 0.25 + 0.3
			var behind := Vector3(pp.x - _pos.x, 0.0, pp.z - _pos.z)
			_goal = _inside(Vector3(pp.x, deep, pp.z) - behind.normalized() * L * 0.6)
			_want = _cruise() * 1.1
			var hd := Vector2(pp.x - _pos.x, pp.z - _pos.z).length()
			if _t > 2.0 and hd < L * 1.4 and (_pos.y < pp.y - 0.25 or _t > 9.0): # (under it, or as near under as the water lets it: then the rush)
				_to("rush")
				if _prey.has_method("scatter"):
					_prey.call("scatter", _pos)
			elif _t > 30.0:
				patrol()
		"rush": # (straight at it, fast, from below)
			var pp := _prey_pos()
			if pp == Vector3.INF:
				patrol()
				return
			_goal = pp
			_want = _cruise() * (5.5 if not young else 4.0)
			_pose_to.pec = 0.35
			if _bite_t < 0.0 and mouth().distance_to(pp) < L * 0.6:
				_bite(false)
			if _bite_t > 0.3 and mouth().distance_to(pp) < L * 0.45 and _held == null:
				_seize()
			if _t > 8.0 and _held == null:
				patrol()
				return
			if _held != null:
				if _pos.y > hi.y - L * 0.25 and _fwd.y > 0.45: # (at the surface, flat out: clean out of the water)
					_launch()
				else:
					_to("feed")
		"rush_up": # (a breach of its own: up from the deep at the surface)
			if _t < 0.1:
				_goal = Vector3(_pos.x, lo.y + 0.5, _pos.z)
			if _pos.y > lo.y + 0.25 * L and _t < 3.0 and _goal.y < hi.y - 1.0:
				_goal = _inside(Vector3(_pos.x, lo.y + 0.4, _pos.z) + Vector3(_fwd.x, 0.0, _fwd.z) * L)
				_want = _cruise()
			else:
				_goal = Vector3(_pos.x + _fwd.x * 0.6, hi.y + 2.0, _pos.z + _fwd.z * 0.6)
				_want = _cruise() * 5.5
				if _pos.y > hi.y - L * 0.25 and _fwd.y > 0.4:
					_launch()
			if _t > 12.0:
				patrol()
		"feed": # (its prey held, shaken, swallowed)
			_want = _cruise() * 0.6
			_pose_to.jaw = 0.18
			_pose_to.eye_roll = 0.0
			_bend = 0.6 * sin(_t * 9.0) * (1.0 - smoothstep(1.6, 2.4, _t))
			if _t > 3.2:
				if _held and is_instance_valid(_held):
					_held.queue_free()
				_held = null
				_bite(true) # (a gulp)
				hunger = maxf(hunger - 0.5, 0.0)
				patrol()
		"circle": # (round it, closer each time; then a test bite)
			var tp := _target_pos()
			if tp == Vector3.INF:
				patrol()
				return
			var r := L * lerpf(1.1, 0.55, clampf(_t / 14.0, 0.0, 1.0))
			var a := atan2(_pos.z - tp.z, _pos.x - tp.x) + 0.7
			_goal = _inside(Vector3(tp.x + cos(a) * r, lerpf(_pos.y, tp.y - 0.3, 0.3), tp.z + sin(a) * r))
			_want = _cruise() * 0.8
			if _t > 14.0:
				_to("mouth")
		"mouth": # (mouthing it, gently: a test bite; then off)
			var tp := _target_pos()
			if tp == Vector3.INF:
				patrol()
				return
			_goal = tp
			_want = _cruise() * 0.7
			if _bite_t < 0.0 and mouth().distance_to(tp) < L * 0.25:
				_bite(true)
				if _target and _target.has_method("flee"):
					_target.call("flee", _pos)
			if (_bite_t < 0.0 and _t > 3.0) or _t > 10.0:
				_target = null
				_goal = _inside(_pos + _fwd * L * 2.0)
				patrol()
		"spyhop": # (its head out of the water, looking about)
			var top := hi.y
			if _t < 4.0 and _pos.y < top - L * 0.7:
				_goal = Vector3(_pos.x + _fwd.x * 0.2, top + 1.0, _pos.z + _fwd.z * 0.2)
				_want = _cruise() * 0.9
			else:
				_fwd = _fwd.slerp(Vector3(_fwd.x * 0.06, 1.0, _fwd.z * 0.06).normalized(), minf(dt * 1.5, 1.0))
				var hold_y := top - L * 0.28 + 0.12 * sin(_t * 1.1) # (its head out to its gills: its eyes clear)
				_pos.y = move_toward(_pos.y, hold_y, dt * 0.6)
				_want = 0.05
				_goal = _pos + _fwd
				_fwd = _fwd.rotated(Vector3.UP, dt * 0.35 * sin(_t * 0.6))
				if _t > 9.0:
					_fwd = Vector3(_fwd.x, -0.4, _fwd.z).normalized()
					patrol()
		"gape":
			_want = _cruise()
			_pose_to.jaw = 0.85
			_pose_to.protrude = 0.3
			_pose_to.gill = 0.6
			if _t > _secs:
				_pose_to.protrude = 0.0
				patrol()
		"slap": # (at the surface: its tail beaten hard, spray thrown)
			_goal = Vector3(_pos.x + _fwd.x * 3.0, hi.y - L * 0.08, _pos.z + _fwd.z * 3.0)
			_goal = _inside(_goal)
			_want = _cruise() * 0.8
			if _t > 0.8 and fmod(_t, 0.7) < dt:
				_splash(_at(Vector3(0.0, 0.3, 1.9)), 0.6)
			if _t > 4.0:
				patrol()
		"chafe": # (rubbing on the bottom, rolled on its side)
			_goal = _inside(Vector3(_pos.x + _fwd.x * 4.0, lo.y + L * 0.06, _pos.z + _fwd.z * 4.0))
			_want = _cruise() * 0.5
			_roll_to = 1.35 * (1.0 if fmod(_t, 12.0) < 6.0 else -1.0) if _pos.y < lo.y + L * 0.2 else 0.0
			if _t > 14.0:
				patrol()
		"rest":
			_goal_t -= dt
			if _goal_t <= 0.0:
				_goal_t = 8.0
				_goal = _inside(Vector3(rng.randf_range(lo.x, hi.x), lo.y + L * 0.12, rng.randf_range(lo.z, hi.z)))
			_want = _cruise() * 0.45
			_pose_to.jaw = 0.15
			_pose_to.gill = 0.3
			if _t > _secs:
				patrol()
		"flee":
			_want = _cruise() * 4.0
			if _pos.distance_to(_goal) < L or _t > 5.0:
				patrol()
		"court": # (after her; her pectoral bitten)
			if _partner == null or not is_instance_valid(_partner):
				patrol()
				return
			var pp: Vector3 = _partner.call("_at", Vector3(-0.85, -0.25, -0.85))
			_goal = pp
			_want = _cruise() * 1.6
			if _bite_t < 0.0 and mouth().distance_to(pp) < L * 0.2:
				_bite(true)
				_partner.set("_mating_marks", float(_partner.get("_mating_marks")) + 0.2)
				_to("mate_")
				_partner.call("_to", "mate_f")
		"mate_": # (belly to belly with her, his clasper in)
			if _partner == null or not is_instance_valid(_partner):
				patrol()
				return
			var pf: Vector3 = _partner.get("_fwd")
			var under: Vector3 = _partner.call("_at", Vector3(-0.32, -0.55, 0.15))
			_pos = _pos.lerp(under, minf(dt * 1.5, 1.0))
			_fwd = _fwd.slerp(pf, minf(dt * 2.0, 1.0)).normalized()
			_goal = _pos + _fwd * 3.0
			_want = float(_partner.get("_spd"))
			_roll_to = -1.45
			_pose_to.clasp = clampf((_t - 2.0) / 2.0, 0.0, 1.0)
			_pose_to.jaw = 0.25
			if _t > 22.0:
				_partner.call("patrol")
				_partner.set("_partner", null)
				_partner = null
				patrol()
		"courted", "mate_f": # (hers: slow, held; rolled to him)
			_goal_t -= dt
			if _goal_t <= 0.0 or _pos.distance_to(_goal) < L:
				_goal_t = 6.0
				_goal = _inside(_pos + _fwd * L * 2.0 + Vector3(rng.randf_range(-2.0, 2.0), 0.0, rng.randf_range(-2.0, 2.0)))
			_want = _cruise() * (0.8 if _mode == "courted" else 0.45)
			_roll_to = 0.5 if _mode == "mate_f" else 0.0
			_mat.set_shader_parameter("mating_scars", minf(float(get("_mating_marks")), 1.0))
			if _t > 40.0:
				patrol()
		"birth": # (slow, mid water; a pup born every few seconds, tail first, off at once)
			_goal_t -= dt
			if _goal_t <= 0.0 or _pos.distance_to(_goal) < L:
				_goal_t = 6.0
				_goal = _inside(Vector3(rng.randf_range(lo.x, hi.x), lerpf(lo.y, hi.y, 0.4), rng.randf_range(lo.z, hi.z)))
			_want = _cruise() * 0.5
			if _t > 3.0 + _born * 4.0 and _born < _to_bear:
				_bear_one()
			if _born >= _to_bear and _t > 3.0 + _born * 4.0 + 2.0:
				patrol()
		"dead": # (sinking, still)
			_want = 0.0
			_goal = _pos + _fwd
			_fwd = _fwd.slerp(Vector3(_fwd.x, -0.2, _fwd.z).normalized(), dt * 0.2)
			_roll_to = 2.6
			_pos.y = maxf(_pos.y - dt * 0.15, lo.y + L * 0.06)
	if _bite_t >= 0.0:
		_bite_t += dt


var _mating_marks := 0.0


## Toward _goal at _want: turning no faster than it can (a big body's slow
## turn; faster swimming, wider), kept off the walls, the bottom, out of the air.
func _swim(dt: float) -> void:
	var L := _len()
	var to := _goal - _pos
	var want_dir := to.normalized() if to.length() > 0.01 else _fwd
	if _mode not in ["spyhop", "rush", "rush_up", "dead"]: # (its way held fairly level)
		want_dir.y = clampf(want_dir.y, -0.45, 0.45)
		want_dir = want_dir.normalized()
	# (the walls ahead: turned from them; the surface too, but for its head up out of it, spyhopping, breaching)
	var ahead := _pos + _fwd * (L * 0.7 + _spd * 1.2)
	var inner := _inside(ahead)
	if _mode in ["spyhop", "rush_up"] or (_mode == "rush" and _held != null):
		inner.y = ahead.y
	if inner.distance_to(ahead) > 0.01:
		want_dir = (want_dir + (inner - ahead).normalized() * 2.0).normalized()
	var rate := (1.4 if young else 0.75) / maxf(0.6 + _spd * 0.15, 0.5) # (rad/s)
	if _mode in ["rush", "rush_up", "court"]:
		rate *= 1.8
	var ang := _fwd.angle_to(want_dir)
	var turned := _fwd
	if ang > 1e-4:
		var axis := _fwd.cross(want_dir)
		if axis.length() < 1e-5:
			axis = Vector3.UP
		turned = _fwd.rotated(axis.normalized(), minf(ang, rate * dt))
	var side := _fwd.cross(Vector3.UP)
	var yaw_rate := (turned - _fwd).dot(side.normalized() if side.length() > 0.01 else Vector3.RIGHT) / maxf(dt, 1e-4)
	if _mode != "feed":
		_bend = lerpf(_bend, clampf(-yaw_rate * 1.2, -1.0, 1.0), minf(dt * 4.0, 1.0))
	_fwd = turned.normalized()
	_spd = move_toward(_spd, _want, dt * (3.0 if _want > _spd else 1.2))
	_pos += _fwd * _spd * dt
	# (inside its water: never the bottom, the air, the walls)
	var m := L * 0.12
	_pos.x = clampf(_pos.x, tank_min.x + m, tank_max.x - m)
	_pos.z = clampf(_pos.z, tank_min.z + m, tank_max.z - m)
	_pos.y = clampf(_pos.y, tank_min.y + m * 0.6, tank_max.y - (0.0 if _mode == "spyhop" else m * 0.5))


func _inside(p: Vector3) -> Vector3:
	var L := _len()
	var mx := minf(L * 0.6, (tank_max.x - tank_min.x) * 0.4)
	var mz := minf(L * 0.6, (tank_max.z - tank_min.z) * 0.4)
	return Vector3(clampf(p.x, tank_min.x + mx, tank_max.x - mx), clampf(p.y, tank_min.y + L * 0.1, tank_max.y - L * 0.08), clampf(p.z, tank_min.z + mz, tank_max.z - mz))


# --- the bite, the prey ----------------------------------------------------------------------

## Its bite (its clock started): its snout lifted, its lower jaw dropped,
## its upper thrown forward, its eyes rolled back; then shut. Soft: a test
## bite, a gulp: slower, gentler.
func _bite(soft: bool) -> void:
	_bite_t = 0.0
	_bite_soft = soft


func _pose_step(dt: float) -> void:
	var p := _pose_to.duplicate()
	if _bite_t >= 0.0:
		var t := _bite_t * (0.7 if _bite_soft else 1.0)
		var open := smoothstep(0.0, 0.22, t) * (1.0 - smoothstep(0.42, 0.62, t))
		var k := 0.55 if _bite_soft else 1.0
		p.jaw = maxf(float(p.jaw), open * k)
		p.snout = open * k
		p.protrude = smoothstep(0.15, 0.35, t) * (1.0 - smoothstep(0.5, 0.7, t)) * k
		p.eye_roll = smoothstep(0.1, 0.25, t) * (1.0 - smoothstep(0.75, 1.0, t))
		p.gill = maxf(float(p.gill), open)
		if t > 1.1:
			_bite_t = -1.0
	for key: String in _pose:
		var r := 14.0 if _bite_t >= 0.0 and key in ["jaw", "snout", "protrude", "eye_roll"] else 3.0
		_pose[key] = lerpf(float(_pose[key]), float(p.get(key, _pose[key])), 1.0 - exp(-r * dt))


func _prey_pos() -> Vector3:
	if _prey == null or not is_instance_valid(_prey):
		return Vector3.INF
	if _prey_i >= 0:
		var ps: PackedVector3Array = _prey.get("pos")
		var tk: PackedInt32Array = _prey.get("task")
		if _prey_i >= ps.size() or tk[_prey_i] == 6: # (gone: another's)
			return Vector3.INF
		return get_parent().to_local(_prey.to_global(ps[_prey_i]))
	return Diet._at(_prey)


func _target_pos() -> Vector3:
	if _target != null and is_instance_valid(_target):
		return Diet._at(_target)
	return _target_at


## (Its jaws shut on it: a fish of a school, out of it, in its mouth.)
func _seize() -> void:
	if _prey_i >= 0 and _prey.has_method("take"):
		_held = _prey.call("take", _prey_i)
		_prey_i = -1
	elif _prey and is_instance_valid(_prey):
		if _prey.has_method("die"):
			_prey.call("die")
		_held = _prey
	_prey = null
	if _held:
		_held.set_meta("taken", true)


func _hold_prey() -> void:
	if _held and is_instance_valid(_held):
		var m: Vector3 = get_parent().to_global(mouth())
		_held.global_position = m
		_held.global_basis = Basis(Vector3.UP, atan2(-_fwd.x, -_fwd.z) + PI * 0.5) * Basis.from_scale(_held.global_basis.get_scale())


# --- in the air: the breach ----------------------------------------------------------------

func _launch() -> void:
	_air = true
	_vel = _fwd * maxf(_spd, _cruise() * 4.5)
	_vel.y = maxf(_vel.y, 7.0 * sqrt(clampf(size, 0.3, 1.0))) # (a real breach: clear of the water, two metres and more)
	_splash(_at(NOSE), 1.0)
	_to("air")


func _fly(dt: float) -> void:
	_t += 0.0
	_vel.y -= 9.8 * dt
	_pos += _vel * dt
	_fwd = _fwd.slerp(_vel.normalized(), minf(dt * 2.5, 1.0)).normalized()
	_roll_to = 0.9 # (twisting as it falls, onto its side)
	_bend = 0.3 * sin(_t * 6.0)
	if _vel.y < 0.0 and _pos.y < tank_max.y - _len() * 0.1:
		_air = false
		_splash(_pos + Vector3(0.0, tank_max.y - _pos.y, 0.0), 1.6)
		_spd = _vel.length() * 0.5
		_fwd = Vector3(_fwd.x, clampf(_fwd.y, -0.6, 0.0), _fwd.z).normalized()
		if _held:
			_to("feed")
		else:
			patrol()


## Spray, thrown up at `at` (its parent's space), falling back; a ring of foam.
func _splash(at: Vector3, k: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = int(90 * k)
	p.lifetime = 1.6
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 55.0
	p.initial_velocity_min = 2.0 * k
	p.initial_velocity_max = 5.5 * k
	p.gravity = Vector3(0.0, -9.8, 0.0)
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.16 * k
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 6
	sm.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.95, 0.97, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.2
	sm.material = mat
	p.mesh = sm
	get_parent().add_child(p)
	p.position = Vector3(at.x, tank_max.y + 0.03, at.z)
	p.emitting = true
	var tree := get_tree()
	await tree.create_timer(3.0).timeout
	if is_instance_valid(p):
		p.queue_free()


# --- her pups --------------------------------------------------------------------------------

func _bear_one() -> void:
	_born += 1
	var pup := (get_script() as Script).new(true) as Node3D
	pup.set("male", rng.randf() < 0.5)
	pup.set("mother", self)
	pup.set("tank_min", tank_min)
	pup.set("tank_max", tank_max)
	get_parent().add_child(pup)
	pup.set("size", 0.28)
	var at := _at(CLOACA + Vector3(0.0, -0.05, 0.25))
	var away := (-_fwd).rotated(Vector3.UP, rng.randf_range(-1.2, 1.2))
	pup.call("place", at, atan2(-away.x, -away.z))
	pup.set("_spd", 1.6)
	pup.set("scale", Vector3.ONE * 0.28)
	pups.append(pup)
	pup.call("flee", _pos) # (off at once: she'd eat it)


# --- for Diet, pilot.gd -------------------------------------------------------------------

func _p_here() -> Vector3:
	return _pos


func behaviours() -> PackedStringArray:
	return PackedStringArray(["hunt", "investigate", "breach", "spyhop", "gape", "tail_slap", "chafe", "rest", "mate", "give_birth"])


func is_busy() -> bool:
	return _mode != "patrol"


func _physics_process(_dt: float) -> void:
	_hold_prey()


# --- the mesh --------------------------------------------------------------------------------

## The body at z: [its middle's height, half width, above, below].
static func _key(z: float) -> Vector4:
	var K := BODY
	if z <= float(K[0][0]):
		return Vector4(K[0][1], K[0][2], K[0][3], K[0][4])
	for i in K.size() - 1:
		var a: Array = K[i]
		var b: Array = K[i + 1]
		if z <= float(b[0]):
			var f := (z - float(a[0])) / (float(b[0]) - float(a[0]))
			var a0: Array = K[maxi(i - 1, 0)]
			var b1: Array = K[mini(i + 2, K.size() - 1)]
			var r := Vector4.ZERO
			for c in 4:
				r[c] = maxf(_cr(a0[c + 1], a[c + 1], b[c + 1], b1[c + 1], f), 0.0)
			return r
	var l: Array = K[K.size() - 1]
	return Vector4(l[1], l[2], l[3], l[4])


static func _cr(p0: float, p1: float, p2: float, p3: float, f: float) -> float:
	return 0.5 * (2.0 * p1 + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)


## A point on the body's skin: at z, a round it (0 its back's middle ..).
static func _skin(z: float, a: float) -> Vector3:
	var k := _key(z)
	var c := cos(a)
	var y := k.x + (k.z * c if c > 0.0 else k.w * -pow(-c, 0.85))
	return Vector3(k.y * sin(a), y, z)


## (The mouth's crescent, seen from beneath: its edge's z at x.)
static func _mouth_z(x: float) -> float:
	return -2.02 + 0.46 * pow(clampf(absf(x) / 0.29, 0.0, 1.0), 1.6)


static func _s_of(z: float) -> float:
	return clampf((z - Z_SNOUT) / (Z_STALK - Z_SNOUT), 0.0, 1.0)


static func _head_w(z: float) -> float:
	return 1.0 - smoothstep(-1.5, -1.2, z) # (with the head as it lifts)


static func _v(st: SurfaceTool, p: Vector3, n: Vector3, c0: Color, c1: Color) -> void:
	st.set_custom(0, c0)
	st.set_custom(1, c1)
	st.set_normal(n)
	st.add_vertex(p)


## [mesh, the pectorals' roots, their axes].
static func build(with_claspers: bool) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	st.set_custom_format(1, SurfaceTool.CUSTOM_RGBA_FLOAT)
	# the body: rings from the snout to the tail's stalk
	var NZ := 84
	var NR := 36
	var grid := []
	for i in NZ + 1:
		var t := float(i) / NZ
		var z := lerpf(Z_SNOUT, 1.47, pow(t, 1.25)) # (finer at the head)
		var row := []
		for r in NR + 1:
			row.append(_skin(z, TAU * r / NR))
		grid.append(row)
	var nrm := []
	for i in NZ + 1:
		var row := []
		for r in NR + 1:
			var pa: Vector3 = grid[mini(i + 1, NZ)][r]
			var pb: Vector3 = grid[maxi(i - 1, 0)][r]
			var qa: Vector3 = grid[i][(r + 1) % NR]
			var qb: Vector3 = grid[i][(r + NR - 1) % NR]
			var n := (qa - qb).cross(pa - pb)
			if n.length() < 1e-7 or i == 0:
				n = Vector3(0.0, -0.1, -1.0)
			n = n.normalized()
			if n.dot((grid[i][r] as Vector3) - Vector3(0.0, _key((grid[i][r] as Vector3).z).x, (grid[i][r] as Vector3).z)) < 0.0 and i > 0:
				n = -n
			row.append(n)
		nrm.append(row)
	for i in NZ:
		for r in NR:
			var q := [[i, r], [i + 1, r], [i + 1, r + 1], [i, r + 1]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var pts := []
				for j: int in tri:
					pts.append(grid[q[j][0]][q[j][1]])
				var cen: Vector3 = ((pts[0] as Vector3) + (pts[1] as Vector3) + (pts[2] as Vector3)) / 3.0
				# (the lower jaw's: below the gape (a ring's own line round it,
				# so the cut runs clean), behind the crescent; the upper jaw's
				# gum: the band just ahead of the crescent)
				var ac := TAU * (float(r) + 0.5) / NR
				var low := absf(ac - PI) < PI - GAPE_A
				var in_front := cen.z < -1.52
				var jaw_tri := 1.0 if (in_front and low and cen.z > _mouth_z(cen.x)) else 0.0
				var gum := 1.0 if (in_front and low and cen.z <= _mouth_z(cen.x) and cen.z > _mouth_z(cen.x) - 0.12) else 0.0
				# a tri's own corners in the order the quad gives (counter-clockwise from outside)
				for j: int in [tri[0], tri[2], tri[1]]:
					var gi: int = q[j][0]
					var gr: int = q[j][1]
					var p: Vector3 = grid[gi][gr]
					var k := _key(p.z)
					var jw := jaw_tri
					if not in_front: # (behind the mouth's corners: the throat stretched with it, smoothly)
						var av := absf(TAU * float(gr) / NR - PI)
						jw = (1.0 - smoothstep(-1.52, -1.15, p.z)) * (1.0 - smoothstep(PI - GAPE_A - 0.35, PI - GAPE_A + 0.05, av))
					var gw := gum * (1.0 - smoothstep(0.0, 0.11, _mouth_z(p.x) - p.z)) # (the gum thrown out from its edge, its back still on the snout: stretched, not torn)
					_v(st, p, nrm[gi][gr], Color(0.0, _s_of(p.z), float(gr) / NR, 0.0), Color(jw, gw, _head_w(p.z), 0.0))
	# the eyes
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 14
	sm.rings = 8
	var sa := sm.get_mesh_arrays()
	var ez := -1.86
	var ek := _key(ez)
	var ey := ek.x + ek.z * 0.38
	var ex := ek.y * sqrt(1.0 - 0.38 * 0.38) - 0.012
	for side: float in [-1.0, 1.0]:
		_prim(st, sa, Transform3D(Basis.from_scale(Vector3(0.026, 0.032, 0.032)), Vector3(ex * side, ey, ez)), Color(1.0, _s_of(ez), 0.0, 0.0), Color(0.0, 0.0, 1.0, side))
	# the teeth: the upper broad, triangular, hanging from the crescent; the
	# lower narrow, standing behind it on the lower jaw
	for row_: int in 2:
		var upper := row_ == 0
		var n := 26 if upper else 24
		for k in n:
			var f := (float(k) + 0.5) / n * 2.0 - 1.0
			var x := f * 0.275
			var z := _mouth_z(x) + (0.004 if upper else 0.045)
			var kk := _key(z)
			var yb := kk.x - kk.w * sqrt(maxf(1.0 - pow(x / maxf(kk.y, 0.01), 2.0), 0.0)) + (0.006 if upper else 0.012)
			var hgt := (0.058 if upper else 0.048) * (1.0 - 0.45 * absf(f))
			var wid := (0.036 if upper else 0.022) * (1.0 - 0.3 * absf(f))
			var tang := Vector3(1.0, 0.0, (_mouth_z(x + 0.01) - _mouth_z(x - 0.01)) / 0.02).normalized()
			var base0 := Vector3(x, yb, z) - tang * wid * 0.5
			var base1 := Vector3(x, yb, z) + tang * wid * 0.5
			var tip := Vector3(x, yb + (-hgt if upper else hgt), z + (0.008 if upper else -0.01))
			var nn := (base1 - base0).cross(tip - base0).normalized()
			var part := 9.0 if upper else 10.0
			var c1 := Color(0.0 if upper else 1.0, 1.0 if upper else 0.0, 1.0, 0.0)
			for e: Array in [[base0, 0.0, 0.0], [base1, 0.0, 1.0], [tip, 1.0, 0.5]]:
				_v(st, e[0], nn, Color(part, _s_of(z), e[1], e[2]), c1)
	# the fins
	var top := func(z: float) -> float:
		var k := _key(z)
		return k.x + k.z
	var bot := func(z: float) -> float:
		var k := _key(z)
		return k.x - k.w
	# (the first dorsal: tall, triangular, its trailing edge concave)
	_fin(st, Vector3(0.0, top.call(-0.72) - 0.04, -0.72), Vector3(0.0, top.call(-0.1) - 0.04, -0.1), Vector3(0.0, top.call(-0.35) + 0.68, -0.12),
			Vector3(0.0, 0.04, -0.08), Vector3(0.0, -0.08, -0.15), 2.0, 0.0)
	_fin(st, Vector3(0.0, top.call(0.93) - 0.01, 0.93), Vector3(0.0, top.call(1.03) - 0.01, 1.03), Vector3(0.0, top.call(1.0) + 0.07, 1.08),
			Vector3(0.0, 0.01, -0.01), Vector3(0.0, -0.01, -0.01), 3.0, 0.0)
	_fin(st, Vector3(0.0, bot.call(0.97) + 0.01, 0.97), Vector3(0.0, bot.call(1.07) + 0.01, 1.07), Vector3(0.0, bot.call(1.03) - 0.06, 1.11),
			Vector3(0.0, -0.01, -0.01), Vector3(0.0, 0.01, -0.01), 4.0, 0.0)
	# (the keels each side of the stalk)
	for side: float in [-1.0, 1.0]:
		var k0 := _key(1.12)
		var k1 := _key(1.47)
		_fin(st, Vector3(side * (k0.y - 0.01), k0.x, 1.12), Vector3(side * (k1.y - 0.01), k1.x, 1.47), Vector3(side * (_key(1.38).y + 0.045), _key(1.38).x, 1.38),
				Vector3(side * 0.005, 0.0, -0.02), Vector3(0.0, 0.0, 0.0), 12.0, side)
	# (the pectorals: long, sickle shaped, out low from the sides behind the gills)
	var roots := PackedVector3Array()
	var axes := PackedVector3Array()
	for side: float in [-1.0, 1.0]:
		var kf := _key(-1.08)
		var kb := _key(-0.74)
		var rf := Vector3(side * kf.y * 0.86, kf.x - kf.w * 0.38, -1.06)
		var rb := Vector3(side * kb.y * 0.8, kb.x - kb.w * 0.5, -0.78)
		var apex := Vector3(side * 1.2, kb.x - 0.66, -0.34)
		_fin(st, rf, rb, apex, Vector3(side * 0.05, 0.06, -0.15), Vector3(-side * 0.08, 0.02, -0.1), 6.0 if side < 0.0 else 7.0, side)
		roots.append(rf)
		axes.append(rb - rf)
	# (the pelvics, small, under the belly behind)
	for side: float in [-1.0, 1.0]:
		var kp := _key(0.5)
		_fin(st, Vector3(side * 0.1, bot.call(0.4) + 0.02, 0.4), Vector3(side * 0.06, bot.call(0.6) + 0.02, 0.6), Vector3(side * 0.3, kp.x - kp.w - 0.12, 0.72),
				Vector3(side * 0.02, -0.01, -0.03), Vector3(-side * 0.03, 0.0, -0.03), 8.0, side)
		if with_claspers: # (a male's: a stout rod back from each pelvic's inner edge)
			var c0 := Vector3(side * 0.06, bot.call(0.6) + 0.005, 0.58)
			var c1 := Vector3(side * 0.075, bot.call(0.92) - 0.035, 0.94)
			_rod(st, c0, c1, 0.026, 0.016, 11.0, side)
	# the tail: a near-symmetric crescent, its upper lobe a little the longer
	var NV := 24
	var NC := 7
	var rows := []
	for i in NV + 1:
		var v := lerpf(-1.0, 1.0, float(i) / NV)
		var av := absf(v)
		var span := 1.15 if v > 0.0 else 1.02
		var tipz := 2.3 if v > 0.0 else 2.2
		var lead := 1.4 + (tipz - 1.4) * pow(av, 1.05) # (its leading edges swept back, near straight)
		var trail := 1.86 + (tipz - 1.86) * pow(av, 0.75) # (its trailing edge a crescent, notched in its middle; the lobes broad)
		var y := 0.03 + v * span + 0.04 * (1.0 - av)
		var row := []
		for c in NC + 1:
			var f := float(c) / NC
			row.append([Vector3(0.0, y, lerpf(lead, trail, f)), av, f])
		rows.append(row)
	for i in NV:
		for c in NC:
			var q := [rows[i][c], rows[i + 1][c], rows[i + 1][c + 1], rows[i][c + 1]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for j: int in tri:
					var e: Array = q[j]
					_v(st, e[0], Vector3.RIGHT, Color(5.0, 1.0, e[1], e[2]), Color(0.0, 0.0, 0.0, 0.0))
	return [st.commit(), roots, axes]


## A fin: from its root (front, back) out to its apex, its leading edge
## bowed by lead, its trailing by trail; two sided.
static func _fin(st: SurfaceTool, rf: Vector3, rb: Vector3, apex: Vector3, lead: Vector3, trail: Vector3, part: float, side: float) -> void:
	var NS := 10
	var NC := 6
	var cl := (rf + apex) * 0.5 + lead
	var ct := (rb + apex) * 0.5 + trail
	var rows := []
	for i in NS + 1:
		var t := float(i) / NS
		var L := rf.lerp(cl, t).lerp(cl.lerp(apex, t), t)
		var T := rb.lerp(ct, t).lerp(ct.lerp(apex, t), t)
		var row := []
		for c in NC + 1:
			var f := float(c) / NC
			row.append([L.lerp(T, f), t, f])
		rows.append(row)
	var nn := (rb - rf).cross(apex - rf).normalized()
	for i in NS:
		for c in NC:
			var q := [rows[i][c], rows[i + 1][c], rows[i + 1][c + 1], rows[i][c + 1]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for j: int in tri:
					var e: Array = q[j]
					var p: Vector3 = e[0]
					_v(st, p, nn, Color(part, _s_of(p.z), e[1], e[2]), Color(0.0, 0.0, _head_w(p.z), side))


static func _rod(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, part: float, side: float) -> void:
	var d := (b - a).normalized()
	var u := d.cross(Vector3.UP).normalized()
	var w := d.cross(u).normalized()
	var N := 8
	var rings := []
	for i in 5:
		var t := float(i) / 4.0
		var c := a.lerp(b, t)
		var r := lerpf(ra, rb, t) * (1.0 if i < 4 else 0.6)
		var ring := []
		for k in N + 1:
			var an := TAU * k / N
			var o := u * cos(an) + w * sin(an)
			ring.append([c + o * r, o, t])
		rings.append(ring)
	for i in 4:
		for k in N:
			var q := [rings[i][k], rings[i + 1][k], rings[i + 1][k + 1], rings[i][k + 1]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for j: int in tri:
					var e: Array = q[j]
					_v(st, e[0], e[1], Color(part, _s_of((e[0] as Vector3).z), e[2], 0.0), Color(0.0, 0.0, 0.0, side))


static func _prim(st: SurfaceTool, arrays: Array, xf: Transform3D, c0: Color, c1: Color) -> void:
	var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in ix:
		_v(st, xf * vs[i], (xf.basis * ns[i]).normalized(), c0, c1)
