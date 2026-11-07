class_name FoxSquirrel
extends "res://scripts/creatures/hare.gd" # (by path: found whether or not the editor has seen the class yet)
## An eastern fox squirrel (Sciurus niger), life size (about 27 cm head and
## body, its tail as long again): the biggest of our tree squirrels, on the
## hare's motor (its bounding, sitting up, grooming, the mating chase), its
## model the hare's measures scaled down (its mm are the hare's; size 0.3).
## One skin (MammalSkin): a long supple body, a round head, a short blunt
## muzzle, big dark eyes ringed pale, short rounded ears; short forelegs,
## the hind longer, long feet, sharp claws; the tail long and bushy, a chain
## of bones, carried up over its back in an S, streaming out behind as it
## runs, flicked. Its coat (carnivore.gdshader's species 10): grizzled grey
## brown above washed orange, its belly, cheeks, feet and the tail beneath
## rusty orange, the tail's hairs black banded, orange tipped round its edge.
## Its kits (FoxSquirrel.new(true)): born in its drey, pink, naked, blind;
## furred as they grow.
##
## - wander(centre, radius): bounding about, stopping, sitting up to look,
##   its tail flicking
## - eat(nut) (FoxSquirrel.nut()): to it, picked up in its teeth; sat up, held
##   in its forepaws at its mouth, turned, gnawed open, eaten
## - cache(nut, at): the nut carried in its mouth to at; a hole dug with its
##   forepaws, the nut pushed down in with its nose, earth scraped over it
##   and patted down; off
## - climb(tree, top): to the trunk (FoxSquirrel.tree()), up it in bounds, its
##   claws gripping, its tail out below; a while at the top, looking; down
##   again head first; off
## - flick(): its alarm: sat tall, its tail flicked over and over in waves,
##   chattering
## - groom(), alert(), freeze(secs), flee(from) (up the tree, if there is
##   one): the hare's, its own way
## - birth(n): (a female's) up into her drey (FoxSquirrel.drey(), at
##   `drey`), her kits born there; nurse(): back up to them
## - mate(her): the hare's chase, round and round; on her, briefly
## Steering (pilot.gd): act eat {food}, cache {nut, at}, climb {tree, top},
## flick, groom, alert, freeze {seconds}, flee {from}, birth {n}, nurse,
## mate {partner}.

const SQ_FORE := {"hip": Vector3(26.0, -30.0, -95.0), "f": 55.0, "t": 60.0, "s": 32.0, "home": Vector2(30.0, -110.0), "dangle": Vector3(24.0, -55.0, -145.0), "pole": Vector3(0.1, 0.0, 1.0), "r": 8.5, "femur_r": 1.9}
const SQ_HIND := {"hip": Vector3(38.0, -10.0, 100.0), "f": 82.0, "t": 88.0, "s": 92.0, "home": Vector2(42.0, 30.0), "dangle": Vector3(36.0, -48.0, 175.0), "pole": Vector3(0.2, 0.1, -1.0), "r": 11.0, "femur_r": 2.3}
const SQ_BODY := [[-150.0, 20.0, 30.0, 34.0], [-120.0, 15.0, 44.0, 50.0], [-60.0, 6.0, 52.0, 56.0], [10.0, 8.0, 55.0, 59.0],
		[80.0, 16.0, 58.0, 62.0], [125.0, 20.0, 54.0, 56.0], [150.0, 19.0, 36.0, 38.0], [160.0, 16.0, 12.0, 12.0]]
const SQ_HEAD := [[18.0, 0.0, 31.0, 31.0], [-8.0, 6.0, 42.0, 40.0], [-38.0, 4.0, 40.0, 36.0], [-60.0, -4.0, 30.0, 27.0], [-78.0, -9.0, 19.0, 17.0], [-86.0, -11.0, 9.0, 9.0]]
const TAIL_N := 9
const TAIL_SEG := 52.0 # (hare mm)
const TAIL_R := [18.0, 32.0, 44.0, 52.0, 57.0, 59.0, 57.0, 50.0, 36.0]
const SQ_EAR := 40.0

