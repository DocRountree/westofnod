class_name Bumblebee
extends "res://scripts/creatures/wasp.gd" # (by path: found whether or not the editor has seen the class yet)
## A common eastern bumble bee (Bombus impatiens), a worker (male: a
## drone, drinking only, no loads): the paper
## wasp's model (Wasp: its legs, wings, head, its motor, its flight, its
## walking, its mating), made over as a bee: stout and round, no wasp waist
## (its gaster's first segment broad against the thorax), the gaster short
## and blunt; all of it in dense short pile (bee_fur.gdshader: shells of
## hairs, darker at their roots), the thorax yellow above, black beneath,
## with a small bare black spot in its middle between the wings, the
## gaster's first segment yellow, the rest black; its face black; its wings
## smoky; its legs black, the hind tibiae broad and flat, the pollen basket
## (corbicula) on each, loaded as it works (pale orange balls of pollen,
## growing); its tongue (the proboscis) out, long, when it drinks.
##
## Its own (the wasp's others, but feed_on_insect and lay_eggs, it has as
## theirs):
## - forage(heads, nest): from flower to flower among heads (each [its top,
##   the way it faces, its share of the wind's sway]): landing on each,
##   its tongue in, crawling about it, now and then buzzing it (its flight
##   muscles shaking the pollen loose, its wings still), the loads on its
##   hind legs growing; full, home to its nest (nest: the hole in the
##   ground), down into it, a while, out again unloaded, and back to the
##   flowers. Till another action
## - home(nest): back to its nest, in, a while, and out again
## - mate(her): (a drone's, with a queen: Bumblebee.new(true), bigger, a
##   third again a worker's size; never a worker, who doesn't mate) after
##   her, onto her back, gripping her, the two of them down together onto
##   the ground or a plant, joined a long while, his wings buzzing now and
##   then; then off, both. A drone's face yellow, a tuft of it (Bombus
##   impatiens's), its pile longer
## Steering (pilot.gd): act forage {heads, nest}, home {nest}, and the
## wasp's seek_food, feed_on_flower, land, take_off, mate, sting.

const FUR_SHELLS := 6
const POLLEN := Color(0.95, 0.68, 0.22)

var pollen := 0.0 ## (its loads: 0 none .. 1 full)
var queen := false ## a queen (a new one, to mate and found a nest), not a worker: bigger
var nest_at := Vector3.INF ## its nest's mouth (on the ground), if it has one
var _shake := 0.0 # (buzzing a flower: its body shaking, its wings still)
var _tongue: MeshInstance3D
var _loads: Array[MeshInstance3D] = []
var _fur_mats := {}


func _init(queen_ := false) -> void:
	queen = queen_
	big = 1.33 if queen_ else 1.0
	mate_secs = 40.0 # (bumble bees: a long while, joined)
	super()


## (A drone's face: a tuft of yellow pile on it.)
func _ready() -> void:
	super()
	if male:
		for c in _head.get_children():
			if c is MeshInstance3D: # (its face's pile recoloured, shell by shell)
				var face := c as MeshInstance3D
				var yel := Color(0.92, 0.78, 0.3)
				face.material_override = _fur(yel, 0, 0.14)
				var k := 0
				for sh in face.get_children():
					k += 1
					(sh as MeshInstance3D).material_override = _fur(yel, k, 0.14)
				break


## Only a drone and a queen (a worker doesn't mate).
func mate(partner: Node3D, secs := -1.0) -> bool:
	if partner == null or not partner.has_method("_mate_begin"):
		return false
	var her: Node3D = self if not male else partner
	if not bool(her.get("queen")):
		return false
	return super(partner, secs)


func _palette() -> Dictionary:
	var black := Color(0.03, 0.028, 0.027)
	return {"body": black, "dark": Color(0.02, 0.018, 0.017), "mark": black, "leg": black, "leg2": Color(0.07, 0.055, 0.045),
		"tip": black, "antenna": black, "mandible": Color(0.12, 0.08, 0.05),
		"membrane": Color(0.42, 0.36, 0.3), "vein": Color(0.12, 0.09, 0.07),
		"bands": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]}


