class_name Owl
extends "res://scripts/creatures/raptor.gd"
## An owl: a Raptor made upright and round headed, of the night. What's
## its own: a big round head with a flat face (a disc of fine feathers
## round each forward eye), a short hooked bill sunk in it, legs feathered
## to the toes, soft broad wings; by day dozing on its perch, puffed, an
## eye opened now and then; at dusk and by night (OakTree's night) awake:
## its head turned far round, weaving side to side to place a sound,
## hooting (leaned forward, its throat swelled, its tail cocked), casting
## a pellet, quartering low and slow, dropping on its prey from a perch.
## Cornered, its threat: wings spread and turned forward, puffed to twice
## its size, swaying, its bill clacking.
##
## A species gives owl_shape() its measures, _plumage() and mass_of().


func _init(young_ := false, juvenile_ := false) -> void:
	super(young_, juvenile_)
	stoop_speed = 0.0
	flaps_glide = false
	hunt_style = "dash"
	tail_rest = -1.38
	flight_pitch = 1.38
	fold_pitch = 1.38
	beat_amp = 1.0
	egg_colors = [Color(0.95, 0.94, 0.9), Color(0.95, 0.94, 0.9)] # (white, round)
	prey_scripts = ["mouse.gd"]


## An owl's body (cm, before k): k its size (1 a great horned owl's), g its
## girth, h its head's size, lift its legs' length more, tuft its ear
## tufts' length (0 none), eye_r its eye, tail and wing their lengths'
## share.
func owl_shape(k: float, g: float, h: float, lift: float, tuft: float, eye_r: float, tail_len: float, wing: float, heart := 0.0) -> Dictionary:
	# its head: big, broad, flat topped; its face a plate (a barn owl's flatter, narrowed to a heart at its chin), forward of its breast
	var hc := Vector3(0.0, 38.0 + 6.2 * h, -3.6 - 1.2 * heart)
	var hr := Vector3(7.6 - 1.1 * heart, 6.2 + 0.9 * heart, 6.4) * h
	var flat := 0.55 - 0.1 * heart
	var fpow := 0.55 - 0.2 * heart
	var taper := 0.32 * heart
	var sg := maxf(g, 0.92) # (its shoulders: broad enough to carry its folded wings, however slim it is)
	var bones := Vector3(12.0, 14.0, 9.0) * lerpf(1.0, wing, 0.3)
	wing *= lerpf(1.0, wing, 0.3) # (a long wing's length in its feathers more than its bones: folded, its wrist kept behind its breast)
	var face := func(x: float, y: float) -> float:
		var dy := (y - hc.y) / hr.y
		var dx := x / (hr.x * (1.0 - taper * pow(maxf(-dy, 0.0), 1.5)))
		return hc.z - flat * hr.z * pow(sqrt(maxf(1.0 - dx * dx - dy * dy, 0.0)), fpow)
	var ex := 2.75 * h * (1.0 - 0.25 * heart)
	var ey := hc.y + 0.7 * h
	var by := hc.y - (1.3 + 1.2 * heart) * h
	var bz: float = face.call(0.0, by)
	var b := minf(h, 1.0) * (0.72 + 0.28 * heart) # (its bill: a horned owl's short, all but hidden in its bristles; a barn owl's long)
	var S := {
		"tilt_rings": true,
		"leg_part": 7.0,
		# (folded: its wrist forward of its shoulder, its feathers fanned back and down over its side, drawn in over its rump)
		# (upright: its tail's root, up its body, its neck lost in its feathers; then forward, hidden in its head, to the bill)
		"spine": [[7.5, 7.0, 1.0, 1.0, 0.0], [8.5, 5.8, 6.5 * g, 5.5 * g, 0.0], [12.5, 4.0, 8.6 * g, 8.6 * g, 0.0], [19.0, 2.4, 9.2 * g, 9.0 * g, 0.0], [26.0, 1.3, 9.0 * sg, 8.8 * g, 0.0],
				[31.5, 0.9, 8.6 * sg, 7.6 * g, 0.2], [35.0, 1.3, 8.0 * sg, 6.1 * g, 1.0], [37.0, 1.6, 7.2 * g, 5.3 * g, 2.0], [38.8, 1.7, 6.6 * g, 4.6 * g, 3.0],
				[40.5, 1.4, 6.0 * g, 4.0 * g, 4.0], [hc.y, hc.z, 3.0, 3.0, 4.5], [lerpf(hc.y, by, 0.6), lerpf(hc.z, bz, 0.6), 2.0, 2.0, 4.9], [by + 0.2 * b, bz + 0.4 * b, 1.0 * b, 1.15 * b, 5.0],
				[by - 0.3 * b, bz - 0.35 * b, 0.85 * b, 0.95 * b, 5.05], [by - 1.3 * b, bz - 0.95 * b, 0.6 * b, 0.66 * b, 5.5], [by - 2.3 * b, bz - 0.85 * b, 0.28 * b, 0.28 * b, 5.85], [by - 2.9 * b, bz - 0.45 * b, 0.07, 0.07, 6.0]],
		"pivot": Vector3(0.0, 20.0, 2.5),
		"jaw": Vector3(0.0, by - 0.9 * b, bz + 0.2 * b),
		"lower_bill": [[by - 1.0 * b, bz - 0.1 * b, 0.6 * b], [by - 1.6 * b, bz - 0.5 * b, 0.42 * b], [by - 2.1 * b, bz - 0.55 * b, 0.12 * b]],
		"head_ball": [hc, hr, flat, fpow, taper],
		"eye": Vector3(ex, ey, float(face.call(ex, ey)) + eye_r * 0.62), "eye_r": eye_r,
		"hip": Vector3(4.2 * g, 13.0, 3.0), "knee": Vector3(4.6 * g, 9.5, -0.5), "ankle": Vector3(4.2 * g, 5.0, 1.6), "foot": Vector3(4.2 * g, 1.3, 0.0),
		"thigh_r": [5.2 * g, 3.0], "leg_r": 0.9, "toes": [4.6, 3.6, 3.0], "claw": 0.4, "claw_r": 0.5, "tuck": Vector3(0.0, -0.05, 0.0),
		"tail": Vector3(0.0, 9.0, 7.0),
		"shoulder": Vector3(8.4 * g, 33.0, 3.0 + 5.0 * (wing - 1.0)), "wing": bones, "coverts": [2.0, 3.5, 3.0, 1.5], "fold_fan": Vector3(-0.5, -0.32, -0.06), "fold_tuck": 0.3, "fold_tuck_front": 3.2,
		"wing_thick": [1.5, 1.1, 0.75, 0.35],
		"primaries": [19.0 * wing, 21.0 * wing, 23.0 * wing, 25.0 * wing, 26.0 * wing, 26.5 * wing, 26.5 * wing, 25.5 * wing, 23.5 * wing, 20.0 * wing],
		"secondaries": [12, 19.0 * wing, 18.0 * wing], "tertials": [3, 14.0 * wing, 12.0 * wing], "feather_w": 6.6 * wing,
		"tail_feathers": [12, tail_len, 6.5], "tail_coverts": [[10, 8.0, 4.0, 0.5, 0.9]],
	}
	# the ridge down between its eyes to the bill, feathered (a barn owl's long and sharp)
	var ry := lerpf(ey, by, 0.45)
	S["ridge"] = [Vector3(0.0, ry, float(face.call(0.0, ry)) + 0.25 * h), Vector3(0.75 * h * (0.7 + 0.3 * heart), (ey - by) * 0.55 + 0.6 * h, 0.75 * h)]
	if tuft > 0.0: # (at the top corners of its head, leaning out a little, back a little)
		S["tufts"] = [[Vector3(hr.x * 0.62, hc.y + hr.y * 0.72, hc.z - 0.5 * h), Vector3(1.5 * h, tuft, 0.35 * h), 0.32, 0.25]]
	return _fit(S, k, lift)