var tree_at := Vector3.INF ## its tree's foot (the trunk's middle, on the ground), if it has one
var tree_r := 0.12 ## its trunk's radius (m)
var drey := Vector3.INF ## its drey (its leaf nest, up its tree), if it has one
var kits: Array[Node3D] = [] ## (a female's) her young
var _tail_nodes: Array[Node3D] = []
var _climb := 0.0 # (how far up the trunk, m)
var _climb_to := 0.0
var _climbing := false
var _head_down := false # (coming down head first)
var _climb_a := 0.0 # (round the trunk: its way out from the trunk's middle)
var _climb_ph := 0.0
var _flick := 0.0
var _nut: Node3D
var _nut_at := Vector3.ZERO
var _mound: Node3D
var _naked := false
var _visit := "" # (up to its drey to give birth, or nurse)


func _init(young_ := false) -> void:
	super(young_)
	size = 0.055 if young_ else 0.3
	_g_to = size
	legs = [SQ_FORE, SQ_HIND]
	body_h = 92.0
	walk_speed = 1.6
	stride = 110.0
	mate_secs = 5.0
	_naked = young_


# --- its model -------------------------------------------------------------------

func _coat_mat(part: int, pale := 0.0) -> ShaderMaterial:
	var m := super(part, pale)
	m.set_shader_parameter("species", 10)
	m.set_shader_parameter("hair", 7.0)
	m.set_shader_parameter("ear_len", SQ_EAR)
	return m


func _build() -> void:
	var fur := _coat_mat(0)
	var ear := _coat_mat(1)
	_head = Node3D.new()
	_head.position = Vector3(0.0, 46.0, -140.0)
	_body.add_child(_head)
	var eye := _mat(Color(0.03, 0.025, 0.02), 0.03)
	eye.clearcoat_enabled = true
	eye.clearcoat = 0.7
	var ring := _coat_mat(0, 0.8) # (the pale ring round each eye)
	var ex := _surface_x(SQ_HEAD, -34.0, 14.0) - 3.0
	for side: float in [-1.0, 1.0]:
		_eyes.append(_part(Vector3(ex * side, 14.0, -34.0), Vector3(15.0, 19.0, 21.0), eye, _head))
		_part(Vector3((ex - 3.0) * side, 14.0, -34.0), Vector3(13.0, 24.0, 26.0), ring, _head)
		var lid := _part(Vector3(ex * side, 14.0, -34.0), Vector3(16.0, 20.0, 22.0), fur, _head)
		_lids.append(lid)
		_part(Vector3(10.0 * side, -8.0, -72.0), Vector3(17.0, 15.0, 20.0), fur, _head) # (its whisker pads)
	_nose = Node3D.new()
	_nose.position = Vector3(0.0, -8.0, -84.0)
	_head.add_child(_nose)
	var nose := _mat(Color(0.2, 0.14, 0.12), 0.35)
	_part(Vector3.ZERO, Vector3(11.0, 8.0, 7.0), nose, _nose)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0.0, -17.0, -54.0)
	_head.add_child(_jaw)
	var tooth := _mat(Color(0.86, 0.5, 0.18), 0.3) # (its incisors: orange)
	_stick(Vector3(-2.0, -16.0, -82.0), Vector3(-2.0, -23.0, -81.0), 2.0, tooth, _head)
	_stick(Vector3(2.0, -16.0, -82.0), Vector3(2.0, -23.0, -81.0), 2.0, tooth, _head)
	var wd := _mat(Color(0.1, 0.09, 0.08), 0.5)
	for side: float in [-1.0, 1.0]:
		var w := Node3D.new()
		w.position = Vector3(10.0 * side, -10.0, -80.0)
		_head.add_child(w)
		w.set_meta("side", side)
		for k in 5:
			var a := deg_to_rad(-20.0 + 10.0 * k)
			var d := Vector3(side * cos(a), sin(a) * 0.5, 0.35).normalized()
			_stick(Vector3.ZERO, d * (48.0 + 8.0 * sin(k * 1.3)), 0.25, wd, w)
		_whiskers.append(w)
	# the ears: short, rounded, upright
	for side: float in [-1.0, 1.0]:
		var e := Node3D.new()
		e.position = Vector3(17.0 * side, 30.0, -6.0)
		_head.add_child(e)
		e.set_meta("side", side)
		var em := MeshInstance3D.new()
		em.mesh = _round_ear()
		em.material_override = ear
		e.add_child(em)
		_ear_nodes.append(e)
	# the tail: a chain from the rump
	var prev: Node3D = _body
	for k in TAIL_N:
		var n := Node3D.new()
		n.position = Vector3(0.0, 22.0, 152.0) if k == 0 else Vector3(0.0, 0.0, TAIL_SEG)
		n.rotation.x = _tail_rest(k)
		prev.add_child(n)
		_tail_nodes.append(n)
		prev = n
	_tail = _tail_nodes[0]
	_build_legs(fur, fur)
	var claw := _mat(Color(0.12, 0.1, 0.08), 0.35)
	for i in 4:
		for q in 4:
			(_leg_mesh[i][q] as MeshInstance3D).mesh = null
		# (its claws, curved, at its toes: on the foot's bone, rigid)
		var tc := MeshInstance3D.new()
		_body.add_child(tc)
		tc.set_meta("claws", true)
		for k in (5 if i >= 2 else 4):
			var x := (float(k) - (2.0 if i >= 2 else 1.5)) * 4.5
			_stick(Vector3(x, 0.0, 0.0), Vector3(x * 1.1, -5.0, -6.0), 1.0, claw, tc)
		_claws.append(tc)
	_joints.resize(4)
	_build_skin(fur)


