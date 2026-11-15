class_name SeaUrchin
extends Node3D
## A purple sea urchin (Strongylocentrotus purpuratus), life size: its test
## (shell) 5-6 cm across, flattened, a little five-sided seen from above, deep
## purple, beaded with the tubercles its spines sit on, the five paler double
## rows (the ambulacra) its tube feet come through, the dark periproct on top;
## its spines 2-3 cm, stout, longest round its middle, short on top, splayed
## flat beneath, purple at the base and paler violet to their tips; its tube
## feet, long, thin and translucent, each with a sucker, waving among the
## spines; beneath, the mouth's leathery membrane and Aristotle's lantern, its
## five white teeth meeting. A young one (spat, a few mm to 2 cm) greenish,
## its spines pale.
##
## One mesh (cached), posed by shaders/render/urchin.gdshader: the spines
## swaying on their ball joints, turned to point at a threat; the tube feet
## reaching and waving, drawn in when threatened; the teeth working.
##
## Its life: spawning (spawn(): the ones near spawning with it, a female's
## eggs fertilized if a male near is spawning too) -> eggs drifting up in the
## water -> echinoplutei, its larvae, swimming, feeding on the plankton
## (UrchinLarvae, urchin_larvae.gd) -> settling to the bottom, turning into
## spat -> growing (green, pale spined) to the grown purple urchin.
##
## - wander(): creeping over the bottom on its tube feet (a few cm a minute
##   in life; here faster, to be seen), any side first.
## - eat(): to the nearest kelp (a giant kelp's holdfast, GiantKelp, or a
##   torn blade drifted down to the bottom, drift_kelp(): its chief food) and
##   up onto it, its tube feet pulling the blade in under it, the lantern
##   biting at it a good while (the kelp never used up). None near: grazing
##   the film of algae on the bottom where it is (graze()).
## - defend(from): its spines swung to point at it (a sea otter near: on its own).
## - spawn(): broadcast spawning: a plume from the five pores on top, rising
##   (a female's eggs orange, a male's milt white).
## Taken up by a sea otter (meta "taken" / "sink"): its own motion stops.

const R := 0.027 # (the test's radius)
const H_TOP := 0.6 # (its height above its equator, of R)
const H_BOT := 0.42
const LIFT := 0.004 # (held up off the bottom on its lower spines)

var young := false
var male := false
var home := Vector3.INF
var roam := 0.6 # (how far it wanders from home)
var size := 1.0 # (grown; a newly settled one 0.06, growing)
var grow_secs := 900.0 # (here, from spat to grown)
var spawned_at := -1e9 # (when it last spawned, in seconds: the time)
var food: Node3D # (the drift kelp it's after)

var _mode := "wander"
var _t := 0.0
var _until := 0.0
var _dir := Vector3.FORWARD
var _threat := Vector3.ZERO
var _threat_to := Vector3.ZERO
var _graze := 0.0
var _check := 0.0
var _plume: CPUParticles3D
var _mi: MeshInstance3D

static var _mesh: ArrayMesh
static var _mat: ShaderMaterial


func _init(young_ := false) -> void:
	young = young_
	male = randf() < 0.5
	_mi = MeshInstance3D.new()
	_mi.mesh = mesh()
	_mi.material_override = material()
	_mi.rotation.y = randf() * TAU
	add_child(_mi)
	_mi.set_instance_shader_parameter("seed", randf())
	if young:
		size = randf_range(0.18, 0.35)
	_set_size()
	_dir = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)


func behaviours() -> Array:
	return ["wander", "eat", "graze", "defend", "spawn"]


func _set_size() -> void:
	scale = Vector3.ONE * size
	young = size < 0.8
	_mi.set_instance_shader_parameter("juvenile", 1.0 - smoothstep(0.35, 0.8, size)) # (green and pale as spat; purple coming on as it grows)


