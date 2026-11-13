class_name RedWingedBlackbird
extends "res://scripts/creatures/thrush.gd"
## A red-winged blackbird (Agelaius phoeniceus), life size: 22 cm long, 35
## cm across, the male 65 g, the female 40 g and smaller. The songbird's
## make (Thrush: walking, foraging, flying, nesting, its young raised);
## its bill sharp and conical; its own ways:
## - the male's song spread (call_out): on a reed top or a post, puffed
##   out, his wings held out from his body and drooped so the red
##   epaulets flare, his tail fanned, leaning forward and up as he sings
##   conk-la-ree, his bill opening on each note, the last a trill. The
##   female's chatter: quick sharp notes, her tail flicked
## - display (a male's): a rival male near, flown at, chased off; none,
##   his song spread
## - foraging at a walk, pecking, its bill pushed into the ground and
##   opened, prying (gaping); insects, caterpillars, grasshoppers and
##   their nymphs, beetles, spiders, snails; its bill on each, swallowed
##   whole; its nestlings fed them, bill to gape
## - alarm: a sharp check, its tail flicking, then off
## - nesting (lay): the female's cup of sedges woven among reed stems over
##   wet ground (set_nest_site: the world's: a stand of cattails), three or
##   four pale blue-green eggs scrawled black at the broad end
##
## The male glossy black all over, his lesser coverts scarlet, the
## median a buff-yellow border below them (the epaulet: at rest often
## only the yellow showing, the red hid under the scapulars), his bill
## and legs black, his eye dark. The female dark brown and heavily
## streaked, buffy white below streaked dark, a pale buff stripe over her
## eye and a pale moustache, her throat washed peach, a little rust in
## her shoulders. The juvenile like her.


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.15 # (she the smaller)
	body_k = 0.48
	walks = true
	gapes = true
	flaps_glide = true
	cruise = 10.0
	nest_style = "cup"
	site_style = "reeds"
	nest_height = 0.65
	nest_scale = 0.33
	clutch = 4
	egg_size = Vector2(0.025, 0.018)
	egg_colors = [Color(0.72, 0.86, 0.86), Color(0.1, 0.08, 0.08)]
	eyas_scale = 0.45
	stand_pitch = 0.4
	song_notes = 3
	song_hz = 4.0
	feather_cm = 1.0


func _build() -> void:
	super()
	if _mat and not young: # (the epaulet's patch at rest: at the bend of its folded wing, on its side)
		var sh: Vector3 = shape.shoulder * 0.01
		_mat.set_shader_parameter("patch_at", sh + Vector3(0.0, -0.012, 0.002) * body_k / 0.48)
		_mat.set_shader_parameter("patch_r", Vector2(0.014, 0.011) * body_k / 0.48)


func mass_of() -> Vector3:
	return Vector3(0.065, 0.36, 0.017) if male else Vector3(0.042, 0.32, 0.013)


func _shape() -> Dictionary:
	return thrush_shape(0.48, 1.0, 1.25, 1.1, 8.5, 1.05, 1.02, 1.7, 0.03)


func _plumage(stage: String, male_: bool) -> Dictionary:
	if male_ and stage != "juvenile":
		var black := Color(0.03, 0.03, 0.035)
		return {
			"back_color": black, "back_edge": Color(0.07, 0.07, 0.09), "back_bar": black, "back_bars": 0.0, "back_from": 0.3, "back_from_hi": 0.2,
			"cap_color": black, "hood_u": 0.6, "hood_low": 0.0, "hood_nape": 1.0, "cheek": 0.0, "malar": 0.0,
			"under_color": black, "breast_wash": black, "wash_from": -0.5, "wash_to": 1.2, "under_mark": black, "under_pattern": 0, "throat_clean": 0.9,
			"cov_lead": Color(0.88, 0.1, 0.03, 1.0), "cov_lead_to": 0.62, "patch_color": Color(0.88, 0.1, 0.03, 1.0), "patch_edge": Color(0.95, 0.8, 0.45, 1.0), "cov_lead_edge": Color(0.95, 0.78, 0.4, 1.0),
			"fl_top": Color(0.04, 0.04, 0.05), "fl_pale": Color(0.12, 0.12, 0.13), "fl_dark": Color(0.05, 0.05, 0.05), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
			"tail_color": Color(0.03, 0.03, 0.035), "tail_band": black, "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": black, "tail_tip_w": 0.0, "tail_under": 0.1,
			"cere_color": Color(0.05, 0.05, 0.05), "bill_color": Color(0.05, 0.05, 0.06), "bill_tip": Color(0.04, 0.04, 0.05), "iris": Color(0.03, 0.03, 0.03),
			"leg_color": Color(0.06, 0.06, 0.07), "down_white": Color(0.5, 0.48, 0.45), "gape": Color(0.98, 0.9, 0.55), "young_legs": Color(0.8, 0.7, 0.6),
			"lid_color": Color(0.05, 0.05, 0.05),
		}
	var brown := Color(0.25, 0.19, 0.15)
	return {
		"back_color": brown, "back_edge": Color(0.52, 0.42, 0.32), "back_bar": Color(0.12, 0.09, 0.07), "back_bars": 0.0, "back_streak": 0.8,
		"back_from": 0.3, "back_from_hi": 0.2,
		"cap_color": Color(0.22, 0.17, 0.14), "hood_u": 0.72, "hood_low": 0.0, "hood_nape": 1.0, "cheek": 0.0, "malar": 0.0,
		"supercilium": Color(0.85, 0.76, 0.64, 1.0),
		"under_color": Color(0.8, 0.73, 0.64), "breast_wash": Color(0.72, 0.64, 0.56), "wash_from": -0.5, "wash_to": 0.9, "under_mark": Color(0.12, 0.09, 0.07),
		"under_pattern": 3, "throat_clean": 0.92,
		"throat_color": Color(0.88, 0.76, 0.66, 0.7), "throat_from": 0.62, "throat_streak": 0.0,
		"cov_lead": Color(0.6, 0.28, 0.14, 0.45), "cov_lead_to": 0.45, "patch_color": Color(0.55, 0.26, 0.14, 0.4), "patch_edge": Color(0.0, 0.0, 0.0, 0.0),
		"fl_top": Color(0.18, 0.14, 0.11), "fl_pale": Color(0.42, 0.38, 0.34), "fl_dark": Color(0.2, 0.17, 0.14), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"tail_color": Color(0.18, 0.14, 0.12), "tail_band": brown, "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": Color(0.18, 0.14, 0.12), "tail_tip_w": 0.0,
		"tail_under": 0.2,
		"cere_color": Color(0.3, 0.27, 0.25), "bill_color": Color(0.38, 0.36, 0.36), "bill_tip": Color(0.15, 0.14, 0.14), "iris": Color(0.05, 0.04, 0.03),
		"leg_color": Color(0.12, 0.11, 0.11), "down_white": Color(0.5, 0.48, 0.45), "gape": Color(0.98, 0.9, 0.55), "young_legs": Color(0.8, 0.7, 0.6),
		"lid_color": Color(0.3, 0.25, 0.2),
	}


