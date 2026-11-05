class_name Moose
extends "res://scripts/creatures/deer.gd" # (by path: found whether or not the editor has seen the class yet)
## A moose (Alces alces americana), life size (a bull about 3 m long and
## 1.9 m at the shoulder, a cow a little smaller), on the deer's make and
## ways (Deer: grazing and browsing, bedding, the alert, flight, grooming, a
## bull's rub and scrape and sparring, a cow's calving and nursing, the
## mating), but its own: a short deep body high in front over a hump of
## muscle at the shoulders, very long legs; a short thick neck; its head
## long and heavy, the muzzle broad and overhanging, its upper lip great
## and mobile, its nostrils big; small eyes set high; long ears; the bell (a
## flap of hair-covered skin) hanging from its throat; a stub of a tail. Its
## coat a bull's near black, his face dark; a cow's browner, her face paler,
## grey brown, a pale patch under her tail; the legs pale grey brown below
## (the stockings); a bull a fifth bigger, his bell longer; a calf (Moose.new(true)) red brown,
## unspotted. A bull's antlers broad flat palms out from his head's sides,
## each fringed with points along its edge, a smaller brow palm before it
## (in velvet in summer, brown and thick; hard and pale in winter).
##
## Its own way (and the deer's, above): wade(at): out into the water, its
## head down under to the plants on the bottom, up again streaming, chewing,
## down again. Its world: wet (x, z) -> whether it's water there, water_y.
## Steering (pilot.gd): the deer's, and act wade {at}.

const MOOSE := {
	"male_parts": {"sheath": [300.0, 700.0, 30.0], "tuft": 90.0, "scrotum": [880.0, 60.0, 0.9]}, # (a grown bull's: Carnivore._build_male)
	"brace": 0.74,
	"species": 13, "hooves": true,
	"body": [[-1000.0, 80.0, 230.0, 320.0], [-850.0, 120.0, 330.0, 520.0], [-550.0, 140.0, 370.0, 560.0], [-150.0, 40.0, 350.0, 480.0],
			[250.0, 30.0, 330.0, 440.0], [600.0, 60.0, 300.0, 400.0], [850.0, 70.0, 210.0, 260.0], [960.0, 60.0, 80.0, 80.0]],
	"body_h": 1450.0, "body_len": 1960.0, "body_w": 350.0,
	"neck_at": Vector3(0.0, 260.0, -950.0), "neck": [[60.0, 0.0, 200.0, 300.0], [-200.0, -20.0, 160.0, 240.0], [-380.0, -20.0, 140.0, 200.0], [-450.0, -20.0, 130.0, 180.0]], "neck_pitch": 0.35,
	"head_at": Vector3(0.0, 0.0, -450.0),
	"head": [[80.0, 0.0, 120.0, 140.0], [-60.0, 10.0, 130.0, 160.0], [-210.0, -10.0, 95.0, 140.0], [-370.0, -15.0, 80.0, 125.0], [-500.0, -20.0, 85.0, 120.0], [-560.0, -20.0, 60.0, 90.0]],
	"jaw_at": Vector3(0.0, -143.8, -152.0), "jaw": [[0.0, 0.0, 55.6, 42.8], [-159.8, -0.3, 61.7, 46.1], [-319.6, -17.5, 56.3, 46.6]], "mouth": 2.4,
	"mouth_z": -1950.0,
	"eye": {"at": Vector3(95.0, 70.0, -150.0), "size": Vector3(34.0, 30.0, 36.0), "color": Color(0.06, 0.04, 0.03), "slit": 0.25},
	"nose": {"at": Vector3(0.0, -60.0, -560.0), "size": Vector3(90.0, 60.0, 50.0), "color": Color(0.1, 0.08, 0.07)},
	"whisker": 40.0,
	"ear": {"at": Vector3(88.0, 132.0, 78.0), "len": 260.0, "width": 130.0, "point": 0.6, "tilt_back": 0.35, "spread": 0.9},
	"tail": {"base": Vector3(0.0, 60.0, 950.0), "n": 3, "seg": 60.0, "radii": [55.0, 50.0, 34.0], "carry": [1.3, 0.05], "wrap": 0.2},
	"fore": {"hip": Vector3(190.0, -250.0, -760.0), "a": 420.0, "b": 560.0, "m": 520.0, "p": 120.0, "home": Vector2(200.0, -800.0), "r": 70.0},
	"hind": {"hip": Vector3(170.0, -100.0, 780.0), "a": 520.0, "b": 640.0, "m": 560.0, "p": 120.0, "home": Vector2(190.0, 830.0), "r": 75.0},
	"fur": 22.0, "tail_fur": 30.0,
	"walk": 1.5, "trot": 4.0, "run": 14.0,
	"stalk_from": 8.0, "spring": 3.0, "stalk_crouch": 0.1, "stalk_neck": 0.0, "eat_crouch": 0.0,
	"sit_drop": 700.0, "sit_pitch": 0.15, "lie_h": 650.0,
	"mate_secs": 6.0,
	# its head sculpted (SculptHead), from life: long and heavy, its brow broad; the
	# muzzle overhanging, swollen, its upper lip great; its nostrils big; its eyes
	# small, set high and back
	"sculpt": {
		"z": [80.0, 40.0, 0.0, -60.0, -130.0, -210.0, -290.0, -370.0, -440.0, -500.0, -560.0],
		"top": [90.0, 150.0, 170.0, 168.0, 150.0, 130.0, 118.0, 113.0, 113.0, 110.0, 82.0],
		"bot": [-90.0, -150.0, -175.0, -175.0, -165.0, -150.0, -140.0, -138.0, -142.0, -152.0, -126.0],
		"w": [80.0, 125.0, 135.0, 125.0, 105.0, 88.0, 78.0, 76.0, 80.0, 84.0, 62.0],
		"wl": [85.0, 130.0, 140.0, 130.0, 108.0, 90.0, 80.0, 80.0, 88.0, 94.0, 66.0],
		"pw": [2.0, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.6, 2.5, 2.2],
		"eye": Vector3(92.0, 74.0, -150.0), "eye_r": 20.0, "socket": 3.0, "lid": 3.0,
		"brow": 7.0, "cheek": 6.0, "stop": 2.0, "pads": 5.0, "flews": 7.0, "nose_r": 34.0,
		"almond": 0.62, "slant": 0.04, "look_fwd": 0.3, "pupil": Vector2(0.35, 0.9),
	},
}

