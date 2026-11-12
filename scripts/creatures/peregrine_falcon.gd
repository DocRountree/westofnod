class_name PeregrineFalcon
extends "res://scripts/creatures/raptor.gd" # (by path: found whether or not the editor has seen the class yet)
## A peregrine falcon (Falco peregrinus, the North American anatum), life
## size: the female (the falcon) about 45 cm long, a metre and ten across;
## the male (the tiercel) a third lighter. Raptor: how it's made and moved.
##
## The adult: slate blue grey above, each feather barred darker, edged
## paler; a black hood down over its nape and the broad black moustache
## below its eye; white cheeks, throat and upper breast (the female's
## washed buff), spotted on the breast, barred black below it, on its
## flanks and its trousers; long pointed wings, the outer primaries
## longest, from below white barred dark; the tail grey, barred black, its
## tip white; a yellow cere, eye ring and feet, the bill blue grey, its tip
## dark, toothed; the eye dark brown. The juvenile: brown above edged buff,
## buff below streaked dark brown, its cere and eye ring blue grey. Its
## eggs reddish brown, heavily blotched, four in a scrape on a ledge.
## Hunting birds in the air: ringing up high over its prey, then the stoop.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 0.86
	cruise = 12.0
	top_speed = 22.0
	stoop_speed = 45.0
	soar_height = 32.0
	hunt_style = "stoop"
	nest_style = "scrape"
	nest_height = 2.8
	clutch = 4
	egg_size = Vector2(0.052, 0.041)
	egg_colors = [Color(0.66, 0.44, 0.33), Color(0.42, 0.15, 0.08)]
	beat_amp = 0.7
	grow_secs = 220.0
	tail_rest = -0.91
	flight_pitch = 0.91
	fold_pitch = 0.91


func mass_of() -> Vector3:
	return Vector3(0.62, 0.98, 0.11) if male else Vector3(0.95, 1.1, 0.14)


func _shape() -> Dictionary:
	return {
		"tilt_rings": true,
		# (sat low, leaning forward, its head on its shoulders)
		"spine": [[14.0, 13.0, 1.0, 1.0, 0.0], [15.0, 11.0, 4.0, 3.5, 0.0], [16.5, 8.0, 5.2, 6.0, 0.0], [19.5, 4.8, 5.8, 7.4, 0.0], [23.5, 2.0, 6.0, 7.8, 0.0],
				[27.5, 0.0, 5.6, 7.0, 0.0], [30.5, -1.0, 4.6, 5.6, 0.2], [32.6, -1.5, 3.7, 3.9, 1.0], [34.2, -2.0, 3.1, 3.3, 2.0], [35.5, -2.7, 2.8, 3.0, 3.0],
				[36.5, -3.6, 2.6, 2.9, 4.0], [37.1, -4.8, 2.5, 2.7, 4.5], [36.8, -6.4, 2.1, 2.3, 4.85], [36.1, -7.5, 1.3, 1.5, 5.0],
				[35.7, -8.1, 1.0, 1.1, 5.05], [35.1, -8.8, 0.7, 0.75, 5.5], [34.2, -9.2, 0.3, 0.3, 5.85], [33.5, -9.05, 0.08, 0.08, 6.0]],
		"pivot": Vector3(0.0, 21.0, 4.0),
		"jaw": Vector3(0.0, 35.4, -7.7),
		"lower_bill": [[35.3, -7.9, 0.8], [34.9, -8.6, 0.5], [34.5, -9.0, 0.15]],
		"eye": Vector3(1.95, 37.1, -5.9), "eye_r": 0.72, "eye_ring": 1.3,
		"cere": [Vector3(0.0, 36.35, -7.5), Vector3(1.0, 0.75, 0.6)],
		# (its legs short: feathered trousers down nearly to its feet, a little yellow showing)
		"hip": Vector3(3.2, 17.0, 4.0), "knee": Vector3(3.8, 12.5, 0.5), "ankle": Vector3(3.4, 4.2, 1.5), "foot": Vector3(3.4, 1.3, 0.0),
		"thigh_r": [4.4, 3.2], "leg_r": 0.6, "toes": [5.0, 3.6, 2.6], "claw": 0.36, "claw_r": 0.55, "tuck": Vector3(0.0, -0.05, 0.0),
		"tail": Vector3(0.0, 14.5, 12.0),
		# (its folded wing broad, from its neck's base down over its side to its tail's tip)
		"shoulder": Vector3(6.2, 30.0, 1.0), "wing": Vector3(8.5, 10.5, 7.5), "coverts": [2.0, 5.0, 4.0, 2.0], "wing_thick": [1.1, 0.8, 0.5, 0.25],
		"fold_fan": Vector3(0.3, 0.42, 0.1), "fold_tuck": 0.2,
		"primaries": [13.0, 14.0, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 23.5, 22.0], "secondaries": [12, 14.0, 12.0], "tertials": [3, 11.0, 9.0], "feather_w": 4.2,
		"tail_feathers": [12, 16.0, 3.8], "tail_coverts": [[10, 9.0, 3.5, 0.5, 0.9]],
	}


