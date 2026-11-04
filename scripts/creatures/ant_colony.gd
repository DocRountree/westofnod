class_name AntColony
extends MultiMeshInstance3D
## Ants: black carpenter ants (Camponotus pennsylvanicus), workers, drawn at
## twice life size as the wasp is (about 24 mm long). Every ant one instance
## of one mesh, posed by its shader (ant.gdshader: walking, feeding), so a
## colony of hundreds is a draw call; here each is only moved along, as a
## whole, once a frame: where it is, which way it faces, how fast it walks
## and how far into feeding (the shader's INSTANCE_CUSTOM).
##
## Each ant's doing one of two things (no state machine yet: the caller
## says, e.g. tools/creatures/ant_demo):
## - wander(i, centre, radius): walking about, in a wandering line,
##   stopping now and then
## - feed(i, food): to the food (its own place round it), and feeding: head
##   down, mandibles working, antennae drumming, front legs on it; now and
##   then round to another place at it
## They keep a little apart from one another. They walk on the ground the
## height callable gives (x, z -> y), flat at y 0 without one.
##
## A black carpenter ant: a big heart-shaped head with elbowed antennae and
## toothed mandibles, a smoothly arched thorax, a single upright scale for
## its waist, an oval gaster, its segments edged faintly gold; dull black,
## the legs a dark reddish black.

const MM := 0.002 ## m drawn per model mm (twice life size)
const BODY_H := 1.5 ## mm an ant's thorax's middle stands over the ground

# (another kind of crawler made the same way sets these: Beetles)
var body_h := BODY_H ## mm its thorax's middle stands over the ground
var top_speed := 0.06 ## m/s, walking (an ant's 3 cm/s, twice life size)
var reach := 4.6 ## mm from its thorax's middle to its mouth
var apart := 9.0 ## mm they keep between them
var shader: Shader = preload("res://shaders/render/ant.gdshader")
var colors := {} ## the shader's colours, its own (else an ant's)

var height: Callable ## (x, z) -> the ground's y; none: 0
var pos := PackedVector3Array()
var yaw := PackedFloat32Array()
var speed := PackedFloat32Array() # m/s now
var task := PackedInt32Array() # 0 wandering, 1 feeding
var target := PackedVector3Array()
var centre := PackedVector3Array() # wandering: round here
var radius := PackedFloat32Array()
var food := PackedVector3Array() # feeding: at this
var slot := PackedFloat32Array() # feeding: its place round the food (rad)
var feed_k := PackedFloat32Array() # 0..1 into feeding
var wait := PackedFloat32Array() # s till it next changes its mind
var seed := PackedFloat32Array()
var rng := RandomNumberGenerator.new()
var _t := 0.0

# the rest pose's joints (m), for the shader
static var _built := {} # script path -> [mesh, pivots]


## n ants round c (within r), wandering.
func setup(n: int, c: Vector3, r: float) -> void:
	rng.randomize()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	var path: String = get_script().resource_path
	if not _built.has(path):
		_built[path] = _build_mesh()
	multimesh.mesh = _built[path][0]
	multimesh.instance_count = n
	var m := ShaderMaterial.new()
	m.shader = shader
	var pivots: Dictionary = _built[path][1]
	for k in pivots:
		m.set_shader_parameter(k, pivots[k])
	for k in colors:
		m.set_shader_parameter(k, colors[k])
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	pos.resize(n)
	target.resize(n)
	centre.resize(n)
	food.resize(n)
	yaw.resize(n)
	speed.resize(n)
	radius.resize(n)
	slot.resize(n)
	feed_k.resize(n)
	wait.resize(n)
	seed.resize(n)
	task.resize(n)
	for i in n:
		var a := rng.randf() * TAU
		pos[i] = c + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * r
		yaw[i] = rng.randf() * TAU
		seed[i] = rng.randf()
		wander(i, c, r)
		target[i] = pos[i]
	custom_aabb = AABB(c - Vector3(r, 1.0, r) - Vector3.ONE, Vector3(r, 1.0, r) * 2.0 + Vector3.ONE * 2.0)


## Ant i walking about round c, within r (m).
func wander(i: int, c: Vector3, r: float) -> void:
	task[i] = 0
	centre[i] = c
	radius[i] = r
	wait[i] = 0.0


## Ant i to the food at f, and feeding on it.
func feed(i: int, f: Vector3) -> void:
	task[i] = 1
	food[i] = f
	var d := pos[i] - f
	slot[i] = atan2(d.z, d.x)
	wait[i] = rng.randf_range(3.0, 7.0)