## (A pile's material: its colour, shell k of FUR_SHELLS (0 the skin).)
func _fur(c: Color, k: int, len_ := 0.14) -> ShaderMaterial:
	var key := "%s/%d/%.2f" % [c, k, len_]
	if _fur_mats.has(key):
		return _fur_mats[key]
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/render/bee_fur.gdshader")
	m.set_shader_parameter("fur_color", c)
	m.set_shader_parameter("shell", float(k) / FUR_SHELLS)
	m.set_shader_parameter("fur_len", len_)
	_mats.append(m)
	_fur_mats[key] = m
	return m


## A part in pile: its own mesh in the colour's skin, and the shells over it.
func _furred(mi: MeshInstance3D, c: Color, len_ := 0.14) -> void:
	mi.material_override = _fur(c, 0, len_)
	for k in range(1, FUR_SHELLS + 1):
		var s := MeshInstance3D.new()
		s.mesh = mi.mesh
		s.material_override = _fur(c, k, len_)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(s)


func _build() -> void:
	super()
	var yellow := Color(0.92, 0.74, 0.22)
	var black := Color(0.05, 0.045, 0.04)
	# the wasp's hard angular thorax and its marks away (its neck and its
	# tegulae kept); the bee's round, in its pile
	var n := 0
	for c in _body.get_children():
		if c is MeshInstance3D:
			n += 1
			if n <= 6: # (the thorax, the collar, the scutellum, the metanotum, the propodeum's marks)
				(c as MeshInstance3D).visible = false
			if n >= 9:
				break
	_furred(_ball(_body, Vector3(0.0, 0.1, -0.05), Vector3(4.5, 4.0, 4.9), null), black) # (beneath: black)
	_furred(_ball(_body, Vector3(0.0, 0.55, -0.1), Vector3(4.65, 3.5, 5.0), null), yellow) # (above: yellow)
	_ball(_body, Vector3(0.0, 2.38, -0.15), Vector3(1.3, 0.3, 1.25), _chitin(Color(0.03, 0.028, 0.027), 0.0, 0.8)) # (the bare spot)
	# the head: black, furred over its face and crown
	for c in _head.get_children():
		if c is MeshInstance3D:
			_furred(c as MeshInstance3D, black, 0.1)
			break
	# the gaster: short, broad, round; no waist; its first segment yellow
	const WIDE := [2.4, 1.5, 1.42, 1.35, 1.25, 1.1]
	const SHORT := 0.72
	for i in _gaster.size():
		var piv := _gaster[i]
		if i > 0:
			piv.position.z *= SHORT
		var seg := _gaster_mesh[i]
		seg.scale = Vector3(seg.scale.x * WIDE[i], seg.scale.y * WIDE[i], seg.scale.z * SHORT)
		seg.position.z *= SHORT
		_furred(seg, yellow if i <= 1 else black, 0.12)
	_gaster[0].position += Vector3(0.0, 0.25, -0.35) # (tucked up against the thorax)
	_sting.position.z *= SHORT
	# its tongue: out, drinking
	_tongue = _stick(_head, _chitin(Color(0.12, 0.08, 0.05), 0.0, 0.5))
	_tongue.visible = false
	# the pollen loads, on its hind tibiae
	var pm := StandardMaterial3D.new()
	pm.albedo_color = POLLEN
	pm.roughness = 0.9
	for s in 2:
		var b := _ball(_body, Vector3.ZERO, Vector3.ONE, pm)
		b.visible = false
		_loads.append(b)


# --- what it does ---------------------------------------------------------------

