class_name Wasp
extends Node3D
## A paper wasp (Polistes fuscatus), drawn at twice life size (about 31 mm
## long, its parts modelled at the life size of 16 mm: MM): dark reddish brown,
## the gaster ringed with narrow yellow bands, yellowish legs, the antennae
## orange at their tips, the wings smoky amber. Built from parts, posed
## every frame by hand (procedural: no clips).
##
## Each animation is a method, run until another's called (no state machine
## yet: nothing chooses them; the caller does, e.g. tools/creatures/wasp_demo):
## - seek_food(centre, radius): flying about, weaving and hovering,
##   turning to look, now and then dropping to look closer
## - feed_on_flower(head, normal, sway): at a flower's head in flight,
##   swaying with it (its shaders: the head's own sway), legs down to it, head down lapping,
##   antennae dabbing, round to another side of it now and then
## - feed_on_insect(prey, surface, normal): over its prey, pouncing,
##   then on the surface chewing it into a ball, held in its front legs,
##   turning it as it goes
## - land(at, normal): letting down onto a surface, walking about a bit,
##   then settling: crouching, cleaning each antenna with a front leg, wings
##   folded, the gaster pumping
## - sting(target): rearing up, wings raised and buzzing, the gaster curled
##   under, jabbing (from the air, darting in at it)
## - lay_eggs(cells, normal): down onto its comb (Wasp.comb), and at each
##   cell in turn: its back to it, crouching, the gaster curled down into
##   it, pumping, an egg left at its bottom (Brood's); then settling
## - mate(partner): he (male set: no different to see) flies to her (she
##   down on a surface, still: the ground under her if she's flying), and
##   pounces onto her back, his legs holding her sides, his antennae
##   stroking hers, his gaster curled down and round under the tip of hers;
##   a while, buzzing now and then; then he's off, and both seek food again
##
## The motor under them, every frame: flight (springing toward a target,
## banking, nose up hovering, a jitter), walking on a plane (a tripod gait:
## three legs swing while three stand), the legs (two-bone reach, dangling
## in flight), the wings (folded, raised, or beating: a blur), the antennae
## (twitching), the head, mandibles and gaster.
##
## Steering (a state machine's: pilot.gd): go (flying, at its height; or
## walking, on the surface it's on), go_to, face, stop (hovering, or
## standing), act (seek_food {centre, radius, seconds}, feed_on_flower
## {head, normal, sway, seconds}, feed_on_insect {prey, at, normal,
## seconds}, land {at, normal}, sting {at}, lay_eggs {cells, normal, depth},
## take_off), behaviours, is_busy, action_finished; height (the ground,
## when it walks on it).
## Its parts are in model mm (_body is scaled by MM); the wasp itself in metres.
## Its position is set every frame: put it under a node that isn't moved.

signal action_finished(name: String, ok: bool)
const PilotScript := preload("res://scripts/creatures/pilot.gd")
const MM := 0.002 ## m drawn per model mm (twice life size)
const BroodScript := preload("res://scripts/creatures/brood.gd") # (by path: found whether or not the editor has seen the class yet)
const BODY_H := 2.3 ## mm the thorax's middle stands over the surface
const STEP_TIME := 0.07 ## s a leg's swing takes

const HEAD_AT := Vector3(0.0, 0.3, -2.2)
const GASTER_AT := Vector3(0.0, -0.1, 2.2)
# the gaster's segments (mm): length, half width, half height
const GASTER := [[1.3, 0.75, 0.7], [2.1, 1.55, 1.35], [1.9, 1.5, 1.3], [1.6, 1.3, 1.1], [1.3, 1.0, 0.85], [1.0, 0.65, 0.55]]
const GASTER_DROOP := [0.22, 0.05, 0.03, 0.03, 0.05, 0.08] # rad each joint bends down at rest
const GASTER_CURL := [0.25, 0.3, 0.35, 0.45, 0.5, 0.55] # and more, curled to sting
# the legs, the right side's (the left's mirrored): hip, femur, tibia,
# tarsus (mm), home (the foot at rest on the surface: x, z), dangle (the
# ankle in flight)
const LEGS := [
	# (their feet splayed each into its own part of the round: the front
	# legs forward and out, the middle out to the side, the hind back and
	# out; so each knee bends up and out in its own leg's plane and none
	# crosses another)
	{"hip": Vector3(0.6, -1.1, -1.3), "f": 2.4, "t": 2.3, "s": 2.2, "home": Vector2(5.0, -5.3), "dangle": Vector3(1.6, -3.0, -3.4), "hang": Vector3(0.25, -0.8, -0.45)},
	{"hip": Vector3(0.85, -1.2, 0.0), "f": 3.0, "t": 3.1, "s": 2.7, "home": Vector2(8.3, -1.0), "dangle": Vector3(2.4, -3.5, 0.2), "hang": Vector3(0.35, -0.9, 0.05)},
	{"hip": Vector3(0.85, -1.1, 1.2), "f": 3.6, "t": 4.1, "s": 3.5, "home": Vector2(7.2, 8.2), "dangle": Vector3(2.0, -3.8, 4.6), "hang": Vector3(0.2, -0.8, 0.6)},
]
const TRIPOD := [[0, 3, 4], [1, 2, 5]] # (a leg: its pair * 2, + 1 the right)
# the wings: hinge, length, chord (mm); folded, and raised (sweep back from
# square out, rad; up, rad)
const WINGS := [
	{"hinge": Vector3(0.95, 1.25, -0.8), "l": 10.5, "c": 2.9, "fold": Vector2(1.47, 0.04), "raise": Vector2(0.55, 0.35)},
	{"hinge": Vector3(0.95, 1.05, 0.5), "l": 7.5, "c": 2.0, "fold": Vector2(1.4, 0.0), "raise": Vector2(0.75, 0.25)},
]
const STROKE := Vector2(-1.0, 1.25) ## the beat's sweep, front to back (rad)

const BROWN := Color(0.28, 0.13, 0.07)
const DARK := Color(0.07, 0.045, 0.03)
const YELLOW := Color(0.93, 0.75, 0.2)
const LEG_BROWN := Color(0.45, 0.2, 0.08)
const LEG_YELLOW := Color(0.8, 0.55, 0.18)
const TIP_ORANGE := Color(0.85, 0.45, 0.12)

var rng := RandomNumberGenerator.new()
var height: Callable ## (x, z) -> the ground's y (walking on it, piloted)
var _pilot: PilotScript
var _piloting := false # (its own action stopped: the pilot steering)
var _p_done := false

# where it is and how it's moving
var flying := true
var surface_p := Vector3.ZERO ## the plane it's on, or landing on
var surface_n := Vector3.UP
var _pos := Vector3.ZERO # flying: the thorax's middle; on a surface: the point under it
var _vel := Vector3.ZERO
var _acc := Vector3.ZERO
var _heading := Vector3.FORWARD
var _look := Vector3.ZERO # hovering: the way to face (ZERO: as it is)
var _fly_target := Vector3.ZERO
var _max_speed := 0.8 # m/s
# swaying with a flower's head (feed_on_flower): drawn so by its shaders
var _sway_at := Vector3.ZERO # the head, still
var _sway_k := 0.0 # its share of the wind's sway
var _sway_w := 0.0 # how much of it's on: more the nearer the head
var _mats: Array[ShaderMaterial] = []
var _sway_set := Vector4(0, 0, 0, -1) # (what the shaders were last told)
var _weave := 0.0 # m/s side to side
var _jitter := 0.002 # m
var _walk_target := Vector3.INF
var _walk_speed := 0.025 # m/s
var _speed := 0.0
var _turn_to := Vector3.ZERO # on a surface: the way to turn to
var _turning := false
var _land_plane := false # flying: reaching its legs down for surface_p
var _ground_w := 0.0 # just taken off: its legs still where they stood
var _t := 0.0
var _act := 0

# the pose: what the actions ask (_p), and as it is, easing there (_a)
const POSE := {"hover_pitch": 0.45, "wing_open": 0.0, "buzz": 1.0, "curl": 0.0, "sting_out": 0.0, "crouch": 0.0, "rise": 0.0, "lift_pitch": 0.0,
		"head_pitch": 0.0, "head_yaw": 0.0, "mandibles": 0.0, "chew": 0.0, "lap": 0.0,
		"ant_pitch": 0.35, "ant_spread": 0.35, "ant_down": 0.0, "ant_tap": 0.0, "pump": 0.0, "hold": 0.0, "groom": 0.0}
