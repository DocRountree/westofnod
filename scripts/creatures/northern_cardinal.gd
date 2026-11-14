class_name NorthernCardinal
extends "res://scripts/creatures/finch.gd"
## A northern cardinal (Cardinalis cardinalis), life size: 22 cm long, 28
## cm across, 45 g, the male a little the bigger. The finch's make (Finch:
## perching, hopping, flying, its seeds, nesting, courtship feeding); its
## bill a great red cone (a seed cracker's), its crest a tall point, its
## tail long. Its own ways:
## - its crest: raised and lowered with its mood (up singing, courting,
##   alarmed, at a rival; half up about its business; down flying, asleep)
## - seeds: the seed heads that are here (a black-eyed Susan's, a
##   coneflower's, yampah's, an aster's), clinging to their stems; berries
##   from a bush; on the ground, hopping, pecking
## - its young fed insects (caterpillars, grasshoppers and their nymphs,
##   beetles): with nestlings, both parents hunt them on the ground and
##   carry each whole in the bill to a gape (Thrush), not seed from the crop
## - song (call_out): loud clear whistles, slurred, each phrase a note
##   repeated (cheer cheer cheer, birdie birdie birdie), its crest up, its
##   head raised, its bill opening on each note; the female sings too, and
##   from the nest as she sits
## - display (a male's): a rival male near: counter-singing, turn and turn
##   about, crests up, then flown at and chased off; none, his song
## - courting (mate): courtship feeding: he brings her seed, bill to bill,
##   as she begs, wings quivering (Finch); his song flight (display_flight)
## - alarm (fly_off): a sharp metallic chip, its crest up, its tail flicked
## - flight: short, a little bounding, low between bushes
## - nesting (lay): her cup of twigs, bark strips and grass in a fork low
##   in a thicket; three or four eggs greyish white speckled brown
##
## The male red all over, his back and wings duller, greyed; a black mask
## round his bill, his lores, his chin and throat; his bill red orange;
## his legs pinkish brown. The female warm buff brown, greyer above, her
## crest, wings and tail washed red; a smaller dusky mask; her bill orange
## red. The juvenile like her, browner, its bill dark.

var _rival: Node3D
var _insects := false # (nestlings to feed: hunting insects, not seed)
var _nest_song := randf() * 30.0 # (hers, singing on the nest: when)


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.04
	body_k = 0.47
	site_style = "fork"
	nest_height = 1.5
	nest_scale = 0.33
	clutch = 3
	egg_size = Vector2(0.025, 0.018)
	egg_colors = [Color(0.86, 0.85, 0.78), Color(0.42, 0.36, 0.3)]
	cup_colors = [Color(0.42, 0.34, 0.25), Color(0.7, 0.64, 0.5)] # (twigs, bark strips; fine grass)
	eyas_scale = 0.5
	stand_pitch = 0.42
	tail_rest = -1.0
	song_notes = 6
	song_hz = 2.6
	song_secs = 2.6
	song_tail = 0.0
	bound_secs = Vector2(0.5, 0.22)
	bound_m = 0.07
	flight_hz = 0.65
	feather_cm = 0.85
	grow_secs = 140.0
	seeds = {"susan": 1.0, "coneflower": 0.9, "yampah": 0.7, "aster": 0.6, "fleabane": 0.4}


func mass_of() -> Vector3:
	return Vector3(0.046, 0.29, 0.0155) if male else Vector3(0.043, 0.27, 0.015)


func _shape() -> Dictionary:
	var S := finch_shape(thrush_shape(0.47, 1.25, 0.8, 0.74, 10.5, 0.98, 1.1, 1.8, 0.06), 0.9)
	S.crest = crest_of(S, 2.5, 0.0, 0.8, 0.5, 0.55, 3, 1.6)
	return S


