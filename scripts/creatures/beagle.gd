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
	})
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
