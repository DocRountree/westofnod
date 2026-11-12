class_name GreatHornedOwl
extends "res://scripts/creatures/owl.gd"
## A great horned owl (Bubo virginianus), life size: the female about 58 cm
## long, 135 across; the male a tenth smaller. Owl: how it's made and moved.
##
## Big, barrel bodied, its head broad with two long ear tufts set wide;
## mottled grey brown above, barred and blotched; its face a rusty disc
## rimmed black, white brows and bristles between great yellow eyes; a
## white bib under its chin; below buff white, barred finely dark brown
## across; its legs and toes feathered buff; its bill and claws black. Its
## eggs white, two, in another bird's old stick nest. Taking anything up
## to a turkey poult or a squirrel, from a perch. Its call five deep hoots.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 0.9
	cruise = 8.0
	top_speed = 13.0
	soar_height = 5.0
	nest_style = "sticks"
	nest_height = 3.6
	clutch = 2
	egg_size = Vector2(0.056, 0.047)
	grow_secs = 220.0
	feather_cm = 3.0
	prey_scripts = ["mouse.gd", "fox_squirrel.gd", "grey_squirrel.gd", "wild_turkey.gd"]


func mass_of() -> Vector3:
	return Vector3(1.2, 1.2, 0.2) if male else Vector3(1.6, 1.35, 0.25)


func _shape() -> Dictionary:
	return owl_shape(1.0, 1.0, 1.0, 0.0, 7.0, 1.3, 21.0, 1.0)


func _plumage(_stage: String, _male: bool) -> Dictionary:
	return owl_face(3.7, {
		"back_color": Color(0.3, 0.24, 0.18), "back_edge": Color(0.62, 0.55, 0.44), "back_bar": Color(0.1, 0.08, 0.06), "back_bars": 0.7, "mottle": 1.0, "back_streak": 0.3,
		"cap_color": Color(0.3, 0.24, 0.18),
		"disc_color": Color(0.56, 0.42, 0.3), "disc_rim": Color(0.04, 0.03, 0.03), "disc_mid": Color(0.9, 0.88, 0.82), "disc_eye": Color(0.42, 0.26, 0.14),
		"under_color": Color(0.93, 0.9, 0.84), "breast_wash": Color(0.84, 0.72, 0.56), "under_mark": Color(0.2, 0.14, 0.1), "under_pattern": 2, "under_bar_n": 4.0, "under_bar_w": 0.3, "throat_clean": 0.7,
		"fl_top": Color(0.34, 0.27, 0.2), "fl_pale": Color(0.84, 0.76, 0.64), "fl_dark": Color(0.24, 0.18, 0.13), "fl_bars": 7.0,
		"tail_color": Color(0.46, 0.38, 0.28), "tail_band": Color(0.14, 0.1, 0.08), "tail_bands": 6.5, "tail_band_w": 0.4, "tail_tip_r": Color(0.7, 0.62, 0.5),
		"bill_color": Color(0.1, 0.1, 0.1), "cere_color": Color(0.3, 0.28, 0.26), "iris": Color(0.98, 0.8, 0.1),
		"leg_color": Color(0.62, 0.55, 0.45), "lid_color": Color(0.6, 0.5, 0.4), "down_white": Color(0.86, 0.84, 0.78),
	})
