class_name Items
## What can be carried: each kind of item, by id. The axe fells trees
## (Felling); the rest, for now, are only things to carry (/give in the chat;
## the pawpaw picked from its trees, the flowers and cattails where they grow:
## Foraging).
##
## Each: name, stack (how many fit in one slot or hand), and how it looks held
## (a primitive: shape, size in m, colour).

const KINDS := {
	"axe": {"name": "Axe", "stack": 1, "shape": "axe", "size": Vector3.ONE, "color": Color(0.55, 0.56, 0.58)},
	"stick": {"name": "Stick", "stack": 16, "shape": "cylinder", "size": Vector3(0.025, 0.55, 0.025), "color": Color(0.42, 0.3, 0.18)},
	"stone": {"name": "Stone", "stack": 16, "shape": "sphere", "size": Vector3(0.09, 0.07, 0.08), "color": Color(0.5, 0.49, 0.46)},
	"acorn": {"name": "Acorn", "stack": 32, "shape": "sphere", "size": Vector3(0.018, 0.026, 0.018), "color": Color(0.55, 0.38, 0.16)},
	"oak_leaf": {"name": "Oak leaf", "stack": 64, "shape": "box", "size": Vector3(0.07, 0.003, 0.11), "color": Color(0.3, 0.42, 0.14)},
	# fruit (PawpawTree, CrabappleTree: their trees bear them)
	"pawpaw": {"name": "Pawpaw", "stack": 1, "shape": "pawpaw", "size": Vector3(0.055, 0.11, 0.05), "color": Color(0.55, 0.62, 0.24)},
	"crabapple": {"name": "Crabapple", "stack": 32, "shape": "crabapple", "size": Vector3(0.026, 0.024, 0.026), "color": Color(0.72, 0.16, 0.1)},
	# flowers and cattails (GroundCover: picked where they grow, Foraging):
	# a stem, its head(s) the petals' colour round the disc's
	"susan": {"name": "Black-eyed Susan", "stack": 16, "shape": "flower", "size": Vector3(0.068, 0.5, 1.0), "color": Color(0.96, 0.7, 0.06), "disc": Color(0.17, 0.08, 0.04), "heads": 1},
	"fleabane": {"name": "Fleabane", "stack": 16, "shape": "flower", "size": Vector3(0.022, 0.45, 1.0), "color": Color(0.96, 0.95, 0.96), "disc": Color(0.95, 0.78, 0.12), "heads": 3},
	"coneflower": {"name": "Purple coneflower", "stack": 16, "shape": "flower", "size": Vector3(0.09, 0.5, 1.0), "color": Color(0.78, 0.42, 0.62), "disc": Color(0.42, 0.2, 0.06), "heads": 1},
	"aster": {"name": "Swamp aster", "stack": 16, "shape": "flower", "size": Vector3(0.028, 0.5, 1.0), "color": Color(0.6, 0.45, 0.85), "disc": Color(0.93, 0.72, 0.12), "heads": 4},
	"yampah": {"name": "Yampah", "stack": 16, "shape": "flower", "size": Vector3(0.04, 0.6, 1.0), "color": Color(0.95, 0.95, 0.9), "disc": Color(0.85, 0.86, 0.72), "heads": 3},
	# a pot to catch sap in (Tapping: under a maple's notch), and full
	"clay_pot": {"name": "Clay pot", "stack": 4, "shape": "pot", "size": Vector3(0.15, 0.15, 0.15), "color": Color(0.66, 0.38, 0.24)},
	"pot_of_sap": {"name": "Pot of maple sap", "stack": 1, "shape": "pot", "size": Vector3(0.15, 0.15, 0.15), "color": Color(0.66, 0.38, 0.24), "full": Color(0.78, 0.6, 0.3)},
	"cattail": {"name": "Cattail", "stack": 16, "shape": "cattail", "size": Vector3(0.024, 0.75, 0.16), "color": Color(0.36, 0.22, 0.12)},
}


static func exists(id: String) -> bool:
	return KINDS.has(id)


static func name_of(id: String) -> String:
	return KINDS[id].name if KINDS.has(id) else id


static func stack_of(id: String) -> int:
	return int(KINDS[id].stack) if KINDS.has(id) else 1


static func color_of(id: String) -> Color:
	return KINDS[id].color if KINDS.has(id) else Color.MAGENTA