var _claws: Array[MeshInstance3D] = []
var _eyes: Array[MeshInstance3D] = []
var _lids: Array[MeshInstance3D] = []


## (Its tail at rest: up from its rump, then curving back over, its tip
## turned out.)
func _tail_rest(k: int) -> float:
	return [-1.3, 0.15, 0.2, 0.22, 0.2, 0.18, 0.12, 0.05, -0.05][k]


## A short rounded ear, up its y, open forward.
static func _round_ear() -> ArrayMesh:
	const RINGS := 7
	const ROUND := 12
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := func(i: int, k: int) -> Array:
		var t := float(i) / RINGS
		var hw := 14.0 * sin(PI * clampf(t * 0.85 + 0.15, 0.0, 1.0)) + 0.8
		var a := TAU * float(k % ROUND) / ROUND
		var x := sin(a) * hw
		var z := cos(a) * 3.5 - absf(sin(a)) * hw * 0.35 * (1.0 - absf(cos(a)))
		return [Vector3(x, t * SQ_EAR, z), Vector3(sin(a), 0.1, cos(a)).normalized()]
	for i in RINGS:
		for k in ROUND:
			var q := [ring.call(i, k), ring.call(i + 1, k), ring.call(i + 1, k + 1), ring.call(i, k + 1)]
			for tri: Array in [[0, 2, 1], [0, 3, 2]]:
				for c: int in tri:
					var v: Array = q[c]
					st.set_normal(v[1])
					st.add_vertex(v[0])
	return st.commit()


