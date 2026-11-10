class_name FarTrees
extends Node3D
## The standing trees far off: past each one's last level of detail (250 m:
## PropKind.view_distance) out to the tree render distance (Settings; its
## kind's far_distance), a card each, its photograph (ImpostorBaker), turned
## to the camera (far_trees.gdshader). Where Population draws its chunks'
## trees kind by kind, level by level, these are drawn a cell of the map
## (CELL, 512 m: eight chunks a side) at once: one MultiMesh of every
## species' trees in it, each tree's photograph a layer of one album.
##
## The trees are Population's own, where it puts them (Population._scatter,
## chunk by chunk, on a worker thread: only the kinds with a card, nothing
## else of the chunk worked out), so a tree's card stands exactly where the
## tree does, and the two hand over between them stippled, tree by tree
## (lod_fade.gdshaderinc), as its nearer levels do.

const CELL_CHUNKS := 8
const CELL := Population.CHUNK * CELL_CHUNKS ## m, a cell's side
const MAX_TASKS := 2 ## Cells being worked out at once (the world loading: one a processor but one).
const AHEAD := 96.0 ## m past the cards' reach a cell is made ready from
const RETARGET := 32.0 ## m the view moves before the cells wanted are looked over again

# ---- the album: every card's photograph, and where each is drawn

static var _frames: Array[Vector2] = [] # layer -> its card's middle's height, half its side (the tree's own units)
static var _spans: Array[Vector2] = [] # layer -> from where it's drawn, to where (m)
static var _album: Texture2DArray
static var _material: ShaderMaterial
static var _quad: ArrayMesh
static var _cards_stale := true


## A standing tree's card, to be photographed from mesh (its simplest
## level): its layer in the album.
static func add_card(mesh: Mesh) -> int:
	var f := OakTree.card_frame(mesh) # (mid, side)
	_frames.append(Vector2(f.x, f.y * 0.5))
	_spans.append(Vector2(OakTree.LOD[OakTree.LOD.size() - 1], OakTree.FAR))
	_cards_stale = true
	var layer := _frames.size() - 1
	OakTree.impostor_jobs.append([mesh, f.y, f.x, null, layer])
	return layer


## From where a card is drawn (m: where its tree's last level ends), to where.
static func set_span(layer: int, begin: float, end: float) -> void:
	if _spans[layer] != Vector2(begin, end):
		_spans[layer] = Vector2(begin, end)
		_cards_stale = true


## The furthest any card is drawn (m).
static func reach() -> float:
	var r := 0.0
	for s in _spans:
		r = maxf(r, s.y)
	return r


## A card's photograph, taken (ImpostorBaker).
static func set_photo(layer: int, img: Image) -> void:
	_grow_album()
	_album.update_layer(img, layer)


## The album with a layer for every card (blank until its photograph's in:
## nothing drawn); those already taken kept when it grows.
static func _grow_album() -> void:
	if _album and _album.get_layers() >= _frames.size():
		return
	var blank := Image.create(ImpostorBaker.PX * ImpostorBaker.FRAMES, ImpostorBaker.PX, true, Image.FORMAT_RGBA8)
	var imgs: Array[Image] = []
	for i in maxi(_frames.size(), 1):
		imgs.append(_album.get_layer_data(i) if _album and i < _album.get_layers() else blank)
	_album = Texture2DArray.new()
	_album.create_from_images(imgs)
	material().set_shader_parameter("atlas", _album)


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://shaders/render/far_trees.gdshader")
		_material.set_shader_parameter("frames", float(ImpostorBaker.FRAMES))
		_material.set_shader_parameter("atlas_px", Vector2(ImpostorBaker.PX * ImpostorBaker.FRAMES, ImpostorBaker.PX))
		_material.set_shader_parameter("far_fade", Population.LOD_FADE)
		_grow_album()
	return _material


