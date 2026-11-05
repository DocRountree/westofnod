class_name Bison
extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## An American bison (Bison bison), life size (a bull 3 m long, 1.8 m at
## the hump; a cow a little smaller), on the four-legged make the hunters
## share (Carnivore: its gaits, its legs, its head and tail, its fur), but
## a grazer's ways: its great hump over its shoulders, its head huge and
## carried low, its short black horns curving up and in, its beard; its
## head, hump, shoulders and forelegs in long dark shaggy wool, its
## hindquarters lighter, browner, short; small eyes set wide, their pupils
## bars; its legs slender under it, on cloven black hooves; its tail thin,
## tufted, hanging. A calf (Bison.new(true)): red orange, no hump yet, no
## horns; up on its feet soon after it's born, at its mother's side,
## suckling. (The coat: carnivore.gdshader's species 6.)
##
## - wander(centre, radius), graze(centre, radius): head down, cropping the
##   grass, chewing, stepping on a little
## - ruminate(secs) (sleep): lying, chewing its cud
## - wallow(): down, rolling in the dust on its side and its back, its
##   legs kicking, a cloud of dust; up, and a shake
## - bellow(): (a bull's) its head up a little, its mouth open, roaring,
##   its tail up
## - spar(him): (a bull's) to another bull, heads down, butting, pushing
##   one another back and forth, horns locked
## - stampede(from): away at a gallop, its tail up
## - birth(): (a cow's) lying, the calf born, licked; the calf struggling
##   up onto its feet, then to her side, suckling at her udder; following her
## - mate(her): the bull tending her (following, his chin on her rump);
##   then on her, briefly
## Steering (pilot.gd): act graze {centre, radius}, ruminate {seconds},
## wallow, bellow, spar {with}, stampede {from}, birth (a cow's), mate
## {partner}.

const SPEC := {
	"male_parts": {"sheath": [250.0, 600.0, 32.0], "tuft": 170.0, "scrotum": [800.0, 70.0, 1.0]}, # (a grown male's: Carnivore._build_male)
	"brace": 0.72, # (mounted, his hind feet nearer under his rump)
	"species": 6, "hooves": true,
	"body": [[-1050.0, 100.0, 200.0, 300.0], [-900.0, 215.0, 330.0, 585.0], [-600.0, 260.0, 380.0, 640.0], [-250.0, 165.0, 360.0, 535.0],
			[200.0, 60.0, 320.0, 400.0], [600.0, 70.0, 300.0, 360.0], [900.0, 60.0, 230.0, 270.0], [1000.0, 40.0, 100.0, 100.0]],
	"body_h": 1050.0, "body_len": 2000.0, "body_w": 360.0,
	"hump": [Vector3(0.0, 560.0, -640.0), Vector3(520.0, 620.0, 950.0)],
	"neck_at": Vector3(0.0, 0.0, -950.0), "neck": [[50.0, 0.0, 260.0, 350.0], [-150.0, -30.0, 230.0, 310.0], [-280.0, -60.0, 200.0, 260.0]], "neck_pitch": -0.35,
	"head_at": Vector3(0.0, -40.0, -270.0),
	"head": [[60.0, 0.0, 190.0, 230.0], [-80.0, -20.0, 205.0, 235.0], [-220.0, -60.0, 175.0, 195.0], [-360.0, -110.0, 140.0, 150.0], [-450.0, -140.0, 120.0, 118.0], [-480.0, -150.0, 80.0, 80.0]],
	"jaw_at": Vector3(0.0, -226.7, -192.0), "jaw": [[0.0, 0.0, 84.2, 55.2], [-91.0, -18.7, 99.2, 56.7], [-182.0, -17.1, 67.7, 44.0]], "mouth": 3.0,
	"mouth_z": -1700.0,
	"eye": {"at": Vector3(150.0, 30.0, -200.0), "size": Vector3(36.0, 30.0, 38.0), "color": Color(0.16, 0.1, 0.06), "slit": 0.22},
	"nose": {"at": Vector3(0.0, -135.0, -478.0), "size": Vector3(130.0, 90.0, 60.0), "color": Color(0.06, 0.05, 0.05)},
	"whisker": 0.0,
	"ear": {"at": Vector3(165.0, 70.0, -40.0), "len": 110.0, "width": 90.0, "point": 0.8, "tilt_back": 0.6, "spread": 1.1},
	"tail": {"base": Vector3(0.0, 90.0, 1000.0), "n": 5, "seg": 110.0, "radii": [40.0, 32.0, 26.0, 24.0, 40.0], "carry": [1.25, 0.04], "wrap": 0.2},
	"fore": {"hip": Vector3(230.0, -250.0, -700.0), "a": 450.0, "b": 420.0, "m": 300.0, "p": 110.0, "home": Vector2(240.0, -770.0), "r": 75.0},
	"hind": {"hip": Vector3(230.0, -150.0, 750.0), "a": 520.0, "b": 480.0, "m": 380.0, "p": 110.0, "home": Vector2(240.0, 820.0), "r": 85.0},
	"fur": 60.0, "tail_fur": 45.0,
	"walk": 1.1, "trot": 3.2, "run": 15.0,
	"stalk_from": 6.0, "spring": 2.5, "stalk_crouch": 0.1, "stalk_neck": -0.2, "eat_crouch": 0.0,
	"sit_drop": 300.0, "sit_pitch": 0.3, "lie_h": 480.0,
	"mate_secs": 6.0,
	# its head sculpted (SculptHead), from photographs: massive, carried low; its forehead broad and flat under its wool, its face long and deep; its muzzle broad, its nose wide and black; its eyes set far out on its head's sides
	"sculpt": {
		"z": [60.0, 20.0, -20.0, -70.0, -120.0, -180.0, -240.0, -300.0, -360.0, -420.0, -478.0],
		"top": [200.0, 228.0, 232.0, 222.0, 196.0, 155.0, 108.0, 62.0, 22.0, -14.0, -50.0],
		"bot": [-200.0, -240.0, -255.0, -258.0, -256.0, -250.0, -244.0, -238.0, -232.0, -226.0, -210.0],
		"w": [170.0, 205.0, 210.0, 200.0, 185.0, 165.0, 145.0, 128.0, 115.0, 105.0, 85.0],
		"wl": [175.0, 210.0, 215.0, 205.0, 185.0, 160.0, 140.0, 124.0, 112.0, 102.0, 85.0],
		"pw": [2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.6, 2.6, 2.5, 2.3],
		"eye": Vector3(145.0, 20.0, -190.0), "eye_r": 18.0, "socket": 2.5, "lid": 2.5,
		"brow": 12.0, "cheek": 6.0, "stop": 3.0, "pads": 0.0, "flews": 2.00, "nose_r": 70.0,
		"almond": 0.62, "slant": 0.05, "look_fwd": 0.45, "pupil": Vector2(0.35, 0.90),
	},
}