# its legs longer by lift (all above its feet raised), then all of it to size k
func _fit(S: Dictionary, k: float, lift: float) -> Dictionary:
	for key: String in ["pivot", "jaw", "eye", "tail", "shoulder", "hip"]:
		S[key] = (S[key] as Vector3) + Vector3(0.0, lift, 0.0)
	S.knee = (S.knee as Vector3) + Vector3(0.0, lift * 0.62, 0.0)
	S.ankle = (S.ankle as Vector3) + Vector3(0.0, lift * 0.3, 0.0)
	for row: Array in S.spine:
		row[0] += lift
		for c in 4:
			row[c] *= k
	for row: Array in S.lower_bill:
		row[0] += lift
		for c in 3:
			row[c] *= k
	var hb: Array = S.head_ball
	hb[0] = ((hb[0] as Vector3) + Vector3(0.0, lift, 0.0)) * k
	hb[1] = (hb[1] as Vector3) * k
	var rg: Array = S.ridge
	rg[0] = ((rg[0] as Vector3) + Vector3(0.0, lift, 0.0)) * k
	rg[1] = (rg[1] as Vector3) * k
	for tf: Array in S.get("tufts", []):
		tf[0] = ((tf[0] as Vector3) + Vector3(0.0, lift, 0.0)) * k
		tf[1] = (tf[1] as Vector3) * k
	for key: String in ["pivot", "jaw", "eye", "tail", "shoulder", "hip", "knee", "ankle", "foot", "wing", "tuck"]:
		S[key] = (S[key] as Vector3) * k
	for key: String in ["eye_r", "leg_r", "feather_w"]:
		S[key] = float(S[key]) * k
	for key: String in ["thigh_r", "toes", "coverts", "wing_thick", "primaries"]:
		var a: Array = S[key]
		for i in a.size():
			a[i] = float(a[i]) * k
	for key: String in ["secondaries", "tertials", "tail_feathers"]:
		var a: Array = S[key]
		a[1] = float(a[1]) * k
		a[2] = float(a[2]) * k
	for row: Array in S.tail_coverts:
		row[1] *= k
		row[2] *= k
	return S