func _build_skin(mat: ShaderMaterial) -> void:
	var K: SkinScript = SkinScript.new()
	var torso := K.bone("torso", Transform3D())
	var hrest := _head.transform
	var head := K.bone("head", hrest)
	var jrest := hrest * _jaw.transform
	var jaw := K.bone("jaw", jrest)
	_sb = {"head": head, "jaw": jaw}
	K.body_head(torso, SQ_BODY, head, hrest, SQ_HEAD, 2.1)
	K.jaw_tube(head, jaw, jrest, [[0.0, -2.0, 11.0, 6.0], [-13.0, -2.0, 10.0, 5.5], [-26.0, -2.0, 6.0, 3.5]])
	var tb := []
	var trest := []
	var prev := Transform3D()
	for k in TAIL_N:
		prev = prev * _tail_nodes[k].transform
		trest.append(prev)
		tb.append(K.bone("tail%d" % k, prev))
	_sb["tail"] = tb
	K.tail_chain(torso, tb, trest, TAIL_R, TAIL_SEG, 0.8, 14)
	for i in 4:
		var L: Dictionary = legs[i / 2]
		var side := 1.0 if i % 2 == 1 else -1.0
		var hm: Vector2 = L.home
		var J := _leg3(i, Vector3(hm.x * side, -body_h, hm.y), Vector3.UP, Vector3.FORWARD, false, false)
		var bones := []
		for q in 3:
			bones.append(K.bone("leg%d_%d" % [i, q], SkinScript.along(J[q], J[q + 1])))
		_sb["leg%d" % i] = bones
		K.leg3(torso, bones, J, float(L.r), i >= 2, 2.2 if i >= 2 else 1.5, -1.0, i >= 2)
	_skin = K
	mat = mat.duplicate() as ShaderMaterial
	mat.set_shader_parameter("skin", true)
	_skin_m = mat
	var ex := _surface_x(SQ_HEAD, -34.0, 14.0) - 3.0
	mat.set_shader_parameter("bare_a", Vector3(-ex, 14.0, -34.0))
	mat.set_shader_parameter("bare_b", Vector3(ex, 14.0, -34.0))
	mat.set_shader_parameter("bare_r", 12.0)
	_torso = K.finish(_body, mat)
	_grow()


var _skin_m: ShaderMaterial


## (A kit: pink and naked till it's grown a little; its eyes shut till then.)
func _grow() -> void:
	var g := clampf((size - 0.09) / 0.08, 0.0, 1.0) if young else 1.0
	if _skin_m:
		_skin_m.set_shader_parameter("fur", g)
	for l in _lids:
		l.visible = young and g < 0.6
	for e in _ear_nodes:
		e.scale = Vector3.ONE * lerpf(0.4, 1.0, g)


# --- props -----------------------------------------------------------------------

## A nut (a hickory nut in its husk, or an acorn: about 2.5 cm): its origin under it.
static func nut() -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 10
	s.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.scale = Vector3(0.022, 0.024, 0.022)
	mi.position.y = 0.012
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.5, 0.38, 0.22)
	m.roughness = 0.55
	mi.material_override = m
	root.add_child(mi)
	var cap := MeshInstance3D.new()
	cap.mesh = s
	cap.scale = Vector3(0.024, 0.01, 0.024)
	cap.position.y = 0.022
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.34, 0.28, 0.18)
	cm.roughness = 0.9
	cap.material_override = cm
	root.add_child(cap)
	return root


## Its tree: a trunk (radius r, m), its bark, a few limbs up it, and its
## drey high in a fork (returned with it: [tree, the drey's place]).
static func tree(r := 0.12, h := 4.5) -> Array:
	var root := Node3D.new()
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.34, 0.29, 0.24)
	bark.roughness = 1.0
	var c := CylinderMesh.new()
	c.top_radius = r * 0.7
	c.bottom_radius = r * 1.1
	c.height = h
	c.radial_segments = 14
	var trunk := MeshInstance3D.new()
	trunk.mesh = c
	trunk.position.y = h * 0.5
	trunk.material_override = bark
	root.add_child(trunk)
	for k in 3: # (its limbs)
		var lc := CylinderMesh.new()
		lc.top_radius = r * 0.18
		lc.bottom_radius = r * 0.35
		lc.height = 1.4
		var limb := MeshInstance3D.new()
		limb.mesh = lc
		limb.material_override = bark
		var a := k * 2.3
		limb.position = Vector3(cos(a) * 0.5, h * (0.62 + 0.12 * k), sin(a) * 0.5)
		limb.rotation = Vector3(0.0, -a, 0.9)
		limb.rotation = Basis(Vector3(-sin(a), 0.0, cos(a)), 0.9).get_euler()
		root.add_child(limb)
	var at := Vector3(r * 0.9, h * 0.78, 0.0)
	var d := drey_nest()
	d.position = at
	root.add_child(d)
	return [root, at]


