class_name Hare
extends "res://scripts/creatures/hexapod.gd" # (by path: found whether or not the editor has seen the class yet)
## A snowshoe hare (Lepus americanus), life size (its model in mm, size 0.5
## of the walker's doubled scale: about 45 cm long), in its summer coat
## (carnivore.gdshader's species 8, on one skin: MammalSkin): brown, grizzled, darker along the back,
## white beneath, the big hind feet paler. Its ears long (not a
## jackrabbit's), black tipped, turning; big dark eyes set high on the
## sides; a split lip, its nose twitching, whiskers; a powder puff of a
## tail; long slender forelegs; its hind feet huge, furred, flat (the
## snowshoes), heel to toe. Young (Hare.new(true)): leverets, born furred,
## eyes open, a fifth her length; hopping about soon; growing. The two sexes
## the same to see. Not yet in the game (tools/creatures/life_cycle_demo.tscn).
##
## Its gait its own: hopping (the hind feet pushing off together, a moment
## in the air, the forefeet down one then the other, the hind feet swung
## past them to land ahead), slow or bounding, the body arched and
## stretched; still, its feet planted, crouched in its form.
## - wander(centre, radius): a few hops, a stop, sitting hunched, looking,
##   nibbling, now and then sitting up to look
## - eat(food) (Hare.clover() low; Hare.twig(): high, it sits up to it):
##   nibbling it away, the jaw going side to side, the nose twitching
## - groom(): sitting up, licking its forepaws, washing its face, an ear
##   drawn down through its paws
## - alert(): up on its haunches, tall, its ears up and turning
## - thump(): its hind feet drummed on the ground, an alarm
## - freeze(secs): flattened, its ears laid back, still
## - flee(from): away, bounding, zigzagging, then a stop and a look back
## - birth(n): (a female's) settled in a form, the leverets born one by one,
##   each licked; she nurses them, standing over them, then leaves them
##   (nurse(): back to them, and nursing again)
## - mate(her): he chases her (she leaping up now and then, running on in
##   a ring); then on her from behind, briefly; off; she leaps away
## Steering (pilot.gd): act eat {food}, groom, alert, thump, freeze
## {seconds}, flee {from}, birth {n} (a female's), nurse, mate {partner}.

const FORE := {"hip": Vector3(28.0, -30.0, -95.0), "f": 62.0, "t": 72.0, "s": 34.0, "home": Vector2(30.0, -112.0), "dangle": Vector3(26.0, -60.0, -150.0), "pole": Vector3(0.1, 0.0, 1.0), "r": 9.0, "femur_r": 1.9}
const HIND := {"hip": Vector3(42.0, -8.0, 100.0), "f": 92.0, "t": 98.0, "s": 118.0, "home": Vector2(46.0, 18.0), "dangle": Vector3(40.0, -50.0, 190.0), "pole": Vector3(0.2, 0.1, -1.0), "r": 12.0, "femur_r": 2.4}
const EAR_LEN := 75.0

var young := false
var leverets: Array[Node3D] = [] ## her young
var _mode := "idle"
var _centre := Vector3.ZERO
var _radius := 0.5
var _wait := 0.0
var _st := 0.0
var _stage := 0
var _food: Node3D
var _food_s := Vector3.ONE
var _flee_from := Vector3.ZERO
var _born_left := 0
var _form := Vector3.ZERO
# the pose
var _hop := 0.0 # the hop's phase (0..1)
var _hopping := false
var _sit := 0.0 # 0 hunched .. 1 up on its haunches
var _sit_to := 0.0
var _ears := 0.0 # -1 laid flat back .. 0 easy .. 1 up, pricked
var _ears_to := 0.0
var _ear_turn := Vector2.ZERO
var _chew := 0.0
var _lick := 0.0
var _groom := 0.0
var _thump := 0.0
var _look := Vector2.ZERO
var _look_to := Vector2.ZERO
var _accel := 3.0 # m/s/s
# the parts
var _torso: MeshInstance3D
var _head: Node3D
var _jaw: Node3D
var _nose: Node3D
var _ear_nodes: Array[Node3D] = []
var _whiskers: Array[Node3D] = []
var _tail: Node3D


func _init(young_ := false) -> void:
	young = young_
	super(young_, 0.11 if young_ else 0.5)
	legs = [FORE, HIND]
	tripod = [[0, 3], [1, 2]]
	body_h = 100.0
	walk_speed = 1.3
	stride = 120.0
	step_time = 0.12
	mate_secs = 6.0


