class_name Ticks
extends AntColony
## Hard ticks, the make they share (the species: BlackleggedTicks, the deer
## tick; LoneStarTicks), drawn at twice life size as the insects are: made
## and moved as the ants are (AntColony: one mesh, every tick an instance,
## posed by its shader, tick.gdshader; walking on the GPU, a hundred and
## fifty or more), with eight legs (the larva six). Each at its stage:
## larva, nymph, adult male, adult female; and how engorged.
##
## Their life (each tick on its own, the colony's minds here):
## - questing: out on the litter, still, its front legs up and out,
##   waving (what it smells and feels with: Haller's organ), now and then a
##   few steps to another place; a host going by (a mammal on the four-
##   legged make: Carnivore's: a deer, a fox, a bear...) close enough, it
##   clings on: gone from here onto the host (TickLoad: on its head, its
##   ears, its neck, its legs), feeding there, its mouthparts in, swelling
##   for days (here, a minute or two), then dropping off, engorged, where
##   the host is then
## - engorged: crawling slowly to cover, still a while; then the larva and
##   the nymph moult (molt(i): split, a stage on, small and flat again,
##   their old skin left by them, pale), the female lays (lay(i): her
##   mouthparts down, her eggs pushed out before her into a heap, thousands
##   of them, an egg mass, TickEggs), and dies, shrivelled; the male mates
##   (mate(i, j)) and wanders on
## - the egg mass hatching (a while after, or told): a swarm of larvae out
##   of it, questing together
## Not yet in the game (tools/creatures/ecology_demo.tscn).

const SHADER := preload("res://shaders/render/tick.gdshader")
const TickEggsScript := preload("res://scripts/creatures/tick_eggs.gd")
const LARVA := 0
const NYMPH := 1
const MALE := 2
const FEMALE := 3
const QUESTING := 1
const ENGORGED := 6 # (task: crawling to cover, digesting)
const LAYING := 3
const DEAD := 8
const MATING := 9
const SIZES := [0.22, 0.45, 1.0, 1.0] ## each stage's size (the adult's 1)
const MOLT_SECS := 45.0 ## s an engorged larva or nymph takes to moult (days, in life)
const LAY_SECS := 30.0 ## s an engorged female waits before laying
const FEED_SECS := [25.0, 35.0, 30.0, 60.0] ## s on a host to fill
const GRAB := 0.35 ## m: how close a host's body must pass

## The species' shape (mm, life size): body (its middle; half sizes: half
## width, half height, half length), scutum ([middle, half sizes]),
## conscutum, mouthparts (length), legs ([hip x, z], [femur, tibia, tarsus])
var shape := {}
var stage := PackedByteArray()
var eng := PackedFloat32Array()
var gone := PackedByteArray() # (on a host)
var mated := PackedByteArray()
var digest := PackedFloat32Array() # s since it dropped off, engorged
var mate_with := PackedInt32Array()
var _enc := PackedFloat32Array()
var _host_t := 0.0
var egg_masses: Array[Node3D] = []


func _init() -> void:
	shader = SHADER
	body_h = 0.0
	lays = true
	top_speed = 0.006
	apart = 3.5


## n ticks round c (within r): stages as given (an Array, one each; or
## all adults, half of them male).
func setup_stages(n: int, c: Vector3, r: float, stages := []) -> void:
	setup(n, c, r)
	for i in n:
		stage[i] = stages[i % stages.size()] if not stages.is_empty() else (MALE if i % 2 == 1 else FEMALE)
		quest(i)


func setup(n: int, c: Vector3, r: float) -> void:
	super(n, c, r)
	custom_aabb = custom_aabb.grow(0.1)


func _resize(n: int) -> void:
	var was := stage.size()
	super(n)
	stage.resize(n)
	eng.resize(n)
	gone.resize(n)
	mated.resize(n)
	digest.resize(n)
	mate_with.resize(n)
	_enc.resize(n)
	for i in range(was, n):
		stage[i] = FEMALE
		mate_with[i] = -1


## A new one (hatched from its eggs, dropped from a host): its index.
func add_tick(at: Vector3, st: int, e := 0.0) -> int:
	var i := add(at, rng.randf() * TAU, 0.03)
	stage[i] = st
	eng[i] = e
	if e > 0.5:
		engorged(i)
	else:
		quest(i)
	return i


# --- their ways -------------------------------------------------------------------

## Questing: still, front legs up, waiting for a host.
func quest(i: int) -> void:
	if task[i] in [DEAD]:
		return
	task[i] = QUESTING
	target[i] = pos[i]
	wait[i] = rng.randf_range(15.0, 40.0)