var wet: Callable ## (x, z) -> whether it's water there
var water_y := 0.0
var _wade_at := Vector3.ZERO
var _bell: MeshInstance3D


func _spec() -> Dictionary:
	return MOOSE


func _young_size() -> float:
	return 0.16


func _male_size() -> float:
	return 1.2 # (a bull a fifth again a cow's size, his hump and neck the heavier for it)


func _coat(part: int, along := 0.0) -> ShaderMaterial:
	var m := super(part, along)
	m.set_shader_parameter("muzzle_z", -400.0)
	return m


func _build_extra() -> void:
	super() # (its hooves; a bull's antlers: _grow_antlers, its own)
	# the bell: a flap of skin and hair hanging from its throat (a bull's longest)
	var bl := (380.0 if male else 220.0) * (0.3 if young else 1.0)
	_bell = _part(Vector3(0.0, -150.0 - bl * 0.45, -300.0), Vector3(60.0, bl, 90.0), _coat(8), _neck)
	_bell.rotation.x = -0.3


## A bull's antlers: from each pedicle a short beam out, then the broad palm,
## turned up and back, its edge fringed with points; the brow palm before it.
func _grow_antlers() -> void:
	var m := _coat(7)
	var thick := 1.2 if season == 0 else 1.0
	for side: float in [-1.0, 1.0]:
		var base := Vector3(80.0 * side, 160.0, 20.0)
		_part(base, Vector3(60.0, 40.0, 60.0) * thick, m, _head) # (the burr)
		var out := base + Vector3(150.0 * side, 40.0, 30.0)
		_stick(base, out, 32.0 * thick, m, _head)
		# the palm: a broad plate out and back, tilted up
		var palm := Node3D.new()
		palm.position = out + Vector3(230.0 * side, 90.0, 80.0)
		palm.rotation = Vector3(-0.35, -0.35 * side, 0.55 * side)
		_head.add_child(palm)
		_part(Vector3.ZERO, Vector3(520.0, 34.0 * thick, 360.0), m, palm)
		for k in 9: # (its points, round its outer rim)
			var a := lerpf(-1.25, 1.35, float(k) / 8.0)
			var rim := Vector3(sin(a) * 250.0 * side, 0.0, -cos(a) * 170.0)
			var tip := rim * 1.35 + Vector3(0.0, 40.0 + 30.0 * float(k % 2), 0.0)
			_stick(rim, tip, 14.0 * thick, m, palm)
		# the brow palm, smaller, forward
		var brow := Node3D.new()
		brow.position = out + Vector3(70.0 * side, 30.0, -170.0)
		brow.rotation = Vector3(0.4, 0.9 * side, 1.15 * side)
		_head.add_child(brow)
		_part(Vector3.ZERO, Vector3(150.0, 22.0 * thick, 80.0), m, brow)
		for k in 3:
			var a := lerpf(-0.7, 0.7, float(k) / 2.0)
			var rim := Vector3(sin(a) * 72.0 * side, 0.0, -cos(a) * 40.0 - 6.0)
			_stick(rim, rim * 1.5 + Vector3(0.0, 25.0, 0.0), 11.0 * thick, m, brow)


# --- its own way ----------------------------------------------------------------------

## Out into the water to at, its head down under to the plants on the bottom.
func wade(at: Vector3) -> void:
	_mode = "wade"
	_wade_at = at
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	if _mode == "wade" and not young:
		_common(dt)
		_wade(dt)
		return
	super(dt)


func _wade(_dt: float) -> void:
	match _stage:
		0: # (out to it, wading)
			_target = _wade_at
			_pace = float(S.walk) * 0.4
			_neck_to = Vector2(0.0, 0.0)
			if Vector2(_pos.x - _wade_at.x, _pos.z - _wade_at.z).length() < 0.3:
				_target = _pos
				_stage = 1
				_st = 0.0
		1: # (its head down under the water, pulling up plants; up again, streaming, chewing)
			_target = _pos
			var cyc := fmod(_st, 12.0)
			if cyc < 7.0:
				_neck_to = Vector2(-1.4, 0.2 * sin(_st * 0.6)) # (down, under)
				_jaw_to = 0.1 * maxf(sin(_st * 5.0), 0.0)
			else:
				_neck_to = Vector2(0.2, 0.3 * sin(_st * 0.5)) # (up, chewing, looking round)
				_chew = 1.0
				_jaw_to = 0.06 * maxf(sin(_st * 6.0), 0.0)
				_ears_to = 0.6
			if _st > 40.0:
				graze(_pos, 1.5)


func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append("wade")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	if name == "wade":
		wade(args.get("at", _pos + Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * 2.0))
		return true
	return super(name, args)


func _p_act_done(name: String) -> bool:
	if name == "wade":
		return _mode != "wade"
	return super(name)
