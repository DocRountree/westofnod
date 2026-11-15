class_name GiantKelp
extends Node3D
## Giant kelp (Macrocystis pyrifera), a plant of it, from the bottom to the
## surface of the water it's in (its origin on the bottom): its holdfast, a
## low tangle of root-like haptera gripping the rock; its fronds (several,
## each its stipe rising) with a blade every hand's breadth, alternate, each
## on its own gas float (pneumatocyst) at its base, the blades long,
## wrinkled, golden brown, finely toothed; at the surface the fronds lying
## out over the water as a canopy, their blades afloat. Swaying all through
## in the swell (shaders/render/kelp.gdshader), the canopy drifting.
##
## A purple sea urchin's chief food (meta "kelp_plant": the urchins graze at
## its holdfast, and at the drift blades lying about its base, drift_kelp()
## in sea_urchin.gd). Grazing never uses it up.

var depth := 1.0
var seed_ := 0


func _init(depth_ := 1.0, seed__ := -1) -> void:
	depth = depth_
	seed_ = seed__ if seed__ >= 0 else randi() % 100000
	set_meta("kelp_plant", true)
	set_meta("item", "kelp")
	var mi := MeshInstance3D.new()
	mi.mesh = build(depth, seed_)
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/render/kelp.gdshader")
	m.set_shader_parameter("depth", depth)
	m.set_shader_parameter("phase", float(seed_ % 997) * 0.37)
	mi.material_override = m
	add_child(mi)


func _ready() -> void:
	# (a few torn blades lying about its base: drifted down, what the urchins graze most)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ + 7
	for k in 3:
		var b: Node3D = (load("res://scripts/creatures/sea_urchin.gd") as GDScript).call("drift_kelp")
		var a := rng.randf() * TAU
		b.position = Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.15, 0.4)
		b.rotation.y = rng.randf() * TAU
		b.scale = Vector3.ONE * rng.randf_range(0.6, 1.0)
		add_child(b)


