class_name Population
extends Node3D
## Everything that grows or lives on the land: static props (PropKind: trees,
## rocks, grass) and actors (ActorKind: NPCs, animals).
##
## The world is cut into CHUNK-metre chunks. The chunks near the player are
## generated on worker threads from a per-chunk seed, so the same chunk always
## gets the same things in the same places and nothing needs saving. Only
## changes do: remove_prop() remembers what was taken (felled trees, picked
## rocks). Each kind of prop in a chunk is one MultiMesh, drawn to the kind's
## view distance; actors spawn in the chunks within actor_radius and are freed
## when the player leaves (unless persistent).
##
## Kinds load from data/population/props/ and data/population/actors/ (.tres
## files), or register_prop() / register_actor().
##
## Props with a radius are solid: push_out() moves a body out of them (the
## player and Actor call it). Positions are world xz; the planet wraps
## (main.gd), but the map's edges are deep ocean, so no chunk straddles a seam.

const CHUNK := 64.0
const PROP_DIR := "res://data/population/props/"
const ACTOR_DIR := "res://data/population/actors/"
const APPLY_PER_FRAME := 2 ## Generated chunks added to the scene per frame, at most.
const MAX_TASKS := 4 ## Chunks generating at once.
const UID_OFFSET := 1 << 18
const LOD_FADE := 6.0 ## m either side of a switch between levels of detail over which they cross-fade (stippled)

@export var actor_radius := 160.0 ## Actors live in the chunks this near the player.
@export var world_seed := 1

var world: WorldData
var props: Array[PropKind] = []
var actor_kinds: Array[ActorKind] = []
var _chunks := {} # Vector2i -> _Chunk
var _queue: Array[Vector2i] = [] # wanted, not yet generating (nearest first)
var _tasks := {} # Vector2i -> WorkerThreadPool task id
var _done: Array = [] # generated, waiting to be added (under _lock)
var _lock := Mutex.new()
var _removed := {} # prop uid -> true
var _centre := Vector2i.MAX
var _radius := 0.0 # chunks are kept this far out (m)
var _focus := Vector3.ZERO


class _Chunk:
	var key: Vector2i
	var nodes: Array[Node3D] = [] # one MultiMeshInstance3D per kind present
	var obstacles := PackedFloat32Array() # x, z, radius
	var spawns: Array = [] # [actor kind index, position, seed]
	var actors: Array[Actor] = []
	var uids: Array = [] # per prop kind: PackedInt64Array of the instances' uids
	var xforms: Array = [] # per prop kind: PackedFloat32Array (12 floats an instance, chunk-local)


func _ready() -> void:
	for k in _load_dir(PROP_DIR):
		if k is PropKind:
			for kv in _variants(k):
				props.append(kv)
	for k in _load_dir(ACTOR_DIR):
		if k is ActorKind:
			actor_kinds.append(k)
	_resolve()


func _exit_tree() -> void:
	for key in _tasks:
		WorkerThreadPool.wait_for_task_completion(_tasks[key])
	_tasks.clear()


func register_prop(kind: PropKind) -> void:
	refresh() # (first: the workers read the kinds)
	props.append_array(_variants(kind))
	_resolve()


## A kind with variants (different models of the same thing) becomes one
## kind per variant, each with its share of the density; meshes from the
## mesh_script are built here (build(variant), build_lods(variant)).
func _variants(k: PropKind) -> Array[PropKind]:
	var out: Array[PropKind] = []
	var n := maxi(k.variants, 1)
	# a variant may differ (mesh_script.variant_props(v): its weight, the
	# share of the density it gets, and any PropKind settings)
	var vp: Array[Dictionary] = []
	var total := 0.0
	for v in n:
		var d: Dictionary = k.mesh_script.variant_props(v) if k.mesh_script and k.mesh_script.has_method("variant_props") else {}
		vp.append(d)
		total += float(d.get("weight", 1.0))
	for v in n:
		var kv: PropKind = k
		if n > 1:
			kv = k.duplicate()
			kv.id = StringName("%s_%d" % [k.id, v])
			var share := float(vp[v].get("weight", 1.0)) / total
			var d := {}
			for b in k.density:
				d[b] = float(k.density[b]) * share
			kv.density = d
			for key in vp[v]:
				if key != "weight":
					kv.set(key, vp[v][key])
		if kv.mesh == null and kv.mesh_script:
			kv.mesh = kv.mesh_script.build(v)
		if kv.lods.is_empty() and kv.mesh_script and kv.mesh_script.has_method("build_lods"):
			kv.lods = kv.mesh_script.build_lods(v)
		if kv.shadow_mesh == null and kv.mesh_script and kv.mesh_script.has_method("build_shadow"):
			kv.shadow_mesh = kv.mesh_script.build_shadow(v)
		out.append(kv)
	return out


