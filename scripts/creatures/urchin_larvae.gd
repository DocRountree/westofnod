class_name UrchinLarvae
extends MultiMeshInstance3D
## A purple sea urchin's young in the water: drawn at 6x life size, to be
## seen (an egg 80 microns; a pluteus under a millimetre).
##
## - "egg": eggs, cream orange, drifting up from where she spawned and
##   spreading. Fertilized, they hatch (here after egg_secs) into larvae;
##   not, they go to nothing.
## - "larva": echinoplutei: a glassy body like an easel, its eight arms held
##   up and out on their skeletal rods, the gut a green brown spot; swimming
##   arms first on the beat of the ciliated band round them, which also
##   sweeps their food in (the plankton: microscopic, not drawn; only the
##   arms' feeding beat shown). After larva_secs they sink and settle: a few
##   (most are eaten, or die) turn into spat on the bottom (SeaUrchin,
##   young), green, growing.
## develop(): the next stage now.

const SCALE := 6.0

var stage := "egg"
var fertile := true
var egg_secs := 40.0
var larva_secs := 90.0
var settle_max := 6 # (how many come to the bottom as spat)
var bottom := -1.0
var top := 0.0

var pos := PackedVector3Array()
var vel := PackedVector3Array()
var _t := 0.0
var _fade := 1.0
var _settled := 0
var _down := PackedByteArray()

static var _egg_mesh: Mesh
static var _larva_mesh: ArrayMesh
static var _mat: ShaderMaterial


func _init(stage_ := "egg", n := 120, fertile_ := true) -> void:
	stage = stage_
	fertile = fertile_
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = _mesh_for(stage)
	multimesh.instance_count = n
	material_override = _material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pos.resize(n)
	vel.resize(n)
	_down.resize(n)
	for i in n:
		pos[i] = Vector3(randf_range(-0.03, 0.03), randf_range(0.0, 0.03), randf_range(-0.03, 0.03))
		vel[i] = Vector3(randf_range(-0.004, 0.004), randf_range(0.004, 0.012), randf_range(-0.004, 0.004))
		multimesh.set_instance_custom_data(i, Color(randf(), 1.0 if stage == "larva" else 0.0, 0.0, 0.0))
	_place_all()


## The water it's in: its bottom and its surface (world y).
func set_water(lo: float, hi: float) -> void:
	bottom = lo
	top = hi


func behaviours() -> Array:
	return ["develop"]


## On to the next stage now: eggs hatch; larvae settle.
func develop() -> void:
	if stage == "egg":
		_t = egg_secs
	elif stage == "larva":
		_t = larva_secs


func _mesh_for(s: String) -> Mesh:
	if s == "egg":
		if _egg_mesh == null:
			var sm := SphereMesh.new()
			sm.radius = 0.00004 * SCALE
			sm.height = 0.00008 * SCALE
			sm.radial_segments = 8
			sm.rings = 4
			_egg_mesh = sm
		return _egg_mesh
	if _larva_mesh == null:
		_larva_mesh = _pluteus()
	return _larva_mesh


static func _material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/render/urchin_larva.gdshader")
	return _mat


