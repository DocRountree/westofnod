class_name Mallard
extends "res://scripts/creatures/canada_goose.gd"
## A mallard (Anas platyrhynchos), life size: 58 cm long, 90 cm across,
## the drake 1.2 kg, the hen 1.1 kg and a little smaller. A dabbling duck:
## the goose's make (CanadaGoose: its water, its swimming and upending, its
## grazing on the bank, its nest by the water, its young after their
## mother), its own body: shorter, rounder, its neck short, its head round,
## its bill broad and flat with a nail at its tip.
##
## The drake: his head and upper neck a glossy green (blue and violet as the
## light turns on it), a narrow white ring round his neck; his breast
## chestnut; his flanks and belly pale grey, finely vermiculated; his back
## grey brown; his rump and under his tail black; his tail white, its middle
## coverts curled up black; his bill yellow with a black nail; his legs and
## feet orange. The hen: mottled brown all over, each feather dark centred
## and edged buff; a dark line through her eye under a paler brow, a dark
## crown; her bill orange blotched dark along its middle; her legs orange.
## Both: the speculum, a violet blue patch on their secondaries edged white
## before and after, flashing in flight and at the side of the folded wing.
##
## Its ways (as the goose's, a duck's own): dabbling and upending in the
## shallows; grazing and picking at seeds on the bank; quacking (the hen's
## loud series, falling away: QUACK quack quack quack; the drake's quiet
## raspy raeb); springing straight up off the water, no run (a dabbler's
## jump); flying fast, in small flocks; courting on the water (head
## pumping, the two of them; then his display: up out of the water, his
## head back, his tail up); she nests on the ground near the water, a bowl
## lined with her down, nine greenish buff eggs; he leaves her to it (no
## guarding); the ducklings: yellow and dark brown down, a dark line
## through the eye, after her in a line, on the water from their first day.

func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	male_size = 1.04
	body_k = 1.75
	feather_cm = 2.3
	cruise = 20.0
	top_speed = 26.0
	clutch = 9
	egg_size = Vector2(0.057, 0.041)
	egg_colors = [Color(0.85, 0.86, 0.72), Color(0.87, 0.87, 0.76)]
	grow_secs = 180.0
	eyas_scale = 0.62


func mass_of() -> Vector3:
	return Vector3(1.2, 0.9, 0.105) if male else Vector3(1.1, 0.86, 0.098)


## The goose's shape, made a duck's: smaller all through, its neck short
## (its head drawn down toward its body), its head rounder, its bill broad
## and flat.
func _shape() -> Dictionary:
	var g: Dictionary = super()
	const K := 0.6
	const NECK := 0.52 # (how much of the goose's neck it keeps)
	const BASE_Y := 34.0
	var head_at := func(v: Vector3) -> Vector3: # (a point of its head or bill: the neck shortened under it)
		return Vector3(v.x * K, (BASE_Y + (v.y - BASE_Y) * NECK) * K, v.z * K * 0.92)
	var out := g.duplicate(true)
	var spine := []
	for e: Array in g.spine:
		var u := float(e[4])
		var y := float(e[0])
		var z := float(e[1])
		var w := float(e[2]) * K
		var h := float(e[3]) * K
		if u > 0.0:
			y = BASE_Y + (y - BASE_Y) * NECK
			z *= 0.92
		if u >= 3.9 and u < 4.85: # (its head: round and full)
			w *= 1.22
			h *= 1.2
		elif u >= 4.85: # (its bill: broad and flat)
			w *= 1.5
			h *= 0.85
		elif u > 0.3 and u < 3.9: # (its neck: thick and short)
			w *= 1.12
			h *= 1.12
		spine.append([y * K, z * K, w, h, u])
	out.spine = spine
	out.pivot = (g.pivot as Vector3) * K
	out.jaw = head_at.call(g.jaw)
	var lb := []
	for e: Array in g.lower_bill:
		var p: Vector3 = head_at.call(Vector3(0.0, float(e[0]), float(e[1])))
		lb.append([p.y, p.z, float(e[2]) * K * 1.4])
	out.lower_bill = lb
	out.eye = head_at.call(g.eye) * Vector3(1.15, 1.0, 1.0)
	out.eye_r = float(g.eye_r) * K * 1.1
	for k: String in ["hip", "knee", "ankle", "foot", "tail", "shoulder"]:
		out[k] = (g[k] as Vector3) * K
	out.wing = (g.wing as Vector3) * K
	for k: String in ["thigh_r", "toes", "coverts", "primaries"]:
		out[k] = (g[k] as Array).map(func(x: Variant) -> float: return float(x) * K)
	out.leg_r = float(g.leg_r) * K * 1.1
	out.secondaries = [g.secondaries[0], float(g.secondaries[1]) * K, float(g.secondaries[2]) * K]
	out.tertials = [g.tertials[0], float(g.tertials[1]) * K, float(g.tertials[2]) * K]
	out.feather_w = float(g.feather_w) * K
	out.tail_feathers = [g.tail_feathers[0], float(g.tail_feathers[1]) * K * 0.8, float(g.tail_feathers[2]) * K]
	out.tail_coverts = [[g.tail_coverts[0][0], float(g.tail_coverts[0][1]) * K, float(g.tail_coverts[0][2]) * K, g.tail_coverts[0][3], g.tail_coverts[0][4]]]
	out.eye_c = float(g.eye_c) * 0.9
	return out


