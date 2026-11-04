class_name GreyWolf
extends "res://scripts/creatures/canid.gd" # (by path: found whether or not the editor has seen the class yet)
## A grey wolf (Canis lupus), North America's, life size (about 1.2 m long,
## its tail half that more, 80 cm at the shoulder): big, deep chested, long
## legged, its feet big; its head broad, its muzzle long and deep, its ears
## shorter and rounder than a coyote's; grizzled grey, a darker saddle, pale
## buff on its legs and flanks, its underside and the mask of its face pale;
## yellow eyes; its tail bushy, carried low and straight, dark tipped. Pups
## (GreyWolf.new(true)): born near black, blind, in the den (Canid.den(1.7));
## growing, about and playing. (Canid, Carnivore: its gaits and ways:
## running its prey down; the tie.) Howling, long, its head thrown back.

const SPEC := {
	"species": 3,
	"body": [[-420.0, 45.0, 69.8, 85.2], [-337.5, 15.0, 105.4, 142.6], [-180.0, 15.0, 114.7, 139.5], [0.0, 22.5, 102.3, 117.8], [180.0, 37.5, 102.3, 114.7], [322.5, 45.0, 96.1, 105.4], [393.0, 52.5, 58.9, 62.0], [417.0, 52.5, 21.7, 21.7]],
	"body_h": 514.5, "body_len": 840.0, "body_w": 111.6,
	"neck_at": Vector3(0.0, 62.0, -375.0), "neck": [[28.0, 0.0, 71.3, 89.9], [-84.0, 0.0, 62.0, 71.3], [-175.0, 0.0, 52.7, 62.0]], "neck_pitch": 0.42,
	"head_at": Vector3(0.0, 0.0, -168.0),
	"head": [[42.6, 0.0, 76.8, 80.0], [-28.4, 14.2, 96.0, 89.6], [-85.2, 7.1, 76.8, 70.4], [-142.0, -11.4, 44.8, 41.6], [-191.7, -19.9, 25.6, 24.0], [-213.0, -22.7, 12.8, 12.8]],
	"jaw_at": Vector3(0.0, -35.2, -71.0), "jaw": [[0.0, 0.0, 48.0, 20.8], [-71.0, -2.8, 33.6, 16.0], [-130.6, -2.8, 16.0, 9.6]], "mouth": 1.28,
	"mouth_z": -760.0,
	"eye": {"at": Vector3(49.6, 24.0, -71.0), "size": Vector3(20.8, 19.2, 24.0), "color": Color(0.82, 0.68, 0.25), "slit": 0.32},
	"nose": {"at": Vector3(0.0, -19.2, -213.0), "size": Vector3(28.8, 22.4, 22.4), "color": Color(0.05, 0.04, 0.04)},
	"whisker": 120.0,
	"ear": {"at": Vector3(46.0, 66.0, -26.0), "len": 98.0, "width": 82.0, "point": 0.85, "tilt_back": 0.08, "spread": 0.2},
	"tail": {"base": Vector3(0.0, 55.0, 410.0), "n": 8, "seg": 62.0, "radii": [40.0, 54.0, 60.0, 62.0, 60.0, 54.0, 44.0, 28.0], "carry": [1.0, 0.03], "wrap": 0.85},
	"fore": {"hip": Vector3(68.2, -75.0, -285.0), "a": 245.0, "b": 248.5, "m": 122.5, "p": 69.8, "home": Vector2(80.6, -322.5), "r": 24.8},
	"hind": {"hip": Vector3(74.4, -30.0, 300.0), "a": 262.5, "b": 280.0, "m": 175.0, "p": 76.5, "home": Vector2(83.7, 315.0), "r": 31.0},
	"walk": 1.2, "trot": 3.4, "run": 14.0,
	"stalk_from": 3.6, "spring": 1.5, "stalk_crouch": 0.3, "stalk_neck": 0.0, "eat_crouch": 0.55,
	"sit_drop": 110.0, "sit_pitch": 0.5, "lie_h": 170.0, "tilt": 0.15,
	"mate_secs": 30.0, "howl": true,
}


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, 0.11 if young_ else 0.5)
	_setup()