func _coat_mat(part: int, pale := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/render/carnivore.gdshader") # (the mammals' coats: its species 8)
	m.set_shader_parameter("species", 8)
	m.set_shader_parameter("young", young)
	m.set_shader_parameter("hair", 9.0)
	m.set_shader_parameter("part", [0, 5, 6][part])
	m.set_shader_parameter("along", 0.5)
	m.set_shader_parameter("to_cream", pale)
	m.set_shader_parameter("ear_len", EAR_LEN)
	return m


func _build() -> void:
	var fur := _coat_mat(0)
	var head_fur := fur
	var leg_fur := _coat_mat(0, 0.1)
	var feet := _coat_mat(0, 0.55) # (the hind feet paler)
	var ear := _coat_mat(1)
	var tail := _coat_mat(2)
	# the body (the narrow neck, the chest, the long back rising to the round
	# of the haunches, the rump) and its head: one skin (_build_skin)
	_head = Node3D.new()
	_head.position = Vector3(0.0, 48.0, -140.0)
	_body.add_child(_head)
	var eye := _mat(Color(0.08, 0.05, 0.03), 0.03)
	eye.clearcoat_enabled = true # (big, dark, wet)
	eye.clearcoat = 1.0
	var ring := _coat_mat(0, 0.75) # (the pale ring round each eye)
	# (each set on the head's surface, high on its side, bulging; the fur
	# bare round it, the pale ring just behind it)
	var ex := _surface_x(HEAD_KEYS, -42.0, 16.0) - 1.6
	head_fur.set_shader_parameter("bare_a", Vector3(-ex, 16.0, -42.0))
	head_fur.set_shader_parameter("bare_b", Vector3(ex, 16.0, -42.0))
	head_fur.set_shader_parameter("bare_r", 15.0)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(ex * side, 16.0, -42.0), Vector3(16.0, 19.0, 20.0), eye, _head)
		_part(Vector3((ex - 4.0) * side, 16.0, -42.0), Vector3(14.0, 24.0, 25.0), ring, _head)
		_part(Vector3(9.0 * side, -9.0, -80.0), Vector3(18.0, 16.0, 22.0), head_fur, _head) # (its whisker pads)
		_part(Vector3(28.0 * side, 16.0, -42.0), Vector3(19.0, 22.0, 23.0), head_fur, _head) # (its lids round it)
	_nose = Node3D.new()
	_nose.position = Vector3(0.0, -8.0, -94.0)
	_head.add_child(_nose)
	_part(Vector3.ZERO, Vector3(12.0, 8.0, 7.0), _mat(Color(0.5, 0.38, 0.34), 0.6), _nose)
	for side: float in [-1.0, 1.0]: # (the lip's halves, either side of its cleft)
		_part(Vector3(5.0 * side, -9.0, -2.0), Vector3(11.0, 9.0, 10.0), head_fur, _nose)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0.0, -18.0, -60.0)
	_head.add_child(_jaw)
	_stick(Vector3(0.0, -17.0, -91.0), Vector3(0.0, -24.0, -90.0), 2.6, _mat(Color(0.95, 0.9, 0.8), 0.3), _head) # (the incisors)
	var wh := _mat(Color(0.85, 0.84, 0.8), 0.5)
	var wd := _mat(Color(0.1, 0.09, 0.08), 0.5)
	for side: float in [-1.0, 1.0]:
		var w := Node3D.new()
		w.position = Vector3(10.0 * side, -12.0, -88.0)
		_head.add_child(w)
		w.set_meta("side", side)
		for k in 6:
			var a := deg_to_rad(-20.0 + 10.0 * k)
			var d := Vector3(side * cos(a), sin(a) * 0.5, 0.3).normalized()
			_stick(Vector3.ZERO, d * (55.0 + 10.0 * sin(k * 1.3)), 0.22, wd if k % 2 == 0 else wh, w)
		_whiskers.append(w)
	# the ears: long, upright, spoon shaped, open forward, black tipped
	for side: float in [-1.0, 1.0]:
		var e := Node3D.new()
		e.position = Vector3(14.0 * side, 30.0, -20.0)
		_head.add_child(e)
		e.set_meta("side", side)
		var em := MeshInstance3D.new()
		em.mesh = _ear_mesh()
		em.material_override = ear
		e.add_child(em)
		_ear_nodes.append(e)
	# the tail: a powder puff
	_tail = Node3D.new()
	_tail.position = Vector3(0.0, 34.0, 156.0)
	_body.add_child(_tail)
	_part(Vector3(0.0, 4.0, 10.0), Vector3(44.0, 38.0, 38.0), tail, _tail)
	_build_legs(leg_fur, leg_fur)
	for i in 4: # (the skin's legs: these carry nothing)
		for q in 4:
			(_leg_mesh[i][q] as MeshInstance3D).mesh = null
	_joints.resize(4)
	_build_skin(fur)


