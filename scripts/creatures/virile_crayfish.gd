class_name VirileCrayfish
extends "res://scripts/creatures/crayfish.gd" # (by path: found whether or not the editor has seen the class yet)
## The virile crayfish (Faxonius virilis), about 12 cm: olive brown to
## rust, darker speckled; paired dark blotches down its abdomen; its claws
## broad and flattened, blue green, mottled, studded with yellow to orange
## tubercles, the fingertips orange; its legs pale green blue; its areola
## open, wide. It shelters under stones and in short burrows (no chimney).
## (Crayfish: its ways.)


func _spec() -> Dictionary:
	return {
		"size": 1.08,
		"shell": Color(0.4, 0.29, 0.13), "back": Color(0.2, 0.13, 0.06), "tail": Color(0.44, 0.32, 0.15),
		"claw": Color(0.2, 0.4, 0.37), "claw_mottle": 0.4, "tuber": Color(0.98, 0.7, 0.3), "tip": Color(0.88, 0.36, 0.1),
		"leg": Color(0.5, 0.58, 0.5), "dots": Color(0.2, 0.13, 0.06), "dot_n": 70, "dot_r": 0.4,
		"antenna": Color(0.45, 0.33, 0.2), "egg": Color(0.2, 0.12, 0.05),
		"palm_w": 6.0, "palm_h": 2.6, "palm_l": 17.0, "finger_l": 15.0, "merus_r": 2.0,
		"tuber_n": 45, "tuber_r": 0.6, "areola": 3.2, "wedge": false, "blotch": true, "spines": false, "chimney": false,
	}
