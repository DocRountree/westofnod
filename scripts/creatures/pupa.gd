class_name Pupa
extends Node3D
## The lepidopterans' pupae, drawn at twice life size, and their hatching
## (eclosion). Each shell one smooth loft, painted by pupa.gdshader:
## - monarch: the chrysalis, a jade lantern hanging from its black stalk
##   (the cremaster, hooked into a pad of silk) under a twig or a leaf: the
##   abdomen a dome narrowing up to the stalk, the wing cases below it
##   plump, rounded at the bottom; between them the black band of the
##   "crown", gold along it, gold spots on the wing cases and near the top
## - hemaris: the clearwing's, lying in the litter, its front up, in a loose
##   ragged cocoon of silk with bits of leaf in it: a glossy mahogany
##   spindle, the abdomen ringed, ending in a short spike; the wing cases'
##   outline, the tongue's sheath down the front, spiracles along each side;
##   now and then it twitches
## eclose(after): it ripens (the monarch's going dark and clear, the
## wings' orange and black showing through the cases; the clearwing's
## darkening), wriggles, splits along the front and is left an empty skin,
## pale and see-through; the adult (a Monarch or a HummingbirdMoth: added
## to this one's parent) pushes out (the monarch head first, down; the
## clearwing out of the front of its cocoon), turns or climbs to hang (the
## monarch beneath its empty case, head up; the clearwing up its perch, or
## onto its cocoon), its abdomen swollen, its crumpled wings hanging down
## and pumped out to their full size, then dried, opened and closed: then
## off, after.call(adult) (Lepidoptera.emerge). Cheap: a loft or two.
## Its origin: the monarch's, the stalk's top (hang it there); the
## clearwing's, the ground under its middle, its head toward -z.
##
## And the rest (no shader of their own: plain, painted with parts):
## - lady: the lady beetle's, glued by its tail to where its larva stopped,
##   hunched, its front raised: orange, black spots over its back, its
##   larval skin bunched dark at its tail. Out: a lady beetle (colony's:
##   Beetles.add), the case left pale and empty
## - june: the June bug's, on its back in its cell in the soil: creamy, its
##   legs folded on its front, its wing pads at its sides. Out: a June bug
##   (colony's), the skin left pale
## - wasp: the paper wasp's: only its cell's cap to see, a white dome of
##   silk over the cell's mouth (its origin). Out: the cap chewed open and
##   gone, a wasp (Wasp) out of the cell and down beside it
## - carpenter: the carpenter ant's, in its tan cocoon, lying. Out: a worker
##   (colony's: AntColony.add), the cocoon left
## - harvester: the red harvester's, bare: white, its legs and antennae
##   folded on it, lying. Out: a worker (colony's), the skin left pale
## Their origin the ground under their middle, the head toward -z (the
## lady's: where its tail's glued; the wasp's: its cell's mouth). colony:
## the colony its adult joins (an AntColony, Beetles).

const MM := 0.002
const MONARCH := preload("res://scripts/creatures/monarch.gd")
const MOTH := preload("res://scripts/creatures/hummingbird_moth.gd")
# the shells: along them (mm), their half width and half depth (front to back)
const MONARCH_SHELL := [[0.0, 0.4, 0.4], [1.5, 1.6, 1.5], [3.0, 3.3, 3.0], [5.5, 4.7, 4.3], [8.0, 5.3, 4.9], [9.5, 5.5, 5.1],
		[12.0, 5.9, 5.5], [16.0, 6.0, 5.7], [20.0, 5.5, 5.3], [23.0, 4.2, 4.0], [25.0, 2.4, 2.3], [26.0, 0.3, 0.3]]
const MOTH_SHELL := [[0.0, 0.4, 0.4], [1.0, 2.6, 2.4], [3.0, 4.0, 3.7], [8.0, 4.5, 4.1], [13.0, 4.3, 3.9], [16.0, 3.9, 3.5],
		[19.0, 3.1, 2.8], [22.0, 2.0, 1.8], [24.0, 1.0, 0.9], [25.5, 0.25, 0.25]]

