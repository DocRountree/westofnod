class_name SeaOtter
extends "res://scripts/creatures/otter.gd" # (by path: found whether or not the editor has seen the class yet)
## A sea otter (Enhydra lutris), life size (about 1.2 m nose to tail tip,
## its tail 30 cm of it), on the four-legged make (Carnivore: plantigrade,
## short legged) and one skin: heavy, round bodied, loose skinned; its neck
## short and thick; its head round and blunt, its muzzle broad, the whisker
## pads full, its whiskers long and pale, its nose a broad black pad; its
## eyes small, dark, set wide; its ears tiny; its forepaws small round
## mittens (their claws drawn in); its hind feet broad flat flippers, the
## toes webbed to their tips; its tail short, thick and flattened. Its coat
## (carnivore.gdshader's species 16) the densest of any animal: a deep
## brown, near black, frosted silver at the tips of its guard hairs; its
## head, throat and chest cream to blond (paler with age, a grown male's
## near white). Its pup (SeaOtter.new(true)) born at sea, a fluffy buff,
## too buoyant to dive: carried on its mother's chest as she floats.
##
## It lives on the water, on its back (Otter's: in the water; on land
## slow, clumsy, humping along on its flippers):
## - swim(centre, radius): about its water: travelling belly down, its hind
##   flippers sculling; long whiles resting on its back, drifting, its
##   forepaws on its chest, its flippers out of the water
## - forage(): to a clam or an urchin on the bottom (a real one: one of
##   SeaOtter.clam(), urchin() lying there, meta "shellfish"; none, it
##   doesn't), a dive to it, nosing and digging there with its forepaws; up
##   with it, and a rock tucked under its arm if one lies by it (meta
##   "otter_rock"); over onto its back, the rock laid on its chest and the clam
##   hammered on it, two-handed, till it cracks; eaten off its chest,
##   bit by bit; the shells let go, sinking, the rock kept a while, then
##   dropped
## - groom(): on the water, rolling over and over, then on its back,
##   rubbing and combing its fur with its forepaws, kneading it, blowing it
##   up with air (its fur's air its warmth)
## - sleep(): on its back, its forepaws over its eyes; with kelp by it
##   (SeaOtter.kelp()), wrapped in a strand of it to keep from drifting; by
##   another asleep, rafted together, holding paws
## - alarm(): up tall in the water, looking about; under, away; up again
## - birth(): (a female's) on her back, licking; her pup on her chest. It
##   rides there, nursing at her belly (nurse()), groomed; when she dives
##   it's left bobbing on its back, crying, till she's back for it
## - eat_held(food), fish(school), catch(prey): all eaten on its back,
##   held to its mouth, off its chest
## - mate(her): in the water (the hunters' way)
## Steering (pilot.gd): Otter's, and act forage, alarm.

