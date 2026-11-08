class_name Beaver
extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## A North American beaver (Castor canadensis), life size (about 80 cm head
## and body, its tail 30 cm more), on the four-legged make (Carnivore: its
## legs plantigrade, a bear's, its gait a waddle) and one skin: heavy, humped,
## pear shaped, broadest at its hips; a broad blunt head, small eyes, small
## round ears, its great orange incisors; short forelegs with clawed hands;
## big webbed hind feet; its tail a broad flat scaly paddle. Its coat
## (carnivore.gdshader's species 11): rich dark brown, glossy, its belly a
## little paler; its feet and tail bare, black, the tail scaled. Its kits
## (Beaver.new(true)): born furred, their eyes open, swimming in a day.
##
## It lives in and by its water (wet: where the water is; water_y: its
## surface): on land a slow humped waddle; in the water it floats low, its
## head and back showing, its hind feet paddling by turns, its forefeet
## tucked to its chest, its tail trailing.
## - wander(centre, radius): about on the bank, nose down, sniffing
## - swim(centre, radius): about in its water
## - slap(): its alarm: its tail raised and slapped down on the water, a
##   splash, and down under; up again a little way off
## - fell(sapling) (Beaver.sapling()): to it, sat up on its tail, gnawing
##   round the trunk, its head swinging, chips flying; the tree falls; a
##   length gnawed off it, carried in its jaws to the water and swum out to
##   its lodge (lodge: Beaver.lodge_of()'s), laid on it
## - eat(stick): sat up, a stick held across in its forepaws at its mouth,
##   turned as it gnaws the bark off, like corn on the cob; the stick left
##   peeled white
## - groom(): sat up on its tail, combing its belly and face with its
##   forepaws, its flank with a hind foot's split claw
## - mark(): mud plastered on its lodge (or a scent mound on the bank):
##   scooped up against its chest with its forepaws, pushed on
## - birth(n): (a female's) at her lodge, her kits born; they follow her,
##   on land and in the water; nurse(): hers
## - mate(her): in the water, his the base's way
## Steering (pilot.gd): act swim {centre, radius}, slap, fell {sapling},
## eat {stick}, groom, mark, birth {n}, nurse, mate {partner}.

