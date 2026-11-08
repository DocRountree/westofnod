class_name Mouse
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A deer mouse (Peromyscus maniculatus), North America's field mouse, life
## size (its model in mm, size 0.5 of the walker's doubled scale: an adult
## about 85 mm long, its tail as long again): brown above, grizzled, darker
## along the spine, white beneath, the line between sharp; white feet; big
## black eyes; big rounded ears, nearly bare, pink inside; a pink nose, long
## whiskers, orange incisors; the tail sharply two-coloured, dark above,
## white below (carnivore.gdshader's species 9, on one skin: MammalSkin). Four legs (hexapod.gd's
## motor: its gait a trot, the diagonals together), the forelegs' elbows
## back, the hind legs' knees forward and their long feet flat, heel to
## toe. Young (Mouse.new(true)): born pink and hairless, eyes shut, ears
## folded flat, helpless; lying and wriggling where they're born, growing
## (grow): their fur coming in (grey: a juvenile's), eyes open, up and
## about once they're big enough; brown as they grow up.
## Not yet in the game (tools/creatures/ecology_demo.tscn).
##
## - wander(centre, radius): scurrying about, stopping, sniffing (the nose
##   and whiskers going, the ears turning), now and then sitting up to look
## - eat(seed) (a Node3D: Mouse.sunflower_seed()): to it, picks it up and sits up on
##   its haunches, turning it in its forepaws at its mouth, nibbling (the
##   seed going); then down again
## - groom(): sitting up, washing its face with its forepaws
## - sleep(secs): into its nest (home_nest, if it has one; else where it
##   is), curled up tight, its head tucked round to its flank, its tail
##   round it, its eyes shut, its sides rising and falling
## - birth(n, nest) (a female's; nest: Mouse.nest(), or none: where she
##   is): into her nest, settled, and n pups born one after another, each
##   licked clean; then she nurses them, lying over them (pups)
## - mate(her) (a male's: male set; no different to see): he follows her,
##   nose to her, then mounts her from behind, his forepaws clasping her
##   flanks, his hind feet on the ground, thrusting in bouts; then off, and
##   he washes himself. Then she's carrying (her belly swelling: birth())
## Steering (pilot.gd): act eat {seed, seconds}, groom {seconds}, birth {n,
## nest} (a female's), mate {partner}.

const FORE := {"hip": Vector3(5.5, -4.0, -21.0), "f": 9.0, "t": 10.0, "s": 5.0, "home": Vector2(7.5, -27.0), "dangle": Vector3(5.0, -9.0, -27.0), "pole": Vector3(0.15, 0.0, 1.0), "r": 1.5, "femur_r": 1.7}
const HIND := {"hip": Vector3(8.0, -2.0, 21.0), "f": 13.0, "t": 15.0, "s": 17.0, "home": Vector2(9.5, 13.0), "dangle": Vector3(8.0, -8.0, 24.0), "pole": Vector3(0.25, 0.1, -1.0), "r": 1.9, "femur_r": 1.8}
const TAIL_N := 14
const TAIL_SEG := 5.6 # mm

var young := false
var pups: Array[Node3D] = [] ## her young, born
var home_nest: Node3D ## her nest (Mouse.nest()), if she has one
var _asleep := 0.0 # (0 awake .. 1 asleep: its eyes shut)
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.2
var _wait := 0.0
var _st := 0.0
var _stage := 0
var _seed: Node3D
var _meal: Node3D # (its seed, nibbled away bit by bit where it lies: Meal)
var _bite_look := -0.5 # (its head's pitch, eating: to the next bite)
const MealScript := preload("res://scripts/creatures/meal.gd")
var _seed_size := Vector3.ONE
var _sit := 0.0 # 0 on all fours .. 1 sitting up on its haunches
var _sit_to := 0.0
var _chew := 0.0
var _sniff := 1.0
var _groom := 0.0
var _lick := 0.0
var _look := Vector2.ZERO # (the head turned: yaw, pitch)
var _look_to := Vector2.ZERO
var _gravid := 0.0 # 0 .. 1: her belly with young
var _born_left := 0
var _litter: Array[Node3D] = []
var _thrust := 0.0
# the parts
var _head: Node3D
var _jaw: Node3D
var _ears: Array[Node3D] = []
var _whiskers: Array[Node3D] = []
var _eyes: Array[MeshInstance3D] = []
var _lids: Array[MeshInstance3D] = []
var _tail: Array[Node3D] = []
var _torso: MeshInstance3D
var _fur_mat: ShaderMaterial
var _tail_mat: ShaderMaterial
var _paw_mat: StandardMaterial3D
var _fur_set := -1.0
var _toes: Array[Node3D] = []


