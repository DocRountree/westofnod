class_name GilaMonster
extends "res://scripts/creatures/anole.gd" # (by path: found whether or not the editor has seen the class yet)
## A Gila monster (Heloderma suspectum), life size (its model in mm on the
## anole's make, Anole: its size the anole's 0.5 scaled up; an adult about
## 50 cm long, its tail a third of it): heavy, low slung, its legs short and
## stout, splayed, its toes short and thick, clawed; its head broad and
## blunt, its eyes small, black and beady; its tail short and fat (fat
## stored in it). Its whole hide beaded (shaders/render/gila.gdshader):
## black, in a broken net of pink, salmon and orange; its tail ringed. A
## hatchling (GilaMonster.new(true)): banded clean across, brighter;
## growing.
##
## Slow: an amble, its body swinging, its tail dragging, its forked tongue
## flicking out and in (tasting the air, the ground) as it goes. Most of
## its life in a burrow (GilaMonster.burrow()): out to forage, back in to
## rest (sleep: in, out of sight). It eats eggs and nestlings, young mice
## and rabbits: to them by smell, a bite, held, chewed (its venom worked in
## along its grooved teeth), swallowed whole. Threatened: its mouth gaping,
## hissing, its head and forequarters up (display). Its eggs, a few at a
## time, buried in a hole (lay: a clutch of five), hatching months later.
## Steering (pilot.gd): the anole's (hunt, display, lay, mate).

const GILA_SIZE := 1.85 ## (its make's size, grown: the anole's 0.5 is an anole's 17 cm)

var burrow_at := Vector3.INF ## (its burrow's mouth, if it has one: its parent's space)
var _tongue: Node3D
var _flick := 0.0
var _hidden := false


func _init(young_ := false) -> void:
	super(young_)
	set_frame(-24.0, -18.0, 46.0, 52.0, 92.0)
	legs = [
		{"hip": Vector3(6.2, -2.6, zs), "f": 7.5, "t": 6.5, "s": 4.0, "home": Vector2(15.5, zs - 3.0), "dangle": Vector3(9.0, -5.0, zs - 4.0), "pole": Vector3(0.4, 1.0, 0.6), "r": 3.0, "femur_r": 1.6},
		{"hip": Vector3(6.6, -2.6, zp), "f": 8.5, "t": 7.5, "s": 4.5, "home": Vector2(16.5, zp + 4.0), "dangle": Vector3(10.0, -5.0, zp + 5.0), "pole": Vector3(0.4, 1.0, -0.5), "r": 3.3, "femur_r": 1.7},
	]
	body_h = 7.0
	walk_speed = 0.06
	stride = 13.0
	step_time = 0.3
	mate_secs = 40.0
	adult_size = GILA_SIZE
	size = 0.6 if young_ else GILA_SIZE
	egg_scale = 5.0
	clutch = 5


## Its body: stout, broad, flattened; its tail thick at its root, blunt.
func _girth(z: float) -> Vector2:
	if z < zs:
		var k := (z - zn) / (zs - zn)
		return Vector2(lerpf(6.4, 8.0, k), lerpf(5.0, 6.2, k))
	if z < zp:
		var k := (z - zs) / (zp - zs)
		var bulge := sin(PI * k)
		return Vector2(8.0 + 3.0 * bulge, 6.2 + 2.0 * bulge)
	if z < zv + 2.0:
		var k := (z - zp) / (zv + 2.0 - zp)
		return Vector2(lerpf(8.0, 7.4, k), lerpf(6.2, 5.8, k))
	var t := (z - zv - 2.0) / (zt - zv - 2.0)
	var w := lerpf(7.4, 2.0, pow(t, 1.6))
	return Vector2(w, w * 0.82)


