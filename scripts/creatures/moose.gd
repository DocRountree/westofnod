class_name Moose
extends "res://scripts/creatures/deer.gd" # (by path: found whether or not the editor has seen the class yet)
## A moose (Alces alces americana), life size (a bull about 3 m long and
## 1.9 m at the shoulder, a cow a little smaller), on the deer's make and
## ways (Deer: grazing and browsing, bedding, the alert, flight, grooming, a
## bull's rub and scrape and sparring, a cow's calving and nursing, the
## mating), but its own: a short deep body high in front over a hump of
## muscle at the shoulders, very long legs; a short thick neck; its head
## long and heavy, the muzzle broad and overhanging, its upper lip great
## and mobile, its nostrils big; small eyes set high; long ears; the bell (a
## flap of hair-covered skin) hanging from its throat; a stub of a tail. Its
## coat a bull's near black, his face dark; a cow's browner, her face paler,
## grey brown, a pale patch under her tail; the legs pale grey brown below
## (the stockings); a bull a fifth bigger, his bell longer; a calf (Moose.new(true)) red brown,
## unspotted. A bull's antlers broad flat palms out from his head's sides,
## each fringed with points along its edge, a smaller brow palm before it
## (in velvet in summer, brown and thick; hard and pale in winter).
##
## Its own way (and the deer's, above): wade(at): out into the water, its
## head down under to the plants on the bottom, up again streaming, chewing,
## down again. Its world: wet (x, z) -> whether it's water there, water_y.
## Steering (pilot.gd): the deer's, and act wade {at}.

const MOOSE := {
	"male_parts": {"sheath": [300.0, 700.0, 30.0], "tuft": 90.0, "scrotum": [880.0, 60.0, 0.9]}, # (a grown bull's: Carnivore._build_male)
	"brace": 0.74,
	"species": 13, "hooves": true,
	"body": [[-1000.0, 80.0, 230.0, 320.0], [-850.0, 120.0, 330.0, 520.0], [-550.0, 140.0, 370.0, 560.0], [-150.0, 40.0, 350.0, 480.0],
			[250.0, 30.0, 330.0, 440.0], [600.0, 60.0, 300.0, 400.0], [850.0, 70.0, 210.0, 260.0], [960.0, 60.0, 80.0, 80.0]],
	"body_h": 1450.0, "body_len": 1960.0, "body_w": 350.0,
	"neck_at": Vector3(0.0, 260.0, -950.0), "neck": [[60.0, 0.0, 200.0, 300.0], [-200.0, -20.0, 160.0, 240.0], [-380.0, -20.0, 135.0, 205.0], [-450.0, -30.0, 125.0, 180.0]], "neck_pitch": 0.35,
	"head_at": Vector3(0.0, 0.0, -450.0),
	"head": [[80.0, 0.0, 120.0, 140.0], [-60.0, 10.0, 130.0, 160.0], [-210.0, -10.0, 95.0, 140.0], [-370.0, -15.0, 80.0, 125.0], [-500.0, -20.0, 85.0, 120.0], [-560.0, -20.0, 60.0, 90.0]],
	"jaw_at": Vector3(0.0, -177.0, -152.0), "jaw": [[0.0, 0.0, 55.6, 42.8], [-159.8, -35.3, 61.7, 46.1], [-319.6, -87.5, 54.0, 44.0]], "mouth": 2.4,
	"mouth_z": -1950.0,
	"eye": {"at": Vector3(70.0, 30.0, -165.0), "size": Vector3(36.0, 32.0, 38.0), "color": Color(0.06, 0.04, 0.03), "slit": 0.25},
	"nose": {"at": Vector3(0.0, -60.0, -560.0), "size": Vector3(90.0, 60.0, 50.0), "color": Color(0.1, 0.08, 0.07)},
	"whisker": 40.0,
	"ear": {"at": Vector3(62.0, 128.0, 45.0), "len": 270.0, "width": 165.0, "point": 0.75, "tilt_back": 0.4, "spread": 0.95},
	"tail": {"base": Vector3(0.0, 60.0, 950.0), "n": 3, "seg": 60.0, "radii": [55.0, 50.0, 34.0], "carry": [1.3, 0.05], "wrap": 0.2},
	"fore": {"hip": Vector3(190.0, -250.0, -760.0), "a": 420.0, "b": 560.0, "m": 520.0, "p": 120.0, "home": Vector2(200.0, -800.0), "r": 70.0},
	"hind": {"hip": Vector3(170.0, -100.0, 780.0), "a": 520.0, "b": 640.0, "m": 560.0, "p": 120.0, "home": Vector2(190.0, 830.0), "r": 75.0},
	"fur": 22.0, "tail_fur": 30.0,
	"walk": 1.5, "trot": 4.0, "run": 14.0,
	"stalk_from": 8.0, "spring": 3.0, "stalk_crouch": 0.1, "stalk_neck": 0.0, "eat_crouch": 0.0,
	"sit_drop": 700.0, "sit_pitch": 0.15, "lie_h": 650.0,
	"mate_secs": 6.0,
	# its head sculpted (SculptHead), from life: long and heavy, its brow broad; the
	# muzzle overhanging, swollen, its upper lip great; its nostrils big; its eyes
	# small, set high and back
	"sculpt": {
		"z": [80.0, 40.0, 0.0, -60.0, -130.0, -210.0, -290.0, -370.0, -440.0, -500.0, -545.0, -580.0],
		"top": [87.6, 136.8, 138.0, 116.8, 84.4, 47.8, 16.2, -5.4, -10.8, -15.0, -35.9, -97.6],
		"bot": [-52.4, -166.2, -205.0, -213.2, -210.6, -208.2, -213.8, -233.4, -261.8, -298.0, -324.9, -312.6], # (its muzzle sloping down, nose low)
		"w": [70.0, 100.0, 108.0, 98.0, 80.0, 66.0, 60.0, 62.0, 74.0, 82.0, 76.0, 48.0],
		"wl": [75.0, 115.0, 122.0, 108.0, 86.0, 70.0, 64.0, 68.0, 82.0, 92.0, 86.0, 55.0],
		"pw": [2.0, 2.0, 2.1, 2.2, 2.3, 2.4, 2.4, 2.5, 2.5, 2.4, 2.3, 2.1],
		"eye": Vector3(70.0, 30.0, -165.0), "eye_r": 23.0, "socket": 4.0, "lid": 3.5,
		"brow": 9.0, "cheek": 7.0, "stop": 1.0, "pads": 3.0, "flews": 22.0, "nose_r": 58.0,
		"almond": 0.66, "slant": 0.06, "look_fwd": 0.25, "pupil": Vector2(0.35, 0.9),
	},
}

