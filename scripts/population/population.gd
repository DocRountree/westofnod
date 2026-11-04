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
## player and Actor call it). Fallen logs can be stood on (deck_at(); see
## PropKind.walk), as can stumps; they are walls to a body below their top. Positions are world xz; the planet wraps
## (main.gd), but the map's edges are deep ocean, so no chunk straddles a seam.

const CHUNK := 64.0
const PROP_DIR := "res://data/population/props/"
const FIRST_KINDS := ["oak", "pawpaw"] ## Placed first, in this order (as before the other trees came: see _ready)
const ACTOR_DIR := "res://data/population/actors/"
const APPLY_PER_FRAME := 2 ## Generated chunks added to the scene per frame, at most (playing).
var apply_per_frame := APPLY_PER_FRAME ## (more while the world loads, behind its screen)
const MAX_TASKS := 4 ## Chunks generating at once.
const UID_OFFSET := 1 << 18
const STEP_UP := 0.7 ## m: a body steps up onto a log or stump this high above its feet; higher, it must jump
const BODY_HEIGHT := 1.7 ## m: a log this far above the feet passes overhead
const LOD_FADE := 6.0 ## m either side of a switch between levels of detail over which they cross-fade (stippled)
const LOD_MID := 6.0 ## m up a tree's own axis (at scale 1) its level is measured from (lod_fade.gdshaderinc: lod_mid_height)
## m the camera may move before a chunk's trees are sorted into their levels
## again (each level holds the trees this much either side of its span, and
## its fade, so none is missing between sortings)
const LOD_SLACK := 6.0
const BUCKETS_PER_FRAME := 24 ## chunks sorted a frame, at the least (more when many are due)
## Biomes where no tree casts a shadow, whatever its kind (the forest: its
## floor shaded by a cheap stand-in for the canopy instead, canopy.gdshaderinc)
const SHADOWLESS := ["forest"]

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
var _fallen := {} # chunk key -> [walk, trunks]: felled trees' (add_fallen), added to the chunk's own whenever it's (re)built
var _notches := {} # prop uid -> Color: an axe's notch in a tree (set_notch; bark.gdshader reads it)
var _near := {} # prop uid -> MultiMeshInstance3D: what's drawn only close by (sporophytes)
var _near_at := Vector3.INF # where the player was when _near was last updated
var _near_walks := -1 # walk_changes then
var _near_data := {} # prop kind index -> [MultiMesh, material, reach, its buffer] (or [] for none)
var _near_want := {} # prop uid -> [near data, transform]: the logs near now
var _near_jobs := {} # prop uid -> [task, out, near data]: its sporophytes being worked out
var _near_mm := {} # prop uid -> MultiMesh (or null): those on its moss (kept a while: _near_order)
var _near_order: Array = [] # uids in _near_mm, oldest first
var walk_changes := 0 ## Counts the times logs or stumps came or went (GroundCover rechecks the grass).
var _view := Vector3.INF # the camera, on the map (update)


class _Chunk:
	var key: Vector2i
	var groups := {} # prop kind index -> Array[_Group]: what it draws of that kind
	var bucket_at := Vector3.INF # the camera (on the map) its trees were last sorted into their levels for
	var obstacles := PackedFloat32Array() # x, z, radius
	var walk := PackedFloat32Array() # world segments to stand on (PropKind.walk)
	var trunks: Array[PackedFloat32Array] = [] # world trunks to climb (PropKind.climb), one each
	var spawns: Array = [] # [actor kind index, position, seed]
	var actors: Array[Actor] = []
	var uids: Array = [] # per prop kind: PackedInt64Array of the instances' uids
	var xforms: Array = [] # per prop kind: PackedFloat32Array (12 floats an instance, chunk-local)


## A chunk's props of one kind that are drawn alike: notched by an axe or
## not (the cut meshes, their notches in the custom data), casting shadows
## or not (by the biome each stands in). Each level of detail its own
## MultiMesh, holding only the trees near enough its span to show in it
## (_bucket), refilled as the camera moves.
class _Group:
	var notched := false
	var casts := false
	var full := PackedFloat32Array() # every tree's: 12 floats (16 notched: + its notch), from the nodes' position
	var stride := 12
	var uids := PackedInt64Array()
	var mids := PackedVector3Array() # each tree's middle (on the map), as lod_fade.gdshaderinc measures from
	var lo := Vector3.ZERO # their box (on the map)
	var hi := Vector3.ZERO
	var levels: Array = [] # [begin, end, MultiMesh, MultiMeshInstance3D, what it last held: -1 not yet, 0 none, 1 all, 2 some]
	var nodes: Array[Node3D] = []


func _ready() -> void:
	var kinds := _load_dir(PROP_DIR)
	# the first kinds as they always were (a kind's index seeds its placing
	# and is in its props' uids: the oaks and pawpaws where they stood, and
	# the saved felled trees still theirs), then the rest by name
	kinds.sort_custom(func(a, b) -> bool:
		var ia := FIRST_KINDS.find(String(a.id))
		var ib := FIRST_KINDS.find(String(b.id))
		ia = ia if ia >= 0 else FIRST_KINDS.size()
		ib = ib if ib >= 0 else FIRST_KINDS.size()
		return ia < ib if ia != ib else String(a.id) < String(b.id))
	for k in kinds:
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
			# density_like {biome: other biome}: as common there as this
			# variant is in the other; or, with like_group, as common as all the
			# variants marked with that group put together
			var like: Dictionary = vp[v].get("density_like", {})
			var group_share := share
			if vp[v].has("like_group"):
				group_share = 0.0
				for u in n:
					if vp[u].get(vp[v].like_group, false):
						group_share += float(vp[u].get("weight", 1.0)) / total
			for b in like:
				d[b] = float(k.density.get(like[b], 0.0)) * group_share
			kv.density = d
			for key in vp[v]:
				if not key in ["weight", "density_like", "like_group"] and key in kv:
					kv.set(key, vp[v][key])
		kv.set_meta("variant", v)
		if kv.mesh == null and kv.mesh_script:
			kv.mesh = kv.mesh_script.build(v)
		if kv.lods.is_empty() and kv.mesh_script and kv.mesh_script.has_method("build_lods"):
			kv.lods = kv.mesh_script.build_lods(v)
		if kv.walk.is_empty() and kv.mesh_script and kv.mesh_script.has_method("build_walk"):
			kv.walk = kv.mesh_script.build_walk(v)
		if kv.climb.is_empty() and kv.mesh_script and kv.mesh_script.has_method("build_climb"):
			kv.climb = kv.mesh_script.build_climb(v)
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
	for uid in _near:
		_near[uid].queue_free()
	_near.clear()
	for uid in _near_jobs:
		WorkerThreadPool.wait_for_task_completion(_near_jobs[uid][0])
	_near_jobs.clear()
	_near_mm.clear()
	_near_order.clear()
	_near_want.clear()
	_near_data.clear()
	_near_at = Vector3.INF
	_queue.clear()
	_centre = Vector2i.MAX