func register_actor(kind: ActorKind) -> void:
	refresh()
	actor_kinds.append(kind)
	_resolve()


## Regenerate every chunk (call after changing a kind's settings).
func refresh() -> void:
	for key in _tasks:
		WorkerThreadPool.wait_for_task_completion(_tasks[key])
	_tasks.clear()
	_lock.lock()
	_done.clear()
	_lock.unlock()
	for key in _chunks.keys():
		_unload(key)
	_queue.clear()
	_centre = Vector2i.MAX


## Call every frame with the player's position.
func update(focus: Vector3) -> void:
	if world == null or (props.is_empty() and actor_kinds.is_empty()):
		return
	_focus = focus
	var c := _key(focus)
	if c != _centre:
		_centre = c
		_retarget(focus)
	while _tasks.size() < MAX_TASKS and not _queue.is_empty():
		var key: Vector2i = _queue.pop_front()
		_tasks[key] = WorkerThreadPool.add_task(_generate.bind(key))
	for key in _tasks.keys():
		if WorkerThreadPool.is_task_completed(_tasks[key]):
			WorkerThreadPool.wait_for_task_completion(_tasks[key])
			_tasks.erase(key)
	_lock.lock()
	var batch := _done.slice(0, APPLY_PER_FRAME)
	_done = _done.slice(APPLY_PER_FRAME)
	_lock.unlock()
	for ch: _Chunk in batch:
		if _wanted(ch.key):
			_apply(ch)
	_update_actors(focus)


## Moves a body (a circle of radius r at p, horizontally) out of any solid
## prop it overlaps.
func push_out(p: Vector3, r: float) -> Vector3:
	if _chunks.is_empty():
		return p
	var c := _key(p)
	var q := Vector2(p.x, p.z)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var o := ch.obstacles
			for i in range(0, o.size(), 3):
				var d := q - Vector2(o[i], o[i + 1])
				var min_d := o[i + 2] + r
				var l2 := d.length_squared()
				if l2 < min_d * min_d:
					var l := sqrt(l2)
					q += (d / l if l > 1e-4 else Vector2.RIGHT) * (min_d - l)
	return Vector3(q.x, p.y, q.y)


## Takes a prop out of the world for good (uid: from prop_at()).
func remove_prop(uid: int) -> void:
	_removed[uid] = true
	var key := Vector2i(uid >> 43, (uid >> 24) & 0x7FFFF) - Vector2i(UID_OFFSET, UID_OFFSET)
	var ch: _Chunk = _chunks.get(key)
	if ch:
		_build_props(ch)


## The nearest prop to p within r: {uid, kind, position} (empty if none).
func prop_at(p: Vector3, r: float) -> Dictionary:
	var best := {}
	var best_d := r
	var c := _key(p)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var base := Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK)
			for k in ch.xforms.size():
				var xf: PackedFloat32Array = ch.xforms[k]
				var uids: PackedInt64Array = ch.uids[k]
				for i in uids.size():
					if _removed.has(uids[i]):
						continue
					var at := base + Vector3(xf[i * 12 + 3], xf[i * 12 + 7], xf[i * 12 + 11])
					var d := at.distance_to(p)
					if d < best_d:
						best_d = d
						best = {"uid": uids[i], "kind": props[k], "position": at}
	return best


