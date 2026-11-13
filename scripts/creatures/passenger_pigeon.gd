class_name PassengerPigeon
extends "res://scripts/creatures/pigeon.gd"
## A passenger pigeon (Ectopistes migratorius), life size: the male about
## 40 cm long, half of it his tail, 64 cm across, 300 g; the female
## smaller. As it looked (the museum's skins); its ways the living doves'
## (Pigeon: the rock dove's, the mourning dove's, the band-tailed
## pigeon's), for none were ever filmed.
##
## The male: his head, his back and his folded wings slate blue grey, the
## coverts scattered with black spots; the sides of his neck iridescent,
## bronze and violet; his throat and breast a deep coppery rufous, paling
## down his belly to white at the vent; his flight feathers blackish
## brown; his tail long, graduated, pointed, its middle feathers dark
## grey, the outer ones white; his eye red in a bare purplish-red ring;
## his bill black, his legs coral red. The female duller, browner: her
## head and back grey brown, her breast a buffy grey brown, her neck's
## sheen faint, her eye orange in a blue-grey ring. The juvenile like her,
## browner still, each feather fringed pale. One white egg on a flimsy
## platform of twigs in a tree. Feeding on the forest floor on mast
## (acorns, swallowed whole) and, nesting, on grubs, caterpillars, snails.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.07 # (she the smaller)
	body_k = 0.68
	clutch = 1
	egg_size = Vector2(0.04, 0.029)
	feather_cm = 1.3


func mass_of() -> Vector3:
	return Vector3(0.3, 0.64, 0.05) if male else Vector3(0.27, 0.6, 0.046)


func _shape() -> Dictionary:
	var S := thrush_shape(0.68, 0.88, 0.82, 0.6, 22.0, 1.3, 0.82, 1.3, 0.5, 1.0, 1.35, 0.8)
	S.erase("eye_ring") # (its bare ring flush, the shader's: no raised rim)
	S.eye_r = float(S.eye_r) * 0.52
	S.eye = (S.eye as Vector3) * Vector3(1.16, 1.0, 1.0) + Vector3(0.0, 0.15, -0.35) * 0.68 # (out on its rounder head's side, a little forward)
	return S


func _plumage(stage: String, male_: bool) -> Dictionary:
	var m := male_ and stage != "juvenile"
	var slate := Color(0.47, 0.5, 0.56)
	var brown := Color(0.5, 0.45, 0.4)
	var d := {
		"back_color": slate if m else brown, "back_edge": (slate if m else brown).lightened(0.08), "back_bar": Color(0.12, 0.12, 0.13), "back_bars": 0.0,
		"back_from": 0.22, "back_from_hi": 0.12,
		"cap_color": Color(0.44, 0.48, 0.55) if m else Color(0.46, 0.42, 0.38), "hood_u": 0.77, "hood_low": 0.002, "hood_nape": 1.0, "cheek": 0.0, "malar": 0.0,
		"nape_color": Color(0.5, 0.4, 0.3) if m else Color(0.5, 0.44, 0.38), "nape_iris": Color(0.62, 0.3, 0.48) if m else Color(0.44, 0.4, 0.42), "nape_u": 0.6,
		"under_color": Color(0.93, 0.92, 0.89), "breast_wash": Color(0.72, 0.38, 0.2) if m else Color(0.66, 0.58, 0.5), "wash_from": -0.5, "wash_to": 0.8,
		"vent_to": 0.092, "under_mark": Color(0.2, 0.2, 0.2), "under_pattern": 0, "throat_clean": 0.95,
		"throat_color": Color(0.74, 0.42, 0.24, 0.0), "throat_from": 0.6, "throat_streak": 0.0,
		"cov_spots": Color(0.06, 0.06, 0.07, 0.5),
		"fl_top": Color(0.42, 0.44, 0.49) if m else Color(0.45, 0.4, 0.36), "fl_prim_dark": 0.9, "fl_top_tip": 0.6, "fl_pale": Color(0.55, 0.53, 0.52), "fl_dark": Color(0.3, 0.28, 0.27), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"tail_color": Color(0.36, 0.38, 0.42) if m else Color(0.42, 0.4, 0.37), "tail_band": Color(0.1, 0.1, 0.1), "tail_bands": 0.0, "tail_band_w": 0.0,
		"tail_tip_r": Color(0.36, 0.38, 0.42) if m else Color(0.42, 0.4, 0.37), "tail_tip_w": 0.0, "tail_under": 0.3,
		"tail_outer": Color(0.95, 0.95, 0.93, 1.0),
		"cere_color": Color(0.62, 0.25, 0.32) if m else Color(0.5, 0.58, 0.66), "bill_color": Color(0.08, 0.08, 0.08), "bill_tip": Color(0.05, 0.05, 0.05),
		"iris": Color(0.85, 0.1, 0.08) if m else Color(0.9, 0.45, 0.12), "leg_color": Color(0.9, 0.38, 0.3), "down_white": Color(0.85, 0.8, 0.6),
		"gape": Color(0.75, 0.62, 0.5), "young_legs": Color(0.7, 0.5, 0.45), "lid_color": Color(0.5, 0.48, 0.5),
	}
	if stage == "juvenile":
		d.merge({"back_edge": Color(0.72, 0.66, 0.58), "mottle": 0.0, "breast_wash": Color(0.6, 0.54, 0.48), "cov_spots": Color(0.1, 0.09, 0.08, 0.2)}, true)
	return d