## Call every frame with the player's position (and the camera's, on the
## map: the trees' levels of detail go by it; else a little over the player).
func update(focus: Vector3, view := Vector3.INF) -> void:
	if world == null or (props.is_empty() and actor_kinds.is_empty()):
		return
	_focus = focus
	_view = view if view != Vector3.INF else focus + Vector3.UP * 1.6
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
	var batch := _done.slice(0, apply_per_frame)
	_done = _done.slice(apply_per_frame)
	_lock.unlock()
	for ch: _Chunk in batch:
		if _wanted(ch.key):
			_apply(ch)
	_rebucket()
	_update_near(focus)
	_update_actors(focus)


const NEAR := 4.5 ## m: the logs and stumps this near the player (to their mesh's furthest) get their sporophytes
const NEAR_KEEP := 24 ## Logs' worked-out sporophytes kept after the player leaves them (to come back to)

## What's drawn only close to the player (a kind's mesh_script.near_multimesh:
## the moss's sporophytes): one MultiMeshInstance3D per log or stump whose
## mesh reaches within NEAR of the focus, placed as that log is. Which of a
## log's sporophytes stand (those on its thick moss: the bark's own moss
## pattern, which goes by where the log lies and how it's turned) is worked
## out once, on a worker thread, when it comes near (_sporophytes_on_moss),
## and only those are drawn: before, every one of up to 40000 a log was
## drawn and its every corner worked out the moss to hide itself.
func _update_near(focus: Vector3) -> void:
	_collect_near()
	if focus.distance_to(_near_at) < 1.0 and walk_changes == _near_walks: # (NEAR's slack: the shader shows them within 4 m)
		return
	_near_at = focus
	_near_walks = walk_changes
	var want := {}
	var c := _key(focus)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var base := Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK)
			for k in ch.xforms.size():
				var nd := _near_of(k)
				if nd.is_empty():
					continue
				var xf: PackedFloat32Array = ch.xforms[k]
				var uids: PackedInt64Array = ch.uids[k]
				for i in uids.size():
					var j := i * 12
					var at := base + Vector3(xf[j + 3], xf[j + 7], xf[j + 11])
					var s := Vector3(xf[j], xf[j + 4], xf[j + 8]).length()
					if at.distance_to(focus) > NEAR + nd[2] * s or _removed.has(uids[i]):
						continue
					var b := Basis(Vector3(xf[j], xf[j + 4], xf[j + 8]), Vector3(xf[j + 1], xf[j + 5], xf[j + 9]), Vector3(xf[j + 2], xf[j + 6], xf[j + 10]))
					want[uids[i]] = [nd, Transform3D(b, at)]
	_near_want = want
	for uid in _near.keys():
		if not want.has(uid):
			_near[uid].queue_free()
			_near.erase(uid)
	for uid in want:
		if _near.has(uid) or _near_jobs.has(uid):
			continue
		if _near_mm.has(uid):
			_add_near(uid)
			continue
		var nd: Array = want[uid][0]
		var mat: ShaderMaterial = nd[1]
		var moss := moss_of(mat)
		var out := []
		var task := WorkerThreadPool.add_task(_sporophytes_on_moss.bind(nd[3], want[uid][1], moss, out))
		_near_jobs[uid] = [task, out, nd]


## A sporophyte material's moss settings (lichen.gdshaderinc): amount, low,
## spill, end (a setting left unset is null: the shader's default then).
static func moss_of(mat: ShaderMaterial) -> Vector4:
	var v := Vector4(0.0, 0.0, 0.0, 0.5)
	var names := ["moss_amount", "moss_low", "moss_spill", "moss_end"]
	for i in 4:
		var x = mat.get_shader_parameter(names[i])
		if x != null:
			v[i] = float(x)
	return v


## The near logs' sporophytes worked out since: drawn if still wanted.
func _collect_near() -> void:
	for uid in _near_jobs.keys():
		var job: Array = _near_jobs[uid]
		if not WorkerThreadPool.is_task_completed(job[0]):
			continue
		WorkerThreadPool.wait_for_task_completion(job[0])
		_near_jobs.erase(uid)
		var out: Array = job[1]
		var mm: MultiMesh = null
		var src: MultiMesh = job[2][0]
		if not out.is_empty() and out[1] > 0:
			mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.use_custom_data = true
			mm.mesh = src.mesh
			mm.instance_count = out[1]
			mm.buffer = out[0]
		_near_mm[uid] = mm
		_near_order.append(uid)
		while _near_order.size() > NEAR_KEEP:
			var old = _near_order.pop_front()
			if not _near.has(old) and not _near_want.has(old):
				_near_mm.erase(old)
			else:
				_near_order.append(old)
				break
		if _near_want.has(uid) and not _near.has(uid):
			_add_near(uid)


func _add_near(uid: int) -> void:
	var mm: MultiMesh = _near_mm[uid]
	if mm == null:
		return # (no thick moss on it)
	var nd: Array = _near_want[uid][0]
	var xf: Transform3D = _near_want[uid][1]
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = nd[1]
	mi.transform = xf
	mi.set_instance_shader_parameter("tree_at", xf.origin) # (on the map)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = (nd[0] as MultiMesh).get_aabb().grow(0.05)
	add_child(mi)
	_near[uid] = mi


