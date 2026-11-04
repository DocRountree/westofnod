class_name RedFox
extends "res://scripts/creatures/canid.gd" # (by path: found whether or not the editor has seen the class yet)
## A red fox (Vulpes vulpes), life size (about 60 cm long and its brush as
## long again, 40 cm at the shoulder): slender, long legged; rufous orange
## above and down its sides, grizzled darker along its back; its chin,
## throat, chest and belly white; its lower legs black (its stockings); its
## muzzle long and narrow, white sided, its nose black; amber eyes, their
## pupils slits; big pointed ears, black backed; its brush long and full,
## carried low, its tip white. Kits (RedFox.new(true)): born dark grey brown,
## blind, in the den (RedFox.den()); growing, their eyes open, about and
## playing. (Canid, Carnivore: its gaits and its ways: hunting mice by
## sound, the pounce; the tie.) It doesn't howl.

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
