class_name Opossum
extends "res://scripts/creatures/carnivore.gd" # (by path: found whether or not the editor has seen the class yet)
## A Virginia opossum (Didelphis virginiana), life size (about 40 cm head
## and body, its tail 30 cm more, 18 cm at the shoulder), on the
## four-legged make (Carnivore: plantigrade, a bear's feet) and one skin:
## low, round backed, its rump high, its coat long and shaggy, grizzled
## grey (white underfur, white guard hairs, black ones among them); its legs
## short, black, its feet bare and pinkish white, five fingered, the hind
## foot's big toe a thumb, clawless, set against the rest; its head long
## and conical, white faced, a dark smudge round each small black eye, its
## snout long, the nose pink, overhanging the lower jaw; fifty teeth (more
## than any other land mammal here), shown when it gapes; its ears black,
## naked, round, pale rimmed; its tail long, bare, scaled, prehensile,
## black from its furred root for a third of its length, then white. A
## male a little bigger. (carnivore.gdshader's species 14.)
##
## Its ways (Carnivore's, and its own):
## - wander(centre, radius): about at an amble, nose down, sniffing; eat,
##   hunt, eat_at: anything (fallen fruit, carrion, a mouse, a grasshopper,
##   a snake, a toad, a grub), eaten piece by piece (Meal)
## - play_dead(secs): "playing possum": over on its side, stiff, curled,
##   its mouth open, its tongue out, drooling; still a while; then an ear
##   twitches, its head comes up, it looks round, and it gets up and goes
## - gape(secs): its threat: crouched, its mouth wide, every tooth showing,
##   hissing, swaying its head, drooling
## - climb(foot, top, r): up a leaning branch (to its foot, then up it, its
##   feet gripping round it, its hind thumbs opposed; its tail coiled round
##   the branch behind it); a while up there, looking about; turned round,
##   down head first, and off
## - gather(from, to): nest stuff: at the litter, leaves picked up in its
##   mouth, tucked back under its body by its forefeet to its hind feet,
##   and into the loop of its tail; carried in it to its den (to), left
##   there
## - groom(), sit(), sleep() (at its den: Opossum.den(), a hollow log),
##   mark() (its chin and neck rubbed along the ground)
## - birth(n): (a female's) sat up, licking her belly, her young born one
##   by one, each the size of a bee, pink, naked: up her fur into her pouch
##   (out of sight); grown there a while, they come out and climb onto her
##   back, clinging to her fur, carried as she goes; play() (the young's):
##   down off her, tumbling with one another, then after her and back on
##   (she waits for them); nurse(): down on her side, her young off her
##   back and at her belly; then back on
## - mate(her): he follows her, clicking; mounts her from behind, gripping
##   her neck fur in his teeth, his feet clasped round her; and the two of
##   them topple over together onto their sides, a while
## Steering (pilot.gd): Carnivore's, and act play_dead {seconds}, gape
## {seconds}, climb {foot, top, radius}, gather {from, to}.

const SPEC := {
	"male_parts": {"scrotum": [92.0, 13.0, 0.9]}, # (a grown male's, in front of his hind legs: Carnivore._build_male)
	"species": 14, "plantigrade": true, "sole_hind": 1.1, "boxy": 2.1,
	"body": [[-150.0, 5.0, 50.0, 56.0], [-110.0, 0.0, 66.0, 74.0], [-40.0, 2.0, 76.0, 82.0], [40.0, 12.0, 84.0, 90.0],
			[110.0, 22.0, 82.0, 86.0], [160.0, 28.0, 60.0, 64.0], [185.0, 30.0, 24.0, 24.0]],
	"body_h": 122.0, "body_len": 380.0, "body_w": 80.0,
	"neck_at": Vector3(0.0, 16.0, -140.0), "neck": [[20.0, 0.0, 46.0, 50.0], [-25.0, 0.0, 39.0, 41.0], [-55.0, 0.0, 33.0, 35.0]], "neck_pitch": 0.3,
	"head_at": Vector3(0.0, 0.0, -68.0),
	"head": [[28.0, 0.0, 30.0, 30.0], [0.0, 4.0, 34.0, 32.0], [-40.0, -2.0, 20.0, 18.0], [-80.0, -6.0, 10.0, 9.0], [-98.0, -8.0, 5.0, 5.0]],
	"jaw_at": Vector3(0.0, -23.0, -28.0), "jaw": [[0.0, 0.0, 13.0, 6.5], [-35.0, 0.0, 8.0, 5.0], [-60.0, 1.5, 4.2, 3.2]], "mouth": 0.5,
	"mouth_z": -330.0,
	"eye": {"at": Vector3(17.0, 13.0, -24.0), "size": Vector3(9.0, 9.0, 9.0), "color": Color(0.02, 0.018, 0.018), "slit": 1.0},
	"nose": {"at": Vector3(0.0, -4.0, -98.0), "size": Vector3(13.0, 10.0, 10.0), "color": Color(0.86, 0.58, 0.6)},
	"whisker": 62.0,
	"ear": {"at": Vector3(22.0, 26.0, 4.0), "len": 34.0, "width": 31.0, "point": 0.3, "tilt_back": 0.15, "spread": 0.5},
	"tail": {"base": Vector3(0.0, 26.0, 182.0), "n": 8, "seg": 38.0, "radii": [21.0, 17.0, 14.0, 11.5, 9.5, 8.0, 6.5, 5.0], "carry": [0.42, 0.06], "wrap": 0.7, "twitch": 0.3},
	"fore": {"hip": Vector3(44.0, -40.0, -100.0), "a": 58.0, "b": 56.0, "m": 24.0, "p": 30.0, "home": Vector2(50.0, -114.0), "r": 13.0},
	"hind": {"hip": Vector3(48.0, -14.0, 115.0), "a": 64.0, "b": 62.0, "m": 44.0, "p": 26.0, "home": Vector2(54.0, 66.0), "r": 16.0},
	"fur": 36.0, "tail_fur": 0.0,
	"walk": 0.35, "trot": 0.8, "run": 1.9,
	"stalk_from": 0.7, "spring": 0.3, "stalk_crouch": 0.1, "stalk_neck": -0.45, "eat_crouch": 0.35,
	"sit_drop": 40.0, "sit_pitch": 0.75, "lie_h": 58.0,
	"mate_secs": 18.0,
	# its head sculpted (SculptHead), from photographs: long, conical; its
	# skull narrow, its brow low, no stop to speak of; its snout long and
	# tapering to the pink nose, which overhangs its lower jaw; its eyes
	# small, black, beady, set forward; its whisker pads slight
	"sculpt": {
		"z": [28.0, 16.0, 4.0, -8.0, -20.0, -32.0, -44.0, -56.0, -70.0, -84.0, -98.0],
		"top": [20.0, 31.0, 36.0, 36.0, 32.0, 26.0, 20.5, 15.5, 11.5, 8.5, 5.5],
		"bot": [-20.0, -26.0, -28.0, -27.0, -24.0, -21.0, -18.5, -16.5, -14.5, -12.0, -8.5],
		"w": [22.0, 30.0, 32.0, 29.0, 23.0, 17.5, 13.5, 11.0, 9.0, 7.5, 5.5],
		"wl": [24.0, 33.0, 37.0, 33.0, 25.5, 18.5, 14.0, 11.0, 9.0, 7.5, 5.5],
		"pw": [2.0, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.5, 2.5, 2.4, 2.2],
		"eye": Vector3(16.0, 12.0, -22.0), "eye_r": 5.2, "socket": 0.5, "lid": 0.6,
		"brow": 1.0, "cheek": 1.4, "stop": 0.6, "pads": 1.2, "flews": 0.5, "nose_r": 6.0,
		"almond": 0.88, "slant": 0.0, "look_fwd": 0.85, "pupil": Vector2(0.8, 0.8),
	},
}

