class_name RiverOtter
extends "res://scripts/creatures/otter.gd" # (by path: found whether or not the editor has seen the class yet)
## A North American river otter (Lontra canadensis), life size (about 70 cm
## head and body, its tail 40 cm more, 25 cm at the shoulder), on the
## four-legged make (Carnivore: plantigrade, short legged) and one skin:
## long, low and supple, its back arched; its neck as thick as its head;
## its head broad and flat, its ears small and round, set low; its eyes
## small, set high and forward; its muzzle short and blunt, the whisker pads
## full, thick white whiskers; its nose a broad bare black pad; its feet
## webbed, clawed; its tail thick at its root, as thick as its body there,
## tapering to a point. Its coat (carnivore.gdshader's species 15) short and
## dense, dark chocolate, glossy, its belly paler; its throat, chin, lips
## and cheeks silvery cream, the pale down the front of its neck to its
## chest. Its pups (RiverOtter.new(true)) born furred, blind, in the holt;
## following their mother, into the water after her, and playing (chasing,
## wrestling, tumbling). Wet (Otter: soaked), its coat dark and spiky.
##
## Its ways (Otter's in the water, Carnivore's on land, and its own):
## - wander(centre, radius): about on the bank at a humped lope (its back
##   arched, its forefeet and hind feet bounding by pairs), nose down,
##   sniffing; into the water, swimming
## - swim, dive, fish(school), catch(prey): Otter's; what it catches (a
##   trout, a crayfish, a frog) carried ashore in its jaws, eaten there
##   lying on its belly, held in its forepaws, head first, its head tilted
##   to crunch it with its back teeth
## - periscope(secs): up on its hind legs, tall, its forepaws hanging at its
##   chest, its neck stretched up, looking round, sniffing the air (in the
##   water: treading water, its head and neck high out of it)
## - slide(): up the bank, then bounding down it, and onto its belly, its
##   forelegs swept back, sliding down into the water; and out to do it
##   again (play, the young's or a grown one's)
## - groom(): ashore, rolling on the bank (over onto its back and over
##   again, rubbing its face and sides along the ground) to dry its coat,
##   then sat licking and combing it
## - mark(): its spraint (its scat, dark, full of fish scales) left on a
##   rise by the water, crouched, its tail up, treading with its hind feet
## - alarm(): a snort, up to look, and a dash for the water, under, and up
##   again a way off, looking back
## - sleep() in its holt (RiverOtter.holt(): a den dug in the bank among
##   roots), out of sight; birth(n): (a female's) in her holt, her pups born
##   one by one; nursed there; then out after her
## - mate(her): in the water (the hunters' way)
## Steering (pilot.gd): Otter's, and act periscope {seconds}, slide, alarm.