const RATES := {"buzz": 40.0, "wing_open": 14.0, "curl": 16.0, "sting_out": 10.0, "mandibles": 20.0, "chew": 6.0, "lap": 6.0,
		"head_pitch": 6.0, "head_yaw": 6.0, "crouch": 4.0, "rise": 8.0, "lift_pitch": 6.0, "pump": 3.0, "hold": 8.0, "groom": 5.0}
var _p := POSE.duplicate()
var _a := POSE.duplicate()
var _groom_side := 1.0
# mating
var male := false
var mate_secs := 20.0 ## s joined
var _mate: Node3D
var _mate_role := "" # "male", "female"
var _riding := false # (a male, on her back)
var _ride_k := 0.0 # 0..1 onto her
var _ride_from := Transform3D()
const RIDE_AT := Vector3(0.0, 2.5, 0.9) # mm, his thorax's middle from hers

# the legs
var _feet: Array[Vector3] = [] # world: planted
var _feet_now: Array[Vector3] = [] # world: as they are (mid-swing)
var _feet_drawn: Array[Vector3] = [] # world: where they were drawn last
var _swing_from: Array[Vector3] = []
var _swinging := -1 # the tripod swinging
var _swing_t := 0.0
var _next_group := 0

# the antennae's twitches: per side, the offset (yaw, pitch) and where it's going
var _tw := [Vector2.ZERO, Vector2.ZERO]
var _tw_to := [Vector2.ZERO, Vector2.ZERO]
var _tw_wait := [0.0, 0.0]

# what it's holding (its prey)
var _holding: Node3D
var _hold_from := Transform3D()
var _hold_t := 0.0
var _prey_roll := 0.0
var _prey_ball := 0.0 # 0 whole .. 1 chewed into a ball

# the parts
var _body: Node3D
var _head: Node3D
var _mandibles: Array[Node3D] = []
var _antennae: Array = [] # per side: its segments (MeshInstance3D)
var eggs: Array[Node3D] = [] ## the eggs it's laid (in its parent)
var _gaster: Array[Node3D] = []
var _gaster_mesh: Array[MeshInstance3D] = []
var _sting: Node3D
var _legs: Array = [] # per leg: [coxa, femur, tibia, tarsus, claw]
var _wings: Array[MeshInstance3D] = [] # fore L, fore R, hind L, hind R
var _fans: Array[MeshInstance3D] = [] # L, R
var _wing_mat: ShaderMaterial
var _hind_mat: ShaderMaterial
var _pal: Dictionary = {} # (its colours: _palette())
var _sphere: SphereMesh
var _cyl: CylinderMesh


func _init() -> void:
	rng.randomize()
	for i in 6:
		_feet.append(Vector3.ZERO)
		_feet_now.append(Vector3.ZERO)
		_feet_drawn.append(Vector3.ZERO)
		_swing_from.append(Vector3.ZERO)
	_build()


func _ready() -> void:
	_pos = global_position
	_fly_target = _pos
	var f := -global_basis.z
	f.y = 0.0
	_heading = f.normalized() if f.length() > 0.01 else Vector3.FORWARD


## Puts it at p (flying, hovering there).
func place(p: Vector3) -> void:
	flying = true
	_pos = p
	_fly_target = p
	_vel = Vector3.ZERO
	global_position = p


# --- the actions -----------------------------------------------------------


## Flying about round centre (the ground there), within radius (m): weaving
## from place to place, hovering, turning this way and that to look, now
## and then dropping low to look closer. Till another action.
func seek_food(centre: Vector3, radius := 1.5) -> void:
	var id := _begin()
	release()
	if not await _take_off(id):
		return
	_p.ant_pitch = 0.45
	_p.ant_spread = 0.4
	while true:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius
		var to := centre + Vector3(cos(a) * r, rng.randf_range(0.15, 0.9), sin(a) * r)
		_max_speed = rng.randf_range(0.5, 1.1)
		_weave = rng.randf_range(0.15, 0.35)
		_jitter = 0.003
		_look = Vector3.ZERO
		_fly_target = to
		if not await _until(id, func() -> bool: return _pos.distance_to(to) < 0.05, 6.0):
			return
		# hovering, looking about
		_weave = 0.0
		_jitter = 0.0025
		_max_speed = 0.3
		for k in rng.randi_range(1, 3):
			_look = _heading.rotated(Vector3.UP, rng.randf_range(-1.6, 1.6))
			_p.ant_spread = rng.randf_range(0.25, 0.55)
			if not await _wait(id, rng.randf_range(0.35, 0.9)):
				return
		# now and then down to look closer at something
		if rng.randf() < 0.4:
			var low := Vector3(_pos.x + rng.randf_range(-0.12, 0.12), centre.y + rng.randf_range(0.04, 0.1), _pos.z + rng.randf_range(-0.12, 0.12))
			_fly_target = low
			_max_speed = 0.35
			if not await _until(id, func() -> bool: return _pos.distance_to(low) < 0.01, 3.0):
				return
			_p.ant_pitch = 0.05
			_p.head_pitch = -0.25
			_look = _heading.rotated(Vector3.UP, rng.randf_range(-0.6, 0.6))
			if not await _wait(id, rng.randf_range(0.6, 1.3)):
				return
			_p.ant_pitch = 0.45
			_p.head_pitch = 0.0


## At a flower's head (where it stands still: head, normal the way it
## faces), feeding from it in flight, not landing: hovering over it, its
## legs reaching down to the head and its own head down, lapping, the
## antennae dabbing at it; now and then round to another side of it.
## sway: the head's share of the wind's sway (ground_cover.gdshader: its
## grass_sway * the clump's size * how far up the clump, squared): the
## wasp's own shaders sway it with the head, coming in as it nears it (so
## the CPU never needs to know where the wind has the head). Till another
## action.
func feed_on_flower(head: Vector3, normal := Vector3.UP, sway := 0.0) -> void:
	var id := _begin()
	release()
	normal = normal.normalized()
	if not await _take_off(id):
		return
	var face := _away(head)
	_look = face
	_sway_at = head
	_sway_k = sway
	# over to it
	_max_speed = 0.9
	var over := head + normal * 0.03 - face * 3.5 * MM
	_fly_target = over
	if not await _until(id, func() -> bool: return _pos.distance_to(over) < 0.006, 8.0):
		return
	# feeding
	_p.head_pitch = -0.5
	_p.ant_down = 0.4
	_p.ant_tap = 0.35
	_p.lap = 1.0
	_p.hover_pitch = 0.12
	_jitter = 0.0005
	_max_speed = 0.12
	surface_p = head
	surface_n = normal
	_land_plane = true
	while true:
		# its thorax over the head, a little back: its own head over the middle
		_fly_target = head + normal * (BODY_H + 0.8) * MM - _flat(face, normal) * 3.5 * MM
		if not await _wait(id, rng.randf_range(2.0, 4.5)):
			return
		# round to another side of it, lifting a little as it goes
		face = face.rotated(normal, rng.randf_range(0.8, 2.0) * (1.0 if rng.randf() < 0.5 else -1.0))
		_look = face
		_p.lap = 0.0
		_land_plane = false
		_fly_target = head + normal * 0.012 - _flat(face, normal) * 3.5 * MM
		if not await _wait(id, 0.7):
			return
		_land_plane = true
		_p.lap = 1.0