## The plumage's shared part: its eyes forward, its disc on (r: the disc's
## reach round each eye, cm at its size).
func owl_face(r_cm: float, over: Dictionary) -> Dictionary:
	var d := {
		"eye_dir": Vector3(0.16, 0.0, -0.99), "disc": 1.0, "disc_r": r_cm * 0.01,
		"hood_nape": 0.0, "malar": 0.0, "cheek": 0.0, "back_from": 0.22, "back_from_hi": 0.13, "throat_clean": 0.8,
		"tail_tip_w": 0.03, "puff_cm": 0.9 * r_cm, "puff_head": 0.0, "fl_top_bars": 0.7, "bill_tip": Color(0.05, 0.05, 0.05),
	}
	d.merge(over, true)
	return d


func is_night() -> bool:
	return OakTree._night > 0.3


## Its threat (cornered, at its nest): wings out and turned forward, all its
## feathers up, swaying, its bill clacked.
func threat(secs := 6.0) -> void:
	if _air or young or dead:
		return
	_to("threat")
	_secs = secs


## Casting a pellet (the fur and bones of its last meals): its neck
## stretched, gaping, a shake of its head; it drops.
func cast_pellet() -> void:
	if _air or young or dead:
		return
	_to("pellet")


func _think(dt: float) -> void:
	super(dt)
	if _air or dead:
		return
	match _mode:
		"call": # (a hoot: leaned forward, its white throat swelled at each note, its tail cocked; its bill all but shut)
			var note := maxf(0.0, sin(_mt * 5.5)) * float(fmod(_mt, 3.2) < 2.2)
			want.pitch = 0.3
			want.tail_up = tail_rest + 0.55
			want.puff = 0.25 + 0.5 * note
			want.jaw = 0.06 * note
			want.head_pitch = -0.1
			rate["puff"] = 14.0
		"threat":
			want.puff = 1.0
			want.pitch = 0.45
			want.drop = 0.03 * size
			set_wings(0.1, 0.25, -1.1, 1.0)
			want.sway = 0.0
			want.roll = 0.16 * sin(_mt * 2.4)
			look_yaw = 0.5 * sin(_mt * 2.4 + 0.8)
			want.jaw = 0.3 * float(fmod(_mt, 0.9) < 0.12) # (clack)
			rate["jaw"] = 40.0
			want.tail_spread = 0.8
			if _mt > _secs:
				perch()
		"pellet":
			var t := _mt
			if t < 1.6: # (its neck stretched up and forward, gaping wider)
				head_want = Vector3(0.0, 0.03, -0.05) * size * smoothstep(0.0, 1.2, t)
				want.jaw = 0.75 * smoothstep(0.3, 1.5, t)
				want.eye_shut = 1.0 if t > 0.8 else 0.0
				want.pitch = 0.35
			elif t < 2.6: # (a shake; out it comes)
				head_want = Vector3(0.012 * sin(t * 30.0), 0.0, -0.05) * size
				want.jaw = 0.8
				want.head_pitch = 0.5
				want.eye_shut = 1.0
				if _n == 0 and t > 2.0:
					_n = 1
					_drop_pellet()
			else:
				want.jaw = 0.0
				want.eye_shut = 0.0
				if t > 3.4:
					perch()


