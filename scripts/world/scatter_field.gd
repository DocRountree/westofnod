class_name ScatterField
extends MultiMeshInstance3D
## A GRID x GRID field of props placed on the GPU (see scatter.gdshaderinc).
## The instances carry no transforms; the shader places each one in its world
## cell around the camera and decides from the masks whether it exists.

var material: ShaderMaterial


func _init(world: WorldData, mesh: Mesh, shader: Shader, cell: float, radius: float,
		fade_in: Vector2, params: Dictionary = {}) -> void:
	var grid := ceili(2.0 * radius / cell) + 1
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = grid * grid
	# Identity instance transforms (new ones are all zero, which would collapse
	# every prop); the shader does the placing.
	var buf := PackedFloat32Array()
	buf.resize(grid * grid * 12)
	for i in grid * grid:
		buf[i * 12] = 1.0
		buf[i * 12 + 5] = 1.0
		buf[i * 12 + 10] = 1.0
	multimesh.buffer = buf
	material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("height_tex", world.height_tex)
	material.set_shader_parameter("mask_tex", world.mask_tex)
	material.set_shader_parameter("map_size", float(world.size))
	material.set_shader_parameter("map_domain", world.domain)
	material.set_shader_parameter("map_origin", world.origin)
	material.set_shader_parameter("grid", grid)
	material.set_shader_parameter("cell", cell)
	material.set_shader_parameter("fade_in_start", fade_in.x)
	material.set_shader_parameter("fade_in_end", fade_in.y)
	material.set_shader_parameter("fade_out_start", radius * 0.8)
	material.set_shader_parameter("fade_out_end", radius)
	for k in params:
		material.set_shader_parameter(k, params[k])
	material_override = material
	custom_aabb = AABB(Vector3(-1e5, -1e4, -1e5), Vector3(2e5, 2e4, 2e5))


func update(cam: Vector3) -> void:
	material.set_shader_parameter("view_pos", cam)
