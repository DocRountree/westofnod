class_name Trigonalid
extends "res://scripts/creatures/wasp.gd" # (by path: found whether or not the editor has seen the class yet)
## A trigonalid wasp (Taeniogonalos gundlachii), North America's commonest:
## the paper wasp's model (Wasp: its parts, its motor, its flight, its
## walking, its mating) in its own colours, drawn at the paper wasp's size
## (it is smaller, about 10 mm). Black, its face, the collar's hind edge, the
## tegulae and the scutellum marked cream; narrow cream bands on the
## gaster's second and third segments only; its legs reddish brown, paler at
## the tarsi; its antennae long, black, a pale ring before their tips; its
## wings near clear, faintly smoky, the veins dark.
##
## It builds no nest, and catches nothing: the adults drink nectar. A female
## lays her eggs by the thousand, tiny, along the margins of leaves (one in
## each little slit she makes there): they hatch only if a caterpillar eats
## them with the leaf, the larva then a parasite of whatever parasite is in
## the caterpillar (a tachinid fly's maggot, say), coming out, grown, of
## what's left of the caterpillar's pupa. Here, her eggs are just left (none
## followed, none hatching, none kept); some milkweeds are seen with rows of
## them on their leaves (one in ten, near: GroundCover's egg_share); and
## one monarch chrysalis in three gives no butterfly but a trigonalid,
## chewing its way out of it, dead (Pupa: parasitized).
##
## Its own (the paper wasp's others, but feed_on_insect, sting and
## lay_eggs, it has as theirs):
## - visit_flowers(heads, sway): from flower to flower among heads (each
##   [its top, the way it faces, its share of the wind's sway]), at each
##   hovering, legs down to it, its head down drinking, a while; then on
## - lay_on_leaf(edge, normal): down onto a leaf, and along its margin
##   (edge: points along it, in order), at each its back to it, the gaster
##   curled down over the edge, pumping, a row of tiny eggs left there; then
##   off again, seeking
## Steering (pilot.gd): act visit_flowers {heads, sway}, lay_on_leaf {edge,
## normal}, and the paper wasp's seek_food, feed_on_flower, land, take_off,
## mate.

const EGG := Color(0.24, 0.15, 0.08) # (its eggs: dark brown, glossy)
const EGG_R := 0.00028 # m (drawn larger than life, about 0.15 mm: to see)

var leaf_eggs: Array[Node3D] = [] ## the rows of eggs it's laid (in its parent): they don't hatch


func _palette() -> Dictionary:
	var black := Color(0.035, 0.03, 0.028)
	var cream := Color(0.92, 0.86, 0.66)
	return {"body": black, "dark": Color(0.02, 0.018, 0.016), "mark": cream, "leg": Color(0.42, 0.16, 0.07), "leg2": Color(0.62, 0.3, 0.12),
		"tip": Color(0.06, 0.05, 0.045), "antenna": Color(0.05, 0.045, 0.04), "mandible": Color(0.55, 0.3, 0.1),
		"membrane": Color(0.62, 0.6, 0.56), "vein": Color(0.12, 0.1, 0.08),
		"bands": [0.0, 0.14, 0.12, 0.0, 0.0, 0.0]}


func _build() -> void:
	super()
	# (the pale ring on each antenna, before its dark tip)
	var ring := _chitin(_pal.mark, 0.0, 0.4)
	for segs: Array in _antennae:
		(segs[3] as MeshInstance3D).material_override = ring


## From flower to flower among heads (each [its top, the way it faces, its
## share of the wind's sway]; sway: the wind's, the clump's), drinking at
## each a while, hovering over it, its legs down on it, its head down; then
## on to another. Till another action.
func visit_flowers(heads: Array, sway := 0.0) -> void:
	var id := _begin()
	release()
	if heads.is_empty():
		return
	if not await _take_off(id):
		return
	var last := -1
	while true:
		var k := rng.randi() % heads.size()
		if k == last and heads.size() > 1:
			k = (k + 1) % heads.size()
		last = k
		var h: Array = heads[k]
		var head: Vector3 = h[0]
		var normal: Vector3 = (h[1] as Vector3).normalized() if h.size() > 1 else Vector3.UP
		var share := float(h[2]) if h.size() > 2 else 0.0
		var face := _away(head)
		_look = face
		_max_speed = 0.8
		_weave = 0.2
		var over := head + normal * 0.03 - face * 3.5 * MM
		_fly_target = over
		if not await _until(id, func() -> bool: return _pos.distance_to(over) < 0.006, 8.0):
			return
		# drinking: its thorax over the head, a little back, its own head down on it
		_weave = 0.0
		_sway_at = head
		_sway_k = sway * share * share
		_p.head_pitch = -0.5
		_p.ant_down = 0.4
		_p.ant_tap = 0.35
		_p.lap = 1.0
		_p.hover_pitch = 0.12
		_jitter = 0.0005
		_max_speed = 0.12
		surface_p = head
		surface_n = normal
		_land_plane = true
		_fly_target = head + normal * (BODY_H + 0.8) * MM - _flat(face, normal) * 3.5 * MM
		if not await _wait(id, rng.randf_range(3.0, 6.0)):
			return
		# up and on
		_p.lap = 0.0
		_p.head_pitch = 0.0
		_p.ant_down = 0.0
		_p.ant_tap = 0.0
		_p.hover_pitch = POSE.hover_pitch
		_land_plane = false
		_sway_k = 0.0
		_jitter = 0.002
		_fly_target = head + normal * 0.06
		if not await _wait(id, 0.6):
			return