## Over its prey (a node: a caterpillar, say: Wasp.caterpillar()) on a
## surface (at, normal), hovering, then pouncing on it; then on the surface
## chewing it, held under its head in its front legs, turning it as it goes,
## into a ball. (If it's already holding it: down on the surface with it,
## and chewing.) Till another action (which drops it, but seek_food).
func feed_on_insect(prey: Node3D, at: Vector3, normal := Vector3.UP) -> void:
	var id := _begin()
	normal = normal.normalized()
	if _holding != prey:
		release()
		if not await _take_off(id):
			return
		var p := prey.global_position
		var from := _pos - p
		from -= normal * from.dot(normal)
		var face := (-from).normalized() if from.length() > 0.01 else _heading
		# hovering over it, facing it
		var over := p - face * 0.025 + normal * 0.035
		_look = face
		_max_speed = 0.9
		_fly_target = over
		if not await _until(id, func() -> bool: return _pos.distance_to(over) < 0.006, 6.0):
			return
		_p.ant_pitch = 0.1
		if not await _wait(id, rng.randf_range(0.4, 0.9)):
			return
		# and on it
		var on := at + (p - at) - normal * (p - at).dot(normal) - face * 4.5 * MM # (its head over it)
		if not await _touch_down(id, on, normal, face, 0.35):
			return
		_holding = prey
		_hold_from = prey.global_transform
		_hold_t = 0.0
		_prey_ball = 0.0
		_p.hold = 1.0
	elif flying:
		if not await _touch_down(id, at, normal, _heading):
			return
	_p.hold = 1.0
	_p.chew = 1.0
	_p.head_pitch = -0.25
	_p.ant_down = 0.35
	_p.ant_tap = 0.2
	_p.crouch = 0.35
	_p.pump = 0.4
	while true:
		if not await _wait(id, rng.randf_range(2.0, 4.0)):
			return
		# a pause, and round a little
		_p.chew = 0.0
		if not await _turn(id, _heading.rotated(surface_n, rng.randf_range(-0.8, 0.8))):
			return
		_p.chew = 1.0


## Down onto a surface (at, normal); walking about on it a bit, stopping
## and starting, then settling: crouching, cleaning its antennae, wings
## folded, the gaster pumping. Stays so till another action.
func land(at: Vector3, normal := Vector3.UP) -> void:
	var id := _begin()
	release()
	normal = normal.normalized()
	if not flying:
		if not await _take_off(id):
			return
	if not await _touch_down(id, at, normal, _in_plane(normal, 1.0).normalized()):
		return
	# about a bit
	_p.ant_tap = 0.3
	for k in rng.randi_range(2, 4):
		_walk_target = at + _in_plane(normal, 0.04)
		if not await _until(id, func() -> bool: return _walk_target == Vector3.INF, 4.0):
			return
		if not await _wait(id, rng.randf_range(0.3, 1.0)):
			return
	# settling
	_p.ant_tap = 0.0
	_p.crouch = 0.7
	_p.ant_down = 0.15
	_p.pump = 0.35
	if not await _wait(id, 0.6):
		return
	for side: float in [-1.0, 1.0]:
		_groom_side = side
		_p.groom = 1.0
		_p.head_yaw = -0.25 * side
		_p.head_pitch = -0.3
		if not await _wait(id, 1.4):
			return
		_p.groom = 0.0
		_p.head_yaw = 0.0
		_p.head_pitch = 0.0
		if not await _wait(id, 0.4):
			return
	_p.ant_pitch = 0.2
	_p.ant_down = 0.25


## Stinging target (a point): on a surface, turning to it, going nearer,
## rearing up with its wings raised and buzzing, the gaster curled under
## and forward, jabbing; from the air, hovering at it, curling, and darting
## in to jab, again and again. Then calming.
func sting(target: Vector3) -> void:
	var id := _begin()
	release()
	# on a surface, but the target's not on it (or not near): from the air
	if not flying:
		var to := target - _pos
		var off_plane := absf(to.dot(surface_n))
		if off_plane > 0.01 or (to - surface_n * to.dot(surface_n)).length() > 0.06:
			if not await _take_off(id):
				return
	if flying:
		var face := target - _pos
		face.y = 0.0
		face = face.normalized() if face.length() > 0.001 else _heading
		var off := target - face * 0.03 + Vector3.UP * 0.012
		_look = face
		_max_speed = 0.9
		_fly_target = off
		if not await _until(id, func() -> bool: return _pos.distance_to(off) < 0.006, 6.0):
			return
		_p.curl = 1.0
		_p.sting_out = 1.0
		_p.ant_pitch = 0.6
		if not await _wait(id, 0.35):
			return
		for k in rng.randi_range(2, 4):
			_max_speed = 1.4
			_fly_target = target - face * 2.0 * MM + Vector3.UP * 7.0 * MM # (the curled tip on it)
			if not await _wait(id, 0.16):
				return
			for j in 3:
				_p.curl = 1.2
				if not await _wait(id, 0.06):
					return
				_p.curl = 0.95
				if not await _wait(id, 0.06):
					return
			_max_speed = 0.8
			_fly_target = off
			if not await _wait(id, rng.randf_range(0.3, 0.6)):
				return
		_p.curl = 0.15
		_p.sting_out = 0.0
		_p.ant_pitch = 0.35
		return
	# on a surface
	if not await _turn(id, target - _pos):
		return
	var to := target - _pos
	to -= surface_n * to.dot(surface_n)
	if to.length() > 0.006:
		_walk_target = _pos + to - to.normalized() * 9.0 * MM
		if not await _until(id, func() -> bool: return _walk_target == Vector3.INF, 3.0):
			return
	_p.wing_open = 0.8
	_p.buzz = 1.0
	_p.rise = 1.0
	_p.lift_pitch = 0.3
	_p.ant_pitch = 0.6
	_p.crouch = 0.0
	if not await _wait(id, 0.25):
		return
	_p.curl = 1.0
	_p.sting_out = 1.0
	if not await _wait(id, 0.3):
		return
	for k in rng.randi_range(4, 6):
		_p.curl = 1.25
		_p.lift_pitch = 0.15
		if not await _wait(id, 0.08):
			return
		_p.curl = 0.95
		_p.lift_pitch = 0.3
		if not await _wait(id, 0.1):
			return
	if not await _wait(id, 0.4):
		return
	_p.buzz = 0.0
	_p.wing_open = 0.0
	_p.curl = 0.1
	_p.sting_out = 0.0
	_p.rise = 0.0
	_p.lift_pitch = 0.0
	_p.ant_pitch = 0.35


## Laying: down onto the comb whose cells' mouths are `cells` (points, the
## comb's face facing normal), and at each in turn: turning its back to
## it, the gaster over it, crouching, curling it down into the cell,
## pumping; an egg left at the cell's bottom (`depth` down). Then settling.
func lay_eggs(cells: Array, normal := Vector3.UP, depth := 0.012) -> void:
	var id := _begin()
	release()
	normal = normal.normalized()
	if cells.is_empty():
		return
	var first: Vector3 = cells[0]
	if flying or _pos.distance_to(first) > 0.05 or surface_n.dot(normal) < 0.99:
		if not flying:
			if not await _take_off(id):
				return
		if not await _touch_down(id, first + _in_plane(normal, 0.015), normal, _in_plane(normal, 1.0).normalized()):
			return
	_p.ant_tap = 0.3
	for c: Vector3 in cells:
		# the thorax a body's length on from the cell, facing away: the
		# gaster's tip over it
		var away := _flat(_pos - c, normal)
		_walk_target = c + away * 8.5 * MM
		if not await _until(id, func() -> bool: return _walk_target == Vector3.INF, 4.0):
			return
		if not await _turn(id, away):
			return
		_p.crouch = 0.8
		_p.curl = 0.6
		_p.pump = 0.7
		_p.ant_down = 0.2
		if not await _wait(id, 1.5):
			return
		var parent := get_parent() as Node3D
		if parent:
			var e := BroodScript.egg("wasp")
			parent.add_child(e)
			var x := normal.cross(Vector3.FORWARD if absf(normal.z) < 0.9 else Vector3.RIGHT).normalized()
			e.transform = Transform3D(Basis(x, normal, x.cross(normal)), c - normal * depth)
			eggs.append(e)
		_p.curl = 0.1
		_p.pump = 0.2
		_p.crouch = 0.3
		if not await _wait(id, 0.5):
			return
	# settling, on guard on its comb
	_p.ant_tap = 0.0
	_p.crouch = 0.7
	_p.pump = 0.35
	_p.ant_down = 0.15


# --- steering: a state machine's (pilot.gd) ---------------------------------------

func _pl() -> PilotScript:
	if _pilot == null:
		_pilot = PilotScript.new(self)
		_pilot.finished = action_finished.emit
	return _pilot


func go(direction: Vector3, speed := -1.0, seconds := -1.0) -> void:
	_pl().go(direction, speed, seconds)


func go_to(point: Vector3, speed := -1.0) -> void:
	_pl().go_to(point, speed)


func face(direction: Vector3) -> void:
	_pl().face(direction)


func stop() -> void:
	_pl().stop()


func act(name: String, args := {}) -> bool:
	return _pl().act(name, args)


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func is_busy() -> bool:
	return _pilot != null and _pilot.busy()


