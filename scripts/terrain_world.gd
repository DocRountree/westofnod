class_name TerrainWorld
extends Node3D
## Streams terrain around a focus point: 64 m chunks at 1 m resolution near the
## player (mesh + collision + river/lake water, diggable), and 1 km tiles at 16 m
## resolution out to the horizon so neighbouring islands are visible.

signal spawn_found(position: Vector3)

const CHUNK_CELLS := 64
const NEAR_SPACING := 1.0
const NEAR_SIZE := 64.0
const NEAR_RADIUS := 4
const FAR_SPACING := 16.0
const FAR_SIZE := 1024.0
const FAR_RADIUS := 3
const FAR_CUTOFF := 232.0 # far tiles are discarded within this distance of the camera
const MAX_IN_FLIGHT := 2
const OUT_N := CHUNK_CELLS + 3

var generator := TerrainGenerator.new()
var block_world: BlockWorld
var focus := Vector3.ZERO
var spawned := false

var near_material: ShaderMaterial
var far_material: ShaderMaterial
var water_material: ShaderMaterial # rivers and lakes near the player
var far_water_material: ShaderMaterial

var _near := {} # Vector2i -> chunk Dictionary
var _far := {} # Vector2i -> Node3D
var _in_flight := {} # Vector3i(kind, x, z) -> true
var _edits := {} # Vector2i -> PackedFloat32Array (OUT_N^2 height deltas)
var _trees_done := {}
var _spawn_requested := false
var _forest := FastNoiseLite.new()


func _ready() -> void:
	near_material = ShaderMaterial.new()
	near_material.shader = load("res://shaders/terrain.gdshader")
	far_material = ShaderMaterial.new()
	far_material.shader = near_material.shader
	far_material.set_shader_parameter("near_cutoff", FAR_CUTOFF)
	far_material.set_shader_parameter("channel_tint", 0.0)
	_forest.seed = generator.seed
	_forest.frequency = 1.0 / 260.0
	generator.start()


func _exit_tree() -> void:
	generator.stop()


func _process(_delta: float) -> void:
	for res in generator.poll():
		if res.kind == 2:
			_in_flight.erase(Vector3i(2, 0, 0))
			spawned = true
			focus = res.spawn
			spawn_found.emit(res.spawn)
			continue
		var key := Vector3i(res.kind, res.key.x, res.key.y)
		_in_flight.erase(key)
		if res.kind == 0:
			_add_near(res)
		else:
			_add_far(res)
	_schedule()
	_unload()


# ------------------------------------------------------------------ scheduling

func near_key(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / NEAR_SIZE), floori(p.z / NEAR_SIZE))


func far_key(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / FAR_SIZE), floori(p.z / FAR_SIZE))


func _schedule() -> void:
	while _in_flight.size() < MAX_IN_FLIGHT:
		var job := _next_job()
		if job.is_empty():
			return
		_in_flight[Vector3i(job.kind, job.key.x, job.key.y)] = true
		generator.request(job)


func _next_job() -> Dictionary:
	if not spawned:
		if _spawn_requested:
			return {}
		_spawn_requested = true
		return {"kind": 2, "key": Vector2i.ZERO}
	var c := near_key(focus)
	var best := Vector2i.ZERO
	var best_d := INF
	for k in _ring(c, NEAR_RADIUS):
		if _near.has(k) or _in_flight.has(Vector3i(0, k.x, k.y)):
			continue
		var center := (Vector2(k) + Vector2(0.5, 0.5)) * NEAR_SIZE
		var d := center.distance_squared_to(Vector2(focus.x, focus.z))
		if d < best_d:
			best_d = d
			best = k
	if best_d < INF:
		return {"kind": 0, "key": best, "origin": Vector2(best) * NEAR_SIZE,
				"spacing": NEAR_SPACING, "n": CHUNK_CELLS}
	var fc := far_key(focus)
	best_d = INF
	for k in _ring(fc, FAR_RADIUS):
		if _far.has(k) or _in_flight.has(Vector3i(1, k.x, k.y)):
			continue
		var d := Vector2(k - fc).length_squared()
		if d < best_d:
			best_d = d
			best = k
	if best_d < INF:
		return _far_job(best)
	return {}


func _far_job(k: Vector2i) -> Dictionary:
	return {"kind": 1, "key": k, "origin": Vector2(k) * FAR_SIZE,
			"spacing": FAR_SPACING, "n": CHUNK_CELLS}