var _rival: Node3D
var _dust: Array[MeshInstance3D] = []
var _calf_t := -1.0 # (a newborn calf: s since it was born; -1 up and about)


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.2 if young_ else 0.5)
	_setup()


func _male_size() -> float:
	return 1.12 # (a bull bigger than a cow)


func _build_extra() -> void:
	# the hump, its wool long; the beard (the neck and the head shaggy:
	# _part_coat)
	var body := _torso.material_override as ShaderMaterial
	body.set_shader_parameter("fur_front", 1.6)
	body.set_shader_parameter("front_z", -350.0)
	var front := _part_coat("neck", body)
	front.set_shader_parameter("skin", false) # (the hump: its own part, not the skin's)
	if not young:
		# (its hump: the skin's own, in its body's rings)
		# the beard, under its chin
		var face := _coat(1)
		_fur_shells(_part(Vector3(0.0, -230.0, -280.0), Vector3(150.0, 220.0, 200.0), face, _head), 90.0, 9)
		# its horns: short, black, out from the sides of its head, curving
		# up and in
		var horn := _coat(7)
		for side: float in [-1.0, 1.0]:
			var p := Vector3(150.0 * side, 120.0, -70.0)
			var d := Vector3(side, 0.15, -0.1).normalized()
			var r := 34.0
			for k in 11: # (smooth: short steps, tapering)
				var q := p + d * 24.0
				_stick(p, q, r, horn, _head)
				_part(q, Vector3.ONE * r * 2.0 * 0.88, horn, _head) # (the joint rounded over)
				p = q
				d = (d + Vector3(-side * 0.17, 0.24, 0.0)).normalized()
				r *= 0.88
	# its hooves: cloven (the walker's paws' pads: two halves, no claws)
	for i in 4:
		var pw := _legx[i][1] as MeshInstance3D
		for c in pw.get_children():
			c.queue_free()
		for side: float in [-1.0, 1.0]:
			_part(Vector3(0.18 * side, -0.05, 0.25), Vector3(0.48, 0.9, 0.7), _coat(4), pw)