const HEAD_KEYS := [[18.0, 0.0, 30.0, 30.0], [-8.0, 8.0, 40.0, 38.0], [-40.0, 6.0, 38.0, 34.0], [-66.0, -3.0, 29.0, 26.0], [-86.0, -9.0, 19.0, 18.0], [-96.0, -11.0, 9.0, 9.0]]
const BODY_KEYS := [[-150.0, 22.0, 34.0, 38.0], [-122.0, 16.0, 50.0, 56.0], [-62.0, 6.0, 60.0, 64.0], [10.0, 10.0, 64.0, 68.0],
		[78.0, 20.0, 70.0, 74.0], [122.0, 24.0, 64.0, 64.0], [148.0, 22.0, 42.0, 44.0], [158.0, 18.0, 12.0, 12.0]]
const SkinScript := preload("res://scripts/creatures/mammal_skin.gd")
var _skin: SkinScript
var _sb := {}
var _joints: Array = []


## Its skin: the body into the head, the jaw, each leg (standing).
func _build_skin(mat: ShaderMaterial) -> void:
	var K: SkinScript = SkinScript.new()
	var torso := K.bone("torso", Transform3D())
	var hrest := _head.transform
	var head := K.bone("head", hrest)
	var jrest := hrest * _jaw.transform
	var jaw := K.bone("jaw", jrest)
	_sb = {"head": head, "jaw": jaw}
	K.body_head(torso, BODY_KEYS, head, hrest, HEAD_KEYS, 2.1)
	K.jaw_tube(head, jaw, jrest, [[0.0, -2.0, 11.0, 6.0], [-14.0, -2.0, 10.0, 5.5], [-28.0, -2.0, 6.0, 3.5]])
	for i in 4:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = L.home
		var J := _leg3(i, Vector3(hm.x * side, -body_h, hm.y), Vector3.UP, Vector3.FORWARD, false, false)
		var bones := []
		for q in 3:
			bones.append(K.bone("leg%d_%d" % [i, q], SkinScript.along(J[q], J[q + 1])))
		_sb["leg%d" % i] = bones
		K.leg3(torso, bones, J, float(L.r), i >= 2, 3.0 if i >= 2 else 1.7, -1.0, i >= 2)
	_skin = K
	mat = mat.duplicate() as ShaderMaterial # (its own: the rigid parts keep theirs)
	mat.set_shader_parameter("skin", true)
	var ex := _surface_x(HEAD_KEYS, -42.0, 16.0) - 1.6
	mat.set_shader_parameter("bare_a", Vector3(-ex, 16.0, -42.0))
	mat.set_shader_parameter("bare_b", Vector3(ex, 16.0, -42.0))
	mat.set_shader_parameter("bare_r", 15.0)
	_torso = K.finish(_body, mat)


## Leg i's joints, its foot at foot: [hip, knee, heel, toe].
func _leg3(i: int, foot: Vector3, up: Vector3, fwd: Vector3, held: bool, stretched: bool) -> Array:
	var L: Dictionary = legs[i / 2]
	var hind := i >= 2
	var side := 1.0 if i % 2 == 1 else -1.0
	var hp: Vector3 = L.hip
	var hip := Vector3(hp.x * side, hp.y, hp.z)
	var s: float = L.s
	var heel: Vector3
	if hind:
		# (flat on the ground, heel to toe; in the air stretched out behind)
		var flat := -fwd
		if stretched:
			flat = (foot - hip).normalized() * 0.4 + (-fwd) * 0.6
		heel = foot + (flat.normalized() * 0.97 + up * 0.15).normalized() * s
	elif held:
		heel = foot + Vector3(0.0, -0.7, 0.5).normalized() * s
	else:
		heel = foot + (-fwd * 0.25 + up * 0.97).normalized() * s
	var pl: Vector3 = L.pole
	var knee := _knee(hip, heel, L.f, L.t, Vector3(pl.x * side, pl.y, pl.z))
	return [hip, knee, heel, foot]


## (No shells: its coat is painted, carnivore.gdshader's species 8.)
func _fur_shells(_mi: MeshInstance3D, _len_mm: float, _shells := 8, _spacing := -1.0) -> void:
	pass


## An ear: up its own y (EAR_LEN), a long spoon, open forward (-z), thin.
static func _ear_mesh() -> ArrayMesh:
	const RINGS := 9
	const ROUND := 12
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := func(i: int, k: int) -> Array:
		var t := float(i) / RINGS
		var y := t * EAR_LEN
		var hw := 15.0 * sin(PI * clampf(t * 0.92 + 0.08, 0.0, 1.0)) * (1.0 - 0.15 * t) + 1.0
		var a := TAU * float(k % ROUND) / ROUND
		var x := sin(a) * hw
		var z := cos(a) * 4.5 * (1.0 - 0.5 * t)
		z -= absf(sin(a)) * hw * 0.45 * (1.0 - absf(cos(a))) # (cupped: its edges forward)
		var p := Vector3(x, y, z)
		var n := Vector3(sin(a), 0.0, cos(a)).normalized()
		return [p, n]
	for i in RINGS:
		for k in ROUND:
			var q := [ring.call(i, k), ring.call(i + 1, k), ring.call(i + 1, k + 1), ring.call(i, k + 1)]
			for tri: Array in [[0, 2, 1], [0, 3, 2]]:
				for c: int in tri:
					var v: Array = q[c]
					st.set_normal(v[1])
					st.add_vertex(v[0])
	return st.commit()


