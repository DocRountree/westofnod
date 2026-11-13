class_name EasternBluebird
extends "res://scripts/creatures/thrush.gd"
## An eastern bluebird (Sialia sialis), life size: 18 cm long, 30 cm
## across, 30 g. Thrush: how it's made and moved.
##
## The male: all his upperparts a vivid royal blue (his head to his eye,
## his back, his wings, his tail), his flight feathers' tips darker; his
## throat, breast and flanks a warm rusty orange, his belly and vent white;
## his bill and legs black, his eye dark. The female greyer: her back, her
## crown grey brown, a white ring round her eye; blue only in her wings
## and tail; her breast a paler orange. The juvenile grey, spotted white
## above and its breast scaled grey on white, blue in its wings and tail.
## Its eggs pale blue, four, in a cup of grass in a hole (a nest box).
## Hunting from a low perch: still, watching the ground, it drops down
## onto what moves (an insect, a spider, a caterpillar, a snail) and back
## up. Its song a soft, rich warble, tu-a-wee.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.0
	body_k = 0.42
	eyas_scale = 0.48
	nest_style = "box"
	site_style = "box"
	nest_height = 1.5
	pounces = true
	song_notes = 3
	song_hz = 2.6
	feather_cm = 0.7
	egg_size = Vector2(0.021, 0.016)
	egg_colors = [Color(0.72, 0.85, 0.9), Color(0.72, 0.85, 0.9)]


func mass_of() -> Vector3:
	return Vector3(0.031, 0.3, 0.012)


func _shape() -> Dictionary:
	return thrush_shape(0.42, 1.25, 0.72, 0.95, 6.8, 1.08)


func _plumage(stage: String, male_: bool) -> Dictionary:
	var blue := Color(0.13, 0.33, 0.78)
	var grey := Color(0.46, 0.45, 0.45)
	var adult_m := male_ and stage != "juvenile"
	var d := {
		"back_color": blue if adult_m else grey, "back_edge": (blue.lightened(0.12) if adult_m else grey.lightened(0.08)), "back_bar": blue.darkened(0.4), "back_bars": 0.0,
		"back_from": 0.32, "back_from_hi": 0.22,
		"cap_color": blue if adult_m else Color(0.44, 0.44, 0.46), "hood_u": 0.86, "hood_low": 0.002, "hood_nape": 1.0, "cheek": 0.0, "malar": 0.0,
		"under_color": Color(0.95, 0.95, 0.93), "breast_wash": Color(0.72, 0.36, 0.14) if adult_m else Color(0.82, 0.55, 0.36), "wash_from": -0.5, "wash_to": 0.82, "vent_to": 0.085,
		"under_mark": Color(0.4, 0.38, 0.36), "under_pattern": 0, "throat_clean": 0.95,
		"throat_color": Color(0.72, 0.36, 0.14, 1.0) if adult_m else Color(0.84, 0.66, 0.5, 0.8), "throat_from": 0.6, "throat_streak": 0.0,
		"fl_top": Color(0.12, 0.3, 0.72) if adult_m else Color(0.3, 0.45, 0.72), "fl_pale": Color(0.5, 0.52, 0.56), "fl_dark": Color(0.3, 0.32, 0.36), "fl_bars": 0.0, "fl_top_bars": 0.0,
		"fl_top_tip": 0.8, "fl_trail": 0.0,
		"tail_color": Color(0.14, 0.32, 0.74) if adult_m else Color(0.3, 0.45, 0.74), "tail_band": Color(0.1, 0.2, 0.45), "tail_bands": 0.0, "tail_band_w": 0.0,
		"tail_tip_r": Color(0.1, 0.18, 0.4), "tail_tip_w": 0.06, "tail_under": 0.4,
		"cere_color": Color(0.6, 0.65, 0.75) if adult_m else Color(0.95, 0.95, 0.93), "bill_color": Color(0.08, 0.08, 0.09), "bill_tip": Color(0.05, 0.05, 0.06),
		"iris": Color(0.05, 0.04, 0.03), "leg_color": Color(0.1, 0.1, 0.11), "down_white": Color(0.55, 0.55, 0.57), "gape": Color(0.98, 0.92, 0.5), "young_legs": Color(0.85, 0.75, 0.62),
		"lid_color": Color(0.5, 0.55, 0.65),
	}
	if stage == "juvenile": # (grey, spotted white above; its breast scaled grey on white)
		d.merge({"back_spot": 1.0, "under_spots": Vector2(0.2, 0.0), "breast_wash": Color(0.9, 0.88, 0.85), "under_pattern": 4, "under_mark": Color(0.4, 0.38, 0.37),
				"throat_color": Color(0.9, 0.9, 0.88, 0.8)}, true)
	return d