## (Its neck and head: all of them the shaggy front, the wool long.)
var _front_m: Dictionary = {}

func _part_coat(name: String, m: ShaderMaterial) -> ShaderMaterial:
	var key := name if name == "head" else "neck"
	if not _front_m.has(key):
		var fm := m.duplicate() as ShaderMaterial
		fm.set_shader_parameter("front_z", 1e5)
		fm.set_shader_parameter("fur_front", 1.3 if key == "head" else 1.6)
		_front_m[key] = fm
	return _front_m[key]


# --- its ways ----------------------------------------------------------------------

func graze(centre: Vector3, radius: float) -> void:
	_mode = "graze"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_stage = 0


func ruminate(secs := 20.0) -> void:
	_mode = "ruminate"
	_wait = secs
	_st = 0.0


## (Its sleep: lying, chewing its cud.)
func sleep(secs := 20.0) -> void:
	ruminate(secs)


func wallow() -> void:
	_mode = "wallow"
	_st = 0.0
	_stage = 0


## (Its grooming: a wallow.)
func groom() -> void:
	wallow()


func bellow() -> void:
	_mode = "bellow"
	_st = 0.0


func spar(rival: Node3D) -> void:
	if rival == null or rival == self:
		return
	_mode = "spar"
	_rival = rival
	_stage = 0
	_st = 0.0


func stampede(from: Vector3) -> void:
	_mode = "stampede"
	_st = 0.0
	_wait = 0.0
	_centre = from


## (A cow's.) One calf, in the open.
func birth(_n := 1, _den: Node3D = null) -> void:
	if young or male:
		return
	_mode = "birth"
	_born_left = 1
	home_den = null
	_stage = 0
	_st = 0.0


## (Its mark: horning the ground, then a wallow.)
func mark() -> void:
	wallow()


func _think(dt: float) -> void:
	if young and _calf_t >= 0.0:
		_newborn(dt)
		return
	match _mode:
		"graze":
			_common(dt)
			_neck_to = Vector2(-1.1, 0.12 * sin(_st * 0.5))
			_chew = 1.0
			_jaw_to = 0.08 * maxf(sin(_st * 5.0), 0.0)
			_tail_mode = "carry"
			if _wait <= 0.0: # (a step or two on, cropping as it goes)
				var a := rng.randf() * TAU
				_target = _pos + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.4, 1.2) * size / 0.5
				if _target.distance_to(_centre) > _radius:
					_target = _centre + (_target - _centre).normalized() * _radius * 0.8
				_pace = float(S.walk) * 0.3
				_wait = rng.randf_range(4.0, 9.0)
			return
		"ruminate":
			_common(dt)
			_target = _pos
			_lie_to = 1.0
			_chew = 1.0
			_jaw_to = 0.06 * maxf(sin(_st * 2.5), 0.0) # (chewing its cud, slowly)
			_neck_to = Vector2(-0.1, 0.2 * sin(_st * 0.2))
			if _wait <= 0.0:
				_lie_to = 0.0
				if _lie < 0.05:
					graze(_pos, 3.0)
			return
		"wallow":
			_common(dt)
			_wallow(dt)
			return
		"bellow":
			_common(dt)
			_target = _pos
			var k := fmod(_st, 4.0)
			_neck_to = Vector2(0.35 if k < 2.2 else 0.0, 0.0)
			_jaw_to = 0.4 if k > 0.4 and k < 2.0 else 0.0
			_tail_mode = "out" if k < 2.2 else "carry"
			if _st > 8.0:
				graze(_pos, 3.0)
			return
		"spar":
			_common(dt)
			_spar(dt)
			return
		"suckle":
			_common(dt)
			_suckle(dt)
			return
		"stampede":
			_common(dt)
			_tail_mode = "out"
			_ears_to = -0.5
			if _wait <= 0.0:
				var away := _pos - _centre
				away.y = 0.0
				away = (away.normalized() if away.length() > 0.01 else Vector3.FORWARD).rotated(Vector3.UP, rng.randf_range(-0.4, 0.4))
				_target = _pos + away * 6.0
				_wait = 2.0
			_pace = float(S.run) * 0.6 * lerpf(0.35, 1.0, size)
			if _st > 6.0:
				_pace = -1.0
				graze(_pos, 3.0)
			return
	super(dt)


func _common(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 2.0)
	_ears_to = 0.0
	_jaw_to = 0.0
	_neck_to = Vector2.ZERO
	_sit_to = 0.0
	if _mode not in ["ruminate", "wallow"]:
		_lie_to = 0.0
	if _mode not in ["graze", "stampede"]:
		_pace = -1.0


