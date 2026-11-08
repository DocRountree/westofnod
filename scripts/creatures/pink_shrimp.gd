class_name PinkShrimp
extends "res://scripts/creatures/shrimp.gd" # (by path: found whether or not the editor has seen the class yet)
## The pink shrimp (Farfantepenaeus duorarum), about 15 cm: pink to coral, see-through, deeper red at its head and tail; a dark spot on each side where its third and fourth segments meet; its legs and antennae red; grooves either side of its crest. (Shrimp: its build and ways.)


func _spec() -> Dictionary:
	return {
		"size": 0.9, "grooves": true, "spot": true,
		"shell": Color(0.92, 0.48, 0.38), "dark": Color(0.35, 0.12, 0.1), "tail": Color(0.94, 0.58, 0.48),
		"fan": Color(0.92, 0.4, 0.3), "fan_edge": Color(0.75, 0.15, 0.12), "leg": Color(0.95, 0.5, 0.42),
		"antenna": Color(0.8, 0.28, 0.2), "egg": Color(0.9, 0.75, 0.6),
	}