## A drey: a ball of leaves and twigs about 40 cm across, its way in at one side.
static func drey_nest() -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var leaf := SphereMesh.new()
	leaf.radius = 0.5
	leaf.height = 1.0
	leaf.radial_segments = 6
	leaf.rings = 3
	mm.mesh = leaf
	mm.instance_count = 160
	for i in 160:
		var p := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var at := p * 0.18 * rng.randf_range(0.85, 1.05)
		var t := p.cross(Vector3.UP if absf(p.y) < 0.9 else Vector3.RIGHT).normalized().rotated(p, rng.randf() * TAU)
		mm.set_instance_transform(i, Transform3D(Basis(t, p, t.cross(p)).orthonormalized() * Basis.from_scale(Vector3(0.07, 0.006, 0.05)), at))
		mm.set_instance_color(i, Color(0.45, 0.34, 0.2).darkened(rng.randf_range(0.0, 0.35)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	mmi.material_override = m
	root.add_child(mmi)
	return root


# --- its ways ----------------------------------------------------------------------

func eat(food: Node3D) -> void:
	super(food)
	_nut = null


func cache(nut_: Node3D, at: Vector3) -> void:
	if nut_ == null or not is_instance_valid(nut_):
		return
	_mode = "cache"
	_food = nut_
	_meal = null
	_nut_at = at
	_stage = 0
	_st = 0.0


func climb(tree_: Vector3 = Vector3.INF, top := 2.5) -> void:
	if tree_ != Vector3.INF:
		tree_at = tree_
	if tree_at == Vector3.INF:
		return
	_mode = "climb"
	_climb_to = top
	_stage = 0
	_st = 0.0


func flick() -> void:
	_mode = "flick"
	_st = 0.0


func flee(from: Vector3) -> void:
	if tree_at != Vector3.INF: # (up its tree)
		_flee_from = from
		climb(tree_at, 2.2)
		return
	super(from)


func birth(n := 3) -> void:
	if young or male:
		return
	_mode = "birth"
	_born_left = n
	_stage = 0
	_st = 0.0


func nurse() -> void:
	if kits.is_empty():
		return
	_mode = "nurse"
	_stage = 0
	_st = 0.0


func _think(dt: float) -> void:
	if young and size < 0.15: # (a kit in the drey: curled, still, growing)
		_target = _pos
		_crouch = 1.0
		_look_to = Vector2(0.0, -0.6)
		_grow()
		return
	match _mode:
		"eat":
			_common(dt)
			_eat_nut(dt)
			return
		"cache":
			_common(dt)
			_cache(dt)
			return
		"climb":
			_common(dt)
			_climb_up(dt)
			return
		"flick":
			_common(dt)
			_target = _pos
			_sit_to = 0.85
			_ears_to = 1.0
			_flick = 1.0
			_chew = 0.6 if fmod(_st, 1.2) < 0.5 else 0.0 # (chattering)
			_look_to = Vector2(0.5 * sin(_st * 0.9), 0.25)
			if _st > 6.0:
				_flick = 0.0
				_sit_to = 0.0
				wander(_pos if _centre == Vector3.ZERO else _centre, _radius)
			return
		"birth", "nurse":
			_common(dt)
			_drey_visit(dt)
			return
	_flick = move_toward(_flick, 0.0, dt)
	super(dt)


func _common(dt: float) -> void:
	_wait -= dt
	_st += dt
	_chew = move_toward(_chew, 0.0, dt * 3.0)
	_lick = move_toward(_lick, 0.0, dt * 3.0)
	_groom = move_toward(_groom, 0.0, dt * 3.0)
	_ears_to = 0.0
	if _mode not in ["climb"]:
		_pace = -1.0


## (A nut: gnawed where it lies, its head down to it, its mouth on each next
## bit; the nut not picked up, not moved.)
func _eat_nut(dt: float) -> void:
	if not is_instance_valid(_food):
		_sit_to = 0.0
		wander(_pos if _centre == Vector3.ZERO else _centre, _radius)
		return
	var p := _food.position
	var to := p - _pos
	to.y = 0.0
	var reach := 200.0 * MM * size
	match _stage:
		0:
			_target = p - to.normalized() * reach if to.length() > reach * 1.05 else _pos
			if to.length() <= reach * 1.2 and _speed < 0.05:
				_target = _pos
				_turn_to = atan2(-to.x, -to.z)
				MealScript.subdue(_food) # (a caterpillar, a mouse pup: bitten, still)
				_stage = 1
				_st = 0.0
		1: # (its head down to it)
			_target = _pos
			_look_to = Vector2(0.0, -0.7)
			_bite_look = -0.7
			if _st > 0.6:
				_stage = 2
				_st = 0.0
		2: # (gnawing it where it lies, its mouth on the next bit)
			_target = _pos
			_sit_to = 0.0
			_chew = 1.0
			if _meal == null: # (gnawed open and eaten, bit by bit)
				_meal = MealScript.of(_food, 1) # (a nut, a seed, an insect: one bite, gone)
			var mouth := _head.global_transform * Vector3(0.0, -22.0, -82.0)
			var na: Vector3 = _meal.call("next_at") if _meal else _food.global_position
			_bite_look = clampf(_bite_look + clampf((na.y - mouth.y) * 30.0, -1.5, 1.5) * dt, -1.2, 0.3)
			_look_to = Vector2(0.12 * sin(_st * 0.6), _bite_look)
			var off := Vector3(na.x - mouth.x, 0.0, na.z - mouth.z)
			if off.length() > 0.003:
				_pos += off.limit_length(0.05 * size * dt)
				_target = _pos
			if _meal:
				_meal.call("tear", 1.0, mouth)
			if _st > 12.0 or (_meal and float(_meal.call("left")) <= 0.0 and _st > 3.5):
				_food.queue_free()
				_food = null
				_sit_to = 0.0
				groom()


## (Burying it: carried to the spot, a hole dug, the nut pushed in with its
## nose, earth raked back over it, patted down.)
func _cache(dt: float) -> void:
	if not is_instance_valid(_food):
		wander(_pos, _radius)
		return
	var reach := 200.0 * MM * size
	match _stage:
		0: # (to the nut)
			var to := _food.position - _pos
			to.y = 0.0
			_target = _food.position - to.normalized() * reach if to.length() > reach * 1.05 else _pos
			if to.length() <= reach * 1.2 and _speed < 0.05:
				_stage = 1
				_st = 0.0
		1: # (in its mouth, off to the place)
			var to := _nut_at - _pos
			to.y = 0.0
			_target = _nut_at - to.normalized() * reach if to.length() > reach * 1.05 else _pos
			if to.length() <= reach * 1.2 and _speed < 0.05:
				_turn_to = atan2(-to.x, -to.z)
				_stage = 2
				_st = 0.0
		2: # (digging: its forepaws scrabbling by turns)
			_target = _pos
			_look_to = Vector2(0.0, -0.75)
			for i: int in [0, 1]:
				var side := 1.0 if i == 1 else -1.0
				var k := sin(_st * 14.0 + (PI if side > 0.0 else 0.0))
				_pose_foot[i] = Vector3(14.0 * side, -body_h + maxf(k, 0.0) * 18.0, -160.0 + k * 22.0)
			if _st > 3.0:
				_stage = 3
				_st = 0.0
				if _mound == null or not is_instance_valid(_mound):
					_mound = _dirt()
					get_parent().add_child(_mound)
				_mound.global_position = _nut_at
		3: # (the nut pushed down in with its nose)
			_target = _pos
			_look_to = Vector2(0.0, -1.0)
			_pose_foot[0] = null
			_pose_foot[1] = null
			if _st > 1.5:
				_food.global_position = _nut_at + Vector3.DOWN * 0.03
				_stage = 4
				_st = 0.0
		4: # (earth raked back over, patted down)
			_target = _pos
			_look_to = Vector2(0.0, -0.6)
			for i: int in [0, 1]:
				var side := 1.0 if i == 1 else -1.0
				var k := sin(_st * 9.0 + (PI if side > 0.0 else 0.0))
				_pose_foot[i] = Vector3(14.0 * side, -body_h + maxf(k, 0.0) * 10.0, -175.0 - k * 10.0)
			if _st > 2.5:
				_pose_foot[0] = null
				_pose_foot[1] = null
				if is_instance_valid(_food):
					_food.visible = false # (buried)
				_food = null
				_flick = 1.0
				wander(_pos if _centre == Vector3.ZERO else _centre, _radius)
	if _stage in [1, 2] and is_instance_valid(_food):
		_food.global_position = _head.global_transform * Vector3(0.0, -22.0, -82.0) + Vector3.DOWN * 0.012


static func _dirt() -> Node3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	mi.mesh = s
	mi.scale = Vector3(0.07, 0.012, 0.06)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.22, 0.15)
	m.roughness = 1.0
	mi.material_override = m
	var root := Node3D.new()
	root.add_child(mi)
	return root


## (Up its tree: to the trunk; up in bounds; a while there, looking about,
## its tail flicking; down head first; off.)
func _climb_up(dt: float) -> void:
	var to := tree_at - _pos
	to.y = 0.0
	match _stage:
		0: # (to its foot)
			var foot := tree_at - to.normalized() * (tree_r + 0.03)
			_target = Vector3(foot.x, _pos.y, foot.z)
			_pace = walk_speed * 1.6
			if to.length() < tree_r + 0.08:
				_target = _pos
				_climb_a = atan2(-to.x, -to.z) + PI # (its way out from the trunk: back toward where it came from)
				_climb = 0.0
				_climbing = true
				_head_down = false
				_stage = 1
				_st = 0.0
		1: # (up)
			_target = _pos
			_climb = move_toward(_climb, _climb_to, dt * 1.1)
			_climb_ph += dt * 3.2
			if _climb >= _climb_to - 0.01:
				_stage = 2
				_st = 0.0
		2: # (up there, looking about; or at her drey)
			_target = _pos
			if _visit != "":
				_look_to = Vector2(0.0, -0.4)
				_lick = 1.0
				if _visit == "birth" and _st > 3.0 and _born_left > 0:
					_born_left -= 1
					_st = 0.0
					_kit()
				if _st > (4.0 if _visit == "birth" else 10.0) and _born_left <= 0:
					_visit = ""
					_st = 5.0 # (a moment, then down)
				return
			_look_to = Vector2(0.6 * sin(_st * 0.7), 0.3)
			_flick = 0.6 if fmod(_st, 3.0) < 1.0 else 0.0
			if _st > 6.0:
				_head_down = true
				_stage = 3
				_st = 0.0
		3: # (down, head first)
			_target = _pos
			_climb = move_toward(_climb, 0.0, dt * 0.8)
			_climb_ph += dt * 2.6
			if _climb <= 0.01:
				_climbing = false
				_head_down = false
				var out := Vector3(sin(_climb_a), 0.0, cos(_climb_a))
				_pos = tree_at + out * (tree_r + 0.06)
				_pos.y = _ground(_pos.x, _pos.z)
				_yaw = atan2(out.x, out.z) + PI
				wander(_pos + out * 0.6, 0.6)


## (Her drey: up its tree to it; there her kits born, or nursed (at the
## top of the climb: _climb_up); then down.)
func _drey_visit(_dt: float) -> void:
	if drey == Vector3.INF or tree_at == Vector3.INF:
		_born_left = 0
		wander(_pos, _radius)
		return
	_visit = _mode
	climb(tree_at, drey.y - tree_at.y - 0.12)


## (Its kind's grown size.)
func _adult_size() -> float:
	return 0.3


func _kit() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var k: Node3D = (get_script() as Script).new(true)
	parent.add_child(k)
	var a := kits.size() * 2.1
	k.call("place", drey + Vector3(cos(a), -0.05, sin(a)) * 0.05, rng.randf() * TAU)
	k.set("ground_y", drey.y - 0.08) # (on the drey's floor: a height of its own, not a lambda of hers (gone with her, if she's taken))
	k.call("grow", _adult_size(), 900.0)
	k.set("_mother", self)
	kits.append(k)


var _mother: Node3D


# --- its motor: on the trunk -------------------------------------------------------

func _place() -> void:
	if not _climbing:
		super()
		return
	# (on the trunk's face: its belly to the bark, its head up, or down
	# coming down; out from the trunk's middle by its body's depth)
	var out := Vector3(sin(_climb_a), 0.0, cos(_climb_a))
	var fwd := Vector3.DOWN if _head_down else Vector3.UP
	var y := out
	var z := -fwd
	var x := y.cross(z).normalized()
	var at := tree_at + out * (tree_r * 0.92 + body_h * MM * size * 0.55) + Vector3.UP * (_climb + 0.12)
	transform = Transform3D(Basis(x, y, z), at)
	_body.scale = Vector3.ONE * MM * size


func _pose(dt: float) -> void:
	super(dt)
	# its tail: up over its back at rest, out behind running, streaming down
	# the trunk climbing; flicked in waves
	var run := clampf(_speed / 2.0, 0.0, 1.0)
	for k in _tail_nodes.size():
		var rest := _tail_rest(k)
		var a := lerpf(rest, -0.25 if k == 0 else 0.04, run)
		if _climbing:
			a = -0.15 if k == 0 else 0.03
		a += _flick * 0.35 * sin(_t * 11.0 - k * 0.9) * (0.3 + 0.7 * float(k) / TAIL_N)
		var sway := 0.12 * sin(_t * 1.3 - k * 0.5) * float(k) / TAIL_N
		_tail_nodes[k].rotation = Vector3(a, sway, 0.0)
	if _climbing: # (its claws in the bark: the fore and hind pairs by turns)
		for i in 4:
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hm: Vector2 = L.home
			var ph := _climb_ph * TAU * 0.5 + (0.0 if i < 2 else PI)
			var moving := _stage in [1, 3]
			var reach := 28.0 * sin(ph) if moving else 0.0
			var lift := maxf(cos(ph), 0.0) * 14.0 if moving else 0.0
			_pose_foot[i] = Vector3(hm.x * side * 1.25, -body_h + 6.0 + lift, hm.y - reach)


func _pose_legs() -> void:
	super()
	if _skin == null:
		return
	var prev := Transform3D()
	var tb: Array = _sb.tail
	for k in _tail_nodes.size():
		prev = prev * _tail_nodes[k].transform
		_skin.pose(tb[k], prev)
	for i in 4: # (its claws at its toes)
		var J: Array = _joints[i]
		if J == null or J.is_empty():
			continue
		var toe: Vector3 = J[3]
		var heel: Vector3 = J[2]
		var along := toe - heel
		along.y = 0.0
		var z := -(along.normalized() if along.length() > 1e-3 else Vector3.FORWARD)
		var x := Vector3.UP.cross(z).normalized()
		_claws[i].transform = Transform3D(Basis(x, Vector3.UP, z), toe)


# --- steering (pilot.gd) -----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := PackedStringArray(["eat", "cache", "climb", "flick", "groom", "alert", "freeze", "flee"])
	if not young:
		b.append("mate")
		if not male:
			b.append_array(PackedStringArray(["birth", "nurse"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"cache":
			if not args.has("nut"):
				return false
			cache(args.nut, args.get("at", _pos + _p_heading()))
			return true
		"climb":
			climb(args.get("tree", tree_at), float(args.get("top", 2.5)))
			return tree_at != Vector3.INF
		"flick":
			flick()
			return true
	return super(name, args)


func _p_act_done(name: String) -> bool:
	if name in ["cache", "climb", "flick"]:
		return _mode != name
	return super(name)