func _init(young_ := false) -> void:
	young = young_
	super(young_, 0.15 if young_ else 0.5)
	legs = [FORE, HIND]
	tripod = [[0, 3], [1, 2]] # (a trot: the diagonals together)
	body_h = 14.0
	walk_speed = 0.2
	stride = 26.0
	step_time = 0.09
	mate_secs = 14.0


func _build() -> void:
	var shader: Shader = preload("res://shaders/render/carnivore.gdshader") # (the mammals' coats: its species 9)
	_fur_mat = ShaderMaterial.new()
	_fur_mat.shader = shader
	_fur_mat.set_shader_parameter("species", 9)
	_fur_mat.set_shader_parameter("hair", 3.0)
	_tail_mat = _fur_mat.duplicate() as ShaderMaterial
	_tail_mat.set_shader_parameter("part", 6)
	_paw_mat = _mat(Color(0.93, 0.9, 0.86), 0.7)
	var pink := _mat(Color(0.9, 0.62, 0.6), 0.45)
	# the body: the neck, the shoulders, the round of the belly, the
	# haunches, the rump
	# its body and head: one skin (_build_skin)
	_head = Node3D.new()
	_head.position = Vector3(0.0, 5.5, -30.0)
	_body.add_child(_head)
	var head_keys := HEAD_KEYS
	for side: float in [-1.0, 1.0]: # (its whisker pads, plump either side of its nose)
		_part(Vector3(2.8 * side, -2.0, -20.5), Vector3(4.4, 3.8, 5.2), _fur_mat, _head)
	# the eyes: big, black, bulging, glossy (a pup's shut: lids of skin over them)
	var eye := _mat(Color(0.02, 0.015, 0.015), 0.02)
	eye.clearcoat_enabled = true # (wet, glossy, bulging)
	eye.clearcoat = 1.0
	# (each set on the head's surface, big, bulging well out of it; the fur
	# bare round it)
	var ex := _surface_x(head_keys, -11.0, 3.4) + 0.3
	_fur_mat.set_shader_parameter("bare_a", Vector3(-ex, 3.4, -11.0))
	_fur_mat.set_shader_parameter("bare_b", Vector3(ex, 3.4, -11.0))
	_fur_mat.set_shader_parameter("bare_r", 3.2)
	for side: float in [-1.0, 1.0]:
		_eyes.append(_part(Vector3(ex * side, 3.4, -11.0), Vector3(3.8, 4.2, 4.6), eye, _head))
		var lid := _part(Vector3((ex - 0.2) * side, 3.4, -11.0), Vector3(4.1, 4.5, 4.9), _fur_mat, _head)
		_lids.append(lid)
	# the ears: big, round, thin, nearly bare: furred outside, pink in
	for side: float in [-1.0, 1.0]:
		var ear := Node3D.new()
		ear.position = Vector3(5.5 * side, 8.0, -4.0)
		_head.add_child(ear)
		ear.set_meta("side", side)
		# (thin, nearly bare, grey brown outside, its rim paler; within pink,
		# the light through it)
		var outer := _mat(Color(0.42, 0.36, 0.33), 0.6, 0.2)
		outer.backlight_enabled = true
		outer.backlight = Color(0.5, 0.3, 0.28)
		_part(Vector3(1.5 * side, 4.8, 0.3), Vector3(9.5, 11.0, 1.0), outer, ear)
		_part(Vector3(1.5 * side, 4.8, 0.3), Vector3(10.2, 11.7, 0.7), _mat(Color(0.7, 0.64, 0.6), 0.7), ear) # (its rim)
		var inner := _mat(Color(0.86, 0.62, 0.6), 0.45)
		inner.backlight_enabled = true
		inner.backlight = Color(0.7, 0.35, 0.32)
		_part(Vector3(1.4 * side, 4.6, -0.3), Vector3(7.5, 8.8, 0.5), inner, ear)
		_ears.append(ear)
	# the nose, the whiskers fanned from the muzzle, the incisors, the jaw
	var nose := _mat(Color(0.82, 0.5, 0.5), 0.2)
	nose.clearcoat_enabled = true
	nose.clearcoat = 0.8
	_part(Vector3(0.0, -1.7, -25.2), Vector3(2.8, 2.2, 2.0), nose, _head)
	for side: float in [-1.0, 1.0]: # (its nostrils)
		_part(Vector3(0.6 * side, -1.6, -26.0), Vector3(0.6, 0.5, 0.4), _mat(Color(0.3, 0.12, 0.12), 0.6), _head)
	var wh := _mat(Color(0.85, 0.83, 0.8), 0.5)
	var dk := _mat(Color(0.12, 0.1, 0.09), 0.5)
	for side: float in [-1.0, 1.0]:
		var w := Node3D.new()
		w.position = Vector3(2.8 * side, -2.4, -21.5)
		_head.add_child(w)
		w.set_meta("side", side)
		for k in 6:
			var a := deg_to_rad(-25.0 + 12.0 * k)
			var l := 16.0 + 4.0 * sin(k * 1.7)
			var d := Vector3(side * cos(a) * 0.85, sin(a) * 0.6 - 0.05, 0.35 + 0.15 * k * 0.2).normalized()
			_stick(Vector3.ZERO, d * l, 0.09, dk if k % 2 == 0 else wh, w)
		_whiskers.append(w)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0.0, -5.0, -16.0)
	_head.add_child(_jaw)
	var tooth := _mat(Color(0.86, 0.55, 0.22), 0.3)
	_stick(Vector3(0.0, -3.0, -23.2), Vector3(0.0, -5.0, -22.6), 0.45, tooth, _head)
	_stick(Vector3(0.0, -0.5, -7.2), Vector3(0.0, 1.2, -7.6), 0.4, tooth, _jaw)
	# the tail: two-coloured, scaly, tapering, in a chain from the rump
	var prev: Node3D = _body
	for k in TAIL_N:
		var n := Node3D.new()
		n.position = Vector3(0.0, -0.5, 38.0) if k == 0 else Vector3(0.0, 0.0, TAIL_SEG)
		prev.add_child(n)
		_tail.append(n)
		prev = n
	_build_legs(_fur_mat, _fur_mat)
	for i in 4: # (the skin's legs: these carry nothing)
		for q in 4:
			(_leg_mesh[i][q] as MeshInstance3D).mesh = null
	_joints.resize(4)
	_build_skin()
	# its feet's toes: long, pink, thin (four before, five behind), each its
	# little claw
	for i in 4:
		var t := Node3D.new()
		_body.add_child(t)
		var hind := i >= 2
		for k in (5 if hind else 4):
			var a := deg_to_rad(-40.0 + (80.0 / (4.0 if hind else 3.0)) * k)
			var l := (5.5 if hind else 3.6) * (0.75 + 0.25 * sin(PI * float(k) / (4.0 if hind else 3.0)))
			var d := Vector3(sin(a), 0.0, -cos(a))
			_stick(Vector3.ZERO, d * l, 0.45, _paw_mat, t)
			_stick(d * l, d * (l + 0.8) + Vector3(0.0, -0.3, 0.0), 0.15, _mat(Color(0.85, 0.82, 0.75), 0.4), t)
		_toes.append(t)
	_grow_fur(true)


