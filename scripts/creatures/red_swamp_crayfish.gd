class_name RedSwampCrayfish
extends "res://scripts/creatures/crayfish.gd" # (by path: found whether or not the editor has seen the class yet)
## The red swamp crayfish (Procambarus clarkii), about 11 cm: dark red to
## near black, its carapace spattered with pale dots; a black wedge down its
## abdomen; its claws long and narrow, bright red, crowded with red
## tubercles, spined along the merus and carpus, the fingertips dark; its
## legs red-orange; its areola shut to a line. It wanders on land, and digs
## its burrows with chimneys of mud pellets. (Crayfish: its ways.)


func _spec() -> Dictionary:
	return {
		"size": 1.0,
		"shell": Color(0.26, 0.04, 0.035), "back": Color(0.05, 0.015, 0.012), "tail": Color(0.32, 0.05, 0.035),
		"claw": Color(0.72, 0.07, 0.04), "claw_mottle": 0.12, "tuber": Color(0.95, 0.16, 0.08), "tip": Color(0.18, 0.02, 0.02),
		"leg": Color(0.6, 0.15, 0.06), "dots": Color(0.95, 0.92, 0.84), "dot_n": 120, "dot_r": 0.45,
		"antenna": Color(0.38, 0.1, 0.05), "egg": Color(0.12, 0.05, 0.04),
		"palm_w": 3.4, "palm_h": 2.9, "palm_l": 20.0, "finger_l": 21.0, "merus_r": 1.8,
		"tuber_n": 55, "tuber_r": 0.55, "areola": 0.6, "wedge": true, "blotch": false, "spines": true, "chimney": true,
	}