const SPEC := {
	"species": 11, "plantigrade": true, "sole_hind": 1.9, "boxy": 2.1,
	"body": [[-300.0, 10.0, 90.0, 85.0], [-230.0, 0.0, 125.0, 118.0], [-100.0, -5.0, 150.0, 138.0], [50.0, 0.0, 168.0, 152.0],
			[170.0, 5.0, 165.0, 145.0], [250.0, 10.0, 122.0, 108.0], [300.0, 15.0, 62.0, 56.0]],
	"body_h": 190.0, "body_len": 600.0, "body_w": 165.0,
	"neck_at": Vector3(0.0, 30.0, -280.0), "neck": [[40.0, 0.0, 95.0, 92.0], [-30.0, 0.0, 86.0, 82.0], [-80.0, 0.0, 80.0, 76.0]], "neck_pitch": 0.12,
	"head_at": Vector3(0.0, 0.0, -90.0),
	"head": [[50.0, 0.0, 80.0, 75.0], [-10.0, 10.0, 86.0, 78.0], [-60.0, 5.0, 76.0, 66.0], [-110.0, -10.0, 56.0, 50.0], [-140.0, -18.0, 40.0, 38.0], [-152.0, -20.0, 22.0, 22.0]],
	"jaw_at": Vector3(0.0, -59.7, -58.0), "jaw": [[0.0, 0.0, 42.6, 19.4], [-37.5, 4.0, 47.6, 19.3], [-75.0, 18.2, 25.7, 12.2]], "mouth": 1.0,
	"mouth_z": -420.0,
	"eye": {"at": Vector3(52.0, 26.0, -52.0), "size": Vector3(14.0, 13.0, 15.0), "color": Color(0.03, 0.025, 0.02), "slit": 0.9},
	"nose": {"at": Vector3(0.0, -12.0, -150.0), "size": Vector3(42.0, 26.0, 22.0), "color": Color(0.05, 0.045, 0.04)},
	"whisker": 65.0,
	"ear": {"at": Vector3(58.0, 52.0, 14.0), "len": 30.0, "width": 34.0, "point": 0.3, "tilt_back": 0.35, "spread": 0.45},
	"tail": {"base": Vector3(0.0, 0.0, 295.0), "n": 5, "seg": 64.0, "radii": [44.0, 66.0, 80.0, 82.0, 66.0], "carry": [0.32, 0.04], "wrap": 0.1, "flat": 0.2},
	"fore": {"hip": Vector3(85.0, -60.0, -180.0), "a": 70.0, "b": 72.0, "m": 42.0, "p": 46.0, "home": Vector2(100.0, -200.0), "r": 27.0},
	"hind": {"hip": Vector3(95.0, -30.0, 180.0), "a": 95.0, "b": 98.0, "m": 70.0, "p": 82.0, "home": Vector2(118.0, 175.0), "r": 37.0},
	"fur": 25.0, "tail_fur": 0.0,
	"walk": 0.55, "trot": 1.1, "run": 2.0,
	"stalk_from": 3.0, "spring": 1.0, "stalk_crouch": 0.0, "stalk_neck": 0.0, "eat_crouch": 0.2,
	"sit_drop": 60.0, "sit_pitch": 0.95, "lie_h": 120.0,
	"mate_secs": 6.0,
	# its head sculpted (SculptHead), from photographs: broad and round, blunt; its eyes small, set high; its muzzle deep, the whisker pads full; its nose broad, dark
	"sculpt": {
		"z": [50.0, 25.0, 0.0, -25.0, -50.0, -75.0, -95.0, -112.0, -128.0, -142.0, -154.0],
		"top": [50.0, 74.0, 80.0, 80.0, 74.0, 64.0, 54.0, 44.0, 34.0, 22.0, 8.0],
		"bot": [-50.0, -68.0, -74.0, -74.0, -70.0, -62.0, -54.0, -46.0, -40.0, -34.0, -26.0],
		"w": [64.0, 82.0, 86.0, 84.0, 78.0, 68.0, 58.0, 50.0, 42.0, 32.0, 18.0],
		"wl": [68.0, 86.0, 90.0, 88.0, 82.0, 72.0, 62.0, 54.0, 46.0, 34.0, 18.0],
		"pw": [2.0, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.6, 2.5, 2.2],
		"eye": Vector3(40.0, 34.0, -56.0), "eye_r": 7.5, "socket": 0.8, "lid": 1.0,
		"brow": 2.0, "cheek": 3.0, "stop": 1.0, "pads": 3.4, "flews": 0.80, "nose_r": 15.0,
		"almond": 0.78, "slant": 0.00, "look_fwd": 0.60, "pupil": Vector2(0.60, 0.60),
	},
}

var wet: Callable ## (x, z) -> whether it's water there (its pond)
var water_y := 0.0 ## its water's surface (m)
var lodge: Node3D ## its lodge (Beaver.lodge_of()), if it has one
var _in_water := false
var _dive := 0.0 # (how far under, 0..1)
var _dive_to := 0.0
var _paddle := 0.0
var _slap := 0.0 # (the tail: -1 raised .. 1 slapped down)
var _tree: Node3D
var _branch: Node3D
var _splash: Array[MeshInstance3D] = []
var _chips: Array[MeshInstance3D] = []
var _held_stick := false
var _gnaw_pitch := -0.6 # (its neck's pitch, gnawing a stick where it lies)


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.2 if young_ else 0.5)
	_setup()


func _male_size() -> float:
	return 1.0 # (the two alike)


