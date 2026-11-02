class_name Items
## What can be carried: each kind of item, by id. The axe fells trees
## (Felling); the rest, for now, are only things to carry (/give in the chat:
## there is nothing in the world to pick up yet).
##
## Each: name, stack (how many fit in one slot or hand), and how it looks held
## (a primitive: shape, size in m, colour).

const KINDS := {
	"axe": {"name": "Axe", "stack": 1, "shape": "axe", "size": Vector3.ONE, "color": Color(0.55, 0.56, 0.58)},
	"stick": {"name": "Stick", "stack": 16, "shape": "cylinder", "size": Vector3(0.025, 0.55, 0.025), "color": Color(0.42, 0.3, 0.18)},
	"stone": {"name": "Stone", "stack": 16, "shape": "sphere", "size": Vector3(0.09, 0.07, 0.08), "color": Color(0.5, 0.49, 0.46)},
	"acorn": {"name": "Acorn", "stack": 32, "shape": "sphere", "size": Vector3(0.018, 0.026, 0.018), "color": Color(0.55, 0.38, 0.16)},
	"oak_leaf": {"name": "Oak leaf", "stack": 64, "shape": "box", "size": Vector3(0.07, 0.003, 0.11), "color": Color(0.3, 0.42, 0.14)},
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


## An axe: an ash handle 70 cm long, held a third of the way up, and a steel
## head across its top, the blade forward (-z).
static func _axe() -> Node3D:
	var root := Node3D.new()
	var handle := _part(CylinderMesh.new(), Vector3(0.032, 0.7, 0.032), Color(0.6, 0.45, 0.28))
	handle.position.y = 0.12
	root.add_child(handle)
	var head := _part(BoxMesh.new(), Vector3(0.03, 0.075, 0.17), Color(0.42, 0.43, 0.45))
	head.position = Vector3(0.0, 0.43, -0.045)
	root.add_child(head)
	var edge := _part(BoxMesh.new(), Vector3(0.022, 0.11, 0.025), Color(0.75, 0.76, 0.78))
	edge.position = Vector3(0.0, 0.43, -0.135)
	root.add_child(edge)
	return root


static func _part(mesh: PrimitiveMesh, size: Vector3, c: Color) -> MeshInstance3D:
	if mesh is CylinderMesh:
		mesh.top_radius = 0.5
		mesh.bottom_radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.6
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