func stats() -> Dictionary:
	var n := 0
	var a := 0
	for ch: _Chunk in _chunks.values():
		for k in ch.uids.size():
			n += (ch.uids[k] as PackedInt64Array).size()
		a += ch.actors.size()
	_lock.lock()
	var waiting := _done.size()
	_lock.unlock()
	return {"chunks": _chunks.size(), "props": n, "actors": a, "generating": _tasks.size() + _queue.size() + waiting,
			"prop_kinds": props.size(), "actor_kinds": actor_kinds.size()}


# ---- internals

func _resolve() -> void:
	_radius = actor_radius if not actor_kinds.is_empty() else 0.0
	if world == null:
		return
	for k in props:
		k.resolve(world.biome_names)
		_radius = maxf(_radius, k.view_distance)
	for k in actor_kinds:
		k.resolve(world.biome_names)


func _load_dir(dir: String) -> Array:
	var out := []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for f in DirAccess.get_files_at(dir):
		f = f.trim_suffix(".remap") # (exported builds)
		if f.ends_with(".tres") or f.ends_with(".res"):
			var r := load(dir.path_join(f))
			if r:
				out.append(r)
	return out


func _key(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / CHUNK), floori(p.z / CHUNK))


func _wanted(key: Vector2i) -> bool:
	return _chunk_dist(key, _focus) <= _radius + CHUNK


func _chunk_dist(key: Vector2i, p: Vector3) -> float:
	var lo := Vector2(key) * CHUNK
	var q := Vector2(clampf(p.x, lo.x, lo.x + CHUNK), clampf(p.z, lo.y, lo.y + CHUNK))
	return q.distance_to(Vector2(p.x, p.z))


## The chunks to keep round the player: unload the far ones, queue the
## missing ones nearest first.
func _retarget(focus: Vector3) -> void:
	_focus = focus
	for key in _chunks.keys():
		if not _wanted(key):
			_unload(key)
	var c := _key(focus)
	var n := ceili(_radius / CHUNK) + 1
	var want: Array[Vector2i] = []
	for dz in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var key := c + Vector2i(dx, dz)
			if _chunk_dist(key, focus) <= _radius and not _chunks.has(key) and not _tasks.has(key):
				want.append(key)
	want.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(c) < b.distance_squared_to(c))
	_queue = want


func _seed(key: Vector2i, salt: int) -> int:
	var h := hash([world_seed, key.x, key.y, salt])
	return h


## A prop's id: its chunk, kind and number in the chunk (stable, as placement
## is): 19 bits each for the chunk's x and z, 8 for the kind, 16 for the number.
static func _uid(key: Vector2i, kind: int, i: int) -> int:
	return ((key.x + UID_OFFSET) << 43) | ((key.y + UID_OFFSET) << 24) | ((kind & 0xFF) << 16) | (i & 0xFFFF)