func _plumage(stage: String, male_: bool) -> Dictionary:
	var juv := stage == "juvenile"
	if male_ and not juv:
		var red := Color(0.82, 0.07, 0.05)
		var dull := Color(0.6, 0.1, 0.08)
		return {
			"back_color": dull, "back_edge": Color(0.55, 0.32, 0.3), "back_bar": dull.darkened(0.3), "back_bars": 0.0, "back_from": 0.3, "back_from_hi": 0.2,
			"cap_color": red, "hood_low": 0.03, "hood_nape": 1.0, "cap_back": 1.0, "cheek": 0.0, "malar": 0.0,
			"under_color": red.lightened(0.04), "breast_wash": red, "wash_from": -0.5, "wash_to": 1.2, "vent_to": -1.0,
			"under_mark": red, "under_pattern": 0, "throat_clean": 0.9,
			"throat_color": Color(0.03, 0.02, 0.02, 0.0), "throat_from": 0.8,
			"mask": Color(0.03, 0.02, 0.02, 1.0), "mask_at": Vector3(0.0008, 0.3, 0.0015), "mask_low": 0.022,
			"crest_color": Color(0.85, 0.08, 0.05, 1.0), "crest_lay": 1.25,
			"fl_top": Color(0.56, 0.1, 0.08), "fl_pale": Color(0.62, 0.32, 0.3), "fl_dark": Color(0.4, 0.12, 0.1), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
			"fl_edge": Color(0.66, 0.35, 0.32, 0.45),
			"tail_color": Color(0.58, 0.09, 0.07), "tail_band": dull, "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": dull, "tail_tip_w": 0.0, "tail_under": 0.25,
			"tail_cov": Color(0.75, 0.08, 0.06, 1.0), "trouser": Color(0.72, 0.08, 0.06, 1.0),
			"cere_color": Color(0.97, 0.38, 0.2), "bill_color": Color(0.97, 0.4, 0.22), "bill_tip": Color(0.93, 0.36, 0.2), "iris": Color(0.03, 0.025, 0.02),
			"leg_color": Color(0.6, 0.42, 0.4), "down_white": Color(0.42, 0.38, 0.36), "gape": Color(0.95, 0.88, 0.7), "young_legs": Color(0.85, 0.66, 0.6),
			"lid_color": Color(0.1, 0.05, 0.05),
		}
	var buff := Color(0.8, 0.66, 0.5) if not juv else Color(0.72, 0.6, 0.47)
	var back := Color(0.55, 0.47, 0.39) if not juv else Color(0.5, 0.42, 0.34)
	var wash := Color(0.72, 0.28, 0.2)
	return {
		"back_color": back, "back_edge": back.lightened(0.1), "back_bar": back.darkened(0.3), "back_bars": 0.0, "back_from": 0.3, "back_from_hi": 0.2,
		"cap_color": back.lerp(wash, 0.18), "hood_low": 0.0, "hood_nape": 1.0, "cap_back": 1.0, "cheek": 1.0, "cheek_color": Color(0.6, 0.55, 0.5), "malar": 0.0,
		"under_color": buff.lightened(0.08), "breast_wash": buff, "wash_from": -0.5, "wash_to": 1.2, "vent_to": -1.0,
		"under_mark": buff, "under_pattern": 0, "throat_clean": 0.9,
		"throat_color": Color(0.36, 0.33, 0.32, 0.0), "throat_from": 0.86,
		"mask": Color(0.26, 0.24, 0.24, 0.8 if not juv else 0.35), "mask_at": Vector3(-0.0015, 0.3, -0.0025), "mask_low": 0.011,
		"crest_color": Color(0.58, 0.47, 0.38, 1.0), "crest_tip": Color(wash.r, wash.g, wash.b, 0.85 if not juv else 0.4), "crest_lay": 1.25,
		"fl_top": Color(0.6, 0.27, 0.19) if not juv else Color(0.52, 0.3, 0.22), "fl_pale": Color(0.62, 0.5, 0.44), "fl_dark": Color(0.42, 0.3, 0.26), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"fl_edge": Color(0.7, 0.36, 0.26, 0.6),
		"tail_color": Color(0.56, 0.24, 0.18) if not juv else Color(0.48, 0.28, 0.22), "tail_band": back, "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": back, "tail_tip_w": 0.0, "tail_under": 0.25,
		"tail_cov": Color(0.0, 0.0, 0.0, 0.0), "trouser": Color(buff.r, buff.g, buff.b, 1.0),
		"cere_color": Color(0.95, 0.45, 0.28) if not juv else Color(0.18, 0.16, 0.16), "bill_color": Color(0.96, 0.48, 0.3) if not juv else Color(0.2, 0.18, 0.18),
		"bill_tip": Color(0.92, 0.42, 0.26) if not juv else Color(0.12, 0.11, 0.11), "iris": Color(0.03, 0.025, 0.02),
		"leg_color": Color(0.62, 0.45, 0.42), "down_white": Color(0.42, 0.38, 0.36), "gape": Color(0.95, 0.88, 0.7), "young_legs": Color(0.85, 0.66, 0.6),
		"lid_color": back.darkened(0.2),
	}


# --- its food: seeds; insects for its young ----------------------------------------------

## With nestlings: insects, hunted on the ground and carried to them whole
## (Thrush); else seeds and berries (Finch).
func forage() -> void:
	_insects = not _live_young().is_empty()
	super()


func _find_food(r := 30.0) -> Node3D:
	if _insects:
		return null
	return super(r)


func _meal_kinds() -> Array:
	return Diet.prey_of(self) if _insects or hunger > 0.8 else []


# --- its crest, its mood -----------------------------------------------------------------