func _wallow(dt: float) -> void:
	_target = _pos
	match _stage:
		0: # (horning, pawing the ground)
			_neck_to = Vector2(-1.2, 0.3 * sin(_st * 3.0))
			if _st > 2.0:
				_stage = 1
				_st = 0.0
		1: # (down, and over onto its side, its back; its legs kicking; dust)
			_lie_to = 1.0
			if _lie > 0.8:
				_roll = lerpf(_roll, (PI * 0.75) * maxf(sin(_st * 1.6), 0.0), 1.0 - exp(-4.0 * dt))
				if fmod(_st, 0.4) < dt:
					_puff()
			if _st > 7.0:
				_roll = 0.0
				_lie_to = 0.0
				_stage = 2
				_st = 0.0
		2: # (up, and a shake)
			if _lie < 0.05:
				_roll = 0.12 * sin(_st * 25.0) * maxf(1.0 - _st, 0.0)
				if _st > 1.2:
					_roll = 0.0
					graze(_pos, 3.0)
	for d in _dust:
		if is_instance_valid(d):
			var a := float(d.get_meta("t")) + dt
			d.set_meta("t", a)
			d.scale = Vector3.ONE * (0.4 + a * 1.2) * size / 0.5
			var dm := d.material_override as StandardMaterial3D
			dm.albedo_color.a = maxf(0.35 - a * 0.15, 0.0)
			if a > 2.4:
				d.queue_free()


func _puff() -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.54, 0.42, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.set_meta("t", 0.0)
	get_parent().add_child(mi)
	mi.position = _pos + Vector3(rng.randf_range(-0.6, 0.6), 0.3, rng.randf_range(-0.6, 0.6)) * size / 0.5
	_dust.append(mi)


func _spar(dt: float) -> void:
	if not is_instance_valid(_rival):
		graze(_pos, 3.0)
		return
	var rp: Vector3 = _rival.get("_pos")
	var to := rp - _pos
	to.y = 0.0
	var gap := float(S.body_len) * 0.62 * MM * size # (head to head)
	match _stage:
		0: # (to him, facing him)
			_target = rp - to.normalized() * gap
			if to.length() < gap * 1.1:
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
				if _rival.get("_mode") != "spar":
					_rival.call("spar", self)
		1: # (heads down, butting, pushing back and forth, horns locked)
			_neck_to = Vector2(-0.85, 0.0)
			_crouch = 0.3
			var push := sin(_st * 1.4) * 0.15 * size / 0.5
			var at := rp - to.normalized() * (gap * 0.95)
			_target = at + to.normalized() * push
			_pace = float(S.walk) * 0.6
			if fmod(_st, 3.0) < dt: # (a clash)
				_neck_to = Vector2(-1.0, 0.0)
			if _st > 10.0:
				_crouch = 0.0
				_pace = -1.0
				graze(_pos, 3.0)


func _birth(dt: float) -> void:
	match _stage:
		0: # (lying, labouring)
			_target = _pos
			_lie_to = 1.0
			_neck_to = Vector2(-0.2, 1.2)
			if _st > 4.0 and _born_left > 0:
				_born_left = 0
				_young_one()
				_stage = 1
				_st = 0.0
		1: # (up, licking it)
			_lie_to = 0.0
			_neck_to = Vector2(-0.9, 0.6 * sin(_st * 0.5))
			_lick = 1.0
			if _st > 25.0:
				graze(_pos, 2.0)


func _young_one() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var y: Node3D = (get_script() as Script).new(true)
	parent.add_child(y)
	var at := _out(Vector3(-float(S.body_w) * 1.6, -body_h, 300.0))
	y.call("place", Vector3(at.x, _pos.y, at.z), _yaw + 1.2)
	y.set("height", height)
	y.set("_mother", self)
	y.set("_calf_t", 0.0)
	y.call("grow", 0.5, 500.0)
	young_ones.append(y)


## (A newborn calf: lying, wet; struggling up onto its feet, its forelegs
## first; then to her, at her side, suckling.)
func _newborn(dt: float) -> void:
	_calf_t += dt
	_st += dt
	_target = _pos
	if _calf_t < 6.0:
		_lie_to = 1.0
		_neck_to = Vector2(0.1 * sin(_calf_t * 2.0), 0.3 * sin(_calf_t * 0.8))
	elif _calf_t < 14.0: # (up: its hind end first, wobbling)
		_lie_to = 0.0
		_roll = 0.08 * sin(_calf_t * 7.0) * (14.0 - _calf_t) / 8.0
	else:
		_roll = 0.0
		_calf_t = -1.0
		_mode = "suckle"