## On a worker thread: where everything in a chunk goes. Reads only WorldData
## and the kinds (read-only while generating).
func _generate(key: Vector2i) -> void:
	var ch := _Chunk.new()
	ch.key = key
	var base := Vector2(key) * CHUNK
	var area_ha := CHUNK * CHUNK / 10000.0
	var obstacles := PackedFloat32Array()
	for k in props.size():
		var kind := props[k]
		var xf := PackedFloat32Array()
		var uids := PackedInt64Array()
		var peak := kind.peak()
		if peak > 0.0 and kind.mesh:
			var rng := RandomNumberGenerator.new()
			rng.seed = _seed(key, k)
			var n := _count(rng, peak * area_ha)
			for i in n:
				# draw everything first, so a rejection doesn't shift the rest
				var x := base.x + rng.randf() * CHUNK
				var z := base.y + rng.randf() * CHUNK
				var keep := rng.randf() * peak
				var turn := rng.randf() * TAU
				var s := rng.randf_range(kind.scale_range.x, kind.scale_range.y)
				if keep >= kind.density_in(world.biome_index_at(x, z)):
					continue
				var h := world.height_at(x, z)
				var nrm := world.normal_at(x, z)
				if not kind.fits(h, nrm):
					continue
				var b := Basis(Vector3.UP, turn)
				if kind.align_to_ground > 0.0:
					var up := Vector3.UP.slerp(nrm, kind.align_to_ground)
					b = Basis(Quaternion(Vector3.UP, up)) * b
				b = b.scaled(Vector3.ONE * s)
				var o := Vector3(x - base.x, h - kind.sink * s, z - base.y)
				xf.append_array([b.x.x, b.y.x, b.z.x, o.x, b.x.y, b.y.y, b.z.y, o.y, b.x.z, b.y.z, b.z.z, o.z])
				var uid := _uid(key, k, i)
				uids.append(uid)
				if kind.radius > 0.0:
					obstacles.append_array([x, z, kind.radius * s])
		ch.xforms.append(xf)
		ch.uids.append(uids)
	ch.obstacles = obstacles
	var area_km2 := CHUNK * CHUNK / 1e6
	for k in actor_kinds.size():
		var kind := actor_kinds[k]
		var peak := kind.peak()
		if peak <= 0.0:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed(key, 1000 + k)
		for g in _count(rng, peak * area_km2):
			var x := base.x + rng.randf() * CHUNK
			var z := base.y + rng.randf() * CHUNK
			var keep := rng.randf() * peak
			var members := rng.randi_range(kind.group_size.x, kind.group_size.y)
			var gseed := rng.randi()
			if keep >= kind.density_in(world.biome_index_at(x, z)):
				continue
			var mr := RandomNumberGenerator.new()
			mr.seed = gseed
			for m in members:
				var a := mr.randf() * TAU
				var px := x + cos(a) * mr.randf() * kind.group_spread
				var pz := z + sin(a) * mr.randf() * kind.group_spread
				var h := world.height_at(px, pz)
				if kind.fits(h, world.normal_at(px, pz)):
					ch.spawns.append([k, Vector3(px, h, pz), mr.randi()])
	_lock.lock()
	_done.append(ch)
	_lock.unlock()


## How many of something with mean count `mean` (the fraction by chance).
static func _count(rng: RandomNumberGenerator, mean: float) -> int:
	var n := floori(mean)
	return n + (1 if rng.randf() < mean - n else 0)


## On the main thread: put a generated chunk in the scene.
func _apply(ch: _Chunk) -> void:
	if _chunks.has(ch.key):
		return
	_chunks[ch.key] = ch
	_build_props(ch)


## (Re)build a chunk's MultiMeshes.
func _build_props(ch: _Chunk) -> void:
	for n in ch.nodes:
		n.queue_free()
	ch.nodes.clear()
	if not _removed.is_empty():
		_drop_removed(ch)
	var at := Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK)
	for k in ch.xforms.size():
		var xf: PackedFloat32Array = ch.xforms[k]
		if xf.is_empty():
			continue
		var kind := props[k]
		# one MultiMesh per level of detail, each drawn over its own span of
		# distance. They all get the same box (round every mesh they draw),
		# so the levels hand over at the same distance, cross-fading.
		var n := mini(kind.lods.size(), kind.lod_distances.size())
		var box := _chunk_box(kind, xf)
		for l in n + 1:
			var begin := 0.0 if l == 0 else kind.lod_distances[l - 1]
			var end := kind.view_distance if l == n else minf(kind.lod_distances[l], kind.view_distance)
			if begin >= end:
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = kind.mesh if l == 0 else kind.lods[l - 1]
			mm.instance_count = xf.size() / 12
			mm.buffer = xf
			var mi := MultiMeshInstance3D.new()
			mi.multimesh = mm
			mi.position = at
			var mat := kind.material if l == 0 or kind.lod_material == null else kind.lod_material
			if mat:
				mi.material_override = mat
			var shadows := kind.shadows and begin < kind.shadow_distance and kind.shadow_mesh == null
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.custom_aabb = box
			# drawn a little past each switch, both levels at once, so their
			# shaders can cross-fade (lod_fade.gdshaderinc: by the same
			# distance, to the box's middle)
			mi.visibility_range_begin = maxf(begin - LOD_FADE * 2.0, 0.0) if l > 0 else 0.0
			mi.visibility_range_end = end + LOD_FADE * 2.0
			mi.set_instance_shader_parameter("lod_range", Vector3(begin, end, LOD_FADE))
			mi.set_instance_shader_parameter("lod_centre", at + box.get_center())
			add_child(mi)
			ch.nodes.append(mi)
		if kind.shadow_mesh and kind.shadows:
			# the stand-in, only in the shadow maps
			var smm := MultiMesh.new()
			smm.transform_format = MultiMesh.TRANSFORM_3D
			smm.mesh = kind.shadow_mesh
			smm.instance_count = xf.size() / 12
			smm.buffer = xf
			var smi := MultiMeshInstance3D.new()
			smi.multimesh = smm
			smi.position = at
			smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			smi.custom_aabb = box
			smi.visibility_range_end = kind.shadow_distance
			smi.visibility_range_end_margin = CHUNK * 0.5
			add_child(smi)
			ch.nodes.append(smi)