func _build_extra() -> void:
	# its incisors: great, orange, chisel edged
	var tooth := _mat(Color(0.85, 0.42, 0.12), 0.3)
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(6.5 * side, -26.0, -138.0), Vector3(7.0 * side, -62.0, -142.0), 6.5, tooth, _head) # (the upper, out from under its lip)
		var jf: Array = (S.jaw as Array)[(S.jaw as Array).size() - 1]
		_stick(Vector3(5.5 * side, float(jf[1]) - 2.0, float(jf[0]) + 8.0), Vector3(5.5 * side, float(jf[1]) + 16.0, float(jf[0]) + 2.0), 5.0, tooth, _jaw) # (the lower, up behind them)
	# its hands' claws (the forefeet only: the hind's webbed toes bare)
	var claw := _mat(Color(0.12, 0.1, 0.08), 0.35)
	for i in 2:
		var paw := _legx[i][1] as MeshInstance3D
		for k in 5:
			var x := (float(k) - 2.0) * 0.22
			_stick(Vector3(x, -0.2, 0.42), Vector3(x * 1.1, -0.4, 0.62), 0.04, claw, paw)


# --- props -------------------------------------------------------------------------

## A sapling for it to fell (an aspen, 2.5 m, its trunk 6 cm): its origin at
## its foot. It falls as it's felled (Beaver.fell).
static func sapling() -> Node3D:
	var root := Node3D.new()
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.72, 0.72, 0.62)
	bark.roughness = 0.8
	var c := CylinderMesh.new()
	c.top_radius = 0.012
	c.bottom_radius = 0.032
	c.height = 2.5
	c.radial_segments = 10
	var trunk := MeshInstance3D.new()
	trunk.mesh = c
	trunk.position.y = 1.25
	trunk.material_override = bark
	root.add_child(trunk)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.4, 0.55, 0.22)
	leaf.roughness = 0.7
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	for k in 4:
		var crown := MeshInstance3D.new()
		crown.mesh = s
		crown.material_override = leaf
		crown.scale = Vector3(0.6, 0.7, 0.6) * (1.0 - 0.12 * k)
		crown.position = Vector3(0.12 * sin(k * 2.0), 1.7 + 0.25 * k, 0.12 * cos(k * 2.0))
		root.add_child(crown)
	return root


## A stick (a length of aspen, 70 cm, its bark on): its middle at its origin, along x.
static func stick_of(len_ := 0.7) -> Node3D:
	var root := Node3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.014
	c.bottom_radius = 0.016
	c.height = len_
	c.radial_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.rotation.z = PI * 0.5
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.6, 0.6, 0.5)
	bark.roughness = 0.8
	mi.material_override = bark
	root.add_child(mi)
	return root


## Its lodge: a dome of sticks and mud, 2 m across, 0.8 m high over the
## water (its floor's way in under the water): its origin at its middle at
## the water's foot.
## (It sleeps in its lodge, if it has one: in by its way in under the
## water, out of sight.)
func _sleep_home() -> Node3D:
	return lodge


func _home_door(h: Node3D) -> Vector3:
	var out := Vector3(_pos.x - h.global_position.x, 0.0, _pos.z - h.global_position.z)
	out = out.normalized() if out.length() > 1e-3 else Vector3.FORWARD
	return h.global_position + out * 1.05