## (Hers: standing for it, the calf come to her udder, suckling.)
func _nurse(_dt: float) -> void:
	_target = _pos
	_neck_to = Vector2(-0.6, 0.9 * sin(_st * 0.3)) # (round to it, licking)
	_lick = 0.5
	for y in young_ones:
		if is_instance_valid(y) and float(y.get("_calf_t")) < 0.0 and y.get("_mode") != "suckle":
			y.set("_mode", "suckle")
			y.set("_st", 0.0)
	if _st > 14.0:
		graze(_pos, 3.0)


func _suckle(dt: float) -> void:
	if not is_instance_valid(_mother):
		wander(_pos, 2.0)
		return
	var udder: Vector3 = _mother.call("_out", Vector3(-float(S.body_w) * 0.7, -float(_mother.get("body_h")), 520.0))
	_target = udder
	if _pos.distance_to(udder) < 0.25:
		_target = _pos
		var mp: Vector3 = _mother.get("_pos")
		var to := mp - _pos
		_turn_to = atan2(-to.x, -to.z) + 0.3
		_neck_to = Vector2(0.5, 0.0) # (its head up under her)
		_tail_mode = "wag"
	if _st > 12.0:
		_mode = "follow"
		_st = 0.0


## (A calf's: alone, no litter to play with: a run and a buck.)
func play() -> void:
	if not young or _calf_t >= 0.0:
		return
	_mode = "play"
	_stage = 0
	_st = 0.0


func _play(dt: float) -> void:
	# (a calf's: a sudden run and a buck, kicking up its heels)
	match _stage:
		0:
			var a := rng.randf() * TAU
			_target = _pos + Vector3(cos(a), 0.0, sin(a)) * 3.0 * size / 0.5
			_pace = float(S.trot) * 0.8
			_stage = 1
			_st = 0.0
		1:
			_tail_mode = "out"
			if fmod(_st, 1.1) < dt and not airborne:
				_leap(_pos + Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * 0.4, 1.0)
			if _st > 4.0:
				_pace = -1.0
				_mode = "follow" if is_instance_valid(_mother) else "wander"


func _court_secs() -> float:
	return 6.0 # (tending her: following, his chin on her rump)


func _mount() -> Dictionary:
	var inv := (transform * _body.transform).affine_inverse()
	var free := {}
	for i: int in [2, 3]:
		var side := 1.0 if i % 2 == 1 else -1.0
		var w: Vector3 = _mate.call("_out", Vector3(float(S.body_w) * 0.6 * side, -body_h, float(S.body_len) * 0.62))
		w.y = _ground(w.x, w.z)
		free[i] = inv * w
	return {"at": Vector3(0.0, float(S.body_h) * 0.69, float(S.body_len) * 0.5), "basis": Basis(Vector3.RIGHT, 0.6), "grips": {
		0: Vector3(-float(S.body_w) * 0.9, 0.0, 400.0), 1: Vector3(float(S.body_w) * 0.9, 0.0, 400.0)}, "free": free}


func _mating(dt: float) -> void:
	super(dt)
	if _mate_role == "male" and _mate_stage == "court":
		var rump: Vector3 = _mate.call("_out", _behind_her(0.75)) # (his chin on her rump)
		_target = Vector3(rump.x, _pos.y, rump.z)
		_neck_to = Vector2(0.2, 0.0) # (his chin up on her rump)


func _after_mate() -> void:
	graze(_pos, 3.0)


func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["graze", "ruminate", "wallow", "stampede"])
	if young:
		b.append("play")
		return b
	b.append("mate")
	if male:
		b.append_array(PackedStringArray(["bellow", "spar"]))
	else:
		b.append("birth")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"graze":
			graze(args.get("centre", _pos), float(args.get("radius", 3.0)))
		"ruminate":
			ruminate(float(args.get("seconds", 20.0)))
		"wallow":
			wallow()
		"bellow":
			bellow()
		"spar":
			var w: Node3D = args.get("with")
			if w == null:
				return false
			spar(w)
		"stampede":
			stampede(args.get("from", _pos + _p_heading()))
		"birth":
			birth()
		"play":
			play()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	if name in ["graze", "ruminate", "wallow", "bellow", "spar", "stampede", "birth", "play"]:
		return _mode != name
	return false