const POUCH_OUT := 0.074 ## (a joey's size when it comes out of the pouch)
const RIDE_SIZE := 0.13 ## (grown, on her back, this big: its size)

# a joey's
var _carrier: Node3D # (its mother: in her pouch, or on her back)
var _in_pouch := false
var _crawl := -1.0 # (newborn: its crawl up her belly to the pouch, s; -1 in)
var _board_t := 1.0 # (its climb on, 0..1)
var _board_from := Transform3D()
var _slot := 0
# its climb
var _branch: Array = [] # [foot, top, radius] (m, its parent's space)
var _cu := 0.0 # (how far up it its middle is, 0..1)
var _cph := 0.0
var _going_up := true
var _turn := 0.0
var _on_branch := false
# gathering
var _gather_at := Vector3.ZERO
var _gather_to := Vector3.ZERO
var _bundle: Node3D
var _mouth_leaf: Node3D
var _tuck := 0.0 # (its forefeet tucked back under its chest)
# its parts
var _tongue: MeshInstance3D
var _teeth: Array[MeshInstance3D] = [] # (shown only with its mouth open: shut, its lips cover them)
var _drool: Array[MeshInstance3D] = []
var _together := 0.0 # (mating: how long they've been joined)
var _den_first := false
static var _leaf_mats: Array = []


func _init(young_ := false) -> void:
	S = SPEC
	young = young_
	super(young_, RIDE_SIZE if young_ else 0.5)
	_setup()


func _male_size() -> float:
	return 1.12


# --- its own parts ------------------------------------------------------------------

func _build_extra() -> void:
	var sc: Dictionary = S.sculpt
	# its fifty teeth: the upper's (five incisors a side, small, at the front
	# of its snout; a long canine; three premolars and four molars back
	# along), the lower's (four incisors a side, a canine, three and four):
	# set in under its lips, shown when it gapes
	var tooth := _mat(Color(0.93, 0.9, 0.8), 0.3)
	for side: float in [-1.0, 1.0]:
		for j in 5:
			var z := -95.0 + float(j) * 1.6
			var y := SculptScript._key(sc, "bot", z)
			_teeth.append(_stick(Vector3((0.8 + float(j) * 1.1) * side, y + 2.5, z), Vector3((0.8 + float(j) * 1.1) * side, y - 2.2, z - 0.4), 0.7, tooth, _head))
		for j in 8:
			var z := lerpf(-84.0, -36.0, float(j) / 7.0)
			var y := SculptScript._key(sc, "bot", z)
			var x := SculptScript._key(sc, "wl", z) * 0.62
			var canine := j == 0
			var l := 8.5 if canine else lerpf(3.0, 4.2, float(j) / 7.0)
			_teeth.append(_stick(Vector3(x * side, y + 3.0, z), Vector3(x * side * 0.98, y - l + 1.5, z - (1.2 if canine else 0.0)), 1.5 if canine else lerpf(1.0, 1.7, float(j) / 7.0), tooth, _head))
		for j in 12: # (the lower's: up along its jaw's top)
			var z := lerpf(-60.0, -6.0, float(j) / 11.0)
			var k := _jaw_key(z)
			var canine := j == 2
			var l := 7.0 if canine else (2.6 if j < 2 else 3.5)
			var x := maxf(float(k.y) * 0.62, 1.2) if j >= 2 else 1.0 + float(j) * 1.2
			_teeth.append(_stick(Vector3(x * side, k.x + k.z - 2.0, z), Vector3(x * side, k.x + k.z + l - 1.0, z + (1.0 if canine else 0.0)), 1.3 if canine else 1.0, tooth, _jaw))
	# its mouth's lining: its palate, dark pink, under its skull (hidden
	# shut, inside its lips and jaw)
	var gum := _mat(Color(0.45, 0.16, 0.18), 0.45)
	for j in 4:
		var z := lerpf(-86.0, -38.0, float(j) / 3.0)
		var y := SculptScript._key(sc, "bot", z)
		var hw := SculptScript._key(sc, "wl", z) * 0.62
		_part(Vector3(0.0, y + 3.0, z), Vector3(hw * 2.0, 6.0, 20.0), gum, _head)
		# its tongue (out, lolling, playing dead) and its drool
	_tongue = _stick(Vector3(0.0, 1.0, -25.0), Vector3(3.0, -16.0, -80.0), 4.2, _mat(Color(0.78, 0.42, 0.44), 0.35), _jaw)
	_tongue.visible = false
	var spit := _mat(Color(0.92, 0.93, 0.95, 0.65), 0.08)
	spit.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for side: float in [-1.0, 1.0]:
		var d := _part(Vector3(9.0 * side, 2.0, -16.0), Vector3(3.5, 4.0, 5.0), spit, _jaw) # (at the corners of its mouth)
		d.visible = false
		_drool.append(d)
		var drip := _stick(Vector3(9.0 * side, 1.0, -16.0), Vector3(9.5 * side, -11.0, -14.0), 0.6, spit, _jaw)
		drip.visible = false
		_drool.append(drip)
	# its fingers and toes: five, bare, pink, spread like a star; the hind
	# foot's big toe a thumb, set out inward and back, clawless
	var pink := _mat(Color(0.88, 0.76, 0.73), 0.5)
	for i in 4:
		var paw := _legx[i][1] as MeshInstance3D
		var side := 1.0 if i % 2 == 1 else -1.0
		for k in 5:
			var x := (float(k) - 2.0) * 0.2
			if i >= 2 and k == (0 if side > 0.0 else 4): # (the thumb)
				_stick(Vector3(-side * 0.3, -0.25, 0.05), Vector3(-side * 1.0, -0.36, -0.05), 0.12, pink, paw)
				continue
			var spread := 2.0 if i < 2 else 1.4
			_stick(Vector3(x, -0.25, 0.3), Vector3(x * spread, -0.38, 1.0 - absf(x) * 0.4), 0.09, pink, paw)


