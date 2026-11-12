class_name GermanShepherd
extends "res://scripts/creatures/dog.gd"
## A German shepherd dog, life size (about 62 cm at the shoulder): the
## wolf's lines, a little smaller, its back sloping; big ears standing up,
## pointed; a long bushy tail hung low in a curve. Black and tan: tan, a
## black saddle over its back, the top of its tail black, its muzzle black
## (the mask), its ears black backed. Barks deep; howls too. (Dog.)


func _init(young_ := false) -> void:
	var s := make_spec(0.78, 0.98, 0.96, 0.95, {
		"coat": {"dog_pat": 1, "dog_base": Color(0.66, 0.44, 0.23), "dog_dark": Color(0.05, 0.045, 0.04), "dog_belly": 1.08, "dog_saddle_ny": 0.22},
		"walk": 1.1, "trot": 3.2, "run": 12.0, "howl": true, "tail_fur": 45.0, "fur": 26.0,
	}, {
		# (its head sculpted, from photographs: a wedge; its skull flatter and narrower than a wolf's, the stop gentle,
		# the muzzle long and strong, tapering, its lips tight)
		"top": [38.0, 72.0, 84.0, 86.0, 83.0, 72.0, 56.0, 47.0, 40.0, 32.0, 16.0],
		"bot": [-30.0, -54.0, -61.0, -61.0, -57.0, -51.0, -46.0, -43.0, -41.0, -38.0, -33.0],
		"w": [32.0, 60.0, 68.0, 65.0, 56.0, 43.0, 31.0, 26.0, 23.0, 19.0, 11.0],
		"wl": [38.0, 65.0, 75.0, 77.0, 71.0, 52.0, 35.0, 28.0, 24.0, 20.0, 11.0],
		"pw": [2.1, 2.1, 2.1, 2.2, 2.3, 2.4, 2.6, 2.7, 2.7, 2.6, 2.3],
		"eye": Vector3(40.0, 27.0, -74.0), "eye_r": 13.5, "brow": 4.5, "cheek": 2.5, "stop": 4.8, "pads": 2.0, "flews": 0.6, "nose_r": 17.0,
		"almond": 0.6, "slant": 0.14,
	})
	(s.eye as Dictionary).color = Color(0.32, 0.18, 0.07) # (brown)
	(s.ear as Dictionary).len = float((s.ear as Dictionary).len) * 1.3
	(s.ear as Dictionary).width = float((s.ear as Dictionary).width) * 1.05
	(s.ear as Dictionary).point = 0.95
	(s.tail as Dictionary).carry = [1.2, 0.06]
	S = s
	young = young_
	super(young_)
