class_name FarFauna
extends Node3D
## The animals with no body, drawn all the same when they're near enough
## to be seen: far off, past their rings (FaunaSim). Each kind one
## MultiMesh, however many of it: a herd of bison on the plain, a flock on
## the wing, a few draw calls.
##
## A kind's far shape is its own body's: one made, once (out of sight),
## stood as it stands, its meshes taken as they're drawn (a skin in its
## skeleton's pose: Meal's baking) with their own materials, and it's
## freed. So it's the animal itself, standing, its legs still: sliding as
## it goes, at this distance. A bird going anywhere is on the wing: a body
## and two beating wings in its kind's tone (shaders/render/far_bird).
## None for the small (Species: far false: under 20 cm, the arthropods).
##
##   sim.far = FarFauna.new(); sim.add_child(sim.far)   # (FaunaSim.for_world does)
## reach(sp): how far off a kind's drawn (220 m for each metre of its
## length, 120 to 1200 m; a bird that flies three times as far, 350 m at the least).

const REACH_PER_M := 220.0
const REACH_MIN := 120.0
const REACH_MAX := 1200.0
const MAX_SURFACES := 20
const GROW := 32

var sim: FaunaSim
var shown := 0 ## how many are drawn far off now
var _kinds := {} # key -> {state: 0 none / 1 being made / 2 ready, body, wait, mm, wing, slots: Array, free: Array[int]}
var _holder: Node3D
var _sweep: Array = []
var _sweep_at := 0
var _moving := {} # agent id -> Agent: those to place every frame
static var _wing_mesh: ArrayMesh


func _ready() -> void:
	sim = get_parent() as FaunaSim
	_holder = Node3D.new() # (where a kind's one body is made, to take its shape from: deep out of sight)
	_holder.position = Vector3(0.0, -4000.0, 0.0)
	add_child(_holder)


func reach(sp: Dictionary) -> float:
	var r := clampf(float(sp.len) * REACH_PER_M, REACH_MIN, REACH_MAX)
	return maxf(r * 3.0, 350.0) if _winged(sp) else r # (a bird's seen further: on the wing, against the sky)


## (Whether a kind's shown on the wing when it goes any way: the birds, but the turkey.)
static func _winged(sp: Dictionary) -> bool:
	return String(sp["class"]) == "bird" and bool(sp.get("far_wing", true))


func _process(_dt: float) -> void:
	if sim == null or sim.space == null or sim.focus == Vector3.INF:
		return
	_making()
	# a few records looked at each frame: one near enough, with no body, drawn; one not, not
	if _sweep_at >= _sweep.size():
		_sweep = sim.agents.values()
		_sweep_at = 0
	for k in mini(64, _sweep.size() - _sweep_at):
		var a: FaunaSim.Agent = _sweep[_sweep_at]
		_sweep_at += 1
		var want := a.alive and a.body == null and bool(a.sp.far)
		if want:
			var p := sim.where(a)
			want = Vector2(p.x - sim.focus.x, p.z - sim.focus.z).length() < reach(a.sp) * sim.ring_scale
		if want and a.far < 0:
			_show(a)
		elif not want and a.far >= 0:
			release(a)
	# those going somewhere: where they are now
	for id: int in _moving.keys():
		var a: FaunaSim.Agent = _moving[id]
		if a.far < 0 or not a.alive:
			_moving.erase(id)
			continue
		_place(a)
		if a.doing != "go_to":
			_moving.erase(id)


## a no longer drawn far off (it has a body now; it's dead; it's gone).
func release(a: FaunaSim.Agent) -> void:
	if a.far < 0:
		return
	var K: Dictionary = _kinds.get(a.key, {})
	if not K.is_empty() and int(K.state) == 2:
		var none := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
		(K.mm as MultiMesh).set_instance_transform(a.far, none)
		if K.wing != null:
			(K.wing as MultiMesh).set_instance_transform(a.far, none)
		(K.slots as Array)[a.far] = null
		(K.free as Array).append(a.far)
		shown -= 1
	a.far = -1
	_moving.erase(a.id)