const SPEC := {
	"male_parts": {"sheath": [-60.0, 40.0, 15.0]},
	"species": 16, "plantigrade": true, "sole_hind": 2.6, "boxy": 2.05, "belly": 1.0,
	"body": [[-370.0, 6.0, 92.0, 92.0], [-300.0, 0.0, 110.0, 108.0], [-160.0, -4.0, 122.0, 116.0], [0.0, -2.0, 126.0, 118.0],
			[150.0, 0.0, 122.0, 112.0], [270.0, 2.0, 104.0, 94.0], [335.0, 2.0, 72.0, 64.0], [362.0, 0.0, 44.0, 40.0]],
	"body_h": 160.0, "body_len": 760.0, "body_w": 124.0,
	"neck_at": Vector3(0.0, 26.0, -350.0), "neck": [[30.0, 0.0, 88.0, 88.0], [-20.0, 0.0, 80.0, 80.0], [-55.0, 0.0, 74.0, 74.0]], "neck_pitch": 0.12,
	"head_at": Vector3(0.0, 0.0, -62.0),
	"head": [[50.0, 0.0, 70.0, 62.0], [10.0, 6.0, 80.0, 72.0], [-30.0, 4.0, 74.0, 64.0], [-70.0, -6.0, 56.0, 46.0], [-104.0, -12.0, 40.0, 32.0], [-124.0, -14.0, 22.0, 20.0]],
	"jaw_at": Vector3(0.0, -44.0, -46.0), "jaw": [[0.0, 0.0, 38.0, 15.0], [-30.0, 4.0, 32.0, 12.0], [-54.0, 11.0, 17.0, 8.0]], "mouth": 1.0,
	"mouth_z": -540.0,
	"eye": {"at": Vector3(40.0, 20.0, -74.0), "size": Vector3(11.0, 11.0, 11.0), "color": Color(0.02, 0.018, 0.016), "slit": 1.0},
	"nose": {"at": Vector3(0.0, -10.0, -122.0), "size": Vector3(40.0, 28.0, 20.0), "color": Color(0.04, 0.035, 0.035)},
	"whisker": 95.0,
	"ear": {"at": Vector3(66.0, 46.0, 14.0), "len": 14.0, "width": 18.0, "point": 0.1, "tilt_back": 0.6, "spread": 0.9},
	"tail": {"base": Vector3(0.0, 0.0, 352.0), "n": 5, "seg": 62.0, "radii": [48.0, 54.0, 54.0, 48.0, 34.0], "carry": [0.12, 0.02], "wrap": 0.3, "flat": 0.42},
	"fore": {"hip": Vector3(78.0, -52.0, -270.0), "a": 58.0, "b": 52.0, "m": 22.0, "p": 34.0, "home": Vector2(86.0, -290.0), "r": 21.0},
	"hind": {"hip": Vector3(84.0, -24.0, 262.0), "a": 72.0, "b": 70.0, "m": 40.0, "p": 125.0, "home": Vector2(100.0, 240.0), "r": 28.0},
	"fur": 22.0, "tail_fur": 0.0,
	"walk": 0.25, "trot": 0.45, "run": 0.9, "swim": 0.55,
	"stalk_from": 0.8, "spring": 0.3, "stalk_crouch": 0.1, "stalk_neck": -0.3, "eat_crouch": 0.2,
	"sit_drop": 60.0, "sit_pitch": 0.8, "lie_h": 120.0,
	"mate_secs": 25.0,
	# its head sculpted (SculptHead), from photographs: round and blunt, its
	# crown full; its muzzle broad, short, the whisker pads swelling either
	# side under the nose; its nose a broad flat black pad; its eyes small,
	# dark, set wide on the front of its face
	"sculpt": {
		"z": [50.0, 30.0, 10.0, -10.0, -30.0, -50.0, -68.0, -84.0, -98.0, -112.0, -124.0],
		"top": [58.0, 70.0, 74.0, 73.0, 68.0, 59.0, 49.0, 39.0, 30.0, 21.0, 10.0],
		"bot": [-58.0, -64.0, -66.0, -65.0, -62.0, -56.0, -50.0, -45.0, -40.0, -33.0, -21.0],
		"w": [66.0, 76.0, 80.0, 79.0, 75.0, 68.0, 61.0, 56.0, 50.0, 38.0, 21.0],
		"wl": [68.0, 79.0, 83.0, 82.0, 79.0, 72.0, 66.0, 61.0, 54.0, 41.0, 22.0],
		"pw": [2.0, 2.0, 2.05, 2.1, 2.15, 2.2, 2.3, 2.4, 2.5, 2.4, 2.2],
		"eye": Vector3(40.0, 20.0, -74.0), "eye_r": 6.5, "socket": 0.6, "lid": 0.7,
		"brow": 1.4, "cheek": 2.6, "stop": 0.8, "pads": 4.6, "flews": 0.9, "nose_r": 22.0,
		"almond": 0.9, "slant": 0.0, "look_fwd": 0.85, "pupil": Vector2(0.8, 0.8),
	},
}

var kelp_bed: Node3D ## kelp near it (SeaOtter.kelp()), to wrap itself in asleep
var _carrier: Node3D # (a pup's: its mother, carrying it on her chest)
var _nursing := false # (a pup's: at her belly)
var _rock: Node3D
var _shells: Array[Node3D] = []
var _clam := true # (what it's brought up: a clam, or an urchin)
var _shell: Node3D # (the one it's after, on the bottom)
var _wrap: Array[MeshInstance3D] = []
var _raft: Node3D # (another asleep by it, holding paws)
var _pound := 0.0


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.24 if young_ else 0.5)
	_setup()
	dry_secs = 150.0


func _male_size() -> float:
	return 1.12


func _surface_sink() -> float:
	return _half_h() * lerpf(0.6, 0.08, _back) # (on its back, high: its chest and belly out of the water)


func _eats_ashore() -> bool:
	return false