static func lodge_of() -> Node3D:
	var root := Node3D.new()
	var mud := StandardMaterial3D.new()
	mud.albedo_color = Color(0.25, 0.2, 0.15)
	mud.roughness = 1.0
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 1.6
	s.is_hemisphere = true
	var dome := MeshInstance3D.new()
	dome.mesh = s
	dome.material_override = mud
	dome.scale = Vector3(0.9, 0.88, 0.82) # (under its sticks)
	root.add_child(dome)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	c.radial_segments = 5
	mm.mesh = c
	mm.instance_count = 260
	for i in 260:
		var a := rng.randf() * TAU
		var e := rng.randf_range(0.05, 1.35)
		var n := Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e) * 0.9).normalized()
		var at := Vector3(n.x, n.y * 0.8, n.z) * 1.0
		var t := n.cross(Vector3.UP if absf(n.y) < 0.95 else Vector3.RIGHT).normalized().rotated(n, rng.randf_range(-1.2, 1.2))
		var b := Basis(t.cross(n), t, n).orthonormalized() * Basis.from_scale(Vector3(0.028, rng.randf_range(0.45, 1.3), 0.028))
		mm.set_instance_transform(i, Transform3D(b, at))
		mm.set_instance_color(i, Color(0.42, 0.36, 0.28).darkened(rng.randf_range(0.0, 0.4)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var sm := StandardMaterial3D.new()
	sm.vertex_color_use_as_albedo = true
	sm.roughness = 0.95
	mmi.material_override = sm
	root.add_child(mmi)
	return root


# --- in the water ----------------------------------------------------------------

## The ground under (x, z): in its water, where its body floats (its back
## just showing; under, diving).
func _ground(x: float, z: float) -> float:
	var g := super(x, z)
	if wet.is_valid() and bool(wet.call(x, z)):
		var float_y := water_y - float(S.body_h) * MM * size - 0.35 * 150.0 * MM * size - _dive * 0.3
		return maxf(float_y, g)
	return g


func swim(centre: Vector3, radius: float) -> void:
	_mode = "swim"
	_centre = centre
	_radius = radius
	_wait = 0.0


## (Its alarm: the tail slapped on the water, and under.)
func slap() -> void:
	_mode = "slap"
	_stage = 0
	_st = 0.0


func fell(tree: Node3D) -> void:
	if tree == null or not is_instance_valid(tree):
		return
	_mode = "fell"
	_tree = tree
	_stage = 0
	_st = 0.0


func eat(food: Node3D) -> void:
	if food == null or not is_instance_valid(food):
		return
	_mode = "eat_stick"
	_branch = food
	_stage = 0
	_st = 0.0


func groom() -> void:
	_mode = "groom"
	_st = 0.0


func mark() -> void:
	_mode = "mud"
	_stage = 0
	_st = 0.0


func birth(n := 3, _den: Node3D = null) -> void:
	if young or male:
		return
	_mode = "birth"
	_born_left = n
	home_den = null
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	_in_water = wet.is_valid() and bool(wet.call(_pos.x, _pos.z))
	_dive = move_toward(_dive, _dive_to, dt * 0.8)
	match _mode:
		"swim":
			_common(dt)
			if _wait <= 0.0 or _pos.distance_to(_target) < 0.15:
				for tries in 8:
					var a := rng.randf() * TAU
					var t := _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
					if not wet.is_valid() or bool(wet.call(t.x, t.z)):
						_target = t
						break
				_wait = rng.randf_range(4.0, 8.0)
			_pace = float(S.walk) * 0.8
			return
		"slap":
			_common(dt)
			_slap_dive(dt)
			return
		"fell":
			_common(dt)
			_fell(dt)
			return
		"eat_stick":
			_common(dt)
			_eat_stick(dt)
			return
		"groom":
			_common(dt)
			_target = _pos
			_sit_to = 1.0
			var ph := fmod(_st, 10.0)
			_neck_to = Vector2(-0.5 if ph < 5.0 else 0.0, 0.5 * sin(_st * 0.8) if ph >= 7.0 else 0.0)
			_lick = 0.5
			if _st > 10.0:
				_sit_to = 0.0
				wander(_pos, 0.8)
			return
		"mud":
			_common(dt)
			_mud(dt)
			return
		"birth":
			_common(dt)
			_target = _pos
			_neck_to = Vector2(-0.6, 0.9 * sin(_st * 0.4))
			_lick = 0.8
			if _st > 3.0 and _born_left > 0:
				_born_left -= 1
				_st = 0.0
				_kit()
			if _born_left <= 0 and _st > 3.0:
				wander(_pos, 0.8)
			return
	super(dt)
	if _in_water and _mode in ["wander", "follow"]: # (in the water, as if on land: swimming)
		_pace = float(S.walk) * 0.8


func _common(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	_lick = move_toward(_lick, 0.0, dt * 2.0)
	_ears_to = 0.0
	_jaw_to = 0.0
	_neck_to = Vector2.ZERO
	_tail_mode = "carry"
	_lie_to = 0.0
	if _mode not in ["groom", "fell", "eat_stick"]:
		_sit_to = 0.0
	if _mode not in ["swim", "fell", "slap"]:
		_pace = -1.0


## (To the water if it's out of it; the tail raised high and slapped down,
## a splash; down under; up again.)
func _slap_dive(dt: float) -> void:
	match _stage:
		0:
			if not _in_water:
				_target = _nearest_water()
				_pace = float(S.run)
				if _target == _pos:
					_stage = 1
				return
			_stage = 1
			_st = 0.0
		1: # (the tail up)
			_target = _pos
			_slap = move_toward(_slap, -1.0, dt * 4.0)
			if _st > 0.5:
				_stage = 2
				_st = 0.0
		2: # (and down: crack)
			_slap = move_toward(_slap, 1.0, dt * 14.0)
			if _st > 0.12 and _st - dt <= 0.12:
				_splash_at(_out(Vector3(0.0, 0.0, 450.0)))
			if _st > 0.3:
				_dive_to = 1.0
				_stage = 3
				_st = 0.0
		3: # (under, away)
			_slap = move_toward(_slap, 0.0, dt * 3.0)
			var a := _yaw + PI + rng.randf_range(-0.5, 0.5)
			if _st < dt * 1.5:
				var t := _pos + Vector3(-sin(a), 0.0, -cos(a)) * 1.2
				_target = t if not wet.is_valid() or bool(wet.call(t.x, t.z)) else _pos
			_pace = float(S.walk) * 1.4
			if _st > 4.0:
				_dive_to = 0.0
				swim(_pos, 1.0)


func _nearest_water() -> Vector3:
	if not wet.is_valid():
		return _pos
	for r in [0.3, 0.6, 1.0, 1.5, 2.2, 3.0]:
		for k in 12:
			var a := TAU * k / 12.0
			var p := _pos + Vector3(cos(a), 0.0, sin(a)) * float(r)
			if bool(wet.call(p.x, p.z)):
				return p + Vector3(cos(a), 0.0, sin(a)) * 0.3
	return _pos


func _splash_at(p: Vector3) -> void:
	for k in 3:
		var mi := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.8
		t.outer_radius = 1.0
		mi.mesh = t
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.85, 0.9, 0.95, 0.6)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = m
		mi.set_meta("t", -0.15 * k)
		get_parent().add_child(mi)
		mi.global_position = Vector3(p.x, water_y + 0.01, p.z)
		mi.scale = Vector3.ONE * 0.05
		_splash.append(mi)
	# (the spray, thrown up)
	var sp := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	sp.mesh = sph
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.9, 0.95, 1.0, 0.5)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sp.material_override = sm
	sp.set_meta("t", 0.0)
	sp.set_meta("spray", true)
	get_parent().add_child(sp)
	sp.global_position = Vector3(p.x, water_y + 0.1, p.z)
	_splash.append(sp)


## (To the sapling; sat up, gnawing round it, chips flying; it falls; a
## length gnawed off; carried to the water and out to its lodge.)
func _fell(dt: float) -> void:
	if not is_instance_valid(_tree):
		wander(_pos, 0.8)
		return
	var tp := _tree.global_position
	var to := tp - _pos
	to.y = 0.0
	var reach := 330.0 * MM * size # (its middle to its mouth, sat up)
	match _stage:
		0:
			_target = tp - to.normalized() * reach if to.length() > reach * 1.05 else _pos
			if to.length() <= reach * 1.15 and _speed < 0.05:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
		1: # (gnawing: its head swung round the trunk, its jaws going)
			_target = _pos
			_sit_to = 1.0
			_neck_to = Vector2(-0.35, 0.55 * sin(_st * 0.9))
			_chew = 1.0
			_jaw_to = 0.15 * maxf(sin(_st * 14.0), 0.0)
			if fmod(_st, 0.35) < dt:
				_chip(tp + Vector3(0.0, 0.3, 0.0))
			var notch := _tree.get_child(0) as MeshInstance3D
			if notch:
				notch.scale = Vector3(lerpf(1.0, 0.85, _st / 10.0), 1.0, lerpf(1.0, 0.85, _st / 10.0))
			if _st > 10.0:
				_stage = 2
				_st = 0.0
		2: # (it falls: away from it, slowly, then fast)
			_sit_to = 0.0
			var f := clampf(_st / 1.8, 0.0, 1.0)
			var axis := to.normalized().cross(Vector3.UP).normalized()
			_tree.transform.basis = Basis(axis, -f * f * PI * 0.47) if axis.length() > 0.5 else Basis()
			if _st > 2.2:
				_stage = 3
				_st = 0.0
		3: # (a length gnawed off it)
			_target = _pos
			_neck_to = Vector2(-1.0, 0.3 * sin(_st * 1.3))
			_chew = 1.0
			if _st > 4.0:
				_branch = stick_of()
				get_parent().add_child(_branch)
				_held_stick = true
				_stage = 4
				_st = 0.0
		4: # (in its jaws, to the water)
			if _in_water:
				_stage = 5
				_st = 0.0
			else:
				_target = _nearest_water()
				_pace = float(S.walk)
		5: # (swum out to its lodge, and laid on it)
			var at := lodge.global_position if is_instance_valid(lodge) else _pos
			var tl := at - _pos
			tl.y = 0.0
			_target = at - tl.normalized() * 1.1 if tl.length() > 1.15 else _pos
			_pace = float(S.walk) * 0.9
			if tl.length() <= 1.2 or _st > 25.0:
				_held_stick = false
				if is_instance_valid(_branch) and is_instance_valid(lodge):
					var spot := Vector3(-tl.normalized().x, 0.55, -tl.normalized().z) * Vector3(0.85, 1.0, 0.8)
					var gt := _branch.global_transform
					_branch.get_parent().remove_child(_branch)
					lodge.add_child(_branch)
					_branch.global_transform = gt
					_branch.position = spot + Vector3(0.0, rng.randf_range(-0.2, 0.15), 0.0)
					_branch.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.5, 0.5))
				_branch = null
				swim(_pos, 1.2)