## The item as held: a small model, centred on the grip.
static func model(id: String) -> Node3D:
	var k: Dictionary = KINDS.get(id, {"shape": "box", "size": Vector3.ONE * 0.05, "color": Color.MAGENTA})
	if k.shape == "axe":
		return _axe()
	if k.shape in ["pawpaw", "crabapple"]:
		return _fruit(k)
	if k.shape == "flower":
		return _flower(k)
	if k.shape == "cattail":
		return _cattail(k)
	if k.shape == "pot":
		return _pot(k)
	var mesh: PrimitiveMesh
	match k.shape:
		"cylinder":
			mesh = CylinderMesh.new()
			mesh.top_radius = 0.5
			mesh.bottom_radius = 0.5
			mesh.height = 1.0
			mesh.radial_segments = 8
		"sphere":
			mesh = SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 1.0
			mesh.radial_segments = 10
			mesh.rings = 6
		_:
			mesh = BoxMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = k.size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = k.color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## An axe, of stone: a stick for a handle, 60 cm, held a third of the way
## up; at its top a sharp stone, knapped to an edge, set in a split in it
## and lashed there with twine, wound round above and below it and across;
## the edge forward (-z).
static func _axe() -> Node3D:
	var root := Node3D.new()
	var wood := Color(0.47, 0.36, 0.24)
	# the stick: a little crooked, thicker at its foot, a knot or two
	var low := _part(CylinderMesh.new(), Vector3(0.03, 0.34, 0.03), wood)
	low.position.y = -0.03
	root.add_child(low)
	var high := _part(CylinderMesh.new(), Vector3(0.027, 0.32, 0.027), wood.darkened(0.06))
	high.position = Vector3(0.0, 0.29, 0.004)
	high.rotation.x = -0.03
	root.add_child(high)
	for k in [[Vector3(0.012, 0.08, 0.0), 0.012], [Vector3(-0.011, 0.25, 0.006), 0.01]]:
		var knot := _part(SphereMesh.new(), Vector3.ONE * float(k[1]), wood.darkened(0.25))
		knot.position = k[0]
		root.add_child(knot)
	# the stone: a flattened, tapering blade, its edge thinner and paler (knapped)
	var stone := Color(0.33, 0.32, 0.3)
	var head := _part(SphereMesh.new(), Vector3(0.032, 0.085, 0.16), stone)
	head.position = Vector3(0.0, 0.41, -0.035)
	(head.material_override as StandardMaterial3D).roughness = 0.75
	root.add_child(head)
	var edge := _part(SphereMesh.new(), Vector3(0.012, 0.075, 0.06), stone.lightened(0.25))
	edge.position = Vector3(0.0, 0.41, -0.1)
	(edge.material_override as StandardMaterial3D).roughness = 0.5
	root.add_child(edge)
	var butt := _part(SphereMesh.new(), Vector3(0.03, 0.06, 0.05), stone.darkened(0.1))
	butt.position = Vector3(0.0, 0.41, 0.035)
	root.add_child(butt)
	# the twine: wound round the stick above and below the stone, and across it
	var twine := Color(0.62, 0.52, 0.34)
	for y in [0.355, 0.37, 0.45, 0.465]:
		var wrap := _ring(0.019, 0.004, twine)
		wrap.position.y = y
		root.add_child(wrap)
	for a in [0.75, -0.75]:
		var cross := _ring(0.03, 0.0035, twine)
		cross.position = Vector3(0.0, 0.41, -0.003)
		cross.rotation = Vector3(0.0, 0.0, a) # (round the stone and the stick, crossing)
		cross.scale = Vector3(1.0, 1.0, 0.55)
		root.add_child(cross)
	return root