## (A worker thread.) Of a log's sporophytes (src: its MultiMesh's buffer,
## 20 floats each: the transform's 12, colour, custom), those on its thick
## moss: the moss's field over 0.8, as the bark works it out
## (lichen.gdshaderinc moss_field) where the log lies (xf, on the map) and
## turned as it is. moss: amount, low, spill, end. out gets [buffer, count].
static func _sporophytes_on_moss(src: PackedFloat32Array, xf: Transform3D, moss: Vector4, out: Array) -> void:
	var keep := PackedFloat32Array()
	var n := 0
	if moss.x > 0.0:
		var off := Vector3(fposmod(xf.origin.x * 0.0137, 1.0), 0.0, fposmod(xf.origin.z * 0.0137, 1.0)) * 61.0
		for i in range(0, src.size(), 20):
			var custom := Vector3(src[i + 16], src[i + 17], src[i + 18])
			var up := (xf.basis * Vector3(src[i], src[i + 4], src[i + 8])).normalized().y
			var m := _moss_field(custom + off, up, moss)
			if src[i + 19] > 1.5:
				m *= moss.w
			if m >= 0.8:
				keep.append_array(src.slice(i, i + 20))
				n += 1
	out.append(keep)
	out.append(n)


## lichen.gdshaderinc moss_field (the same; moss: amount, low, spill).
static func _moss_field(p: Vector3, up: float, moss: Vector4) -> float:
	var top := smoothstep(-0.35, 0.7, up)
	var nz := _lc_noise(p * 2.2)
	var m := smoothstep(-0.25, 0.35, nz - 1.0 + moss.x * top)
	if moss.y > 0.0:
		var low := moss.y * smoothstep(0.8, 0.05, p.y)
		m = maxf(m, smoothstep(-0.15, 0.2, fposmod(nz * 7.31 + p.y * 0.7, 1.0) * 0.4 + nz * 0.6 - 0.88 + 0.42 * low))
	if moss.z > 0.0:
		var below := moss.z - p.y
		var tongue := _lc_noise(Vector3(p.x * 7.0, p.y * 1.2, p.z * 7.0) + Vector3(9.0, 9.0, 9.0))
		m = maxf(m, smoothstep(-0.15, 0.2, tongue - 0.45 - below * 1.6))
	return m


static func _lc_hash(x: float, y: float, z: float) -> float:
	x = fposmod(x * 0.1031, 1.0)
	y = fposmod(y * 0.1030, 1.0)
	z = fposmod(z * 0.0973, 1.0)
	var d := x * (y + 33.33) + y * (x + 33.33) + z * (z + 33.33)
	x += d
	y += d
	z += d
	return fposmod((x + y) * z, 1.0)


static func _lc_noise(p: Vector3) -> float:
	var ix := floorf(p.x)
	var iy := floorf(p.y)
	var iz := floorf(p.z)
	var fx := p.x - ix
	var fy := p.y - iy
	var fz := p.z - iz
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	fz = fz * fz * (3.0 - 2.0 * fz)
	var a := lerpf(lerpf(_lc_hash(ix, iy, iz), _lc_hash(ix + 1, iy, iz), fx), lerpf(_lc_hash(ix, iy + 1, iz), _lc_hash(ix + 1, iy + 1, iz), fx), fy)
	var b := lerpf(lerpf(_lc_hash(ix, iy, iz + 1), _lc_hash(ix + 1, iy, iz + 1), fx), lerpf(_lc_hash(ix, iy + 1, iz + 1), _lc_hash(ix + 1, iy + 1, iz + 1), fx), fy)
	return lerpf(a, b, fz)


func _near_of(k: int) -> Array:
	if not _near_data.has(k):
		var kind := props[k]
		var nd := []
		if kind.mesh_script and kind.mesh_script.has_method("near_multimesh"):
			nd = kind.mesh_script.near_multimesh(int(kind.get_meta("variant", 0)))
			if not nd.is_empty():
				var box: AABB = kind.mesh.get_aabb() if kind.mesh else AABB()
				var reach := 0.0
				for e in 8:
					reach = maxf(reach, box.get_endpoint(e).length())
				nd = [nd[0], nd[1], reach, (nd[0] as MultiMesh).buffer]
		_near_data[k] = nd
	return _near_data[k]


## How much of what should be round `focus` is in place, 0..1 (the share of
## the chunks within view that have been generated and added).
func load_progress(focus: Vector3) -> float:
	if world == null or (props.is_empty() and actor_kinds.is_empty()):
		return 1.0
	var c := _key(focus)
	var n := ceili(_radius / CHUNK) + 1
	var total := 0
	var done := 0
	for dz in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var key := c + Vector2i(dx, dz)
			if _chunk_dist(key, focus) <= _radius:
				total += 1
				if _chunks.has(key):
					done += 1
	return float(done) / maxf(total, 1)


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
	# logs and stumps: a wall to a body they stand too high above the feet
	# of (more than a step) and that isn't ducking under them
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var w := ch.walk
			for k in range(0, w.size(), 8):
				var a := _on_segment(w, k, q)
				var post := _is_post(w, k)
				var top := maxf(w[k + 1], w[k + 4]) if post else a.y + a.w
				var bottom := minf(w[k + 1], w[k + 4]) if post else a.y - a.w
				if top <= p.y + STEP_UP or bottom >= p.y + BODY_HEIGHT:
					continue
				var d := q - Vector2(a.x, a.z)
				var min_d := a.w + r
				var l2 := d.length_squared()
				if l2 < min_d * min_d:
					var l := sqrt(l2)
					q += (d / l if l > 1e-4 else Vector2.RIGHT) * (min_d - l)
	return Vector3(q.x, p.y, q.y)


## The top of whatever can be stood on (fallen logs, stumps) at p (world; a sole of
## radius foot), the highest no higher than `below`; -INF if nothing.
func deck_at(p: Vector3, below: float, foot := 0.15) -> float:
	var best := -INF
	if _chunks.is_empty():
		return best
	var c := _key(p)
	var q := Vector2(p.x, p.z)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var w := ch.walk
			for k in range(0, w.size(), 8):
				var a := _on_segment(w, k, q)
				var d := maxf(q.distance_to(Vector2(a.x, a.z)) - foot, 0.0)
				if d < a.w:
					var top := maxf(w[k + 1], w[k + 4]) if _is_post(w, k) else a.y + sqrt(a.w * a.w - d * d)
					if top <= below and top > best:
						best = top
	return best