const SPEC := {
	"male_parts": {"sheath": [-40.0, 30.0, 11.0]},
	"species": 15, "plantigrade": true, "sole_hind": 1.5, "boxy": 2.15, "belly": 0.95,
	"body": [[-275.0, 0.0, 52.0, 56.0], [-215.0, -2.0, 62.0, 66.0], [-120.0, 0.0, 66.0, 69.0], [0.0, 6.0, 69.0, 70.0],
			[110.0, 12.0, 71.0, 69.0], [195.0, 12.0, 64.0, 60.0], [245.0, 8.0, 52.0, 48.0], [272.0, 4.0, 36.0, 34.0]],
	"body_h": 118.0, "body_len": 560.0, "body_w": 70.0,
	"neck_at": Vector3(0.0, 20.0, -255.0), "neck": [[25.0, 0.0, 52.0, 56.0], [-25.0, 0.0, 48.0, 50.0], [-70.0, 0.0, 44.0, 44.0]], "neck_pitch": 0.22,
	"head_at": Vector3(0.0, 0.0, -88.0),
	"head": [[36.0, 0.0, 46.0, 40.0], [0.0, 4.0, 50.0, 40.0], [-30.0, 2.0, 46.0, 34.0], [-55.0, -4.0, 36.0, 28.0], [-74.0, -6.0, 28.0, 22.0], [-84.0, -7.0, 18.0, 16.0]],
	"jaw_at": Vector3(0.0, -27.0, -26.0), "jaw": [[0.0, 0.0, 28.0, 11.0], [-30.0, 3.0, 25.0, 10.0], [-52.0, 9.0, 15.0, 7.0]], "mouth": 0.8,
	"mouth_z": -420.0,
	"eye": {"at": Vector3(24.0, 22.0, -30.0), "size": Vector3(9.0, 9.0, 9.0), "color": Color(0.03, 0.025, 0.02), "slit": 1.0},
	"nose": {"at": Vector3(0.0, -6.0, -84.0), "size": Vector3(30.0, 20.0, 16.0), "color": Color(0.04, 0.035, 0.035)},
	"whisker": 75.0,
	"ear": {"at": Vector3(40.0, 26.0, 16.0), "len": 15.0, "width": 21.0, "point": 0.15, "tilt_back": 0.5, "spread": 0.75},
	"tail": {"base": Vector3(0.0, 0.0, 262.0), "n": 8, "seg": 50.0, "radii": [36.0, 33.0, 29.0, 25.0, 20.0, 15.0, 10.5, 6.0], "carry": [0.18, 0.015], "wrap": 0.6},
	"fore": {"hip": Vector3(46.0, -38.0, -190.0), "a": 52.0, "b": 48.0, "m": 22.0, "p": 34.0, "home": Vector2(54.0, -205.0), "r": 15.0},
	"hind": {"hip": Vector3(50.0, -16.0, 175.0), "a": 66.0, "b": 64.0, "m": 40.0, "p": 52.0, "home": Vector2(60.0, 140.0), "r": 19.0},
	"fur": 14.0, "tail_fur": 0.0,
	"walk": 0.45, "trot": 0.95, "run": 2.4, "swim": 0.65,
	"stalk_from": 1.2, "spring": 0.5, "stalk_crouch": 0.3, "stalk_neck": -0.3, "eat_crouch": 0.3,
	"sit_drop": 45.0, "sit_pitch": 0.9, "lie_h": 64.0,
	"mate_secs": 20.0,
	# its head sculpted (SculptHead), from photographs: broad and flat, its
	# skull low, no stop to speak of; its eyes small, high, set forward; its
	# muzzle short, blunt, square; its whisker pads full; its nose a broad
	# bare pad
	"sculpt": {
		"z": [36.0, 24.0, 12.0, 0.0, -12.0, -24.0, -36.0, -48.0, -60.0, -72.0, -84.0],
		"top": [32.0, 39.0, 41.0, 41.0, 39.0, 35.0, 30.0, 26.0, 22.0, 18.0, 11.0],
		"bot": [-32.0, -36.0, -37.0, -36.0, -35.0, -33.0, -31.0, -29.0, -26.0, -22.0, -14.0],
		"w": [40.0, 47.0, 50.0, 50.0, 48.0, 44.0, 40.0, 36.0, 33.0, 28.0, 17.0],
		"wl": [42.0, 49.0, 53.0, 53.0, 51.0, 47.0, 43.0, 39.0, 36.0, 30.0, 18.0],
		"pw": [2.2, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.8, 2.7, 2.4],
		"eye": Vector3(24.0, 22.0, -30.0), "eye_r": 5.0, "socket": 0.6, "lid": 0.7,
		"brow": 1.0, "cheek": 2.0, "stop": 0.5, "pads": 3.6, "flews": 0.8, "nose_r": 13.0,
		"almond": 0.86, "slant": 0.0, "look_fwd": 0.7, "pupil": Vector2(0.75, 0.75),
	},
}

var _peri := 0.0 # (up on its hind legs, looking: 0..1)
var _peri_to := 0.0
var _slide_v := 0.0
var _slide_from := Vector3.ZERO
var _spraints: Array[Node3D] = []


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.16 if young_ else 0.5)
	_setup()
	dry_secs = 90.0


func _male_size() -> float:
	return 1.08 # (a male a little bigger)


