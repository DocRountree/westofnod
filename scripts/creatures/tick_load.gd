extends Node
## The ticks on a host (a mammal on the four-legged make: Carnivore's, with
## its one skin, MammalSkin): each pinned to a place on its skin (a
## vertex of it, by the bone that carries it most: so it goes where that
## part of the body goes, turning, walking, lying dead) or on an ear, its
## mouthparts in, its legs splayed gripping; drawn as the colonies' ticks
## are (Ticks.look: the species' mesh and material), a MultiMesh for each
## body part and species.
##
## TickLoad.of(host): the host's (made the first time). attach(colony, i):
## a questing tick come aboard (Ticks._hosts): it feeds (FEED_SECS), swelling,
## then drops off where the host is then (colony.dropped). infest(n): a
## heavy load all at once, as a deer in a bad tick year: most on its head,
## its ears, round its eyes, down its neck and onto its shoulders and
## chest, fewer on its legs and belly, the rest few; most adults (lone star
## and blacklegged), many females engorged, swollen grey; some nymphs, and
## clusters of seed ticks (larvae).

const TicksScript := preload("res://scripts/creatures/ticks.gd")
const LONE_STAR := preload("res://scripts/creatures/lone_star_ticks.gd")
const BLACKLEGGED := preload("res://scripts/creatures/blacklegged_ticks.gd")

var host: Node3D
var _sites: Array = [] # [parent node, local point, local normal, weight]
var _cum: PackedFloat32Array
var _ticks: Array = [] # {sp, site, turn, stage, eng, rate, colony, i, seed, t}
var _mmis := {} # "site parent id:species path" -> MultiMeshInstance3D
var _dirty := true
var _t := 0.0
var rng := RandomNumberGenerator.new()
var _pending := 0
static var _mats := {} # species -> its attached material


## The host's load (made the first time).
static func of(h: Node3D) -> Node:
	var tl := h.get_node_or_null("TickLoad")
	if tl:
		return tl
	tl = (load("res://scripts/creatures/tick_load.gd") as GDScript).new()
	tl.name = "TickLoad"
	tl.set("host", h)
	h.add_child(tl)
	return tl


func _ready() -> void:
	rng.randomize()


## Where ticks can be (once): every few vertices of its skin, weighted by
## where ticks gather (the head, the ears, the neck most), and its ears.
func _find_sites() -> void:
	if not _sites.is_empty() or host == null:
		return
	var skin: Variant = host.get("_skin")
	var torso := host.get("_torso") as MeshInstance3D
	if skin == null or torso == null or torso.mesh == null:
		return
	var skel: Skeleton3D = (skin as Object).get("skel")
	var arr := torso.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var bs: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var ws: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var atts := {}
	var front_z := INF
	var back_z := -INF
	for k in vs.size():
		front_z = minf(front_z, vs[k].z)
		back_z = maxf(back_z, vs[k].z)
	for k in range(0, vs.size(), 2):
		# its bone: the one that carries it most
		var best := 0
		for j in 4:
			if ws[k * 4 + j] > ws[k * 4 + best]:
				best = j
		var b := bs[k * 4 + best]
		var bname := skel.get_bone_name(b)
		var w := 0.0
		if bname == "head":
			w = 1.0
		elif bname == "jaw":
			w = 0.45
		elif bname == "neck":
			w = 1.1
		elif bname == "torso":
			var fz := clampf((vs[k].z - front_z) / maxf(back_z - front_z, 1.0), 0.0, 1.0) # (0 its front .. 1 its rump)
			w = lerpf(0.6, 0.05, smoothstep(0.15, 0.55, fz))
			if ns[k].y < -0.5: # (its belly, between its legs)
				w = maxf(w, 0.18)
		elif bname.begins_with("leg"):
			w = 0.12 if bname.ends_with("_0") else 0.025
		else: # (its tail)
			w = 0.04
		if w <= 0.0:
			continue
		if not atts.has(b):
			var at := BoneAttachment3D.new()
			at.bone_idx = b
			skel.add_child(at)
			atts[b] = at
		var rest := skel.get_bone_global_rest(b)
		_sites.append([atts[b], rest.affine_inverse() * vs[k], (rest.basis.inverse() * ns[k]).normalized(), w])
	# its ears (a mesh each, on its head): thick with them
	for en: Variant in host.get("_ear_nodes"):
		if not en is Node3D:
			continue
		for mi in (en as Node3D).get_children():
			if mi is MeshInstance3D and (mi as MeshInstance3D).mesh:
				var ea := (mi as MeshInstance3D).mesh.surface_get_arrays(0)
				var ev: PackedVector3Array = ea[Mesh.ARRAY_VERTEX]
				var enn: PackedVector3Array = ea[Mesh.ARRAY_NORMAL]
				for k in range(0, ev.size(), 2):
					_sites.append([mi, ev[k], enn[k].normalized(), 1.4])
	_cum = PackedFloat32Array()
	var c := 0.0
	for s: Array in _sites:
		c += float(s[3])
		_cum.append(c)


func _pick_site() -> int:
	var r := rng.randf() * _cum[_cum.size() - 1]
	var lo := 0
	var hi := _cum.size() - 1
	while lo < hi:
		var m := (lo + hi) / 2
		if _cum[m] < r:
			lo = m + 1
		else:
			hi = m
	return lo