const HEAD_KEYS := [[3.0, 0.0, 5.5, 5.5], [-3.0, 1.2, 9.5, 9.0], [-9.0, 1.0, 9.0, 8.0], [-15.0, -0.2, 6.8, 6.2], [-20.0, -1.2, 4.6, 4.4],
		[-23.5, -1.8, 2.8, 2.7], [-25.0, -2.0, 1.2, 1.2]]
const BODY_KEYS := [[-34.0, 3.5, 4.5, 4.5], [-28.0, 3.5, 8.5, 8.5], [-18.0, 3.0, 11.0, 10.5], [-4.0, 3.5, 13.0, 11.5],
		[12.0, 4.0, 14.0, 12.0], [24.0, 4.0, 13.5, 11.5], [33.0, 3.0, 10.0, 9.0], [38.5, 2.0, 5.0, 5.0], [40.0, 1.5, 1.2, 1.2]]
const SkinScript := preload("res://scripts/creatures/mammal_skin.gd")
var _skin: SkinScript
var _skin_mat: ShaderMaterial
var _sb := {}
var _joints: Array = []


## Its skin: the body into the head, the jaw, the tail, each leg (standing).
func _build_skin() -> void:
	var K: SkinScript = SkinScript.new()
	var torso := K.bone("torso", Transform3D())
	var hrest := _head.transform
	var head := K.bone("head", hrest)
	var jrest := hrest * _jaw.transform
	var jaw := K.bone("jaw", jrest)
	_sb = {"head": head, "jaw": jaw}
	K.body_head(torso, BODY_KEYS, head, hrest, HEAD_KEYS, 2.0)
	K.jaw_tube(head, jaw, jrest, [[0.0, -0.5, 2.6, 1.4], [-3.5, -0.5, 2.3, 1.3], [-7.5, -0.4, 1.4, 0.9]])
	var tb := []
	var trest := []
	var prev := Transform3D()
	var radii := []
	for k in TAIL_N:
		prev = prev * _tail[k].transform
		trest.append(prev)
		tb.append(K.bone("tail%d" % k, prev))
		radii.append(lerpf(2.3, 0.8, float(k) / (TAIL_N - 1)))
	_sb["tail"] = tb
	K.tail_chain(torso, tb, trest, radii, TAIL_SEG, 1.0, 10)
	for i in 4:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = L.home
		var J := _leg3(i, Vector3(hm.x * side, -body_h, hm.y), Vector3.UP, Vector3.FORWARD, false)
		var bones := []
		for q in 3:
			bones.append(K.bone("leg%d_%d" % [i, q], SkinScript.along(J[q], J[q + 1])))
		_sb["leg%d" % i] = bones
		K.leg3(torso, bones, J, float(L.r), i >= 2, 1.4 if i >= 2 else 1.2)
	_skin = K
	_skin_mat = _fur_mat.duplicate() as ShaderMaterial
	_skin_mat.set_shader_parameter("skin", true)
	_torso = K.finish(_body, _skin_mat)


