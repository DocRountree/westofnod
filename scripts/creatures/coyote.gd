class_name Coyote
extends "res://scripts/creatures/canid.gd" # (by path: found whether or not the editor has seen the class yet)
## A coyote (Canis latrans), life size (about 85 cm long, its tail a third
## more, 60 cm at the shoulder): lean, long legged, its muzzle long and
## narrow, its ears big and pointed, held up; grizzled grey brown above, the
## guard hairs along its back black tipped, tawny on its sides, legs, ears
## and muzzle, its throat and belly pale cream; yellow eyes, round pupils;
## its tail bushy, carried low (down between its legs running), grizzled,
## black tipped. Pups (Coyote.new(true)): born dark grey brown, blind, in
## the den (Canid.den(1.3)); growing, about and playing. (Canid, Carnivore:
## its gaits and ways: mousing pounces, small prey; a hare run down; the
## tie.) Howling, its yips between.

const SPEC := {
	"species": 2,
	"body": [[-350.0, 37.5, 54.0, 66.0], [-281.2, 12.5, 81.6, 110.4], [-150.0, 12.5, 88.8, 108.0], [0.0, 18.8, 79.2, 91.2], [150.0, 31.2, 79.2, 88.8], [268.8, 37.5, 74.4, 81.6], [327.5, 43.8, 45.6, 48.0], [347.5, 43.8, 16.8, 16.8]],
	"body_h": 388.1, "body_len": 700.0, "body_w": 86.4,
	"neck_at": Vector3(0.0, 48.0, -312.5), "neck": [[24.0, 0.0, 55.2, 69.6], [-72.0, 0.0, 48.0, 55.2], [-150.0, 0.0, 40.8, 48.0]], "neck_pitch": 0.5,
	"head_at": Vector3(0.0, 0.0, -144.0),
	"head": [[35.4, 0.0, 55.2, 57.5], [-23.6, 11.8, 69.0, 64.4], [-70.8, 5.9, 55.2, 50.6], [-118.0, -9.4, 32.2, 29.9], [-159.3, -16.5, 18.4, 17.2], [-177.0, -18.9, 9.2, 9.2]],
	"jaw_at": Vector3(0.0, -25.3, -59.0), "jaw": [[0.0, 0.0, 34.5, 14.9], [-59.0, -2.4, 24.1, 11.5], [-108.6, -2.4, 11.5, 6.9]], "mouth": 0.92,
	"mouth_z": -620.0,
	"eye": {"at": Vector3(35.6, 17.2, -59.0), "size": Vector3(14.9, 13.8, 17.2), "color": Color(0.8, 0.64, 0.22), "slit": 0.32},
	"nose": {"at": Vector3(0.0, -13.8, -177.0), "size": Vector3(20.7, 16.1, 16.1), "color": Color(0.05, 0.04, 0.04)},
	"whisker": 86.2,
	"ear": {"at": Vector3(33.0, 50.0, -24.0), "len": 92.0, "width": 62.0, "point": 1.05, "tilt_back": 0.05, "spread": 0.22},
	"tail": {"base": Vector3(0.0, 44.0, 340.0), "n": 7, "seg": 52.0, "radii": [30.0, 42.0, 48.0, 50.0, 46.0, 38.0, 24.0], "carry": [0.8, 0.05], "wrap": 0.9},
	"fore": {"hip": Vector3(52.8, -62.5, -237.5), "a": 184.8, "b": 187.4, "m": 92.4, "p": 52.7, "home": Vector2(62.4, -268.8), "r": 19.2},
	"hind": {"hip": Vector3(57.6, -25.0, 250.0), "a": 198.0, "b": 211.2, "m": 132.0, "p": 57.7, "home": Vector2(64.8, 262.5), "r": 24.0},
	"walk": 1.0, "trot": 3.0, "run": 12.0,
	"stalk_from": 2.8, "spring": 1.2, "stalk_crouch": 0.35, "stalk_neck": -0.15, "eat_crouch": 0.5,
	"sit_drop": 80.0, "sit_pitch": 0.55, "lie_h": 120.0, "tilt": 0.3,
	"mate_secs": 30.0, "howl": true, "yips": true,
}


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.11 if young_ else 0.5)
	_setup()