func _plumage(stage: String, male_: bool) -> Dictionary:
	var drake := male_ and stage == "adult"
	var orange := Color(0.93, 0.5, 0.16)
	var speculum := Vector4(0.24, 0.2, 0.62, 1.0) # (violet blue)
	var white := Color(0.95, 0.95, 0.93, 1.0)
	if drake:
		var green := Color(0.06, 0.32, 0.14)
		var grey := Color(0.74, 0.73, 0.7)
		return {
			"back_color": Color(0.42, 0.37, 0.32), "back_edge": Color(0.6, 0.56, 0.5), "back_bar": Color(0.3, 0.26, 0.22), "back_bars": 0.0, "back_from": 0.32, "back_from_hi": 0.26,
			"cap_color": green, "hood_u": 0.62, "hood_low": 0.0, "hood_nape": 1.0, "cheek": 0.0, "malar": 0.0,
			"hood_ring": Vector4(0.95, 0.95, 0.93, 0.02), # (his white neck ring)
			"iridescence": 0.0, "nape_iris": Vector4(0.25, 0.18, 0.55, 0.8), # (his green head glossed blue and violet as the light turns)
			"chin_strap": Vector4(0.0, 0.0, 0.0, 0.0),
			"under_color": grey, "breast_wash": Color(0.36, 0.17, 0.1), "wash_from": 0.3, "wash_to": 0.62, "vent_to": 0.2, # (his breast chestnut, between the ring and the grey)
			"under_mark": Color(0.52, 0.5, 0.47), "under_pattern": 2, "under_bar_n": 6.0, "under_bar_w": 0.25, "throat_clean": 0.74, "mark_from": 0.18, # (finely vermiculated)
			"fl_top": Color(0.4, 0.38, 0.36), "fl_pale": Color(0.75, 0.74, 0.72), "fl_dark": Color(0.4, 0.38, 0.36), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
			"speculum": speculum, "fl_tip": Vector4(0.95, 0.95, 0.93, 0.12), "wing_bars": Vector4(0.95, 0.95, 0.93, 0.9), "wing_bar_at": Vector2(0.55, 0.86), "wing_bar_fl": Vector2(0.12, 0.2),
			"tail_color": Color(0.9, 0.89, 0.86), "tail_band": Color(0.9, 0.89, 0.86), "tail_bands": 0.0, "tail_band_w": 0.0, "tail_tip_r": Color(0.95, 0.94, 0.92), "tail_tip_w": 0.0, "tail_under": 0.0,
			"tail_cov": Color(0.04, 0.04, 0.045, 1.0), # (his black rump and under his tail)
			"cere_color": Color(0.86, 0.8, 0.2), "bill_color": Color(0.86, 0.8, 0.22), "bill_tip": Color(0.06, 0.06, 0.05), "iris": Color(0.18, 0.08, 0.04),
			"leg_color": orange, "down_white": Color(0.92, 0.82, 0.36), "down_back": Vector4(0.28, 0.2, 0.1, 0.9), "gape": Color(0.6, 0.45, 0.3), "young_legs": Color(0.45, 0.38, 0.25),
			"lid_color": green, "bill_gloss": 0.35, "nostril": Vector4(0.22, 0.14, 0.1, 0.9), "trouser": Vector4(0.0, 0.0, 0.0, 0.0),
		}
	# the hen (and the young, the drake in his first plumage): mottled brown
	var brown := Color(0.45, 0.33, 0.21)
	var buff := Color(0.74, 0.6, 0.42)
	return {
		"back_color": brown.darkened(0.2), "back_edge": buff, "back_bar": brown.darkened(0.45), "back_bars": 0.0, "back_streak": 0.6, "back_from": 0.3, "back_from_hi": 0.24,
		"cap_color": Color(0.24, 0.17, 0.11), "hood_u": -1.0, "hood_low": -0.002, "hood_nape": 0.6, "cheek": 0.0, "malar": 0.0,
		"supercilium": Vector4(0.78, 0.68, 0.52, 0.5), "mask": Vector4(0.2, 0.14, 0.09, 0.85), "mask_at": Vector3(0.0015, 0.0, 0.0), "mask_low": 0.002, # (a dark line through her eye under a paler brow)
		"chin_strap": Vector4(0.0, 0.0, 0.0, 0.0),
		"under_color": buff, "breast_wash": Color(0.66, 0.5, 0.33), "wash_from": 0.3, "wash_to": 0.8, "vent_to": 0.2,
		"under_mark": Color(0.3, 0.2, 0.12), "under_pattern": 3, "under_bar_n": 1.0, "under_bar_w": 0.5, "throat_clean": 0.8, "mark_from": 0.1,
		"fl_top": Color(0.32, 0.26, 0.2), "fl_pale": Color(0.62, 0.56, 0.48), "fl_dark": Color(0.3, 0.25, 0.2), "fl_bars": 0.0, "fl_top_bars": 0.0, "fl_trail": 0.0,
		"speculum": speculum, "fl_tip": Vector4(0.95, 0.95, 0.93, 0.12), "wing_bars": Vector4(0.95, 0.95, 0.93, 0.9), "wing_bar_at": Vector2(0.55, 0.86), "wing_bar_fl": Vector2(0.12, 0.2),
		"tail_color": Color(0.62, 0.52, 0.4), "tail_band": brown, "tail_bands": 3.0, "tail_band_w": 0.25, "tail_tip_r": Color(0.82, 0.74, 0.6), "tail_tip_w": 0.1, "tail_under": 0.3,
		"tail_cov": Vector4(0.0, 0.0, 0.0, 0.0),
		"cere_color": orange, "bill_color": Color(0.3, 0.22, 0.14), "bill_base": Vector4(0.9, 0.5, 0.17, 0.25), "bill_tip": Color(0.72, 0.42, 0.16), "iris": Color(0.18, 0.08, 0.04),
		"leg_color": orange, "down_white": Color(0.92, 0.82, 0.36), "down_back": Vector4(0.28, 0.2, 0.1, 0.9), "gape": Color(0.6, 0.45, 0.3), "young_legs": Color(0.45, 0.38, 0.25),
		"lid_color": brown.darkened(0.3), "bill_gloss": 0.35, "nostril": Vector4(0.22, 0.14, 0.1, 0.9), "trouser": Vector4(0.0, 0.0, 0.0, 0.0),
	}