## Leg i's joints, its foot at foot: [hip, knee, heel, toe].
func _leg3(i: int, foot: Vector3, up: Vector3, fwd: Vector3, held: bool) -> Array:
	var L: Dictionary = legs[i / 2]
	var hind := i >= 2
	var side := 1.0 if i % 2 == 1 else -1.0
	var hp: Vector3 = L.hip
	var hip := Vector3(hp.x * side, hp.y, hp.z)
	var s: float = L.s
	var heel: Vector3
	if hind:
		heel = foot + (-fwd * 0.95 + up * 0.3).normalized() * s
	elif held: # (a paw held up: the wrist under it)
		heel = foot + Vector3(0.0, -0.6, 0.4).normalized() * s
	else:
		heel = foot + (-fwd * 0.3 + up * 0.95).normalized() * s
	var pl: Vector3 = L.pole
	var knee := _knee(hip, heel, L.f, L.t, Vector3(pl.x * side, pl.y, pl.z))
	return [hip, knee, heel, foot]


func _skin_pose() -> void:
	if _skin == null:
		return
	_skin.pose(_sb.head, _head.transform)
	_skin.pose(_sb.jaw, _head.transform * _jaw.transform)
	var prev := Transform3D()
	var tb: Array = _sb.tail
	for k in _tail.size():
		prev = prev * _tail[k].transform
		_skin.pose(tb[k], prev)
	for i in 4:
		if _joints[i] != null:
			_skin.pose_leg3(_sb["leg%d" % i], _joints[i])


## (No shells: its coat is painted, carnivore.gdshader's species 9.)
func _fur_shells(_mi: MeshInstance3D, _len_mm: float, _shells := 8, _spacing := -1.0) -> void:
	pass


## The fur as it grows in (a pup's): its share by size, grey then brown;
## the eyes open, the ears up.
func _grow_fur(force := false) -> void:
	var g := clampf((size - 0.16) / 0.12, 0.0, 1.0) if young else 1.0
	var adult := clampf((size - 0.38) / 0.1, 0.0, 1.0) if young else 1.0
	var k := g + adult * 2.0
	if not force and absf(k - _fur_set) < 0.01:
		return
	_fur_set = k
	var grey := Color(0.4, 0.4, 0.42)
	var brown := Color(0.46, 0.33, 0.21)
	for m: ShaderMaterial in [_fur_mat, _tail_mat, _skin_mat]:
		if m:
			m.set_shader_parameter("fur", g)
			m.set_shader_parameter("mouse_back", grey.lerp(brown, adult))
	_paw_mat.albedo_color = Color(0.9, 0.62, 0.58).lerp(Color(0.93, 0.9, 0.86), g)
	var open := not young or size > 0.27
	for l in _lids:
		l.visible = not open
	for e in _eyes:
		e.visible = open
	for ear in _ears:
		ear.scale = Vector3.ONE * lerpf(0.35, 1.0, g)


## A seed, for it to eat (life size: about 9 mm, a sunflower's, striped
## grey); its origin under it.
static func sunflower_seed() -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 6
	mi.mesh = s
	mi.scale = Vector3(0.0045, 0.0032, 0.009)
	mi.position.y = 0.0016
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.36, 0.34, 0.3)
	m.roughness = 0.6
	mi.material_override = m
	root.add_child(mi)
	var stripe := MeshInstance3D.new()
	stripe.mesh = s
	stripe.scale = Vector3(0.0012, 0.0034, 0.0085)
	stripe.position.y = 0.0016
	var w := StandardMaterial3D.new()
	w.albedo_color = Color(0.78, 0.76, 0.7)
	stripe.material_override = w
	root.add_child(stripe)
	return root