var kind := "monarch"
var adult: Node3D ## once out (the others': their colony)
var colony: Node ## (the lady's, the June bug's, the ants': the colony its adult joins)
var _shell: MeshInstance3D
## where the clearwing climbs to, to hang and dry (its parent's space; INF:
## onto its cocoon), and the way the perch faces there
var perch_at := Vector3.INF
var perch_normal := Vector3.BACK
var _mat: ShaderMaterial
var _state := "" # "", "ripening", "out"
var _t := 0.0
var _twitch := 0.0
var _body: Node3D
var _after := Callable()


func _init(k := "monarch") -> void:
	kind = k


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/render/pupa.gdshader")
	_mat.set_shader_parameter("kind", 0 if kind == "monarch" else 1)
	var shell := MeshInstance3D.new()
	shell.material_override = _mat
	_body.add_child(shell)
	_shell = shell
	if kind != "monarch" and kind != "hemaris":
		_mat = null
		_build_other(shell)
	elif kind == "monarch":
		# the stalk, black, then the case hanging from it down -y, its
		# front +z
		var stalk := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5 * MM
		cyl.bottom_radius = 0.35 * MM
		cyl.height = 3.0 * MM
		cyl.radial_segments = 6
		stalk.mesh = cyl
		stalk.position = Vector3(0.0, -1.5 * MM, 0.0)
		stalk.material_override = _plain(Color(0.03, 0.03, 0.03), 0.4)
		_body.add_child(stalk)
		shell.mesh = _loft(MONARCH_SHELL, Vector3(0.0, -3.0, 0.0), Vector3.DOWN, Vector3.RIGHT, Vector3.BACK)
	else: # (the clearwing's)
		# lying, head to -z, its front up; the spike at its tail
		var half: float = (MOTH_SHELL[MOTH_SHELL.size() - 1] as Array)[0] * 0.5
		shell.mesh = _loft(MOTH_SHELL, Vector3(0.0, 4.2, -half), Vector3.BACK, Vector3.RIGHT, Vector3.UP)
		var spike := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.35 * MM
		cone.height = 2.0 * MM
		cone.radial_segments = 6
		spike.mesh = cone
		spike.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		spike.position = Vector3(0.0, 4.0, half + 0.8) * MM
		spike.material_override = _plain(Color(0.15, 0.07, 0.03), 0.3)
		_body.add_child(spike)
		# the cocoon: loose, ragged silk (a few see-through bags, offset),
		# bits of leaf caught in it
		var silk := _plain(Color(0.86, 0.83, 0.74, 0.28), 0.9)
		silk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		silk.cull_mode = BaseMaterial3D.CULL_DISABLED
		var sphere := SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 12
		sphere.rings = 7
		for b in [[Vector3(0.0, 4.5, 0.0), Vector3(14.0, 10.5, 30.0)], [Vector3(1.2, 5.0, -3.0), Vector3(12.0, 9.0, 22.0)], [Vector3(-1.0, 4.0, 4.0), Vector3(11.0, 8.0, 20.0)]]:
			var bag := MeshInstance3D.new()
			bag.mesh = sphere
			bag.position = (b[0] as Vector3) * MM
			bag.scale = (b[1] as Vector3) * MM
			bag.material_override = silk
			add_child(bag) # (not on _body: the cocoon stays still as the pupa twitches)
		var litter := _plain(Color(0.4, 0.28, 0.14), 0.9)
		litter.cull_mode = BaseMaterial3D.CULL_DISABLED
		for b in [[Vector3(5.0, 8.5, -6.0), 0.5], [Vector3(-5.5, 7.0, 7.0), -0.7], [Vector3(1.0, 10.0, 9.0), 0.2]]:
			var bit := MeshInstance3D.new()
			bit.mesh = sphere
			bit.position = (b[0] as Vector3) * MM
			bit.scale = Vector3(7.0, 0.3, 4.5) * MM
			bit.rotation = Vector3(0.3, float(b[1]), float(b[1]) * 0.6)
			bit.material_override = litter
			add_child(bit)