## From flower to flower among heads (each [its top, the way it faces, its
## share of the wind's sway]), landing and working each; full, home to its
## nest (if it has one: nest, or its nest_at) and back. Till another action.
func forage(heads: Array, nest := Vector3.INF) -> void:
	var id := _begin()
	release()
	if nest != Vector3.INF:
		nest_at = nest
	if heads.is_empty():
		return
	if not await _take_off(id):
		return
	var last := -1
	while true:
		if pollen >= 0.95 and nest_at != Vector3.INF:
			if not await _go_home(id):
				return
			continue
		var k := rng.randi() % heads.size()
		if k == last and heads.size() > 1:
			k = (k + 1) % heads.size()
		last = k
		var h: Array = heads[k]
		var head: Vector3 = h[0]
		var normal: Vector3 = (h[1] as Vector3).normalized() if h.size() > 1 else Vector3.UP
		if normal.y < 0.3: # (a head turned well over: on its top side)
			normal = (normal + Vector3.UP).normalized()
		_weave = 0.12
		# down onto it (a bee lands on its flowers, heavily), swaying with
		# it there (its share of the wind's sway: as the trigonalid's, the
		# clump's sway * its height's share, given as one, squared)
		var share := float(h[2]) if h.size() > 2 else 0.0
		_sway_at = head
		_sway_k = share * share
		if not await _touch_down(id, head, normal, _flat(_away(head), normal), 0.09):
			return
		# working it: its tongue in, crawling about over it, now and then
		# buzzing it (its wings still, its body shaking), its loads growing
		_p.head_pitch = -0.45
		_p.lap = 1.0
		_p.ant_down = 0.35
		_p.ant_tap = 0.3
		var secs := rng.randf_range(2.5, 5.0)
		var t := 0.0
		while t < secs:
			if rng.randf() < 0.4:
				_walk_target = head + _in_plane(normal, 0.005)
			_shake = 1.0 if rng.randf() < 0.3 else 0.0
			if not await _wait(id, 0.7):
				return
			t += 0.7
			if not male: # (a drone drinks only: no pollen baskets)
				pollen = minf(pollen + 0.05, 1.0)
		_shake = 0.0
		_p.lap = 0.0
		_p.head_pitch = 0.0
		_p.ant_down = 0.0
		_p.ant_tap = 0.0
		_sway_k = 0.0 # (off it: it eases out)
		if not await _take_off(id):
			return
		_fly_target = head + normal * 0.05
		_max_speed = 0.5
		if not await _wait(id, 0.4):
			return


## Back to its nest (nest, or its nest_at), into it, a while (its loads
## left there), and out again; then about its flowers' way, seeking.
func home(nest := Vector3.INF) -> void:
	var id := _begin()
	release()
	if nest != Vector3.INF:
		nest_at = nest
	if nest_at == Vector3.INF:
		return
	if not await _take_off(id):
		return
	if not await _go_home(id):
		return
	seek_food(nest_at, 0.6)


func _go_home(id: int) -> bool:
	var over := nest_at + Vector3.UP * 0.07
	_look = Vector3.ZERO
	_max_speed = 0.8
	_weave = 0.15
	_fly_target = over
	if not await _until(id, func() -> bool: return _pos.distance_to(over) < 0.01, 10.0):
		return false
	# (a turn or two over it, looking; then down into it)
	_weave = 0.0
	_jitter = 0.001
	_max_speed = 0.2
	for k in 2:
		_look = _heading.rotated(Vector3.UP, rng.randf_range(1.0, 2.5))
		if not await _wait(id, 0.5):
			return false
	_p.hover_pitch = 0.75
	_max_speed = 0.05
	var down := nest_at - Vector3.UP * 0.03
	_fly_target = down
	if not await _until(id, func() -> bool: return _pos.y < nest_at.y - 0.004, 5.0):
		return false
	visible = false
	if not await _wait(id, rng.randf_range(5.0, 8.0)):
		visible = true
		return false
	pollen = 0.0
	visible = true
	_max_speed = 0.12
	_fly_target = nest_at + Vector3.UP * 0.06
	if not await _until(id, func() -> bool: return _pos.distance_to(_fly_target) < 0.01, 4.0):
		return false
	_p.hover_pitch = POSE.hover_pitch
	_jitter = 0.002
	return true


func _begin() -> int:
	_shake = 0.0
	if not visible: # (out of its nest)
		visible = true
		if nest_at != Vector3.INF:
			_pos = nest_at + Vector3.UP * 0.04
	return super()