func _build_extra() -> void:
	# its claws, short, dark, on every toe; its whiskers thick and white
	var claw := _mat(Color(0.12, 0.1, 0.08), 0.35)
	for i in 4:
		var paw := _legx[i][1] as MeshInstance3D
		for k in 5:
			var x := (float(k) - 2.0) * 0.2
			_stick(Vector3(x, -0.2, 0.44), Vector3(x * 1.08, -0.36, 0.58), 0.035, claw, paw)
	var wd := _mat(Color(0.88, 0.86, 0.8), 0.45)
	var sc: Dictionary = S.sculpt
	var zt := float((sc.z as Array)[(sc.z as Array).size() - 1])
	for side: float in [-1.0, 1.0]:
		for k in 6:
			var p0 := SculptScript.point(sc, zt + 16.0 + float(k % 3) * 5.0, PI * (0.4 + 0.05 * float(k / 3)) * side)
			var d := Vector3(side, 0.05 - 0.12 * float(k / 3) + 0.05 * float(k % 3), 0.45).normalized()
			_stick(p0, p0 + d * 30.0, 0.45, wd, _head)
			_stick(p0 + d * 30.0, p0 + d * 30.0 + (d + Vector3(0.0, -0.25, 0.3)).normalized() * 25.0, 0.35, wd, _head)


# --- its holt ----------------------------------------------------------------------

## Its holt: a den dug into the bank among a tree's roots, a dark way in
## (its origin at the way in, on the ground; the bank behind, -z).
static func holt() -> Node3D:
	var root := Node3D.new()
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.3, 0.24, 0.17)
	earth.roughness = 1.0
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.is_hemisphere = true
	var mound := MeshInstance3D.new()
	mound.mesh = s
	mound.material_override = earth
	mound.scale = Vector3(0.5, 0.25, 0.4)
	mound.position = Vector3(0.0, 0.0, -0.2)
	root.add_child(mound)
	var hole := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.5
	hs.height = 1.0
	hole.mesh = hs
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.03, 0.025, 0.02)
	dark.roughness = 1.0
	hole.material_override = dark
	hole.scale = Vector3(0.16, 0.12, 0.1)
	hole.position = Vector3(0.0, 0.05, 0.05)
	root.add_child(hole)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.32, 0.26, 0.2)
	bark.roughness = 0.9
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 5: # (the roots over and round it)
		var a := lerpf(-1.2, 1.2, float(k) / 4.0) + rng.randf_range(-0.15, 0.15)
		var c := CylinderMesh.new()
		c.top_radius = 0.008
		c.bottom_radius = 0.02
		c.height = 0.45
		c.radial_segments = 6
		var r := MeshInstance3D.new()
		r.mesh = c
		r.material_override = bark
		var from := Vector3(sin(a) * 0.08, 0.24, -0.24)
		var to := Vector3(sin(a) * 0.36, 0.0, cos(a) * 0.08 - 0.08)
		r.transform = Transform3D(Basis(Quaternion(Vector3.UP, (from - to).normalized())), (from + to) * 0.5)
		root.add_child(r)
	return root


func _sleep_home() -> Node3D:
	return home_den


func _home_door(h: Node3D) -> Vector3:
	return h.global_position + h.global_basis.z.normalized() * 0.12


# --- its ways ------------------------------------------------------------------------

func periscope(secs := 5.0) -> void:
	_mode = "periscope"
	_wait = secs
	_st = 0.0


func slide() -> void:
	_mode = "slide"
	_stage = 0
	_st = 0.0


func alarm() -> void:
	_mode = "alarm"
	_stage = 0
	_st = 0.0


func groom() -> void:
	if _in_water:
		ashore(groom)
		return
	_mode = "roll"
	_stage = 0
	_st = 0.0


func sleep(secs := 20.0) -> void:
	if _in_water:
		ashore(func() -> void: sleep(secs))
		return
	super(secs)


func sit(secs := 8.0) -> void:
	if _in_water:
		ashore(func() -> void: sit(secs))
		return
	super(secs)


func mark() -> void:
	if _in_water:
		ashore(mark)
		return
	super()


