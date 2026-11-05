class_name Bobcat
extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## A bobcat (Lynx rufus), life size (about 75 cm long, 50 cm at the
## shoulder): stocky, long legged, big pawed; tawny buff to grey brown,
## spotted and streaked dark, its legs barred, its belly white, spotted
## black; its face round, a ruff of barred fur flaring down its cheeks, white
## about its eyes and muzzle, its eyes yellow, their pupils round (slits in
## the light); its ears pointed, black backed with a white spot, their tips
## tufted black; its tail short (bobbed), barred, its tip black above,
## white beneath. Kittens (Bobcat.new(true)): born spotted all over,
## greyer, blind, in the den (Bobcat.den(): a shelter of rocks); growing,
## their eyes open, about and playing. (Carnivore: its gaits and its ways.)
## Its own: hunting by ambush (stalking flat, its belly low, its head level
## and still, its shoulders up; freezing; its hindquarters treading, its
## tail tip twitching; then the rush and the spring); marking (scraping
## with its hind feet); mating: he mounts her, gripping the scruff of her
## neck in his teeth, briefly; then she rolls on her back, and he springs
## away.

const SPEC := {
	"species": 1,
	"body": [[-300.0, 40.0, 66.0, 76.0], [-240.0, 15.0, 96.0, 116.0], [-120.0, 10.0, 100.0, 112.0], [0.0, 10.0, 90.0, 100.0],
			[130.0, 25.0, 96.0, 106.0], [240.0, 40.0, 90.0, 96.0], [295.0, 45.0, 56.0, 58.0], [310.0, 45.0, 18.0, 18.0]],
	"body_h": 360.0, "body_len": 620.0, "body_w": 96.0,
	"neck_at": Vector3(0.0, 50.0, -280.0), "neck": [[20.0, 0.0, 70.0, 84.0], [-50.0, 0.0, 62.0, 70.0], [-90.0, 0.0, 58.0, 62.0]], "neck_pitch": 0.32,
	"head_at": Vector3(0.0, 0.0, -88.0),
	"head": [[40.0, 0.0, 72.0, 68.0], [0.0, 10.0, 86.0, 78.0], [-45.0, 8.0, 76.0, 68.0], [-80.0, -10.0, 50.0, 43.0], [-100.0, -18.0, 29.0, 25.0], [-108.0, -20.0, 15.0, 13.0]],
	"jaw_at": Vector3(0.0, -24.7, -61.0), "jaw": [[0.0, 0.0, 14.6, 8.3], [-7.7, -1.4, 17.6, 8.9], [-15.5, 0.6, 11.1, 7.0]], "mouth": 1.0,
	"mouth_z": -480.0,
	"eye": {"at": Vector3(40.0, 18.0, -56.0), "size": Vector3(22.0, 21.0, 22.0), "color": Color(0.78, 0.7, 0.25), "slit": 0.6},
	"nose": {"at": Vector3(0.0, -14.0, -106.0), "size": Vector3(22.0, 15.0, 14.0), "color": Color(0.6, 0.35, 0.3)},
	"whisker": 90.0,
	"ear": {"at": Vector3(38.0, 50.0, 4.0), "len": 74.0, "width": 56.0, "point": 1.3, "tuft": 12.0, "tilt_back": 0.02, "spread": 0.18},
	"ruff": [[Vector3(68.0, -24.0, -12.0), Vector3(56.0, 76.0, 52.0)]],
	"tail": {"base": Vector3(0.0, 55.0, 302.0), "n": 4, "seg": 40.0, "radii": [40.0, 38.0, 34.0, 26.0], "carry": [0.25, -0.05], "twitch": 1.0, "wrap": 0.5},
	"fore": {"hip": Vector3(60.0, -60.0, -220.0), "a": 165.0, "b": 165.0, "m": 62.0, "p": 54.0, "home": Vector2(66.0, -235.0), "r": 24.0},
	"hind": {"hip": Vector3(64.0, -20.0, 232.0), "a": 190.0, "b": 195.0, "m": 122.0, "p": 58.0, "home": Vector2(66.0, 245.0), "r": 28.0},
	"walk": 0.8, "trot": 1.8, "run": 9.0,
	"stalk_from": 2.8, "spring": 1.0, "stalk_crouch": 0.65, "stalk_neck": 0.15, "eat_crouch": 0.7,
	"sit_drop": 80.0, "sit_pitch": 0.5, "lie_h": 120.0,
	"mate_secs": 8.0,
	# its head sculpted (SculptHead), from photographs: round, its brow domed, its muzzle short, the whisker pads full; big round eyes, set to look forward; its ruff wide over its cheeks; its chin small, behind its nose
	"sculpt": {
		"z": [40.0, 25.0, 10.0, -5.0, -20.0, -35.0, -50.0, -61.0, -72.0, -81.0, -88.0],
		"top": [30.0, 52.0, 60.0, 62.0, 60.0, 54.0, 42.0, 31.0, 21.0, 13.0, 5.0],
		"bot": [-26.0, -42.0, -48.0, -50.0, -48.0, -42.0, -34.0, -28.0, -24.0, -20.0, -15.0],
		"w": [32.0, 54.0, 60.0, 60.0, 56.0, 48.0, 38.0, 31.0, 25.0, 18.0, 9.0],
		"wl": [36.0, 64.0, 78.0, 82.0, 76.0, 60.0, 44.0, 36.0, 28.0, 20.0, 9.0],
		"pw": [2.0, 2.0, 2.0, 2.1, 2.2, 2.3, 2.5, 2.7, 2.8, 2.7, 2.3],
		"eye": Vector3(24.0, 19.0, -59.0), "eye_r": 11.5, "socket": 2.0, "lid": 1.2,
		"brow": 2.4, "cheek": 2.0, "stop": 1.2, "pads": 3.4, "flews": 0.3, "nose_r": 7.0,
		"almond": 0.62, "slant": 0.12, "look_fwd": 1.6, "pupil": Vector2(0.75, 0.55),
	},
}