## What the grass is kept out of within r of p, nearest first, at most n:
## the segments that can be stood on over the ground (logs, stumps:
## PropKind.walk) and the solid trunks and boulders (their obstacles, a
## little wider than they are: a trunk's roots flare out), in xs Vector4(ax,
## az, bx, bz) (a trunk: a = b, its middle), in rs each one's radius (a
## segment's larger end's). (GroundCover: nothing grows through them.)
func walk_near(p: Vector3, r: float, n: int, xs: PackedVector4Array, rs: PackedFloat32Array, ds := PackedFloat32Array()) -> void:
	var found: Array = [] # [distance, Vector4, radius]
	var q := Vector2(p.x, p.z)
	var c := _key(p)
	var reach := ceili(r / CHUNK)
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var w := ch.walk
			for k in range(0, w.size(), 8):
				if w[k + 6] < 0.0:
					continue # (a tree's limb, up in the air)
				var a := _on_segment(w, k, q)
				var d := q.distance_to(Vector2(a.x, a.z))
				if d < r:
					found.append([d, Vector4(w[k], w[k + 2], w[k + 3], w[k + 5]), maxf(absf(w[k + 6]), w[k + 7])])
			var o := ch.obstacles
			for k in range(0, o.size(), 3):
				var d := q.distance_to(Vector2(o[k], o[k + 1]))
				if d < r:
					found.append([d, Vector4(o[k], o[k + 1], o[k], o[k + 1]), o[k + 2] * OBSTACLE_GRASS])
	found.sort_custom(func(u, v): return u[0] < v[0])
	for i in mini(found.size(), n):
		xs.append(found[i][1])
		rs.append(found[i][2])
		ds.append(found[i][0]) # (how far, if wanted)


const OBSTACLE_GRASS := 1.2 ## a trunk's (boulder's) radius x this is kept clear of grass (the roots' flare)


## Segment k of w stands steeper than 45°: a post (a stump), flat on top,
## not a log lying round.
static func _is_post(w: PackedFloat32Array, k: int) -> bool:
	return w[k + 6] >= 0.0 and absf(w[k + 4] - w[k + 1]) > Vector2(w[k + 3] - w[k], w[k + 5] - w[k + 2]).length()


## The point of segment k of w (a log's axis) nearest q over the ground
## (x, y, z) and the log's radius there (w).
static func _on_segment(w: PackedFloat32Array, k: int, q: Vector2) -> Vector4:
	var a := Vector2(w[k], w[k + 2])
	var ab := Vector2(w[k + 3], w[k + 5]) - a
	var l2 := ab.length_squared()
	var t := clampf((q - a).dot(ab) / l2, 0.0, 1.0) if l2 > 1e-6 else 0.0
	var at := a + ab * t
	return Vector4(at.x, lerpf(w[k + 1], w[k + 4], t), at.y, lerpf(absf(w[k + 6]), w[k + 7], t))


## Appends instance i's walkable segments (kind.walk), in the world.
static func _add_walk(out: PackedFloat32Array, kind: PropKind, xf: PackedFloat32Array, i: int, base: Vector3) -> void:
	var w := kind.walk
	if w.is_empty():
		return
	var j := i * 12
	var b := Basis(Vector3(xf[j], xf[j + 4], xf[j + 8]), Vector3(xf[j + 1], xf[j + 5], xf[j + 9]), Vector3(xf[j + 2], xf[j + 6], xf[j + 10]))
	var t := Transform3D(b, Vector3(xf[j + 3], xf[j + 7], xf[j + 11]) + base)
	var s := b.x.length()
	for k in range(0, w.size(), 8):
		var a := t * Vector3(w[k], w[k + 1], w[k + 2])
		var e := t * Vector3(w[k + 3], w[k + 4], w[k + 5])
		out.append_array([a.x, a.y, a.z, e.x, e.y, e.z, w[k + 6] * s, w[k + 7] * s])


## Appends instance i's climbable lines (kind.climb), in the world.
static func _add_trunk(out: Array[PackedFloat32Array], kind: PropKind, xf: PackedFloat32Array, i: int, base: Vector3) -> void:
	var c := kind.climb
	if c.is_empty():
		return
	var j := i * 12
	var b := Basis(Vector3(xf[j], xf[j + 4], xf[j + 8]), Vector3(xf[j + 1], xf[j + 5], xf[j + 9]), Vector3(xf[j + 2], xf[j + 6], xf[j + 10]))
	var t := Transform3D(b, Vector3(xf[j + 3], xf[j + 7], xf[j + 11]) + base)
	var s := b.x.length()
	var k := 0
	while k < c.size():
		var n := int(c[k])
		k += 1
		var tr := PackedFloat32Array()
		for m in n:
			var p := t * Vector3(c[k], c[k + 1], c[k + 2])
			tr.append_array([p.x, p.y, p.z, c[k + 3] * s])
			k += 4
		out.append(tr)


## The climbable lines (trunks, limbs: x, y, z, radius a node, from where
## each starts) whose bark is within reach (m) of p: [[line, gap], ...],
## nearest first.
func climbs_near(p: Vector3, reach: float) -> Array:
	var found := []
	var c := _key(p)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			for tr in ch.trunks:
				if Vector2(tr[0] - p.x, tr[2] - p.z).length_squared() > 400.0:
					continue
				var f := trunk_frame(tr, trunk_nearest(tr, p))
				var gap := (p - (f[0] as Vector3)).length() - (f[1] as float)
				if gap < reach:
					found.append([tr, gap])
	found.sort_custom(func(u, v): return u[1] < v[1])
	return found


## The climbable line whose bark is nearest p, if within reach; empty if none.
func trunk_near(p: Vector3, reach: float) -> PackedFloat32Array:
	var f := climbs_near(p, reach)
	return f[0][0] if not f.is_empty() else PackedFloat32Array()


## A trunk's length along its axis (m).
static func trunk_length(tr: PackedFloat32Array) -> float:
	var l := 0.0
	for k in range(4, tr.size(), 4):
		l += Vector3(tr[k] - tr[k - 4], tr[k + 1] - tr[k - 3], tr[k + 2] - tr[k - 2]).length()
	return l


## The trunk s m up its axis: [axis point, radius, axis direction (up)].
static func trunk_frame(tr: PackedFloat32Array, s: float) -> Array:
	var walked := 0.0
	for k in range(4, tr.size(), 4):
		var a := Vector3(tr[k - 4], tr[k - 3], tr[k - 2])
		var b := Vector3(tr[k], tr[k + 1], tr[k + 2])
		var l := a.distance_to(b)
		if s <= walked + l or k + 4 >= tr.size():
			var t := clampf((s - walked) / maxf(l, 1e-4), 0.0, 1.0)
			return [a.lerp(b, t), lerpf(tr[k - 1], tr[k + 3], t), (b - a) / maxf(l, 1e-4)]
		walked += l
	return [Vector3(tr[0], tr[1], tr[2]), tr[3], Vector3.UP]