func wander(i: int, c: Vector3, r: float) -> void:
	if task.size() > i and task[i] == DEAD:
		return
	super(i, c, r)
	if eng.size() > i and eng[i] < 0.5:
		wait[i] = 0.0


## Engorged (dropped off a host): to cover, a little way, and still there,
## digesting.
func engorged(i: int) -> void:
	task[i] = ENGORGED
	digest[i] = 0.0
	var a := rng.randf() * TAU
	target[i] = pos[i] + Vector3(cos(a), 0.0, sin(a)) * 0.03
	pace[i] = top_speed * 0.25


## Moulting: a larva to a nymph, a nymph to an adult (male or female, by
## chance), flat and hungry again; its old skin left by it.
func molt(i: int) -> void:
	if stage[i] >= MALE or task[i] == DEAD:
		return
	_skin_left(i)
	stage[i] = NYMPH if stage[i] == LARVA else (MALE if rng.randf() < 0.5 else FEMALE)
	eng[i] = 0.0
	pace[i] = -1.0
	quest(i)


## An engorged female laying: her eggs before her, a heap (and then she
## dies).
func lay(i: int, _at := Vector3.ZERO) -> void:
	if stage[i] != FEMALE or eng[i] < 0.5 or task[i] in [DEAD, LAYING]:
		return
	task[i] = LAYING
	target[i] = pos[i]
	var fwd := Vector3(-sin(yaw[i]), 0.0, -cos(yaw[i]))
	var mass := TickEggsScript.new()
	mass.colony = self
	mass.yellow = stage_color_egg()
	add_child(mass)
	mass.position = pos[i] + fwd * 0.0045
	egg_masses.append(mass)
	lay_at[i] = mass.position
	lay_wait[i] = 0.0


## (The eggs' colour: the species'.)
func stage_color_egg() -> Color:
	return Color(0.55, 0.32, 0.12)


## Male i with female j (both adults, both off a host): he comes to her,
## under her front, a while; she's mated.
func mate(i: int, j: int) -> bool:
	if i < 0 or j < 0 or i == j or stage[i] < MALE or stage[j] < MALE or stage[i] == stage[j]:
		return false
	var him := i if stage[i] == MALE else j
	var her := j if him == i else i
	if task[him] == DEAD or task[her] == DEAD or gone[him] == 1 or gone[her] == 1:
		return false
	task[him] = MATING
	mate_with[him] = her
	mate_t_of[him] = 0.0
	mated[her] = 1
	return true


var mate_t_of := {}


func _together(i: int, j: int) -> bool:
	return mate_with[i] == j or mate_with[j] == i


func die(i: int) -> void:
	task[i] = DEAD
	target[i] = pos[i]
	speed[i] = 0.0


func is_dead(i: int) -> bool:
	return task[i] == DEAD


# --- each frame -------------------------------------------------------------------

func _process(dt: float) -> void:
	if multimesh == null or dt <= 0.0:
		return
	for i in pos.size():
		var st := float(stage[i]) + (4.0 if task[i] == DEAD else 0.0)
		if gone[i] == 1:
			st = 8.0
		_enc[i] = st + clampf(eng[i], 0.0, 1.0) * 0.999
	_host_t -= dt
	if _host_t <= 0.0:
		_host_t = 0.4
		_hosts()
	super(dt)


func _fly_array() -> PackedFloat32Array:
	if _enc.size() != pos.size():
		_enc.resize(pos.size())
	return _enc


func _fly_of(i: int) -> float:
	return _enc[i]