func _chip(at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.012, 0.004, 0.018)
	mi.mesh = b
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.92, 0.86, 0.7)
	mi.material_override = m
	mi.set_meta("v", Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0.4, 0.9), rng.randf_range(-0.4, 0.4)))
	get_parent().add_child(mi)
	mi.global_position = at
	_chips.append(mi)


## (The stick where it lies, not picked up: its head down to it, its mouth
## working along it, its bark gnawed off.)
func _eat_stick(dt: float) -> void:
	if not is_instance_valid(_branch):
		wander(_pos, 0.8)
		return
	var sp := _branch.global_position
	var to := sp - _pos
	to.y = 0.0
	var reach := 300.0 * MM * size
	match _stage:
		0:
			_target = sp - to.normalized() * reach if to.length() > reach * 1.05 else _pos
			if to.length() <= reach * 1.2 and _speed < 0.05:
				_target = _pos
				_stage = 1
				_st = 0.0
		1:
			_target = _pos
			_sit_to = 0.0
			_chew = 1.0
			_held_stick = false
			# (its mouth along the stick, end to end and back, on it)
			var m := _jaw.global_transform * Vector3(0.0, -5.0, -70.0)
			if _st < dt * 1.5 or _gnaw_ends.is_empty():
				_gnaw_ends = _ends_of(_branch)
			var at: Vector3 = (_gnaw_ends[0] as Vector3).lerp(_gnaw_ends[1], 0.5 + 0.35 * sin(_st * 0.5))
			_gnaw_pitch = clampf(_gnaw_pitch + clampf((at.y - m.y) * 10.0, -1.0, 1.0) * dt, -1.1, 0.2)
			_neck_to = Vector2(_gnaw_pitch, 0.0)
			var off := Vector3(at.x - m.x, 0.0, at.z - m.z)
			if off.length() > 0.01:
				_pos += off.limit_length(0.08 * size * dt)
				_target = _pos
			var bark := _bark_of(_branch)
			if bark:
				bark.albedo_color = _bark_was.lerp(Color(0.93, 0.9, 0.8), clampf(_st / 12.0, 0.0, 1.0))
			if _st > 12.0:
				_held_stick = false
				_branch = null
				_sit_to = 0.0
				groom()


