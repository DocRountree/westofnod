class_name CoopersHawk
extends "res://scripts/creatures/raptor.gd" # (by path: found whether or not the editor has seen the class yet)
## A Cooper's hawk (Accipiter cooperii), life size: the female about 42 cm
## long, 85 across; the male a third smaller (the size of a crow, she; of
## a jay, nearly, he). Raptor: how it's made and moved.
##
## The adult: blue grey above (the male bluer, the female browner); a
## dark cap, its nape paler; rosy grey cheeks; its underparts barred
## orange rufous and white, finely, its undertail white; short rounded
## wings, from below pale, barred dark; a long rounded tail, grey with
## three or four broad black bands, its tip broadly white; a bony brow
## over its eye (its scowl); the eye red orange (the male's deeper red);
## a yellow cere and long slender yellow legs. The juvenile: brown above
## edged rufous, white below streaked brown, its head brown streaked, its
## eye yellow. Its eggs pale bluish white, four in a stick nest. Hunting
## birds and small mammals by ambush: low and fast off a hidden perch, a
## twisting chase through cover, feet thrust out. Flying flap-flap-glide.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 0.82
	cruise = 9.0
	top_speed = 16.0
	stoop_speed = 0.0
	soar_height = 22.0
	flaps_glide = true
	hunt_style = "dash"
	nest_style = "sticks"
	nest_height = 3.4
	clutch = 4
	egg_size = Vector2(0.048, 0.038)
	egg_colors = [Color(0.86, 0.88, 0.86), Color(0.86, 0.88, 0.86)]
	beat_amp = 0.85
	grow_secs = 200.0
	tail_rest = -0.91
	flight_pitch = 0.91
	fold_pitch = 0.91


func mass_of() -> Vector3:
	return Vector3(0.35, 0.72, 0.075) if male else Vector3(0.53, 0.86, 0.1)


func _shape() -> Dictionary:
	return {
		"tilt_rings": true,
		# (leaning forward on its perch, its head on its shoulders; slimmer than the falcon)
		"spine": [[13.5, 13.0, 1.0, 1.0, 0.0], [14.6, 11.0, 3.6, 3.3, 0.0], [16.2, 8.0, 4.3, 5.5, 0.0], [19.2, 4.8, 4.7, 6.8, 0.0], [23.0, 2.0, 4.9, 7.0, 0.0],
				[27.0, 0.0, 4.6, 6.3, 0.0], [30.0, -1.0, 3.9, 5.0, 0.2], [32.0, -1.5, 3.3, 3.6, 1.0], [33.6, -2.0, 2.9, 3.1, 2.0], [34.9, -2.7, 2.6, 2.8, 3.0],
				[35.9, -3.6, 2.4, 2.7, 4.0], [36.5, -4.7, 2.3, 2.5, 4.5], [36.2, -6.2, 1.9, 2.1, 4.85], [35.5, -7.2, 1.2, 1.4, 5.0],
				[35.1, -7.7, 0.9, 1.0, 5.05], [34.5, -8.3, 0.62, 0.65, 5.5], [33.7, -8.65, 0.26, 0.26, 5.85], [33.0, -8.5, 0.07, 0.07, 6.0]],
		"pivot": Vector3(0.0, 20.0, 4.0),
		"jaw": Vector3(0.0, 34.8, -7.3),
		"lower_bill": [[34.7, -7.5, 0.7], [34.3, -8.1, 0.45], [34.0, -8.45, 0.13]],
		"eye": Vector3(1.8, 36.3, -5.7), "eye_r": 0.62,
		"brow": [Vector3(1.6, 36.9, -5.85), Vector3(0.75, 0.32, 1.05)],
		"cere": [Vector3(0.0, 35.75, -7.15), Vector3(0.9, 0.7, 0.55)],
		# (its legs long and slender, an accipiter's: more yellow showing below its trousers than a falcon's)
		"hip": Vector3(2.9, 16.5, 4.0), "knee": Vector3(3.3, 12.5, 0.5), "ankle": Vector3(2.9, 6.5, 1.5), "foot": Vector3(2.9, 1.2, 0.0),
		"thigh_r": [3.6, 2.4], "leg_r": 0.42, "toes": [4.6, 3.3, 2.4], "claw": 0.33, "claw_r": 0.5, "tuck": Vector3(0.0, -0.05, 0.0),
		"tail": Vector3(0.0, 14.0, 12.0),
		"shoulder": Vector3(5.0, 25.5, 4.6), "wing": Vector3(7.5, 9.0, 6.0), "coverts": [2.0, 4.6, 3.6, 2.0], "fold_fan": Vector3(0.3, 0.4, 0.08), "fold_tuck": 0.12, "wing_thick": [1.0, 0.75, 0.5, 0.25],
		"primaries": [11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 16.5, 16.5, 15.5, 13.0], "secondaries": [11, 13.0, 11.5], "tertials": [3, 10.0, 8.5], "feather_w": 4.4,
		"tail_feathers": [12, 21.0, 4.0], "tail_coverts": [[10, 8.0, 3.5, 0.5, 0.9]],
	}