func _p_here() -> Vector3:
	return _pos


func _p_heading() -> Vector3:
	return _heading


## Flying: to the point; on a surface: walking to it, on the surface (the
## ground's height under it, if it's given).
func _p_steer(point: Vector3, speed: float) -> void:
	if not _piloting:
		_begin() # (its own action stopped)
		release()
		_piloting = true
	if flying:
		_fly_target = point
		_max_speed = speed if speed > 0.0 else 0.8
		_look = Vector3.ZERO
	else:
		if height.is_valid() and surface_n.y > 0.95:
			surface_p = Vector3(_pos.x, float(height.call(_pos.x, _pos.z)), _pos.z)
		_walk_target = point - surface_n * (point - surface_p).dot(surface_n)
		_walk_speed = speed if speed > 0.0 else 0.025


func _p_hold() -> void:
	_begin()
	_piloting = true
	if flying:
		_fly_target = _pos
		_max_speed = 0.5
	else:
		_walk_target = Vector3.INF


func _p_mobile() -> bool:
	return true


func _p_speed() -> float:
	return 0.8 if flying else 0.025


func _p_reach() -> float:
	return 0.03 if flying else 0.01


func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["seek_food", "feed_on_flower", "feed_on_insect", "land", "sting", "lay_eggs", "take_off", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"feed_on_flower":
			if not args.has("head"):
				return false
		"feed_on_insect":
			if not args.has("prey"):
				return false
		"land", "sting":
			if not args.has("at"):
				return false
		"lay_eggs":
			if (args.get("cells", []) as Array).is_empty():
				return false
	_piloting = false
	_p_run(name, args)
	return true


## Runs its action; done if it ends (not cut short by another).
func _p_run(name: String, args: Dictionary) -> void:
	_p_done = false
	var id := _act + 1 # (the action's own: each begins by taking the next)
	match name:
		"seek_food":
			await seek_food(args.get("centre", _pos), float(args.get("radius", 1.0)))
		"feed_on_flower":
			await feed_on_flower(args.head, args.get("normal", Vector3.UP), float(args.get("sway", 0.0)))
		"feed_on_insect":
			await feed_on_insect(args.prey, args.get("at", (args.prey as Node3D).position), args.get("normal", Vector3.UP))
		"land":
			await land(args.at, args.get("normal", Vector3.UP))
		"sting":
			await sting(args.at)
		"lay_eggs":
			await lay_eggs(args.cells, args.get("normal", Vector3.UP), float(args.get("depth", 0.012)))
		"take_off":
			var tid := _begin()
			await _take_off(tid)
	if _act == id:
		_p_done = true


func _p_act_done(_name: String) -> bool:
	return _p_done


func _p_act_secs(name: String) -> float:
	match name:
		"seek_food", "feed_on_flower":
			return 10.0
		"feed_on_insect":
			return 15.0
	return -1.0


# --- mating ----------------------------------------------------------------------

## Mating with partner (a wasp, the other sex; neither mating): see the
## class. False if they can't.
func mate(partner: Node3D, secs := -1.0) -> bool:
	if partner == null or partner == self or not partner.has_method("_mate_begin") or bool(partner.get("male")) == male:
		return false
	if _mate_role != "" or partner.get("_mate_role") != "":
		return false
	var him: Node3D = self if male else partner
	var her: Node3D = partner if male else self
	her.call("_mate_begin", him, "female", secs if secs > 0.0 else mate_secs)
	him.call("_mate_begin", her, "male", secs if secs > 0.0 else mate_secs)
	return true


func is_mating() -> bool:
	return _mate_role != ""


func _mate_begin(partner: Node3D, role: String, secs: float) -> void:
	var id := _begin()
	release()
	_mate = partner
	_mate_role = role
	mate_secs = secs
	if role == "female":
		_mate_wait(id)
	else:
		_mate_go(id)


## (Hers: down where she is (on the surface she's on, or the ground under
## her), still, till he's done.)
func _mate_wait(id: int) -> void:
	if flying:
		var g := float(height.call(_pos.x, _pos.z)) if height.is_valid() else 0.0
		if not await _touch_down(id, Vector3(_pos.x, g, _pos.z), Vector3.UP, _heading, 0.12):
			return
	_p.crouch = 0.35
	_p.ant_down = 0.2
	await _until(id, func() -> bool: return _mate_role == "", 600.0)


## (His: to her, onto her back, joined, and off.)
func _mate_go(id: int) -> void:
	if not flying:
		if not await _take_off(id):
			return
	_max_speed = 0.9
	_weave = 0.0
	var t := 0.0
	while true:
		await get_tree().process_frame
		if id != _act or not _mate_ok():
			return
		t += get_process_delta_time()
		var her := _mate as Node3D
		var hh: Vector3 = her.get("_heading")
		_fly_target = her.global_position + Vector3.UP * 0.02 - hh * 0.012
		_look = hh
		if (not bool(her.get("flying")) and _pos.distance_to(_fly_target) < 0.01) or t > 30.0:
			break
	if bool(_mate.get("flying")):
		_mate_end()
		return
	# the pounce: onto her back (his feet from where they're drawn, dangling:
	# the ground's, left from when he last stood, may be anywhere)
	_ride_from = global_transform
	for i in 6:
		_feet_now[i] = _feet_drawn[i]
		_feet[i] = _feet_drawn[i]
	_ride_k = 0.0
	_riding = true
	flying = false
	_p.buzz = 0.0
	_p.wing_open = 0.0
	_p.curl = 0.85
	_p.ant_down = 0.6
	_p.ant_tap = 1.0
	var left := mate_secs
	while left > 0.0:
		if not await _wait(id, 0.5):
			return
		left -= 0.5
		_p.buzz = 1.0 if rng.randf() < 0.12 else 0.0 # (a buzz of his wings now and then)
		_p.wing_open = _p.buzz
	# off her, and away
	var up := global_basis.y
	_riding = false
	_ride_k = 0.0
	flying = true
	_pos = global_position
	_vel = up * 0.2
	_fly_target = _pos + up * 0.04
	_p.curl = 0.0
	_p.ant_tap = 0.0
	_p.ant_down = 0.0
	var was := _mate
	_mate_end()
	seek_food(_pos, 1.0)
	if is_instance_valid(was):
		was.call("seek_food", was.get("_pos"), 1.0)


func _mate_ok() -> bool:
	return _mate != null and is_instance_valid(_mate) and _mate.get("_mate_role") != ""


func _mate_end() -> void:
	var m := _mate
	_mate = null
	_mate_role = ""
	if _riding:
		_riding = false
		flying = true
		_pos = global_position
		_vel = Vector3.ZERO
		_fly_target = _pos
	if m != null and is_instance_valid(m) and m.get("_mate_role") != "":
		m.call("_mate_end")


## On her back: carried (his place hers), his legs holding her sides.
func _ride(dt: float) -> void:
	if not _mate_ok():
		_mate_end()
		return
	var her := _mate as Node3D
	var ht := her.global_transform
	_ride_k = move_toward(_ride_k, 1.0, dt / 0.35)
	var e := _ride_k * _ride_k * (3.0 - 2.0 * _ride_k)
	var on := Transform3D(ht.basis * Basis(Vector3.RIGHT, -0.08), ht * (RIDE_AT * MM))
	global_transform = _ride_from.interpolate_with(on, e)
	surface_n = ht.basis.y.normalized()
	surface_p = ht * (Vector3(0.0, -0.6, 0.0) * MM)
	_heading = -ht.basis.z
	# (his feet: hers sides, front to back)
	for i in 6:
		var side := 1.0 if i % 2 == 1 else -1.0
		var z := [-1.4, 0.2, 1.8][i / 2] as float
		var f := ht * (Vector3(1.5 * side, -0.6, z) * MM)
		_feet[i] = f
		_feet_now[i] = (_feet_now[i] as Vector3).lerp(f, e)


## Lets go of what it holds (it's left where it is).
func release() -> void:
	_holding = null
	_p.hold = 0.0
	_a.hold = 0.0


## A caterpillar, as prey (about 16 mm, green, its head brown): its middle
## at its origin, lying along z.
static func caterpillar() -> Node3D:
	var root := Node3D.new()
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.42, 0.62, 0.2)
	green.roughness = 0.55
	var brown := StandardMaterial3D.new()
	brown.albedo_color = Color(0.4, 0.28, 0.12)
	brown.roughness = 0.4
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 6
	for i in 9:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		var z := (i - 4.0) * 0.0017
		var r := 0.0024 * (1.0 - 0.25 * pow(absf(i - 3.5) / 4.5, 2.0))
		mi.scale = Vector3(r, r * 0.9, 0.0024)
		mi.position = Vector3(0.0, 0.0, z)
		mi.material_override = brown if i == 0 else green
		root.add_child(mi)
	return root