## A clover clump, for it to eat (life size, a hand across); its origin on
## the ground.
static func clover() -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 8
	s.rings = 4
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.25, 0.48, 0.2)
	leaf.roughness = 0.7
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 14:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.0, 0.045)
		var base := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var h := rng.randf_range(0.02, 0.06)
		for l in 3: # (three leaflets)
			var mi := MeshInstance3D.new()
			mi.mesh = s
			var la := TAU * l / 3.0 + rng.randf()
			mi.position = base + Vector3(cos(la) * 0.007, h, sin(la) * 0.007)
			mi.scale = Vector3(0.011, 0.0015, 0.011)
			mi.material_override = leaf
			root.add_child(mi)
	return root


## A willow shoot, for it to browse (life size, 40 cm up, its
## buds and thin twigs); its origin at its foot. Its top's high: it sits up
## to it.
static func twig() -> Node3D:
	var root := Node3D.new()
	root.set_meta("high", true)
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	c.radial_segments = 5
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.45, 0.25, 0.15)
	bark.roughness = 0.6
	var spots := [[Vector3(0.0, 0.0, 0.0), Vector3(0.01, 0.4, 0.0)], [Vector3(0.008, 0.22, 0.0), Vector3(0.08, 0.36, 0.03)], [Vector3(0.005, 0.3, 0.0), Vector3(-0.06, 0.42, -0.02)]]
	for sp: Array in spots:
		var a: Vector3 = sp[0]
		var b: Vector3 = sp[1]
		var mi := MeshInstance3D.new()
		mi.mesh = c
		var d := b - a
		var y := d.normalized()
		var x := y.cross(Vector3.FORWARD).normalized()
		mi.transform = Transform3D(Basis(x * 0.006, d, x.cross(y) * 0.006), (a + b) * 0.5)
		mi.material_override = bark
		root.add_child(mi)
	return root


# --- what it does --------------------------------------------------------------

func wander(centre: Vector3, radius: float) -> void:
	_mode = "wander"
	_centre = centre
	_radius = radius
	_wait = 0.0
	_pace = -1.0
	_sit_to = 0.0


func eat(food: Node3D) -> void:
	if food == null or not is_instance_valid(food):
		return
	_mode = "eat"
	_food = food
	_food_s = food.scale
	_stage = 0
	_st = 0.0


func groom() -> void:
	_mode = "groom"
	_st = 0.0


func alert() -> void:
	_mode = "alert"
	_st = 0.0


func thump() -> void:
	_mode = "thump"
	_st = 0.0


func freeze(secs := 6.0) -> void:
	_mode = "freeze"
	_st = 0.0
	_wait = secs


func flee(from: Vector3) -> void:
	_mode = "flee"
	_flee_from = from
	_stage = 0
	_st = 0.0
	_wait = 0.0


## (A female's.) Leverets born where she is (her form): n of them.
func birth(n := 4) -> void:
	if young or male:
		return
	_mode = "birth"
	_born_left = n
	_form = _pos
	_stage = 0
	_st = 0.0


