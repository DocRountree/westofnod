class_name GrassSnails
extends "res://scripts/creatures/snails.gd" # (by path: found whether or not the editor has seen the class yet)
## Lovely grass snails (Vallonia pulchella), drawn at twice life size (the
## shell about 5 mm across): tiny, a flat disc of three and a quarter
## whorls widening fast, the last dropping a little to its round mouth,
## which flares out in a thick white lip; the umbilicus wide; glossy,
## nearly smooth, glassy and pale, its first whorls a warm brown showing
## through, the body's shadow in it. The body a translucent greyish white,
## the tentacles short. Of lawns, meadows and grassy banks, eating
## decaying plants and the film on them. Mostly selfing (its eggs its own,
## alone); mating now and then. A clutch of one to a few eggs. Snails: how
## they're made and moved. Not yet in the game
## (tools/creatures/ecology_demo.tscn).


func _init() -> void:
	super()
	top_speed = 0.0009
	reach = 2.2
	apart = 3.2
	egg_kind = "grass_snail"
	clutch = 3
	self_rate = 1.0
	grow_secs = 180.0
	colors = {
		"body_color": Color(0.84, 0.84, 0.82),
		"body_dark": Color(0.62, 0.62, 0.62),
		"sole_color": Color(0.9, 0.9, 0.88),
		"tentacle_color": Color(0.58, 0.58, 0.62),
		"tubercles": 0.3,
		"body_sss": 0.6,
		"shell_base": Color(0.87, 0.85, 0.78),
		"shell_apex": Color(0.64, 0.5, 0.34),
		"shell_inner": Color(0.9, 0.88, 0.82),
		"lip_color": Color(0.98, 0.97, 0.94),
		"flames": 0.0,
		"ribs": 26.0,
		"rib_depth": 0.15,
		"shell_gloss": 0.88,
		"glassy": 1.0,
		"apex_whorls": 1.7,
		"glide_hz": 0.7,
	}
	shape = {
		"shell": {"diam": 2.5, "whorls": 3.3, "grow": 2.25, "tube": 0.42, "round": 0.8, "spire": 0.4, "lip": 0.45, "descend": 0.12,
				"apex": Vector3(-0.4, 0.9, 0.1), "mouth_side": Vector3(-0.55, -0.6, 0.2), "mouth": Vector3(0.12, 0.0, -0.2)},
		"body": [[2.15, 0.01, 0.04], [2.1, 0.05, 0.1], [1.5, 0.25, 0.3], [0.6, 0.36, 0.42], [0.0, 0.4, 0.48], [-0.7, 0.38, 0.52], [-1.3, 0.33, 0.56],
				[-1.75, 0.27, 0.52], [-2.1, 0.18, 0.4], [-2.25, 0.07, 0.24], [-2.29, 0.01, 0.14]],
		"neck": -1.0,
		"upper": [Vector3(0.11, 0.5, -1.65), Vector3(0.3, 0.7, -0.65), 0.75, 0.06],
		"lower": [Vector3(0.13, 0.25, -2.08), Vector3(0.4, -0.25, -0.85), 0.2, 0.045],
	}
