class_name HouseFinch
extends "res://scripts/creatures/finch.gd"
## A house finch (Haemorhous mexicanus), life size: 14 cm long, 23 cm
## across, 21 g; the sexes alike in size. Finch: how it's made and moved.
##
## The male: his forehead, a broad band back over his eye, his throat and
## breast, his rump a rosy red (from his food: brighter or oranger, bird to
## bird), his crown's middle and the patch behind his eye brown; his back
## and wings brown, streaked darker, two thin whitish bars on the wings;
## his belly and flanks whitish, streaked brown; his tail brown, square,
## a little notched; his bill short, stout, its ridge curved, horn grey;
## his legs brown. The female: no red: plain grey brown, her face plain, all
## of her underparts blurrily streaked brown on whitish. The juvenile like
## her. Its eggs pale blue, finely dotted black, four or five, in a cup of
## twigs, grasses and feathers on a ledge, under eaves, in a hanging
## planter. Seeds above all, buds and fruit: berries pecked at; its young
## fed seed brought up from its crop. Its song a long jumbled warble ending
## in a burry wheer; its call a cheep; its flight a little bounding. The
## male feeds her as she begs as a nestling does; his song flight up, and
## down in a glide, singing.

var red := Color(0.8, 0.2, 0.25) ## (his red: a carotenoid's, from his food)


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.0
	body_k = 0.31
	site_style = "shelf"
	nest_height = 2.2
	nest_scale = 0.25
	clutch = 4
	egg_size = Vector2(0.019, 0.014)
	egg_colors = [Color(0.72, 0.86, 0.9), Color(0.08, 0.07, 0.08)]
	cup_colors = [Color(0.52, 0.45, 0.33), Color(0.78, 0.74, 0.66)] # (twigs and grass; feathers, hair)
	eyas_scale = 0.42
	song_notes = 26
	song_hz = 8.0
	song_secs = 2.8
	song_tail = 0.55
	bound_secs = Vector2(0.55, 0.3)
	bound_m = 0.15
	flight_hz = 0.85
	feather_cm = 0.6
	seeds = {"susan": 0.9, "coneflower": 0.9, "aster": 0.8, "fleabane": 0.8, "yampah": 0.6}


func mass_of() -> Vector3:
	return Vector3(0.021, 0.23, 0.0092)


func _shape() -> Dictionary:
	return finch_shape(thrush_shape(0.31, 1.3, 0.56, 0.6, 6.0, 1.25, 1.06, 1.95, -0.08))


func _plumage(stage: String, male_: bool) -> Dictionary:
	var m := male_ and stage != "juvenile"
	var brown := Color(0.44, 0.36, 0.3)
	var pale := Color(0.9, 0.85, 0.82)
	var streak := Color(0.4, 0.31, 0.26)
	var d := {
		"back_color": brown, "back_edge": Color(0.58, 0.5, 0.43), "back_bar": Color(0.24, 0.19, 0.16), "back_bars": 0.0, "back_streak": 0.75,
		"back_from": 0.3, "back_from_hi": 0.2,
		"cap_color": red if m else brown, "hood_low": -0.0008, "hood_nape": 0.0, "cap_back": 0.0035 if m else 1.0, "cap_lore": 0.0,
		"supercilium": Color(red.r, red.g, red.b, 1.0 if m else 0.0),
		"cheek": 1.0 if m else 0.0, "cheek_color": Color(0.5, 0.38, 0.33), "malar": 0.0,
		"under_color": pale, "breast_wash": red if m else pale, "wash_from": -0.1 if m else 2.0, "wash_to": 1.2, "vent_to": -1.0,
		"under_mark": streak, "under_pattern": 3, "throat_clean": 0.18 if m else 0.95,
		"throat_color": Color(red.r, red.g, red.b, 1.0 if m else 0.0), "throat_from": 0.6,
		"mark_from": -0.6, "wing_bar_fl": Vector2(0.14, 0.2), "wing_bars": Color(0.86, 0.82, 0.76, 0.75), "wing_bar_at": Vector2(0.52, 0.84),
		"fl_top": Color(0.3, 0.25, 0.21), "fl_pale": Color(0.55, 0.52, 0.5), "fl_dark": Color(0.32, 0.28, 0.26), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"fl_edge": Color(0.66, 0.58, 0.5, 0.55),
		"tail_color": Color(0.33, 0.28, 0.24), "tail_band": brown, "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": Color(0.33, 0.28, 0.24), "tail_tip_w": 0.0,
		"tail_under": 0.3, "tail_cov": Color(red.r, red.g, red.b, 0.75 if m else 0.0), "tail_cov_below": 0.0, "trouser": Color(0.82, 0.78, 0.72, 1.0),
		"cere_color": Color(0.62, 0.6, 0.58), "bill_color": Color(0.64, 0.62, 0.6), "bill_tip": Color(0.48, 0.46, 0.45), "iris": Color(0.03, 0.025, 0.02),
		"leg_color": Color(0.42, 0.35, 0.32), "down_white": Color(0.7, 0.66, 0.6), "gape": Color(0.98, 0.9, 0.72), "young_legs": Color(0.85, 0.7, 0.65),
		"lid_color": Color(0.36, 0.3, 0.26),
	}
	return d