## A torn blade of giant kelp, drifted down to the bottom: olive brown,
## its surface rumpled, a float at its base. Meta "drift_kelp".
static func drift_kelp() -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var NL := 24
	var NW := 4
	var Lb := 0.42
	var pts := []
	for i in NL + 1:
		var u := float(i) / NL
		var w := 0.055 * sin(PI * minf(u * 1.15 + 0.08, 1.0)) + 0.008
		var row := []
		for j in NW + 1:
			var v := float(j) / NW - 0.5
			var x := v * w * 2.0 + 0.012 * sin(u * 9.0)
			var y := 0.002 + 0.004 * absf(sin(u * 23.0 + v * 6.0)) * (0.4 + absf(v)) # (rumpled)
			row.append(Vector3(x, y, u * Lb - Lb * 0.2))
		pts.append(row)
	for i in NL:
		for j in NW:
			var q: Array = [pts[i][j], pts[i + 1][j], pts[i + 1][j + 1], pts[i][j + 1]]
			var n: Vector3 = (q[1] - q[0]).cross(q[3] - q[0]).normalized()
			if n.y < 0.0:
				n = -n
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.set_normal(n)
				st.add_vertex(q[k])
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.36, 0.3, 0.1)
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	root.add_child(mi)
	var fl := MeshInstance3D.new() # (its pneumatocyst: the gas float at the blade's base)
	var sm := SphereMesh.new()
	sm.radius = 0.012
	sm.height = 0.03
	fl.mesh = sm
	fl.material_override = m
	fl.rotation.x = PI * 0.5
	fl.position = Vector3(0.0, 0.01, -Lb * 0.2 - 0.012)
	root.add_child(fl)
	root.set_meta("drift_kelp", 1.0)
	root.set_meta("item", "kelp")
	return root


func eat(what: Node3D = null) -> void:
	food = what
	if food == null:
		var best := 3.0
		for o in get_parent().get_children(): # (a blade lying on the bottom, or a kelp plant's holdfast; a plant's own drift blades)
			var cands: Array = [o]
			if o is Node3D and o.has_meta("kelp_plant"):
				cands.append_array(o.get_children())
			for f in cands:
				if f is Node3D and (f.has_meta("drift_kelp") or f.has_meta("kelp_plant")):
					var d := (f as Node3D).global_position.distance_to(global_position)
					if d < best:
						best = d
						food = f
	if food == null:
		graze()
		return
	_to("seek", 120.0)


func wander() -> void:
	_to("wander", randf_range(20.0, 50.0))


func graze() -> void:
	_to("graze", randf_range(10.0, 25.0))


func defend(from: Vector3) -> void:
	var d := global_transform.affine_inverse() * from
	_threat_to = d.normalized() if d.length() > 0.001 else Vector3.UP
	_to("defend", 8.0)


func spawn(with_others := true) -> void:
	if young:
		return
	_to("spawn", 12.0)
	spawned_at = Time.get_ticks_msec() / 1000.0
	if with_others: # (one spawning sets off those near it)
		for o in get_parent().get_children():
			if o is SeaUrchin and o != self and not o.young and (o as Node3D).global_position.distance_to(global_position) < 2.5:
				o.call("spawn", false)
	if not male: # (her eggs, out into the water above her: fertilized if a male near is spawning)
		var fert := false
		for o in get_parent().get_children():
			if o is SeaUrchin and o.male and o != self and (o as Node3D).global_position.distance_to(global_position) < 3.0:
				fert = true
		var larvae: Node3D = (load("res://scripts/creatures/urchin_larvae.gd") as GDScript).new("egg", 120, fert)
		get_parent().add_child(larvae)
		larvae.global_position = global_position + Vector3(0.0, (LIFT + R) * size + 0.02, 0.0)
		larvae.call("set_water", global_position.y, global_position.y + float(get_meta("depth", 1.0)))
	if _plume == null:
		_plume = CPUParticles3D.new()
		_plume.amount = 160
		_plume.lifetime = 9.0
		_plume.local_coords = false
		_plume.direction = Vector3.UP
		_plume.spread = 14.0
		_plume.initial_velocity_min = 0.02
		_plume.initial_velocity_max = 0.05
		_plume.gravity = Vector3(0.0, 0.004, 0.0) # (drifting up and spreading: a cloud above it)
		_plume.damping_min = 0.004
		_plume.damping_max = 0.01
		_plume.scale_amount_min = 0.5
		_plume.scale_amount_max = 1.6
		_plume.amount = 260
		var grow := Curve.new() # (spreading as it rises)
		grow.add_point(Vector2(0.0, 0.25))
		grow.add_point(Vector2(1.0, 1.0))
		_plume.scale_amount_curve = grow
		var q := QuadMesh.new()
		q.size = Vector2(0.03, 0.03)
		var blob := GradientTexture2D.new() # (a soft round puff)
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
		m.albedo_color = Color(0.95, 0.94, 0.9, 0.28) if male else Color(0.95, 0.62, 0.3, 0.32)
		q.material = m
		_plume.mesh = q
		_plume.position = Vector3(0.0, LIFT + R * (H_BOT + H_TOP), 0.0)
		add_child(_plume)
	_plume.emitting = true