var _bark_was := Color(0.6, 0.6, 0.5)
var _gnaw_ends: Array = []


## (A stick's two ends, lying: along its longer way over the ground, at its top.)
static func _ends_of(stick: Node3D) -> Array:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in stick.find_children("*", "MeshInstance3D", true, false):
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return [stick.global_position, stick.global_position]
	var c := box.get_center()
	c.y = box.end.y
	var along := Vector3(box.size.x * 0.5, 0.0, 0.0) if box.size.x >= box.size.z else Vector3(0.0, 0.0, box.size.z * 0.5)
	return [c - along, c + along]


## (A stick's bark, to whiten as it's gnawed: its first mesh's material, its
## own copy (its bark's colour first kept), wherever in it that mesh is
## (its own stick_of's, or the game's stick, laid as dropped).)
func _bark_of(stick: Node) -> StandardMaterial3D:
	if stick.has_meta("gnawed"):
		return stick.get_meta("gnawed")
	var mi: MeshInstance3D = stick as MeshInstance3D
	if mi == null:
		var found := stick.find_children("*", "MeshInstance3D", true, false)
		mi = found[0] if not found.is_empty() else null
	if mi == null:
		return null
	var m := mi.material_override if mi.material_override else mi.get_active_material(0)
	var bark := (m.duplicate() as StandardMaterial3D) if m is StandardMaterial3D else StandardMaterial3D.new()
	_bark_was = bark.albedo_color
	mi.material_override = bark
	stick.set_meta("gnawed", bark)
	return bark