## A deer mouse's nest: a ball of dry grass and shredded stems about 10 cm
## across, hollow, its way in at one side (-z), lined; its origin at its
## middle on the ground.
static func nest() -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var blade := BoxMesh.new()
	blade.size = Vector3(0.0012, 0.0004, 0.03)
	mm.mesh = blade
	const N := 420
	mm.instance_count = N
	var R := 0.05
	for i in N:
		# (a point on the ball, not where the way in is)
		var p := Vector3.ZERO
		for tries in 8:
			p = Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1), rng.randf_range(-1, 1)).normalized()
			if not (p.z < -0.7 and p.y < 0.55):
				break
		var r := R * rng.randf_range(0.82, 1.08)
		var at := Vector3(p.x * r, maxf(p.y * r * 0.85, 0.0) + R * 0.08, p.z * r)
		# (lying round the ball, along it, every way)
		var t := p.cross(Vector3.UP if absf(p.y) < 0.9 else Vector3.RIGHT).normalized().rotated(p, rng.randf() * TAU)
		var b := Basis(t.cross(p).normalized(), p, t)
		mm.set_instance_transform(i, Transform3D(b.orthonormalized() * Basis.from_scale(Vector3(1.0, 1.0, rng.randf_range(0.6, 1.4))), at))
		mm.set_instance_color(i, Color(0.72, 0.62, 0.4).darkened(rng.randf_range(0.0, 0.3)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mmi.material_override = m
	root.add_child(mmi)
	# its lining, a floor of finer stuff
	var floor_ := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = R * 0.85
	c.bottom_radius = R * 0.9
	c.height = 0.006
	floor_.mesh = c
	floor_.position.y = 0.003
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.8, 0.74, 0.6)
	lm.roughness = 1.0
	floor_.material_override = lm
	root.add_child(floor_)
	return root


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_sit_to = 0.0


func eat(s: Node3D) -> void:
	if s == null or not is_instance_valid(s):
		return
	_mode = "eat"
	_seed = s
	_meal = null
	_seed_size = s.scale
	_stage = 0
	_st = 0.0


## Into its nest (or where it is), curled up asleep, secs.
func sleep(secs := 20.0) -> void:
	_mode = "sleep"
	_stage = 0
	_st = 0.0
	_wait = secs


func groom() -> void:
	_mode = "groom"
	_st = 0.0
	_target = _pos


## (A female's.) Her young born: into her nest (if she has one), n pups.
func birth(n := 4, nest_: Node3D = null) -> void:
	if young or male:
		return
	if nest_ != null:
		home_nest = nest_
	_born_left = n
	_mode = "birth"
	_stage = 0
	_st = 0.0
	_gravid = maxf(_gravid, 1.0)


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 3.0)
	_groom = move_toward(_groom, 0.0, dt * 3.0)
	_lick = move_toward(_lick, 0.0, dt * 2.0)
	_sniff = 1.0
	if young and size < 0.25:
		_helpless(dt)
		return
	match _mode:
		"wander":
			if _wait <= 0.0:
				var r := rng.randf()
				if r < 0.25: # (a stop, sniffing, looking about)
					_target = _pos
					_look_to = Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.3, 0.3))
					_wait = rng.randf_range(0.8, 2.5)
				elif r < 0.33: # (up on its haunches to look)
					_target = _pos
					_sit_to = 0.75
					_look_to = Vector2(rng.randf_range(-0.6, 0.6), 0.2)
					_wait = rng.randf_range(1.2, 2.5)
				else:
					var a := rng.randf() * TAU
					_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
					_look_to = Vector2.ZERO
					_sit_to = 0.0
					_wait = rng.randf_range(1.0, 3.5)
			if _speed > 0.01:
				_sit_to = 0.0
		"eat":
			if not is_instance_valid(_seed):
				_sit_to = 0.0
				wander(_pos, 0.15)
				return
			match _stage:
				0: # to it, its nose to it
					_sit_to = 0.0
					var to := _seed.position - _pos
					to.y = 0.0
					var reach := 34.0 * MM * size
					_target = _seed.position - to.normalized() * reach if to.length() > reach * 1.05 else _pos
					_look_to = Vector2(0.0, -0.4)
					if to.length() <= reach * 1.15 and _speed < 0.01:
						_turn_to = atan2(-to.x, -to.z)
						MealScript.subdue(_seed) # (an insect, a grub: bitten, still)
						_stage = 1
						_st = 0.0
				1: # its head down to it
					_look_to = Vector2(0.0, -0.5)
					_bite_look = -0.5
					if _st > 0.4:
						_stage = 2
						_st = 0.0
				2: # nibbling it away where it lies, its mouth on the next bit (not picked up)
					_target = _pos
					_sit_to = 0.0
					_chew = 1.0
					var keep := MealScript.kept(_seed) # (a mushroom: nibbled at, never used up)
					if _meal == null and not keep:
						_meal = MealScript.of(_seed, 1) # (a seed, an insect: one bite, gone)
					var m := _body.global_transform * (_head.transform * Vector3(0.0, -6.5, -19.5))
					var na: Vector3 = _meal.call("next_at") if _meal else (MealScript.bite_at(_seed) if keep else _seed.global_position)
					_bite_look = clampf(_bite_look + clampf((na.y - m.y) * 60.0, -1.5, 1.5) * dt, -1.2, 0.3)
					_look_to = Vector2(0.12 * sin(_st * 0.9), _bite_look)
					var off := Vector3(na.x - m.x, 0.0, na.z - m.z)
					if off.length() > 0.0015:
						_pos += off.limit_length(0.03 * size * dt)
						_target = _pos
					if _meal:
						_meal.call("tear", 1.0, m)
					if _st > 9.0 or (_meal and float(_meal.call("left")) <= 0.0 and _st > 3.0) or (keep and _st > 6.0):
						if not keep:
							_seed.queue_free()
						_seed = null
						groom()
		"groom":
			_target = _pos
			_sit_to = 1.0
			_groom = 1.0
			_look_to = Vector2(0.0, -0.25)
			if _st > 6.0:
				_sit_to = 0.0
				wander(_pos, 0.15)
		"birth":
			_birth(dt)
		"sleep":
			_sit_to = 0.0
			if _stage == 0: # (to its nest's middle, or where it is)
				var at := home_nest.position if is_instance_valid(home_nest) else _pos
				_target = at
				if _pos.distance_to(at) < 0.012 and _speed < 0.01:
					_stage = 1
					_st = 0.0
					_wait = maxf(_wait, 4.0)
			else: # (curled tight, its head round to its flank, asleep)
				_target = _pos
				_sniff = 0.0
				_crouch = move_toward(_crouch, 1.0, dt * 1.5)
				_look_to = Vector2(1.1, -0.55)
				if _wait <= 0.0:
					wander(_pos, 0.15)
		"nurse":
			_target = _pos
			_sit_to = 0.0
			_crouch = move_toward(_crouch, 1.0, dt)
			_look_to = Vector2(0.4 * sin(_st * 0.3), -0.3)
			_lick = 0.5 * maxf(sin(_st * 0.7), 0.0)
	if _mode not in ["nurse", "birth", "sleep"]:
		_crouch = move_toward(_crouch, 0.0, dt * 2.0)
	_asleep = move_toward(_asleep, 1.0 if _mode == "sleep" and _stage == 1 and _st > 1.0 else 0.0, dt * 1.5)


