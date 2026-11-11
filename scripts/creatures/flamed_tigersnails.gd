class_name FlamedTigersnails
extends "res://scripts/creatures/snails.gd" # (by path: found whether or not the editor has seen the class yet)
## Flamed tigersnails (Anguispira alternata, the "flamed disc"), drawn at
## twice life size (the shell about 40 mm across): a low, rounded cone of
## five and a half whorls, finely and closely ribbed, the umbilicus wide
## open beneath; a warm yellowish horn colour, streaked across its whorls
## by slanting reddish brown flames (on its underside too), a little paler
## round its shoulder; the first whorls plain. The body a warm tan, orange
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
		"body_color": Color(0.74, 0.52, 0.32),
		"body_dark": Color(0.44, 0.3, 0.2),
		"sole_color": Color(0.8, 0.7, 0.56),
		"tentacle_color": Color(0.46, 0.43, 0.5),
		"tubercles": 1.0,
		"shell_base": Color(0.8, 0.62, 0.34),
		"shell_flame": Color(0.46, 0.15, 0.07),
		"shell_apex": Color(0.66, 0.52, 0.36),
		"shell_inner": Color(0.88, 0.82, 0.72),
		"flames": 12.0,
		"ribs": 34.0,
		"rib_depth": 0.9,
		"shell_gloss": 0.55,
		"apex_whorls": 1.4,
		"glide_hz": 0.5,
	}
	shape = {
		"shell": {"diam": 20.0, "whorls": 5.4, "grow": 1.48, "tube": 0.4, "round": 0.84, "spire": 0.85,
				"apex": Vector3(-0.85, 0.45, 0.15), "mouth_side": Vector3(0.1, -1.0, 0.25), "mouth": Vector3(0.6, 0.0, 0.5)},
		"body": [[17.4, 0.05, 0.3], [17.0, 0.3, 0.7], [13.0, 1.9, 2.4], [6.0, 3.0, 3.8], [0.0, 3.3, 4.5], [-6.0, 3.2, 5.0], [-11.0, 2.8, 5.4],
				[-15.0, 2.4, 5.2], [-17.8, 1.7, 4.0], [-19.2, 0.6, 2.2], [-19.5, 0.05, 1.2]],
		"neck": -9.5,
		"upper": [Vector3(0.85, 4.8, -15.0), Vector3(0.32, 0.72, -0.62), 8.0, 0.42],
		"lower": [Vector3(1.1, 2.2, -18.2), Vector3(0.45, -0.25, -0.85), 2.2, 0.36],
	}
