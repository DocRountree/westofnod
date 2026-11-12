class_name BaldEagle
extends "res://scripts/creatures/eagle.gd"
## A bald eagle (Haliaeetus leucocephalus), life size: the female about
## 90 cm long, 2.1 m across, 5 kg; the male smaller. Eagle: how it's made
## and moved.
##
## The adult (its fifth year on): dark chocolate brown, body and wings;
## its head and neck white, the white ragged where it meets the brown; its
## tail and its coverts white, wedge tipped; its great hooked bill, its
## cere and its feet yellow, its eye pale yellow under a heavy brow; its
## legs feathered brown to the ankle, bare below. The juvenile brown, its
## underparts, underwing and tail blotched white; its head dark, its bill
## blackish, its eye brown. Its eggs dull white, two, in a great platform
## of sticks. Fishing (a fish snatched from the surface in its feet), and
## at carrion; taking a hare or a poult now and then. Soaring on flat
## wings. Its call a high chittering, its head thrown back.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 0.88
	fishes = true
	head_back_call = true
	hunt_style = "dash"
	stoop_speed = 0.0
	egg_size = Vector2(0.073, 0.054)
	egg_colors = [Color(0.93, 0.92, 0.86), Color(0.93, 0.92, 0.86)]
	prey_scripts = ["hare.gd", "wild_turkey.gd"]


func mass_of() -> Vector3:
	return Vector3(4.1, 1.95, 0.68) if male else Vector3(5.2, 2.15, 0.8)


func _shape() -> Dictionary:
	return eagle_shape(1.18, 1.06, 13.5 * 2.1, false)


func _plumage(stage: String, _male: bool) -> Dictionary:
	var brown := Color(0.19, 0.13, 0.085)
	if stage == "juvenile":
		var jb := Color(0.3, 0.21, 0.13)
		return {
			"back_color": jb, "back_edge": Color(0.72, 0.64, 0.52), "back_bar": Color(0.18, 0.13, 0.08), "back_bars": 0.0, "mottle": 0.55, "back_from": 0.22, "back_from_hi": 0.13,
			"cap_color": Color(0.26, 0.18, 0.11), "cheek_color": Color(0.36, 0.26, 0.17), "cheek": 0.6, "hood_low": -0.004, "hood_nape": 0.0, "malar": 0.0,
			"under_color": jb, "breast_wash": jb, "under_mark": Color(0.88, 0.84, 0.76), "under_pattern": 6, "under_blotch": 1.0, "throat_clean": 0.9,
			"fl_top": Color(0.2, 0.15, 0.1), "fl_pale": Color(0.72, 0.66, 0.56), "fl_dark": Color(0.2, 0.15, 0.1), "fl_bars": 4.0,
			"tail_color": Color(0.7, 0.64, 0.56), "tail_band": Color(0.24, 0.18, 0.12), "tail_bands": 3.0, "tail_band_w": 0.45, "tail_tip_r": Color(0.2, 0.15, 0.1), "tail_tip_w": 0.14,
			"cere_color": Color(0.42, 0.4, 0.36), "bill_color": Color(0.2, 0.19, 0.19), "bill_tip": Color(0.08, 0.08, 0.08), "iris": Color(0.32, 0.21, 0.12),
			"leg_color": Color(0.95, 0.8, 0.3), "down_white": Color(0.68, 0.66, 0.63),
		}
	return {
		"back_color": brown, "back_edge": Color(0.25, 0.18, 0.12), "back_bar": Color(0.12, 0.085, 0.055), "back_bars": 0.25, "back_from": 0.22, "back_from_hi": 0.13,
		"cap_color": Color(0.96, 0.96, 0.94), "hood_u": 0.3, "hood_low": 0.05, "hood_nape": 1.0, "cheek": 0.0, "malar": 0.0,
		"under_color": brown, "breast_wash": brown, "under_mark": brown, "under_pattern": 0, "throat_clean": 0.9,
		"fl_top": Color(0.13, 0.1, 0.07), "fl_pale": Color(0.24, 0.19, 0.14), "fl_dark": Color(0.11, 0.08, 0.06), "fl_bars": 2.0,
		"tail_color": Color(0.96, 0.95, 0.92), "tail_band": Color(0.96, 0.95, 0.92), "tail_bands": 1.0, "tail_band_w": 0.0, "tail_tip_r": Color(0.96, 0.95, 0.92), "tail_tip_w": 0.02,
		"tail_cov": Color(0.95, 0.94, 0.91, 1.0), "tail_under": 0.0,
		"cere_color": Color(0.97, 0.8, 0.26), "bill_color": Color(0.98, 0.8, 0.22), "bill_tip": Color(0.95, 0.72, 0.18), "iris": Color(0.96, 0.92, 0.62),
		"leg_color": Color(0.98, 0.8, 0.22), "down_white": Color(0.68, 0.66, 0.63),
	}