func _show(a: FaunaSim.Agent) -> void:
	if not _kinds.has(a.key):
		_kinds[a.key] = {"state": 0, "body": null, "wait": 0, "mm": null, "wing": null, "slots": [], "free": []}
	var K: Dictionary = _kinds[a.key]
	if int(K.state) != 2:
		return # (its shape's not made yet: _making)
	var free: Array = K.free
	if free.is_empty():
		var mm: MultiMesh = K.mm
		var n := mm.instance_count
		var keep := []
		for i in n:
			keep.append(mm.get_instance_transform(i))
		mm.instance_count = n + GROW
		var none := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
		for i in n + GROW:
			mm.set_instance_transform(i, keep[i] if i < n else none)
		if K.wing != null:
			var wm: MultiMesh = K.wing
			var keep_w := []
			for i in n:
				keep_w.append(wm.get_instance_transform(i))
			wm.instance_count = n + GROW
			for i in n + GROW:
				wm.set_instance_transform(i, keep_w[i] if i < n else none)
				wm.set_instance_custom_data(i, Color(randf(), 0.0, 0.0, 0.0))
		(K.slots as Array).resize(n + GROW)
		for i in range(n + GROW - 1, n - 1, -1):
			free.append(i)
	a.far = free.pop_back()
	(K.slots as Array)[a.far] = a
	shown += 1
	_place(a)
	if a.doing == "go_to":
		_moving[a.id] = a


## (Its place among those drawn: where it is, the way it faces; a bird
## going somewhere on the wing, up off the ground.)
func _place(a: FaunaSim.Agent) -> void:
	var K: Dictionary = _kinds[a.key]
	var p := sim.where(a)
	var size := 0.55 if a.young else 1.0
	var xf := Transform3D(Basis(Vector3.UP, a.yaw).scaled(Vector3.ONE * size), p)
	var none := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
	var flying: bool = K.wing != null and a.doing == "go_to" and a.p0.distance_to(a.p1) > 12.0 # (any way off: flown; a few steps: walked)
	if flying:
		var along := clampf((sim.now - a.t0) / maxf(a.t1 - a.t0, 0.01), 0.0, 1.0)
		xf.origin.y += sin(along * PI) * clampf(a.p0.distance_to(a.p1) * 0.25, 2.0, 25.0) + 0.5
		xf.basis = xf.basis.scaled(Vector3.ONE * float(K.wing_scale) * 1.6) # (the wing mesh a metre's bird: its kind's size)
		(K.wing as MultiMesh).set_instance_transform(a.far, xf)
		(K.mm as MultiMesh).set_instance_transform(a.far, none)
	else:
		(K.mm as MultiMesh).set_instance_transform(a.far, xf)
		if K.wing != null:
			(K.wing as MultiMesh).set_instance_transform(a.far, none)
	if a.doing == "go_to":
		_moving[a.id] = a


## (A kind's shape made: one of them at a time, a body put out of sight,
## left a few frames to stand, its meshes taken, freed.)
func _making() -> void:
	for key: String in _kinds:
		var K: Dictionary = _kinds[key]
		if int(K.state) == 1:
			K.wait = int(K.wait) - 1
			if int(K.wait) <= 0:
				_take(key, K)
			return
	for key: String in _kinds:
		var K: Dictionary = _kinds[key]
		if int(K.state) == 0:
			var c := Species.make(key, _holder, Vector3.ZERO, 0.0, false, false, {})
			if c == null:
				K.state = 3 # (none to be had)
				continue
			K.body = c # (left to stand a few frames: its legs under it, its skin in its pose)
			K.state = 1
			K.wait = 8
			return


func _take(key: String, K: Dictionary) -> void:
	var body: Creature = K.body
	K.body = null
	var mesh := bake(body) if is_instance_valid(body) else null
	if is_instance_valid(body):
		body.queue_free()
	if mesh == null or mesh.get_surface_count() == 0:
		K.state = 3
		return
	var sp := Species.of(key)
	var mi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3.ONE * -1e6, Vector3.ONE * 2e6) # (they're anywhere round the focus: never culled as one)
	sim.space.add_child(mi)
	K.mm = mm
	K.node = mi
	if _winged(sp):
		var wi := MultiMeshInstance3D.new()
		var wm := MultiMesh.new()
		wm.transform_format = MultiMesh.TRANSFORM_3D
		wm.use_custom_data = true
		wm.mesh = _wings()
		wi.multimesh = wm
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/render/far_bird.gdshader")
		m.set_shader_parameter("tone", sp.get("tone", Color(0.34, 0.31, 0.28)))
		m.set_shader_parameter("beat_hz", clampf(1.6 / maxf(float(sp.len), 0.1), 2.0, 9.0))
		wi.material_override = m
		wi.scale = Vector3.ONE # (the mesh is a metre's bird: each instance its kind's length)
		wi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wi.custom_aabb = AABB(Vector3.ONE * -1e6, Vector3.ONE * 2e6)
		sim.space.add_child(wi)
		K.wing = wm
		K.wing_node = wi
		K.wing_scale = float(sp.len)
	K.state = 2


