class_name BrownBear
extends "res://scripts/creatures/ursid.gd" # (by path: found whether or not the editor has seen the class yet)
## A brown bear (Ursus arctos: the grizzly), life size (about 2 m long, 1.1
## m at the shoulder): massive; the hump of muscle over its shoulders,
## higher than its rump; its face dished, its muzzle broad, its ears small
## and round; its claws long, nearly straight, pale; its coat by its phase:
## "brown", "grizzled" (the hairs' tips silvered over its back and
## shoulders) or "blond"; darker on its legs. Cubs (BrownBear.new(true)):
## born tiny, near naked, blind, in the den (Ursid.den(1.3)); growing,
## following her, playing. (Ursid, Carnivore: its ways: digging for roots
## and ground squirrels its own.)

const PHASES := {"brown": 0, "grizzled": 1, "blond": 2}
const SPEC := {
	"species": 5, "plantigrade": true,
	"body": [[-700.0, 50.0, 150.0, 188.0], [-600.0, 25.0, 225.0, 285.0], [-375.0, 12.0, 250.0, 302.0], [-100.0, 12.0, 256.0, 296.0],
			[188.0, 25.0, 262.0, 292.0], [475.0, 45.0, 250.0, 280.0], [650.0, 50.0, 188.0, 196.0], [725.0, 45.0, 75.0, 75.0]],
	"body_h": 680.0, "body_len": 1450.0, "body_w": 256.0,
	"hump": [[Vector3(0.0, 235.0, -400.0), Vector3(330.0, 230.0, 460.0)]],
	"neck_at": Vector3(0.0, 80.0, -650.0), "neck": [[36.0, 0.0, 150.0, 185.0], [-96.0, 0.0, 130.0, 152.0], [-180.0, 0.0, 118.0, 128.0]], "neck_pitch": 0.08,
	"head_at": Vector3(0.0, 0.0, -180.0),
	"head": [[50.0, 0.0, 145.0, 140.0], [-30.0, 24.0, 172.0, 150.0], [-110.0, 0.0, 140.0, 112.0], [-175.0, -10.0, 86.0, 70.0], [-225.0, -22.0, 58.0, 48.0], [-245.0, -26.0, 34.0, 30.0]],
	"jaw_at": Vector3(0.0, -66.0, -90.0), "jaw": [[0.0, 0.0, 86.0, 32.0], [-90.0, -3.0, 64.0, 24.0], [-150.0, 0.0, 34.0, 14.0]], "mouth": 2.2,
	"mouth_z": -1080.0, "muzzle_z": -150.0,
	"eye": {"at": Vector3(70.0, 34.0, -112.0), "size": Vector3(17.0, 16.0, 17.0), "color": Color(0.22, 0.13, 0.07), "slit": 0.8},
	"nose": {"at": Vector3(0.0, -22.0, -244.0), "size": Vector3(50.0, 36.0, 30.0), "color": Color(0.06, 0.05, 0.05)},
	"whisker": 25.0,
	"ear": {"at": Vector3(102.0, 118.0, -6.0), "len": 70.0, "width": 82.0, "point": 0.45, "tilt_back": 0.05, "spread": 0.4},
	"tail": {"base": Vector3(0.0, 70.0, 720.0), "n": 2, "seg": 48.0, "radii": [48.0, 32.0], "carry": [0.6, 0.2], "wrap": 0.3},
	"fore": {"hip": Vector3(145.0, -110.0, -470.0), "a": 360.0, "b": 350.0, "m": 150.0, "p": 90.0, "home": Vector2(160.0, -700.0), "r": 60.0},
	"hind": {"hip": Vector3(150.0, -50.0, 500.0), "a": 390.0, "b": 360.0, "m": 280.0, "p": 75.0, "home": Vector2(160.0, 230.0), "r": 64.0},
	"claw": 70.0,
	"walk": 1.2, "trot": 2.8, "run": 14.0,
	"stalk_from": 5.0, "spring": 2.4, "stalk_crouch": 0.2, "stalk_neck": 0.0, "eat_crouch": 0.3,
	"sit_drop": 280.0, "sit_pitch": 0.75, "lie_h": 300.0,
	"mate_secs": 25.0,
}


func _init(young_ := false, phase_ := "brown") -> void:
	S = SPEC
	young = young_
	phase = int(PHASES.get(phase_, 0))
	super(young_, 0.07 if young_ else 0.5)
	_setup()
