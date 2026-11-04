class_name RedFox
extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## A red fox (Vulpes vulpes), life size (about 60 cm long and its brush as
## long again, 40 cm at the shoulder): slender, long legged; rufous orange
## above and down its sides, grizzled darker along its back; its chin,
## throat, chest and belly white; its lower legs black (its stockings); its
## muzzle long and narrow, white sided, its nose black; amber eyes, their
## pupils slits; big pointed ears, black backed; its brush long and full,
## carried low, its tip white. Kits (RedFox.new(true)): born dark grey brown,
## blind, in the den (RedFox.den()); growing, their eyes open, about and
## playing. (Carnivore: its gaits and its ways.)
## Its own: hunting mice by sound (stalking, still, its head cocked one
## way then the other, listening; then the pounce, high, arcing, diving
## nose and forefeet first onto it); marking (a squat); mating: he mounts
## her, then turns round off her, and they're tied, standing tail to tail,
## a long while.

const SPEC := {
	"species": 0,
	"body": [[-280.0, 30.0, 45.0, 55.0], [-225.0, 10.0, 68.0, 92.0], [-120.0, 10.0, 74.0, 90.0], [0.0, 15.0, 66.0, 76.0],
			[120.0, 25.0, 66.0, 74.0], [215.0, 30.0, 62.0, 68.0], [262.0, 35.0, 38.0, 40.0], [278.0, 35.0, 14.0, 14.0]],
	"body_h": 300.0, "body_len": 560.0, "body_w": 72.0,
	"neck_at": Vector3(0.0, 40.0, -250.0), "neck": [[20.0, 0.0, 46.0, 58.0], [-60.0, 0.0, 40.0, 46.0], [-125.0, 0.0, 34.0, 40.0]], "neck_pitch": 0.55,
	"head_at": Vector3(0.0, 0.0, -120.0),
	"head": [[30.0, 0.0, 48.0, 50.0], [-20.0, 10.0, 60.0, 56.0], [-60.0, 5.0, 48.0, 44.0], [-100.0, -8.0, 28.0, 26.0], [-135.0, -14.0, 16.0, 15.0], [-150.0, -16.0, 8.0, 8.0]],
	"jaw_at": Vector3(0.0, -22.0, -50.0), "jaw": [[0.0, 0.0, 30.0, 13.0], [-50.0, -2.0, 21.0, 10.0], [-92.0, -2.0, 10.0, 6.0]], "mouth": 0.8,
	"mouth_z": -490.0,
	"eye": {"at": Vector3(31.0, 15.0, -50.0), "size": Vector3(13.0, 12.0, 15.0), "color": Color(0.78, 0.55, 0.12), "slit": 0.75},
	"nose": {"at": Vector3(0.0, -12.0, -150.0), "size": Vector3(18.0, 14.0, 14.0), "color": Color(0.05, 0.04, 0.04)},
	"whisker": 75.0,
	"ear": {"at": Vector3(28.0, 44.0, -22.0), "len": 88.0, "width": 62.0, "point": 1.1, "tilt_back": 0.05, "spread": 0.28},
	"tail": {"base": Vector3(0.0, 42.0, 268.0), "n": 8, "seg": 52.0, "radii": [34.0, 52.0, 62.0, 66.0, 64.0, 58.0, 46.0, 28.0], "carry": [0.55, 0.06], "wrap": 1.0},
	"fore": {"hip": Vector3(44.0, -50.0, -190.0), "a": 140.0, "b": 142.0, "m": 70.0, "p": 42.0, "home": Vector2(52.0, -215.0), "r": 16.0},
	"hind": {"hip": Vector3(48.0, -20.0, 200.0), "a": 150.0, "b": 160.0, "m": 100.0, "p": 46.0, "home": Vector2(54.0, 210.0), "r": 20.0},
	"walk": 0.9, "trot": 2.4, "run": 9.0,
	"stalk_from": 2.4, "spring": 1.1, "stalk_crouch": 0.35, "stalk_neck": -0.15, "eat_crouch": 0.5,
	"sit_drop": 60.0, "sit_pitch": 0.55, "lie_h": 95.0, "tilt": 0.35,
	"mate_secs": 30.0,
}


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.12 if young_ else 0.5)
	_setup()


## A fox's den: a mound of dug earth, its mouth a dark hole at one side
## (-z), its spoil fanned out before it. Its origin on the ground at its
## middle.
static func den() -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.42, 0.32, 0.22)
	earth.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.04, 0.03)
	dark.roughness = 1.0
	for p in [[Vector3(0.0, 0.0, 0.0), Vector3(1.2, 0.5, 1.0), earth], [Vector3(0.0, 0.0, -0.55), Vector3(0.9, 0.12, 0.6), earth],
			[Vector3(0.0, 0.1, -0.47), Vector3(0.24, 0.22, 0.1), dark]]:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = p[0]
		mi.scale = p[1]
		mi.material_override = p[2]
		root.add_child(mi)
	return root


# --- its own ways --------------------------------------------------------------------

## (Listening for it, still: the head cocked one way, then the other.)
func _attack_ready(_dt: float) -> void:
	_look_to = Vector2(-0.25, 0.0)
	_tail_mode = "low"


## The pounce: up high, arcing, coming down nose and forefeet first on it.
func _attack(_dt: float, p: Vector3, _d: float) -> bool:
	_crouch = 0.0
	_leap(p, 1.1)
	return true


func _mark(_dt: float) -> void:
	_sit_to = 0.4 if _st < 2.2 else 0.0 # (a squat)
	_tail_mode = "out"
	_neck_to = Vector2(-0.2, 0.0)


func _mount() -> Dictionary:
	# on her from behind, his forelegs clasping her; then off her, turned
	# round, tied, standing tail to tail
	var k := 0.0
	if _mate_stage == "joined":
		k = clampf((_mate_t - mate_secs * 0.18) / 1.6, 0.0, 1.0)
	elif _mate_stage == "part":
		k = 1.0
	var on_at := Vector3(0.0, 120.0, 235.0)
	var on_b := Basis(Vector3.RIGHT, 0.4)
	var tie_at := Vector3(0.0, 0.0, float(S.body_len) + 20.0)
	var tie_b := Basis(Vector3.UP, PI)
	var e := k * k * (3.0 - 2.0 * k)
	var b := Basis(on_b.get_rotation_quaternion().slerp(tie_b.get_rotation_quaternion(), e))
	var inv := (transform * _body.transform).affine_inverse()
	var free := {}
	var grips := {}
	for i in 4:
		var side := 1.0 if i % 2 == 1 else -1.0
		if i < 2 and e < 0.5:
			grips[i] = Vector3(72.0 * side, 15.0, 110.0)
		elif i >= 2 and e < 0.5:
			var w: Vector3 = _mate.call("_out", Vector3(55.0 * side, -body_h, 340.0))
			w.y = _ground(w.x, w.z)
			free[i] = inv * w
		else:
			free[i] = inv * _home(i)
	_tail_mode = "out"
	return {"at": on_at.lerp(tie_at, e), "basis": b, "grips": grips, "free": free}


func _after_mate() -> void:
	_tail_mode = "carry"
	wander(_home_spot(), _radius)