func _think(i: int, dt: float) -> void:
	wait[i] -= dt
	lay_k[i] = move_toward(lay_k[i], 1.0 if task[i] == LAYING else 0.0, dt)
	match task[i]:
		DEAD:
			target[i] = pos[i]
			feed_k[i] = move_toward(feed_k[i], 0.0, dt)
			return
		QUESTING:
			if gone[i] == 1:
				target[i] = pos[i]
				return
			target[i] = pos[i]
			feed_k[i] = move_toward(feed_k[i], 1.0, dt * 0.8) # (feed_k: questing, for the shader)
			if wait[i] <= 0.0: # (a few steps to another place)
				var a := rng.randf() * TAU
				target[i] = pos[i] + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.01, 0.04)
				task[i] = 0
				centre[i] = target[i]
				radius[i] = 0.005
				wait[i] = rng.randf_range(3.0, 6.0)
			return
		ENGORGED:
			feed_k[i] = move_toward(feed_k[i], 0.0, dt)
			digest[i] += dt
			if pos[i].distance_to(target[i]) < 0.003:
				target[i] = pos[i]
			if stage[i] == FEMALE and digest[i] > LAY_SECS:
				lay(i)
			elif stage[i] < MALE and digest[i] > MOLT_SECS:
				molt(i)
			return
		LAYING:
			feed_k[i] = 0.0
			target[i] = pos[i]
			lay_wait[i] += dt
			var mass: Node3D = null
			for m in egg_masses:
				if is_instance_valid(m) and m.position.distance_to(lay_at[i]) < 0.001:
					mass = m
			if mass:
				mass.call("grow_to", clampf(lay_wait[i] / 25.0, 0.0, 1.0))
			eng[i] = maxf(eng[i] - dt / 30.0, 0.3) # (emptied as she lays)
			if lay_wait[i] > 28.0:
				die(i)
			return
		MATING:
			var j := mate_with[i]
			mate_t_of[i] = float(mate_t_of.get(i, 0.0)) + dt
			if j < 0 or task[j] == DEAD:
				mate_with[i] = -1
				quest(i)
				return
			var fwd := Vector3(-sin(yaw[j]), 0.0, -cos(yaw[j]))
			target[i] = pos[j] + fwd * 0.0018 * SIZES[stage[j]]
			if float(mate_t_of[i]) > 25.0:
				mate_with[i] = -1
				quest(i)
			return
	# walking a little (task 0): then questing again where it stops
	feed_k[i] = move_toward(feed_k[i], 0.0, dt * 2.0)
	if eng[i] < 0.5 and (wait[i] <= 0.0 or pos[i].distance_to(target[i]) < 0.002):
		quest(i)
		return
	super(i, dt)


## A tick's speed: the larva's and the nymph's a little slower, engorged
## hardly moving.
func _p_speed(i: int) -> float:
	return top_speed * (0.5 + 0.5 * SIZES[stage[i]]) * (0.25 if eng[i] > 0.5 else 1.0)


## Hosts going by: those questing near one's body cling on.
func _hosts() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var hosts := []
	for n in parent.get_children():
		if n is Node3D and n.get("_skin") != null and n.get("_body") is Node3D and not bool(n.get("dead")):
			hosts.append(n)
	if hosts.is_empty():
		return
	var load_script := load("res://scripts/creatures/tick_load.gd")
	for i in pos.size():
		if task[i] != QUESTING or gone[i] == 1 or eng[i] > 0.3:
			continue
		var w := to_global(pos[i])
		for h: Node3D in hosts:
			var b := (h.get("_body") as Node3D).global_position
			if Vector2(b.x - w.x, b.z - w.z).length() < GRAB * maxf(h.scale.x, 0.5):
				var tl: Node = load_script.call("of", h)
				if tl.call("attach", self, i):
					gone[i] = 1
				break


## Back from a host, engorged (TickLoad's): at `at` (global), on the ground.
func dropped(i: int, at: Vector3, e: float) -> void:
	var p := to_local(at)
	p.y = height.call(p.x, p.z) if height.is_valid() else 0.0
	pos[i] = p
	target[i] = p
	gone[i] = 0
	eng[i] = e
	if e > 0.5:
		engorged(i)
	else:
		quest(i)


## (Its moulted skin: pale, empty, left where it moulted.)
func _skin_left(i: int) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = multimesh.mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.8, 0.7, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.6
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.transform = Transform3D(Basis(Vector3.UP, yaw[i] + 0.4) * Basis.from_scale(Vector3.ONE * SIZES[stage[i]] * 0.95), pos[i] + Vector3(0.002, 0.0, 0.001))


## Larvae out of an egg mass (TickEggs'): n of them about `at` (its own space).
func hatch_larvae(at: Vector3, n: int) -> void:
	for k in n:
		var a := rng.randf() * TAU
		add_tick(at + Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.0, 0.02), LARVA)


# --- the mesh, and its material for others (TickLoad) ---------------------------------

static var _looks := {}


## The species' mesh and material (shared: a host's ticks drawn with them).
static func look(sc: Script) -> Array:
	if _looks.has(sc):
		return _looks[sc]
	var t: Ticks = sc.new()
	var built: Array = t._build_mesh()
	var m := ShaderMaterial.new()
	m.shader = SHADER
	var pivots: Dictionary = built[1]
	for k in pivots:
		m.set_shader_parameter(k, pivots[k])
	for k in t.colors:
		m.set_shader_parameter(k, t.colors[k])
	_looks[sc] = [built[0], m]
	t.free()
	return _looks[sc]