## (Its lower jaw at z (the jaw's mm): its middle's y, its half width, its
## half height.)
func _jaw_key(z: float) -> Vector3:
	var jk: Array = S.jaw
	for j in jk.size() - 1:
		var a: Array = jk[j]
		var b: Array = jk[j + 1]
		if z <= float(a[0]) and z >= float(b[0]):
			var f := (float(a[0]) - z) / maxf(float(a[0]) - float(b[0]), 1e-3)
			return Vector3(lerpf(a[1], b[1], f), lerpf(a[2], b[2], f), lerpf(a[3], b[3], f))
	var l: Array = jk[jk.size() - 1] if z < float(jk[0][0]) else jk[0]
	return Vector3(l[1], l[2], l[3])


## (Its body at z (mm): its middle's y, half width, half height.)
func _body_key(z: float) -> Vector3:
	var bk: Array = (S.body as Array).duplicate()
	bk.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	if z <= float(bk[0][0]):
		return Vector3(bk[0][1], bk[0][2], bk[0][3])
	for j in bk.size() - 1:
		var a: Array = bk[j]
		var b: Array = bk[j + 1]
		if z >= float(a[0]) and z <= float(b[0]):
			var f := (z - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-3)
			return Vector3(lerpf(a[1], b[1], f), lerpf(a[2], b[2], f), lerpf(a[3], b[3], f))
	var l: Array = bk[bk.size() - 1]
	return Vector3(l[1], l[2], l[3])


## (Its fur: 0 a newborn's bare pink skin, 1 furred.)
func _set_fur(f: float) -> void:
	for n in find_children("*", "MeshInstance3D", true, false):
		var m := (n as MeshInstance3D).material_override
		if m is ShaderMaterial:
			(m as ShaderMaterial).set_shader_parameter("fur", f)


# --- props ----------------------------------------------------------------------------

## Its den: a hollow log, fallen, its open end (the origin, on the ground)
## facing -z, the log running back along +z.
static func den() -> Node3D:
	var root := Node3D.new()
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.36, 0.3, 0.24)
	bark.roughness = 0.95
	var c := CylinderMesh.new()
	c.top_radius = 0.12
	c.bottom_radius = 0.135
	c.height = 0.85
	c.radial_segments = 14
	var log_ := MeshInstance3D.new()
	log_.mesh = c
	log_.material_override = bark
	log_.rotation.x = PI * 0.5
	log_.position = Vector3(0.0, 0.115, 0.42)
	root.add_child(log_)
	var hole := CylinderMesh.new() # (its mouth: the rotten heart dark, a rim of pale wood)
	hole.top_radius = 0.1
	hole.bottom_radius = 0.1
	hole.height = 0.004
	var rim := MeshInstance3D.new()
	rim.mesh = hole
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.62, 0.52, 0.38)
	rim.material_override = wood
	rim.rotation.x = PI * 0.5
	rim.position = Vector3(0.0, 0.115, -0.004)
	root.add_child(rim)
	var dark := MeshInstance3D.new()
	var h2 := CylinderMesh.new()
	h2.top_radius = 0.085
	h2.bottom_radius = 0.085
	h2.height = 0.006
	dark.mesh = h2
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.05, 0.04, 0.03)
	dark.material_override = dm
	dark.rotation.x = PI * 0.5
	dark.position = Vector3(0.0, 0.112, -0.007)
	root.add_child(dark)
	return root


## A dead branch leaning from the ground at foot up to top (radius r), a
## stub or two off it; to climb.
static func snag(foot: Vector3, top: Vector3, r := 0.035) -> Node3D:
	var root := Node3D.new()
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.42, 0.38, 0.33)
	bark.roughness = 0.9
	var limb := func(a: Vector3, b: Vector3, ra: float, rb: float) -> void:
		var c := CylinderMesh.new()
		c.top_radius = rb
		c.bottom_radius = ra
		c.height = a.distance_to(b)
		c.radial_segments = 10
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = bark
		root.add_child(mi)
		var y := (b - a).normalized()
		var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
		mi.transform = Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5)
	limb.call(foot - (top - foot).normalized() * 0.05, top + (top - foot).normalized() * 0.1, r * 1.15, r * 0.75)
	var d := (top - foot)
	limb.call(foot + d * 0.45, foot + d * 0.45 + Vector3(0.12, 0.1, 0.06), r * 0.4, r * 0.15)
	limb.call(foot + d * 0.8, foot + d * 0.8 + Vector3(-0.1, 0.14, -0.02), r * 0.35, r * 0.12)
	return root


## Fallen fruit (persimmons, ripe, soft, orange) scattered round `at` (its
## parent's space): n of them; their places its "fruit" meta.
static func windfall(at: Vector3, n := 7, r := 0.18) -> Node3D:
	var root := Node3D.new()
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.86, 0.42, 0.12)
	fm.roughness = 0.35
	var s := SphereMesh.new()
	s.radius = 0.02
	s.height = 0.032
	var pts: Array = []
	var rr := RandomNumberGenerator.new()
	rr.seed = 7
	for k in n:
		var a := rr.randf() * TAU
		var p := Vector3(cos(a), 0.0, sin(a)) * sqrt(rr.randf()) * r
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.material_override = fm
		mi.position = p + Vector3.UP * 0.014
		root.add_child(mi)
		var cap := MeshInstance3D.new() # (its calyx: four brown sepals)
		var cs := SphereMesh.new()
		cs.radius = 0.01
		cs.height = 0.004
		cap.mesh = cs
		cap.material_override = _mat(Color(0.32, 0.24, 0.12), 0.8)
		cap.position = p + Vector3.UP * 0.03
		root.add_child(cap)
		pts.append(at + p + Vector3.UP * 0.016)
	root.position = at
	root.set_meta("fruit", pts)
	return root