func _process(dt: float) -> void:
	if multimesh == null or dt <= 0.0:
		return
	_t += dt
	var n := pos.size()
	# who's near whom (a grid of cells APART across): to keep apart
	var cell := apart * MM
	var grid := {}
	for i in n:
		var k := Vector2i(floori(pos[i].x / cell), floori(pos[i].z / cell))
		if not grid.has(k):
			grid[k] = []
		grid[k].append(i)
	for i in n:
		if _air(i, dt): # (a beetle flying: moved there, not walking)
			continue
		_think(i, dt)
		var fwd := Vector3(-sin(yaw[i]), 0.0, -cos(yaw[i]))
		var to := target[i] - pos[i]
		to.y = 0.0
		var d := to.length()
		var want := speed[i]
		if d > 0.0012:
			# a wandering line: weaving a little either side of the way
			var wiggle := (sin(_t * 2.3 + seed[i] * 40.0) * 0.35 + sin(_t * 5.1 + seed[i] * 13.0) * 0.15) * clampf(d / 0.03, 0.0, 1.0)
			var a := atan2(-to.x, -to.z) + wiggle
			var turn := wrapf(a - yaw[i], -PI, PI)
			yaw[i] += clampf(turn, -6.0 * dt, 6.0 * dt)
			want = minf(top_speed * (0.75 + 0.5 * seed[i]), d * 5.0) * clampf(1.0 - absf(turn) / 1.3, 0.0, 1.0)
		else:
			want = 0.0
			if task[i] == 1: # (at the food: facing it)
				var f := food[i] - pos[i]
				var turn := wrapf(atan2(-f.x, -f.z) - yaw[i], -PI, PI)
				yaw[i] += clampf(turn, -4.0 * dt, 4.0 * dt)
		speed[i] = move_toward(speed[i], want, dt * 0.6)
		var p := pos[i] + fwd * speed[i] * dt
		# keeping apart: a push from any too near (at food hardly: they
		# crowd round it)
		var crowd := 0.08 if task[i] == 1 and Vector2(p.x - food[i].x, p.z - food[i].z).length() < 0.04 else 1.0
		var k := Vector2i(floori(p.x / cell), floori(p.z / cell))
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for j in grid.get(k + Vector2i(dx, dz), []):
					if j == i:
						continue
					var off := p - pos[j]
					off.y = 0.0
					var l := off.length()
					if l < cell and l > 1e-6:
						p += off / l * minf((cell - l) * minf(dt * 6.0, 0.5), top_speed * 0.4 * dt) * crowd # (never faster than they walk: a band going the same way shoved itself back)
		p.y = height.call(p.x, p.z) if height.is_valid() else 0.0
		pos[i] = p
		var at := Transform3D(Basis(Vector3.UP, yaw[i]), p + Vector3.UP * body_h * MM)
		multimesh.set_instance_transform(i, at)
		multimesh.set_instance_custom_data(i, Color(clampf(speed[i] / top_speed, 0.0, 1.0), feed_k[i], seed[i], _fly_of(i)))


## A flyer's (Beetles): whether i's in the air, moved there (true: not
## walking); an ant never is.
func _air(_i: int, _dt: float) -> bool:
	return false


## A flyer's: how far into flying i's pose is (the shader's), 0 an ant's.
func _fly_of(_i: int) -> float:
	return 0.0


## Where ant i's making for, as it's doing.
func _think(i: int, dt: float) -> void:
	wait[i] -= dt
	if task[i] == 0:
		feed_k[i] = move_toward(feed_k[i], 0.0, dt * 2.0)
		if wait[i] <= 0.0 or (pos[i].distance_to(target[i]) < 0.002 and wait[i] > 1.0):
			if rng.randf() < 0.3:
				# a stop, to feel about
				target[i] = pos[i]
				wait[i] = rng.randf_range(0.4, 1.5)
			else:
				var a := rng.randf() * TAU
				target[i] = centre[i] + Vector3(cos(a), 0.0, sin(a)) * sqrt(rng.randf()) * radius[i]
				wait[i] = rng.randf_range(2.0, 6.0)
		return
	# feeding: at its place round the food, its mouth on it
	var at := food[i] + Vector3(cos(slot[i]), 0.0, sin(slot[i])) * reach * MM
	target[i] = at
	var there := Vector2(pos[i].x - at.x, pos[i].z - at.z).length() < 0.003
	feed_k[i] = move_toward(feed_k[i], 1.0 if there and speed[i] < 0.015 else 0.0, dt * 2.0)
	if wait[i] <= 0.0:
		# round to another place at it
		slot[i] += rng.randf_range(0.6, 1.8) * (1.0 if rng.randf() < 0.5 else -1.0)
		wait[i] = rng.randf_range(3.0, 7.0)