## Down onto a leaf (its face toward normal), and along its margin (edge:
## points along it, in order), at each in turn: its back to the edge, the
## gaster over it, curled down to the margin, pumping; a row of tiny eggs
## left along it there. Then off again, seeking food about the leaf.
func lay_on_leaf(edge: Array, normal := Vector3.UP) -> void:
	var id := _begin()
	release()
	normal = normal.normalized()
	if edge.is_empty():
		return
	var mid := Vector3.ZERO
	for e: Vector3 in edge:
		mid += e
	mid /= edge.size()
	var first: Vector3 = edge[0]
	var onto := first + (mid - first).normalized() * 0.012
	if not flying:
		if not await _take_off(id):
			return
	if not await _touch_down(id, onto, normal, (first - mid).normalized()):
		return
	_p.ant_tap = 0.4
	for k in edge.size():
		var c: Vector3 = edge[k]
		# the thorax in from the edge a body's length, facing away from it
		var inward := _flat(mid - c, normal)
		_walk_target = c + inward * 8.0 * MM
		if not await _until(id, func() -> bool: return _walk_target == Vector3.INF, 4.0):
			return
		if not await _turn(id, inward):
			return
		_p.crouch = 0.7
		_p.curl = 0.75
		_p.pump = 0.8
		_p.ant_down = 0.3
		if not await _wait(id, 1.2):
			return
		# the row along the margin there
		var along := _flat((edge[mini(k + 1, edge.size() - 1)] as Vector3) - (edge[maxi(k - 1, 0)] as Vector3), normal)
		_lay_row(c + inward * 0.0012, along, normal)
		_p.curl = 0.15
		_p.pump = 0.2
		_p.crouch = 0.25
		if not await _wait(id, 0.4):
			return
	_p.ant_tap = 0.0
	if not await _wait(id, 0.8):
		return
	seek_food(mid, 0.4)


## A row of its eggs at c along the margin (along), on the leaf's face:
## one MultiMesh (there are so many), in the parent.
func _lay_row(c: Vector3, along: Vector3, normal: Vector3) -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var n := rng.randi_range(9, 14)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var egg := SphereMesh.new()
	egg.radius = 0.5
	egg.height = 1.0
	egg.radial_segments = 6
	egg.rings = 3
	mm.mesh = egg
	mm.instance_count = n
	var side := normal.cross(along).normalized()
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.albedo_color = EGG
	m.roughness = 0.25
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_transform = Transform3D(Basis.IDENTITY, c)
	for i in n:
		var u := (float(i) - (n - 1) * 0.5) * EGG_R * 2.6
		var p := along * u + side * rng.randf_range(-0.6, 0.6) * EGG_R + normal * EGG_R * 0.5
		mm.set_instance_transform(i, Transform3D(Basis(side, normal, along) * Basis.from_scale(Vector3(EGG_R * 1.6, EGG_R * 1.4, EGG_R * 3.0)), p))
	leaf_eggs.append(mi)


# --- steering (pilot.gd) -----------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["seek_food", "visit_flowers", "feed_on_flower", "lay_on_leaf", "land", "take_off", "mate"])


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"visit_flowers":
			if (args.get("heads", []) as Array).is_empty():
				return false
		"lay_on_leaf":
			if (args.get("edge", []) as Array).is_empty() or male:
				return false
		"feed_on_insect", "sting", "lay_eggs":
			return false # (not its ways)
	return super(name, args)


func _p_run(name: String, args: Dictionary) -> void:
	if name not in ["visit_flowers", "lay_on_leaf"]:
		await super(name, args)
		return
	_p_done = false
	var id := _act + 1
	if name == "visit_flowers":
		await visit_flowers(args.heads, float(args.get("sway", 0.0)))
	else:
		await lay_on_leaf(args.edge, args.get("normal", Vector3.UP))
	if _act == id:
		_p_done = true


func _p_act_secs(name: String) -> float:
	if name == "visit_flowers":
		return 20.0
	return super(name)
