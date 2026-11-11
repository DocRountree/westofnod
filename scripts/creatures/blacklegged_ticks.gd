class_name BlackleggedTicks
extends "res://scripts/creatures/ticks.gd" # (by path: found whether or not the editor has seen the class yet)
## Blacklegged ticks (Ixodes scapularis, "deer ticks"), drawn at twice life
## size (an unfed female about 6 mm long): small, flat, teardrop-shaped,
## the mouthparts long and slender; legs black. The female: her scutum
## black, small, at her front; her soft back behind it a deep orange-red,
## engorged a bluish slate grey. The male: all dark brown, his back one
## shield (the conscutum), pale at its rim. The nymph: tiny (poppy seed),
## grey and see-through, its scutum dark; the larva tinier, pale, six legs.
## Ticks: their life and how they're made. Not yet in the game
## (tools/creatures/ecology_demo.tscn).


func _init() -> void:
	super()
	colors = {
		"scutum_color": Color(0.07, 0.045, 0.035),
		"body_color": Color(0.55, 0.14, 0.05),
		"nymph_color": Color(0.5, 0.47, 0.44),
		"larva_color": Color(0.62, 0.52, 0.42),
		"fed_color": Color(0.5, 0.38, 0.32),
		"full_color": Color(0.36, 0.36, 0.4),
		"full_pattern": Color(0.55, 0.52, 0.52),
		"pattern_k": 0.25,
		"leg_color": Color(0.08, 0.05, 0.04),
		"leg_band": Color(0.12, 0.08, 0.06),
		"male_color": Color(0.14, 0.08, 0.06),
		"male_mark": Color(0.62, 0.5, 0.4),
		"male_rim": 1.0,
		"male_streaks": 0.0,
		"spot": 0.0,
		"festoons": 0.0,
		"punctate": 0.3,
	}
	shape = {
		"body_c": Vector3(0.0, 0.62, 0.15), "body_half": Vector3(0.8, 0.26, 1.2),
		"scutum": [Vector3(0.0, 0.8, -0.55), Vector3(0.52, 0.11, 0.55)],
		"conscutum": [Vector3(0.0, 0.8, 0.12), Vector3(0.74, 0.12, 1.12)],
		"mouth": 0.62,
		"legs": [Vector2(0.38, -0.65), Vector2(0.5, -0.4), Vector2(0.55, -0.12), Vector2(0.52, 0.14)],
		"leg_len": [[0.85, 0.85, 0.68], [0.72, 0.68, 0.55], [0.72, 0.68, 0.55], [0.81, 0.77, 0.64]],
		"leg_r": 0.13,
	}


func stage_color_egg() -> Color:
	return Color(0.62, 0.36, 0.14)
