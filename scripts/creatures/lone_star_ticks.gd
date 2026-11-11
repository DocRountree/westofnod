class_name LoneStarTicks
extends "res://scripts/creatures/ticks.gd" # (by path: found whether or not the editor has seen the class yet)
## Lone star ticks (Amblyomma americanum), drawn at twice life size (an
## unfed female about 8 mm long): broader and rounder than the blacklegged,
## its mouthparts long; its legs a reddish orange, banded pale at the
## joints; eyes at the scutum's edges. The female: reddish brown, her
## scutum finely pitted, one silvery white spot at its tip (the lone
## star); engorging, a leathery tan, then grey olive marbled pale yellow.
## The male: brown, his back one shield, pale streaks along its back edge,
## a spot on each shoulder; the margin behind scalloped in festoons. The
## nymph: a smaller brown, no spot; the larva tiny, six legs ("seed
## ticks"), swarming. Aggressive: they come to a host, not only wait.
## Ticks: their life and how they're made. Not yet in the game
## (tools/creatures/ecology_demo.tscn).


func _init() -> void:
	super()
	top_speed = 0.009
	colors = {
		"scutum_color": Color(0.3, 0.12, 0.06),
		"body_color": Color(0.32, 0.13, 0.07),
		"nymph_color": Color(0.42, 0.24, 0.13),
		"larva_color": Color(0.6, 0.45, 0.3),
		"fed_color": Color(0.66, 0.5, 0.34),
		"full_color": Color(0.42, 0.42, 0.34),
		"full_pattern": Color(0.86, 0.7, 0.46),
		"pattern_k": 0.85,
		"leg_color": Color(0.6, 0.25, 0.1),
		"leg_band": Color(0.88, 0.76, 0.6),
		"male_color": Color(0.28, 0.11, 0.06),
		"male_mark": Color(0.85, 0.72, 0.58),
		"male_rim": 0.0,
		"male_streaks": 1.0,
		"spot_color": Color(0.97, 0.85, 0.75),
		"spot": 1.0,
		"festoons": 1.0,
		"punctate": 0.7,
	}
	shape = {
		"body_c": Vector3(0.0, 0.66, 0.1), "body_half": Vector3(1.1, 0.28, 1.3),
		"scutum": [Vector3(0.0, 0.86, -0.5), Vector3(0.75, 0.12, 0.72)],
		"conscutum": [Vector3(0.0, 0.86, 0.08), Vector3(1.02, 0.13, 1.2)],
		"eyes": true,
		"mouth": 0.55,
		"legs": [Vector2(0.45, -0.7), Vector2(0.62, -0.42), Vector2(0.68, -0.12), Vector2(0.64, 0.16)],
		"leg_len": [[0.98, 0.94, 0.77], [0.81, 0.77, 0.64], [0.81, 0.77, 0.64], [0.89, 0.85, 0.72]],
		"leg_r": 0.16,
	}


func stage_color_egg() -> Color:
	return Color(0.5, 0.3, 0.12)