## Its mesh: COLOR r its height up the water (0 the bottom, 1 the surface),
## g 1 for the canopy afloat, b its part (0 the holdfast and stipes, 0.5 a
## float, 1 a blade), a along a blade; CUSTOM0 x a frond's phase, y across a
## blade (-1..1).
static func build(d: float, sd: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	# the holdfast: a knob, and haptera curving down and out from it
	var top := 0.045
	_tube(st, [Vector3(0, 0.0, 0), Vector3(0, top, 0)], [0.035, 0.02], d, 0.0, 0.0)
	for k in 22:
		var a := rng.randf() * TAU
		var h := rng.randf_range(0.01, top)
		var reach := rng.randf_range(0.05, 0.11)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var pts := []
		for j in 5:
			var t := float(j) / 4.0
			pts.append(dir * (0.012 + reach * t) + Vector3(0.0, h * (1.0 - t * t) + 0.002, 0.0) + Vector3(sin(t * 5.0 + k), 0.0, cos(t * 4.0 + k)) * 0.006)
		_tube(st, pts, [0.006, 0.005, 0.004, 0.0035, 0.002], d, 0.0, 0.0)
	# its fronds
	var nf := rng.randi_range(5, 8)
	var surf := d - 0.01
	for f in nf:
		var ph := rng.randf() * TAU
		var a0 := rng.randf() * TAU
		var lean := Vector3(cos(a0), 0.0, sin(a0)) * rng.randf_range(0.05, 0.25)
		var tall := surf * rng.randf_range(0.55, 1.0) # (some still growing up toward the surface)
		var reaches := tall > surf * 0.97
		var spine := []
		var NSg := 24
		for j in NSg + 1:
			var t := float(j) / NSg
			var y := top + (tall - top) * t
			spine.append(Vector3(0.0, y, 0.0) + lean * t * t + Vector3(sin(t * 4.0 + ph), 0.0, cos(t * 3.0 + ph)) * 0.02 * t)
		if reaches: # (out along the surface: the canopy)
			var out := Vector3(cos(a0 + 0.3), 0.0, sin(a0 + 0.3))
			var last: Vector3 = spine[spine.size() - 1]
			var canopy := rng.randf_range(0.35, 0.7)
			for j in range(1, 9):
				var t := float(j) / 8.0
				spine.append(last + out * canopy * t + Vector3(sin(t * 6.0 + ph) * 0.03, 0.0, 0.0))
		var radii := []
		for j in spine.size():
			radii.append(0.0035)
		_tube(st, spine, radii, d, ph, 0.0)
		# its blades, alternate, every so often up it, each on its float
		var side := 1.0
		var stepping := 0.11
		var along := 0.0
		var total := 0.0
		for j in spine.size() - 1:
			total += (spine[j + 1] as Vector3).distance_to(spine[j])
		var j0 := 0
		var acc := 0.0
		along = 0.12
		while along < total - 0.02:
			while j0 < spine.size() - 2 and acc + (spine[j0 + 1] as Vector3).distance_to(spine[j0]) < along:
				acc += (spine[j0 + 1] as Vector3).distance_to(spine[j0])
				j0 += 1
			var seg: Vector3 = (spine[j0 + 1] as Vector3) - (spine[j0] as Vector3)
			var tt := clampf((along - acc) / maxf(seg.length(), 1e-5), 0.0, 1.0)
			var at: Vector3 = (spine[j0] as Vector3).lerp(spine[j0 + 1], tt)
			var up := seg.normalized()
			var flat := absf(up.y) < 0.5 # (afloat in the canopy)
			var aw := up.cross(Vector3.UP if not flat else Vector3.FORWARD).normalized()
			if aw.length() < 0.5:
				aw = Vector3.RIGHT
			var bdir := (up * (0.5 if not flat else 0.2) + aw * side).normalized()
			if flat:
				bdir.y = 0.0
				bdir = bdir.normalized()
			var fl := at + aw * side * 0.012
			_float(st, fl, up, d, ph, flat)
			var bl := rng.randf_range(0.18, 0.32) * clampf(along / 0.3, 0.45, 1.0)
			_blade(st, fl + bdir * 0.012, bdir, bl, rng.randf_range(0.05, 0.07), d, ph + float(j0) * 0.3, flat, rng)
			side = -side
			along += stepping * rng.randf_range(0.8, 1.2)
	st.index()
	return st.commit()


static func _col(p: Vector3, d: float, part: float, along := 0.0) -> Color:
	var h := clampf(p.y / d, 0.0, 1.0)
	return Color(h, 1.0 if h > 0.97 else 0.0, part, along)


## A tube along pts (radii at each).
static func _tube(st: SurfaceTool, pts: Array, radii: Array, d: float, ph: float, part: float) -> void:
	var NS := 5
	var frames := []
	for j in pts.size():
		var tng: Vector3 = ((pts[mini(j + 1, pts.size() - 1)] as Vector3) - (pts[maxi(j - 1, 0)] as Vector3)).normalized()
		var a := tng.cross(Vector3.FORWARD if absf(tng.z) < 0.9 else Vector3.RIGHT).normalized()
		frames.append([a, tng.cross(a)])
	for j in pts.size() - 1:
		for s in NS:
			var q := []
			for e: Vector2i in [Vector2i(j, s), Vector2i(j + 1, s), Vector2i(j + 1, s + 1), Vector2i(j, s + 1)]:
				var an := TAU * float(e.y) / NS
				var off: Vector3 = ((frames[e.x][0] as Vector3) * cos(an) + (frames[e.x][1] as Vector3) * sin(an))
				q.append([(pts[e.x] as Vector3) + off * float(radii[e.x]), off])
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.set_color(_col(q[k][0], d, part))
				st.set_custom(0, Color(ph, 0.0, 0.0, 0.0))
				st.set_normal(q[k][1])
				st.add_vertex(q[k][0])


## A float: a little gas bladder, a teardrop on its short stalk.
static func _float(st: SurfaceTool, at: Vector3, up: Vector3, d: float, ph: float, flat: bool) -> void:
	var r := 0.007
	var NS := 6
	var NR := 4
	var a := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var b := up.cross(a)
	for i in NR:
		for s in NS:
			var q := []
			for e: Vector2i in [Vector2i(i, s), Vector2i(i + 1, s), Vector2i(i + 1, s + 1), Vector2i(i, s + 1)]:
				var th := PI * float(e.x) / NR
				var an := TAU * float(e.y) / NS
				var n := up * cos(th) + (a * cos(an) + b * sin(an)) * sin(th)
				var p := at + up * cos(th) * r * 1.5 + (a * cos(an) + b * sin(an)) * sin(th) * r
				q.append([p, n])
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.set_color(_col(q[k][0], d, 0.5))
				st.set_custom(0, Color(ph, 0.0, 0.0, 0.0))
				st.set_normal(q[k][1])
				st.add_vertex(q[k][0])


## A blade: long, lance shaped, rumpled across, its edges finely toothed (in
## the shader); out along dir from its float.
static func _blade(st: SurfaceTool, at: Vector3, dir: Vector3, ln: float, w: float, d: float, ph: float, flat: bool, rng: RandomNumberGenerator) -> void:
	var nrm := Vector3.UP if flat else dir.cross(Vector3.UP).cross(dir).normalized()
	if nrm.length() < 0.5:
		nrm = Vector3.FORWARD
	var across := dir.cross(nrm).normalized()
	var NL := 10
	var NW := 3
	var rows := []
	var wob := rng.randf() * 10.0
	for i in NL + 1:
		var u := float(i) / NL
		var ww := w * (0.25 + 0.75 * sin(PI * minf(u * 0.9 + 0.1, 1.0))) * (1.0 - 0.6 * u * u)
		var row := []
		for j in NW * 2 + 1:
			var v := float(j) / NW - 1.0
			var p := at + dir * ln * u + across * v * ww * 0.5 + nrm * (0.004 * sin(u * 25.0 + v * 3.0 + wob) * absf(v) + (0.0 if flat else -0.02 * u * u))
			if flat:
				p.y = minf(p.y, d - 0.008)
			row.append([p, u, v])
		rows.append(row)
	for i in NL:
		for j in NW * 2:
			var q: Array = [rows[i][j], rows[i + 1][j], rows[i + 1][j + 1], rows[i][j + 1]]
			for k: int in [0, 1, 2, 0, 2, 3]:
				var p: Vector3 = q[k][0]
				var c := _col(p, d, 1.0, q[k][1])
				if flat:
					c.g = 1.0
				st.set_color(c)
				st.set_custom(0, Color(ph, q[k][2], 0.0, 0.0))
				st.set_normal(nrm)
				st.add_vertex(p)