func _build_extra() -> void:
	var wd := _mat(Color(0.9, 0.88, 0.82), 0.45)
	var sc: Dictionary = S.sculpt
	var zt := float((sc.z as Array)[(sc.z as Array).size() - 1])
	for side: float in [-1.0, 1.0]: # (its whiskers: long, pale, many, drooping)
		for k in 8:
			var p0 := SculptScript.point(sc, zt + 22.0 + float(k % 4) * 6.0, PI * (0.42 + 0.05 * float(k / 4)) * side)
			var d := Vector3(side, -0.12 + 0.07 * float(k % 4), 0.35).normalized()
			_stick(p0, p0 + d * 55.0 + Vector3(0.0, -12.0, 22.0), 0.55, wd, _head)


# --- what it eats, its kelp -------------------------------------------------------

## A clam (a littleneck: ridged, grey-brown), shut; its origin at its middle.
static func clam(open := false) -> Node3D:
	var root := Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.5, 0.42)
	m.roughness = 0.6
	var inner := StandardMaterial3D.new()
	inner.albedo_color = Color(0.9, 0.85, 0.78)
	inner.roughness = 0.35
	var flesh := StandardMaterial3D.new()
	flesh.albedo_color = Color(0.85, 0.62, 0.48)
	flesh.roughness = 0.4
	for k in 2:
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.is_hemisphere = true
		var v := MeshInstance3D.new()
		v.mesh = s
		v.material_override = m
		v.scale = Vector3(0.05, 0.014, 0.042)
		if k == 1:
			v.rotation.x = PI
		if open:
			v.rotation.x += (-0.9 if k == 0 else 0.9)
			v.position.z = 0.012
		root.add_child(v)
	if open:
		var f := MeshInstance3D.new()
		var fs := SphereMesh.new()
		fs.radius = 0.5
		fs.height = 1.0
		f.mesh = fs
		f.material_override = flesh
		f.scale = Vector3(0.036, 0.012, 0.028)
		root.add_child(f)
	return root


## A purple sea urchin: a flattened ball, bristling with spines.
static func urchin() -> Node3D:
	var root := Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.28, 0.12, 0.3)
	m.roughness = 0.5
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var b := MeshInstance3D.new()
	b.mesh = s
	b.material_override = m
	b.scale = Vector3(0.05, 0.032, 0.05)
	root.add_child(b)
	var sp := StandardMaterial3D.new()
	sp.albedo_color = Color(0.42, 0.2, 0.46)
	sp.roughness = 0.45
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 0.0016
	c.height = 0.03
	c.radial_segments = 4
	c.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = c
	mm.instance_count = 80
	for i in 80:
		var y := 1.0 - 2.0 * (float(i) + 0.5) / 80.0
		var r := sqrt(1.0 - y * y)
		var a := float(i) * 2.39996
		var n := Vector3(cos(a) * r, y * 0.7, sin(a) * r).normalized()
		var at := Vector3(n.x * 0.025, n.y * 0.016, n.z * 0.025)
		mm.set_instance_transform(i, Transform3D(Basis(Quaternion(Vector3.UP, n)), at + n * 0.015))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = sp
	root.add_child(mi)
	return root


## A rock to crack shells on: a flattish cobble, grey.
static func rock() -> Node3D:
	var root := Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.45, 0.43)
	m.roughness = 0.9
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = m
	mi.scale = Vector3(0.08, 0.035, 0.065)
	root.add_child(mi)
	return root


## Kelp (bull kelp) at the surface: its stipes up from the bottom, its
## floats, its long brown blades streaming out over the water. Its origin
## on the surface at its floats; down to depth (m).
static func kelp(depth := 1.0) -> Node3D:
	var root := Node3D.new()
	root.set_meta("kelp", true)
	var brown := StandardMaterial3D.new()
	brown.albedo_color = Color(0.36, 0.3, 0.12)
	brown.roughness = 0.55
	brown.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for k in 5:
		var a := rng.randf() * TAU
		var float_at := Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.05, 0.5)
		var st := CylinderMesh.new() # (its stipe, down to its holdfast)
		st.top_radius = 0.008
		st.bottom_radius = 0.004
		st.height = depth
		st.radial_segments = 5
		var sm := MeshInstance3D.new()
		sm.mesh = st
		sm.material_override = brown
		sm.position = float_at + Vector3(0.0, -depth * 0.5, 0.0)
		root.add_child(sm)
		var bulb := MeshInstance3D.new()
		var bs := SphereMesh.new()
		bs.radius = 0.03
		bs.height = 0.06
		bulb.mesh = bs
		bulb.material_override = brown
		bulb.position = float_at + Vector3(0.0, 0.005, 0.0)
		root.add_child(bulb)
		for j in 6: # (its blades, out over the water)
			var b := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.06, rng.randf_range(0.5, 0.9))
			b.mesh = q
			b.material_override = brown
			var ba := a + rng.randf_range(-0.6, 0.6)
			var len_ := q.size.y
			b.transform = Transform3D(Basis(Vector3.UP, -ba + PI * 0.5) * Basis(Vector3.RIGHT, -PI * 0.5), float_at + Vector3(cos(ba), 0.0, sin(ba)) * len_ * 0.5 + Vector3(0.0, 0.004 + 0.001 * j, 0.0))
			root.add_child(b)
	return root