## Its nest's mouth: a hole in the ground (an old mouse burrow's), a little
## crumbled soil round it, moss and dead grass over it. Its origin the
## hole's middle, on the ground.
static func nest() -> Node3D:
	var root := Node3D.new()
	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color(0.3, 0.22, 0.15)
	soil.roughness = 0.95
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.03, 0.02, 0.015)
	var moss := StandardMaterial3D.new()
	moss.albedo_color = Color(0.3, 0.38, 0.14)
	moss.roughness = 0.95
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 12
	s.rings = 6
	var mound := MeshInstance3D.new()
	mound.mesh = s
	mound.material_override = soil
	mound.scale = Vector3(0.09, 0.016, 0.08)
	root.add_child(mound)
	var hole := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.011
	c.bottom_radius = 0.011
	c.height = 0.004
	hole.mesh = c
	hole.material_override = dark
	hole.position = Vector3(0.0, 0.007, 0.0)
	root.add_child(hole)
	for k in 6: # (moss and dead grass round its back)
		var m := MeshInstance3D.new()
		m.mesh = s
		m.material_override = moss if k % 2 == 0 else soil
		var a := PI * 0.2 + float(k) * 0.42
		m.position = Vector3(cos(a), 0.0, sin(a)) * 0.04
		m.scale = Vector3(0.03, 0.022, 0.025)
		root.add_child(m)
	return root


# --- its pose -------------------------------------------------------------------

func _pose(dt: float) -> void:
	super(dt)
	# its body shaking, buzzing a flower
	var j := Vector3(rng.randf() - 0.5, rng.randf() - 0.5, rng.randf() - 0.5) * 0.0006 * _shake
	_body.position = j
	# its tongue out, drinking
	_tongue.visible = _a.lap > 0.25
	if _tongue.visible:
		var l: float = 3.2 * _a.lap
		_seg(_tongue, Vector3(0.0, -1.5, -1.9), Vector3(0.0, -1.5 - l * 0.6, -1.9 - l * 0.8), 0.12)
	# its loads, on its hind tibiae
	for s in 2:
		var b := _loads[s]
		b.visible = pollen > 0.04
		if b.visible:
			var tib := (_legs[4 + s][2] as MeshInstance3D).transform # (the tibia, along its y)
			var side := 1.0 if s == 1 else -1.0
			var r := lerpf(0.35, 1.0, pollen)
			b.transform = Transform3D(Basis.from_scale(Vector3(1.1, 1.0, 1.5) * r), tib.origin + tib.basis.y * 0.15 + Vector3(0.25 * side, 0.0, 0.0))


func _pose_legs() -> void:
	super()
	# (its legs stouter than a wasp's, hairy)
	for parts: Array in _legs:
		for q in 4:
			var mi := parts[q] as MeshInstance3D
			mi.transform.basis.x *= 1.5
			mi.transform.basis.z *= 1.5
	# (the hind tibiae broad and flat: the pollen baskets)
	for s in 2:
		var tib := _legs[4 + s][2] as MeshInstance3D
		tib.transform.basis.x *= 1.6
		tib.transform.basis.z *= 1.1


# --- steering (pilot.gd) --------------------------------------------------------

func _p_behaviours() -> PackedStringArray:
	var b := super()
	b.append_array(PackedStringArray(["forage", "home"]))
	return b


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"forage":
			if (args.get("heads", []) as Array).is_empty():
				return false
		"home":
			if args.get("nest", nest_at) == Vector3.INF:
				return false
		_:
			return super(name, args)
	_piloting = false
	_p_run(name, args)
	return true


func _p_run(name: String, args: Dictionary) -> void:
	if name not in ["forage", "home"]:
		await super(name, args)
		return
	_p_done = false
	var id := _act + 1
	if name == "forage":
		await forage(args.heads, args.get("nest", Vector3.INF))
	else:
		await home(args.get("nest", Vector3.INF))
	if _act == id:
		_p_done = true