func _exit_tree() -> void:
	for key: String in _kinds:
		var K: Dictionary = _kinds[key]
		for n in ["node", "wing_node"]:
			if K.get(n) != null and is_instance_valid(K[n]):
				(K[n] as Node).queue_free()


## A body's shape as it stands, one mesh (its own space), each surface its
## own material: its biggest MAX_SURFACES meshes (not the least: a claw,
## an eye), a skin in its skeleton's pose.
static func bake(body: Node3D) -> ArrayMesh:
	var mis: Array[MeshInstance3D] = []
	Meal._collect(body, mis)
	# (its shape about the point it stands on, where(): a walker's own origin is its body's middle, up off the ground)
	var foot := body.global_position
	if body is Creature and body.get_parent() is Node3D:
		foot = (body.get_parent() as Node3D).global_transform * (body as Creature).where()
	var inv := Transform3D(body.global_transform.basis.orthonormalized(), foot).affine_inverse()
	var parts := []
	for mi in mis:
		if not (mi.mesh is ArrayMesh or mi.mesh is PrimitiveMesh):
			continue
		var xf := inv * mi.global_transform
		var box := xf * mi.mesh.get_aabb()
		parts.append([box.size.length(), mi, xf])
	parts.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var whole := 0.0
	if not parts.is_empty():
		whole = parts[0][0]
	var out := ArrayMesh.new()
	for q: Array in parts:
		if out.get_surface_count() >= MAX_SURFACES or float(q[0]) < whole * 0.06:
			break
		var mi: MeshInstance3D = q[1]
		var xf: Transform3D = q[2]
		var nb := xf.basis.inverse().transposed()
		for s in mi.mesh.get_surface_count():
			if out.get_surface_count() >= MAX_SURFACES:
				break
			var arrays := Meal._posed(mi, mi.mesh.surface_get_arrays(s)).duplicate()
			var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if vs.is_empty():
				continue
			vs = vs.duplicate()
			for i in vs.size():
				vs[i] = xf * vs[i]
			arrays[Mesh.ARRAY_VERTEX] = vs
			if arrays[Mesh.ARRAY_NORMAL] != null:
				var ns: PackedVector3Array = (arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate()
				for i in ns.size():
					ns[i] = (nb * ns[i]).normalized()
				arrays[Mesh.ARRAY_NORMAL] = ns
			arrays[Mesh.ARRAY_BONES] = null
			arrays[Mesh.ARRAY_WEIGHTS] = null
			var prim := Mesh.PRIMITIVE_TRIANGLES
			if mi.mesh is ArrayMesh:
				prim = (mi.mesh as ArrayMesh).surface_get_primitive_type(s)
			out.add_surface_from_arrays(prim, arrays, [], {}, Meal._custom_flags(mi.mesh, s))
			var mat: Material = mi.material_override if mi.material_override else mi.get_active_material(s)
			if mat != null:
				out.surface_set_material(out.get_surface_count() - 1, mat)
	return out


## A metre's bird on the wing: a spindle, two wings (their beat the shader's).
static func _wings() -> ArrayMesh:
	if _wing_mesh != null:
		return _wing_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := [Vector3(0, 0, -0.5), Vector3(0.09, 0, -0.1), Vector3(0, 0.07, -0.1), Vector3(-0.09, 0, -0.1), Vector3(0, -0.06, -0.1), Vector3(0, 0, 0.5)]
	for tri: Array in [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [5, 2, 1], [5, 3, 2], [5, 4, 3], [5, 1, 4]]:
		for k: int in tri:
			st.set_color(Color(0.0, 0.0, 0.0, 0.6))
			st.set_normal(Vector3.UP)
			st.add_vertex(body[k])
	for side: float in [-1.0, 1.0]:
		var w := [Vector3(0.06 * side, 0.02, -0.25), Vector3(0.75 * side, 0.02, -0.12), Vector3(1.1 * side, 0.02, 0.1), Vector3(0.06 * side, 0.02, 0.2)]
		var outs := [0.0, 0.7, 1.0, 0.0]
		for tri: Array in [[0, 1, 3], [1, 2, 3]]:
			for k: int in tri:
				st.set_color(Color(1.0, outs[k], side, 1.0))
				st.set_normal(Vector3.UP)
				st.add_vertex(w[k])
	_wing_mesh = st.commit()
	return _wing_mesh