## (The others' shells and parts.)
func _build_other(shell: MeshInstance3D) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 7
	var part := func(at: Vector3, size: Vector3, c: Color, rough := 0.5, rot := Vector3.ZERO) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.position = at * MM
		mi.scale = size * MM
		mi.rotation = rot
		mi.material_override = _plain(c, rough)
		_body.add_child(mi)
		return mi
	match kind:
		"lady":
			# glued by its tail, hunched, its front raised up and forward
			var keys := [[0.0, 0.3, 0.3], [0.8, 1.5, 1.3], [2.2, 2.3, 2.0], [3.8, 2.6, 2.3], [5.2, 2.3, 2.1], [6.2, 1.5, 1.3], [6.8, 0.3, 0.3]]
			var along := Vector3(0.0, 0.55, -0.83)
			shell.mesh = _loft(keys, Vector3(0.0, 0.6, 0.0), along, Vector3.RIGHT, Vector3(0.0, 0.83, 0.55))
			shell.material_override = _plain(Color(0.93, 0.47, 0.1), 0.35)
			var back := Vector3(0.0, 0.83, 0.55)
			for sp: Array in [[2.4, 0.0], [3.6, -1.1], [3.6, 1.1], [4.8, -0.7], [4.8, 0.7], [1.6, -1.3], [1.6, 1.3]]:
				var at: Vector3 = Vector3(0.0, 0.6, 0.0) + along * float(sp[0]) + Vector3.RIGHT * float(sp[1]) + back * 2.05
				part.call(at, Vector3(0.9, 0.35, 0.9), Color(0.04, 0.03, 0.03), 0.35, Vector3(-0.6, 0.0, 0.0))
			part.call(Vector3(0.0, 0.5, 0.4), Vector3(3.6, 1.6, 2.4), Color(0.12, 0.12, 0.13), 0.7) # (its larval skin, bunched at its tail)
		"june":
			# on its back in its cell: creamy, its legs folded on its front
			var keys := [[0.0, 0.4, 0.4], [2.0, 4.0, 3.4], [6.0, 5.2, 4.4], [12.0, 5.5, 4.6], [17.0, 5.0, 4.2], [21.0, 3.2, 2.7], [22.5, 0.4, 0.4]]
			shell.mesh = _loft(keys, Vector3(0.0, 4.6, -11.0), Vector3.BACK, Vector3.RIGHT, Vector3.UP)
			shell.material_override = _plain(Color(0.88, 0.78, 0.56), 0.4)
			for k in 5: # (the abdomen's segments: a faint fold between each)
				var z := 2.0 + 2.2 * k
				var hw: float = lerpf(5.2, 3.6, k / 4.0)
				part.call(Vector3(0.0, 4.6, z), Vector3(hw * 2.04, hw * 1.74, 0.5), Color(0.74, 0.62, 0.42), 0.5)
			for k in 3: # (the legs, folded on its front: up, on its back)
				for side: float in [-1.0, 1.0]:
					part.call(Vector3(2.2 * side, 8.6, -5.0 + 2.6 * k), Vector3(1.5, 1.0, 5.0), Color(0.82, 0.7, 0.48), 0.4, Vector3(0.0, 0.25 * side, 0.0))
			for side: float in [-1.0, 1.0]: # (its wing pads, along its sides)
				part.call(Vector3(4.2 * side, 6.4, -2.0), Vector3(1.8, 3.0, 9.0), Color(0.84, 0.74, 0.52), 0.4)
			part.call(Vector3(0.0, 6.0, -10.0), Vector3(4.0, 3.5, 3.0), Color(0.78, 0.6, 0.36), 0.35) # (its head)
		"carpenter":
			# its cocoon: tan, lying, a dark spot at its tail end
			var keys := [[0.0, 0.4, 0.4], [1.5, 2.4, 2.4], [4.0, 3.2, 3.2], [7.0, 3.1, 3.1], [9.0, 2.2, 2.2], [10.0, 0.3, 0.3]]
			shell.mesh = _loft(keys, Vector3(0.0, 3.2, -5.0), Vector3.BACK, Vector3.RIGHT, Vector3.UP)
			shell.material_override = _plain(Color(0.8, 0.67, 0.46), 0.85)
			part.call(Vector3(0.0, 3.2, 4.7), Vector3(1.6, 1.6, 0.8), Color(0.15, 0.1, 0.06), 0.6)
		"harvester":
			# bare: white, head, thorax and gaster, legs folded under
			var keys := [[0.0, 0.3, 0.3], [1.0, 1.4, 1.3], [2.5, 1.3, 1.2], [3.4, 0.9, 0.8], [4.2, 1.7, 1.6], [6.0, 1.9, 1.8], [7.4, 0.4, 0.4]]
			shell.mesh = _loft(keys, Vector3(0.0, 1.9, -3.7), Vector3.BACK, Vector3.RIGHT, Vector3.UP)
			shell.material_override = _plain(Color(0.95, 0.92, 0.85), 0.45)
			for k in 3:
				for side: float in [-1.0, 1.0]:
					part.call(Vector3(1.1 * side, 1.0, -1.2 + 1.0 * k), Vector3(0.5, 0.4, 1.8), Color(0.92, 0.88, 0.8), 0.45, Vector3(0.0, 0.4 * side, 0.0))
		"wasp":
			# its cell's cap: a white dome of silk over the mouth
			shell.mesh = sphere
			shell.scale = Vector3(6.4, 2.6, 6.4) * MM
			shell.position = Vector3(0.0, 0.5, 0.0) * MM
			shell.material_override = _plain(Color(0.96, 0.95, 0.92), 0.9)