## A fallen leaf (oak, maple: brown, tan, rust), lying flat: its origin at
## its middle. (mm: for a bundle carried in a tail; m, scale 1: on the
## ground.)
static func leaf(k := 0, mm := false) -> MeshInstance3D:
	if _leaf_mats.is_empty():
		for c: Color in [Color(0.48, 0.32, 0.16), Color(0.62, 0.45, 0.24), Color(0.55, 0.24, 0.1), Color(0.4, 0.3, 0.18)]:
			var m := StandardMaterial3D.new()
			m.albedo_color = c
			m.roughness = 0.85
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			_leaf_mats.append(m)
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 4
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = _leaf_mats[k % _leaf_mats.size()]
	var sz := Vector3(42.0, 2.5, 30.0) if mm else Vector3(0.05, 0.003, 0.035)
	mi.scale = sz
	mi.rotation.y = float(k) * 1.7
	return mi


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	if young and is_instance_valid(_mother):
		if _carrier == null:
			_mode = "follow" # (after her, and back on)
		return
	super(centre, radius)


## Playing possum: over on its side, stiff, its mouth open and drooling, a
## while (secs); then up, cautiously.
func play_dead(secs := 18.0) -> void:
	if _carrier != null or _on_branch or dead:
		return
	_mode = "play_dead"
	_stage = 0
	_st = 0.0
	_wait = secs


## Its threat: its mouth wide, every tooth bared, hissing.
func gape(secs := 6.0) -> void:
	if _carrier != null or _on_branch or dead:
		return
	_mode = "gape"
	_st = 0.0
	_wait = secs


## Up a leaning branch (its foot on the ground, its top; r its radius,
## m), a while, and down again head first.
func climb(foot: Vector3, top: Vector3, r := 0.035) -> void:
	if young or _carrier != null or dead:
		return
	_branch = [foot, top, r]
	_mode = "climb"
	_stage = 0
	_st = 0.0


## Leaves for its nest: picked up at `from`, carried in its tail to `to`.
func gather(from: Vector3, to: Vector3) -> void:
	if young or _carrier != null or _on_branch or dead:
		return
	_mode = "gather"
	_stage = 0
	_st = 0.0
	_gather_at = from
	_gather_to = to


func sleep(secs := 20.0) -> void:
	if young:
		return
	super(secs)
	_den_first = is_instance_valid(home_den) and home_den.position.distance_to(_pos) > 0.1


## (A female's.) Her young born, one by one, into her pouch.
func birth(n := 7, den_: Node3D = null) -> void:
	if young or male:
		return
	if den_ != null:
		home_den = den_
	_mode = "birth"
	_born_left = n
	_stage = 0
	_st = 0.0


func nurse() -> void:
	for y in young_ones:
		if is_instance_valid(y):
			_mode = "nurse"
			_stage = 0
			_st = 0.0
			return


## (A joey's.) Off her back, after one of the others: a stalk, a pounce, a
## tumble; then after her and back on.
func play() -> void:
	if not young or _in_pouch:
		return
	var best: Node3D = null
	for c in get_parent().get_children():
		if c != self and c.get_script() == get_script() and bool(c.get("young")) and not bool(c.get("_in_pouch")):
			if best == null or (c as Node3D).global_position.distance_to(global_position) < best.global_position.distance_to(global_position):
				best = c
	if best == null:
		return
	if _carrier != null:
		_off()
		var a := rng.randf() * TAU
		_pos += Vector3(cos(a), 0.0, sin(a)) * 0.08
		_place()
	if best.get("_carrier") != null:
		best.call("_off")
	_mode = "play"
	_sib = best
	_stage = 0
	_st = 0.0


# --- its thinking -----------------------------------------------------------------

func _think(dt: float) -> void:
	super(dt)
	if young:
		return
	match _mode:
		"play_dead":
			_play_dead(dt)
		"gape":
			_gape(dt)
		"climb":
			_climb(dt)
		"gather":
			_gather(dt)
		"sleep":
			if _den_first and is_instance_valid(home_den): # (to its den first)
				_target = home_den.position
				_lie_to = 0.0
				_wait += dt
				if Vector2(_pos.x - home_den.position.x, _pos.z - home_den.position.z).length() < 0.08 + 0.04 * size:
					_den_first = false
					_target = _pos
		"wander":
			# (her young off, after her: she waits for them, looking back)
			for y in young_ones:
				if is_instance_valid(y) and y.get("_carrier") == null and y.get("_mode") in ["follow", "play"]:
					_target = _pos
					_look_to = Vector2(0.0, 1.1 * sin(_t * 0.6))
					break
	_tuck = move_toward(_tuck, 1.0 if _mode == "gather" and _stage == 1 and fmod(_st, 2.6) > 0.9 and fmod(_st, 2.6) < 2.0 else 0.0, dt * 4.0)


## Playing possum.
func _play_dead(dt: float) -> void:
	_target = _pos
	_pace = -1.0
	match _stage:
		0: # (keeled over on its side, stiff, its lips drawn back, its mouth open, drooling)
			_lie_to = 1.0
			_lie = move_toward(_lie, 1.0, dt * 2.5) # (dropping: quickly)
			_side = move_toward(_side, 1.0, dt * 3.0)
			_curl = move_toward(_curl, 0.35, dt)
			_jaw_to = 0.5
			_neck_to = Vector2(-0.25, 0.45)
			_look_to = Vector2(0.25, 0.0)
			_ears_to = -0.25
			_tail_mode = "limp"
			if _st > _wait:
				_stage = 1
				_st = 0.0
		1: # (an ear twitches; its head comes up a little, looking)
			_lie_to = 1.0
			_side = move_toward(_side, 1.0, dt * 3.0)
			_curl = move_toward(_curl, 0.2, dt)
			_jaw_to = 0.05
			_ears_to = 0.5 * maxf(sin(_st * 5.0), 0.0) if _st < 1.5 else 0.3
			_neck_to = Vector2(0.2, -0.3) if _st > 1.5 else Vector2(-0.25, 0.45)
			_look_to = Vector2(0.1, 0.5 * sin(_st * 1.3)) if _st > 1.5 else _look_to
			_tail_mode = "limp"
			if _st > 4.0:
				_stage = 2
				_st = 0.0
		2: # (up, and off)
			if _lie < 0.05 and _side < 0.05:
				wander(_home_spot(), _radius)