func _build() -> void:
	var shader: Shader = preload("res://shaders/render/gila.gdshader")
	_skin_mat = ShaderMaterial.new()
	_skin_mat.shader = shader
	_skin_mat.set_shader_parameter("skinned", true)
	_skin_mat.set_shader_parameter("count", SPINE)
	_skin_mat.set_shader_parameter("young", young)
	for k: String in ["zn", "seg", "zv", "zt"]:
		_skin_mat.set_shader_parameter(k, get(k))
	_paint = ShaderMaterial.new()
	_paint.shader = shader
	_paint.set_shader_parameter("young", young)
	_paint.set_shader_parameter("part", 1)
	var limb := _paint.duplicate() as ShaderMaterial
	limb.set_shader_parameter("part", 2)
	var toe_m := _paint.duplicate() as ShaderMaterial
	toe_m.set_shader_parameter("part", 3)
	_skin = MeshInstance3D.new()
	_skin.mesh = _tube()
	_skin.material_override = _skin_mat
	_skin.custom_aabb = AABB(Vector3(-400, -400, -400), Vector3(800, 800, 800))
	_body.add_child(_skin)
	# the head: broad, flat topped, blunt; its jaws heavy
	_head = Node3D.new()
	_body.add_child(_head)
	var hm := MeshInstance3D.new()
	hm.mesh = _loft([[1.5, 0.6, 6.6, 4.4], [-3.0, 1.0, 7.4, 4.4], [-8.0, 0.9, 6.9, 3.9], [-12.0, 0.4, 5.9, 3.2], [-15.0, -0.2, 4.6, 2.5], [-16.6, -0.6, 2.8, 1.8]], 2.4)
	hm.material_override = _paint
	_head.add_child(hm)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0.0, -1.8, -0.5)
	_head.add_child(_jaw)
	var jm := MeshInstance3D.new()
	jm.mesh = _loft([[1.0, -0.8, 6.2, 3.0], [-3.0, -1.0, 6.8, 3.0], [-8.0, -0.8, 6.0, 2.4], [-12.0, -0.4, 4.8, 1.8], [-15.0, 0.0, 3.4, 1.2], [-16.2, 0.2, 1.8, 0.7]], 2.4)
	jm.material_override = _paint
	_jaw.add_child(jm)
	_part(Vector3(0.0, 0.2, -7.0), Vector3(9.0, 0.7, 14.0), _mat(Color(0.62, 0.42, 0.45), 0.5), _jaw) # (inside: pale pink, seen as it gapes)
	# its forked tongue: dark, flicked out and in
	_tongue = Node3D.new()
	_tongue.position = Vector3(0.0, -0.9, -15.0)
	_head.add_child(_tongue)
	var tm := _mat(Color(0.22, 0.12, 0.18), 0.35)
	_stick(Vector3.ZERO, Vector3(0.0, 0.0, -6.0), 0.45, tm, _tongue)
	for side: float in [-1.0, 1.0]:
		_stick(Vector3(0.0, 0.0, -6.0), Vector3(1.0 * side, -0.2, -8.5), 0.28, tm, _tongue)
	_tongue.scale = Vector3(1.0, 1.0, 0.01)
	# its eyes small, black, beady, under a brow; the ear openings; the nostrils at its snout's tip
	var eye := _mat(Color(0.03, 0.025, 0.025), 0.05)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(5.0 * side, 1.8, -8.6), Vector3(2.0, 1.8, 2.4), _paint, _head)
		_part(Vector3(5.85 * side, 1.9, -8.6), Vector3(0.8, 1.15, 1.2), eye, _head)
		var lid := _part(Vector3(5.9 * side, 1.9, -8.6), Vector3(0.95, 1.3, 1.35), _paint, _head) # (shut, asleep)
		lid.visible = false
		_shut.append(lid)
		_part(Vector3(6.4 * side, 0.4, -1.0), Vector3(0.6, 1.5, 1.2), _mat(Color(0.03, 0.025, 0.02), 0.6), _head) # (the ear opening)
		_part(Vector3(1.6 * side, 0.6, -15.6), Vector3(0.6, 0.5, 0.5), _mat(Color(0.02, 0.02, 0.02), 0.6), _head)
	_dewlap = Node3D.new() # (none: the anole's)
	_head.add_child(_dewlap)
	_build_legs(limb, limb)
	# the toes: short, thick, each with a dark claw
	var claw := _mat(Color(0.05, 0.045, 0.04), 0.3)
	for i in 4:
		var hind := i >= 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var t := Node3D.new()
		_body.add_child(t)
		for k in 5:
			var a := deg_to_rad(-60.0 + 28.0 * k) * side
			var l := ([2.2, 3.4, 4.0, 4.2, 3.0][k] as float) * (1.15 if hind else 1.0)
			var d := Vector3(sin(a), 0.0, -cos(a))
			_stick(Vector3.ZERO, d * l, 0.75, toe_m, t)
			_stick(d * l, d * (l + 1.4) + Vector3(0.0, -0.4, 0.0), 0.32, claw, t)
		_toes.append(t)
	_place()
	_spine(0.0)