## The cards' frames and spans to the shader (a texel a layer).
static func _sync_cards() -> void:
	if not _cards_stale:
		return
	_cards_stale = false
	_grow_album()
	var img := Image.create(maxi(_frames.size(), 1), 1, false, Image.FORMAT_RGBAF)
	for i in _frames.size():
		img.set_pixel(i, 0, Color(_frames[i].x, _frames[i].y, _spans[i].x, _spans[i].y))
	material().set_shader_parameter("cards", ImageTexture.create_from_image(img))


## The card itself: four corners at the tree's foot, spread by the shader.
static func _card_mesh() -> ArrayMesh:
	if _quad == null:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
		_quad = ArrayMesh.new()
		_quad.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_quad.surface_set_material(0, material())
	return _quad


# ---- the cells

class _Cell:
	var key: Vector2i
	var origin := Vector3.ZERO # its node's place (on the map): its trees' middle
	var xf := PackedFloat32Array() # 12 floats a tree, from origin
	var layers := PackedInt32Array() # each tree's card
	var uids := PackedInt64Array() # each tree's (Population's: those felled left out)
	var box := AABB() # round its cards (from origin)
	var node: MultiMeshInstance3D


var population: Population
var _cells := {} # Vector2i -> _Cell
var _queue: Array[Vector2i] = [] # wanted, not yet being worked out (nearest first)
var _tasks := {} # Vector2i -> WorkerThreadPool task id
var _done: Array[_Cell] = [] # worked out, waiting to be added (under _lock)
var _lock := Mutex.new()
var _at := Vector3.INF # the view the cells wanted were last looked over from
var _reach := 0.0


func _exit_tree() -> void:
	_wait()


func _wait() -> void:
	for key in _tasks:
		WorkerThreadPool.wait_for_task_completion(_tasks[key])
	_tasks.clear()


## Every cell made again (Population.refresh: its kinds changed).
func clear() -> void:
	_wait()
	_lock.lock()
	_done.clear()
	_lock.unlock()
	for key in _cells:
		if _cells[key].node:
			_cells[key].node.queue_free()
	_cells.clear()
	_queue.clear()
	_at = Vector3.INF


## Cells still to come (being worked out, or waiting to be).
func pending() -> int:
	_lock.lock()
	var n := _done.size()
	_lock.unlock()
	return n + _tasks.size() + _queue.size()


## The cells within the cards' reach of `view` (the camera, on the map)
## kept, the rest let go; `all` at once those worked out are added (the
## world loading), else one a frame.
func update(view: Vector3, all := false) -> void:
	if population == null or population.far_kinds.is_empty():
		return
	_sync_cards()
	var r := reach() + AHEAD
	if r != _reach or Vector2(view.x - _at.x, view.z - _at.z).length() > RETARGET:
		_reach = r
		_at = view
		_retarget()
	var tasks := maxi(OS.get_processor_count() - 1, MAX_TASKS) if all else MAX_TASKS
	while _tasks.size() < tasks and not _queue.is_empty():
		var key: Vector2i = _queue.pop_front()
		_tasks[key] = WorkerThreadPool.add_task(_generate.bind(key))
	for key in _tasks.keys():
		if WorkerThreadPool.is_task_completed(_tasks[key]):
			WorkerThreadPool.wait_for_task_completion(_tasks[key])
			_tasks.erase(key)
	_lock.lock()
	var n := _done.size() if all else mini(_done.size(), 1)
	var batch := _done.slice(0, n)
	_done = _done.slice(n)
	_lock.unlock()
	for c: _Cell in batch:
		if _wanted(c.key) and not _cells.has(c.key):
			_cells[c.key] = c
			_build(c)


## A tree taken out of the world, or put back (Population.remove_prop,
## restore_props): its cell's cards made again, without it or with.
func changed(uid: int) -> void:
	var ck := population._uid_key(uid)
	var c: _Cell = _cells.get(Vector2i(floori(float(ck.x) / CELL_CHUNKS), floori(float(ck.y) / CELL_CHUNKS)))
	if c and c.uids.has(uid):
		_build(c)