var wet: Callable ## (x, z) -> whether it's water there
var water_y := 0.0
var _wade_at := Vector3.ZERO
var _bell: MeshInstance3D


func _spec() -> Dictionary:
	return MOOSE


func _young_size() -> float:
	return 0.16


func _male_size() -> float:
	return 1.2 # (a bull a fifth again a cow's size, his hump and neck the heavier for it)


func _coat(part: int, along := 0.0) -> ShaderMaterial:
	var m := super(part, along)
	m.set_shader_parameter("muzzle_z", -400.0)
	return m


func _build_extra() -> void:
	super() # (its hooves; a bull's antlers: _grow_antlers, its own)
	# the bell: a flap of skin and hair hanging from its throat (a bull's
	# longest): broad where it hangs from, narrowing down to a tassel of
	# long hair
	var bl := (380.0 if male else 220.0) * (0.3 if young else 1.0)
	var fl := 30.0 if not young else 12.0
	_bell = _part(Vector3(0.0, -180.0, 30.0), Vector3(60.0, 170.0, 150.0), _coat(8), _head) # (sizes across: a unit sphere's)
	_fur_shells(_bell, fl, 6)
	var tassel := _part(Vector3(0.0, -230.0 - bl * 0.5, 45.0), Vector3(75.0, bl, 115.0), _coat(8), _head)
	tassel.rotation.x = -0.08
	_fur_shells(tassel, fl * 2.0, 10) # (long, shaggy)
	_part(Vector3(0.0, -230.0 - bl * 0.97, 55.0), Vector3(45.0, 70.0, 60.0), _coat(8), _head) # (its tip)


## A bull's antlers: from each pedicle a short thick beam out to the side,
## then the palm: one broad plate (its own mesh: _palm_mesh) cupped up, its
## outer edge raised, spreading out and back, fringed with tines round its
## rim; before it, split off by a deep cleft, the smaller brow palm, its few
## tines forward. (In velvet in summer: thicker, brown felt; hard and pale
## in winter.)
func _grow_antlers() -> void:
	var m := _coat(7)
	var thick := 1.2 if season == 0 else 1.0
	for side: float in [-1.0, 1.0]:
		var base := Vector3(70.0 * side, 133.0, 25.0)
		_part(base, Vector3(52.0, 34.0, 52.0) * thick, m, _head) # (the burr)
		var out := base + Vector3(105.0 * side, 34.0, 18.0)
		_stick(base, out, 30.0 * thick, m, _head)
		_part(out, Vector3(44.0, 36.0, 48.0) * thick, m, _head) # (where it flares into the palm)
		var palm := Node3D.new()
		palm.position = out + Vector3(10.0 * side, 4.0, 0.0)
		palm.rotation = Vector3(-0.7, 0.1 * side, 0.3 * side)
		_head.add_child(palm)
		_mesh(_palm_mesh(side, thick, hash(get_instance_id()) + int(side)), m, palm)