# --- its ways ------------------------------------------------------------------------

## False if there's no clam or urchin on the bottom near (within 40 m).
func forage() -> bool:
	_shell = null
	var bd := 40.0
	for o in get_parent().get_children():
		if o is Node3D and o.has_meta("shellfish") and not o.has_meta("taken") and (o as Node3D).global_position.distance_to(global_position) < bd:
			bd = (o as Node3D).global_position.distance_to(global_position)
			_shell = o
	if _shell == null:
		return false
	_shell.set_meta("taken", true)
	_mode = "forage"
	_stage = 0
	_st = 0.0
	return true


func alarm() -> void:
	_mode = "alarm"
	_stage = 0
	_st = 0.0


func groom() -> void:
	if not _in_water:
		super()
		return
	_mode = "groom_sea"
	_stage = 0
	_st = 0.0


func sleep(secs := 20.0) -> void:
	if not _in_water:
		super(secs)
		return
	_mode = "sleep_sea"
	_wait = secs
	_stage = 0
	_st = 0.0
	_raft = null


func birth(n := 1, _den: Node3D = null) -> void:
	if young or male:
		return
	_mode = "birth_sea"
	_born_left = clampi(n, 1, 1) # (one, always)
	_stage = 0
	_st = 0.0


func nurse() -> void:
	if young_ones.is_empty():
		return
	_mode = "nurse_sea"
	_stage = 0
	_st = 0.0


func _swim_leg() -> void:
	var r := rng.randf()
	if r < 0.5: # (a long while resting on its back)
		_float_t = rng.randf_range(6.0, 14.0)
		_under_t = 0.0
	elif r < 0.65:
		_under_t = rng.randf_range(3.0, 6.0)


func _own_think(dt: float) -> bool:
	if young and _carrier == null:
		return _pup_think(dt)
	match _mode:
		"forage":
			_common(dt)
			_forage(dt)
			return true
		"groom_sea":
			_common(dt)
			_groom_sea(dt)
			return true
		"sleep_sea":
			_common(dt)
			_sleep_sea(dt)
			return true
		"alarm":
			_common(dt)
			_alarm(dt)
			return true
		"birth_sea":
			_common(dt)
			_back_to = 1.0
			_target = _pos
			_neck_to = Vector2(-1.0, 0.0)
			_lick = 0.7
			if _st > 4.0 and _born_left > 0:
				_born_left = 0
				_pup()
			if _st > 6.0:
				swim(_pos, 1.2)
				_float_t = 12.0
			return true
		"nurse_sea":
			_common(dt)
			_back_to = 1.0
			_target = _pos
			_neck_to = Vector2(-0.8, 0.3 * sin(_st * 0.4))
			for y in young_ones:
				if is_instance_valid(y) and y.get("_carrier") == self:
					y.set("_nursing", _st < 20.0)
			if _st > 20.0:
				swim(_pos, 1.2)
				_float_t = 8.0
			return true
		"swim":
			_common(dt)
			_swim(dt)
			_fetch_pup()
			return true
	return false


## (Back for her pup, left bobbing: to it, and it onto her chest.)
func _fetch_pup() -> void:
	if _dive > 0.05:
		return
	for y in young_ones:
		if is_instance_valid(y) and y.get("_carrier") == null and bool(y.get("_in_water")):
			var yp: Vector3 = y.get("_pos")
			var to := Vector3(yp.x - _pos.x, 0.0, yp.z - _pos.z)
			if to.length() > 0.3:
				_target = Vector3(yp.x, _pos.y, yp.z)
				_back_to = 0.0
				_float_t = 0.0
				_pace = float(S.swim)
			else:
				_back_to = 1.0
				if _back > 0.9:
					y.call("board", self)
			return


