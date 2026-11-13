class_name AmericanGoldfinch
extends "res://scripts/creatures/finch.gd"
## An American goldfinch (Spinus tristis), life size: 12.5 cm long, 20 cm
## across, 13 g; the sexes alike in size. Finch: how it's made and moved.
##
## The male in summer: a brilliant lemon yellow all over his body; a black
## cap on his forehead and forecrown, black down in front of his eye to his
## bill; his wings black, the shoulder (the lesser coverts) yellow, two
## white bars across them, the tertials and secondaries edged white; his
## tail black, notched, white spots on its inner webs; under his tail and
## his rump white; his bill a bright orange pink, his legs pinkish brown.
## The female: olive yellow above, a duller yellow below, whitish under her
## tail; no cap; her wings blackish brown, their bars buff; her bill
## duller. In winter (winter) both drab, buffy brown, a wash of yellow at
## the face, the wings still dark and barred, the bill dark. The juvenile
## brownish, its wing bars cinnamon buff. Its eggs pale bluish white,
## unmarked, five, in a tight cup of plant fibres lined with thistle down,
## in a fork of a shrub. The latest of all to nest, in midsummer, when the
## thistles go to seed. Clinging to seed heads (coneflower, black-eyed
## Susan, aster): a seed eater all its life, its young fed seed too. Its
## flight deeply bounding, po-ta-to-chip on each rise; the male's song a
## long canary-like twittering; his song flight slow, deep beats, circling.

var winter := false ## (its winter plumage: drab)


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.0
	body_k = 0.28
	site_style = "fork"
	nest_height = 1.3
	nest_scale = 0.22
	clutch = 5
	egg_size = Vector2(0.016, 0.012)
	egg_colors = [Color(0.86, 0.92, 0.92), Color(0.86, 0.92, 0.92)]
	cup_colors = [Color(0.66, 0.62, 0.46), Color(0.92, 0.9, 0.83)] # (plant fibres; thistle down)
	eyas_scale = 0.4
	song_notes = 40
	song_hz = 11.0
	song_secs = 4.0
	song_tail = 0.0
	bound_secs = Vector2(0.38, 0.45)
	bound_m = 0.4
	flight_hz = 0.5
	feather_cm = 0.55
	seeds = {"coneflower": 1.0, "susan": 1.0, "aster": 0.9, "fleabane": 0.7, "yampah": 0.4}


func mass_of() -> Vector3:
	return Vector3(0.013, 0.2, 0.0075)


func _shape() -> Dictionary:
	return finch_shape(thrush_shape(0.28, 1.4, 0.56, 0.6, 4.6, 1.35, 1.06, 1.75, -0.14))


func _plumage(stage: String, male_: bool) -> Dictionary:
	var juv := stage == "juvenile"
	var bright := male_ and not juv and not winter
	var yellow := Color(0.98, 0.83, 0.05)
	var olive := Color(0.6, 0.57, 0.24)
	var drab := Color(0.55, 0.47, 0.33)
	var back := yellow.darkened(0.04) if bright else (olive if not winter and not juv else drab)
	var under := yellow if bright else (Color(0.86, 0.79, 0.36) if not winter and not juv else Color(0.74, 0.68, 0.55))
	var wing := Color(0.03, 0.03, 0.035) if male_ and not juv else Color(0.16, 0.13, 0.1)
	var bars := Color(0.97, 0.96, 0.92) if male_ and not juv else (Color(0.86, 0.74, 0.55) if juv else Color(0.9, 0.86, 0.74))
	var d := {
		"back_color": back, "back_edge": back.lightened(0.08), "back_bar": back.darkened(0.3), "back_bars": 0.0, "back_from": 0.3, "back_from_hi": 0.2,
		"cap_color": Color(0.02, 0.02, 0.02) if bright else back, "hood_low": 0.0003, "hood_nape": 0.0, "cap_back": 0.0028, "cap_lore": 1.0 if bright else 0.0,
		"cheek": 0.0, "malar": 0.0,
		"under_color": Color(0.95, 0.94, 0.9) if not bright else Color(0.97, 0.96, 0.9), "breast_wash": under, "wash_from": -0.7, "wash_to": 1.2, "vent_to": -1.0,
		"under_mark": Color(0.2, 0.2, 0.2), "under_pattern": 0, "throat_clean": 0.9,
		"throat_color": Color(0.96, 0.82, 0.12, 0.8 if winter and not juv else 0.0), "throat_from": 0.6,
		"cov_lead": Color(yellow.r, yellow.g, yellow.b, 1.0 if male_ and not juv else 0.0), "cov_lead_to": 0.32,
		"wing_bar_fl": Vector2(0.1, 0.22), "wing_bars": Color(bars.r, bars.g, bars.b, 1.0), "wing_bar_at": Vector2(0.52, 0.84),
		"fl_top": wing, "fl_pale": Color(0.42, 0.4, 0.38), "fl_dark": wing, "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"fl_edge": Color(bars.r, bars.g, bars.b, 0.9 if male_ and not juv else 0.6),
		"tail_color": wing, "tail_band": wing, "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": wing, "tail_tip_w": 0.0, "tail_under": 0.35,
		"tail_inner": Color(0.97, 0.97, 0.95, 1.0 if male_ and not juv else 0.55),
		"tail_cov": Color(0.95, 0.94, 0.9, 0.7 if bright else 0.3), "trouser": Color(under.r, under.g, under.b, 1.0),
		"cere_color": Color(0.95, 0.55, 0.3), "bill_color": Color(0.96, 0.56, 0.3) if bright else (Color(0.85, 0.64, 0.5) if not winter else Color(0.36, 0.32, 0.3)),
		"bill_tip": Color(0.86, 0.5, 0.3) if not winter else Color(0.3, 0.27, 0.26), "iris": Color(0.03, 0.025, 0.02),
		"leg_color": Color(0.72, 0.55, 0.48), "down_white": Color(0.72, 0.68, 0.6), "gape": Color(0.97, 0.88, 0.74), "young_legs": Color(0.88, 0.72, 0.66),
		"lid_color": back.darkened(0.2),
	}
	return d