## Giving birth: into her nest, settled, the pups out one by one, each
## licked; then nursing them.
func _birth(dt: float) -> void:
	match _stage:
		0: # to her nest (its middle), or where she is
			var at := home_nest.position if is_instance_valid(home_nest) else _pos
			_target = at
			_sit_to = 0.0
			if _pos.distance_to(at) < 0.01 and _speed < 0.01:
				_stage = 1
				_st = 0.0
		1: # settled, curled a little, labouring (her flanks heaving)
			_target = _pos
			_crouch = move_toward(_crouch, 0.7, dt)
			_look_to = Vector2(0.9, -0.4) # (round to her side, to them)
			if _st > 2.0:
				_stage = 2
				_st = 0.0
		2: # a pup out, and licked clean; the next
			_lick = 1.0
			if _st > 2.5 and _born_left > 0:
				_born_left -= 1
				_st = 0.0
				_pup()
				_gravid = float(_born_left) / maxf(float(_born_left + _litter.size()), 1.0)
			if _born_left <= 0 and _st > 2.5:
				_gravid = 0.0
				_mode = "nurse"
				_st = 0.0


func _pup() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var p: Node3D = (get_script() as Script).new(true)
	parent.add_child(p)
	# (by her side, under her flank, each a little apart)
	var k := _litter.size()
	var b := Basis(Vector3.UP, _yaw)
	var off := b * Vector3(16.0 + 4.0 * (k % 2), 0.0, -6.0 + 7.0 * k) * MM * 0.5
	p.call("place", _pos + off, _yaw + rng.randf_range(-2.0, 2.0))
	p.call("grow", 0.5, 240.0)
	p.set("_centre", _pos)
	p.set("height", height)
	p.set("sink_water", sink_water)
	_litter.append(p)
	pups.append(p)


## (A newborn: lying where it is, helpless, wriggling, its legs paddling;
## now and then over onto its side and back.)
func _helpless(dt: float) -> void:
	_target = _pos
	_speed = 0.0
	_sit_to = 0.0
	_sniff = 0.4
	_look_to = Vector2(0.5 * sin(_t * 1.3 + rng.randf() * 0.01), -0.2 + 0.2 * sin(_t * 2.1))
	_roll = lerpf(_roll, 0.9 * maxf(sin(_t * 0.23 + float(get_instance_id() % 7)), 0.0), 1.0 - exp(-1.5 * dt))
	_crouch = 0.8
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var paddle := sin(_t * (5.0 + i) + i * 1.3)
		_pose_foot[i] = Vector3(hp.x * side * 1.6, hp.y - float(L.f) * 0.7, hp.z + paddle * 4.0)
	if size >= 0.25: # (up and about: its own feet)
		for i in _pose_foot.size():
			_pose_foot[i] = null
		_roll = 0.0
		wander(_centre if _centre != Vector3.ZERO else _pos, 0.12)


