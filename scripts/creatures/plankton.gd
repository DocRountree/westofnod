class_name Plankton
extends MultiMeshInstance3D
## Young in the plankton, drawn at 6x life size (a few mm at the most, most
## under one): a cloud of them in the water, drifting, swimming.
## - "octopus": an octopus's paralarvae: a big glassy mantle, its gut and
##   eyes dark in it, flecked with orange brown chromatophores, eight short
##   arms each with a few suckers; going by little jets.
## - "sea_star": a sea star's bipinnaria, then brachiolaria: glassy, a body
##   folded into lobes edged with its ciliated band (it swims and feeds by
##   it, beating), the gut a brown spot in it, three short arms out front
##   to settle by.
## - "pluteus": a sea urchin's or a sand dollar's echinopluteus (eight
##   arms on their rods: UrchinLarvae's).
## With a record (FaunaSim's: the young of a kind, a "plankton" stage),
## what it is is all: its time is the record's. Left to itself (the
## sandbox's) with young_script set, after its time a few of it settle to
## the bottom, a young one each (reported "hatched").
## plume(): a spawning one's plume of eggs or milt, going up in the water.

const SCALE := 6.0

var kind := "octopus"
var bottom := -1e9
var top := 1e9
var life := 120.0 # (left to itself: its time in the water)
var young_script := "" # (left to itself: what settles from it)
var settle_max := 4

var pos := PackedVector3Array()
var vel := PackedVector3Array()
var _t := 0.0
var _settled := 0

static var _meshes := {}
static var _mat: ShaderMaterial


func _init(kind_ := "octopus", n := 60) -> void:
	kind = kind_
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh_for(kind)
	multimesh.instance_count = n
	material_override = material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pos.resize(n)
	vel.resize(n)
	for i in n:
		pos[i] = Vector3(randf_range(-0.25, 0.25), randf_range(0.0, 0.4), randf_range(-0.25, 0.25))
		vel[i] = Vector3.ZERO
		multimesh.set_instance_custom_data(i, Color(randf(), 1.0 if kind == "octopus" else 0.0, 0.0, 0.0))
	_place_all()


## The water it's in: its bottom and its surface (world y).
func set_water(lo: float, hi: float) -> void:
	bottom = lo
	top = hi


func behaviours() -> Array:
	return []


func _process(dt: float) -> void:
	dt = Fauna.swarm_dt(self, dt)
	if dt <= 0.0:
		return
	_t += dt
	var n := pos.size()
	var lo := bottom - global_position.y + 0.02
	var hi := top - global_position.y - 0.03
	var settling := young_script != "" and _t > life
	for i in n:
		var want := Vector3(sin(_t * 0.21 + i), 0.5 * sin(_t * 0.13 + i * 1.7), cos(_t * 0.17 + i * 0.7)) * 0.012
		if kind == "octopus": # (by little jets: a pulse, a glide)
			var ph := fmod(_t * 1.3 + i * 0.37, 1.0)
			want *= 0.4 + 3.0 * float(ph < 0.15)
		if settling:
			want = Vector3(0.0, -0.02, 0.0)
		vel[i] = vel[i].lerp(want, minf(dt * 1.5, 1.0))
		pos[i] += vel[i] * dt
		var off := Vector2(pos[i].x, pos[i].z)
		if off.length() > 0.6: # (kept a cloud)
			off = off.normalized() * 0.6
			pos[i] = Vector3(off.x, pos[i].y, off.y)
		pos[i].y = clampf(pos[i].y, lo, maxf(hi, lo))
		if settling and pos[i].y <= lo + 0.001 and _settled < settle_max and randf() < 0.3:
			_settled += 1
			var y: Node3D = (load(young_script) as GDScript).new(true)
			get_parent().add_child(y)
			if y.has_method("place"):
				y.call("place", global_position + Vector3(pos[i].x, lo - 0.02, pos[i].z), randf() * TAU)
			else:
				y.global_position = global_position + Vector3(pos[i].x, lo - 0.02, pos[i].z)
			Fauna.report.call_deferred(&"hatched", self, {"young": y})
	if settling and _t > life + 30.0:
		queue_free()
		return
	_place_all()


func _place_all() -> void:
	for i in pos.size():
		var b := Basis()
		if vel[i].length() > 0.0005: # (its way: arms behind an octopus's, the rest's ahead)
			var up := vel[i].normalized() * (-1.0 if kind == "octopus" else 1.0)
			var side := up.cross(Vector3.UP if absf(up.y) < 0.95 else Vector3.RIGHT).normalized()
			b = Basis(side, up, side.cross(up))
		multimesh.set_instance_transform(i, Transform3D(b, pos[i]))


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/render/plankton.gdshader")
	return _mat