# --- song: the song spread; the female's chatter -------------------------------------------

func _sing(_dt: float) -> void:
	if not male or juvenile:
		# her chatter: quick sharp notes, her tail flicked
		var ch := fmod(_mt, 2.2)
		want.jaw = 0.3 * maxf(0.0, sin(_mt * 30.0)) if ch < 0.9 else 0.0
		rate["jaw"] = 50.0
		want.tail_up = tail_rest + (0.3 * maxf(0.0, sin(_mt * 18.0)) if ch < 0.9 else 0.0)
		rate["tail_up"] = 30.0
		want.head_pitch = -0.2
		if _mt > _secs:
			perch()
		return
	# conk-la-ree: puffed, wings held out and drooped, the epaulets flared,
	# his tail fanned, leaning forward and then up, his bill open on each note
	var phrase := 1.6
	var ph := fmod(_mt, phrase + 2.2)
	var on := ph < phrase
	var k := clampf(ph / 0.25, 0.0, 1.0) * (1.0 - clampf((ph - phrase) / 0.4, 0.0, 1.0)) if ph < phrase + 0.4 else 0.0
	want.puff = 0.2 + 0.7 * k
	want.tail_spread = 0.9 * k
	set_wings(lerpf(-1.55, -0.75, k), 0.0, -0.15 * k, lerpf(0.0, 0.55, k)) # (out from his body, drooped)
	want.fold_pitch = lerpf(fold_pitch, 0.25, k)
	want.droop = 0.4 * k
	want.pitch = stand_pitch + 0.25 * k
	want.head_pitch = lerpf(-0.1, -0.5, clampf((ph - 0.3) / 0.6, 0.0, 1.0)) * k
	var note := 0.0
	if on:
		if ph < 0.7: # (conk-la: two short notes)
			note = maxf(0.0, sin(ph / 0.35 * PI))
		else: # (ree: the trill)
			note = 0.6 + 0.4 * maxf(0.0, sin(ph * 60.0))
	want.jaw = 0.5 * note
	rate["jaw"] = 40.0
	for kk: String in ["puff", "tail_spread", "pitch", "fold_pitch"]:
		rate[kk] = 10.0
	if _mt > _secs:
		want.puff = 0.0
		want.tail_spread = 0.0
		want.droop = 0.0
		fold_wings()
		want.fold_pitch = fold_pitch
		perch()


## (A male's.) A rival male near: flown at, chased off; none: his song spread.
func display(rival: Node3D = null) -> void:
	if young or dead:
		return
	if male and rival != null and is_instance_valid(rival) and rival != self and not rival.get("dead"):
		var rp: Vector3 = rival.get("_pos")
		_to("fly")
		_take_off("go", rp + Vector3(0.3, 0.0, 0.2), true)
		if rival.has_method("fly_off"):
			rival.call("fly_off", _pos)
		return
	call_out(rng.randf_range(8.0, 14.0))


## A sharp check, its tail flicking; then off.
func fly_off(from: Vector3) -> void:
	if _air or young or dead:
		super(from)
		return
	_beg = 0.4
	want.tail_up = tail_rest + 0.4
	super(from)


func _fly_step(dt: float) -> void:
	super(dt)
	if _air and male and not juvenile and _mode == "fly": # (flying, the epaulets flared a little: his song flight's)
		want.puff = 0.15
