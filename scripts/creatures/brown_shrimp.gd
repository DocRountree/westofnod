class_name BrownShrimp
extends "res://scripts/creatures/shrimp.gd" # (by path: found whether or not the editor has seen the class yet)
## The brown shrimp (Farfantepenaeus aztecus), about 15 cm: red brown to tan, darker across its segments, mottled; its legs and antennae red orange; its tail fan's tips red, edged darker; grooves either side of its crest. (Shrimp: its build and ways.)


func _spec() -> Dictionary:
	return {
		"size": 0.95, "grooves": true, "bands": true,
		"shell": Color(0.58, 0.38, 0.22), "dark": Color(0.36, 0.2, 0.1), "tail": Color(0.62, 0.45, 0.3),
		"fan": Color(0.55, 0.36, 0.22), "fan_edge": Color(0.55, 0.12, 0.08), "leg": Color(0.78, 0.36, 0.2),
		"antenna": Color(0.72, 0.32, 0.18), "egg": Color(0.8, 0.7, 0.5),
	}
