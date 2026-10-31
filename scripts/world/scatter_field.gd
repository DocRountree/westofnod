class_name ScatterField
extends MultiMeshInstance3D
## A GRID x GRID field of props placed on the GPU (see scatter.gdshaderinc).
## The instances carry no transforms; the shader places each one in its world
## cell around the camera and decides from the masks whether it exists.

const MAX_ZOOM := 8.0 ## The most magnification the instance budget covers.
const MAX_TILES := 24 ## Must match scatter.gdshaderinc.
const MAX_INSTANCES := 120000 ## Cap on a field's magnified budget.

var material: ShaderMaterial
var cell := 1.0
var radius := 1.0
var grid := 1
var _budget := 0


func _init(world: WorldData, mesh: Mesh, shader: Shader, cell_size: float, range_m: float,
		fade_in: Vector2, params: Dictionary = {}) -> void:
	cell = cell_size
	radius = range_m
	grid = ceili(2.0 * radius / cell) + 1
	# Magnified, the field reaches MAX_ZOOM times farther, but only in a wedge
	# about the view (a horizontal half-angle of up to ~9.5 degrees at 8x on a
	# 16:9 screen), tiled with some overlap.
	_budget = maxi(grid * grid, mini(ceili(2.2 * pow(radius * MAX_ZOOM, 2.0) * 0.17 / (cell * cell)), MAX_INSTANCES))
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = _budget
	multimesh.visible_instance_count = grid * grid
	# Identity instance transforms (new ones are all zero, which would collapse
	# every prop); the shader does the placing.
	var buf := PackedFloat32Array()
	buf.resize(_budget * 12)
	for i in _budget:
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


## Magnified view (zoom > 1): tile the wedge seen along dir (horizontal unit
## vector) with half-angle tangent tan_half out to radius * zoom; zoom 1 goes
## back to the grid around the camera. Returns how far (m) the field reaches:
## less than radius * zoom when the budget runs out first.
func magnify(cam: Vector3, dir: Vector2, zoom: float, tan_half: float) -> float:
	if zoom <= 1.01:
		material.set_shader_parameter("tiles", 0)
		multimesh.visible_instance_count = grid * grid
		return radius
	var perp := Vector2(-dir.y, dir.x)
	var c := Vector2(cam.x, cam.z)
	var pad := cell * 2.0 + 20.0
	var reach := radius * zoom
	var boxes: Array[Vector4i] = []
	var starts := PackedInt32Array()
	var spans := PackedVector2Array()
	var total := 0
	var a := -pad
	while a < reach and boxes.size() < MAX_TILES:
		var b := minf(a + maxf(6.0 * cell, 2.0 * (maxf(a, 0.0) * tan_half + pad)), reach)
		if boxes.size() == MAX_TILES - 1:
			b = reach
		var wa := maxf(a, 0.0) * tan_half + pad
		var wb := b * tan_half + pad
		var lo := Vector2.INF
		var hi := -Vector2.INF
		for q: Vector2 in [c + dir * a + perp * wa, c + dir * a - perp * wa, c + dir * b + perp * wb, c + dir * b - perp * wb]:
			lo = lo.min(q)
			hi = hi.max(q)
		var c0 := Vector2i((lo / cell).floor()) - Vector2i.ONE
		var c1 := Vector2i((hi / cell).floor()) + Vector2i.ONE
		var size := c1 - c0 + Vector2i.ONE
		if total + size.x * size.y > _budget:
			break # out of instances: the far end goes without
		boxes.append(Vector4i(c0.x, c0.y, size.x, size.y))
		starts.append(total)
		spans.append(Vector2(a, b))
		total += size.x * size.y
		a = b
	material.set_shader_parameter("tiles", boxes.size())
	material.set_shader_parameter("tile_box", boxes)
	material.set_shader_parameter("tile_start", starts)
	material.set_shader_parameter("tile_span", spans)
	material.set_shader_parameter("view_dir_xz", dir)
	material.set_shader_parameter("wedge_tan", tan_half)
	material.set_shader_parameter("wedge_pad", pad)
	multimesh.visible_instance_count = total
	return a