func _swim_leg() -> void:
	var r := rng.randf()
	if r < 0.35: # (a dive: under, along the bottom, up again a way off)
		_under_t = rng.randf_range(3.0, 7.0)
	elif r < 0.45: # (a while on its back, floating)
		_float_t = rng.randf_range(3.0, 6.0)
		_under_t = 0.0
	elif r < 0.55:
		periscope(rng.randf_range(2.0, 4.0))


func _own_think(dt: float) -> bool:
	_peri = move_toward(_peri, _peri_to, dt * 2.5)
	if _mode != "periscope":
		_peri_to = 0.0
	match _mode:
		"periscope":
			_common(dt)
			_target = _pos
			_peri_to = 1.0
			_neck_to = Vector2(0.2, 0.0)
			_sniff = 1.0
			_ears_to = 1.0
			if rng.randf() < dt * 0.8:
				_look_to = Vector2(rng.randf_range(-0.05, 0.2), rng.randf_range(-0.9, 0.9))
			if _wait <= 0.0:
				_peri_to = 0.0
				if _peri < 0.05:
					if _in_water:
						swim(_pos, 1.5)
					else:
						wander(_pos, 1.0)
			return true
		"slide":
			_common(dt)
			_slide(dt)
			return true
		"roll":
			_common(dt)
			_roll_dry(dt)
			return true
		"alarm":
			_common(dt)
			_alarm(dt)
			return true
	return false


## (Up the bank, a bound down it, onto its belly and sliding into the water.)
func _slide(dt: float) -> void:
	var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	match _stage:
		0: # (out, and a way up the bank from the water)
			if _in_water:
				_target = _nearest_bank()
				_pace = float(S.swim)
				return
			if _st <= dt * 1.5:
				var w := _nearest_water()
				var away := Vector3(_pos.x - w.x, 0.0, _pos.z - w.z)
				away = away.normalized() if away.length() > 0.01 else Vector3.RIGHT
				_slide_from = w + away * 1.8
				_slide_from.y = _pos.y
			_target = _slide_from
			_pace = float(S.trot)
			if Vector2(_pos.x - _slide_from.x, _pos.z - _slide_from.z).length() < 0.15 or _st > 12.0:
				var w := _nearest_water()
				var to := Vector3(w.x - _pos.x, 0.0, w.z - _pos.z)
				_turn_to = atan2(-to.x, -to.z)
				_target = _pos
				_stage = 1
				_st = 0.0
		1: # (turned to the water: a look, then off)
			_target = _pos
			_neck_to = Vector2(0.15, 0.0)
			if _st > 0.9 and _turn_to == INF:
				_stage = 2
				_st = 0.0
		2: # (bounding down toward it)
			_target = _pos + fwd * 2.0
			_pace = float(S.run) * 0.8
			if _st > 0.7:
				_slide_v = maxf(_speed, 1.6)
				_stage = 3
				_st = 0.0
		3: # (onto its belly, its forelegs swept back, sliding)
			_lie_to = 1.0
			_lie = move_toward(_lie, 1.0, dt * 5.0)
			_target = _pos
			_slide_v = move_toward(_slide_v, 0.9, dt * 0.6)
			_pos += fwd * _slide_v * dt
			_neck_to = Vector2(0.25, 0.0)
			_tail_mode = "out"
			if _in_water or _st > 4.0:
				_lie_to = 0.0
				_lie = 0.0
				_slide_v = 0.0
				swim(_pos, 1.5)


## (Rolling on the bank, over and over, rubbing its coat dry; then sat up,
## licking and combing it.)
func _roll_dry(dt: float) -> void:
	_target = _pos
	match _stage:
		0:
			_lie_to = 1.0
			_lie = move_toward(_lie, 1.0, dt * 2.0)
			_spin = PI * 0.92 * sin(_st * 1.7) * smoothstep(0.0, 0.8, _st) * (1.0 - smoothstep(7.0, 8.0, _st))
			_neck_to = Vector2(-0.3, 0.6 * sin(_st * 2.3))
			_wiggle = 1.0
			if _st > 8.0:
				_spin = 0.0
				_stage = 1
				_st = 0.0
		1:
			_sit_to = 1.0
			_lie_to = 0.0
			var ph := fmod(_st, 9.0)
			if ph < 3.0:
				_lick = 1.0
				_neck_to = Vector2(-0.45, 0.0)
			elif ph < 6.0:
				_lick = 0.6
				_neck_to = Vector2(-0.1, 0.25 * sin(_st * 2.0))
			else:
				_lick = 1.0
				_neck_to = Vector2(-0.5, 1.3)
			if _st > 9.0:
				wander(_pos, 1.0)


