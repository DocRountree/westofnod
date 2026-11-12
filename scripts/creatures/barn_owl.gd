class_name BarnOwl
extends "res://scripts/creatures/owl.gd"
## A barn owl (Tyto alba), life size: about 37 cm long, 105 across, the
## female a little the larger and darker. Owl: how it's made and moved.
##
## Pale, slim, long legged, its head big and smooth (no tufts); its face a
## white heart, rimmed tawny, its eyes small and black, set close, a dusky
## smudge at each one's inner corner, its long bill ivory; golden buff
## above washed with pearl grey, each feather tipped with a white spot,
## black above it; white below (the female buff), sparsely spotted dark;
## long wings, from below white. Its eggs white, five, laid on the bare
## floor of a hollow or a loft. Quartering low and slow over rough grass,
## dropping on mice. Its call a long hissing shriek.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 0.95
	cruise = 6.5
	top_speed = 10.0
	soar_height = 3.0
	nest_style = "scrape"
	nest_height = 2.8
	clutch = 5
	egg_size = Vector2(0.043, 0.033)
	grow_secs = 200.0
	feather_cm = 2.4


func mass_of() -> Vector3:
	return Vector3(0.45, 1.0, 0.14) if male else Vector3(0.55, 1.07, 0.155)


func _shape() -> Dictionary:
	return owl_shape(0.66, 0.76, 1.08, 4.0, 0.0, 0.85, 19.0, 1.28, 1.0)


func _plumage(_stage: String, male_: bool) -> Dictionary:
	var under := Color(0.97, 0.96, 0.93) if male_ else Color(0.93, 0.84, 0.68)
	return owl_face(3.0, {
		"disc_heart": 1.0, "eye_dir": Vector3(0.1, 0.0, -1.0),
		"back_color": Color(0.74, 0.55, 0.3), "back_edge": Color(0.6, 0.6, 0.6), "back_bar": Color(0.42, 0.4, 0.4), "back_bars": 0.0, "mottle": 0.7, "back_spot": 1.0,
		"cap_color": Color(0.74, 0.55, 0.3),
		"disc_color": Color(0.97, 0.96, 0.94), "disc_rim": Color(0.6, 0.4, 0.22), "disc_mid": Color(0.97, 0.96, 0.94), "disc_mid_a": 0.0, "disc_eye": Color(0.5, 0.34, 0.24),
		"under_color": under, "breast_wash": under, "under_mark": Color(0.2, 0.16, 0.14), "under_pattern": 4, "throat_clean": 0.84,
		"fl_top": Color(0.72, 0.56, 0.34), "fl_pale": Color(0.97, 0.96, 0.93), "fl_dark": Color(0.6, 0.56, 0.5), "fl_bars": 5.0,
		"tail_color": Color(0.8, 0.64, 0.4), "tail_band": Color(0.42, 0.36, 0.3), "tail_bands": 4.5, "tail_band_w": 0.22, "tail_tip_r": Color(0.95, 0.93, 0.88),
		"bill_color": Color(0.9, 0.84, 0.74), "bill_tip": Color(0.8, 0.74, 0.64), "cere_color": Color(0.9, 0.8, 0.74), "iris": Color(0.02, 0.02, 0.02),
		"leg_color": Color(0.7, 0.66, 0.6), "lid_color": Color(0.9, 0.86, 0.82),
	})