## A small paper comb, for it to lay in (twice life size): seven round
## cells of grey paper, packed, flaring a little to their mouths, each its
## own height and shade, their mouths up (a real comb hangs mouth down:
## turned up here, to see in), about 6 mm across, 7 mm deep. Its origin at
## its foot. Returns [the comb, its cells' mouths (the comb's space)].
static func comb() -> Array:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mouths := []
	var spots := [Vector2.ZERO]
	for k in 6:
		var a := k * PI / 3.0
		spots.append(Vector2(cos(a), sin(a)) * 6.2 * MM)
	for p: Vector2 in spots:
		var cell := CylinderMesh.new()
		var deep := rng.randf_range(6.3, 7.4) * MM
		cell.top_radius = 3.2 * MM
		cell.bottom_radius = 2.7 * MM
		cell.height = deep
		cell.radial_segments = 14
		cell.rings = 2
		cell.cap_top = false
		var paper := StandardMaterial3D.new()
		paper.albedo_color = Color(0.55, 0.52, 0.47).darkened(rng.randf_range(0.0, 0.15))
		paper.roughness = 0.95
		paper.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi := MeshInstance3D.new()
		mi.mesh = cell
		mi.material_override = paper
		mi.position = Vector3(p.x, deep * 0.5, p.y)
		root.add_child(mi)
		mouths.append(Vector3(p.x, deep, p.y))
	return [root, mouths]


# --- action helpers ----------------------------------------------------------


## A new action: the last one's stopped (its awaits see it), the pose back to rest.
func _begin() -> int:
	_act += 1
	if _mate_role != "":
		_mate_end()
	for k in POSE:
		if k in ["buzz", "wing_open", "hold"]:
			continue
		_p[k] = POSE[k]
	_walk_target = Vector3.INF
	_turning = false
	_land_plane = false
	_sway_k = 0.0 # (it eases out: _sway)
	_weave = 0.0
	_jitter = 0.002
	_look = Vector3.ZERO
	return _act


func _wait(id: int, secs: float) -> bool:
	var t := 0.0
	while t < secs:
		await get_tree().process_frame
		if id != _act:
			return false
		t += get_process_delta_time()
	return true


## Till cond's true (or a while: on anyway). False if the action's been stopped.
func _until(id: int, cond: Callable, most := 8.0) -> bool:
	var t := 0.0
	while not cond.call() and t < most:
		await get_tree().process_frame
		if id != _act:
			return false
		t += get_process_delta_time()
	return id == _act


## On a surface: turning on the spot to face dir.
func _turn(id: int, dir: Vector3) -> bool:
	_turn_to = dir
	_turning = true
	var ok := await _until(id, func() -> bool: return not _turning, 3.0)
	_turning = false
	return ok


## Up off the surface it's on (if it is).
func _take_off(id: int) -> bool:
	_p.buzz = 1.0
	_p.wing_open = 1.0
	if not flying:
		_p.crouch = 0.0
		_p.buzz = 0.0
		if not await _wait(id, 0.12):
			return false
		_p.buzz = 1.0
		if not await _wait(id, 0.08):
			return false
		flying = true
		_land_plane = false
		_ground_w = 1.0
		_pos = global_position
		_vel = surface_n * 0.15
		_fly_target = _pos + surface_n * 0.025
		_max_speed = 0.4
		if not await _wait(id, 0.15):
			return false
	return true


## Flying to over at, facing face, letting itself down onto the surface
## there (normal), its legs reaching for it, and standing: wings folded.
## down: how fast it lets down (m/s).
func _touch_down(id: int, at: Vector3, normal: Vector3, face: Vector3, down := 0.06) -> bool:
	surface_p = at
	surface_n = normal
	_land_plane = true
	var hover := at + normal * 0.045
	_look = face
	_max_speed = 0.9
	_fly_target = hover
	if not await _until(id, func() -> bool: return _pos.distance_to(hover) < 0.006, 8.0):
		return false
	if not await _wait(id, rng.randf_range(0.25, 0.6) if down < 0.2 else 0.05):
		return false
	_max_speed = down
	var low := at + normal * (BODY_H + 0.3) * MM
	_fly_target = low
	if not await _until(id, func() -> bool: return _pos.distance_to(low) < 0.0008, 4.0):
		return false
	# down
	flying = false
	_land_plane = false
	_pos -= normal * (_pos - at).dot(normal)
	_heading = _flat(_heading, normal)
	_vel = Vector3.ZERO
	for i in 6:
		var f := _feet_drawn[i]
		_feet[i] = f - normal * (f - at).dot(normal)
		_feet_now[i] = _feet[i]
	_swinging = -1
	if not await _wait(id, 0.15):
		return false
	_p.buzz = 0.0
	_p.wing_open = 0.0
	return await _wait(id, 0.2)


## A point round the origin on a plane of normal n, within r (or its
## direction, r 1: a random way along it).
func _in_plane(n: Vector3, r: float) -> Vector3:
	var u := n.cross(Vector3.RIGHT if absf(n.x) < 0.9 else Vector3.FORWARD).normalized()
	var v := n.cross(u)
	var a := rng.randf() * TAU
	return (u * cos(a) + v * sin(a)) * r * (sqrt(rng.randf()) if r < 1.0 else 1.0)


## The way from where it is toward p, across the ground.
func _away(p: Vector3) -> Vector3:
	var d := p - _pos
	d.y = 0.0
	return d.normalized() if d.length() > 0.005 else _heading


static func _flat(v: Vector3, n: Vector3) -> Vector3:
	var f := v - n * v.dot(n)
	return f.normalized() if f.length() > 1e-5 else n.cross(Vector3.RIGHT).normalized()


## A basis facing fwd (-z), its up up.
static func _frame(up: Vector3, fwd: Vector3) -> Basis:
	var right := fwd.cross(up).normalized()
	var u := right.cross(fwd).normalized()
	return Basis(right, u, -fwd.normalized())


static func _turned(from: Vector3, to: Vector3, most: float, axis: Vector3) -> Vector3:
	var a := from.signed_angle_to(to, axis)
	return from.rotated(axis, clampf(a, -most, most))


# --- the motor ----------------------------------------------------------------


func _process(dt: float) -> void:
	if dt <= 0.0:
		return
	_t += dt
	if _pilot:
		_pilot.tick(dt)
	for k in _p:
		_a[k] = lerpf(_a[k], _p[k], 1.0 - exp(-RATES.get(k, 10.0) * dt))
	if _riding:
		_ride(dt)
		_pose(dt)
		return
	if flying:
		_fly(dt)
	else:
		_walk(dt)
		_gait(dt)
	_place(dt)
	_pose(dt)
	_sway(dt)


func _fly(dt: float) -> void:
	_ground_w = move_toward(_ground_w, 0.0, dt / 0.25)
	var to := _fly_target - _pos
	var want := to * 3.5
	if want.length() > _max_speed:
		want = want.normalized() * _max_speed
	var right := _heading.cross(Vector3.UP).normalized()
	want += right * sin(_t * 5.3) * _weave + Vector3.UP * sin(_t * 3.1 + 1.0) * _weave * 0.3
	_acc = ((want - _vel) * 7.0).limit_length(9.0)
	_vel += _acc * dt
	_pos += _vel * dt
	var hv := Vector3(_vel.x, 0.0, _vel.z)
	var face := _heading
	if hv.length() > 0.12:
		face = hv.normalized()
	elif _look != Vector3.ZERO and Vector2(_look.x, _look.z).length() > 1e-4:
		face = Vector3(_look.x, 0.0, _look.z).normalized()
	_heading = _turned(_heading, face, 7.0 * dt, Vector3.UP)