## (A snort, up to look; a dash for the water; under, away; up again.)
func _alarm(dt: float) -> void:
	match _stage:
		0:
			_target = _pos
			_peri_to = 1.0
			_jaw_to = 0.25 if _st < 0.3 else 0.0
			_ears_to = 1.0
			if _st > 1.3:
				_peri_to = 0.0
				_stage = 1
				_st = 0.0
		1:
			if not _in_water:
				_target = _nearest_water()
				_pace = float(S.run)
				if _target == _pos:
					wander(_pos, 1.0)
				return
			var away := _water_point(_pos, 2.0)
			_target = away
			_stage = 2
			_st = 0.0
		2:
			_dive_to = 1.0
			_pace = float(S.swim) * 1.6
			if _pos.distance_to(_target) < 0.2:
				_target = _water_point(_pos, 2.0)
			if _st > 5.0:
				_dive_to = 0.0
				_stage = 3
				_st = 0.0
		3:
			_target = _pos
			_neck_to = Vector2(0.35, 0.0)
			if _dive < 0.05:
				periscope(2.5)


func _eat_pose(_dt: float) -> void:
	_lie_to = 1.0
	_neck_to = Vector2(-0.75 + 0.15 * maxf(sin(_st * 1.3), 0.0), 0.0) # (its head down to it, a tug now and then)


## (Its catch pinned to the ground under its forepaws, before its chest,
## along it, its head end to its mouth.)
func _hold_food(_dt: float) -> void:
	var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var m := _mouth()
	var len_ := PersonalSpace._dims(_food).x if _food is Node3D else 0.2
	var at := Vector3(m.x, 0.0, m.z) - fwd * len_ * 0.25
	at.y = _ground(at.x, at.z) + 0.012
	_food.global_transform = Transform3D(Basis(Vector3.UP, _yaw) * Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(_food.scale), (get_parent() as Node3D).to_global(at) if get_parent() is Node3D else at)
	var inv := (transform * _body.transform).affine_inverse()
	for i: int in [0, 1]:
		var side := 1.0 if i == 1 else -1.0
		var paw := at - fwd * len_ * 0.15 + Vector3(cos(_yaw), 0.0, -sin(_yaw)) * side * 0.03
		paw.y = _ground(paw.x, paw.z) + 0.02
		_pose_foot[i] = inv * paw


## (Its spraint: crouched, its tail up, treading; left on the ground.)
func _mark(_dt: float) -> void:
	_crouch = move_toward(_crouch, 0.35, _dt * 2.0)
	if _st > 1.6 and _st - _dt <= 1.6:
		var at := _out(Vector3(0.0, -body_h, float(S.body_len) * 0.55))
		var sp := Node3D.new()
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.16, 0.13, 0.1)
		m.roughness = 0.6
		for k in 3:
			var mi := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.5
			s.height = 1.0
			s.radial_segments = 8
			s.rings = 4
			mi.mesh = s
			mi.material_override = m
			mi.scale = Vector3(0.016, 0.011, 0.03) * rng.randf_range(0.8, 1.2)
			mi.position = Vector3(rng.randf_range(-0.012, 0.012), 0.005, rng.randf_range(-0.02, 0.02))
			mi.rotation.y = rng.randf() * TAU
			sp.add_child(mi)
		var scales := StandardMaterial3D.new() # (the fish scales in it, glinting)
		scales.albedo_color = Color(0.75, 0.75, 0.7)
		scales.metallic = 0.6
		scales.roughness = 0.25
		for k in 5:
			var mi := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(0.004, 0.0005, 0.004)
			mi.mesh = b
			mi.material_override = scales
			mi.position = Vector3(rng.randf_range(-0.015, 0.015), 0.011, rng.randf_range(-0.025, 0.025))
			mi.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, 0.0)
			sp.add_child(mi)
		get_parent().add_child(sp)
		sp.global_position = Vector3(at.x, _ground(at.x, at.z), at.z)
		_spraints.append(sp)
		if _spraints.size() > 6:
			var old: Node3D = _spraints.pop_front()
			if is_instance_valid(old):
				old.queue_free()