## A heavy load (n ticks), all at once.
func infest(n := 600) -> void:
	_find_sites()
	if _sites.is_empty(): # (its skin not made yet: once it is)
		_pending = n
		return
	for k in n:
		var sp: Script = LONE_STAR if rng.randf() < 0.65 else BLACKLEGGED
		var r := rng.randf()
		var st := TicksScript.FEMALE
		var e := rng.randf() * 0.4
		if r < 0.2:
			st = TicksScript.MALE
			e = 0.0
		elif r < 0.42:
			st = TicksScript.NYMPH
			e = rng.randf() * 0.8
		elif r < 0.56: # (engorged females, swollen grey)
			e = rng.randf_range(0.65, 1.0)
		_add(sp, _pick_site(), st, e)
	# clusters of seed ticks (larvae), round its eyes and ears
	for c in 6:
		var s0 := _pick_site()
		for k in 25:
			_add(LONE_STAR, clampi(s0 + rng.randi_range(-12, 12), 0, _sites.size() - 1), TicksScript.LARVA, rng.randf() * 0.5)
	_dirty = true


func _add(sp: Script, site: int, st: int, e: float, colony: Node = null, i := -1) -> void:
	_ticks.append({"sp": sp, "site": site, "turn": rng.randf() * TAU, "stage": st, "eng": e, "colony": colony, "i": i,
			"seed": rng.randf(), "t": 0.0, "rate": 1.0 / float(TicksScript.FEED_SECS[st])})
	_dirty = true


## A questing tick of colony's (index i) come aboard: true if it's on.
func attach(colony: Node, i: int) -> bool:
	_find_sites()
	if _sites.is_empty():
		return false
	_add(colony.get_script(), _pick_site(), int(colony.get("stage")[i]), float(colony.get("eng")[i]), colony, i)
	return true


func _process(dt: float) -> void:
	if host == null or not is_instance_valid(host):
		queue_free()
		return
	_t -= dt
	if _pending > 0:
		var n := _pending
		_pending = 0
		infest(n)
	var dead := bool(host.get("dead"))
	# those come aboard: feeding, swelling (a female only so far, unmated:
	# she's mated by a male on the host), then off
	var has_male := false
	for tk: Dictionary in _ticks:
		if tk.stage == TicksScript.MALE:
			has_male = true
	for tk: Dictionary in _ticks.duplicate():
		if tk.colony == null:
			continue
		if not is_instance_valid(tk.colony):
			_ticks.erase(tk)
			_dirty = true
			continue
		if dead:
			continue
		tk.t = float(tk.t) + dt
		var cap := 1.0 if tk.stage != TicksScript.FEMALE or has_male else 0.45
		tk.eng = minf(float(tk.eng) + dt * float(tk.rate), cap)
		_dirty = true
		var done: bool = float(tk.eng) >= 0.999 or (tk.stage == TicksScript.MALE and float(tk.t) > 40.0)
		if done:
			var a := rng.randf() * TAU
			var at := host.global_position + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.1, 0.4)
			tk.colony.call("dropped", tk.i, at, float(tk.eng) if tk.stage != TicksScript.MALE else 0.0)
			_ticks.erase(tk)
	if _dirty and _t <= 0.0:
		_t = 0.25
		_dirty = false
		_draw()


## Each part's (and species') ticks into its MultiMesh.
func _draw() -> void:
	var groups := {}
	for tk: Dictionary in _ticks:
		var s: Array = _sites[tk.site]
		var key := "%d:%s" % [(s[0] as Node).get_instance_id(), (tk.sp as Script).resource_path]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(tk)
	for key: String in _mmis:
		if not groups.has(key):
			(_mmis[key] as MultiMeshInstance3D).multimesh.instance_count = 0
	for key: String in groups:
		var list: Array = groups[key]
		var first: Dictionary = list[0]
		var parent: Node3D = (_sites[first.site] as Array)[0]
		if not _mmis.has(key):
			var look: Array = TicksScript.look(first.sp)
			var mmi := MultiMeshInstance3D.new()
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.mesh = look[0]
			mmi.multimesh = mm
			if not _mats.has(first.sp):
				var m := (look[1] as ShaderMaterial).duplicate() as ShaderMaterial
				m.set_shader_parameter("attached", true)
				_mats[first.sp] = m
			mmi.material_override = _mats[first.sp]
			mmi.custom_aabb = AABB(Vector3.ONE * -1e5, Vector3.ONE * 2e5) # (on a moving part: never culled away)
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(mmi)
			_mmis[key] = mmi
		var mm2 := (_mmis[key] as MultiMeshInstance3D).multimesh
		mm2.instance_count = list.size()
		# (the parent's scale undone: the ticks in metres, wherever they are)
		var ps := parent.global_transform.basis.get_scale()
		var unscale := Basis.from_scale(Vector3(1.0 / maxf(ps.x, 1e-6), 1.0 / maxf(ps.y, 1e-6), 1.0 / maxf(ps.z, 1e-6)))
		for k in list.size():
			var tk: Dictionary = list[k]
			var s: Array = _sites[tk.site]
			var p: Vector3 = s[1]
			var n: Vector3 = s[2]
			var side := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized().rotated(n, float(tk.turn))
			var fwd := side.cross(n).normalized()
			var b := Basis(side, n, -fwd) * Basis(Vector3.RIGHT, -0.3) # (its front down, its mouthparts in)
			mm2.set_instance_transform(k, Transform3D(unscale * b, p + unscale * (n * 0.0006)))
			mm2.set_instance_custom_data(k, Color(0.0, 0.0, float(tk.seed), float(tk.stage) + clampf(float(tk.eng), 0.0, 1.0) * 0.999))