## How far up its axis (m) a trunk passes nearest p.
static func trunk_nearest(tr: PackedFloat32Array, p: Vector3) -> float:
	var best := INF
	var best_s := 0.0
	var walked := 0.0
	for k in range(4, tr.size(), 4):
		var a := Vector3(tr[k - 4], tr[k - 3], tr[k - 2])
		var b := Vector3(tr[k], tr[k + 1], tr[k + 2])
		var ab := b - a
		var l2 := ab.length_squared()
		var t := clampf((p - a).dot(ab) / maxf(l2, 1e-6), 0.0, 1.0)
		var d := p.distance_squared_to(a + ab * t)
		if d < best:
			best = d
			best_s = walked + t * sqrt(l2)
		walked += sqrt(l2)
	return best_s


## A felled tree, to stand on and climb as the logs and trees are (Felling):
## walk, segments over the ground as PropKind.walk's in the world (8 floats
## each); trunks, its climbable lines as PropKind.climb's in the world (x, y,
## z, radius a node). Kept with the chunk its first point is in.
func add_fallen(walk: PackedFloat32Array, trunks: Array[PackedFloat32Array]) -> void:
	if trunks.is_empty() and walk.is_empty():
		return
	var at := Vector3(trunks[0][0], 0.0, trunks[0][2]) if not trunks.is_empty() else Vector3(walk[0], 0.0, walk[2])
	var key := _key(at)
	if not _fallen.has(key):
		_fallen[key] = [PackedFloat32Array(), [] as Array[PackedFloat32Array]]
	var f: Array = _fallen[key]
	var fw: PackedFloat32Array = f[0]
	fw.append_array(walk)
	f[0] = fw # (packed arrays are values: put it back)
	(f[1] as Array).append_array(trunks)
	var ch: _Chunk = _chunks.get(key)
	if ch:
		var w := ch.walk
		w.append_array(walk)
		ch.walk = w
		ch.trunks.append_array(trunks)
		walk_changes += 1


func _merge_fallen(ch: _Chunk) -> void:
	if _fallen.has(ch.key):
		var w := ch.walk
		w.append_array(_fallen[ch.key][0])
		ch.walk = w
		ch.trunks.append_array(_fallen[ch.key][1])


## A tree's notch, as far as the axe has cut it (Felling): the bark shader's
## INSTANCE_CUSTOM (bark.gdshader: direction, depth, height, radius, in the
## tree's own units). Its chunk is rebuilt with it. Saved with the game
## (notches_to_dict: a maple's notch drips sap, Tapping).
func set_notch(uid: int, notch: Color) -> void:
	var was := _notches.has(uid)
	_notches[uid] = notch
	var ch: _Chunk = _chunks.get(_uid_key(uid))
	if ch == null:
		return
	var k := (uid >> 16) & 0xFF
	if was:
		# (cut deeper: only its notch, in its group's data)
		for g: _Group in ch.groups.get(k, []):
			var i := g.uids.find(uid)
			if g.notched and i >= 0:
				var full := g.full # (a value: changed, then put back)
				for j in 4:
					full[i * 16 + 12 + j] = notch[j]
				g.full = full
				_bucket(g, true)
				return
	_build_kind(ch, k) # (first cut: into a group of its own, the cut meshes')


## The notches an axe has cut: tree uid -> its notch (set_notch's Color).
func notches() -> Dictionary:
	return _notches


func notches_to_dict() -> Dictionary:
	var out := {}
	for uid in _notches:
		var c: Color = _notches[uid]
		out[str(uid)] = [c.r, c.g, c.b, c.a]
	return out


func notches_from_dict(d: Dictionary) -> void:
	for k in d:
		var a = d[k]
		if a is Array and a.size() == 4:
			set_notch(int(k), Color(a[0], a[1], a[2], a[3]))


## A standing prop by its uid, if its chunk's in: {uid, kind, variant,
## transform (on the map)}, or {}.
func tree_by_uid(uid: int) -> Dictionary:
	var ch: _Chunk = _chunks.get(_uid_key(uid))
	if ch == null or _removed.has(uid):
		return {}
	var k := (uid >> 16) & 0xFF
	if k >= ch.uids.size():
		return {}
	var uids: PackedInt64Array = ch.uids[k]
	var i := uids.find(uid)
	if i < 0:
		return {}
	var xf: PackedFloat32Array = ch.xforms[k]
	var j := i * 12
	var base := Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK)
	var b := Basis(Vector3(xf[j], xf[j + 4], xf[j + 8]), Vector3(xf[j + 1], xf[j + 5], xf[j + 9]), Vector3(xf[j + 2], xf[j + 6], xf[j + 10]))
	var kind := props[k]
	return {"uid": uid, "kind": kind, "variant": int(kind.get_meta("variant", 0)), "transform": Transform3D(b, base + Vector3(xf[j + 3], xf[j + 7], xf[j + 11]))}


func _uid_key(uid: int) -> Vector2i:
	return Vector2i(uid >> 43, (uid >> 24) & 0x7FFFF) - Vector2i(UID_OFFSET, UID_OFFSET)


## Takes a prop out of the world for good (uid: from prop_at()).
func remove_prop(uid: int) -> void:
	_removed[uid] = true
	_notches.erase(uid)
	var ch: _Chunk = _chunks.get(_uid_key(uid))
	if ch:
		_build_props(ch)