## An antler's palm (mm, its root at the origin, out along x by side, up y,
## back +z): its outline round from the brow palm's forward tip to the main
## palm's back, each tine a sharp point out from the rim, the cleft between
## the two palms; through it rings from the root out, the plate thick at its
## root, thin at its rim, cupped up.
static func _palm_mesh(side: float, thick: float, seed_: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var outline: Array[Vector2] = [] # (angle from +x toward back +z, radius)
	var add_lobe := func(a0: float, a1: float, r: float, tines: int, tl: float) -> void:
		for k in tines:
			var f0 := float(k) / tines
			var f1 := float(k + 1) / tines
			var am := lerpf(a0, a1, (f0 + f1) * 0.5)
			var rr := r * (0.86 + 0.14 * sin(PI * (f0 + f1) * 0.5))
			outline.append(Vector2(lerpf(a0, a1, f0), rr * 0.97))
			outline.append(Vector2(am - (a1 - a0) / tines * 0.12, rr * 1.02))
			outline.append(Vector2(am + rng.randf_range(-0.02, 0.02), rr + tl * rng.randf_range(0.75, 1.2))) # (the tine's point)
			outline.append(Vector2(am + (a1 - a0) / tines * 0.12, rr * 1.02))
		outline.append(Vector2(a1, r * 0.9))
	add_lobe.call(-1.25, -0.62, 210.0, 3, 95.0) # (the brow palm, forward)
	outline.append(Vector2(-0.5, 95.0)) # (the cleft)
	add_lobe.call(-0.38, 1.55, 390.0, 8, 105.0) # (the main palm, out and back)
	var rings: Array[float] = [0.0, 0.18, 0.4, 0.62, 0.8, 0.92, 1.0]
	var pt := func(i: int, j: int, up: float) -> Vector3:
		var o: Vector2 = outline[j]
		var t := rings[i]
		var r := o.y * t
		var h := lerpf(26.0, 4.0, pow(t, 1.2)) * thick * (0.55 if o.y < 160.0 and t > 0.5 else 1.0)
		var y := 0.0003 * r * r + (h * up) # (cupped up, toward its rim)
		return Vector3(cos(o.x) * r * side, y, sin(o.x) * r)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri := func(a: Vector3, b: Vector3, c: Vector3) -> void:
		if side > 0.0:
			st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
		else:
			st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
	var n := outline.size()
	for i in rings.size() - 1:
		for j in n - 1:
			for up: float in [1.0, -1.0]:
				var a: Vector3 = pt.call(i, j, up)
				var b: Vector3 = pt.call(i, j + 1, up)
				var c: Vector3 = pt.call(i + 1, j + 1, up)
				var d: Vector3 = pt.call(i + 1, j, up)
				if up > 0.0:
					tri.call(a, b, c); tri.call(a, c, d)
				else:
					tri.call(a, c, b); tri.call(a, d, c)
	var last := rings.size() - 1
	for j in n - 1: # (the rim: its thin edge)
		var a: Vector3 = pt.call(last, j, 1.0)
		var b: Vector3 = pt.call(last, j + 1, 1.0)
		var c: Vector3 = pt.call(last, j + 1, -1.0)
		var d: Vector3 = pt.call(last, j, -1.0)
		tri.call(a, b, c); tri.call(a, c, d)
	for j: int in [0, n - 1]: # (its two ends: the brow palm's front, the main palm's back)
		for i in rings.size() - 1:
			var a: Vector3 = pt.call(i, j, 1.0)
			var b: Vector3 = pt.call(i + 1, j, 1.0)
			var c: Vector3 = pt.call(i + 1, j, -1.0)
			var d: Vector3 = pt.call(i, j, -1.0)
			if j == 0:
				tri.call(a, b, c); tri.call(a, c, d)
			else:
				tri.call(a, c, b); tri.call(a, d, c)
	st.index()
	st.generate_normals()
	return st.commit()


# --- its own way ----------------------------------------------------------------------

## Out into the water to at, its head down under to the plants on the bottom.
func wade(at: Vector3) -> void:
	_mode = "wade"
	_wade_at = at
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	if _mode == "wade" and not young:
		_common(dt)
		_wade(dt)
		return
	super(dt)


func _wade(_dt: float) -> void:
	match _stage:
		0: # (out to it, wading)
			_target = _wade_at
			_pace = float(S.walk) * 0.4
			_neck_to = Vector2(0.0, 0.0)
			if Vector2(_pos.x - _wade_at.x, _pos.z - _wade_at.z).length() < 0.3:
				_target = _pos
				_stage = 1
				_st = 0.0
		1: # (its head down under the water, pulling up plants; up again, streaming, chewing)
			_target = _pos
			var cyc := fmod(_st, 12.0)
			if cyc < 7.0:
				_neck_to = Vector2(-1.4, 0.2 * sin(_st * 0.6)) # (down, under)
				_jaw_to = 0.1 * maxf(sin(_st * 5.0), 0.0)
			else:
				_neck_to = Vector2(0.2, 0.3 * sin(_st * 0.5)) # (up, chewing, looking round)
				_chew = 1.0
				_jaw_to = 0.06 * maxf(sin(_st * 6.0), 0.0)
				_ears_to = 0.6
			if _st > 40.0:
				graze(_pos, 1.5)


func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append("wade")
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	if name == "wade":
		wade(args.get("at", _pos + Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * 2.0))
		return true
	return super(name, args)


func _p_act_done(name: String) -> bool:
	if name == "wade":
		return _mode != "wade"
	return super(name)
