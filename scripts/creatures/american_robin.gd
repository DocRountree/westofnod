class_name AmericanRobin
extends "res://scripts/creatures/thrush.gd"
## An American robin (Turdus migratorius), life size: 25 cm long, 36 cm
## across, 77 g; the sexes alike in size. Thrush: how it's made and moved.
##
## The male: his head black, a broken white ring round his eye (white arcs
## above and below it); his throat white, streaked black; his back and
## wings grey brown, his tail blackish, its outer corners white tipped; his
## breast and belly a deep brick orange, his vent and under his tail
## white; his bill yellow, dark at its tip; his legs dark. The female
## paler: her head grey brown, hardly darker than her back, her breast a
## washed out orange. The juvenile: its back spotted pale, its breast
## spotted black on pale orange. Its eggs robin's egg blue, four, in a cup
## of dry grass walled with mud, on a ledge or in a fork. Running and
## stopping on the lawn, its head cocked; worms and grubs, beetles,
## caterpillars, spiders, snails, ants. Its song a carolling, cheerily
## cheer-up cheerio, phrase after phrase.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.0
	body_k = 0.55
	eyas_scale = 0.62
	nest_style = "cup"
	nest_height = 1.8
	pounces = false
	song_notes = 4
	song_hz = 3.2
	feather_cm = 0.9
	egg_size = Vector2(0.028, 0.02)
	egg_colors = [Color(0.45, 0.74, 0.8), Color(0.45, 0.74, 0.8)]


func mass_of() -> Vector3:
	return Vector3(0.077, 0.36, 0.019)


func _shape() -> Dictionary:
	return thrush_shape(0.55, 1.22, 1.0, 1.15, 10.0, 0.9)


func _plumage(stage: String, male_: bool) -> Dictionary:
	var back := Color(0.36, 0.33, 0.3) if male_ else Color(0.42, 0.39, 0.35)
	var d := {
		"back_color": back, "back_edge": back.lightened(0.1), "back_bar": back.darkened(0.35), "back_bars": 0.0, "back_from": 0.3, "back_from_hi": 0.2,
		"cap_color": Color(0.06, 0.06, 0.06) if male_ else Color(0.24, 0.23, 0.22), "hood_u": 0.6, "hood_low": 0.02, "hood_nape": 1.0, "cheek": 0.0, "malar": 0.0,
		"under_color": Color(0.94, 0.93, 0.9), "breast_wash": Color(0.72, 0.29, 0.09) if male_ else Color(0.8, 0.46, 0.24), "wash_from": -0.5, "wash_to": 0.64, "vent_to": 0.088,
		"under_mark": Color(0.1, 0.09, 0.08), "under_pattern": 0, "throat_clean": 0.9,
		"throat_color": Color(0.95, 0.95, 0.93, 1.0), "throat_from": 0.6, "throat_streak": 1.0,
		"fl_top": Color(0.24, 0.22, 0.2), "fl_pale": Color(0.5, 0.48, 0.46), "fl_dark": Color(0.28, 0.27, 0.26), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"tail_color": Color(0.09, 0.09, 0.09), "tail_band": Color(0.09, 0.09, 0.09), "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": Color(0.92, 0.92, 0.9), "tail_tip_w": 0.03,
		"tail_cov": Color(0.94, 0.93, 0.9, 0.0), "tail_under": 0.2,
		"cere_color": Color(0.96, 0.96, 0.94), "bill_color": Color(0.92, 0.72, 0.16), "bill_tip": Color(0.35, 0.28, 0.12), "iris": Color(0.05, 0.04, 0.03),
		"leg_color": Color(0.3, 0.25, 0.22), "down_white": Color(0.52, 0.5, 0.48), "gape": Color(0.98, 0.9, 0.35), "young_legs": Color(0.85, 0.72, 0.55),
		"lid_color": Color(0.9, 0.9, 0.88), "eye_arcs": Color(0.97, 0.97, 0.95, 0.0085),
	}
	if stage == "juvenile": # (spotted: its back pale spotted, its breast black spotted on pale orange)
		d.merge({"back_spot": 1.0, "under_spots": Vector2(0.2, 0.0), "cap_color": Color(0.22, 0.2, 0.19), "breast_wash": Color(0.86, 0.6, 0.38), "under_pattern": 4, "under_mark": Color(0.1, 0.08, 0.07),
				"throat_streak": 0.5}, true)
	return d
