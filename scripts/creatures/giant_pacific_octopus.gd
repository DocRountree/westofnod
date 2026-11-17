class_name GiantPacificOctopus
extends "res://scripts/creatures/octopus.gd"
## The giant Pacific octopus (Enteroctopus dofleini), life size: the
## largest octopus, its mantle about 45 cm, its arms 1.5 m (some 3 m and
## more across); reddish brown, its skin loose and wrinkled, set with flaps
## and papillae and pale spots, a tall horn over each eye; its suckers up to
## 6 cm across near its arms' bases. Cold northern Pacific waters, in dens
## under rock (a midden of crab and clam shells out front); out at night.
## Octopus (octopus.gd) has the rest.


func _species() -> void:
	FIG = {"ml": 0.45, "al": 1.5, "r0": 0.055, "crown_r": 0.075, "crown_y": 0.08, "web": 0.2, "walk": 0.14, "jet": 2.2,
			"base": Color(0.62, 0.27, 0.18), "dark": Color(0.36, 0.11, 0.07), "spot": Color(0.92, 0.82, 0.75), "spots": 0.45, "horn": 1.4}
	brood_secs = 900.0
