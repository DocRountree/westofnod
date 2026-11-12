class_name FlamedTigersnails
extends "res://scripts/creatures/snails.gd" # (by path: found whether or not the editor has seen the class yet)
## Flamed tigersnails (Anguispira alternata, the "flamed disc"), drawn at
## twice life size (the shell about 40 mm across): a low, rounded cone of
## five and a half whorls, finely and closely ribbed, the umbilicus open
## beneath; a horn brown, blotched across its whorls by rows of ragged
## reddish brown flames, each row's set off the last's (on its underside
## too); the first whorls plain. The body a warm tan, orange
## toward its head, its skin a network of grooves round low bumps; the
## tentacles long, lavender grey, the eyes black at their tips. Of
## woodland litter and rotting logs, eating fungi, rotting leaves and
## wood. Mating each other (they've no love dart); selfing rarely. Snails:
## how they're made and moved. Not yet in the game
## (tools/creatures/ecology_demo.tscn).


func _init() -> void:
	super()
	top_speed = 0.0028 # (about 1.4 mm/s, twice life size)
	reach = 18.5
	apart = 22.0
	egg_kind = "tigersnail"
	clutch = 10
	self_rate = 0.12
	grow_secs = 300.0
	colors = {
		"body_color": Color(0.7, 0.46, 0.27),
		"body_dark": Color(0.34, 0.21, 0.14),
		"sole_color": Color(0.8, 0.7, 0.56),
		"tentacle_color": Color(0.46, 0.43, 0.5),
		"tubercles": 1.0,
		"shell_base": Color(0.66, 0.52, 0.31),
		"shell_flame": Color(0.36, 0.11, 0.06),
		"shell_apex": Color(0.66, 0.52, 0.36),
		"shell_inner": Color(0.88, 0.82, 0.72),
		"band_color": Color(0.36, 0.2, 0.13),
		"band": 0.75,
		"flames": 13.0,
		"ribs": 62.0,
		"rib_depth": 1.0,
		"shell_gloss": 0.6,
		"apex_whorls": 1.4,
		"glide_hz": 0.5,
	}
	shape = {
		"shell": {"diam": 20.0, "whorls": 5.4, "grow": 1.48, "tube": 0.52, "round": 0.86, "spire": 0.8, "keel": 0.05, "oblique": 0.07,
				"apex": Vector3(0.4, 0.9, 0.12), "mouth_side": Vector3(0.0, -0.2, -1.0), "mouth": Vector3(0.7, 5.5, -6.3)},
		"body": [[10.8, 0.05, 0.03, 0.25], [10.3, 0.9, 0.4, 0.8], [8.0, 2.5, 1.5, 2.0], [4.0, 3.6, 2.7, 3.7], [-1.0, 3.9, 3.1, 4.8],
				[-6.0, 3.7, 2.9, 5.2], [-10.0, 3.3, 2.65, 5.4], [-14.0, 3.0, 2.55, 5.5, 0.05], [-16.8, 2.5, 2.5, 5.5, 0.5],
				[-18.3, 1.7, 2.2, 5.3, 1.3], [-19.1, 0.7, 1.4, 4.7, 2.1], [-19.4, 0.03, 0.05, 3.9, 2.9]],
		"neck": -10.5,
		"skin_cell": 0.62,
		"upper": [Vector3(1.2, 5.1, -17.5), Vector3(0.36, 0.6, -0.72), 9.0, 0.62],
		"lower": [Vector3(1.2, 2.9, -18.7), Vector3(0.5, -0.3, -0.8), 2.0, 0.36],
	}