## The standing tree an axe swung from eye (on the map) toward fwd would
## strike: its trunk within reach (m, from the trunk's surface), and in
## front, within 40 degrees of fwd across the ground. {uid, kind, variant,
## transform (on the map), radius (the trunk's, scaled)} or {} for none.
func choppable_near(eye: Vector3, fwd: Vector3, reach: float) -> Dictionary:
	var best := {}
	var best_score := INF
	var f := Vector2(fwd.x, fwd.z).normalized()
	var c := _key(eye)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var base := Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK)
			for k in ch.xforms.size():
				var kind := props[k]
				var v := int(kind.get_meta("variant", 0))
				if kind.mesh_script == null or not kind.mesh_script.has_method("choppable") or not kind.mesh_script.choppable(v):
					continue
				var xf: PackedFloat32Array = ch.xforms[k]
				var uids: PackedInt64Array = ch.uids[k]
				for i in uids.size():
					var j := i * 12
					var at := base + Vector3(xf[j + 3], xf[j + 7], xf[j + 11])
					var to := Vector2(at.x - eye.x, at.z - eye.z)
					var s := Vector3(xf[j], xf[j + 4], xf[j + 8]).length()
					var r: float = kind.mesh_script.trunk_radius(v) * s
					var gap := to.length() - r
					if gap > reach or eye.y < at.y - 0.5 or eye.y > at.y + 4.0 or _removed.has(uids[i]):
						continue
					var cosine := f.dot(to.normalized()) if to.length() > 0.01 else 1.0
					if cosine < cos(deg_to_rad(40.0)) and gap > 0.25:
						continue
					var score := gap + (1.0 - cosine)
					if score < best_score:
						best_score = score
						var b := Basis(Vector3(xf[j], xf[j + 4], xf[j + 8]), Vector3(xf[j + 1], xf[j + 5], xf[j + 9]), Vector3(xf[j + 2], xf[j + 6], xf[j + 10]))
						best = {"uid": uids[i], "kind": kind, "variant": v, "transform": Transform3D(b, at), "radius": r}
	return best


## The fruiting tree (a kind whose mesh_script's fruit_of(variant) names an
## item: a pawpaw's) within reach of eye (its crown: reach m out from the
## trunk), in front (fwd); as choppable_near's, plus "fruit" (the item id),
## or {} for none.
func fruit_near(eye: Vector3, fwd: Vector3, reach: float) -> Dictionary:
	var best := {}
	var best_score := INF
	var f := Vector2(fwd.x, fwd.z).normalized()
	var c := _key(eye)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var base := Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK)
			for k in ch.xforms.size():
				var kind := props[k]
				var v := int(kind.get_meta("variant", 0))
				if kind.mesh_script == null or not kind.mesh_script.has_method("fruit_of"):
					continue
				var fruit: String = kind.mesh_script.fruit_of(v)
				if fruit == "":
					continue
				var xf: PackedFloat32Array = ch.xforms[k]
				var uids: PackedInt64Array = ch.uids[k]
				for i in uids.size():
					var j := i * 12
					var at := base + Vector3(xf[j + 3], xf[j + 7], xf[j + 11])
					var to := Vector2(at.x - eye.x, at.z - eye.z)
					var gap := to.length()
					if gap > reach or eye.y < at.y - 1.0 or eye.y > at.y + 6.0 or _removed.has(uids[i]):
						continue
					var cosine := f.dot(to.normalized()) if gap > 0.01 else 1.0
					if cosine < cos(deg_to_rad(60.0)) and gap > 1.0:
						continue
					var score := gap + 2.0 * (1.0 - cosine)
					if score < best_score:
						best_score = score
						best = {"uid": uids[i], "kind": kind, "variant": v, "fruit": fruit}
	return best


## Every fruiting tree within r of p (Foraging hangs their fruit): each
## {uid, kind, variant, transform (on the map), fruit}.
func fruit_trees_near(p: Vector3, r: float) -> Array:
	var out := []
	var c := _key(p)
	var n := ceili(r / CHUNK)
	for dz in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var ch: _Chunk = _chunks.get(c + Vector2i(dx, dz))
			if ch == null:
				continue
			var base := Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK)
			for k in ch.xforms.size():
				var kind := props[k]
				var v := int(kind.get_meta("variant", 0))
				if kind.mesh_script == null or not kind.mesh_script.has_method("fruit_of"):
					continue
				var fruit: String = kind.mesh_script.fruit_of(v)
				if fruit == "":
					continue
				var xf: PackedFloat32Array = ch.xforms[k]
				var uids: PackedInt64Array = ch.uids[k]
				for i in uids.size():
					var j := i * 12
					var at := base + Vector3(xf[j + 3], xf[j + 7], xf[j + 11])
					if Vector2(at.x - p.x, at.z - p.z).length() > r or _removed.has(uids[i]):
						continue
					var b := Basis(Vector3(xf[j], xf[j + 4], xf[j + 8]), Vector3(xf[j + 1], xf[j + 5], xf[j + 9]), Vector3(xf[j + 2], xf[j + 6], xf[j + 10]))
					out.append({"uid": uids[i], "kind": kind, "variant": v, "transform": Transform3D(b, at), "fruit": fruit})
	return out


## The prop kind made from mesh_script's variant v (null if none).
func kind_of(mesh_script: Script, v: int) -> PropKind:
	for k in props:
		if k.mesh_script == mesh_script and int(k.get_meta("variant", -1)) == v:
			return k
	return null


## The prop kind with this id (null if none).
func kind_by_id(id: StringName) -> PropKind:
	for k in props:
		if k.id == id:
			return k
	return null


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
		k.resolve_clump(world.biome_names)
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
	var walk := PackedFloat32Array()
	var trunks: Array[PackedFloat32Array] = []
	for k in props.size():
		var kind := props[k]
		var xf := PackedFloat32Array()
		var uids := PackedInt64Array()
		var peak := kind.peak_clumped()
		var placed := PackedVector2Array() # (for min_spacing)
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
				# (the biomes blended across their borders, as the ground's: a
				# pick by a hash of the place, so the rng's draws stay as they were)
				var u := fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
				var bi: int
				if kind.strays:
					# straying over the border: the biome read a few hundred
					# metres off, at random, so a kind thins out across it
					var ox := (fposmod(sin(x * 39.346 + z * 11.135) * 24634.634, 1.0) - 0.5) * 700.0
					var oz := (fposmod(sin(x * 73.156 + z * 52.235) * 51381.457, 1.0) - 0.5) * 700.0
					bi = world.biome_blend_at(x + ox * u, z + oz * u, u)
				else:
					bi = world.biome_blend_at(x, z, u)
				var dc := kind.density_in(bi) * kind.clump_at(bi, x, z)
				if kind.swamp_depth != Vector2.ZERO and bi == world.swamp and keep < dc * maxf(kind.swamp_depth.x, kind.swamp_depth.y):
					dc *= lerpf(kind.swamp_depth.x, kind.swamp_depth.y, world.swamp_depth(x, z)) # (more at the edge, or in the middle)
				if keep >= dc:
					continue
				if kind.strict and kind.density_in(world.biome_blend_at(x, z, u)) <= 0.0:
					continue # (strayed onto ground it doesn't grow in)
				if kind.not_in_swamp and world.swamp >= 0 and (world.swampiness(x, z) > 0.0 or world.biome_blend_at(x, z, u) == world.swamp):
					continue # (none in the swamp, nor its muddy edge)
				if kind.strays:
					# thinning out up the mountains, gone at the top of its range
					var top := kind.height_range.y
					if keep >= dc * (1.0 - smoothstep(top * 0.5, top, world.base_height(x, z))):
						continue
				if kind.min_spacing > 0.0:
					var crowded := false
					for q in placed:
						if q.distance_squared_to(Vector2(x, z)) < kind.min_spacing * kind.min_spacing:
							crowded = true
							break
					if crowded:
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
				# (on a slope, sunk as far as the ground falls away under its foot)
				var fall := kind.foot * s * sqrt(maxf(1.0 - nrm.y * nrm.y, 0.0)) / maxf(nrm.y, 0.3)
				var o := Vector3(x - base.x, h - kind.sink * s - fall, z - base.y)
				xf.append_array([b.x.x, b.y.x, b.z.x, o.x, b.x.y, b.y.y, b.z.y, o.y, b.x.z, b.y.z, b.z.z, o.z])
				placed.append(Vector2(x, z))
				var uid := _uid(key, k, i)
				uids.append(uid)
				if kind.radius > 0.0:
					obstacles.append_array([x, z, kind.radius * s])
				_add_walk(walk, kind, xf, xf.size() / 12 - 1, Vector3(base.x, 0.0, base.y))
				_add_trunk(trunks, kind, xf, xf.size() / 12 - 1, Vector3(base.x, 0.0, base.y))
		ch.xforms.append(xf)
		ch.uids.append(uids)
	ch.obstacles = obstacles
	ch.walk = walk
	ch.trunks = trunks
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
	_merge_fallen(ch)
	_build_props(ch)
	if not ch.walk.is_empty():
		walk_changes += 1