## A box (chunk-local) round everything a kind draws in a chunk: the
## instances' spread, plus the largest of its meshes at the largest scale.
func _chunk_box(kind: PropKind, xf: PackedFloat32Array) -> AABB:
	var m := AABB()
	for mesh in [kind.mesh, kind.shadow_mesh] + kind.lods:
		if mesh:
			m = m.merge(mesh.get_aabb())
	m = AABB(m.position * kind.scale_range.y * 1.05, m.size * kind.scale_range.y * 1.05)
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for i in range(0, xf.size(), 12):
		var o := Vector3(xf[i + 3], xf[i + 7], xf[i + 11])
		lo = lo.min(o)
		hi = hi.max(o)
	return AABB(lo + m.position, hi - lo + m.size)


## Leave out what remove_prop() took (instances and their obstacles).
func _drop_removed(ch: _Chunk) -> void:
	var obstacles := PackedFloat32Array()
	for k in ch.xforms.size():
		var xf: PackedFloat32Array = ch.xforms[k]
		var uids: PackedInt64Array = ch.uids[k]
		var keep_xf := PackedFloat32Array()
		var keep_uids := PackedInt64Array()
		var kind := props[k]
		for i in uids.size():
			if _removed.has(uids[i]):
				continue
			keep_xf.append_array(xf.slice(i * 12, i * 12 + 12))
			keep_uids.append(uids[i])
			if kind.radius > 0.0:
				var s := Vector3(xf[i * 12], xf[i * 12 + 4], xf[i * 12 + 8]).length()
				obstacles.append_array([xf[i * 12 + 3] + ch.key.x * CHUNK, xf[i * 12 + 11] + ch.key.y * CHUNK, kind.radius * s])
		ch.xforms[k] = keep_xf
		ch.uids[k] = keep_uids
	ch.obstacles = obstacles


func _unload(key: Vector2i) -> void:
	var ch: _Chunk = _chunks.get(key)
	if ch == null:
		return
	for n in ch.nodes:
		n.queue_free()
	ch.nodes.clear()
	_despawn(ch)
	_chunks.erase(key)


## Actors in the chunks within actor_radius; freed beyond it (with a margin).
func _update_actors(focus: Vector3) -> void:
	if actor_kinds.is_empty():
		return
	for ch: _Chunk in _chunks.values():
		var d := _chunk_dist(ch.key, focus)
		if ch.actors.is_empty() and not ch.spawns.is_empty() and d <= actor_radius:
			_spawn(ch)
		elif not ch.actors.is_empty() and d > actor_radius + CHUNK:
			_despawn(ch)


func _spawn(ch: _Chunk) -> void:
	for s: Array in ch.spawns:
		var kind := actor_kinds[s[0]]
		var a: Actor = kind.scene.instantiate() if kind.scene else Actor.new()
		a.world = world
		a.population = self
		a.kind = kind
		a.home = s[1]
		a.rng.seed = s[2]
		a.position = s[1]
		a.rotation.y = a.rng.randf() * TAU
		add_child(a)
		ch.actors.append(a)
		if kind.persistent:
			ch.spawns = ch.spawns.filter(func(x: Array) -> bool: return x != s) # it lives on: don't spawn it again


func _despawn(ch: _Chunk) -> void:
	for a in ch.actors:
		if is_instance_valid(a) and not a.kind.persistent:
			a.queue_free()
	ch.actors.clear()
