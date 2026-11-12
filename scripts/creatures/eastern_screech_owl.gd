class_name EasternScreechOwl
extends "res://scripts/creatures/owl.gd"
## An eastern screech owl (Megascops asio), life size: about 22 cm long,
## 52 across (a robin's length, stocky); the female a little the larger.
## Owl: how it's made and moved.
##
## Small, big headed, short tailed, its ear tufts short; grey (or, one in
## three, bright rufous: red := true), patterned like bark: each feather
## above streaked black down its shaft and finely barred, a row of white
## spots along its shoulders; its face pale grey, finely ringed, rimmed
## black at the sides; yellow eyes; a greenish yellow bill; below white,
## each feather streaked dark and barred across. Its eggs white, four, in
## a woodpecker's old hole. Taking mice and big insects from a low perch.
## Its call a descending whinny and a long even trill.

var red := false ## the rufous morph


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	red = randf() < 0.33
	male_size = 0.92
	cruise = 6.0
	top_speed = 9.5
	soar_height = 2.5
	nest_style = "scrape"
	nest_height = 2.4
	clutch = 4
	egg_size = Vector2(0.036, 0.03)
	grow_secs = 180.0
	feather_cm = 1.7


func mass_of() -> Vector3:
	return Vector3(0.165, 0.5, 0.036) if male else Vector3(0.195, 0.55, 0.04)


func _mesh_key() -> String:
	return super() + ("r" if red else "")


func _shape() -> Dictionary:
	return owl_shape(0.4, 1.04, 1.14, 0.0, 3.2, 1.5, 15.0, 1.0)


func _plumage(_stage: String, _male: bool) -> Dictionary:
	var back := Color(0.62, 0.3, 0.13) if red else Color(0.42, 0.4, 0.37)
	var pale := Color(0.86, 0.62, 0.42) if red else Color(0.74, 0.72, 0.68)
	var mark := Color(0.3, 0.12, 0.05) if red else Color(0.07, 0.06, 0.06)
	return owl_face(3.1 * 0.4 * 1.14, {
		"back_color": back, "back_edge": pale, "back_bar": mark, "back_bars": 0.0 if red else 0.5, "mottle": 0.35 if red else 0.8, "back_streak": 0.9,
		"cap_color": back,
		"disc_color": Color(0.84, 0.56, 0.36) if red else Color(0.7, 0.68, 0.65), "disc_rim": Color(0.05, 0.04, 0.04), "disc_mid": Color(0.92, 0.9, 0.86), "disc_eye": Color(0.5, 0.3, 0.18) if red else Color(0.4, 0.38, 0.36),
		"disc_rim_w": 0.16, "disc_low": 0.72, "disc_brow": 0.8, "disc_rim_sides": 0.75, "eye_lid": 0.08, "tuft_dark": mark, "tuft_pale": pale,
		"under_color": Color(0.94, 0.93, 0.9), "breast_wash": Color(0.92, 0.8, 0.68) if red else Color(0.86, 0.85, 0.82), "under_mark": Color(0.5, 0.2, 0.08) if red else Color(0.1, 0.09, 0.09), "under_pattern": 5, "throat_clean": 0.8,
		"fl_top": back * 0.85, "fl_pale": Color(0.86, 0.82, 0.76), "fl_dark": Color(0.3, 0.26, 0.22), "fl_bars": 6.0,
		"tail_color": back, "tail_band": mark.lerp(back, 0.4), "tail_bands": 7.0, "tail_band_w": 0.35, "tail_tip_r": pale,
		"bill_color": Color(0.62, 0.66, 0.4), "bill_tip": Color(0.7, 0.72, 0.5), "cere_color": Color(0.5, 0.5, 0.4), "iris": Color(0.98, 0.86, 0.12),
		"leg_color": Color(0.7, 0.66, 0.6), "lid_color": pale * 0.9,
	})
