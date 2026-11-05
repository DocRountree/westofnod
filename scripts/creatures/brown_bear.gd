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
	"male_parts": {"sheath": [220.0, 380.0, 22.0], "scrotum": [590.0, 32.0, 0.3]}, # (a grown male's: Carnivore._build_male)
	"species": 5, "plantigrade": true,
	"body": [[-700.0, 50.0, 150.0, 188.0], [-600.0, 25.0, 225.0, 285.0], [-375.0, 12.0, 250.0, 302.0], [-100.0, 12.0, 256.0, 296.0],
			[188.0, 25.0, 262.0, 292.0], [475.0, 45.0, 250.0, 280.0], [650.0, 50.0, 188.0, 196.0], [725.0, 45.0, 75.0, 75.0]],
	"body_h": 680.0, "body_len": 1450.0, "body_w": 256.0,
	"hump": [[Vector3(0.0, 235.0, -400.0), Vector3(330.0, 230.0, 460.0)]],
	"neck_at": Vector3(0.0, 80.0, -650.0), "neck": [[36.0, 0.0, 150.0, 185.0], [-96.0, 0.0, 130.0, 152.0], [-180.0, 0.0, 118.0, 128.0]], "neck_pitch": 0.08,
	"head_at": Vector3(0.0, 0.0, -180.0),
	"head": [[50.0, 0.0, 145.0, 140.0], [-30.0, 24.0, 172.0, 150.0], [-110.0, 0.0, 140.0, 112.0], [-175.0, -10.0, 86.0, 70.0], [-225.0, -22.0, 58.0, 48.0], [-245.0, -26.0, 34.0, 30.0]],
	"jaw_at": Vector3(0.0, -73.7, -108.0), "jaw": [[0.0, 0.0, 64.2, 26.5], [-31.0, 0.5, 62.8, 27.4], [-62.0, 7.4, 38.3, 23.2]], "mouth": 2.2,
	"mouth_z": -1080.0, "muzzle_z": -150.0,
	"eye": {"at": Vector3(70.0, 34.0, -112.0), "size": Vector3(17.0, 16.0, 17.0), "color": Color(0.22, 0.13, 0.07), "slit": 0.8},
	"nose": {"at": Vector3(0.0, -22.0, -244.0), "size": Vector3(50.0, 36.0, 30.0), "color": Color(0.06, 0.05, 0.05)},
	"whisker": 25.0,
	"ear": {"at": Vector3(100.0, 120.0, -4.0), "len": 70.0, "width": 82.0, "point": 0.25, "tilt_back": 0.05, "spread": 0.4},
	"tail": {"base": Vector3(0.0, 70.0, 720.0), "n": 2, "seg": 48.0, "radii": [48.0, 32.0], "carry": [0.6, 0.2], "wrap": 0.3},
	"fore": {"hip": Vector3(145.0, -110.0, -470.0), "a": 360.0, "b": 350.0, "m": 150.0, "p": 90.0, "home": Vector2(160.0, -700.0), "r": 60.0},
	"hind": {"hip": Vector3(150.0, -50.0, 500.0), "a": 390.0, "b": 360.0, "m": 280.0, "p": 75.0, "home": Vector2(160.0, 230.0), "r": 64.0},
	"claw": 70.0,
	"walk": 1.2, "trot": 2.8, "run": 14.0,
	"stalk_from": 5.0, "spring": 2.4, "stalk_crouch": 0.2, "stalk_neck": 0.0, "eat_crouch": 0.3,
	"sit_drop": 280.0, "sit_pitch": 0.75, "lie_h": 300.0,
	"mate_secs": 25.0,
	# its head sculpted (SculptHead), from photographs: massive, its forehead high and broad, its face dished below it; its muzzle broad, its nose pad big; its eyes small, set wide; its ears small and round
	"sculpt": {
		"z": [50.0, 20.0, -10.0, -40.0, -70.0, -100.0, -130.0, -160.0, -190.0, -220.0, -248.0],
		"top": [112.0, 124.0, 135.0, 142.0, 136.0, 112.0, 86.0, 72.0, 64.0, 57.0, 42.0],
		"bot": [-104.0, -106.0, -108.0, -108.0, -100.0, -88.0, -74.0, -62.0, -54.0, -46.0, -38.0],
		"w": [120.0, 144.0, 158.0, 156.0, 140.0, 112.0, 80.0, 62.0, 52.0, 44.0, 33.0],
		"wl": [128.0, 156.0, 178.0, 182.0, 164.0, 130.0, 88.0, 66.0, 54.0, 45.0, 33.0],
		"pw": [2.0, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.6, 2.5, 2.2],
		"eye": Vector3(64.0, 42.0, -106.0), "eye_r": 12.0, "socket": 1.4, "lid": 1.0,
		"brow": 4.0, "cheek": 3.5, "stop": 2.5, "pads": 2.4, "flews": 1.20, "nose_r": 26.0,
		"almond": 0.75, "slant": 0.05, "look_fwd": 1.00, "pupil": Vector2(0.65, 0.65),
	},
}


func _init(young_ := false, phase_ := "brown") -> void:
	S = SPEC
	young = young_
	phase = int(PHASES.get(phase_, 0))
	super(young_, 0.07 if young_ else 0.5)
	_setup()