# --- its pose ----------------------------------------------------------------------

func _pose(dt: float) -> void:
	super(dt)
	var e := _peri * _peri * (3.0 - 2.0 * _peri)
	if e > 0.001:
		# (up on its hind legs: its body near upright, its forepaws hanging at
		# its chest; in the water, treading it, its head and neck high)
		var up := 1.2 if not _in_water else 0.85
		_pitch = lerpf(_pitch, up, e)
		var hip_z := float((S.hind as Dictionary).hip.z)
		if not _in_water:
			_lift = lerpf(_lift, 55.0 + hip_z * sin(_pitch) - body_h, e)
		else:
			_lift = lerpf(_lift, float(S.body_len) * 0.18, e)
		_neck_to = Vector2(_neck_to.x, _neck_to.y)
		_neck.rotation.x -= _pitch * 0.55 * e
		for i in 2:
			var L: Dictionary = legs[0]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			_pose_foot[i] = Vector3(hp.x * side * 0.75, hp.y - float(L.f) * 0.9, hp.z - float(L.f) * 0.55 + 8.0 * sin(_t * 3.0 + i))
		if not _in_water:
			for i: int in [2, 3]:
				var side := 1.0 if i % 2 == 1 else -1.0
				var hm: Vector2 = (legs[1] as Dictionary).home
				_pose_foot[i] = _ground_at(Vector3(hm.x * side, 0.0, float((S.hind as Dictionary).hip.z) + 25.0))
	if _mode == "slide" and _stage == 3:
		# (its forelegs swept back along its chest, its hind legs trailing)
		for i in 4:
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			var gy := -(body_h * (1.0 - 0.45 * _crouch) + _lift)
			if i < 2:
				_pose_foot[i] = Vector3(hp.x * side * 1.05, gy + 20.0, hp.z + float(L.f) * 1.3)
			else:
				_pose_foot[i] = Vector3(hp.x * side * 0.8, gy + 22.0, hp.z + float(L.f) * 1.6)
	if _mode == "roll" and _stage == 0:
		for i in 4: # (its feet pawing the air, rolled over)
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			_pose_foot[i] = Vector3(hp.x * side * 1.2, hp.y - float(L.f) * 0.8 + 15.0 * sin(_t * 5.0 + i * 1.7), hp.z + (-1.0 if i < 2 else 1.0) * float(L.f) * 0.5)
	if _mode == "eat_held" and _stage == 1: # (its head tilted, crunching with its back teeth)
		_head.rotation.z = 0.35 * sin(_st * 0.9)


func _pose_tail(dt: float) -> void:
	super(dt)
	if _mode == "mark": # (up, out of the way)
		var r: Vector3 = _tail[0].rotation
		_tail[0].rotation = Vector3(lerpf(r.x, -0.5, 0.5), r.y, 0.0)
	var e := _peri * _peri * (3.0 - 2.0 * _peri)
	if e > 0.001 and not _in_water: # (up on its hind legs: its tail out along the ground behind, a prop)
		var r0: Vector3 = _tail[0].rotation
		_tail[0].rotation = Vector3(lerpf(r0.x, _pitch * 0.95, e), r0.y, 0.0)


# --- steering (pilot.gd) -----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["periscope", "slide", "alarm"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"periscope":
			periscope(float(args.get("seconds", 5.0)))
		"slide":
			slide()
		"alarm":
			alarm()
		_:
			return super(name, args)
	return true


func _p_act_done(name: String) -> bool:
	if name in ["periscope", "slide", "alarm"]:
		return _mode != name
	if name == "groom":
		return _mode not in ["roll", "ashore"]
	return super(name)