func _ring(c: Vector2i, r: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for z in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			out.append(Vector2i(x, z))
	return out


func _unload() -> void:
	var c := near_key(focus)
	for k in _near.keys():
		if maxi(absi(k.x - c.x), absi(k.y - c.y)) > NEAR_RADIUS + 1:
			_near[k].node.queue_free()
			_near.erase(k)
	var fc := far_key(focus)
	for k in _far.keys():
		if maxi(absi(k.x - fc.x), absi(k.y - fc.y)) > FAR_RADIUS + 1:
			_far[k].queue_free()
			_far.erase(k)


# ------------------------------------------------------------------ chunk nodes

func _add_far(res: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = TerrainMesher.make_mesh(res.arrays, CHUNK_CELLS)
	mi.material_override = far_material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(res.origin.x, -0.8, res.origin.y)
	add_child(mi)
	var water := _build_water(res.water, far_water_material)
	if water:
		mi.add_child(water)
	_far[res.key] = mi


func _add_near(res: Dictionary) -> void:
	var key: Vector2i = res.key
	var node := Node3D.new()
	node.position = Vector3(res.origin.x, 0.0, res.origin.y)
	add_child(node)
	var delta = _edits.get(key)
	var arrays: Dictionary = res.arrays
	if delta != null:
		arrays = TerrainMesher.build(res.data, delta, CHUNK_CELLS, NEAR_SPACING)
	var mi := MeshInstance3D.new()
	mi.mesh = TerrainMesher.make_mesh(arrays, CHUNK_CELLS)
	mi.material_override = near_material
	node.add_child(mi)

	var body := StaticBody3D.new()
	body.set_meta("kind", "terrain")
	var cs := CollisionShape3D.new()
	var shape := HeightMapShape3D.new()
	shape.map_width = CHUNK_CELLS + 1
	shape.map_depth = CHUNK_CELLS + 1
	shape.map_data = arrays.heights
	cs.shape = shape
	cs.position = Vector3(NEAR_SIZE * 0.5, 0.0, NEAR_SIZE * 0.5)
	body.add_child(cs)
	node.add_child(body)

	var water := _build_water(res.water, water_material)
	if water:
		node.add_child(water)

	_near[key] = {"node": node, "mesh": mi, "shape": shape, "data": res.data,
			"arrays": arrays, "origin": res.origin}
	_place_trees(key)


func _build_water(water: Dictionary, material: ShaderMaterial) -> MeshInstance3D:
	if water.is_empty():
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = water.verts
	arr[Mesh.ARRAY_NORMAL] = water.normals
	arr[Mesh.ARRAY_INDEX] = water.indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# ------------------------------------------------------------------ queries

func has_collision_at(p: Vector3) -> bool:
	return _near.has(near_key(p))


## Height of the (edited) terrain surface, bilinear between vertices. NAN if unloaded.
func height_at(x: float, z: float) -> float:
	var k := Vector2i(floori(x / NEAR_SIZE), floori(z / NEAR_SIZE))
	if not _near.has(k):
		return NAN
	var ch: Dictionary = _near[k]
	var lx: float = x - ch.origin.x
	var lz: float = z - ch.origin.y
	var i := clampi(floori(lx), 0, CHUNK_CELLS - 1)
	var j := clampi(floori(lz), 0, CHUNK_CELLS - 1)
	var fx := lx - i
	var fz := lz - j
	var hs: PackedFloat32Array = ch.arrays.heights
	var w := CHUNK_CELLS + 1
	return lerpf(lerpf(hs[j * w + i], hs[j * w + i + 1], fx),
			lerpf(hs[(j + 1) * w + i], hs[(j + 1) * w + i + 1], fx), fz)


## Block type you get from digging the surface at p (mirrors terrain.gdshader).
func surface_material(p: Vector3) -> int:
	var k := near_key(p)
	if not _near.has(k):
		return BlockWorld.DIRT
	var ch: Dictionary = _near[k]
	var i := clampi(roundi(p.x - ch.origin.x), 0, CHUNK_CELLS)
	var j := clampi(roundi(p.z - ch.origin.y), 0, CHUNK_CELLS)
	var v := j * (CHUNK_CELLS + 1) + i
	var h: float = ch.arrays.heights[v]
	var col: Color = ch.arrays.colors[v]
	var n: Vector3 = ch.arrays.normals[v]
	var dug := col.a * 3.0
	if dug > 2.0 or n.y < 0.7:
		return BlockWorld.STONE
	if h < 1.25:
		return BlockWorld.SAND
	if col.b * 2.0 > 0.4:
		return BlockWorld.GRAVEL
	if dug > 0.2:
		return BlockWorld.DIRT
	return BlockWorld.GRASS


# ------------------------------------------------------------------ digging

## Lowers the terrain around p with a smooth brush. Returns the block type removed.
func dig(p: Vector3, radius: float = 1.3, depth: float = 0.7) -> int:
	var mat := surface_material(p)
	var k0 := Vector2i(floori((p.x - radius - 2.0) / NEAR_SIZE), floori((p.z - radius - 2.0) / NEAR_SIZE))
	var k1 := Vector2i(floori((p.x + radius + 2.0) / NEAR_SIZE), floori((p.z + radius + 2.0) / NEAR_SIZE))
	for kz in range(k0.y, k1.y + 1):
		for kx in range(k0.x, k1.x + 1):
			var key := Vector2i(kx, kz)
			if not _near.has(key):
				continue
			var ch: Dictionary = _near[key]
			if not _edits.has(key):
				var d := PackedFloat32Array()
				d.resize(OUT_N * OUT_N)
				_edits[key] = d
			var delta: PackedFloat32Array = _edits[key]
			# ring index o <-> vertex o - 1 <-> world origin + (o - 1)
			var lx: float = p.x - ch.origin.x + 1.0
			var lz: float = p.z - ch.origin.y + 1.0
			var o0 := Vector2i(maxi(0, floori(lx - radius)), maxi(0, floori(lz - radius)))
			var o1 := Vector2i(mini(OUT_N - 1, ceili(lx + radius)), mini(OUT_N - 1, ceili(lz + radius)))
			if o0.x > o1.x or o0.y > o1.y:
				continue
			for oz in range(o0.y, o1.y + 1):
				for ox in range(o0.x, o1.x + 1):
					var dist := Vector2(ox - lx, oz - lz).length()
					if dist < radius:
						var f := 1.0 - dist / radius
						delta[oz * OUT_N + ox] -= depth * f * f * (3.0 - 2.0 * f)
			_edits[key] = delta
			TerrainMesher.update_rect(ch.arrays, ch.data, delta, CHUNK_CELLS, NEAR_SPACING,
					o0.x - 2, o0.y - 2, o1.x, o1.y)
			ch.mesh.mesh = TerrainMesher.make_mesh(ch.arrays, CHUNK_CELLS)
			ch.shape.map_data = ch.arrays.heights
	return mat


# ------------------------------------------------------------------ spawn & trees

func _place_trees(key: Vector2i) -> void:
	if _trees_done.has(key) or block_world == null:
		return
	_trees_done[key] = true
	var ch: Dictionary = _near[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(key.x, key.y, generator.seed))
	const STEP := 6
	for gz in range(0, CHUNK_CELLS, STEP):
		for gx in range(0, CHUNK_CELLS, STEP):
			var x := mini(gx + rng.randi_range(0, STEP - 1), CHUNK_CELLS - 1)
			var z := mini(gz + rng.randi_range(0, STEP - 1), CHUNK_CELLS - 1)
			var roll := rng.randf()
			var wx: float = ch.origin.x + x + 0.5
			var wz: float = ch.origin.y + z + 0.5
			var density := 0.015 + 0.25 * clampf(_forest.get_noise_2d(wx, wz) * 1.6 + 0.2, 0.0, 1.0)
			if roll > density:
				continue
			var v := z * (CHUNK_CELLS + 1) + x
			var h: float = ch.arrays.heights[v]
			var n: Vector3 = ch.arrays.normals[v]
			var col: Color = ch.arrays.colors[v]
			var r := ((z + 1) * OUT_N + x + 1) * TerrainGenerator.OUT_STRIDE
			if h < 2.0 or h > 120.0 or n.y < 0.86 or col.b * 2.0 > 0.05 \
					or ch.data[r + 4] > h - 1.5:
				continue
			var hmin := minf(h, height_at(wx, wz))
			block_world.add_tree(Vector3i(floori(wx), floori(hmin - 0.4), floori(wz)), rng)