## Gaping, hissing.
func _gape(dt: float) -> void:
	_target = _pos
	_crouch = move_toward(_crouch, 0.3, dt * 2.0)
	_jaw_to = 0.95
	_neck_to = Vector2(0.08 + 0.04 * sin(_st * 14.0), 0.28 * sin(_st * 0.9))
	_look_to = Vector2(0.05, 0.0)
	_ears_to = 0.2
	_tail_mode = "low"
	if _wait <= 0.0:
		_crouch = 0.0
		wander(_home_spot(), _radius)


## Its climb.
func _climb(dt: float) -> void:
	if _branch.is_empty():
		wander(_home_spot(), _radius)
		return
	var foot: Vector3 = _branch[0]
	var top: Vector3 = _branch[1]
	var L := foot.distance_to(top)
	var dxz := Vector3(top.x - foot.x, 0.0, top.z - foot.z).normalized()
	var half := float(S.body_len) * 0.5 * MM * size
	match _stage:
		0: # (to its foot, facing up it)
			var start := foot - dxz * half * 0.8
			_target = Vector3(start.x, _pos.y, start.z)
			_sniff = 1.0
			_neck_to = Vector2(0.2, 0.0)
			if Vector2(_pos.x - start.x, _pos.z - start.z).length() < 0.04:
				_target = _pos
				_turn_to = atan2(-dxz.x, -dxz.z)
				_stage = 1
				_st = 0.0
		1: # (turned to it: on)
			_target = _pos
			if _turn_to == INF or _st > 2.0:
				_turn_to = INF
				_on_branch = true
				_going_up = true
				_turn = 0.0
				_cu = 0.0
				_board_t = 0.0
				_board_from = transform
				_stage = 2
				_st = 0.0
		2: # (up it)
			_cu = minf(_cu + dt * 0.1 / L, 1.0 - half * 1.3 / L)
			_cph += dt * 1.5
			_neck_to = Vector2(0.15, 0.0)
			_tail_mode = "coil"
			if _cu >= 1.0 - half * 1.3 / L - 0.001:
				_stage = 3
				_st = 0.0
		3: # (up there: still, looking about, its tail round the branch)
			_tail_mode = "coil"
			_neck_to = Vector2(0.1, 0.0)
			if rng.randf() < dt * 0.6:
				_look_to = Vector2(rng.randf_range(-0.3, 0.2), rng.randf_range(-0.9, 0.9))
			_sniff = 1.0 if fmod(_st, 4.0) < 1.0 else 0.0
			if _st > 7.0:
				_look_to = Vector2.ZERO
				_stage = 4
				_st = 0.0
		4: # (turned round on it)
			_tail_mode = "coil"
			_turn = PI * smoothstep(0.0, 1.0, _st / 1.8)
			_cph += dt * 0.8
			if _st > 1.8:
				_turn = 0.0
				_going_up = false
				_stage = 5
				_st = 0.0
		5: # (down, head first)
			_cu = maxf(_cu - dt * 0.08 / L, half * 0.9 / L)
			_cph += dt * 1.3
			_neck_to = Vector2(0.3, 0.0)
			_tail_mode = "coil"
			if _cu <= half * 0.9 / L + 0.001:
				# (off it, onto the ground)
				_on_branch = false
				var out := foot - dxz * half * 1.2
				_pos = Vector3(out.x, _ground(out.x, out.z), out.z)
				ground_y = _pos.y
				_yaw = atan2(dxz.x, dxz.z)
				_pitch = 0.0
				_roll = 0.0
				_target = _pos
				_place()
				for i in 4:
					_feet[i] = _home(i)
					_pose_foot[i] = null
				wander(_home_spot(), _radius)


## Gathering nest stuff.
func _gather(dt: float) -> void:
	match _stage:
		0: # (to the litter)
			_target = _gather_at
			_sniff = 1.0
			_neck_to = Vector2(-0.5, 0.0)
			if Vector2(_pos.x - _gather_at.x, _pos.z - _gather_at.z).length() < 0.06 and _speed < 0.03:
				_target = _pos
				_stage = 1
				_st = 0.0
				if _bundle == null:
					_bundle = Node3D.new()
					_tail[4].add_child(_bundle)
		1: # (a leaf picked up; tucked back under it, to its tail; three times)
			_target = _pos
			var ph := fmod(_st, 2.6)
			if ph < 0.9: # (its head down to the leaves, a mouthful)
				_neck_to = Vector2(-1.05, 0.15 * sin(_st * 3.0))
				_jaw_to = 0.3 if ph < 0.55 else 0.0
				_sniff = 1.0
				if ph > 0.55 and _mouth_leaf == null:
					_mouth_leaf = leaf(int(_st) + 1, true)
					_jaw.add_child(_mouth_leaf)
					_mouth_leaf.position = Vector3(0.0, 2.0, -58.0)
					_mouth_leaf.rotation = Vector3(1.2, 0.0, 0.0)
			elif ph < 2.0: # (its head tucked down under its chest, its forefeet passing it back)
				_neck_to = Vector2(-1.45, 0.0)
				if ph > 1.5 and _mouth_leaf != null:
					_mouth_leaf.queue_free()
					_mouth_leaf = null
					var lf := leaf(_bundle.get_child_count() + 2, true)
					_bundle.add_child(lf)
					var k := _bundle.get_child_count()
					lf.position = Vector3(6.0 * sin(k * 2.0), -10.0 - k * 2.0, 10.0 * cos(k * 1.3))
					lf.rotation = Vector3(0.4 * k, k * 1.1, 0.3)
			_tail_mode = "loop" if _bundle.get_child_count() > 0 else "low"
			if _st > 2.6 * 3.0:
				_stage = 2
				_st = 0.0
		2: # (carried in the loop of its tail, to its den)
			_target = _gather_to
			_tail_mode = "loop"
			if Vector2(_pos.x - _gather_to.x, _pos.z - _gather_to.z).length() < 0.12 or _st > 25.0:
				_target = _pos
				_stage = 3
				_st = 0.0
		3: # (let go: left there)
			_target = _pos
			_neck_to = Vector2(-0.4, 0.0)
			if _st > 0.5 and _bundle != null:
				var gt := _bundle.global_transform
				var parent := get_parent() as Node3D
				_bundle.get_parent().remove_child(_bundle)
				parent.add_child(_bundle)
				var p := parent.global_transform.affine_inverse() * gt.origin
				_bundle.transform = Transform3D(Basis.from_scale(gt.basis.get_scale()), Vector3(p.x, _ground(p.x, p.z) + 0.004, p.z))
				_bundle.set_meta("nest", true)
				get_tree().create_timer(90.0).timeout.connect(_bundle.queue_free)
				_bundle = null
			if _st > 1.5:
				wander(_home_spot(), _radius)


