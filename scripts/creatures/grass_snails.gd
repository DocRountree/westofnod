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
	reach = 1.9
	apart = 3.2
	egg_kind = "grass_snail"
	clutch = 3
	self_rate = 1.0
	grow_secs = 180.0
	colors = {
		"body_color": Color(0.87, 0.85, 0.8),
		"body_dark": Color(0.62, 0.62, 0.62),
		"sole_color": Color(0.9, 0.9, 0.88),
		"tentacle_color": Color(0.74, 0.74, 0.78),
		"tubercles": 0.3,
		"body_sss": 0.6,
		"shell_base": Color(0.87, 0.85, 0.78),
		"shell_apex": Color(0.64, 0.5, 0.34),
		"shell_inner": Color(0.9, 0.88, 0.82),
		"lip_color": Color(0.98, 0.97, 0.94),
		"flames": 0.0,
		"ribs": 44.0,
		"rib_depth": 0.15,
		"shell_gloss": 0.88,
		"glassy": 1.0,
		"apex_whorls": 1.7,
		"glide_hz": 0.7,
	}
	shape = {
		"shell": {"diam": 2.5, "whorls": 3.3, "grow": 1.95, "tube": 0.44, "round": 0.82, "spire": 0.36, "lip": 0.4, "descend": 0.16, "oblique": 0.11,
				"apex": Vector3(0.14, 0.98, 0.04), "mouth_side": Vector3(0.0, -0.1, -1.0), "mouth": Vector3(-0.02, 0.37, -0.92)},
		"body": [[1.0, 0.008, 0.005, 0.03], [0.92, 0.08, 0.04, 0.07], [0.6, 0.24, 0.14, 0.17], [0.1, 0.33, 0.2, 0.22], [-0.45, 0.36, 0.24, 0.27],
				[-0.85, 0.34, 0.27, 0.42], [-1.2, 0.31, 0.27, 0.5], [-1.55, 0.26, 0.26, 0.5, 0.02], [-1.82, 0.17, 0.22, 0.47, 0.08],
				[-1.95, 0.07, 0.13, 0.41, 0.16], [-1.99, 0.004, 0.006, 0.33, 0.24]],
		"neck": -1.05,
		"skin_cell": 0.09,
		"upper": [Vector3(0.11, 0.46, -1.74), Vector3(0.34, 0.55, -0.76), 1.05, 0.07],
		"lower": [Vector3(0.11, 0.25, -1.88), Vector3(0.45, -0.3, -0.8), 0.12, 0.035],
	}