## Its young's mesh, drawn: COLOR.g 0 the body (glassy), 0.5 its gut, its
## eyes, 0.75 a chromatophore, 1 an arm or a lobe's band (r along it).
static func mesh_for(k: String) -> Mesh:
	if _meshes.has(k):
		return _meshes[k]
	var m: Mesh
	match k:
		"pluteus":
			m = (load("res://scripts/creatures/urchin_larvae.gd") as GDScript).call("_pluteus")
		"sea_star":
			m = _bipinnaria()
		_:
			m = _paralarva()
	_meshes[k] = m
	return m


static func _blob(st: SurfaceTool, c: Vector3, r: Vector3, g: float, rings := 5, segs := 8) -> void:
	for i in rings:
		for j in segs:
			var q := []
			for e: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var ph := PI * float(e.x) / rings
				var th := TAU * float(e.y) / segs
				var n := Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th))
				q.append([c + n * r, n])
			for t: int in [0, 1, 2, 0, 2, 3]:
				st.set_color(Color(0.0, g, 0.0, 1.0))
				st.set_normal(q[t][1])
				st.add_vertex(q[t][0])


## An octopus's paralarva (about 2 mm): its mantle up, arms below.
static func _paralarva() -> ArrayMesh:
	var k := SCALE * 0.001
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_blob(st, Vector3(0.0, 0.7 * k, 0.0), Vector3(0.45, 0.75, 0.45) * k, 0.0, 6, 10) # (its mantle)
	_blob(st, Vector3(0.0, 0.6 * k, 0.0), Vector3(0.2, 0.35, 0.2) * k, 0.5) # (its gut, its ink sac)
	for s in [-1.0, 1.0]:
		_blob(st, Vector3(s * 0.22 * k, 0.05 * k, 0.0), Vector3.ONE * 0.1 * k, 0.5) # (its eyes)
	for i in 14: # (chromatophores)
		var a := float(i) * 2.4
		var y := 0.2 + 0.08 * float(i)
		_blob(st, Vector3(cos(a) * 0.4 * k, y * k, sin(a) * 0.4 * k), Vector3.ONE * 0.05 * k, 0.75, 2, 4)
	for a in 8: # (its arms: short, a few suckers each)
		var an := TAU * float(a) / 8.0
		var d := Vector3(cos(an) * 0.5, -1.0, sin(an) * 0.5).normalized()
		for seg in 3:
			var t := float(seg) / 3.0
			_blob(st, Vector3(0.0, -0.1 * k, 0.0) + d * (0.15 + t * 0.45) * k, Vector3.ONE * (0.07 - 0.015 * seg) * k, 1.0, 3, 5)
	return st.commit()


## A sea star's bipinnaria (under a mm): its body folded into lobes,
## three short arms in front.
static func _bipinnaria() -> ArrayMesh:
	var k := SCALE * 0.001
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_blob(st, Vector3.ZERO, Vector3(0.28, 0.5, 0.2) * k, 0.0, 6, 10)
	_blob(st, Vector3(0.0, -0.05 * k, 0.0), Vector3(0.12, 0.18, 0.1) * k, 0.5)
	for i in 8: # (its lobes, their bands)
		var y := -0.4 + 0.11 * float(i)
		var s := -1.0 if i % 2 == 0 else 1.0
		_blob(st, Vector3(s * 0.26 * k, y * k, 0.0), Vector3(0.1, 0.07, 0.08) * k, 1.0, 3, 6)
	for i in 3: # (its brachiolar arms)
		var an := (float(i) - 1.0) * 0.6
		_blob(st, Vector3(sin(an) * 0.12 * k, 0.6 * k, cos(an) * 0.05 * k), Vector3(0.05, 0.14, 0.05) * k, 1.0, 3, 5)
	return st.commit()


## A spawning one's plume: eggs (orange) or milt (white), up from it into
## the water, spreading. Put at the pores, under what spawns.
static func plume(female: bool, amount := 160) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 9.0
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 14.0
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.05
	p.gravity = Vector3(0.0, 0.004, 0.0)
	p.damping_min = 0.004
	p.damping_max = 0.01
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.6
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.25))
	grow.add_point(Vector2(1.0, 1.0))
	p.scale_amount_curve = grow
	var q := QuadMesh.new()
	q.size = Vector2(0.03, 0.03)
	var blob := GradientTexture2D.new()
	blob.fill = GradientTexture2D.FILL_RADIAL
	blob.fill_from = Vector2(0.5, 0.5)
	blob.fill_to = Vector2(0.5, 0.0)
	blob.gradient = Gradient.new()
	blob.gradient.set_color(0, Color(1, 1, 1, 1))
	blob.gradient.set_color(1, Color(1, 1, 1, 0))
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = blob
	m.albedo_color = Color(0.95, 0.62, 0.3, 0.32) if female else Color(0.95, 0.94, 0.9, 0.28)
	q.material = m
	p.mesh = q
	return p
