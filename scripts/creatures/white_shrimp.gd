class_name WhiteShrimp
extends "res://scripts/creatures/shrimp.gd" # (by path: found whether or not the editor has seen the class yet)
## The white shrimp (Litopenaeus setiferus), about 15 cm: greyish white, see-through; its tail fan edged green and yellow, its antennae long (up to three times its length), dark; smooth, no grooves beside its crest. (Shrimp: its build and ways.)


func _spec() -> Dictionary:
	return {
		"size": 1.0, "ant_n": 40,
		"shell": Color(0.82, 0.82, 0.76), "dark": Color(0.55, 0.55, 0.5), "tail": Color(0.84, 0.83, 0.76),
		"fan": Color(0.78, 0.8, 0.66), "fan_edge": Color(0.45, 0.6, 0.3), "leg": Color(0.88, 0.86, 0.8),
		"antenna": Color(0.42, 0.3, 0.22), "egg": Color(0.85, 0.82, 0.62),
	}