## (Marking: its chin and the side of its neck rubbed along the ground.)
func _mark(_dt: float) -> void:
	_crouch = 0.55
	_neck_to = Vector2(-1.0, 0.35 * sin(_st * 2.2))
	_look_to = Vector2(0.15, 0.0)
	_jaw_to = 0.05


func _birth(_dt: float) -> void:
	# sat up, licking her belly: her young born one by one, up her fur into
	# her pouch
	_target = _pos
	_sit_to = 1.0
	_neck_to = Vector2(-1.25, 0.0)
	_lick = 0.8
	_tail_mode = "wrap"
	if _st > 1.6 and _born_left > 0:
		_born_left -= 1
		_st = 0.0
		_joey()
	if _born_left <= 0 and _st > 3.0:
		_sit_to = 0.0
		wander(_home_spot(), _radius)


func _joey() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var j: Node3D = (get_script() as Script).new(true)
	j.set("size", 0.02)
	j.set("_g_to", 0.02)
	j.set("height", height)
	parent.add_child(j)
	j.set("_mother", self)
	j.set("_carrier", self)
	j.set("_in_pouch", true)
	j.set("_crawl", 0.0)
	j.call("place", _pos, _yaw)
	j.call("grow", POUCH_OUT + 0.002, 22.0)
	j.call("_set_fur", 0.0)
	young_ones.append(j)


func _nurse(_dt: float) -> void:
	_target = _pos
	match _stage:
		0: # (her young off her back, to her belly)
			for y in young_ones:
				if is_instance_valid(y) and y.get("_carrier") == self and not bool(y.get("_in_pouch")):
					y.call("_off")
				if is_instance_valid(y) and y.get("_carrier") == null:
					y.set("_mode", "nursing")
					y.set("_stage", 0)
			_stage = 1
			_st = 0.0
		1: # (down on her side, her young at her belly)
			_lie_to = 1.0
			_side = move_toward(_side, 1.0, _dt * 0.6)
			_neck_to = Vector2(-0.3, 0.5 * sin(_st * 0.2))
			if _st > 20.0:
				for y in young_ones:
					if is_instance_valid(y) and y.get("_carrier") == null:
						y.set("_mode", "follow")
				_lie_to = 0.0
				wander(_home_spot(), _radius)


## (A joey, off her: after her and back on, at play, or at her belly.)
func _helpless(dt: float) -> void:
	_ears_to = 0.3
	_tail_mode = "low"
	var m := _mother
	match _mode:
		"play":
			_play(dt)
		"nursing":
			if is_instance_valid(m):
				var belly: Vector3 = m.call("_out", Vector3(-float(S.body_w) * 0.8, -float(m.get("body_h")), -20.0 + 15.0 * float(young_ones.size())))
				if _pos.distance_to(belly) > 0.03:
					_target = belly
					_pace = 0.15
				else:
					_target = _pos
					_lie_to = 1.0
					_neck_to = Vector2(-0.2, 0.0)
					_jaw_to = 0.1 * maxf(sin(_t * 5.0), 0.0)
				if m.get("_mode") != "nurse":
					_lie_to = 0.0
					_mode = "follow"
			else:
				_mode = "wander"
		"follow":
			if is_instance_valid(m) and not bool(m.get("dead")):
				var mp: Vector3 = m.get("_pos")
				_target = mp
				_pace = 0.22
				if Vector2(_pos.x - mp.x, _pos.z - mp.z).length() < 0.11 and m.get("_mode") not in ["nurse", "play_dead", "climb"] and m.get("_mate_role") == "":
					_board(m)
			else:
				_mode = "wander"
		_:
			if _wait <= 0.0:
				var a := rng.randf() * TAU
				_target = _pos + Vector3(cos(a), 0.0, sin(a)) * 0.12
				_wait = rng.randf_range(2.0, 5.0)
			if is_instance_valid(m):
				_mode = "follow"


## (A joey at play: low, creeping after the other, a wiggle, a pounce, a
## tumble; then after her.)
func _play(dt: float) -> void:
	if not is_instance_valid(_sib):
		_mode = "follow"
		return
	var p: Vector3 = _sib.get("_pos")
	var to := p - _pos
	to.y = 0.0
	match _stage:
		0:
			_crouch = move_toward(_crouch, 0.4, dt * 2.0)
			_target = p - to.normalized() * 0.05
			_pace = 0.08
			if to.length() < 0.07 or _st > 6.0:
				_stage = 1
				_st = 0.0
		1:
			_target = _pos
			_wiggle = 1.0
			if _st > 0.7 and not airborne:
				_crouch = 0.0
				_leap(p, 0.7)
				_stage = 2
				_st = 0.0
		2:
			if not airborne:
				_roll = lerpf(_roll, PI * 0.6 * sin(_st * 4.0), 1.0 - exp(-6.0 * dt)) if _st < 1.5 else lerpf(_roll, 0.0, 1.0 - exp(-6.0 * dt))
				_target = _pos
				if _st > 2.2:
					_roll = 0.0
					_pace = -1.0
					if _st > 2.2 and rng.randf() < 0.5 and _sib.get("_carrier") == null:
						_stage = 0 # (again)
						_st = 0.0
					else:
						_mode = "follow"


# --- a joey carried ----------------------------------------------------------------

## (On.)
func _board(m: Node3D) -> void:
	_carrier = m
	_in_pouch = false
	_board_t = 0.0
	_board_from = transform
	_mode = "ride"
	_slot = maxi((m.get("young_ones") as Array).find(self), 0)


## (Off her, onto the ground where it is.)
func _off() -> void:
	var o := transform.origin
	_carrier = null
	_in_pouch = false
	visible = true
	process_priority = 0
	_pos = Vector3(o.x, _ground(o.x, o.z), o.z)
	ground_y = _pos.y
	var f := -transform.basis.z
	f.y = 0.0
	_yaw = atan2(-f.x, -f.z) if f.length() > 0.01 else _yaw
	_pitch = 0.0
	_roll = 0.0
	_target = _pos
	_speed = 0.0
	_mode = "follow"
	_place()
	for i in 4:
		_feet[i] = _home(i)
		_pose_foot[i] = null


func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	if _carrier != null:
		_ride(dt)
		return
	if _on_branch:
		_t += dt
		size = move_toward(size, _g_to, _g_rate * dt)
		_think(dt)
		if _on_branch:
			_branch_pose(dt)
		return
	super(dt)