## A burrow's mouth in a low mound of dug earth, its origin on the ground
## at the mouth (its tunnel down along -z).
static func burrow(scale_ := 1.0) -> Node3D:
	var root := Node3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.62, 0.48, 0.34)
	earth.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.06, 0.045, 0.035)
	dark.roughness = 1.0
	for p: Array in [[Vector3(0.0, 0.0, -0.16), Vector3(0.5, 0.14, 0.42), earth], [Vector3(0.0, 0.0, 0.12), Vector3(0.36, 0.05, 0.3), earth],
			[Vector3(0.0, 0.035, -0.02), Vector3(0.13, 0.08, 0.06), dark]]:
		var mi := MeshInstance3D.new()
		mi.mesh = s
		mi.position = (p[0] as Vector3) * scale_
		mi.scale = (p[1] as Vector3) * scale_
		mi.material_override = p[2]
		root.add_child(mi)
	return root


## Asleep in its burrow, if it has one (to its mouth, in, out of sight, a
## while; out again), else where it is.
func sleep(secs := 30.0) -> void:
	super(secs)
	if burrow_at != Vector3.INF:
		_mode = "burrow"
		_stage = 0


func _think(dt: float) -> void:
	if _mode != "burrow" and _hidden: # (called out of its burrow by something else)
		_hidden = false
		visible = true
	if _mode == "burrow":
		_wait -= dt
		_st += dt
		match _stage:
			0: # (to its mouth, slowly)
				_target = burrow_at
				_pace = walk_speed
				if Vector2(burrow_at.x - _pos.x, burrow_at.z - _pos.z).length() < 0.06:
					_stage = 1
					_st = 0.0
			1: # (in: out of sight)
				_hidden = true
				visible = false
				_target = _pos
				if _wait <= 0.0:
					_stage = 2
					_st = 0.0
					_hidden = false
					visible = true
			2: # (out, a look round, off)
				_look_to = Vector2(0.4 * sin(_st * 1.5), 0.1)
				if _st > 3.0:
					wander(burrow_at, _radius)
		_flick_tongue(dt)
		return
	super(dt)
	if _mode == "wander" and _pace > 0.0: # (an amble, not the anole's dart)
		_pace = walk_speed * lerpf(0.5, 1.0, size / GILA_SIZE)
	if _mode == "display": # (its threat: gaping, hissing, its forequarters up)
		_jaw_open = 0.9
		_bob = 0.0
		_push = 0.8
		_dew_to = 0.0
	_flick_tongue(dt)


# (its tongue flicked out and in, going about, tasting: two or three
# quick flicks, then a while)
func _flick_tongue(dt: float) -> void:
	_flick += dt
	if _tongue == null:
		return
	var cyc := fmod(_flick, 2.4)
	var out := 0.0
	if _mode not in ["sleep", "burrow"] or _stage != 1:
		if cyc < 0.9:
			out = maxf(sin(fmod(cyc, 0.3) / 0.3 * PI), 0.0)
	_tongue.scale = Vector3(1.0, 1.0, maxf(out, 0.01))
	_tongue.visible = out > 0.02 and _jaw_open < 0.5