# --- mating -------------------------------------------------------------------

func _mate_approach() -> Vector3:
	return Vector3(0.0, -body_h, 62.0) # (behind her, his nose to her)


func _mate_leave() -> Vector3:
	return Vector3(26.0, -body_h, 40.0)


func _court_secs() -> float:
	return 3.0 # (sniffing her, following)


func _mount_secs() -> float:
	return 0.35


func _mount() -> Dictionary:
	# over her rump, his front up on her back, his forepaws clasping her
	# flanks; his hind feet on the ground behind her; thrusting in bouts
	var bout := maxf(sin(_mate_t * 0.9), 0.0)
	_thrust = bout
	var push := sin(_mate_t * 14.0) * 2.2 * bout
	var free := {}
	var inv := (transform * _body.transform).affine_inverse()
	for i: int in [2, 3]:
		var side := 1.0 if i % 2 == 1 else -1.0
		var w: Vector3 = _mate.call("_out", Vector3(10.0 * side, -body_h, 60.0))
		w.y = _ground(w.x, w.z)
		free[i] = inv * w
	return {"at": Vector3(0.0, 18.0, 30.0 + push), "basis": Basis(Vector3.RIGHT, 0.25), "grips": {
		0: Vector3(-12.0, 0.0, 8.0), 1: Vector3(12.0, 0.0, 8.0)}, "free": free}


func _mating(dt: float) -> void:
	super(dt)
	_sit_to = 0.0
	_sniff = 1.0
	if _mate_role == "male" and _mate_stage == "court":
		_look_to = Vector2(0.0, -0.35) # (his nose to her)
		# (following her, nose to her)
		var to: Vector3 = _mate.call("_out", Vector3(0.0, 0.0, 45.0))
		_target = Vector3(to.x, _pos.y, to.z)


func _after_mate() -> void:
	_thrust = 0.0
	if male:
		groom() # (washing himself)
	else:
		_gravid = maxf(_gravid, 0.15) # (carrying)
		wander(_pos, 0.15)


# --- the pose -----------------------------------------------------------------

func _pose(dt: float) -> void:
	_grow_fur()
	if _asleep > 0.5 and not young: # (its eyes shut: the lids over them)
		for l in _lids:
			l.visible = true
		for e in _eyes:
			e.visible = false
	elif not young:
		for l in _lids:
			l.visible = false
		for e in _eyes:
			e.visible = true
	_sit = move_toward(_sit, _sit_to, dt * 3.0)
	var s := _sit * _sit * (3.0 - 2.0 * _sit)
	# up on its haunches: nose up, the body lifted so the rump stays down
	if not (_mate_role == "male" and _mate_stage in ["mount", "joined", "part"]):
		_pitch = 0.95 * s
		_lift = 16.0 * s
	# the head: turning to look, sniffing; down to what it eats; kept level
	# sitting up
	_look = _look.lerp(_look_to, 1.0 - exp(-6.0 * dt))
	var nib := 0.05 * _chew * sin(_t * 22.0)
	var lick := 0.25 * _lick * maxf(sin(_t * 6.0), 0.0)
	_head.rotation = Vector3(_look.y - s * 1.05 + nib - lick, _look.x, 0.0)
	_jaw.rotation.x = 0.18 * _chew * (0.5 + 0.5 * sin(_t * 22.0))
	for w in _whiskers:
		var side: float = w.get_meta("side")
		w.rotation = Vector3(0.0, side * 0.12 * _sniff * sin(_t * 48.0), 0.05 * sin(_t * 3.0))
	for e in _ears:
		var side: float = e.get_meta("side")
		e.rotation = Vector3(-0.15 + 0.1 * sin(_t * 0.7 + side), side * (0.25 + 0.15 * sin(_t * 0.9 + side * 2.0)), side * 0.35)
	# her belly swelling with young
	var g := _gravid
	var br := 0.04 * _asleep * sin(_t * 3.0) # (asleep: its sides rising and falling)
	_torso.scale = Vector3(1.0 + 0.22 * g + br, 1.0 + 0.12 * g + br, 1.0 + 0.05 * g)
	# the tail: down off the rump to the ground and trailing behind, swaying
	# (held off the ground at its root, sitting up: its root kept level)
	var sway := 0.4 if _speed > 0.01 else 0.12
	for k in _tail.size():
		var n := _tail[k]
		var down := ([0.18, 0.16, 0.12, 0.04, -0.08, -0.12, -0.12, -0.1, -0.06, -0.02][k] as float) if k < 10 else 0.0 # (a smooth arc: down off its rump, then along the ground, no kink)
		if k == 0:
			down -= _pitch
		n.rotation = Vector3(down, sway * 0.25 * sin(_t * 2.2 - k * 0.5) * (0.4 + float(k) / TAIL_N), 0.0)
	# the forepaws: holding its seed at its mouth, washing its face, licking
	# a pup, or walking
	var mouth := _head.transform * Vector3(0.0, -6.5, -19.5)
	for i: int in [0, 1]:
		var side := 1.0 if i % 2 == 1 else -1.0
		if _mate_role == "male" and _mate_stage in ["mount", "joined", "part"]:
			continue
		if _groom > 0.3:
			var ph := _t * 9.0 + (PI if side > 0.0 else 0.0)
			_pose_foot[i] = _head.transform * Vector3(side * (3.5 + 1.5 * cos(ph)), -3.0 + 3.0 * sin(ph), -14.0 + 4.0 * cos(ph))
		elif _sit > 0.6 and _mode == "eat" and _stage >= 1:
			_pose_foot[i] = mouth + Vector3(side * 2.4, -1.0 + 0.5 * sin(_t * 3.0 + side), 0.0)
		elif _sit > 0.5:
			_pose_foot[i] = Vector3(side * 4.5, -10.0, -24.0) # (held up before its chest)
		elif not (young and size < 0.25):
			_pose_foot[i] = null