## (A female's.) Back to her leverets, and nursing them.
func nurse() -> void:
	if leverets.is_empty():
		return
	_mode = "nurse"
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	_wait -= dt
	_st += dt
	_pace = -1.0 if _mode not in ["flee", "eat"] else _pace
	_chew = move_toward(_chew, 0.0, dt * 3.0)
	_lick = move_toward(_lick, 0.0, dt * 3.0)
	_groom = move_toward(_groom, 0.0, dt * 3.0)
	_ears_to = 0.0
	match _mode:
		"wander":
			if _wait <= 0.0:
				var r := rng.randf()
				if r < 0.35: # (hunched, still, looking)
					_target = _pos
					_look_to = Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.1, 0.15))
					_sit_to = 0.0
					_wait = rng.randf_range(2.0, 6.0)
				elif r < 0.45:
					alert()
					return
				else: # (a few hops)
					var a := rng.randf() * TAU
					_target = _centre + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * _radius
					_look_to = Vector2.ZERO
					_wait = rng.randf_range(2.0, 4.0)
		"eat":
			_eat(dt)
		"groom":
			_target = _pos
			_sit_to = 0.8
			_groom = 1.0
			if _st > 9.0:
				_sit_to = 0.0
				wander(_pos if _centre == Vector3.ZERO else _centre, _radius)
		"alert":
			_target = _pos
			_sit_to = 1.0
			_ears_to = 1.0
			_look_to = Vector2(0.6 * sin(_st * 0.8), 0.25)
			if _st > 5.0:
				_sit_to = 0.0
				wander(_pos if _centre == Vector3.ZERO else _centre, _radius)
		"thump":
			_target = _pos
			_ears_to = 1.0
			_thump = maxf(sin(_st * 9.0), 0.0) if _st < 2.0 else 0.0
			if _st > 2.5:
				_thump = 0.0
				freeze(4.0)
		"freeze":
			_target = _pos
			_sit_to = 0.0
			_ears_to = -1.0
			_crouch = move_toward(_crouch, 1.0, dt * 4.0)
			if _wait <= 0.0:
				wander(_pos if _centre == Vector3.ZERO else _centre, _radius)
		"flee":
			_ears_to = -0.6
			if _wait <= 0.0: # (a zigzag: each leg of it a new way, away)
				var away := _pos - _flee_from
				away.y = 0.0
				away = away.normalized() if away.length() > 1e-4 else Vector3.FORWARD
				away = away.rotated(Vector3.UP, rng.randf_range(-0.7, 0.7))
				_target = _pos + away * rng.randf_range(0.8, 1.6)
				_wait = rng.randf_range(0.5, 1.0)
				_stage += 1
			_pace = 5.0
			if _stage > 5:
				_pace = -1.0
				_mode = "alert" # (a stop, and a look back)
				_st = 0.0
		"birth":
			_birth(dt)
		"nurse":
			_nurse(dt)
	if _mode != "freeze":
		_crouch = move_toward(_crouch, 0.0, dt * 2.0)


func _eat(_dt: float) -> void:
	if not is_instance_valid(_food):
		_sit_to = 0.0
		wander(_pos if _centre == Vector3.ZERO else _centre, _radius)
		return
	var high := _food.has_meta("high")
	var p := _food.position
	var to := p - _pos
	to.y = 0.0
	var reach := (140.0 + 95.0) * MM * size * (0.7 if high else 1.0) # (its middle to its mouth)
	match _stage:
		0: # to it
			_target = p - to.normalized() * reach if to.length() > reach * 1.05 else _pos
			if to.length() <= reach * 1.15 and _speed < 0.05:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				_stage = 1
				_st = 0.0
		1: # nibbling (sat up to it, if it's high)
			_target = _pos
			_sit_to = 0.9 if high else 0.0
			_look_to = Vector2(0.15 * sin(_st * 0.7), 0.35 if high else -0.55)
			_chew = 1.0
			var k := clampf(1.0 - _st / 10.0, 0.08, 1.0)
			_food.scale = _food_s * Vector3(1.0, k, 1.0) if high else _food_s * k
			if _st > 10.0:
				if not high:
					_food.queue_free()
				_food = null
				_sit_to = 0.0
				groom()


func _birth(dt: float) -> void:
	match _stage:
		0: # settled in her form, hunched, labouring
			_target = _pos
			_crouch = move_toward(_crouch, 0.6, dt)
			_look_to = Vector2(0.9, -0.4)
			if _st > 2.5:
				_stage = 1
				_st = 0.0
		1: # each born, licked dry
			_target = _pos
			_crouch = move_toward(_crouch, 0.6, dt)
			_lick = 1.0
			_look_to = Vector2(0.9 * sin(_st * 0.2 + 1.0), -0.6)
			if _st > 3.0 and _born_left > 0:
				_born_left -= 1
				_st = 0.0
				_leveret()
			if _born_left <= 0 and _st > 3.0:
				_mode = "nurse"
				_stage = 1
				_st = 0.0


func _leveret() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var l: Node3D = (get_script() as Script).new(true)
	parent.add_child(l)
	var k := leverets.size()
	var off := Basis(Vector3.UP, _yaw) * Vector3((60.0 + 25.0 * (k % 2)) * (1.0 if k % 2 == 0 else -1.0), 0.0, -40.0 + 35.0 * k) * MM * size
	l.call("place", _pos + off, _yaw + rng.randf_range(-1.5, 1.5))
	l.set("height", height)
	l.call("grow", 0.5, 300.0)
	l.call("wander", _pos + off, 0.12)
	leverets.append(l)