## Carried: a newborn crawling up her belly to her pouch; in it, out of
## sight, growing; out, clinging to her back, its feet gripping her fur.
func _ride(dt: float) -> void:
	_t += dt
	size = move_toward(size, _g_to, _g_rate * dt)
	var m := _carrier
	if not is_instance_valid(m) or bool(m.get("dead")):
		_off()
		return
	process_priority = m.process_priority + 1 # (after her: where she is now)
	var ms := maxf(float(m.get("size")), 0.01)
	var mb: Basis = m.transform.basis.orthonormalized()
	var r_mm := size / ms # (its mm, in hers)
	var mp: Vector3 = m.get("_pos")
	if _in_pouch:
		var pouch: Vector3 = m.call("_out", Vector3(0.0, _body_key(20.0).x - _body_key(20.0).z * 0.9, 20.0))
		if _crawl >= 0.0: # (newborn: up her fur from her vent to the pouch, wriggling)
			_crawl += dt
			var u := clampf(_crawl / 2.2, 0.0, 1.0)
			var from: Vector3 = m.call("_out", Vector3(0.0, _body_key(165.0).x - _body_key(165.0).z * 0.6, 168.0))
			var at := from.lerp(pouch, u) + (mb * Vector3(sin(_t * 9.0) * 0.003, 0.0, 0.0))
			transform = Transform3D(mb * Basis(Vector3.RIGHT, -0.3) * Basis(Vector3.UP, 0.4 * sin(_t * 9.0)), at)
			visible = true
			if u >= 1.0:
				_crawl = -1.0
		else:
			visible = false
			transform = Transform3D(mb, pouch)
		_body.scale = Vector3.ONE * MM * size
		_pos = Vector3(transform.origin.x, mp.y, transform.origin.z)
		if visible:
			_tail_mode = "low"
			_neck_to = Vector2(0.3 * sin(_t * 7.0), 0.0)
			_pose(dt)
			for i in 4:
				var dg: Vector3 = legs[i / 2].dangle
				_pose_foot[i] = Vector3(dg.x * (1.0 if i % 2 == 1 else -1.0), dg.y + 20.0 * sin(_t * 9.0 + i), dg.z)
			_pose_legs()
		if size >= POUCH_OUT and _crawl < 0.0: # (out, and up onto her back)
			_in_pouch = false
			visible = true
			_set_fur(1.0)
			_board_t = 0.0
			_board_from = transform
			_slot = maxi((m.get("young_ones") as Array).find(self), 0)
			grow(RIDE_SIZE, 200.0)
			_mode = "ride"
		return
	# on her back: in rows, rump to shoulders, side by side
	var row := _slot / 2
	var zs := 92.0 - float(row % 4) * 48.0
	var xs := (-1.0 if _slot % 2 == 0 else 1.0) * (20.0 + 4.0 * float(row / 4))
	var bk := _body_key(zs)
	var top := bk.x + bk.z
	var at := Vector3(xs, top + 64.0 * r_mm + 8.0 * float(row / 4), zs)
	var bb := (mb * Basis(Vector3.UP, 0.3 * sin(float(_slot) * 2.3)) * Basis(Vector3.RIGHT, -0.12)).orthonormalized()
	var want := Transform3D(bb, m.call("_out", at))
	if _board_t < 1.0:
		_board_t = minf(_board_t + dt / 1.2, 1.0)
		var e := smoothstep(0.0, 1.0, _board_t)
		transform = _board_from.interpolate_with(want, e)
		transform.origin += Vector3.UP * sin(PI * e) * 0.02
	else:
		transform = want
	_body.scale = Vector3.ONE * MM * size
	_pos = Vector3(transform.origin.x, mp.y, transform.origin.z)
	var f := -transform.basis.z
	_yaw = atan2(-f.x, -f.z)
	_sit_to = 0.0
	_lie_to = 0.0
	_crouch = 0.0
	_speed = 0.0
	_mode = "ride"
	if rng.randf() < dt * 0.5:
		_look_to = Vector2(rng.randf_range(-0.2, 0.35), rng.randf_range(-0.8, 0.8))
	_neck_to = Vector2(0.1, 0.0)
	_ears_to = 0.3
	_tail_mode = "low"
	_pose(dt)
	# its feet gripping her fur either side of it, fore and hind
	var inv := (transform * _body.transform).affine_inverse()
	for i in 4:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = L.home
		var fz := zs + hm.y * r_mm
		var fk := _body_key(fz)
		var gx := xs + side * hm.x * r_mm * 1.5
		var gy := fk.x + fk.z * sqrt(maxf(1.0 - pow(gx / maxf(fk.y, 1.0), 2.0), 0.0)) - 6.0 * r_mm
		_pose_foot[i] = inv * (m.call("_out", Vector3(gx, gy, fz)) as Vector3)
	_pose_legs()


# --- on a branch ------------------------------------------------------------------

## On its branch: its body along it (up or down it, or turning), its feet
## gripping round it, stepping by diagonals; its tail coiled round it.
func _branch_pose(dt: float) -> void:
	var a: Vector3 = _branch[0]
	var b: Vector3 = _branch[1]
	var r: float = _branch[2]
	var L := a.distance_to(b)
	var d := (b - a) / L
	var upv := (Vector3.UP - d * d.y).normalized()
	var fwd := d if _going_up else -d
	var z := -fwd
	var x := upv.cross(z).normalized()
	var bas := Basis(x, upv, z)
	if _turn != 0.0:
		bas = Basis(upv, _turn) * bas
	var clear := 70.0 * MM * size
	var c := a + d * (_cu * L) + upv * (r + clear)
	var want := Transform3D(bas, c)
	if _board_t < 1.0:
		_board_t = minf(_board_t + dt / 0.7, 1.0)
		transform = _board_from.interpolate_with(want, smoothstep(0.0, 1.0, _board_t))
	else:
		transform = want
	_body.scale = Vector3.ONE * MM * size
	_pos = Vector3(c.x, _ground(c.x, c.z), c.z)
	_sit_to = 0.0
	_lie_to = 0.0
	_pose(dt)
	var moving := _stage == 2 or _stage == 5 or _stage == 4
	var mm := MM * size
	var axis_y := -(r + clear) / mm
	var R := r / mm
	for i in 4:
		var Lg: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = Lg.home
		var q := fmod(_cph + (0.0 if i == 0 or i == 3 else 0.5), 1.0)
		var dz := 0.0
		var lift := 0.0
		if moving:
			const DUTY := 0.65
			const STRIDE := 46.0
			if q < DUTY:
				dz = lerpf(-STRIDE * 0.5, STRIDE * 0.5, q / DUTY)
			else:
				var s := (q - DUTY) / (1.0 - DUTY)
				dz = lerpf(STRIDE * 0.5, -STRIDE * 0.5, s * s * (3.0 - 2.0 * s))
				lift = sin(PI * s) * 14.0
		# (round its side, a little above its middle: the branch's surface)
		var ang := 0.75 if i < 2 else 0.95
		var foot := Vector3(side * R * sin(ang), axis_y + R * cos(ang) + lift, hm.y + dz)
		if _turn != 0.0: # (turning: the branch runs across it now)
			var lt := (Basis(Vector3.UP, -_turn)) * Vector3(0.0, 0.0, hm.y + dz)
			foot = Vector3(lt.x + side * R * sin(ang) * cos(_turn), axis_y + R * cos(ang) + lift, lt.z * 0.4 + hm.y * 0.6)
		_pose_foot[i] = foot
	_pose_legs()