func _think(dt: float) -> void:
	super(dt)
	if young:
		return
	var up := 0.55 # (about its business: half up, a point)
	match _mode:
		"call", "court_g", "courted", "counter", "mount":
			up = 1.0
		"seed", "forage", "hunt", "swallow", "nest_feed", "feed_young":
			up = 0.42
		"incubate", "brood":
			up = 0.3
		"sleep":
			up = 0.0
		"preen":
			up = 0.25
	if _air:
		up = 0.15
	if _beg > 0.0 and not _air: # (a chip: up)
		up = 1.0
	want.crest = up * (0.75 if juvenile else 1.0)
	rate["crest"] = 5.0
	if _mode == "counter":
		_counter(dt)
	if _mode == "incubate" and not male: # (she sings on the nest, now and then, softly: a phrase or two)
		var ph := fmod(_mt + _nest_song, 34.0) - 30.0
		if ph > 0.0 and ph < 2.4:
			want.jaw = 0.3 * sin(PI * fmod(ph * 2.2, 1.0))
			want.head_pitch = -0.25
			want.crest = 0.8
			rate["jaw"] = 30.0
		else:
			want.jaw = 0.0


## Its song: phrase after phrase, each a run of one whistled note slurred
## down (cheer) or up and down (birdie), its bill opening on each, its head
## up, its crest raised, its tail a little lowered.
func _sing(_dt: float) -> void:
	want.head_pitch = -0.45
	head_want = Vector3(0.0, 0.006, -0.002) * body_k / 0.55
	want.tail_up = tail_rest - 0.12
	var phrase := song_notes / song_hz
	var cyc := phrase + 1.4
	var ph := fmod(_mt, cyc)
	var o := 0.0
	if ph < phrase:
		var note := fmod(ph * song_hz, 1.0)
		var kind := int(floorf(_mt / cyc)) % 2 # (cheer, then birdie)
		o = (0.42 * sin(PI * note) if kind == 0 else 0.36 * maxf(sin(PI * note * 2.0), 0.25 * sin(PI * note))) # (one long slur; two quick)
	want.jaw = o
	want.puff = 0.2 + o * 0.5
	rate["jaw"] = 32.0
	rate["puff"] = 18.0
	if _mt > _secs:
		want.jaw = 0.0
		want.puff = 0.0
		perch()


## (A male's.) A rival male near: they sing at each other, turn and turn
## about, crests up, facing; then he flies at it, and it's chased off. None:
## his song.
func display(rival: Node3D = null) -> void:
	if young or dead:
		return
	if male and rival != null and is_instance_valid(rival) and rival != self and not rival.get("dead"):
		_rival = rival
		_to("counter")
		_secs = rng.randf_range(9.0, 14.0)
		if rival.has_method("_to") and String(rival.get("_mode")) not in ["counter"]:
			rival.set("_rival", self)
			rival.call("_to", "counter")
			rival.set("_secs", _secs + 30.0) # (it sings back till it's chased)
			rival.set("_mt", 1.6) # (its turn after his)
		return
	call_out(rng.randf_range(8.0, 14.0))


func _counter(_dt: float) -> void:
	if _rival == null or not is_instance_valid(_rival) or _rival.get("dead"):
		_rival = null
		perch()
		return
	var to: Vector3 = (_rival.get("_pos") as Vector3) - _pos
	turn_to(to)
	want.puff = 0.3
	want.tail_spread = 0.4
	var turn := fmod(_mt, 3.2) < 1.6 # (his phrase, then its)
	var ph := fmod(_mt, 1.6)
	if turn:
		want.head_pitch = -0.45
		want.jaw = 0.42 * sin(PI * fmod(ph * song_hz, 1.0))
	else: # (listening: still, crest up, its head toward it)
		want.head_pitch = -0.1
		want.jaw = 0.0
	rate["jaw"] = 32.0
	if _mt > _secs: # (enough: flown at)
		want.jaw = 0.0
		var rp: Vector3 = _rival.get("_pos")
		var rv := _rival
		_rival = null
		if rv.has_method("fly_off"):
			rv.set("_rival", null)
			rv.call("fly_off", _pos)
		_to("fly")
		_take_off("go", rp + Vector3(0.2, 0.0, 0.15) * body_k / 0.55, true)


## A sharp chip, its crest up, its tail flicked; then off, low.
func fly_off(from: Vector3) -> void:
	if _air or young or dead:
		super(from)
		return
	_beg = 0.3
	want.crest = 1.0
	want.tail_up = tail_rest + 0.4
	super(from)


func _to(mode: String, sub := "") -> void:
	if mode != "counter" and _mode == "counter":
		want.tail_spread = 0.0
	super(mode, sub)


func test_mode(mode: String) -> void:
	if mode.contains("counter"):
		_rival = self
		_to("counter")
		_secs = 60.0
	else:
		super(mode)
