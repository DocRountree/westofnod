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
	})
	(s.ear as Dictionary).len = float((s.ear as Dictionary).len) * 1.3
	(s.ear as Dictionary).width = float((s.ear as Dictionary).width) * 1.05
	(s.ear as Dictionary).point = 0.95
	(s.tail as Dictionary).carry = [1.2, 0.06]
	S = s
	young = young_
	super(young_)
