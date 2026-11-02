class_name Items
## What can be carried: each kind of item, by id. For now a few things to try
## the knapsack and hands with (/give in the chat); there is nothing in the
## world to pick up yet.
##
## Each: name, stack (how many fit in one slot or hand), and how it looks held
## (a primitive: shape, size in m, colour).

const KINDS := {
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


## The item as held: a small mesh, centred on the grip.
static func model(id: String) -> MeshInstance3D:
	var k: Dictionary = KINDS.get(id, {"shape": "box", "size": Vector3.ONE * 0.05, "color": Color.MAGENTA})
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