## An echinopluteus, 8-armed: its body (COLOR.g 0), its arms (1: r along
## them), its gut (0.5). Up its +y, arms forward.
static func _pluteus() -> ArrayMesh:
	var k := SCALE * 0.001 # (a millimetre, drawn)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := SphereMesh.new() # (the body: a rounded pyramid)
	body.radius = 0.16 * k
	body.height = 0.36 * k
	body.radial_segments = 8
	body.rings = 5
	var arr := body.get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for gut in [false, true]:
		for i in ix:
			var v: Vector3 = vs[i] * (0.5 if gut else 1.0)
			v.y *= 1.0 if gut else (1.0 - 0.35 * clampf(v.y / (0.18 * k), 0.0, 1.0)) # (tapered up: the easel's peak)
			st.set_color(Color(0.0, 0.5 if gut else 0.0, 0.0, 1.0))
			st.set_normal(ns[i])
			st.add_vertex(v - Vector3(0.0, 0.04 * k if gut else 0.0, 0.0))
	# its arms: four pairs, up and out, the postoral longest
	var arms := [[0.95, 0.3, 0.2, 0.0], [0.6, 0.55, 0.05, 0.0], [0.5, 0.2, -0.25, 0.05], [0.35, 0.75, 0.2, 0.1]]
	for a: Array in arms:
		for side in [-1.0, 1.0]:
			var d := Vector3(side * float(a[1]), 1.0, float(a[2])).normalized()
			var base := Vector3(side * 0.08 * k, (0.05 + float(a[3])) * k, float(a[2]) * 0.2 * k)
			var ln: float = float(a[0]) * k
			var r := 0.022 * k
			var u := d.cross(Vector3.FORWARD).normalized()
			var w := d.cross(u)
			var NSd := 4
			for seg in 3:
				for s in NSd:
					var q := []
					for e: Vector2i in [Vector2i(seg, s), Vector2i(seg + 1, s), Vector2i(seg + 1, s + 1), Vector2i(seg, s + 1)]:
						var t := float(e.x) / 3.0
						var an := TAU * float(e.y) / NSd
						var off := (u * cos(an) + w * sin(an)) * r * (1.0 - 0.6 * t)
						q.append([base + d * ln * t + off, off.normalized(), t])
					for tri: Array in [[0, 1, 2], [0, 2, 3]]:
						for j: int in tri:
							st.set_color(Color(q[j][2], 1.0, side * 0.5 + 0.5, 1.0))
							st.set_normal(q[j][1])
							st.add_vertex(q[j][0])
	return st.commit()


func _process(dt: float) -> void:
	_t += dt
	var n := pos.size()
	var lo := bottom - global_position.y
	var hi := top - global_position.y
	match stage:
		"egg":
			for i in n: # (drifting up, spreading, slowing)
				vel[i] = vel[i].lerp(Vector3(randf_range(-0.003, 0.003), 0.001, randf_range(-0.003, 0.003)), dt * 0.3)
				pos[i] += vel[i] * dt
				pos[i].y = clampf(pos[i].y, lo + 0.01, hi - 0.01)
			if _t > egg_secs:
				if fertile: # (hatched: plutei)
					stage = "larva"
					_t = 0.0
					multimesh.mesh = _mesh_for("larva")
					for i in n:
						multimesh.set_instance_custom_data(i, Color(randf(), 1.0, 0.0, 0.0))
				else: # (unfertilized: gone)
					_fade -= dt * 0.2
					if _fade <= 0.0:
						queue_free()
						return
		"larva":
			var settling := _t > larva_secs
			for i in n:
				if _down[i] == 1:
					continue
				if settling: # (sinking, to settle)
					vel[i] = vel[i].lerp(Vector3(0.0, -0.01, 0.0), dt)
				else: # (swimming, arms first, on their beat; wandering through the water)
					var want := Vector3(sin(_t * 0.2 + i), 0.4 * sin(_t * 0.13 + i * 1.7), cos(_t * 0.17 + i * 0.7)) * 0.006
					vel[i] = vel[i].lerp(want, dt * 0.5)
				pos[i] += vel[i] * dt
				pos[i].y = minf(pos[i].y, hi - 0.01)
				if pos[i].y <= lo + 0.003:
					pos[i].y = lo + 0.003
					if settling:
						_down[i] = 1
						if _settled < settle_max and randf() < (1.0 if i % 4 == 0 else 0.25):
							_settled += 1
							var spat: Node3D = (load("res://scripts/creatures/sea_urchin.gd") as GDScript).new(true)
							spat.set("size", 0.06)
							spat.call("_set_size")
							get_parent().add_child(spat)
							spat.global_position = Vector3(global_position.x + pos[i].x, bottom, global_position.z + pos[i].z)
			if settling and _t > larva_secs + 60.0:
				queue_free()
				return
	_place_all()


func _place_all() -> void:
	for i in pos.size():
		var s := _fade
		if stage == "larva" and _down[i] == 1:
			s = 0.0 # (settled: a spat now, or gone)
		var b := Basis.from_scale(Vector3.ONE * maxf(s, 0.0001))
		if stage == "larva" and vel[i].length() > 0.0005: # (arms first, into its way)
			var up := vel[i].normalized()
			var side := up.cross(Vector3.UP if absf(up.y) < 0.95 else Vector3.RIGHT).normalized()
			b = Basis(side, up, side.cross(up)).scaled(Vector3.ONE * maxf(s, 0.0001))
		multimesh.set_instance_transform(i, Transform3D(b, pos[i]))