## Back to them (the first), standing over them, nursing; then off.
func _nurse(dt: float) -> void:
	var at := _form
	for l in leverets:
		if is_instance_valid(l):
			at = l.get("_pos")
			break
	match _stage:
		0:
			_target = at
			if _pos.distance_to(at) < 0.06:
				_stage = 1
				_st = 0.0
		1: # (over them, still, they under her)
			_target = _pos
			_crouch = move_toward(_crouch, 0.3, dt)
			_look_to = Vector2(0.3 * sin(_st * 0.4), -0.3)
			for l in leverets:
				if is_instance_valid(l) and float(l.get("size")) < 0.3:
					var to := _out(Vector3(0.0, -body_h, 30.0)) - (l.get("_pos") as Vector3)
					if to.length() > 0.02:
						l.call("go_to", _out(Vector3(rng.randf_range(-20.0, 20.0), -body_h, 30.0)))
			if _st > 10.0:
				for l in leverets:
					if is_instance_valid(l):
						l.call("stop")
						l.call("freeze", 30.0) # (left: each still, hidden, till she's back)
				wander(_pos + Vector3(0.6, 0.0, 0.4), 0.5)


# --- mating -------------------------------------------------------------------

func _mate_approach() -> Vector3:
	return Vector3(0.0, -body_h, 420.0)


func _mate_leave() -> Vector3:
	return Vector3(140.0, -body_h, 320.0)


func _court_secs() -> float:
	return 9.0 # (the chase)


func _mount_secs() -> float:
	return 0.4


func _mount() -> Dictionary:
	var thrust := sin(_mate_t * 16.0) * 6.0
	var free := {}
	var inv := (transform * _body.transform).affine_inverse()
	for i: int in [2, 3]:
		var side := 1.0 if i % 2 == 1 else -1.0
		var w: Vector3 = _mate.call("_out", Vector3(50.0 * side, -body_h, 230.0))
		w.y = _ground(w.x, w.z)
		free[i] = inv * w
	return {"at": Vector3(0.0, 60.0, 150.0 + thrust), "basis": Basis(Vector3.RIGHT, 0.3), "grips": {
		0: Vector3(-60.0, 10.0, 50.0), 1: Vector3(60.0, 10.0, 50.0)}, "free": free}


func _mating(dt: float) -> void:
	super(dt)
	_sit_to = 0.0
	if _mate == null or not is_instance_valid(_mate):
		return
	if _mate_role == "male" and _mate_stage == "court": # (after her)
		var to: Vector3 = _mate.call("_out", Vector3(0.0, -body_h, 380.0))
		_target = Vector3(to.x, _pos.y, to.z)
		_pace = walk_speed * 0.9
	elif _mate_role == "female" and _mate.get("_mate_stage") in ["seek", "court"]:
		# (running on in a ring, him after her, leaping up now and then)
		var a := _mate_t * 0.9
		var c := _form if _form != Vector3.ZERO else _pos
		if _mate_t < dt * 1.5:
			_form = _pos
			c = _pos
		_target = c + Vector3(cos(a), 0.0, sin(a)) * 0.6
		_pace = walk_speed * 0.7
		if not airborne and fmod(_mate_t, 3.1) < dt and _mate_t > 1.0:
			_leap(_pos + Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * 0.15, 1.25)
	elif _mate_role == "female":
		_pace = -1.0


func _after_mate() -> void:
	_pace = -1.0
	if male:
		groom()
	else:
		_form = Vector3.ZERO
		if not airborne:
			_leap(_pos + Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * 0.3, 1.0)
		wander(_pos, 0.6)


# --- the motor: its own walk (it gets going fast), its own gait (hops) ---------

func _walk(dt: float) -> void:
	var to := _target - _pos
	to.y = 0.0
	var d := to.length()
	var want := 0.0
	if _turn_to != INF:
		var tt := wrapf(_turn_to - _yaw, -PI, PI)
		_yaw += clampf(tt, -4.0 * dt, 4.0 * dt)
		if absf(tt) < 0.02:
			_turn_to = INF
	elif d > 0.01 * size:
		var a := atan2(-to.x, -to.z)
		var turn := wrapf(a - _yaw, -PI, PI)
		_yaw += clampf(turn, -5.0 * dt, 5.0 * dt)
		var pace := _pace if _pace > 0.0 else walk_speed * lerpf(0.35, 1.0, size)
		want = minf(pace, d * 3.0) * clampf(1.0 - absf(turn) / 1.4, 0.0, 1.0)
	_speed = move_toward(_speed, want, dt * (_accel if want > _speed else _accel * 2.0))
	_pos += Vector3(-sin(_yaw), 0.0, -cos(_yaw)) * _speed * dt
	ground_y = _ground(_pos.x, _pos.z)
	_pos.y = ground_y


func _gait(dt: float) -> void:
	if _hopping:
		return
	# (still: its feet planted where they are, settled under it)
	for i in legs.size() * 2:
		var h := _home(i)
		if _feet[i].distance_to(h) > 30.0 * MM * size:
			_feet[i] = _feet[i].lerp(h, 1.0 - exp(-10.0 * dt))