## A crumb of food (a sugar crumb, say), for them to feed on: about 3 mm
## (twice life size), its origin at its foot.
static func crumb() -> Node3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 8
	s.rings = 5
	mi.mesh = s
	mi.scale = Vector3(0.007, 0.0045, 0.006)
	mi.position.y = 0.0018
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.93, 0.9, 0.82)
	m.roughness = 0.5
	mi.material_override = m
	var root := Node3D.new()
	root.add_child(mi)
	return root


# --- the mesh ------------------------------------------------------------------

# the legs, the right side's (the left's mirrored): hip, femur, tibia,
# tarsus (mm), home (the foot at rest: x, z), its feet each in its own part
# of the round (front forward, middle out, hind back)
const LEGS := [
	{"hip": Vector3(0.35, -0.75, -0.95), "f": 2.3, "t": 2.0, "s": 2.0, "home": Vector2(3.6, -4.4)},
	{"hip": Vector3(0.45, -0.75, 0.15), "f": 2.6, "t": 2.4, "s": 2.3, "home": Vector2(5.2, 0.4)},
	{"hip": Vector3(0.5, -0.7, 0.95), "f": 3.2, "t": 3.0, "s": 2.9, "home": Vector2(4.8, 5.6)},
]
const HEAD_AT := Vector3(0.0, 0.25, -1.75)
const GASTER_AT := Vector3(0.0, -0.05, 2.0)
const GASTER := [[1.0, 1.0, 0.95, 0.12], [1.1, 1.3, 1.15, 0.02], [1.0, 1.25, 1.1, 0.04], [0.8, 0.95, 0.85, 0.08]] # length, half width, half height (mm), droop (rad)


## The ant at rest, standing (in metres): every part tagged for the shader
## (CUSTOM0: its part, its segment, along it, banded); its joints noted (the
## shader's uniforms): [mesh, pivots]. (Another crawler: its own.)
func _build_mesh() -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 7
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	var S := sphere.get_mesh_arrays()
	var C := cyl.get_mesh_arrays()
	var ball := func(at: Vector3, size: Vector3, part: int, banded := false, b := Basis()) -> void:
		_add(st, S, Transform3D(b * Basis.from_scale(size), at), part, 0, banded)
	var stick := func(a: Vector3, b: Vector3, r: float, part: int, seg := 0) -> void:
		_add(st, C, _seg(a, b, r), part, seg, false)
	# the thorax: arched, the pronotum high, the propodeum falling to the waist
	ball.call(Vector3(0.0, 0.15, -0.95), Vector3(1.55, 1.5, 1.6), 0)
	ball.call(Vector3(0.0, 0.25, 0.15), Vector3(1.25, 1.3, 1.5), 0)
	ball.call(Vector3(0.0, -0.05, 1.05), Vector3(1.15, 1.15, 1.05), 0)
	ball.call(Vector3(0.0, 0.15, -1.6), Vector3(0.75, 0.75, 0.6), 0) # (the neck)
	ball.call(Vector3(0.0, 0.05, 1.65), Vector3(0.95, 1.15, 0.4), 0) # (the waist: one upright scale)
	# the head: big, heart-shaped (broad behind), the eyes small, on its sides
	var h := HEAD_AT
	ball.call(h + Vector3(0.0, 0.0, -0.9), Vector3(2.5, 2.0, 2.0), 1)
	ball.call(h + Vector3(0.0, -0.15, -1.75), Vector3(1.6, 1.4, 1.2), 1)
	ball.call(h + Vector3(0.0, -0.45, -2.3), Vector3(1.0, 0.45, 0.4), 1)
	var sockets := []
	var elbows := []
	var mands := []
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		ball.call(h + Vector3(1.05 * side, 0.3, -1.3), Vector3(0.45, 0.65, 0.6), 15)
		# a mandible: a blade from its pivot, closed across the front
		var mp := h + Vector3(0.45 * side, -0.55, -2.35)
		mands.append(mp)
		ball.call(mp + Basis(Vector3.UP, 0.45 * side) * Vector3(0.0, 0.0, -0.45), Vector3(0.4, 0.3, 1.0), 2 + s, false, Basis(Vector3.UP, 0.45 * side))
		# an antenna: the scape up, out and forward; the funiculus elbowed down and forward
		var base := h + Vector3(0.45 * side, 0.4, -2.3)
		var elbow := base + _dir(0.5, 0.75, side) * 2.2
		sockets.append(base)
		elbows.append(elbow)
		stick.call(base, elbow, 0.09, 4 + s)
		var p: Vector3 = elbow
		var fp := 0.05 - 0.3
		for k in 4:
			var q := p + _dir(0.15, fp, side) * 0.65
			stick.call(p, q, 0.08 if k < 3 else 0.1, 6 + s)
			p = q
			fp -= 0.12
	# the gaster: its segments, drooping a little each, edged gold
	var gb := Basis()
	var gat := GASTER_AT
	for i in GASTER.size():
		var g: Array = GASTER[i]
		gb = gb * Basis(Vector3.RIGHT, g[3])
		var mid := gat + gb * Vector3(0.0, 0.0, g[0] * 0.5)
		_add(st, S, Transform3D(gb * Basis.from_scale(Vector3(g[1] * 2.0, g[2] * 2.0, g[0] * 1.5)), mid), 14, 0, i < 3)
		gat += gb * Vector3(0.0, 0.0, g[0])
	# the legs, standing: each foot at its home on the ground, the knee up
	# and out in its own leg's plane (the two-bone reach)
	var hips := []
	var knees := []
	var dirs := []
	var up := Vector3.UP
	for i in 6:
		var pair := i / 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var L: Dictionary = LEGS[pair]
		var hip0 := Vector3(L.hip.x * side, L.hip.y, L.hip.z)
		var hip := hip0 + Vector3(0.35 * side, -0.25, 0.0)
		var home: Vector2 = L.home
		var foot := Vector3(home.x * side, -BODY_H + 0.08, home.y)
		var out := Vector3(foot.x - hip.x, 0.0, foot.z - hip.z).normalized()
		var ankle := foot + (-out * 0.9 + up * 0.42) * float(L.s)
		var aout := Vector3(ankle.x - hip.x, 0.0, ankle.z - hip.z).normalized()
		var knee := _knee(hip, ankle, L.f, L.t, up + aout * 0.6)
		stick.call(hip0, hip, 0.24, 8 + i, 0)
		stick.call(hip, knee, 0.17, 8 + i, 1)
		stick.call(knee, ankle, 0.12, 8 + i, 2)
		stick.call(ankle, foot, 0.085, 8 + i, 3)
		_add(st, S, Transform3D(Basis.from_scale(Vector3(0.16, 0.12, 0.16)), foot), 8 + i, 3, false)
		hips.append(hip0 * MM)
		knees.append(knee * MM)
		dirs.append(out)
	var pivots := {
		"hips": PackedVector3Array(hips), "knees": PackedVector3Array(knees), "leg_dirs": PackedVector3Array(dirs),
		"sockets": PackedVector3Array(sockets.map(func(v): return v * MM)), "elbows": PackedVector3Array(elbows.map(func(v): return v * MM)),
		"mand_pivots": PackedVector3Array(mands.map(func(v): return v * MM)), "neck": (HEAD_AT + Vector3(0.0, -0.1, 0.1)) * MM,
		"petiole": GASTER_AT * MM,
	}
	st.generate_tangents()
	return [st.commit(), pivots]