## (Re)build a chunk's MultiMeshes.
func _build_props(ch: _Chunk) -> void:
	for k in ch.groups.keys():
		_free_groups(ch, k)
	if not _removed.is_empty():
		_drop_removed(ch)
	for k in ch.xforms.size():
		_build_kind(ch, k)
	ch.bucket_at = _view


func _free_groups(ch: _Chunk, k: int) -> void:
	for g: _Group in ch.groups.get(k, []):
		for n in g.nodes:
			n.queue_free()
	ch.groups.erase(k)


## (Re)build what a chunk draws of kind k: its trees in groups drawn alike
## (_Group: notched or not, casting shadows or not), each a MultiMesh a
## level of detail, sorted (_bucket).
func _build_kind(ch: _Chunk, k: int) -> void:
	_free_groups(ch, k)
	var xf: PackedFloat32Array = ch.xforms[k]
	if xf.is_empty():
		return
	var kind := props[k]
	var uids: PackedInt64Array = ch.uids[k]
	var at := Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK)
	var none := _shadowless(kind)
	var parts := {} # 2 notched + 1 casting -> its trees' indices
	for i in uids.size():
		var casts := kind.shadows and not world.biome_index_at(at.x + xf[i * 12 + 3], at.z + xf[i * 12 + 11]) in none
		var key := (2 if _notches.has(uids[i]) else 0) + (1 if casts else 0)
		if not parts.has(key):
			parts[key] = PackedInt32Array()
		var list: PackedInt32Array = parts[key]
		list.append(i)
		parts[key] = list
	var groups: Array[_Group] = []
	for key: int in parts:
		var g := _make_group(kind, xf, uids, parts[key], key >= 2, key % 2 == 1, at)
		_bucket(g, true)
		groups.append(g)
	ch.groups[k] = groups


## The biomes (indices) a kind casts no shadow in: its own (shadowless_in)
## and every kind's (SHADOWLESS).
func _shadowless(kind: PropKind) -> PackedInt32Array:
	var none := PackedInt32Array()
	if world == null:
		return none
	for b in Array(kind.shadowless_in) + SHADOWLESS:
		var i := world.biome_names.find(b)
		if i >= 0:
			none.append(i)
	return none


func _make_group(kind: PropKind, xf: PackedFloat32Array, uids: PackedInt64Array, idx: PackedInt32Array, notched: bool, casts: bool, at: Vector3) -> _Group:
	var g := _Group.new()
	g.notched = notched
	g.casts = casts
	g.stride = 16 if notched else 12
	# (built here and then given to it: packed arrays are values)
	var gx := PackedFloat32Array()
	gx.resize(idx.size() * 12)
	var gu := PackedInt64Array()
	for n in idx.size():
		var i := idx[n]
		for j in 12:
			gx[n * 12 + j] = xf[i * 12 + j]
		gu.append(uids[i])
	g.uids = gu
	# the nodes stand at the middle of the group's box (and the trees are
	# placed from there): Godot measures visibility distance from a node's
	# origin, which must not be off at the chunk's corner at sea level,
	# hundreds of metres from the trees. All its levels get the same box
	# (round every mesh they draw), so they hand over alike.
	var box := _chunk_box(kind, gx)
	var mid := box.get_center()
	for n in idx.size():
		gx[n * 12 + 3] -= mid.x
		gx[n * 12 + 7] -= mid.y
		gx[n * 12 + 11] -= mid.z
	box.position -= mid
	var origin := at + mid
	var full := PackedFloat32Array()
	full.resize(idx.size() * g.stride)
	var mids := PackedVector3Array()
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for n in idx.size():
		for j in 12:
			full[n * g.stride + j] = gx[n * 12 + j]
		if notched:
			var c: Color = _notches.get(gu[n], Color(0, 0, 0, 0))
			for j in 4:
				full[n * 16 + 12 + j] = c[j]
		var o := n * 12
		var m := origin + Vector3(gx[o + 3], gx[o + 7], gx[o + 11]) + Vector3(gx[o + 1], gx[o + 5], gx[o + 9]) * LOD_MID
		mids.append(m)
		lo = lo.min(m)
		hi = hi.max(m)
	g.full = full
	g.mids = mids
	g.lo = lo
	g.hi = hi
	var n_lods := mini(kind.lods.size(), kind.lod_distances.size())
	var meshes: Array = [kind.mesh] + kind.lods
	if notched and kind.mesh_script and kind.mesh_script.has_method("cut_meshes"):
		# (a tree being felled: the cut variant, its notch a real hollow)
		var cm: Array = kind.mesh_script.cut_meshes(int(kind.get_meta("variant", 0)))
		meshes = [cm[0]] + cm[1]
	for l in n_lods + 1:
		var begin := 0.0 if l == 0 else kind.lod_distances[l - 1]
		var end := kind.view_distance if l == n_lods else minf(kind.lod_distances[l], kind.view_distance)
		if begin >= end:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = notched
		mm.mesh = meshes[l]
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.position = origin
		var mat := kind.material if l == 0 or kind.lod_material == null else kind.lod_material
		if mat:
			mi.material_override = mat
		var shadows := casts and begin < kind.shadow_distance and kind.shadow_mesh == null
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = box
		# (a backstop: the MultiMesh holds only the trees near its span, and
		# the shader fades each tree in and out of it, lod_fade.gdshaderinc)
		var pad := CHUNK + LOD_FADE * 2.0
		mi.visibility_range_begin = maxf(begin - pad, 0.0) if l > 0 else 0.0
		mi.visibility_range_end = end + pad
		add_child(mi)
		g.nodes.append(mi)
		g.levels.append([begin, end, mm, mi, -1])
	if kind.shadow_mesh and casts:
		# the stand-in, only in the shadow maps (every tree of the group, to
		# the shadows' distance)
		var smm := MultiMesh.new()
		smm.transform_format = MultiMesh.TRANSFORM_3D
		smm.mesh = kind.shadow_mesh
		smm.instance_count = idx.size()
		smm.buffer = gx
		var smi := MultiMeshInstance3D.new()
		smi.multimesh = smm
		smi.position = origin
		smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		smi.custom_aabb = box
		smi.visibility_range_end = kind.shadow_distance
		smi.visibility_range_end_margin = CHUNK * 0.5
		add_child(smi)
		g.nodes.append(smi)
	return g


