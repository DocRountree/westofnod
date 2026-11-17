class_name CommonOctopus
extends "res://scripts/creatures/octopus.gd"
## The common octopus (Octopus vulgaris), life size: its mantle about 20 cm,
## its arms about three times that (some 1.5 m across, spread); grey brown
## to reddish brown, mottled, with pale spots, able to go any colour of the
## bottom it's on in a moment and back; small horns over its eyes. Shallow
## warm seas, on rock and rubble, in a den; most about at dusk and night.
## Octopus (octopus.gd) has the rest.


func _species() -> void:
	FIG = {"ml": 0.2, "al": 0.65, "r0": 0.022, "crown_r": 0.03, "crown_y": 0.035, "web": 0.17, "walk": 0.08, "jet": 1.5,
			"base": Color(0.52, 0.4, 0.3), "dark": Color(0.28, 0.17, 0.11), "spot": Color(0.9, 0.86, 0.78), "spots": 0.25, "horn": 0.8}