## (Down to the bottom; nosing, digging; up with a clam or an urchin and a
## rock; over onto its back; the clam hammered on the rock on its chest
## till it cracks; eaten; the shells let go.)
func _forage(dt: float) -> void:
	match _stage:
		0: # (to its water)
			if not _in_water:
				_target = _nearest_water()
				_pace = float(S.run)
				if _target == _pos:
					wander(_pos, 1.0)
				return
			if not is_instance_valid(_shell):
				wander(_pos, 1.0)
				return
			var over := _shell.position
			_target = Vector3(over.x, _pos.y, over.z) # (over it)
			if Vector2(over.x - _pos.x, over.z - _pos.z).length() > 0.3:
				_pace = float(S.swim)
				return
			_stage = 1
			_st = 0.0
		1: # (a dive: its rump up, its flippers last, down)
			_dive_to = 1.0
			_pace = float(S.swim) * 1.2
			_neck_to = Vector2(-0.3, 0.0)
			if _dive > 0.95 or _st > 6.0:
				_target = _pos
				_stage = 2
				_st = 0.0
		2: # (on the bottom: nosing, digging with its forepaws)
			_dive_to = 1.0
			_target = _pos
			_neck_to = Vector2(-0.7, 0.4 * sin(_st * 1.5))
			_sniff = 1.0
			if _st > 3.5:
				if not is_instance_valid(_shell):
					_stage = 4
					_dive_to = 0.0
					return
				_clam = String(_shell.get_meta("shellfish")) == "clam"
				_food = _shell # (the one it dove for: taken up)
				_food_s = _food.scale
				_rock = null
				if _clam: # (a rock lying by it, if there is one)
					for o in get_parent().get_children():
						if o is Node3D and o.has_meta("otter_rock") and (o as Node3D).position.distance_to(_food.position) < 2.0:
							_rock = o
							break
				_stage = 3
				_st = 0.0
		3: # (up with them)
			_dive_to = 0.0
			_neck_to = Vector2(0.2, 0.0)
			if _dive < 0.04:
				_stage = 4
				_st = 0.0
		4: # (over onto its back)
			_target = _pos
			_back_to = 1.0
			_neck_to = Vector2(-1.0, 0.0)
			if _back > 0.95:
				_stage = 5 if _clam else 6
				_st = 0.0
		5: # (the rock on its chest; the clam hammered on it, two-handed)
			_target = _pos
			_back_to = 1.0
			_neck_to = Vector2(-1.05, 0.0)
			if _st > 4.5:
				var at := _food.global_transform
				_food.queue_free()
				_food = clam(true)
				get_parent().add_child(_food)
				_food.global_transform = at
				_food_s = _food.scale
				_stage = 6
				_st = 0.0
		6: # (eaten off its chest, bit by bit)
			_target = _pos
			_back_to = 1.0
			_neck_to = Vector2(-1.15, 0.15 * sin(_st * 0.8))
			_chew = 1.0
			_jaw_to = 0.3 * maxf(sin(_st * 7.0), 0.0)
			var secs := 8.0
			if is_instance_valid(_food):
				for ch in _food.get_children():
					if ch is MeshInstance3D and (ch as MeshInstance3D).material_override and ((ch as MeshInstance3D).material_override as StandardMaterial3D).albedo_color.r > 0.8 and ((ch as MeshInstance3D).material_override as StandardMaterial3D).albedo_color.g < 0.7:
						ch.scale = ch.scale.lerp(Vector3.ONE * 0.0001, dt / secs * 2.0) # (the clam's flesh, going)
				if not _clam:
					_food.scale = _food_s * lerpf(1.0, 0.35, clampf(_st / secs, 0.0, 1.0))
			if _st > secs:
				_let_go()
				groom()


## (The shells let go, sinking; the rock dropped after.)
func _let_go() -> void:
	for n: Node3D in [_food, _rock]:
		if is_instance_valid(n):
			n.set_meta("sink", water_y)
			_shells.append(n)
	_food = null
	_rock = null


func _groom_sea(dt: float) -> void:
	_target = _pos
	_back_to = 1.0
	match _stage:
		0: # (rolling over and over in the water)
			_spin += dt * 3.6
			_wiggle = 1.0
			if _st > 5.2:
				_spin = wrapf(_spin, -PI, PI)
				_stage = 1
				_st = 0.0
		1: # (on its back: rubbing, kneading, combing its fur with its forepaws; its head down to it)
			_spin = move_toward(_spin, 0.0, dt * 2.0)
			_neck_to = Vector2(-1.2 + 0.3 * sin(_st * 0.7), 0.5 * sin(_st * 0.5))
			_lick = 0.6
			if _st > 10.0:
				swim(_pos, 1.2)
				_float_t = 6.0