## A hop's feet (its phase p 0..1; L its length, mm): each in the body's mm,
## on the ground or in the air.
func _hop_feet(p: float, L: float, lift: float) -> void:
	var to_world := transform * _body.transform
	var inv := to_world.affine_inverse()
	for i in legs.size() * 2:
		var hind := i >= 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var Lg: Dictionary = legs[i / 2]
		var hm: Vector2 = Lg.home
		var x := hm.x * side
		var q := fmod(p + (0.02 * side if hind else (0.0 if side < 0.0 else 0.07)) + 1.0, 1.0)
		var foot: Vector3
		var down := false
		if hind:
			if q < 0.3: # (pushing off: on the ground, left behind)
				foot = Vector3(x, 0.0, hm.y - L * 0.35 + L * (q / 0.3))
				down = true
			elif q < 0.5: # (kicked out straight behind)
				var k := (q - 0.3) / 0.2
				foot = Vector3(x, -body_h + 40.0 + lift + 30.0 * k, hm.y + L * 0.65 + 60.0 * k)
			else: # (swung forward under it, past the forefeet)
				var k := (q - 0.5) / 0.5
				var s := k * k * (3.0 - 2.0 * k)
				foot = Vector3(x * (1.0 + 0.2 * sin(PI * k)), -body_h + 50.0 * sin(PI * k) + lift * (1.0 - k), lerpf(hm.y + L * 0.65 + 60.0, hm.y - L * 0.35, s))
		else:
			var f0 := 0.55
			var g := fmod(q - f0 + 1.0, 1.0)
			if g < 0.25: # (down, one then the other, sweeping back under it)
				foot = Vector3(x, 0.0, hm.y - L * 0.25 + L * 0.6 * (g / 0.25))
				down = true
			else: # (up, reaching forward)
				var k := (g - 0.25) / 0.75
				foot = Vector3(x, -body_h + 45.0 + 30.0 * sin(PI * k) + lift * 0.5, lerpf(hm.y + L * 0.35, hm.y - L * 0.25 - 30.0, k * k * (3.0 - 2.0 * k)))
		if down:
			var w := to_world * Vector3(foot.x, 0.0, foot.z)
			w.y = _ground(w.x, w.z)
			foot = inv * w
		_pose_foot[i] = foot


# --- the pose -----------------------------------------------------------------

func _pose(dt: float) -> void:
	var mounted := _mate_role == "male" and _mate_stage in ["mount", "joined", "part"]
	# hopping: its phase with its speed (a hop finished once begun)
	var moving := _speed > 0.04 and not airborne and not mounted
	if moving or (_hopping and _hop > 0.05 and _hop < 0.95):
		if not _hopping:
			_hopping = true
			_hop = 0.0
		var freq := lerpf(2.0, 3.8, clampf(_speed / 6.0, 0.0, 1.0))
		_hop = fmod(_hop + dt * freq, 1.0)
		var L := clampf(_speed / freq / (MM * size), 30.0, 900.0)
		var flight := clampf((_hop - 0.3) / 0.25, 0.0, 1.0)
		var h := clampf(L * 0.22, 15.0, 120.0) * sin(PI * flight) * (1.0 if _hop > 0.3 and _hop < 0.55 else 0.0)
		_lift = h
		_pitch = 0.12 * sin(TAU * (_hop - 0.15)) * clampf(L / 200.0, 0.3, 1.0)
		_hop_feet(_hop, L, h)
	elif _hopping:
		_hopping = false
		_lift = 0.0
		for i in _pose_foot.size():
			_pose_foot[i] = null
			_feet[i] = _home(i)
	# sitting up: on its haunches, its front raised, its forefeet up
	_sit = move_toward(_sit, _sit_to, dt * 2.5)
	var s := _sit * _sit * (3.0 - 2.0 * _sit)
	if not _hopping and not mounted:
		_pitch = 0.85 * s - 0.08 * _crouch
		_lift = 70.0 * s - 40.0 * _crouch * (1.0 - s) + 12.0 * _thump
		for i: int in [0, 1]:
			var side := 1.0 if i % 2 == 1 else -1.0
			if _groom > 0.3: # (licking its paws, washing its face, an ear)
				var ph := _t * 7.0 + (PI if side > 0.0 else 0.0)
				_pose_foot[i] = _head.transform * Vector3(side * (22.0 + 8.0 * cos(ph)), -20.0 + 15.0 * sin(ph), -60.0 + 15.0 * cos(ph))
			elif s > 0.5:
				_pose_foot[i] = Vector3(side * 22.0, -60.0, -120.0) # (held before its chest)
			elif _mode != "nurse" or _stage != 1:
				_pose_foot[i] = null
	# the head: looking, nibbling, kept level as it sits up
	_look = _look.lerp(_look_to, 1.0 - exp(-6.0 * dt))
	var lick := 0.3 * _lick * maxf(sin(_t * 5.0), 0.0)
	_head.rotation = Vector3(_look.y - s * 0.8 - lick - 0.05 * _groom * sin(_t * 3.5), _look.x, 0.0)
	_jaw.rotation = Vector3(0.12 * _chew * (0.5 + 0.5 * sin(_t * 18.0)), 0.08 * _chew * sin(_t * 9.0), 0.0) # (side to side, grinding)
	_nose.position.y = -8.0 + 1.5 * maxf(sin(_t * 22.0), 0.0) * (0.4 + _chew * 0.6) # (twitching)
	for w in _whiskers:
		var side: float = w.get_meta("side")
		w.rotation = Vector3(0.0, side * 0.08 * sin(_t * 22.0), 0.0)
	# the ears: easy, pricked, turning; laid back fleeing, frozen
	_ears = move_toward(_ears, _ears_to, dt * 3.0)
	if rng.randf() < dt * 0.4:
		_ear_turn = Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))
	for e in _ear_nodes:
		var side: float = e.get_meta("side")
		var turn := _ear_turn.x if side < 0.0 else _ear_turn.y
		var back := -0.25 - 0.2 * (1.0 - absf(_ears)) - (1.0 if _ears < 0.0 else 0.0) * absf(_ears) * 1.1 + 0.25 * maxf(_ears, 0.0)
		var spread := side * (0.12 + 0.15 * maxf(-_ears, 0.0))
		var grooming := 0.5 * _groom * maxf(sin(_t * 3.5 + side), 0.0) # (drawn down through its paws)
		e.rotation = Vector3(back + grooming, turn * (1.0 - absf(minf(_ears, 0.0))), spread)
	# the tail: flicked up, fleeing
	_tail.rotation.x = -0.5 if _mode == "flee" else 0.0