# --- the pose ---------------------------------------------------------------------

func _pose(dt: float) -> void:
	super(dt)
	var open := _jaw.rotation.x < -0.12
	for t in _teeth:
		t.visible = open
	if _tongue:
		_tongue.visible = _mode == "play_dead" and _stage == 0
		var dr := (_mode == "play_dead" and _stage == 0) or _mode == "gape" or (_mode == "mark" and not young)
		for d in _drool:
			d.visible = dr
	if _mode == "play_dead" and _lie > 0.3 and _stage == 0:
		# (stiff: its legs held out from it)
		for i in 4:
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hp: Vector3 = L.hip
			var f: float = float(L.f) + float(L.t)
			_pose_foot[i] = Vector3(hp.x * side + side * f * 0.55, hp.y - f * 0.75, hp.z + (-25.0 if i < 2 else 30.0))
	if _mode == "gather" and _pose_foot.size() >= 2: # (its forefeet back under its chest, passing the leaves back)
		for i in 2:
			var side := 1.0 if i % 2 == 1 else -1.0
			var hm: Vector2 = legs[0].home
			var home := _ground_at(Vector3(hm.x * side, 0.0, hm.y))
			var tuck := Vector3(side * 18.0, -float(body_h) * 0.55, -40.0)
			_pose_foot[i] = home.lerp(tuck, _tuck)
		if _tuck < 0.02:
			for i in 2:
				_pose_foot[i] = null


func _pose_tail(dt: float) -> void:
	if _tail_mode not in ["coil", "loop", "limp"]:
		super(dt)
		return
	for k in _tail.size():
		var down := 0.0
		var roll_r := 0.0
		match _tail_mode:
			"coil": # (wrapped round the branch: down, under it, and up round it)
				down = 0.3 if k == 0 else (0.12 if k < 3 else 0.62)
				roll_r = 0.06 * k
			"loop": # (curled down and forward under it, the leaves held in its loop)
				down = 1.0 if k == 0 else (0.55 if k < 6 else 0.4)
			"limp": # (lying: limp, a loose curve)
				down = 0.2
				roll_r = 0.18
		var now: Array = _tail_k[k]
		var ak := lerpf(float(now[0]), down, 1.0 - exp(-4.0 * dt))
		var rk := lerpf(float(now[1]), roll_r, 1.0 - exp(-4.0 * dt))
		_tail_k[k] = [ak, rk]
		_tail[k].rotation = Vector3(ak, rk, 0.0)


# --- its attack: an amble up to it, a lunge ----------------------------------------

func _attack(_dt: float, p: Vector3, d: float) -> bool:
	if d > float(S.spring) * size / 0.5 * 0.9:
		_target = p
		_pace = float(S.trot) * 0.8
		return false
	_pace = -1.0
	_spring_at(p, 0.2)
	return true


# --- mating ------------------------------------------------------------------------

func _court_secs() -> float:
	return 6.0


func _mount() -> Dictionary:
	# on her from behind, his teeth in the fur of her neck; his forefeet
	# clasping her sides, his hind feet gripping her hind legs
	_neck_to = Vector2(-0.95, 0.0)
	_jaw_to = 0.3
	return {"at": Vector3(0.0, 92.0, 118.0), "basis": Basis(Vector3.RIGHT, 0.12), "thrust": false, "grips": {
		0: Vector3(-62.0, -10.0, -30.0), 1: Vector3(62.0, -10.0, -30.0), 2: Vector3(-52.0, -70.0, 120.0), 3: Vector3(52.0, -70.0, 120.0)}}


func _mating(dt: float) -> void:
	super(dt)
	if _mate_role == "male" and _mate_stage == "court": # (clicking at her)
		_jaw_to = 0.1 * maxf(sin(_t * 28.0), 0.0)
		_neck_to = Vector2(-0.3, 0.0)
	if _mate_role == "female":
		if _mate_stage == "joined":
			_together += dt
			if _together > 2.5: # (the two toppled over together, onto their sides)
				_lie_to = 1.0
				_side = move_toward(_side, 1.0, dt * 0.8)
		else:
			_together = 0.0


func mate(partner: Node3D, secs := -1.0) -> bool:
	if _carrier != null or _on_branch or (partner != null and (partner.get("_on_branch") == true or partner.get("_carrier") != null)):
		return false
	return super(partner, secs)


func _on_mate_start() -> void:
	# (whatever it was at, left off: playing dead, gaping, gathering)
	if _mode in ["play_dead", "gape", "gather", "birth", "nurse", "sleep"]:
		_mode = "idle"
		_stage = 0
	_lie_to = 0.0
	_curl = 0.0


func _after_mate() -> void:
	_together = 0.0
	super()


# --- steering (pilot.gd) ---------------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["play_dead", "gape"]))
	if not young:
		b.append_array(PackedStringArray(["climb", "gather"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"play_dead":
			play_dead(float(args.get("seconds", 18.0)))
		"gape":
			gape(float(args.get("seconds", 6.0)))
		"climb":
			if not (args.get("foot") is Vector3) or not (args.get("top") is Vector3):
				return false
			climb(args.foot, args.top, float(args.get("radius", 0.035)))
		"gather":
			if not (args.get("from") is Vector3) or not (args.get("to") is Vector3):
				return false
			gather(args.from, args.to)
		_:
			return super(name, args)
	return true


func _p_act_done(name: String) -> bool:
	if name in ["play_dead", "gape", "climb", "gather"]:
		return _mode != name
	return super(name)


func _p_mobile() -> bool:
	return _carrier == null and not _on_branch and not (young and size < 0.05)
