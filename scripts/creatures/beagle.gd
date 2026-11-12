class_name Beagle
extends "res://scripts/creatures/dog.gd"
## A beagle, life size (about 37 cm at the shoulder): a small hound, its
## legs short and sturdy, its body long for them; its head domed, its
## muzzle square; long ears hanging, rounded at their tips; its tail
## carried up (the flag), white tipped. Tricolour: tan head and ears, a
## black saddle, white legs, belly, chest, muzzle and a blaze up its face.
## Nose down on a scent; it bays (howl). (Dog.)


func _init(young_ := false) -> void:
	var s := make_spec(0.47, 0.72, 1.14, 0.82, {
		"coat": {"dog_pat": 2, "dog_base": Color(0.68, 0.42, 0.2), "dog_dark": Color(0.05, 0.045, 0.04), "dog_belly": 1.0, "dog_saddle_ny": 0.12},
		"walk": 0.9, "trot": 2.6, "run": 8.5, "howl": true, "tail_fur": 10.0, "fur": 9.0,
	}, {
		# (its head sculpted, from photographs: its skull domed, long, fairly broad; a marked stop; the muzzle square,
		# straight, a little shorter than the skull; the upper lips hanging over the lower jaw's line; its eyes big)
		"top": [44.0, 82.0, 95.0, 97.0, 95.0, 87.0, 59.0, 55.0, 52.0, 48.0, 34.0],
		"bot": [-30.0, -56.0, -64.0, -65.0, -63.0, -59.0, -56.0, -55.0, -53.0, -50.0, -41.0],
		"w": [34.0, 66.0, 76.0, 74.0, 67.0, 54.0, 39.0, 35.0, 33.0, 29.0, 18.0],
		"wl": [40.0, 72.0, 86.0, 88.0, 81.0, 61.0, 45.0, 41.0, 39.0, 33.0, 19.0],
		"pw": [2.1, 2.1, 2.1, 2.2, 2.3, 2.5, 2.9, 3.1, 3.2, 3.0, 2.5],
		"eye": Vector3(41.0, 29.0, -74.0), "eye_r": 15.5, "brow": 4.5, "cheek": 3.0, "stop": 6.0, "pads": 3.0, "flews": 2.0, "nose_r": 18.0,
		"almond": 0.72, "slant": 0.0,
	})
	(s.eye as Dictionary).color = Color(0.28, 0.15, 0.06)
	(s.eye as Dictionary).size = ((s.eye as Dictionary).size as Vector3) * 1.12
	var E: Dictionary = s.ear
	E.len = float(E.len) * 2.2
	E.width = float(E.width) * 1.7
	E.point = 0.0
	E.drop = 1.0
	E.at = Vector3((((s.sculpt as Dictionary).wl as Array).max() as float) * 0.92, (E.at as Vector3).y * 0.55, (E.at as Vector3).z - 12.0) # (hung from the sides of its head, not its crown)
	var T: Dictionary = s.tail
	var rr: Array = T.radii
	for i in rr.size():
		rr[i] = float(rr[i]) * lerpf(0.5, 0.35, float(i) / (rr.size() - 1))
	T.carry = [-0.75, 0.1]
	S = s
	young = young_
	super(young_)