func _build_mesh() -> Array:
	var S: Dictionary = shape
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 18
	sphere.rings = 10
	var SA := sphere.get_mesh_arrays()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	var CA := cyl.get_mesh_arrays()
	var put := func(arrays: Array, xf: Transform3D, part: int, seg := 0, along := Callable()) -> void:
		var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var nb := xf.basis.inverse().transposed()
		for k in idx:
			st.set_normal((nb * ns[k]).normalized())
			st.set_uv(Vector2.ZERO)
			st.set_custom(0, Color(part, seg, along.call(vs[k].y) if along.is_valid() else 0.0, 0.0))
			st.add_vertex((xf * vs[k]) * MM)
	var bc: Vector3 = S.body_c
	var bh: Vector3 = S.body_half
	# the body: a flat oval, its back a little domed
	put.call(SA, Transform3D(Basis.from_scale(bh * 2.0), bc), 0)
	# the shields: the small scutum at its front (the female's, the
	# young's), the conscutum over all its back (the male's)
	var sc: Array = S.scutum
	put.call(SA, Transform3D(Basis.from_scale((sc[1] as Vector3) * 2.0), sc[0]), 1)
	var cs: Array = S.conscutum
	put.call(SA, Transform3D(Basis.from_scale((cs[1] as Vector3) * 2.0), cs[0]), 4)
	# the eyes (the lone star's: at the scutum's edges)
	if S.get("eyes", false):
		for side: float in [-1.0, 1.0]:
			var e := (sc[0] as Vector3) + Vector3((sc[1] as Vector3).x * 0.92 * side, 0.0, -(sc[1] as Vector3).z * 0.1)
			put.call(SA, Transform3D(Basis.from_scale(Vector3.ONE * 0.16), e), 3)
	# the mouthparts: the basis, the palps either side, the hypostome
	var ml: float = S.mouth
	var front := bc + Vector3(0.0, 0.0, -bh.z)
	put.call(SA, Transform3D(Basis.from_scale(Vector3(0.5, 0.28, 0.4)), front + Vector3(0.0, 0.0, -0.1)), 2)
	for side: float in [-1.0, 1.0]:
		put.call(SA, Transform3D(Basis.from_scale(Vector3(0.2, 0.18, ml)), front + Vector3(0.13 * side, -0.02, -ml * 0.5 - 0.1)), 2)
	put.call(SA, Transform3D(Basis.from_scale(Vector3(0.1, 0.07, ml * 0.95)), front + Vector3(0.0, -0.06, -ml * 0.5 - 0.12)), 2)
	# the legs: four pairs, from the front half of its underside, out and
	# down (each a coxa, a femur up to its knee, the tibia down, the tarsus
	# to the ground)
	var hips := []
	var dirs := []
	var L: Array = S.legs
	var lens: Array = S.leg_len
	var yaws := [0.5, 1.15, 1.95, 2.55] # (rad from forward: the front pair forward, the back pair back)
	for i in 8:
		var pair := i / 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var hz: Vector2 = L[pair]
		var hip := Vector3(hz.x * side, bc.y - bh.y * 0.5, hz.y)
		var out := Vector3(sin(yaws[pair]) * side, 0.0, -cos(yaws[pair])).normalized()
		var ln: Array = lens[pair]
		var knee := hip + out * float(ln[0]) * 0.85 + Vector3.UP * float(ln[0]) * 0.32
		var ankle := knee + out * float(ln[1]) * 0.6 + Vector3.DOWN * float(ln[1]) * 0.8
		var foot := ankle + out * float(ln[2]) * 0.85 + Vector3.DOWN * maxf(ankle.y, 0.0) * 0.95
		var lr: float = S.leg_r
		put.call(SA, Transform3D(Basis.from_scale(Vector3.ONE * lr * 2.6), hip), 8 + i, 0)
		for sgm: Array in [[hip, knee, lr * 1.15, 1], [knee, ankle, lr, 2], [ankle, foot, lr * 0.75, 3]]:
			var a: Vector3 = sgm[0]
			var b: Vector3 = sgm[1]
			put.call(CA, _seg(a, b, float(sgm[2])), 8 + i, int(sgm[3]), func(vy: float) -> float: return vy + 0.5)
			put.call(SA, Transform3D(Basis.from_scale(Vector3.ONE * float(sgm[2]) * 2.1), b), 8 + i, int(sgm[3]), func(_vy: float) -> float: return 0.98)
		hips.append(hip * MM)
		dirs.append(out)
	var pivots := {
		"hips": PackedVector3Array(hips), "leg_dirs": PackedVector3Array(dirs),
		"body_c": bc * MM, "body_half": bh * MM,
	}
	return [st.commit(), pivots]