func _dist(key: Vector2i) -> float:
	var lo := Vector2(key) * CELL
	var q := Vector2(clampf(_at.x, lo.x, lo.x + CELL), clampf(_at.z, lo.y, lo.y + CELL))
	return q.distance_to(Vector2(_at.x, _at.z))


func _wanted(key: Vector2i) -> bool:
	return _dist(key) <= _reach + CELL * 0.5 # (kept a little past where it's first wanted: not made and let go at the edge)


func _retarget() -> void:
	for key in _cells.keys():
		if not _wanted(key):
			if _cells[key].node:
				_cells[key].node.queue_free()
			_cells.erase(key)
	var c := Vector2i(floori(_at.x / CELL), floori(_at.z / CELL))
	var n := ceili(_reach / CELL) + 1
	var want: Array[Vector2i] = []
	for dz in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var key := c + Vector2i(dx, dz)
			if _dist(key) <= _reach and not _cells.has(key) and not _tasks.has(key):
				want.append(key)
	want.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return _dist(a) < _dist(b))
	_queue = want


## On a worker thread: the cell's standing trees, chunk by chunk as
## Population places them. Reads only what Population's own workers read.
func _generate(key: Vector2i) -> void:
	var c := _Cell.new()
	c.key = key
	var xf := PackedFloat32Array()
	var layers := PackedInt32Array()
	var uids := PackedInt64Array()
	var no_feet := PackedVector4Array()
	var rng := RandomNumberGenerator.new()
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for cz in CELL_CHUNKS:
		for cx in CELL_CHUNKS:
			var ck := key * CELL_CHUNKS + Vector2i(cx, cz)
			var off := Vector2(cx, cz) * Population.CHUNK
			for k in population.far_kinds:
				var kind := population.props[k]
				var placed: Array = population._scatter(kind, k, ck, no_feet, rng)
				var t: PackedFloat32Array = placed[0]
				if t.is_empty():
					continue
				var f := _frames[kind.far_card]
				for i in range(0, t.size(), 12):
					t[i + 3] += off.x
					t[i + 11] += off.y
					# (the box round its card: as high as its top, as wide as it turns)
					var o := Vector3(t[i + 3], t[i + 7], t[i + 11])
					var s := Vector3(t[i], t[i + 4], t[i + 8]).length()
					lo = lo.min(o - Vector3(f.y, 0.0, f.y) * s)
					hi = hi.max(o + Vector3(f.y, f.x + f.y, f.y) * s)
					layers.append(kind.far_card)
				xf.append_array(t)
				uids.append_array(placed[1])
	if not uids.is_empty():
		var mid := (lo + hi) * 0.5
		for i in range(0, xf.size(), 12):
			xf[i + 3] -= mid.x
			xf[i + 7] -= mid.y
			xf[i + 11] -= mid.z
		c.origin = Vector3(key.x * CELL, 0.0, key.y * CELL) + mid
		c.box = AABB(lo - mid, hi - lo).grow(1.0)
	c.xf = xf
	c.layers = layers
	c.uids = uids
	_lock.lock()
	_done.append(c)
	_lock.unlock()


## On the main thread: a cell's MultiMesh, of its trees still standing.
func _build(c: _Cell) -> void:
	if c.node:
		c.node.queue_free()
		c.node = null
	var removed := population.removed()
	var buf := PackedFloat32Array()
	buf.resize(c.uids.size() * 16)
	var n := 0
	for i in c.uids.size():
		if removed.has(c.uids[i]):
			continue
		for j in 12:
			buf[n * 16 + j] = c.xf[i * 12 + j]
		buf[n * 16 + 12] = c.layers[i]
		n += 1
	if n == 0:
		return
	buf.resize(n * 16)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _card_mesh()
	mm.instance_count = n
	mm.buffer = buf
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.position = c.origin
	mi.custom_aabb = c.box
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	c.node = mi


## How many cards stand in the cells kept, and the cells.
func stats() -> Dictionary:
	var n := 0
	for key in _cells:
		if _cells[key].node:
			n += (_cells[key].node as MultiMeshInstance3D).multimesh.instance_count
	return {"far_cells": _cells.size(), "far_trees": n}