var _rush := false


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.12 if young_ else 0.5)
	_setup()


## A bobcat's den: a shelter under rocks, a hollow out of the wind. Its
## origin on the ground at its mouth.
static func den() -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 6
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.5, 0.48, 0.44)
	rock.roughness = 0.9
	for p in [[Vector3(-0.45, 0.25, 0.3), Vector3(0.7, 0.55, 0.8), 0.3], [Vector3(0.45, 0.22, 0.35), Vector3(0.6, 0.5, 0.7), -0.4],
			[Vector3(0.0, 0.55, 0.45), Vector3(1.3, 0.3, 0.75), 0.1], [Vector3(0.0, 0.2, 0.85), Vector3(1.0, 0.45, 0.4), 0.0]]:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = p[0]
		mi.scale = p[1]
		mi.rotation.y = p[2]
		mi.material_override = rock
		root.add_child(mi)
	return root


# --- its own ways --------------------------------------------------------------------

## (Flat, still, its hindquarters treading, its tail tip twitching.)
func _attack_ready(_dt: float) -> void:
	_wiggle = 1.0 if _st > 1.0 else 0.0
	_look_to = Vector2(0.0, 0.0)
	_rush = false


## The rush, then the spring onto it.
func _attack(_dt: float, p: Vector3, d: float) -> bool:
	var spring := float(S.spring) * size / 0.5
	if d > spring * 0.5 and not _rush:
		_crouch = 0.2
		_target = p
		_pace = float(S.run) * 0.5 * lerpf(0.35, 1.0, size)
		if d < spring * 0.55:
			_rush = true
		return false
	_pace = -1.0
	_crouch = 0.0
	_leap(p, 0.38)
	return true


func _mark(_dt: float) -> void:
	# (scraping: its hind feet raking back in turn)
	for i: int in [2, 3]:
		var side := 1.0 if i % 2 == 1 else -1.0
		var L: Dictionary = legs[1]
		var hm: Vector2 = L.home
		var k := sin(_st * 7.0 + (PI if side > 0.0 else 0.0))
		_pose_foot[i] = _ground_at(Vector3(hm.x * side, 0.0, hm.y + 60.0 * k)) + Vector3(0.0, maxf(-k, 0.0) * 30.0, 0.0)
	_tail_mode = "out"
	if _st > 2.9:
		_pose_foot[2] = null
		_pose_foot[3] = null


func _court_secs() -> float:
	return 6.0


func _mount() -> Dictionary:
	# on her, gripping the scruff of her neck in his teeth
	var inv := (transform * _body.transform).affine_inverse()
	var free := {}
	for i: int in [2, 3]:
		var side := 1.0 if i % 2 == 1 else -1.0
		var w: Vector3 = _mate.call("_out", Vector3(70.0 * side, -body_h, 230.0))
		w.y = _ground(w.x, w.z)
		free[i] = inv * w
	_neck_to = Vector2(-1.0, 0.0)
	_jaw_to = 0.4
	_ears_to = -0.6
	return {"at": Vector3(0.0, 175.0, 185.0), "basis": Basis(Vector3.RIGHT, 0.22), "grips": {
		0: Vector3(-96.0, 10.0, -60.0), 1: Vector3(96.0, 10.0, -60.0)}, "free": free}


func _mating(dt: float) -> void:
	super(dt)
	if _mate_role == "female" and _mate.get("_mate_stage") == "court":
		# (rolling, rubbing, crouching for him)
		_crouch = move_toward(_crouch, 0.5, dt)
		_tail_mode = "out"


func _after_mate() -> void:
	if male: # (away from her, a spring)
		var side := Vector3(cos(_yaw), 0.0, -sin(_yaw))
		_leap(_pos + side * 0.5, 0.6)
		groom()
	else:
		_mode = "roll_over"
		_st = 0.0


func _think(dt: float) -> void:
	if _mode == "roll_over": # (over on her back, writhing, and up)
		_st += dt
		_target = _pos
		_lie_to = 1.0
		_roll = lerpf(_roll, PI * 0.8 if _st < 3.0 else 0.0, 1.0 - exp(-3.0 * dt))
		if _st > 4.0:
			_roll = 0.0
			wander(_home_spot(), _radius)
		return
	super(dt)