static var _pellet_mat: StandardMaterial3D
const PELLET_SECS := 180.0


func _drop_pellet() -> void:
	var par := get_parent()
	if par == null:
		return
	if _pellet_mat == null:
		_pellet_mat = StandardMaterial3D.new()
		_pellet_mat.albedo_color = Color(0.2, 0.19, 0.18)
		_pellet_mat.roughness = 1.0
	var pm := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.011 * size
	cap.height = 0.045 * size
	cap.radial_segments = 8
	cap.rings = 3
	pm.mesh = cap
	pm.material_override = _pellet_mat
	pm.set_meta("prop", true)
	par.add_child(pm)
	var from := bill_tip()
	pm.position = from
	pm.rotation = Vector3(1.4, _yaw, 0.3)
	var fwd := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var to := from + fwd * 0.12
	to.y = (float(height.call(to.x, to.z)) if height.is_valid() else ground_y) + 0.011 * size # (the ground under its perch)
	var tw := pm.create_tween()
	tw.tween_property(pm, "position", to, sqrt(maxf(from.y - to.y, 0.01) / 4.9)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(PELLET_SECS) # (left a while, then gone: broken up, rained away)
	tw.tween_property(pm, "scale", Vector3.ONE * 0.01, 5.0)
	tw.tween_callback(pm.queue_free)


# on its perch: by day dozing; by night watching, listening
func _watch(dt: float) -> void:
	if young:
		super(dt)
		return
	if not is_night():
		var peek := fmod(_mt + 3.0, 12.0) > 9.5 # (an eye opened: its head round to look, and back)
		want.puff = 0.45
		want.eye_shut = 0.0 if peek else 1.0
		want.drop = 0.01 * size
		look_yaw = lerpf(look_yaw, 1.5 * sin(floor((_mt + 3.0) / 12.0) * 2.1 + 1.0) if peek else 0.0, 1.0 - exp(-3.0 * dt))
		head_want = Vector3(0.0, -0.012, 0.0) * size
		if _st > 15.0:
			_st = 0.0
			if rng.randf() < 0.15:
				preen(rng.randf_range(5.0, 9.0))
		return
	want.puff = 0.0
	want.eye_shut = 0.0
	want.drop = 0.0
	look_yaw = lerpf(look_yaw, 2.3 * sin(floor(_mt / 3.0) * 2.7), 1.0 - exp(-7.0 * dt)) # (far round: over its back)
	if fmod(_mt, 6.0) > 4.4: # (weaving: its head side to side, up and down, placing a sound)
		head_want = Vector3(0.022 * sin(_mt * 5.0), 0.012 * sin(_mt * 7.3), 0.0) * size
	else:
		head_want = Vector3.ZERO
	if _st > 6.0:
		_st = 0.0
		var r := rng.randf()
		if hunger > 0.5:
			var p := _find_prey()
			if p:
				hunt(p)
				return
		if r < 0.14:
			call_out(6.0)
		elif r < 0.2:
			rouse()
		elif r < 0.26:
			preen(rng.randf_range(5.0, 9.0))
		elif r < 0.31:
			cast_pellet()
		elif r < 0.4:
			soar(rng.randf_range(20.0, 35.0)) # (quartering: low, slow)
		elif r < 0.46 and home_perch != Vector3.INF and perch_at.distance_to(home_perch) > 0.5:
			perch_on(home_perch)


func test_mode(mode: String) -> void:
	if mode.contains("night"):
		OakTree._night = 1.0
	super(mode)
	if mode.contains("threat"):
		threat(60.0)
	if mode.contains("pellet"):
		cast_pellet()