## Its legs, a mammal's: from the shoulder or hip to the foot, the foot
## flat on the ground heel to toe (the hind's long), the forelegs' elbows
## back, the hind legs' knees forward.
func _pose_legs() -> void:
	var inv := (transform * _body.transform).affine_inverse()
	var up := (inv.basis * Vector3.UP).normalized()
	var fwd := inv.basis * (transform.basis * Vector3.FORWARD)
	fwd = (fwd - up * fwd.dot(up)).normalized()
	for i in legs.size() * 2:
		var L: Dictionary = legs[i / 2]
		var hind := i >= 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var hp: Vector3 = L.hip
		var hip := Vector3(hp.x * side, hp.y, hp.z)
		var foot: Vector3
		if _pose_foot[i] != null:
			foot = _pose_foot[i]
		elif airborne:
			var dg: Vector3 = L.dangle
			foot = Vector3(dg.x * side, dg.y, dg.z)
		else:
			foot = inv * _feet[i]
		var held := _pose_foot[i] != null and not hind
		var J := _leg3(i, foot, up, fwd, held)
		var knee: Vector3 = J[1]
		var heel: Vector3 = J[2]
		_joints[i] = J
		var r: float = L.r
		var m: Array = _leg_mesh[i]
		(m[0] as MeshInstance3D).transform = _seg(hip, knee, r * float(L.femur_r))
		(m[1] as MeshInstance3D).transform = _seg(knee, heel, r * 0.85)
		var ts := m[2] as MeshInstance3D
		ts.transform = _seg(heel, foot, r * (0.55 if hind else 0.6))
		ts.material_override = _paw_mat
		(m[3] as MeshInstance3D).transform = Transform3D(Basis().scaled(Vector3.ONE * r * 1.5), knee)
		if i < _toes.size(): # (its toes splayed from the foot, along it)
			var along := (foot - heel)
			along -= up * along.dot(up)
			var z := along.normalized() if along.length() > 1e-4 else -fwd
			var xx := z.cross(up).normalized()
			_toes[i].transform = Transform3D(Basis(xx, up, -z), foot)
	_skin_pose()


# --- steering (pilot.gd): its behaviours ----------------------------------------

## eat {seed, seconds}, groom {seconds}, birth {n, nest} (a female's), mate
## {partner}; a newborn's none, till it's up and about.
func _p_behaviours() -> PackedStringArray:
	if young:
		return PackedStringArray(["eat"]) if size >= 0.25 else PackedStringArray()
	return PackedStringArray(["eat", "groom", "sleep", "mate"]) if male else PackedStringArray(["eat", "groom", "sleep", "birth", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"eat":
			var s: Node3D = args.get("seed")
			if s == null:
				return false
			eat(s)
		"groom":
			groom()
		"sleep":
			sleep(float(args.get("seconds", 20.0)))
		"birth":
			if male or young:
				return false
			birth(int(args.get("n", 4)), args.get("nest"))
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"eat", "birth", "groom", "sleep":
			return _mode != name
	return false


func _p_act_secs(name: String) -> float:
	return 6.0 if name == "groom" else -1.0


func _p_mobile() -> bool:
	return not (young and size < 0.25) and _mode not in ["birth", "nurse"]


func _piloted() -> void:
	if _mode in ["wander", "idle", "nurse"]:
		_mode = "piloted"
	_sit_to = 0.0