func _plumage(stage: String, male_: bool) -> Dictionary:
	if stage == "juvenile":
		return {
			"back_color": Color(0.26, 0.2, 0.15), "back_edge": Color(0.62, 0.46, 0.3), "back_bar": Color(0.2, 0.15, 0.11), "back_bars": 0.0, "back_from": 0.22,
			"cap_color": Color(0.2, 0.15, 0.11), "cheek_color": Color(0.85, 0.74, 0.58), "hood_low": 0.0, "hood_nape": 0.6, "malar": 1.0,
			"under_color": Color(0.86, 0.74, 0.56), "breast_wash": Color(0.84, 0.7, 0.5), "under_mark": Color(0.26, 0.18, 0.12), "under_pattern": 3, "throat_clean": 0.76,
			"fl_top": Color(0.22, 0.18, 0.14), "fl_pale": Color(0.78, 0.68, 0.54), "fl_dark": Color(0.25, 0.19, 0.14), "fl_bars": 11.0,
			"tail_color": Color(0.3, 0.23, 0.17), "tail_band": Color(0.72, 0.6, 0.44), "tail_bands": 8.0, "tail_band_w": 0.3, "tail_tip_r": Color(0.8, 0.7, 0.55), "tail_tip_w": 0.04,
			"cere_color": Color(0.6, 0.66, 0.72), "bill_color": Color(0.45, 0.5, 0.58), "bill_tip": Color(0.08, 0.08, 0.1), "iris": Color(0.1, 0.06, 0.04),
			"leg_color": Color(0.8, 0.82, 0.55),
		}
	return {
		"back_color": Color(0.25, 0.28, 0.33) if male_ else Color(0.22, 0.24, 0.28), "back_edge": Color(0.5, 0.54, 0.6), "back_bar": Color(0.11, 0.12, 0.14), "back_bars": 0.7, "back_from": 0.22,
		"cap_color": Color(0.06, 0.065, 0.08), "cheek_color": Color(0.96, 0.95, 0.92), "hood_low": 0.002, "hood_nape": 1.0, "malar": 1.0,
		"under_color": Color(0.95, 0.94, 0.9) if male_ else Color(0.93, 0.88, 0.8), "breast_wash": Color(0.97, 0.95, 0.9) if male_ else Color(0.92, 0.84, 0.72),
		"under_mark": Color(0.1, 0.1, 0.12), "under_pattern": 1, "throat_clean": 0.7,
		"fl_top": Color(0.17, 0.18, 0.21), "fl_pale": Color(0.88, 0.87, 0.84), "fl_dark": Color(0.18, 0.18, 0.2), "fl_bars": 12.0,
		"tail_color": Color(0.32, 0.35, 0.4), "tail_band": Color(0.08, 0.08, 0.1), "tail_bands": 8.0, "tail_band_w": 0.32, "tail_tip_r": Color(0.92, 0.9, 0.86), "tail_tip_w": 0.035,
		"cere_color": Color(0.96, 0.78, 0.12), "bill_color": Color(0.52, 0.58, 0.66), "bill_tip": Color(0.07, 0.07, 0.09), "iris": Color(0.1, 0.06, 0.035),
		"leg_color": Color(0.98, 0.8, 0.1),
	}
