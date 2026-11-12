class_name LabradorRetriever
extends "res://scripts/creatures/dog.gd"
## A Labrador retriever, life size (about 57 cm at the shoulder): sturdy,
## broad headed, deep chested, its muzzle shorter and broad; its ears
## hanging, soft, beside its cheeks; its tail thick at its root and
## tapering (the otter's tail), carried level, wagging. Its coat short and
## dense, one colour: yellow (cream to fox red), black, or chocolate
## (colour: chosen when it's made). Keen to fetch. (Dog.)

var colour := "" ## "yellow", "black", "chocolate"


func _init(young_ := false, colour_ := "") -> void:
	colour = colour_ if colour_ != "" else ["yellow", "yellow", "black", "black", "chocolate"][randi() % 5]
	var base: Color = {"yellow": Color(0.86, 0.68, 0.42), "black": Color(0.055, 0.05, 0.048), "chocolate": Color(0.3, 0.18, 0.1)}[colour]
	var s := make_spec(0.71, 0.92, 1.16, 0.8, {
		"coat": {"dog_pat": 0, "dog_base": base, "dog_belly": 1.1 if colour == "yellow" else 1.0},
		"walk": 1.05, "trot": 3.0, "run": 11.0, "tail_fur": 14.0, "fur": 11.0,
	})
	var E: Dictionary = s.ear
	E.len = float(E.len) * 1.5
	E.width = float(E.width) * 1.6
	E.point = 0.0
	E.drop = 1.0
	E.at = Vector3((((s.sculpt as Dictionary).wl as Array).max() as float) * 0.92, (E.at as Vector3).y * 0.55, (E.at as Vector3).z - 15.0) # (hung from the sides of its head, not its crown)
	var T: Dictionary = s.tail
	var rr: Array = T.radii
	for i in rr.size():
		rr[i] = float(rr[i]) * lerpf(0.62, 0.35, float(i) / (rr.size() - 1))
	T.carry = [0.6, 0.03]
	S = s
	young = young_
	super(young_)