## (Mud: scooped up against its chest with its forepaws, pushed on to its
## lodge.)
func _mud(dt: float) -> void:
	var at := lodge.global_position if is_instance_valid(lodge) else _pos
	var to := at - _pos
	to.y = 0.0
	match _stage:
		0: # (a scoop at its feet)
			_target = _pos
			_neck_to = Vector2(-0.8, 0.0)
			if _st > 2.0:
				_stage = 1
				_st = 0.0
		1: # (to the lodge, the mud held to its chest)
			_target = at - to.normalized() * 1.1 if to.length() > 1.15 else _pos
			_pace = float(S.walk) * 0.8
			if to.length() <= 1.2 or _st > 20.0:
				_stage = 2
				_st = 0.0
		2: # (pushed on, patted)
			_target = _pos
			_neck_to = Vector2(-0.2, 0.0)
			if _st > 2.5:
				if is_instance_valid(lodge):
					var mi := MeshInstance3D.new()
					var s := SphereMesh.new()
					s.radius = 0.5
					s.height = 1.0
					mi.mesh = s
					mi.scale = Vector3(0.22, 0.08, 0.18)
					var m := StandardMaterial3D.new()
					m.albedo_color = Color(0.22, 0.17, 0.12)
					m.roughness = 0.6
					mi.material_override = m
					lodge.add_child(mi)
					var d := -to.normalized()
					mi.position = Vector3(d.x * 0.85, 0.45 + rng.randf() * 0.2, d.z * 0.75)
				if _in_water:
					swim(_pos, 1.0)
				else:
					wander(_pos, 0.8)


func _kit() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var y: Node3D = (get_script() as Script).new(true)
	y.set("wet", wet)
	y.set("water_y", water_y)
	y.set("height", height)
	parent.add_child(y)
	var k := young_ones.size()
	var at := _out(Vector3(float(S.body_w) * 2.2 * (1.0 if k % 2 == 0 else -1.0), -body_h, 200.0 - 150.0 * k))
	y.call("place", Vector3(at.x, _pos.y, at.z), _yaw + rng.randf_range(-1.0, 1.0))
	y.set("_mother", self)
	y.set("_mode", "follow")
	y.call("grow", 0.5, 800.0)
	young_ones.append(y)


# --- its pose ----------------------------------------------------------------------