func _build() -> void:
	super()
	walk_speed = 0.4 * size
	run_speed = 1.6


# --- its quack -------------------------------------------------------------------------------

func _sing(_dt: float) -> void:
	# the hen's loud series, falling away (QUACK quack quack quack); the drake's quiet, raspy raeb, raeb
	head_point = Vector3.INF
	want.head_pitch = -0.1
	head_want = Vector3(0.0, 0.015, -0.01) * size
	var period := 2.6 if not male else 1.8
	var ph := fmod(_mt, period)
	var o := 0.0
	if male:
		if ph < 0.25:
			o = 0.18 * sin(PI * ph / 0.25)
	else:
		var n := int(ph / 0.32)
		var f := fmod(ph, 0.32) / 0.32
		if n < 5 and f < 0.55:
			o = (0.42 - 0.07 * n) * sin(PI * f / 0.55)
	want.jaw = o
	rate["jaw"] = 32.0
	want.puff = 0.05 + o * 0.2
	if _mt > _secs:
		want.jaw = 0.0
		head_want = Vector3.ZERO
		forage()


# --- flying: straight up off the water ------------------------------------------------------

## Up and away to `to`: a dabbler's jump, straight up off the water (or the
## ground), no run, its wings beating hard; spray thrown off.
func takeoff_to(to: Vector3) -> void:
	if young or dead:
		return
	if in_water():
		_splash(_pos, 0.8)
	_to("fly")
	_take_off("go", to, true)
	_vel = _fwd() * 1.0 + Vector3(0.0, 3.2, 0.0)


# --- a drake leaves her to it -----------------------------------------------------------------

## (A drake: he doesn't stand guard over her nest; off to forage.)
func guard(_at: Vector3) -> void:
	forage()


## His display after mating: up out of the water, his head drawn back, his
## tail cocked up (head-up-tail-up); then swimming off, nodding.
func _post(_dt: float) -> void:
	want.pitch = -0.35 if _mt < 1.2 else 0.0
	head_want = (Vector3(0.0, 0.04, 0.03) if _mt < 1.2 else Vector3(0.0, 0.01 * sin(_mt * 6.0), -0.01)) * size
	want.head_pitch = -0.45 if _mt < 1.2 else 0.1
	want.tail_up = 0.6 if _mt < 1.2 else 0.0
	if _mt > _secs:
		head_want = Vector3.ZERO
		want.tail_up = 0.0
		forage()


## A duckling: the goose's gosling's shape (round, its head big, its bill
## short), its own down: yellow below and on its face, dark brown above, a
## dark line through its eye.
func _eyas() -> Dictionary:
	var e: Dictionary = super()
	e = e.duplicate(true)
	var sp := []
	for s: Array in e.spine:
		var u := float(s[4])
		sp.append([s[0], s[1], float(s[2]) * (1.25 if u >= 4.85 else 1.0), float(s[3]) * (0.85 if u >= 4.85 else 1.0), u]) # (its bill broad, flat)
	e.spine = sp
	return e
