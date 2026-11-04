class_name BlackBear
extends "res://scripts/creatures/ursid.gd" # (by path: found whether or not the editor has seen the class yet)
## An American black bear (Ursus americanus), life size (about 1.5 m long,
## 85 cm at the shoulder): its rump as high as its shoulders (no hump), its
## face straight in profile, its muzzle long, tan; its ears tall, rounded,
## set wide; its claws short, curved, dark; its coat by its phase: "black"
## (glossy, the commonest), "cinnamon", "brown" or "blond"; now and then a
## white blaze on its chest. Cubs (BlackBear.new(true)): born tiny, near
## naked, blind, in the den (Ursid.den()); growing, following her, playing.
## (Ursid, Carnivore: its ways.)

const PHASES := {"black": 0, "cinnamon": 1, "brown": 2, "blond": 3}
const SPEC := {
	"species": 4, "plantigrade": true,
	"body": [[-560.0, 40.0, 120.0, 150.0], [-480.0, 20.0, 180.0, 228.0], [-300.0, 10.0, 200.0, 242.0], [-80.0, 10.0, 205.0, 238.0],
			[150.0, 25.0, 210.0, 238.0], [380.0, 55.0, 200.0, 228.0], [520.0, 60.0, 150.0, 158.0], [580.0, 55.0, 60.0, 60.0]],
	"body_h": 560.0, "body_len": 1160.0, "body_w": 205.0,
	"neck_at": Vector3(0.0, 60.0, -520.0), "neck": [[30.0, 0.0, 120.0, 150.0], [-80.0, 0.0, 105.0, 125.0], [-150.0, 0.0, 95.0, 105.0]], "neck_pitch": 0.12,
	"head_at": Vector3(0.0, 0.0, -150.0),
	"head": [[40.0, 0.0, 108.0, 108.0], [-30.0, 15.0, 132.0, 118.0], [-110.0, 10.0, 112.0, 94.0], [-170.0, -12.0, 70.0, 60.0], [-215.0, -22.0, 48.0, 42.0], [-235.0, -26.0, 28.0, 26.0]],
	"jaw_at": Vector3(0.0, -55.0, -80.0), "jaw": [[0.0, 0.0, 70.0, 26.0], [-80.0, -3.0, 52.0, 20.0], [-145.0, 0.0, 28.0, 12.0]], "mouth": 1.8,
	"mouth_z": -900.0, "muzzle_z": -130.0,
	"eye": {"at": Vector3(62.0, 30.0, -108.0), "size": Vector3(16.0, 15.0, 16.0), "color": Color(0.25, 0.15, 0.08), "slit": 0.8},
	"nose": {"at": Vector3(0.0, -20.0, -234.0), "size": Vector3(40.0, 30.0, 26.0), "color": Color(0.06, 0.05, 0.05)},
	"whisker": 20.0,
	"ear": {"at": Vector3(82.0, 92.0, -18.0), "len": 88.0, "width": 86.0, "point": 0.55, "tilt_back": 0.0, "spread": 0.38},
	"tail": {"base": Vector3(0.0, 70.0, 575.0), "n": 2, "seg": 40.0, "radii": [40.0, 28.0], "carry": [0.6, 0.2], "wrap": 0.3},
	"fore": {"hip": Vector3(115.0, -90.0, -380.0), "a": 300.0, "b": 290.0, "m": 120.0, "p": 70.0, "home": Vector2(130.0, -560.0), "r": 48.0},
	"hind": {"hip": Vector3(120.0, -40.0, 400.0), "a": 320.0, "b": 300.0, "m": 230.0, "p": 60.0, "home": Vector2(130.0, 170.0), "r": 52.0},
	"claw": 30.0,
	"walk": 1.1, "trot": 2.5, "run": 13.0,
	"stalk_from": 4.0, "spring": 2.0, "stalk_crouch": 0.2, "stalk_neck": 0.0, "eat_crouch": 0.3,
	"sit_drop": 220.0, "sit_pitch": 0.75, "lie_h": 240.0,
	"mate_secs": 25.0,
}


func _init(young_ := false, phase_ := "black") -> void:
	S = SPEC
	young = young_
	phase = int(PHASES.get(phase_, 0))
	super(young_, 0.07 if young_ else 0.5)
	blaze = not young_ and rng.randf() < 0.2
	_setup()