## A smooth shell lofted through keys ([along, half width, half depth],
## mm) from `start` along `along`, its width across `across`, its front
## `front` (mm, the pupa's space): UV.x along (0 .. 1), UV.y round (0.5 its
## front, 0 and 1 its back).
static func _loft(keys: Array, start: Vector3, along: Vector3, across: Vector3, front: Vector3) -> ArrayMesh:
	const RINGS := 40
	const ROUND := 20
	var total: float = (keys[keys.size() - 1] as Array)[0]
	var at := func(t: float) -> Vector2: # (half width, half depth at t: the keys eased between)
		for j in keys.size() - 1:
			var k0: Array = keys[j]
			var k1: Array = keys[j + 1]
			if t <= float(k1[0]) or j == keys.size() - 2:
				var f := clampf((t - float(k0[0])) / maxf(float(k1[0]) - float(k0[0]), 1e-5), 0.0, 1.0)
				f = f * f * (3.0 - 2.0 * f)
				return Vector2(lerpf(k0[1], k1[1], f), lerpf(k0[2], k1[2], f))
		return Vector2.ZERO
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vert := func(i: int, k: int) -> Array:
		var t := total * float(i) / RINGS
		var r: Vector2 = at.call(t)
		var dr: Vector2 = (at.call(minf(t + 0.2, total)) - at.call(maxf(t - 0.2, 0.0))) / 0.4
		var th := TAU * float(k) / ROUND
		var p := start + along * t + across * sin(th) * r.x - front * cos(th) * r.y
		var n := (across * sin(th) / maxf(r.x, 0.05) - front * cos(th) / maxf(r.y, 0.05)).normalized()
		n = (n - along * (dr.x + dr.y) * 0.5).normalized()
		return [p * MM, n, Vector2(t / total, float(k) / ROUND)]
	for i in RINGS:
		for k in ROUND:
			var q := [vert.call(i, k), vert.call(i + 1, k), vert.call(i + 1, k + 1), vert.call(i, k + 1)]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var A: Array = q[tri[0]]
				var B: Array = q[tri[1]]
				var C: Array = q[tri[2]]
				# (a front face clockwise: its normal along -cross(b - a, c - a); turned to face out)
				var face := -((B[0] as Vector3) - (A[0] as Vector3)).cross((C[0] as Vector3) - (A[0] as Vector3))
				var out := (A[1] as Vector3) + (B[1] as Vector3) + (C[1] as Vector3)
				var order := [A, B, C] if face.dot(out) >= 0.0 else [A, C, B]
				for v: Array in order:
					st.set_normal(v[1])
					st.set_uv(v[2])
					st.add_vertex(v[0])
	return st.commit()