## Its legs, a hare's: from the shoulder or the hip to the foot; the
## forefeet small; the hind feet long, flat, heel to toe (the snowshoes),
## the knees forward, the hocks back.
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
		var held := _pose_foot[i] != null and not hind and _sit > 0.4
		var J := _leg3(i, foot, up, fwd, held, airborne or (_hopping and foot.y > -body_h + 20.0))
		var knee: Vector3 = J[1]
		var heel: Vector3 = J[2]
		_joints[i] = J
		var r: float = L.r
		var m: Array = _leg_mesh[i]
		(m[0] as MeshInstance3D).transform = _seg(hip, knee, r * float(L.femur_r))
		(m[1] as MeshInstance3D).transform = _seg(knee, heel, r * (1.0 if hind else 0.8))
		# the foot: a furred pad from heel to toe, the hind's broad
		var along := foot - heel
		var len_ := maxf(along.length(), 1.0)
		var z := along / len_
		var x := z.cross(up).normalized() if absf(z.dot(up)) < 0.95 else Vector3.RIGHT
		var y := x.cross(z).normalized()
		var wide := 46.0 if hind else 22.0
		(m[2] as MeshInstance3D).transform = Transform3D(Basis(x * wide, y * (16.0 if hind else 14.0), z * len_ * 1.15), (heel + foot) * 0.5)
		(m[3] as MeshInstance3D).transform = Transform3D(Basis().scaled(Vector3.ONE * r * 1.7), knee)
	if _skin != null:
		_skin.pose(_sb.head, _head.transform)
		_skin.pose(_sb.jaw, _head.transform * _jaw.transform)
		for i in 4:
			if _joints[i] != null:
				_skin.pose_leg3(_sb["leg%d" % i], _joints[i])


# --- steering (pilot.gd): its behaviours ----------------------------------------

## eat {food}, groom, alert, thump, freeze {seconds}, flee {from}, birth {n}
## (a female's), nurse (a female's), mate {partner}.
func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["eat", "groom", "alert", "thump", "freeze", "flee"])
	if not young:
		b.append("mate")
		if not male:
			b.append_array(PackedStringArray(["birth", "nurse"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"eat":
			var f: Node3D = args.get("food")
			if f == null:
				return false
			eat(f)
		"groom":
			groom()
		"alert":
			alert()
		"thump":
			thump()
		"freeze":
			freeze(float(args.get("seconds", 6.0)))
		"flee":
			flee(args.get("from", _pos + _p_heading()))
		"birth":
			if young or male:
				return false
			birth(int(args.get("n", 4)))
		"nurse":
			if young or male or leverets.is_empty():
				return false
			nurse()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"eat", "groom", "alert", "thump", "freeze", "flee", "birth", "nurse":
			return _mode != name
	return false


func _p_act_secs(name: String) -> float:
	return 6.0 if name == "freeze" else -1.0


func _p_speed() -> float:
	return walk_speed * lerpf(0.35, 1.0, size)


func _p_reach() -> float:
	return 0.12 * size + 0.02


func _piloted() -> void:
	if _mode in ["wander", "idle", "alert"]:
		_mode = "piloted"
	_sit_to = 0.0