func _to(m: String, secs: float) -> void:
	_mode = m
	_t = 0.0
	_until = secs


func _process(dt: float) -> void:
	if home == Vector3.INF:
		home = position
	_t += dt
	var held := has_meta("taken") or has_meta("sink")
	if held:
		_threat_to = Vector3.ZERO
	else:
		_check -= dt
		if _check <= 0.0: # (a sea otter close: its spines to it)
			_check = 1.0
			for o in get_parent().get_children():
				if o is SeaOtter and (o as Node3D).global_position.distance_to(global_position) < 1.2:
					defend((o as Node3D).global_position)
					break
		if young: # (growing)
			size = minf(size + dt / grow_secs, 1.0)
			_set_size()
		match _mode:
			"seek": # (to the kelp)
				if not is_instance_valid(food):
					wander()
				else:
					var to := food.global_position - global_position
					to.y = 0.0
					if to.length() < (0.09 if food.has_meta("kelp_plant") else 0.06) * maxf(size, 0.5): # (at its holdfast; on the blade)
						_to("eat", randf_range(30.0, 70.0))
					else:
						position += to.normalized() * 0.02 * dt * maxf(size, 0.4)
				_threat_to = Vector3.ZERO
			"eat": # (up on it, the blade pulled in under it by its tube feet, bitten at: there's always more)
				_threat_to = Vector3.ZERO
				if not is_instance_valid(food):
					wander()
				elif food.has_meta("drift_kelp"):
					position.y = lerpf(position.y, home.y + 0.004 * size, 1.0 - exp(-dt)) # (up on the blade)
			"wander":
				_dir = _dir.rotated(Vector3.UP, randf_range(-0.3, 0.3) * dt)
				var off := position + _dir * 0.012 * dt - home
				off.y = 0.0
				if off.length() > roam:
					_dir = _dir.lerp(-off.normalized(), clampf(dt, 0.0, 1.0)).normalized()
				position += _dir * 0.012 * dt * (0.5 if young else 1.0)
				_threat_to = Vector3.ZERO
			"graze", "spawn":
				_threat_to = Vector3.ZERO
			"defend":
				pass
		if _t > _until:
			if _plume:
				_plume.emitting = false
			if _mode == "wander":
				graze()
			else:
				wander()
	_threat = _threat.lerp(_threat_to, 1.0 - exp(-2.0 * dt))
	_graze = lerpf(_graze, 1.0 if _mode in ["graze", "eat"] and not held else 0.0, 1.0 - exp(-3.0 * dt))
	var local := _mi.transform.basis.inverse() * _threat
	_mi.set_instance_shader_parameter("threat", local)
	_mi.set_instance_shader_parameter("graze", _graze)
	_mi.set_instance_shader_parameter("feet", 0.0 if held else (1.0 - _threat.length()) * (1.0 if _mode == "wander" else 0.6))


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/render/urchin.gdshader")
	return _mat


## The test's surface at (polar angle phi from the top, around theta): its
## point and its normal.
static func _test(phi: float, th: float) -> Array:
	var rr := R * (1.0 + 0.035 * cos(5.0 * th)) # (a little five-sided)
	var c := cos(phi)
	var s := sin(phi)
	var h := H_TOP if c > 0.0 else H_BOT
	var p := Vector3(rr * s * cos(th), R * h * c + R * H_BOT + LIFT, rr * s * sin(th))
	var n := Vector3(s * cos(th) / rr, c / (R * h), s * sin(th) / rr).normalized()
	return [p, n]