func _walk(dt: float) -> void:
	var n := surface_n
	var fwd := _flat(_heading, n)
	var want := fwd
	_speed = 0.0
	if _walk_target != Vector3.INF:
		var to := _walk_target - _pos
		to -= n * to.dot(n)
		if to.length() > 0.0015:
			want = to.normalized()
			_speed = minf(_walk_speed, to.length() * 4.0) * clampf(1.0 - fwd.angle_to(want) / 1.2, 0.0, 1.0)
		else:
			_walk_target = Vector3.INF
	elif _turning:
		want = _flat(_turn_to, n)
		if fwd.angle_to(want) < 0.08:
			_turning = false
	_heading = _turned(fwd, want, 4.0 * dt, n)
	_pos += _heading * _speed * dt
	_pos -= n * (_pos - surface_p).dot(n)


## The legs on a surface: a tripod at a time swings to where it'd stand
## (ahead of it, walking), when they've fallen behind.
func _gait(dt: float) -> void:
	var homes := _homes()
	if _swinging < 0:
		var need := [0.0, 0.0]
		for g in 2:
			for i in TRIPOD[g]:
				need[g] = maxf(need[g], _feet[i].distance_to(homes[i]))
		var th := 0.8 * MM
		var g: int = _next_group
		if need[g] < th and need[1 - g] >= th:
			g = 1 - g
		if need[g] >= th:
			_swinging = g
			_swing_t = 0.0
			for i in TRIPOD[g]:
				_swing_from[i] = _feet[i]
	if _swinging >= 0:
		_swing_t += dt / STEP_TIME
		var u := minf(_swing_t, 1.0)
		var ahead := _heading * _speed * STEP_TIME * 1.5
		for i in TRIPOD[_swinging]:
			_feet_now[i] = _swing_from[i].lerp(homes[i] + ahead, smoothstep(0.0, 1.0, u)) + surface_n * sin(PI * u) * 0.9 * MM
		if u >= 1.0:
			for i in TRIPOD[_swinging]:
				_feet[i] = homes[i] + ahead
				_feet_now[i] = _feet[i]
			_next_group = 1 - _swinging
			_swinging = -1
	for g in 2:
		if g != _swinging:
			for i in TRIPOD[g]:
				_feet_now[i] = _feet[i]


## Where each foot would stand, as it stands now (world).
func _homes() -> Array[Vector3]:
	var b := _frame(surface_n, _flat(_heading, surface_n))
	var out: Array[Vector3] = []
	var spread: float = 1.0 + 0.12 * _a.crouch
	for i in 6:
		var L: Dictionary = LEGS[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var h: Vector2 = L.home
		out.append(_pos + (b.x * h.x * side * spread + b.z * h.y) * MM)
	return out


## The wasp where it is, turned as it's going.
func _place(dt: float) -> void:
	var b: Basis
	var o: Vector3
	if flying:
		var hs := Vector2(_vel.x, _vel.z).length()
		var pitch := lerpf(_a.hover_pitch, 0.1, clampf(hs / 0.8, 0.0, 1.0))
		var right := _heading.cross(Vector3.UP).normalized()
		var roll := clampf(-_acc.dot(right) * 0.06, -0.6, 0.6)
		b = _frame(Vector3.UP, _heading) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, roll)
		var j := Vector3(sin(_t * 13.1) + sin(_t * 7.7 + 1.0), sin(_t * 11.3 + 2.0) + sin(_t * 5.9), sin(_t * 9.7 + 3.0) + sin(_t * 6.3 + 0.5))
		o = _pos + j * 0.5 * _jitter
	else:
		b = _frame(surface_n, _flat(_heading, surface_n)) * Basis(Vector3.RIGHT, 0.12 + _a.lift_pitch)
		o = _pos + surface_n * (BODY_H + 1.2 * _a.rise - 0.45 * _a.crouch) * MM
		o = global_position.lerp(o, 1.0 - exp(-25.0 * dt)) if global_position.distance_to(o) < 0.01 else o
	var q := global_basis.get_rotation_quaternion().slerp(b.get_rotation_quaternion(), 1.0 - exp(-14.0 * dt))
	global_transform = Transform3D(Basis(q), o)


## The wasp's shaders told how much to sway with the flower's head: all of
## it at the head, none from a hand's breadth off; easing in and out.
func _sway(dt: float) -> void:
	var want := 0.0
	if _sway_k > 0.0:
		want = 1.0 - smoothstep(0.04, 0.25, global_position.distance_to(_sway_at))
	_sway_w = move_toward(_sway_w, want, dt / 0.4)
	var k := _sway_k * _sway_w
	if k == _sway_set.w and _sway_at == Vector3(_sway_set.x, _sway_set.y, _sway_set.z):
		return
	_sway_set = Vector4(_sway_at.x, _sway_at.y, _sway_at.z, k)
	for m in _mats:
		m.set_shader_parameter("sway_at", _sway_at)
		m.set_shader_parameter("sway_k", k)


# --- the pose -------------------------------------------------------------------


func _pose(dt: float) -> void:
	# head and mandibles
	var bob: float = 0.06 * _a.chew * sin(_t * TAU * 2.2) + 0.04 * _a.lap * sin(_t * TAU * 3.0)
	_head.rotation = Vector3(_a.head_pitch + bob, _a.head_yaw, 0.0)
	var open := maxf(_a.mandibles, maxf(_a.chew * (0.5 + 0.5 * sin(_t * TAU * 4.5)), _a.lap * (0.15 + 0.15 * sin(_t * TAU * 3.0))))
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		_mandibles[s].rotation.y = side * lerpf(0.6, -0.15, open)
	_pose_antennae(dt)
	_pose_gaster()
	_pose_legs()
	_pose_wings()
	_pose_prey(dt)


func _pose_antennae(dt: float) -> void:
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		_tw_wait[s] -= dt
		if _tw_wait[s] <= 0.0:
			_tw_wait[s] = rng.randf_range(0.2, 1.4)
			_tw_to[s] = Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.3, 0.3))
		_tw[s] = (_tw[s] as Vector2).lerp(_tw_to[s], 1.0 - exp(-12.0 * dt))
		var tw: Vector2 = _tw[s]
		var tap: float = _a.ant_tap * (0.5 + 0.5 * sin(_t * 9.0 + s * 2.1))
		var yaw: float = _a.ant_spread + tw.x
		var pitch: float = _a.ant_pitch + tw.y - tap * 0.6
		# grooming: the one being cleaned pulled down to the leg
		var gw: float = _a.groom * (1.0 if side == _groom_side else 0.0)
		pitch = lerpf(pitch, -0.5, gw)
		yaw = lerpf(yaw, 0.6, gw)
		var segs: Array = _antennae[s]
		var base := Vector3(0.45 * side, 0.45, -1.75)
		var d := _dir(yaw, pitch, side)
		var p := _over(base, base + d * 1.3, 1.3)
		_seg(segs[0], base, p, 0.13)
		# the flagellum, elbowed down from the scape and curling (along the
		# surface, where it'd go into it)
		var fy := yaw + 0.25
		var fp: float = pitch - 0.9 - _a.ant_down
		for k in 4:
			var q := _over(p, p + _dir(fy, fp, side) * 1.2, 1.2)
			_seg(segs[k + 1], p, q, 0.12 if k < 3 else 0.14)
			p = q
			fp -= 0.12 + 0.15 * gw


## An antenna's next joint q (the head's own space, len on from p): if
## it'd be in the surface it stands on (or is coming down on), laid along it
## instead.
func _over(p: Vector3, q: Vector3, len: float) -> Vector3:
	if flying and not _land_plane:
		return q
	var w := _head.to_global(q)
	var h := (w - surface_p).dot(surface_n) - 0.2 * MM
	if h >= 0.0:
		return q
	q = _head.to_local(w - surface_n * h)
	q = p + (q - p).normalized() * len
	# (the length kept, it can dip again: on the surface then, a little short)
	w = _head.to_global(q)
	h = (w - surface_p).dot(surface_n) - 0.2 * MM
	return _head.to_local(w - surface_n * h) if h < 0.0 else q


static func _dir(yaw: float, pitch: float, side: float) -> Vector3:
	return Vector3(sin(yaw) * side * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))