func _sleep_sea(dt: float) -> void:
	_back_to = 1.0
	_target = _pos
	_neck_to = Vector2(-0.8, 0.0)
	_ears_to = -0.3
	match _stage:
		0: # (to its kelp, if it's near; or by another asleep)
			if is_instance_valid(kelp_bed) and kelp_bed.global_position.distance_to(global_position) < 4.0:
				var kp: Vector3 = (get_parent() as Node3D).to_local(kelp_bed.global_position)
				var to := Vector3(kp.x - _pos.x, 0.0, kp.z - _pos.z)
				if to.length() > 0.25 and _st < 20.0:
					_back_to = 0.0
					_target = Vector3(kp.x, _pos.y, kp.z)
					_pace = float(S.swim)
					return
			_raft = null
			for c in get_parent().get_children():
				if c != self and c.get_script() == get_script() and not bool(c.get("young")) and c.get("_mode") == "sleep_sea":
					if (c as Node3D).position.distance_to(position) < 1.8:
						_raft = c
						break
			_stage = 1
			_st = 0.0
		1: # (wrapped in a strand of it, if there's kelp)
			if is_instance_valid(kelp_bed) and kelp_bed.global_position.distance_to(global_position) < 0.8 and _wrap.is_empty():
				_wrap_kelp()
			_stage = 2
			_st = 0.0
		2: # (asleep, its forepaws over its eyes; rafted, holding paws)
			if is_instance_valid(_raft):
				var rp: Vector3 = _raft.get("_pos")
				var side := Vector3(cos(_yaw), 0.0, -sin(_yaw))
				var want := rp + side * float(S.body_w) * MM * size * 2.6
				if Vector2(_pos.x - want.x, _pos.z - want.z).length() > 0.05:
					_pos = _pos.lerp(Vector3(want.x, _pos.y, want.z), 1.0 - exp(-0.4 * dt))
				_yaw = lerp_angle(_yaw, float(_raft.get("_yaw")), 1.0 - exp(-0.5 * dt))
			if _wait <= 0.0:
				for w in _wrap:
					if is_instance_valid(w):
						w.queue_free()
				_wrap.clear()
				_raft = null
				_stretch = 1.0
				swim(_pos, 1.2)


func _wrap_kelp() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.34, 0.28, 0.11)
	m.roughness = 0.5
	for k in 2:
		var t := TorusMesh.new()
		t.inner_radius = float(S.body_w) * 1.0
		t.outer_radius = float(S.body_w) * 1.12
		t.rings = 20
		t.ring_segments = 6
		var mi := MeshInstance3D.new()
		mi.mesh = t
		mi.material_override = m
		mi.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.FORWARD, 0.3 * (1.0 if k == 0 else -1.0)) * Basis.from_scale(Vector3(1.0, 3.0, 0.95)), Vector3(0.0, 0.0, -60.0 + 170.0 * k))
		_body.add_child(mi)
		_wrap.append(mi)


## (Up tall in the water, looking round; under, away; up again.)
func _alarm(dt: float) -> void:
	match _stage:
		0:
			_target = _pos
			_ears_to = 1.0
			if not _in_water:
				_target = _nearest_water()
				_pace = float(S.run)
				if _target == _pos:
					_stage = 1
				return
			if _st > 1.8:
				_target = _water_point(_pos, 2.5)
				_stage = 1
				_st = 0.0
		1:
			_dive_to = 1.0
			_pace = float(S.swim) * 1.5
			if _st > 5.0:
				_stage = 2
				_st = 0.0
		2:
			_dive_to = 0.0
			if _dive < 0.05:
				swim(_pos, 1.5)


func _after_catch() -> void:
	super()


func _eat_pose(_dt: float) -> void:
	_back_to = 1.0
	_neck_to = Vector2(-1.15, 0.15 * sin(_st * 0.8))


## Her pup: born onto her chest, carried there.
func _pup() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var y: Node3D = (get_script() as Script).new(true)
	y.set("wet", wet)
	y.set("water_y", water_y)
	y.set("floor_y", floor_y)
	y.set("height", height)
	parent.add_child(y)
	y.call("place", _pos, _yaw)
	y.set("_mother", self)
	y.call("grow", 0.5, 1200.0)
	young_ones.append(y)
	y.call("board", self)


# --- a pup's ----------------------------------------------------------------------

## (A pup's: onto its mother's chest.)
func board(m: Node3D) -> void:
	_carrier = m
	_mode = "ride"


func _off() -> void:
	_carrier = null
	_nursing = false
	_mode = "bob"
	_pitch = 0.0
	_back = 1.0
	_back_to = 1.0