static func _plain(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


## Ripening, splitting, the adult out: see the top.
func eclose(after := Callable()) -> void:
	if _state != "":
		return
	_state = "ripening"
	_t = 0.0
	_after = after


func _process(dt: float) -> void:
	_t += dt
	if _state == "ripening":
		var ripe := clampf(_t / 3.5, 0.0, 1.0)
		if _mat:
			_mat.set_shader_parameter("ripe", ripe)
		# working inside it: wriggling, more as it ripens
		var w := ripe * ripe
		if kind == "monarch":
			_body.rotation = Vector3(sin(_t * 7.0) * 0.05 * w, sin(_t * 3.1) * 0.15 * w, sin(_t * 9.0) * 0.04 * w)
		elif kind != "wasp":
			_body.rotation = Vector3(0.0, sin(_t * 8.0) * 0.07 * w, 0.0)
		if _t > 4.2:
			_split()
	elif _state == "":
		# the clearwing's twitching now and then, the bare pupae's (the
		# monarch's still, the cocoon and the capped cell too)
		if kind in ["hemaris", "june", "harvester", "lady"]:
			_twitch -= dt
			if _twitch <= 0.0:
				_twitch = randf_range(3.0, 7.0)
			_body.rotation.y = sin((0.6 - _twitch) * 18.0) * 0.08 if _twitch < 0.6 else 0.0


## The case split along its front, left empty (pale, see-through); the
## adult out of it.
func _split() -> void:
	_state = "out"
	_body.rotation = Vector3.ZERO
	if _mat:
		_mat.set_shader_parameter("empty", true)
	var parent := get_parent() as Node3D
	if parent == null:
		return
	if kind != "monarch" and kind != "hemaris":
		_out_other(parent)
		return
	var a: Node3D
	var b := global_transform.basis
	var to := func(local_mm: Vector3) -> Vector3: return parent.to_local(global_transform * (local_mm * MM))
	if kind == "monarch":
		a = MONARCH.new()
		parent.add_child(a)
		var front := (b * Vector3.BACK).normalized()
		# out head first, down, from inside the wing cases; then turned
		# head up, hanging beneath the empty case from it
		a.call("place", to.call(Vector3(0.0, -20.0, 0.0)))
		a.call("emerge", to.call(Vector3(0.0, -40.0, 2.0)), front, (b * Vector3.UP).normalized(), _done.bind(a),
				to.call(Vector3(0.0, -20.0, 0.0)), (b * Vector3.DOWN).normalized(), front)
	else:
		a = MOTH.new()
		parent.add_child(a)
		var fwd := (b * Vector3.FORWARD).normalized()
		var at: Vector3
		var n: Vector3
		if perch_at != Vector3.INF:
			at = perch_at
			n = perch_normal.normalized()
		else:
			at = to.call(Vector3(0.0, 12.0, 0.0))
			n = Vector3.UP
		# out of the front of its cocoon, crawling; then up its perch
		var head := Vector3.UP if absf(n.y) < 0.7 else fwd
		a.call("place", to.call(Vector3(0.0, 4.0, -6.0)))
		a.call("emerge", at, n, head, _done.bind(a), to.call(Vector3(0.0, 4.0, -6.0)), fwd, Vector3.UP)
	adult = a


## (The others out: the case left empty, pale (the cocoon as it is, the
## cap gone); the adult: a colony's, there, off about its ways; or a wasp,
## up out of its cell and down beside it.)
func _out_other(parent: Node3D) -> void:
	if kind == "wasp":
		_shell.visible = false # (chewed open)
		var w: Node3D = load("res://scripts/creatures/wasp.gd").new()
		parent.add_child(w)
		w.call("place", global_position + Vector3.UP * 0.01)
		var a := randf() * TAU
		w.call("land", global_position + Vector3(cos(a), 0.0, sin(a)) * 0.03 + Vector3.DOWN * 0.012, Vector3.UP)
		adult = w
		_done(w)
		return
	if kind != "carpenter":
		var pale := _plain(Color(0.9, 0.85, 0.72, 0.45), 0.6)
		pale.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shell.material_override = pale
	if is_instance_valid(colony) and colony.has_method("add"):
		var fwd := (global_transform.basis * Vector3.FORWARD).normalized()
		var at := (colony as Node3D).to_local(global_position + fwd * 0.004)
		colony.call("add", Vector3(at.x, 0.0, at.z), atan2(-fwd.x, -fwd.z), 0.06)
		adult = colony as Node3D
		_done(adult)


func _done(a: Node3D) -> void:
	if _after.is_valid():
		_after.call(a)