func _pose_gaster() -> void:
	var pump: float = _a.pump * sin(_t * TAU * 1.2)
	var hang := 0.12 if flying else 0.0
	var twist := 0.3 * _ride_k if _riding else 0.0 # (his, round under the tip of hers)
	for i in GASTER.size():
		var ang: float = GASTER_DROOP[i] + _a.curl * GASTER_CURL[i] + (hang if i == 0 else 0.0) + pump * 0.02
		_gaster[i].rotation = Vector3(ang, twist if i < 2 else 0.0, 0.0)
		var g: Array = GASTER[i]
		_gaster_mesh[i].scale = Vector3(g[1] * 2.0, g[2] * 2.0 * (1.0 + pump * 0.04), g[0] * 1.4 * (1.0 + pump * 0.05))
	var out: float = _a.sting_out
	_sting.visible = out > 0.02
	_sting.scale = Vector3(1.0, 1.0, maxf(out, 0.01))


func _pose_legs() -> void:
	var inv := _body.global_transform.affine_inverse()
	var up_l := (inv.basis * surface_n).normalized()
	var plane_l := inv * surface_p
	var plane_on := not flying or _land_plane
	var reach := 0.0
	var homes: Array[Vector3] = []
	if flying and _land_plane:
		var hgt := (_pos - surface_p).dot(surface_n) / MM - BODY_H
		reach = clampf(1.0 - hgt / 10.0, 0.0, 1.0)
		var save := _pos
		_pos = _pos - surface_n * (_pos - surface_p).dot(surface_n)
		homes = _homes()
		_pos = save
	for i in 6:
		var pair := i / 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var L: Dictionary = LEGS[pair]
		var hip0 := Vector3(L.hip.x * side, L.hip.y, L.hip.z)
		var hip := hip0 + Vector3(0.4 * side, -0.35, 0.0)
		var ankle: Vector3
		var foot: Vector3
		if flying:
			var sway := Vector3(sin(_t * 2.1 + i) * 0.15, sin(_t * 1.7 + i * 0.7) * 0.2, 0.0)
			ankle = Vector3(L.dangle.x * side, L.dangle.y, L.dangle.z) + sway
			foot = ankle + Vector3(L.hang.x * side, L.hang.y, L.hang.z).normalized() * L.s
			if reach > 0.0:
				var f := inv * homes[i]
				foot = foot.lerp(f, reach)
				ankle = ankle.lerp(_ankle(hip, f, L.s, up_l), reach)
			if _ground_w > 0.0:
				var f := inv * _feet[i]
				foot = foot.lerp(f, _ground_w)
				ankle = ankle.lerp(_ankle(hip, f, L.s, up_l), _ground_w)
		else:
			foot = inv * _feet_now[i]
			ankle = _ankle(hip, foot, L.s, up_l)
		# the front legs: holding the prey, or cleaning an antenna
		if pair == 0 and _a.hold > 0.01 and _holding:
			var f := _body.to_local(_holding.global_position) + Vector3(0.9 * side, -0.1, 0.5)
			foot = foot.lerp(f, _a.hold)
			ankle = ankle.lerp(f + Vector3(0.7 * side, 0.6, 1.3).normalized() * L.s, _a.hold)
		if pair == 0 and _a.groom > 0.01 and side == _groom_side:
			var u := 0.5 + 0.5 * sin(_t * TAU * 1.4)
			var segs: Array = _antennae[1 if side > 0.0 else 0]
			var a0 := _body.to_local((segs[1] as Node3D).global_position)
			var a1 := _body.to_local((segs[4] as Node3D).global_position)
			var f := a0.lerp(a1, u)
			foot = foot.lerp(f, _a.groom)
			ankle = ankle.lerp(f + Vector3(0.5 * side, -0.8, 1.0).normalized() * L.s, _a.groom)
		# the knee up, and out the way the leg goes (in its own plane)
		var up := up_l if plane_on else Vector3.UP
		var out := ankle - hip
		out -= up * out.dot(up)
		out = out.normalized() if out.length() > 1e-4 else Vector3(side, 0.0, 0.0)
		var knee := _knee(hip, ankle, L.f, L.t, up + out * 0.6)
		# none of it through the surface
		if plane_on:
			foot = _above(foot, plane_l, up_l, 0.12)
			ankle = _above(ankle, plane_l, up_l, 0.25)
			knee = _above(knee, plane_l, up_l, 0.35)
		var parts: Array = _legs[i]
		_seg(parts[0], hip0, hip, 0.36)
		_seg(parts[1], hip, knee, 0.27)
		_seg(parts[2], knee, ankle, 0.19)
		_seg(parts[3], ankle, foot, 0.13)
		(parts[4] as Node3D).position = foot
		_feet_drawn[i] = _body.to_global(foot)


## The ankle over a foot: the tarsus lying back from it toward the hip,
## mostly along the surface, up a little.
static func _ankle(hip: Vector3, foot: Vector3, s: float, up: Vector3) -> Vector3:
	var out := foot - hip
	out -= up * out.dot(up)
	out = out.normalized() if out.length() > 1e-4 else Vector3.FORWARD
	return foot + (-out * 0.9 + up * 0.42) * s


## p (the body's own space) kept at least margin (model mm) over the plane
## through on, of normal n.
static func _above(p: Vector3, on: Vector3, n: Vector3, margin: float) -> Vector3:
	var h := (p - on).dot(n) - margin
	return p - n * h if h < 0.0 else p


## The knee between hip and ankle (femur f, tibia t), bending toward pole.
static func _knee(hip: Vector3, ankle: Vector3, f: float, t: float, pole: Vector3) -> Vector3:
	var d := ankle - hip
	var l := clampf(d.length(), absf(f - t) + 0.01, f + t - 0.01)
	var dir := d.normalized() if d.length() > 1e-4 else Vector3.DOWN
	var a := (f * f - t * t + l * l) / (2.0 * l)
	var h := sqrt(maxf(f * f - a * a, 0.0))
	var p := pole - dir * pole.dot(dir)
	p = p.normalized() if p.length() > 1e-4 else Vector3.UP
	return hip + dir * a + p * h


func _pose_wings() -> void:
	var buzzing: bool = _a.buzz > 0.5
	var plane := Basis(Vector3.RIGHT, -0.35) # (the stroke: level, the body nose up hovering)
	var ph := rng.randf() # (where in the beat this frame catches them)
	for k in 4:
		var W: Dictionary = WINGS[k / 2]
		var side := 1.0 if k % 2 == 1 else -1.0
		var sweep: float
		var elev: float
		var b := Basis()
		if buzzing:
			b = plane
			sweep = lerpf(STROKE.x, STROKE.y, ph)
			elev = 0.15 * sin(ph * PI)
		else:
			var fold: Vector2 = W.fold
			var raise: Vector2 = W.raise
			sweep = lerpf(fold.x, raise.x, _a.wing_open)
			elev = lerpf(fold.y, raise.y, _a.wing_open)
		var s := b * Vector3(cos(sweep) * cos(elev), sin(elev), sin(sweep) * cos(elev))
		var t := b * Vector3(-sin(sweep), 0.0, cos(sweep))
		s.x *= side
		t.x *= side
		var n := s.cross(t).normalized()
		var hinge := Vector3(W.hinge.x * side, W.hinge.y, W.hinge.z)
		_wings[k].transform = Transform3D(Basis(s * W.l, n, t * W.c), hinge - t * W.c * 0.25)
	_wing_mat.set_shader_parameter("opacity", 0.35 if buzzing else 1.0)
	_hind_mat.set_shader_parameter("opacity", 0.35 if buzzing else 1.0)
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		_fans[s].visible = buzzing
		var W: Dictionary = WINGS[0]
		_fans[s].transform = Transform3D(plane * Basis.from_scale(Vector3(W.l * side, 1.0, W.l)), Vector3(W.hinge.x * side, W.hinge.y, W.hinge.z))


func _pose_prey(dt: float) -> void:
	if _holding == null:
		return
	_hold_t = minf(_hold_t + dt / 0.25, 1.0)
	_prey_ball = minf(_prey_ball + dt * 0.03 * _a.chew, 1.0)
	_prey_roll += dt * _a.chew * (1.5 + 2.0 * maxf(sin(_t * 3.0), 0.0))
	var at := _head.to_global(Vector3(0.0, -1.7, -2.3))
	var long := lerpf(1.0, 0.28, _prey_ball)
	var wide := lerpf(1.0, 1.25, _prey_ball)
	var b := global_basis * Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.BACK, _prey_roll)
	b = b * Basis.from_scale(Vector3(wide, wide, long))
	var held := Transform3D(b, at)
	_holding.global_transform = _hold_from.interpolate_with(held, smoothstep(0.0, 1.0, _hold_t))