## (A pup's, off her: bobbing on its back on the water, crying for her,
## paddling; on land, about after her.)
func _pup_think(dt: float) -> bool:
	if not _in_water:
		return false
	_common(dt)
	_target = _pos
	_back_to = 1.0
	_neck_to = Vector2(-0.5, 0.4 * sin(_t * 0.9))
	_jaw_to = 0.35 if fmod(_t, 2.5) < 0.5 else 0.0 # (crying)
	_mode = "bob"
	return true


func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	if _carrier != null:
		_ride(dt)
		_sink_shells(dt)
		return
	super(dt)
	_sink_shells(dt)


## (On its mother's chest, as she floats on her back, its belly to hers;
## at her belly, nursing; off, when she rolls over to dive.)
func _ride(dt: float) -> void:
	_t += dt
	size = move_toward(size, _g_to, _g_rate * dt)
	var m := _carrier
	if not is_instance_valid(m) or bool(m.get("dead")) or float(m.get("_back")) < 0.75:
		var keep := global_transform
		_off()
		_pos = (get_parent() as Node3D).to_local(keep.origin) if get_parent() is Node3D else keep.origin
		_pos.y = _ground(_pos.x, _pos.z)
		return
	process_priority = m.process_priority + 1
	_in_water = true
	_soak(dt)
	var ms := maxf(float(m.get("size")), 0.01)
	var mh: float = (m.call("_half_h") as float) / (MM * ms) # (her half height, her mm)
	var my_h := _half_h() / (MM * ms) # (mine, in her mm)
	var z := 60.0 if _nursing else -150.0
	var at: Vector3 = m.call("_out", Vector3(0.0, -mh - my_h * 0.35, z))
	var mb: Basis = (m.transform.basis.orthonormalized() * Basis(Vector3.BACK, PI)).orthonormalized()
	if _nursing:
		mb = mb * Basis(Vector3.UP, PI) # (turned round, its head to her belly)
	transform = Transform3D(mb * Basis(Vector3.RIGHT, -0.08), at)
	_body.scale = Vector3.ONE * MM * size
	_pos = Vector3(at.x, (m.get("_pos") as Vector3).y, at.z)
	_yaw = float(m.get("_yaw")) + (PI if _nursing else 0.0)
	_neck_to = Vector2(-0.15, 0.25 * sin(_t * 0.6))
	_jaw_to = 0.12 * maxf(sin(_t * 5.0), 0.0) if _nursing else 0.0
	_tail_mode = "carry"
	var keep_roll := _roll
	var keep_pitch := _pitch
	_pose(dt)
	_roll = keep_roll
	_pitch = keep_pitch
	for i in 4: # (its paws spread on her, its flippers trailing)
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		_pose_foot[i] = Vector3(hp.x * side * 1.4, hp.y - float(L.f) * 0.5, hp.z + (float(L.f) * 0.3 if i >= 2 else -float(L.f) * 0.2))
	_pose_legs()


func _sink_shells(dt: float) -> void:
	for k in range(_shells.size() - 1, -1, -1):
		var n := _shells[k]
		if not is_instance_valid(n):
			_shells.remove_at(k)
			continue
		var t := float(n.get_meta("t", 0.0)) + dt
		n.set_meta("t", t)
		var lp := n.position
		var floor_ := floor_y + 0.02
		if lp.y > floor_:
			n.position = Vector3(lp.x, maxf(lp.y - dt * 0.35, floor_), lp.z)
			n.rotation += Vector3(dt * 1.3, dt * 0.7, 0.0)
		if t > 40.0:
			n.queue_free()
			_shells.remove_at(k)


# --- its pose ----------------------------------------------------------------------

## (Its chest, in its body's mm: on its back, the top of it.)
func _chest_mm(z: float) -> Vector3:
	return Vector3(0.0, -_half_h() / (MM * size) - 6.0, z)