func _pose(dt: float) -> void:
	super(dt)
	# swimming: low in the water, its forefeet tucked to its chest, its hind
	# feet paddling by turns
	if _in_water and not _mate_role in ["male"]:
		_paddle += dt * (3.0 + 4.0 * clampf(_speed / 0.5, 0.0, 1.0))
		for i in 4:
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			if i < 2:
				_pose_foot[i] = Vector3(hp.x * side * 0.7, hp.y - 75.0, hp.z - 35.0)
			else:
				var ph := _paddle + (PI if side > 0.0 else 0.0)
				_pose_foot[i] = Vector3(hp.x * side * 1.3, hp.y - 95.0 + 25.0 * sin(ph), hp.z + 110.0 + 70.0 * cos(ph))
	elif _mode in ["fell", "eat_stick"] and _sit > 0.6: # (its hands up at its mouth: on the trunk; the stick held)
		var mouth := _neck.transform * (_head.transform * Vector3(0.0, -40.0, -130.0))
		for i: int in [0, 1]:
			var side := 1.0 if i == 1 else -1.0
			_pose_foot[i] = mouth + Vector3(45.0 * side, -30.0, 25.0)
	# the stick, in its jaws or its hands
	if _held_stick and is_instance_valid(_branch):
		var jt := _jaw.global_transform
		var b := jt.basis.orthonormalized()
		var roll := Basis(Vector3.RIGHT, _st * 1.5) if _mode == "eat_stick" else Basis()
		_branch.global_transform = Transform3D(b * roll, jt * Vector3(0.0, -5.0, -70.0))
	# the splash's rings spreading, fading; chips falling
	for d in _splash:
		if is_instance_valid(d):
			var t := float(d.get_meta("t")) + dt
			d.set_meta("t", t)
			var dm := d.material_override as StandardMaterial3D
			if d.has_meta("spray"):
				d.scale = Vector3(0.25, 0.4, 0.25) * clampf(t * 3.0, 0.05, 1.0)
				dm.albedo_color.a = maxf(0.5 - t * 0.8, 0.0)
			else:
				d.scale = Vector3(1.0, 0.3, 1.0) * maxf(t, 0.01) * 0.6
				dm.albedo_color.a = maxf(0.6 - t * 0.3, 0.0)
			if t > 2.0:
				d.queue_free()
	for c in _chips:
		if is_instance_valid(c):
			var v: Vector3 = c.get_meta("v")
			v.y -= 9.8 * dt
			c.set_meta("v", v)
			c.global_position += v * dt
			var g := _ground(c.global_position.x, c.global_position.z)
			if c.global_position.y < g:
				c.global_position.y = g
				c.set_meta("v", Vector3.ZERO)


func _pose_tail(dt: float) -> void:
	super(dt)
	# (in the water: flat out behind; slapped: raised, then cracked down)
	var n := _tail.size()
	for k in n:
		var r: Vector3 = _tail[k].rotation
		var a := r.x
		if _in_water:
			a = lerpf(a, -0.25 if k == 0 else 0.02, 0.6)
		if absf(_slap) > 0.01:
			a = lerpf(a, (-1.1 if k == 0 else -0.15) if _slap < 0.0 else (0.35 if k == 0 else 0.05), absf(_slap))
		_tail[k].rotation = Vector3(a, r.y, 0.0)


# --- mating ------------------------------------------------------------------------

func _court_secs() -> float:
	return 5.0


func _after_mate() -> void:
	if _in_water:
		swim(_pos, 1.0)
	else:
		wander(_pos, 0.8)


# --- steering (pilot.gd) -----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["swim", "slap", "fell", "eat", "groom", "mark"])
	if not young:
		b.append("mate")
		if not male:
			b.append_array(PackedStringArray(["birth", "nurse"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"swim":
			swim(args.get("centre", _pos), float(args.get("radius", 1.0)))
		"slap":
			slap()
		"fell":
			if not args.has("sapling"):
				return false
			fell(args.sapling)
		"eat":
			if not args.has("stick"):
				return false
			eat(args.stick)
		"groom":
			groom()
		"mark":
			mark()
		"birth":
			birth(int(args.get("n", 3)))
		"nurse":
			nurse()
		_:
			return super(name, args)
	return true


func _p_act_done(name: String) -> bool:
	if name in ["swim", "slap", "fell", "groom", "mark", "birth", "nurse"]:
		return _mode != name
	if name == "eat":
		return _mode != "eat_stick"
	return super(name)