func _plumage(stage: String, male_: bool) -> Dictionary:
	if stage == "juvenile":
		return {
			"back_color": Color(0.3, 0.22, 0.15), "back_edge": Color(0.58, 0.38, 0.22), "back_bar": Color(0.22, 0.16, 0.11), "back_bars": 0.0, "back_from": 0.22, "back_from_hi": 0.13,
			"cap_color": Color(0.36, 0.25, 0.16), "cheek_color": Color(0.7, 0.55, 0.4), "cheek": 0.5, "hood_low": -0.004, "hood_nape": 0.0, "malar": 0.0,
			"under_color": Color(0.95, 0.93, 0.88), "breast_wash": Color(0.93, 0.88, 0.8), "under_mark": Color(0.36, 0.24, 0.15), "under_pattern": 3, "throat_clean": 0.84,
			"fl_top": Color(0.28, 0.21, 0.15), "fl_pale": Color(0.82, 0.76, 0.68), "fl_dark": Color(0.26, 0.2, 0.15), "fl_bars": 7.0,
			"tail_color": Color(0.46, 0.37, 0.28), "tail_band": Color(0.12, 0.09, 0.07), "tail_bands": 4.6, "tail_band_w": 0.3, "tail_tip_r": Color(0.9, 0.88, 0.84), "tail_tip_w": 0.05,
			"cere_color": Color(0.88, 0.85, 0.45), "bill_color": Color(0.32, 0.34, 0.38), "bill_tip": Color(0.06, 0.06, 0.07), "iris": Color(0.95, 0.85, 0.25),
			"leg_color": Color(0.96, 0.84, 0.25),
		}
	return {
		"back_color": Color(0.32, 0.36, 0.42) if male_ else Color(0.34, 0.34, 0.36), "back_edge": Color(0.42, 0.45, 0.5) if male_ else Color(0.44, 0.42, 0.42),
		"back_bar": Color(0.25, 0.27, 0.3), "back_bars": 0.2, "back_from": 0.22, "back_from_hi": 0.13,
		"cap_color": Color(0.1, 0.11, 0.13), "cheek_color": Color(0.72, 0.6, 0.55), "cheek": 1.0, "hood_low": -0.002, "hood_nape": 0.0, "malar": 0.0,
		"under_color": Color(0.96, 0.94, 0.9), "breast_wash": Color(0.95, 0.9, 0.84), "under_mark": Color(0.8, 0.4, 0.16), "under_pattern": 2, "throat_clean": 0.8,
		"fl_top": Color(0.3, 0.32, 0.36), "fl_pale": Color(0.88, 0.86, 0.82), "fl_dark": Color(0.25, 0.25, 0.27), "fl_bars": 7.0,
		"tail_color": Color(0.44, 0.45, 0.48), "tail_band": Color(0.08, 0.08, 0.09), "tail_bands": 4.6, "tail_band_w": 0.32, "tail_tip_r": Color(0.96, 0.95, 0.93), "tail_tip_w": 0.06,
		"cere_color": Color(0.96, 0.8, 0.2), "bill_color": Color(0.26, 0.28, 0.32), "bill_tip": Color(0.05, 0.05, 0.06),
		"iris": Color(0.72, 0.08, 0.04) if male_ else Color(0.9, 0.36, 0.05),
		"leg_color": Color(0.98, 0.82, 0.2),
	}