## A primitive's arrays (a unit sphere or cylinder) into st, placed by xf
## (model mm; made metres), tagged.
static func _add(st: SurfaceTool, arrays: Array, xf: Transform3D, part: int, seg: int, banded: bool) -> void:
	var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var nb := xf.basis.inverse().transposed()
	var verts := []
	for k in vs.size():
		verts.append([(xf * vs[k]) * MM, (nb * ns[k]).normalized(), uvs[k], vs[k].z])
	for k in idx:
		var v: Array = verts[k]
		st.set_normal(v[1])
		st.set_uv(v[2])
		st.set_custom(0, Color(part, seg, v[3], 1.0 if banded else 0.0))
		st.add_vertex(v[0])


## A unit cylinder's placing to span a to b, radius r.
static func _seg(a: Vector3, b: Vector3, r: float) -> Transform3D:
	var d := b - a
	if d.length() < 1e-4:
		d = Vector3.UP * 1e-4
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD) if absf(y.z) < 0.9 else y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x * 2.0 * r, d, z * 2.0 * r), (a + b) * 0.5)


static func _dir(yaw_a: float, pitch: float, side: float) -> Vector3:
	return Vector3(sin(yaw_a) * side * cos(pitch), sin(pitch), -cos(yaw_a) * cos(pitch))


static func _knee(hip: Vector3, ankle: Vector3, f: float, t: float, pole: Vector3) -> Vector3:
	var d := ankle - hip
	var l := clampf(d.length(), absf(f - t) + 0.01, f + t - 0.01)
	var dir := d.normalized() if d.length() > 1e-4 else Vector3.DOWN
	var a := (f * f - t * t + l * l) / (2.0 * l)
	var hh := sqrt(maxf(f * f - a * a, 0.0))
	var p := pole - dir * pole.dot(dir)
	p = p.normalized() if p.length() > 1e-4 else Vector3.UP
	return hip + dir * a + p * hh