# --- the parts ------------------------------------------------------------------


## A part (a unit sphere or cylinder) spanning a to b, radius r.
static func _seg(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var d := b - a
	if d.length() < 1e-4:
		d = Vector3.UP * 1e-4
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD) if absf(y.z) < 0.9 else y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y)
	mi.transform = Transform3D(Basis(x * 2.0 * r, d, z * 2.0 * r), (a + b) * 0.5)


## Its colours (a species reusing the model says its own): its body, its
## darker parts, its marks (the gaster's bands too), its legs (femora,
## tibiae and tarsi), its antennae's tips, its mandibles, its wings'
## membrane and veins; the gaster's bands, each segment's share (0 none).
func _palette() -> Dictionary:
	return {"body": BROWN, "dark": DARK, "mark": YELLOW, "leg": LEG_BROWN, "leg2": LEG_YELLOW, "tip": TIP_ORANGE,
		"mandible": Color(0.6, 0.38, 0.12), "membrane": Color(0.5, 0.36, 0.2), "vein": Color(0.22, 0.13, 0.06),
		"bands": [0.16, 0.16, 0.16, 0.16, 0.16, 0.0], "antenna": DARK}


func _chitin(c: Color, band := 0.0, gloss := 0.65) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/render/wasp_chitin.gdshader")
	m.set_shader_parameter("base_color", c)
	m.set_shader_parameter("band_color", _pal.get("mark", YELLOW))
	m.set_shader_parameter("band", band)
	m.set_shader_parameter("gloss", gloss)
	_mats.append(m)
	return m


func _ball(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	mi.position = at
	mi.scale = size
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _stick(parent: Node3D, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _cyl
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _build() -> void:
	_sphere = SphereMesh.new()
	_sphere.radius = 0.5
	_sphere.height = 1.0
	_sphere.radial_segments = 14
	_sphere.rings = 8
	_cyl = CylinderMesh.new()
	_cyl.top_radius = 0.5
	_cyl.bottom_radius = 0.5
	_cyl.height = 1.0
	_cyl.radial_segments = 6
	_cyl.rings = 1
	_body = Node3D.new()
	_body.scale = Vector3.ONE * MM
	add_child(_body)
	_pal = _palette()
	var BODY: Color = _pal.body
	var brown := _chitin(BODY)
	var dark := _chitin(_pal.dark)
	var yellow := _chitin(_pal.mark)
	var eye := _chitin(Color(0.05, 0.035, 0.03), 0.0, 1.0)
	var leg_brown := _chitin(_pal.leg, 0.0, 0.5)
	var leg_yellow := _chitin(_pal.leg2, 0.0, 0.5)
	var tip := _chitin(_pal.tip, 0.0, 0.4)
	var ant := _chitin(_pal.antenna)
	# the thorax (mesosoma): its marks yellow
	_ball(_body, Vector3.ZERO, Vector3(2.8, 2.9, 4.6), brown)
	_ball(_body, Vector3(0.0, 0.2, -1.75), Vector3(2.9, 2.5, 0.9), _chitin(BODY, 0.25)) # (the collar, its hind edge yellow)
	_ball(_body, Vector3(0.0, 1.3, 1.1), Vector3(1.1, 0.5, 0.7), yellow) # (the scutellum)
	_ball(_body, Vector3(0.0, -0.1, 1.9), Vector3(2.0, 2.2, 1.4), dark) # (the propodeum)
	_ball(_body, Vector3(0.0, 0.25, -2.2), Vector3(1.0, 1.0, 0.8), dark) # (the neck)
	for side: float in [-1.0, 1.0]:
		_ball(_body, Vector3(0.95 * side, 1.15, -0.75), Vector3(0.5, 0.35, 0.6), yellow) # (the tegulae, over the wings' hinges)
	# the head
	_head = Node3D.new()
	_head.position = HEAD_AT
	_body.add_child(_head)
	_ball(_head, Vector3(0.0, 0.0, -1.0), Vector3(3.3, 2.9, 1.9), brown)
	_ball(_head, Vector3(0.0, -0.75, -1.85), Vector3(1.3, 1.0, 0.5), yellow) # (the clypeus)
	_ball(_head, Vector3(0.0, 0.6, -1.85), Vector3(0.9, 0.5, 0.3), yellow) # (between the antennae)
	for side: float in [-1.0, 1.0]:
		_ball(_head, Vector3(1.25 * side, 0.15, -1.15), Vector3(0.9, 2.3, 1.4), eye)
		var piv := Node3D.new()
		piv.position = Vector3(0.45 * side, -1.2, -1.75)
		_head.add_child(piv)
		_ball(piv, Vector3(0.0, 0.0, -0.45), Vector3(0.38, 0.3, 0.95), _chitin(_pal.mandible))
		_mandibles.append(piv)
		var segs := []
		for k in 5:
			segs.append(_stick(_head, tip if k == 4 else (ant if k > 0 else brown)))
		_antennae.append(segs)
	# the gaster: a chain of segments, each banded yellow behind
	var bands: Array = _pal.bands
	var parent := _body
	var at := GASTER_AT
	for i in GASTER.size():
		var g: Array = GASTER[i]
		var piv := Node3D.new()
		piv.position = at
		parent.add_child(piv)
		_gaster.append(piv)
		_gaster_mesh.append(_ball(piv, Vector3(0.0, 0.0, g[0] * 0.5), Vector3(g[1] * 2.0, g[2] * 2.0, g[0] * 1.4), _chitin(BODY, float(bands[i]))))
		parent = piv
		at = Vector3(0.0, 0.0, g[0])
	# the stinger: grows out of the tip (its holder scaled along it by sting_out)
	_sting = Node3D.new()
	_sting.position = Vector3(0.0, -0.1, GASTER[GASTER.size() - 1][0] * 0.95)
	parent.add_child(_sting)
	var stinger := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.12
	cone.height = 1.4
	cone.radial_segments = 5
	cone.rings = 1
	stinger.mesh = cone
	stinger.material_override = dark
	stinger.rotation = Vector3(PI * 0.5, 0.0, 0.0) # (along +z, from 0 to 1.4)
	stinger.position = Vector3(0.0, 0.0, 0.7)
	_sting.add_child(stinger)
	_sting.visible = false
	# the legs: coxa, femur, tibia, tarsus, claw
	for i in 6:
		var pair := i / 2
		var parts := [_stick(_body, dark), _stick(_body, leg_brown if pair < 2 else dark), _stick(_body, leg_yellow), _stick(_body, leg_yellow)]
		parts.append(_ball(_body, Vector3.ZERO, Vector3(0.25, 0.2, 0.25), dark))
		_legs.append(parts)
	# the wings, and the blur of their beat
	_wing_mat = ShaderMaterial.new()
	_wing_mat.shader = preload("res://shaders/render/wasp_wing.gdshader")
	_wing_mat.set_shader_parameter("membrane", _pal.membrane)
	_wing_mat.set_shader_parameter("vein", _pal.vein)
	_hind_mat = _wing_mat.duplicate()
	_mats.append(_wing_mat)
	_mats.append(_hind_mat)
	var quad := _wing_quad()
	for k in 4:
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = _wing_mat if k < 2 else _hind_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_body.add_child(mi)
		_wings.append(mi)
	var fan_mat := _wing_mat.duplicate() as ShaderMaterial
	fan_mat.set_shader_parameter("blur", true)
	_mats.append(fan_mat)
	var fan := _fan_mesh()
	for s in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = fan
		mi.material_override = fan_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_body.add_child(mi)
		_fans.append(mi)


## A wing's quad: x along it 0..1, z across it 0..1 (UV the same).
static func _wing_quad() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
		st.set_normal(Vector3.UP)
		st.set_uv(v)
		st.add_vertex(Vector3(v.x, 0.0, v.y))
	return st.commit()


## The beat's blur: a fan round the hinge, out to 1, across the stroke.
static func _fan_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const N := 16
	for k in N:
		var corners := []
		for e in [[k, 0.1], [k + 1, 0.1], [k + 1, 1.0], [k, 0.1], [k + 1, 1.0], [k, 1.0]]:
			var u := float(e[0]) / N
			var a := lerpf(STROKE.x, STROKE.y, u)
			var r: float = e[1]
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(r, u))
			st.add_vertex(Vector3(cos(a), 0.0, sin(a)) * r)
	return st.commit()