## Puts into each level's MultiMesh only the group's trees near enough its
## span to show in it (from the camera, _view: as lod_fade.gdshaderinc
## measures, with its fade and LOD_SLACK to spare either side): none of the
## rest's vertices worked out only to be collapsed. A level all or none of
## the group is in is left as it was unless forced.
func _bucket(g: _Group, force := false) -> void:
	if _view == Vector3.INF:
		return
	var box_near := _view.clamp(g.lo, g.hi).distance_to(_view)
	var box_far := 0.0
	for c in 8:
		var q := Vector3(g.lo.x if c & 1 else g.hi.x, g.lo.y if c & 2 else g.hi.y, g.lo.z if c & 4 else g.hi.z)
		box_far = maxf(box_far, q.distance_to(_view))
	var count := g.uids.size()
	for lv: Array in g.levels:
		var lo: float = lv[0] - LOD_FADE - LOD_SLACK if lv[0] > 0.0 else -INF
		var hi: float = lv[1] + LOD_FADE + LOD_SLACK
		var state := 2
		if box_near > hi or box_far < lo:
			state = 0
		elif box_near >= lo and box_far <= hi:
			state = 1
		if state != 2 and state == lv[4] and not force:
			continue
		lv[4] = state
		var mm: MultiMesh = lv[2]
		var mi: MultiMeshInstance3D = lv[3]
		var buf := g.full
		var n := count
		if state == 0:
			n = 0
		elif state == 2:
			buf = PackedFloat32Array()
			n = 0
			for i in count:
				var d := g.mids[i].distance_to(_view)
				if d >= lo and d <= hi:
					buf.append_array(g.full.slice(i * g.stride, (i + 1) * g.stride))
					n += 1
		mm.instance_count = n
		if n > 0:
			mm.buffer = buf
		mi.visible = n > 0


## Sorts the trees of the chunks the camera has moved LOD_SLACK / 2 from
## since they were last sorted (BUCKETS_PER_FRAME at the least a frame, more
## when many are due).
func _rebucket() -> void:
	var due: Array[_Chunk] = []
	for ch: _Chunk in _chunks.values():
		if ch.bucket_at.distance_to(_view) > LOD_SLACK * 0.5:
			due.append(ch)
	var n := mini(due.size(), maxi(BUCKETS_PER_FRAME, due.size() / 6))
	for i in n:
		var ch := due[i]
		ch.bucket_at = _view
		for k in ch.groups:
			for g: _Group in ch.groups[k]:
				_bucket(g)


## A box (chunk-local) round everything a kind draws in a chunk: each
## instance's box (round the largest of its meshes, turned, tilted and
## scaled as it stands), all together, a little wider (the twigs' sway).
## (Not the mesh's box as it is, unturned: a long log lying across that
## stuck out of it, and with the box out of view the whole chunk was culled,
## the log's end with it, though in view.)
func _chunk_box(kind: PropKind, xf: PackedFloat32Array) -> AABB:
	var m := AABB()
	for mesh in [kind.mesh, kind.shadow_mesh] + kind.lods:
		if mesh:
			m = m.merge(mesh.get_aabb())
	var c := m.get_center()
	var e := m.size * 0.5
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for i in range(0, xf.size(), 12):
		# (a row of the instance's basis, then its origin: x, y, z in turn)
		var cc := Vector3.ZERO
		var ee := Vector3.ZERO
		for r in 3:
			var k := i + r * 4
			cc[r] = xf[k] * c.x + xf[k + 1] * c.y + xf[k + 2] * c.z + xf[k + 3]
			ee[r] = absf(xf[k]) * e.x + absf(xf[k + 1]) * e.y + absf(xf[k + 2]) * e.z
		lo = lo.min(cc - ee)
		hi = hi.max(cc + ee)
	return AABB(lo, hi - lo).grow(0.3)


## Leave out what remove_prop() took (instances and their obstacles).
func _drop_removed(ch: _Chunk) -> void:
	var obstacles := PackedFloat32Array()
	var walk := PackedFloat32Array()
	var trunks: Array[PackedFloat32Array] = []
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
			_add_walk(walk, kind, xf, i, Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK))
			_add_trunk(trunks, kind, xf, i, Vector3(ch.key.x * CHUNK, 0.0, ch.key.y * CHUNK))
		ch.xforms[k] = keep_xf
		ch.uids[k] = keep_uids
	ch.obstacles = obstacles
	ch.walk = walk
	ch.trunks = trunks
	_merge_fallen(ch)
	walk_changes += 1


func _unload(key: Vector2i) -> void:
	var ch: _Chunk = _chunks.get(key)
	if ch == null:
		return
	for k in ch.groups.keys():
		_free_groups(ch, k)
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