## A ring of twine (a torus): radius r, thickness t.
static func _ring(r: float, t: float, c: Color) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = r - t
	m.outer_radius = r + t
	m.rings = 12
	m.ring_segments = 5
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.95
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A clay pot (a lathe's round: a narrow foot, a full belly, a shoulder, a
## lip), its middle at the origin; with sap in it to near its shoulder if
## it's full.
static func _pot(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var h: float = k.size.y
	var prof := [Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.056, 0.012), Vector2(0.07, 0.05), Vector2(0.072, 0.088),
			Vector2(0.062, 0.122), Vector2(0.052, 0.138), Vector2(0.058, 0.15), Vector2(0.054, 0.15), Vector2(0.047, 0.138), Vector2(0.056, 0.12), Vector2(0.064, 0.088), Vector2(0.062, 0.05), Vector2(0.05, 0.016), Vector2(0.0, 0.012)] # (out, up the outside, over the lip, down the inside)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const N := 20
	for i in prof.size() - 1:
		var a: Vector2 = prof[i]
		var b: Vector2 = prof[i + 1]
		for j in N:
			var t0 := TAU * j / N
			var t1 := TAU * (j + 1) / N
			var q := [Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x), Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x),
					Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x), Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x)]
			for idx in [0, 2, 1, 0, 3, 2]:
				st.add_vertex((q[idx] as Vector3) * (h / 0.15) - Vector3.UP * h * 0.5)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = k.color
	mat.roughness = 0.9
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	if k.has("full"):
		var sap := _part(CylinderMesh.new(), Vector3(0.11, 0.004, 0.11) * (h / 0.15), k.full)
		sap.position.y = h * 0.3
		(sap.material_override as StandardMaterial3D).roughness = 0.08
		root.add_child(sap)
	return root


## A fruit: its body (a pawpaw's long, a little lopsided, green going
## yellow; a crabapple's a small round apple, red), and its stalk.
static func _fruit(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var body := _part(SphereMesh.new(), k.size, k.color)
	(body.material_override as StandardMaterial3D).roughness = 0.45 if k.shape == "crabapple" else 0.6
	root.add_child(body)
	if k.shape == "pawpaw":
		# lopsided: a second, smaller lobe to one side, and the dark scar at the stalk end
		var lobe := _part(SphereMesh.new(), k.size * Vector3(0.85, 0.7, 0.85), Color(0.6, 0.64, 0.26))
		lobe.position = Vector3(0.006, -0.02, 0.0)
		root.add_child(lobe)
		var scar := _part(CylinderMesh.new(), Vector3(0.012, 0.01, 0.012), Color(0.25, 0.2, 0.12))
		scar.position.y = k.size.y * 0.5
		root.add_child(scar)
	else:
		var stalk := _part(CylinderMesh.new(), Vector3(0.0025, 0.035, 0.0025), Color(0.35, 0.27, 0.15))
		stalk.position.y = k.size.y * 0.5 + 0.015
		stalk.rotation.z = 0.25
		root.add_child(stalk)
	return root


## A flower, picked: its stem (size.y long, held near its foot), and at
## its top a head or a few (size.x across): the petals a flat disc, the
## middle a small dome.
static func _flower(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var len: float = k.size.y
	var stem := _part(CylinderMesh.new(), Vector3(0.005, len, 0.005), Color(0.3, 0.42, 0.15))
	stem.position.y = len * 0.5 - 0.06
	root.add_child(stem)
	var n: int = k.get("heads", 1)
	var w: float = k.size.x
	for i in n:
		var a := TAU * i / n
		var off := Vector3(cos(a), 0.0, sin(a)) * (0.0 if n == 1 else w * 1.4)
		var top := Vector3(0.0, len - 0.06 + (0.0 if n == 1 else -0.02 * (i % 2)), 0.0) + off
		var petals := _part(CylinderMesh.new(), Vector3(w, 0.004, w), k.color)
		petals.position = top
		root.add_child(petals)
		var disc := _part(SphereMesh.new(), Vector3(w * 0.38, w * 0.3, w * 0.38), k.disc)
		disc.position = top + Vector3.UP * 0.003
		root.add_child(disc)
	return root


## A cattail, picked: its stalk (size.y long) and the brown head near its
## top (size.x across, size.z long), a thin spike above.
static func _cattail(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var len: float = k.size.y
	var stalk := _part(CylinderMesh.new(), Vector3(0.012, len, 0.012), Color(0.38, 0.45, 0.2))
	stalk.position.y = len * 0.5 - 0.1
	root.add_child(stalk)
	var head := _part(CylinderMesh.new(), Vector3(k.size.x, k.size.z, k.size.x), k.color)
	head.position.y = len - 0.1 - 0.06 - k.size.z * 0.5
	root.add_child(head)
	var spike := _part(CylinderMesh.new(), Vector3(0.004, 0.08, 0.004), Color(0.45, 0.4, 0.25))
	spike.position.y = len - 0.1 + 0.02
	root.add_child(spike)
	return root


static func _part(mesh: PrimitiveMesh, size: Vector3, c: Color) -> MeshInstance3D:
	if mesh is CylinderMesh:
		mesh.top_radius = 0.5
		mesh.bottom_radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 8
	elif mesh is SphereMesh:
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 12
		mesh.rings = 8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.6
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