func _pose(dt: float) -> void:
	super(dt)
	if _carrier != null:
		return
	var e := _back * _back * (3.0 - 2.0 * _back)
	if _in_water and e > 0.5 and not (_mode in ["forage"] and _stage < 4):
		# (on its back: its forepaws on its chest, its flippers up out of the
		# water at its tail end, crossed, sculling a little)
		var hh := _half_h() / (MM * size)
		for i in 4:
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			if i < 2:
				_pose_foot[i] = Vector3(hp.x * side * 0.55, -hh - 10.0, hp.z + 40.0)
			else:
				var scull := 15.0 * sin(_paddle * 0.6 + side) * clampf(_speed / 0.1, 0.0, 1.0)
				_pose_foot[i] = Vector3(hp.x * side * 0.55, -hh * 0.9 - 40.0, hp.z + float(L.f) * 1.25 + scull)
	var m := _mouth_mm()
	match _mode:
		"forage":
			if _stage == 2: # (digging on the bottom, its forepaws by turns)
				for i: int in [0, 1]:
					var L: Dictionary = legs[0]
					var side := 1.0 if i == 1 else -1.0
					var hp: Vector3 = L.hip
					_pose_foot[i] = Vector3(hp.x * side * 0.7, hp.y - float(L.f) * 1.5 + 20.0 * sin(_t * 6.0 + side * 1.5), hp.z - 60.0)
			elif _stage >= 3:
				var c := _chest_mm(-170.0)
				var hold := m.lerp(c, 0.55)
				if _stage == 5: # (the clam hammered on the rock: up, and down hard)
					_pound = absf(sin(_st * 5.5))
					hold = c + Vector3(0.0, -16.0 - 55.0 * _pound, 0.0)
				elif _stage == 6:
					hold = m + Vector3(0.0, -20.0, 40.0)
				for i: int in [0, 1]:
					var side := 1.0 if i == 1 else -1.0
					_pose_foot[i] = hold + Vector3(26.0 * side, 0.0, 12.0)
				if is_instance_valid(_food):
					_food.global_transform = Transform3D(global_basis.orthonormalized() * Basis.from_scale(_food.scale), _out(hold + Vector3(0.0, -10.0, 0.0)))
				if is_instance_valid(_rock):
					var rat := _chest_mm(-190.0) if _stage >= 5 else Vector3(float(S.body_w) * 0.75, 0.0, -230.0) # (on its chest; under its arm, coming up)
					_rock.global_transform = Transform3D(global_basis.orthonormalized() * Basis.from_scale(_rock.scale), _out(rat + Vector3(0.0, -12.0, 0.0)))
		"sleep_sea":
			if _stage == 2: # (its forepaws over its eyes; rafted, one held out to the other's)
				var eye: Vector3 = (S.sculpt as Dictionary).eye
				var ep := _neck.transform * (_head.transform * Vector3(0.0, eye.y, eye.z))
				for i: int in [0, 1]:
					var side := 1.0 if i == 1 else -1.0
					_pose_foot[i] = ep + Vector3(side * 22.0, 25.0, 10.0)
				if is_instance_valid(_raft):
					var their: Vector3 = _raft.call("_out", Vector3(-float(S.body_w) * 0.9, 0.0, -150.0))
					var mine := (transform * _body.transform).affine_inverse() * their
					_pose_foot[1] = _pose_foot[1].lerp(mine, 0.8)
		"groom_sea":
			if _stage == 1: # (rubbing its chest and face, round and round)
				var c := _chest_mm(-120.0 + 80.0 * sin(_st * 0.9))
				for i: int in [0, 1]:
					var side := 1.0 if i == 1 else -1.0
					_pose_foot[i] = c + Vector3(30.0 * side + 25.0 * cos(_t * 6.0 + side), -10.0, 25.0 * sin(_t * 6.0 + side))
		"birth_sea", "nurse_sea":
			for i: int in [0, 1]:
				var side := 1.0 if i == 1 else -1.0
				_pose_foot[i] = _chest_mm(-100.0) + Vector3(50.0 * side, -30.0, 0.0)
	if _mode == "alarm" and _stage == 0 and _in_water: # (up tall in the water)
		_pitch = lerpf(_pitch, 1.0, 1.0 - exp(-4.0 * dt))
		_lift = lerpf(_lift, float(S.body_len) * 0.2, 1.0 - exp(-4.0 * dt))
		_neck.rotation.x -= 0.6
	# (a pup on her chest: her paws round it)
	if _mode in ["swim"] and e > 0.9:
		for y in young_ones:
			if is_instance_valid(y) and y.get("_carrier") == self:
				for i: int in [0, 1]:
					var side := 1.0 if i == 1 else -1.0
					_pose_foot[i] = _chest_mm(-120.0) + Vector3(70.0 * side, -40.0, 20.0)
				break


# --- steering (pilot.gd) -----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["forage", "alarm"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"forage":
			return forage()
		"alarm":
			alarm()
		_:
			return super(name, args)
	return true


func _p_act_done(name: String) -> bool:
	if name in ["forage", "alarm"]:
		return _mode != name
	if name == "groom":
		return _mode not in ["groom", "groom_sea"]
	if name == "sleep":
		return _mode not in ["sleep", "sleep_sea"]
	return super(name)


func _p_mobile() -> bool:
	return _carrier == null and super()
