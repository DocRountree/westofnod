class_name GoldenEagle
extends "res://scripts/creatures/eagle.gd"
## A golden eagle (Aquila chrysaetos), life size: the female about 90 cm
## long, 2.1 m across, 4.8 kg; the male smaller. Eagle: how it's made and
## moved.
##
## The adult: dark brown; the crown, the nape and the back of its neck
## golden (its hackles), its face darker; a pale tawny bar across the
## coverts of its folded wing, each covert edged paler; its tail grey
## brown, faintly banded, broadly dark tipped; its flight feathers from
## below grey, barred; its legs feathered to its toes, pale tawny; its feet
## and its cere yellow, its bill dark, blue grey at its root; its eye amber
## brown under a heavy brow. The juvenile darker, a white patch at the base
## of its flight feathers, its tail white with a broad black band at its
## end. Its eggs white, blotched reddish brown, two, in a platform of
## sticks. Hunting hares and squirrels from high: a long slanting stoop,
## its feet thrown forward; at carrion in hard times. Soaring with its
## wings lifted a little; its display a sky dance of swoops and climbs.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 0.88
	hunt_style = "stoop"
	stoop_speed = 40.0
	soar_height = 40.0
	egg_size = Vector2(0.074, 0.058)
	egg_colors = [Color(0.92, 0.9, 0.84), Color(0.55, 0.32, 0.2)]


func mass_of() -> Vector3:
	return Vector3(3.6, 1.95, 0.6) if male else Vector3(4.8, 2.12, 0.7)


func _shape() -> Dictionary:
	return eagle_shape(0.92, 0.97, 15.5 * 2.1, true)


func _plumage(stage: String, _male: bool) -> Dictionary:
	var juv := stage == "juvenile"
	var brown := Color(0.22, 0.14, 0.085) if juv else Color(0.27, 0.18, 0.11)
	var d := {
		"back_color": brown, "back_edge": Color(0.58, 0.44, 0.28) if not juv else Color(0.36, 0.26, 0.16), "back_bar": Color(0.14, 0.1, 0.06), "back_bars": 0.3, "mottle": 0.25 if not juv else 0.0, "back_from": 0.22, "back_from_hi": 0.13,
		"cap_color": Color(0.78, 0.56, 0.27) if not juv else Color(0.62, 0.42, 0.2), "hood_low": -0.004, "hood_nape": 0.0, "cheek_color": Color(0.22, 0.15, 0.09), "cheek": 1.0, "malar": 0.0,
		"nape_color": Color(0.8, 0.58, 0.28) if not juv else Color(0.6, 0.4, 0.2), "nape_u": 0.5,
		"under_color": brown, "breast_wash": brown * 1.1, "under_mark": brown, "under_pattern": 0, "throat_clean": 0.9,
		"trouser": Color(0.46, 0.33, 0.2, 0.8) if not juv else Color(0.7, 0.58, 0.42, 1.0),
		# the wings: above, a tawny bar over the arm's coverts (the adult's), the leading edge golden; the flight feathers
		# grey brown, barred dark on their bases, their ends dark, the primaries blackish; below, the coverts dark, a few
		# fringed tawny, the flight feathers grey, barred irregularly dark near their bases, a broad dark band at their ends
		"cov_bar": 0.9 if not juv else 0.15, "cov_bar_color": Color(0.7, 0.53, 0.32), "cov_lead": Color(0.74, 0.52, 0.25, 0.65 if not juv else 0.2), "under_cov_var": 0.6,
		"fl_top": Color(0.34, 0.28, 0.22) if not juv else Color(0.17, 0.12, 0.08), "fl_top_bars": 0.55, "fl_top_tip": 0.8, "fl_prim_dark": 0.85,
		"fl_pale": Color(0.52, 0.49, 0.46), "fl_dark": Color(0.12, 0.095, 0.075), "fl_bars": 4.0, "fl_bar_wave": 0.5, "fl_bar_to": 0.72, "fl_trail": 0.9, "fl_trail_from": 0.72,
		"tail_color": Color(0.38, 0.32, 0.26), "tail_band": Color(0.16, 0.12, 0.08), "tail_bands": 3.5, "tail_band_w": 0.45, "tail_tip_r": Color(0.15, 0.11, 0.08), "tail_tip_w": 0.16,
		"cere_color": Color(0.96, 0.8, 0.3), "bill_color": Color(0.36, 0.38, 0.43), "bill_tip": Color(0.06, 0.06, 0.07), "iris": Color(0.5, 0.29, 0.09),
		"leg_color": Color(0.96, 0.8, 0.3), "down_white": Color(0.9, 0.89, 0.86),
	}
	if juv: # (the white at its flight feathers' bases, its tail's white base)
		d.merge({"fl_patch": 0.42, "tail_under": 0.0, "tail_color": Color(0.94, 0.93, 0.9), "tail_band": Color(0.94, 0.93, 0.9), "tail_bands": 1.0, "tail_band_w": 0.0,
				"tail_tip_r": Color(0.1, 0.08, 0.06), "tail_tip_w": 0.36}, true)
	return d