static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	# the test
	var NT := 48
	var NP := 24
	for i in NP:
		for j in NT:
			var q := []
			for e: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				q.append(_test(PI * float(e.x) / NP, TAU * float(e.y) / NT))
			for tri: Array in [[0, 2, 1], [0, 3, 2]]:
				for k: int in tri:
					_v(st, q[k][0], q[k][1], Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0))
	# the spines: on their tubercles, in five-fold rows
	var NS := 460
	for i in NS:
		var u := (float(i) + 0.5) / NS
		var phi := acos(1.0 - 2.0 * u) * 0.94 + 0.04
		var th := float(i) * 2.39996 + rng.randf_range(-0.05, 0.05)
		var tn: Array = _test(phi, th)
		var p: Vector3 = tn[0]
		var n: Vector3 = tn[1]
		var c := cos(phi)
		var d := n
		if c < -0.2: # (beneath: splayed out flat, holding it up)
			d = (n * Vector3(1.0, 0.25, 1.0)).normalized()
		d = (d + Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.08, 0.08), rng.randf_range(-0.12, 0.12))).normalized()
		var inter := 0.5 - 0.5 * cos(5.0 * th) # (the primary spines between the ambulacra: longer)
		var ln := 0.024 * (0.3 + 0.7 * pow(sin(phi), 1.4)) * (0.82 + 0.25 * inter) * rng.randf_range(0.85, 1.1)
		if c < -0.5:
			ln *= 0.65
		var rad := 0.001 * (0.75 + 0.35 * inter)
		_spine(st, p - d * 0.001, d, ln, rad, 1.0, rng.randf(), 5)
	# the tube feet: out through the five ambulacra
	for i in 70:
		var k := i % 5
		var th := TAU * float(k) / 5.0 + rng.randf_range(-0.07, 0.07) + PI / 5.0 * 0.0
		var phi := rng.randf_range(0.25, 0.95) * PI
		var tn: Array = _test(phi, th)
		var d: Vector3 = (tn[1] as Vector3)
		if cos(phi) < -0.3:
			d = (d * Vector3(1.0, 0.5, 1.0)).normalized()
		_spine(st, tn[0], d, rng.randf_range(0.02, 0.034), 0.00038, 0.5, rng.randf(), 4)
	# the teeth: five, meeting at the middle beneath
	for k in 5:
		var a := TAU * float(k) / 5.0
		var b := Vector3(cos(a) * 0.0045, LIFT + 0.0016, sin(a) * 0.0045)
		var d := (Vector3(-cos(a), -0.9, -sin(a))).normalized()
		_spine(st, b, d, 0.0042, 0.0011, 0.75, 0.0, 4)
	st.index()
	_mesh = st.commit()
	return _mesh


static func _v(st: SurfaceTool, p: Vector3, n: Vector3, col: Color, cu: Color) -> void:
	st.set_normal(n)
	st.set_color(col)
	st.set_custom(0, cu)
	st.add_vertex(p)


## A spine (kind 1), a tube foot (0.5, its sucker at the tip) or a tooth
## (0.75): a tapered rod from base along d. Its colour: r its way along, g
## its kind, b a phase; its custom: its direction, its length.
static func _spine(st: SurfaceTool, base: Vector3, d: Vector3, ln: float, rad: float, kind: float, ph: float, sides: int) -> void:
	var a := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	var b := d.cross(a)
	var ts: Array = [0.0, 0.5, 1.0] if kind != 0.5 else [0.0, 0.45, 0.88, 0.94, 1.0]
	var rs: Array = [rad, rad * 0.62, 0.0] if kind != 0.5 else [rad, rad, rad * 0.9, rad * 1.8, 0.0]
	var cu := Color(d.x, d.y, d.z, ln)
	for r in ts.size() - 1:
		for s in sides:
			var q := []
			for e: Vector2i in [Vector2i(r, s), Vector2i(r + 1, s), Vector2i(r + 1, s + 1), Vector2i(r, s + 1)]:
				var ang := TAU * float(e.y) / sides
				var off := (a * cos(ang) + b * sin(ang))
				var t: float = ts[e.x]
				var p := base + d * ln * t + off * float(rs[e.x])
				var nn := (off + d * 0.15).normalized() if float(rs[e.x]) > 0.0 else d
				q.append([p, nn, t])
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for k: int in tri:
					_v(st, q[k][0], q[k][1], Color(q[k][2], kind, ph, 1.0), cu)
