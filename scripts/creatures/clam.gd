class_name Clam
extends "res://scripts/creatures/creature.gd"
## A Pacific littleneck clam (Leukoma staminea), life size: its shell some
## 5.5 cm long, oval, the beaks a little forward of the middle, sculptured
## with concentric ridges crossed by fine radial ribs (finely latticed),
## cream to grey brown, mottled and zigzagged in brown, each its own; white
## inside, its two muscle scars and its pallial line; its siphons short,
## fused, buff flecked with brown, two openings at their tip, the incurrent
## fringed with little tentacles; its foot a pale tongue. One mesh (cached),
## posed in shaders/render/clam.gdshader: its valves gaping on their hinge,
## its foot out, its siphons out to the sand's top or drawn in, its flesh as
## much of it as is left.
##
## Its life is under the sand, a few cm down, standing on end, its siphons
## up to the top. What it does:
## - feed(): its siphons out, their tips just above the sand, drawing water
##   in by the incurrent (what drifts in it drawn in with it: specks going
##   in), out by the excurrent: filtering it.
## - shut(): something near (a shadow, a footfall, a hunter digging): its
##   siphons snapped in, a spurt of water and sand out of its hole (its
##   "show"), its valves shut; a while, then out again.
## - burrow(): turned up on its edge, its foot out and down into the sand,
##   swelling to anchor, the shell pulled down after it, rocking, a step at
##   a time, till it's at its depth (dug up, or a newly settled spat). Its
##   rest: a little deeper, siphons in.
## - spawn(): out of its excurrent siphon, a plume (hers eggs, his milt); those
##   of its kind near spawning with it (mate(partner)).
## Taken (a sea otter's, its meta "taken"; an octopus's, a sea star's,
## "hunted"): out of the sand, lying, shut tight; what takes it moves it.
## crack(by): forced open (killed: Meal.subdue); consume(k): its flesh eaten
## so far; emptied(): an empty shell (meta "empty_shell", no longer
## "shellfish"), fading, gone in a while. die(): its valves gape, its flesh
## going, then an empty shell.
## Its life: spawned eggs, fertilized in the water -> trochophore, then
## veliger (a tiny shell, swimming on its ciliated velum) in the plankton
## (Plankton "veliger") -> settled, a spat a few mm long, digging in ->
## growing.

const L := 0.055 ## m: its length
const H := 0.046 ## m: its height (beak to margin)
const W := 0.012 ## m: a valve's swell
const HINGE_Y := 0.022
const SIPHON_REF := 0.02 ## m: its siphons as made
const SIPHON_BASE := Vector3(0.43 * L, 0.06 * L, 0.0)
const SIPHON_DIR := Vector3(0.93, 0.37, 0.0) # (normalized below)
const DEPTH := 0.045 ## m: its middle under the sand, grown
const UMBO := Vector2(-0.08 * L, 0.42 * H)

var young := false
var male := false
var dead := false
var size := 1.0
var height: Callable
var floor_y := 0.0
var water_y := INF

var _pos := Vector3.ZERO
var _yaw := 0.0
var _home := Vector3.INF
var _mode := "feed"
var _t := 0.0
var _until := 60.0
var _depth := DEPTH # (its middle under the sand: 0 lying on top)
var _up := 1.0 # (1 on end, as it lives; 0 lying on its side)
var _gape := 0.0
var _flesh := 1.0
var _foot := 0.0
var _siphon := 0.0
var _bleach := 0.0
var _check := 0.0
var _partner: Node3D
var _plume: CPUParticles3D
var _specks: CPUParticles3D
var _dead_t := 0.0
var _cracked := false
var _goal := Vector3.INF
var _pace := -1.0
var _body: Node3D
var _mi: MeshInstance3D
var _show: MeshInstance3D

static var _mesh: ArrayMesh
static var _mat: ShaderMaterial
static var _show_mesh: Mesh


func _init(young_ := false) -> void:
	young = young_
	male = randf() < 0.5
	set_meta("shellfish", "clam")
	_body = Node3D.new()
	add_child(_body)
	_mi = MeshInstance3D.new()
	_mi.mesh = mesh()
	_mi.material_override = material()
	_body.add_child(_mi)
	_mi.set_instance_shader_parameter("seed", randf())
	_mi.set_instance_shader_parameter("tone", randf_range(0.15, 0.85))
	_show = MeshInstance3D.new() # (its show: the hole its siphons come up through, in the sand's top)
	_show.mesh = show_mesh()
	_show.position.y = 0.0006
	add_child(_show)
	if young:
		size = randf_range(0.1, 0.35)
	_mi.scale = Vector3.ONE * size
	_depth = DEPTH * size
	_yaw = randf() * TAU


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func _p_behaviours() -> PackedStringArray:
	var out := PackedStringArray(["feed", "shut", "burrow"])
	if not young:
		out.append_array(PackedStringArray(["spawn", "mate"]))
	return out


## Placed at `at` (its burrow there, at its depth: dug in).
func place(at: Vector3, yaw := 0.0) -> void:
	_pos = at
	_pos.y = _bottom(at)
	_yaw = yaw
	if _home == Vector3.INF:
		_home = _pos
	_apply()


## Put lying on the sand's top, not dug in (it digs itself in).
func lay_out() -> void:
	_depth = 0.0
	_up = 0.0
	_to("burrow", 1e9)


func where() -> Vector3:
	return _pos


func _bottom(p: Vector3) -> float:
	if height.is_valid():
		return float(height.call(p.x, p.z))
	return floor_y if floor_y != 0.0 or p.y == 0.0 else p.y


# --- what it does -----------------------------------------------------------------------

func feed(secs := -1.0) -> void:
	_to("feed" if _depth >= _deep() * 0.9 else "burrow", secs if secs > 0.0 else randf_range(60.0, 180.0))


func shut(secs := -1.0) -> void:
	if dead:
		return
	if _mode != "shut" and _siphon > 0.004: # (a spurt out of its show)
		_spurt()
	_to("shut", secs if secs > 0.0 else randf_range(6.0, 15.0))


## (Dug in already: its rest, a little deeper, siphons in, a while.)
func burrow(secs := -1.0) -> void:
	if _depth >= _deep() * 0.9:
		_to("rest", secs if secs > 0.0 else randf_range(30.0, 90.0))
	else:
		_to("burrow", secs if secs > 0.0 else 60.0)


func spawn(with_others := true) -> void:
	if young or dead:
		return
	_to("spawn", 15.0)
	if with_others:
		for o: Node in Fauna.near(get_parent(), _pos, 2.0):
			if o != self and o is Clam and not o.young and not o.dead and o.get("_mode") != "spawn":
				o.call("spawn", false)
	if _plume == null:
		_plume = Plankton.plume(not male, 60)
		_plume.scale = Vector3.ONE * 0.6
		_plume.position = Vector3(0.0, 0.006, 0.0)
		add_child(_plume)
	_plume.emitting = true
	if not male and not has_meta("sim"): # (left to itself: her eggs, if one of his kind's spawning near, to the plankton)
		for o: Node in Fauna.near(get_parent(), _pos, 3.0):
			if o is Clam and o.male and o.get("_mode") == "spawn":
				var pl: Plankton = Plankton.new("veliger", 50)
				pl.young_script = (get_script() as Script).resource_path
				get_parent().add_child(pl)
				pl.position = _pos + Vector3(0.0, 0.2, 0.0)
				pl.set_water(_bottom(_pos), water_y if water_y < INF else _pos.y + 1.5)
				break


func mate(partner: Node3D, _secs := -1.0) -> bool:
	if young or dead or partner == null or not is_instance_valid(partner):
		return false
	_partner = partner
	spawn(false)
	if partner.has_method("spawn"):
		partner.call("spawn", false)
	return true


func is_mating() -> bool:
	return _mode == "spawn"


## Forced open by what eats it (killed): its valves apart, its flesh there.
func crack(by: Node = null) -> void:
	if not dead:
		Meal.subdue(self, by)
		set_process(true) # (its valves gaping, its flesh going: still its own to show)
	dead = true
	_cracked = true
	_to("dead", 1e9)


## Its flesh eaten, so far (0 .. 1: all of it).
func consume(k: float) -> void:
	_flesh = minf(_flesh, 1.0 - clampf(k, 0.0, 1.0))


## An empty shell: nothing of it left to eat.
func emptied() -> void:
	if not dead:
		Meal.subdue(self)
		set_process(true)
	dead = true
	_flesh = 0.0
	_cracked = true
	remove_meta("shellfish")
	remove_meta("hunted")
	set_meta("empty_shell", true)
	_to("dead", 1e9)


func die() -> void:
	if dead:
		return
	dead = true
	_to("dead", 1e9)


func _to(m: String, secs: float) -> void:
	if dead and m != "dead":
		return
	if _plume and m != "spawn":
		_plume.emitting = false
	_mode = m
	_t = 0.0
	_until = secs


func _deep() -> float:
	return DEPTH * maxf(size, 0.3)


## (A spurt of water and sand up out of its show.)
func _spurt() -> void:
	if get_parent() == null or not seen:
		return
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 1.6
	p.one_shot = true
	p.explosiveness = 0.95
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.15
	p.initial_velocity_max = 0.35
	p.gravity = Vector3(0.0, -0.35, 0.0)
	p.damping_min = 0.3
	p.damping_max = 0.6
	var q := QuadMesh.new()
	q.size = Vector2.ONE * 0.004
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.72, 0.66, 0.55)
	q.material = m
	p.mesh = q
	get_parent().add_child(p)
	p.position = _pos + Vector3(0.0, 0.003, 0.0)
	p.emitting = true
	p.finished.connect(p.queue_free)


## (What it draws in as it feeds: specks going in at its incurrent.)
func _feeding_specks(on: bool) -> void:
	if on and _specks == null and seen:
		_specks = CPUParticles3D.new()
		_specks.amount = 8
		_specks.lifetime = 1.4
		_specks.local_coords = true
		_specks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
		_specks.emission_sphere_radius = 0.02
		_specks.direction = Vector3.ZERO
		_specks.spread = 180.0
		_specks.initial_velocity_min = 0.0
		_specks.initial_velocity_max = 0.0
		_specks.gravity = Vector3.ZERO
		_specks.radial_accel_min = -0.03 # (drawn in to the opening)
		_specks.radial_accel_max = -0.02
		var q := QuadMesh.new()
		q.size = Vector2.ONE * 0.0012
		var m := StandardMaterial3D.new()
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.8, 0.82, 0.7)
		q.material = m
		_specks.mesh = q
		_specks.position = Vector3(0.0, 0.008, 0.0)
		add_child(_specks)
	if _specks:
		_specks.emitting = on


# --- steering (pilot.gd) --------------------------------------------------------------------

func is_busy() -> bool:
	return _mode in ["spawn", "burrow", "piloted"] or (_pilot != null and _pilot.busy())


func _p_here() -> Vector3:
	return _pos


func _p_heading() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func _p_steer(point: Vector3, speed: float) -> void:
	_goal = point
	_pace = speed
	_to("piloted", 1e9)


func _p_hold() -> void:
	_goal = _pos
	if _mode == "piloted":
		_to("burrow", 1e9)


func _p_mobile() -> bool:
	return not dead and not has_meta("taken") and not has_meta("hunted")


func _p_speed() -> float:
	return 0.0015 * maxf(size, 0.4) # (out, ploughing along on its foot)


func _p_reach() -> float:
	return 0.02


func _p_act(name: String, args: Dictionary) -> bool:
	if dead:
		return false
	var secs := float(args.get("seconds", -1.0))
	match name:
		"feed":
			feed(secs)
		"shut":
			shut(secs)
		"burrow":
			burrow(secs)
		"spawn":
			spawn()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"feed":
			return _mode not in ["feed", "burrow"]
		"shut":
			return _mode != "shut"
		"burrow":
			return _mode not in ["burrow", "rest"]
		"spawn":
			return _mode != "spawn"
	return true


# --- its frame ----------------------------------------------------------------------------------

func tick(dt: float) -> void:
	dt = minf(dt, 0.5)
	if _home == Vector3.INF: # (put there, not placed: its burrow where it was put)
		_pos = position
		_yaw = rotation.y
		_home = _pos
	_t += dt
	if _pilot and not dead:
		_pilot.tick(dt)
	var held := has_meta("taken") or has_meta("hunted") or has_meta("sink")
	var moved := Vector2(position.x - _pos.x, position.z - _pos.z).length() > 0.03 # (taken up: what has it moves it)
	var gape := 0.03 # (just open, as it lives: its mantle edge between its valves)
	var foot := 0.0
	var siphon := 0.0
	var pulse := 0.0
	var feeding := false
	if dead:
		_dead_frame(dt)
		gape = 0.9 if _cracked else 0.45
		_up = lerpf(_up, 0.0, 1.0 - exp(-dt))
		_depth = lerpf(_depth, 0.0, 1.0 - exp(-dt))
	elif held:
		gape = 0.0 # (shut tight)
		if moved or has_meta("hunted"):
			_depth = 0.0
			_up = 0.0
	else:
		_check -= dt
		if _check <= 0.0 and _mode in ["feed", "spawn"]:
			_check = 0.6
			for o: Node in Fauna.near(get_parent(), _pos, 0.5): # (a shadow, a footfall: its siphons in)
				if o is Creature and not (o is Clam) and not (o is SandDollar) and o.get("dead") != true:
					var w: Vector3 = (o as Creature).where()
					if w.distance_to(_pos) < 0.35 + 0.1 * float(o.get("size") if o.get("size") is float else 1.0):
						shut()
						break
		match _mode:
			"feed":
				siphon = _reach_top()
				pulse = 0.5 + 0.5 * sin(_t * 1.7)
				gape = 0.05
				feeding = true
				if _t > _until and not piloted():
					_to("rest", randf_range(30.0, 90.0))
			"rest": # (a little deeper, siphons in)
				gape = 0.02
				_depth = lerpf(_depth, _deep() * 1.25, 1.0 - exp(-0.3 * dt))
				if _t > _until and not piloted():
					feed()
			"shut":
				gape = 0.0
				if _t > _until:
					if piloted():
						_to("idle", 1e9)
					else:
						feed()
			"spawn":
				siphon = _reach_top()
				gape = 0.06
				if _t > _until:
					_to("idle" if piloted() else "feed", 1e9 if piloted() else randf_range(60.0, 120.0))
			"burrow": # (up on its edge; its foot down, swelling, the shell pulled after it; a step at a time)
				var cyc := fmod(_t, 2.4) / 2.4
				_up = lerpf(_up, 1.0, 1.0 - exp(-1.5 * dt))
				foot = 1.0 - absf(cyc * 2.0 - 1.0)
				gape = 0.05 + 0.08 * foot
				if cyc > 0.55 and _up > 0.8: # (the foot anchored: pulled down, its valves rocking)
					_depth = minf(_depth + dt * 0.012 * maxf(size, 0.4), _deep())
				if _depth >= _deep() * 0.99:
					_to("feed" if not piloted() else "idle", randf_range(60.0, 180.0) if not piloted() else 1e9)
			"piloted": # (out of the sand, ploughing along on its foot)
				_depth = lerpf(_depth, 0.0, 1.0 - exp(-dt))
				_up = lerpf(_up, 0.6, 1.0 - exp(-dt))
				foot = 0.6 + 0.3 * sin(_t * 2.0)
				var to := _goal - _pos
				to.y = 0.0
				if to.length() > 0.005:
					var p := _pos + to.normalized() * minf((_pace if _pace > 0.0 else _p_speed()) * dt, to.length())
					p.y = _bottom(p)
					_pos = p
			"idle":
				siphon = _reach_top() if _depth > _deep() * 0.8 else 0.0
				feeding = siphon > 0.0
	var k := 1.0 - exp(-(8.0 if _mode == "shut" else 2.0) * dt) # (in fast; out slow)
	_gape = lerpf(_gape, gape, k)
	_foot = lerpf(_foot, foot, 1.0 - exp(-3.0 * dt))
	_siphon = lerpf(_siphon, siphon, k)
	_feeding_specks(feeding and _siphon > 0.004 and seen)
	if seen:
		_mi.set_instance_shader_parameter("gape", _gape)
		_mi.set_instance_shader_parameter("flesh", _flesh)
		_mi.set_instance_shader_parameter("foot", _foot)
		_mi.set_instance_shader_parameter("siphon", _siphon / maxf(size, 0.01))
		_mi.set_instance_shader_parameter("pulse", pulse)
		_mi.set_instance_shader_parameter("bleach", _bleach)
	_show.visible = not dead and not held and _depth > _deep() * 0.5
	if (held and moved) or dead:
		_pos = position # (where it's been taken, or thrown: what had it, its place)
	if not held and not dead:
		_apply()
	else:
		_pose_body()


## (Its siphons' length to just above the sand's top, standing on end at its depth.)
func _reach_top() -> float:
	var r := _bury_rot()
	var base_up := (SIPHON_BASE.x * sin(r) + SIPHON_BASE.y * cos(r)) * size
	return maxf(_depth - base_up + 0.003, 0.0)


func _bury_rot() -> float:
	var d := SIPHON_DIR.normalized()
	return PI * 0.5 - atan2(d.y, d.x) # (on end: its siphons straight up)


func _dead_frame(dt: float) -> void:
	if not _cracked:
		_flesh = maxf(_flesh - dt / 300.0, 0.0) # (rotting, picked at: gone in a while)
		if _flesh <= 0.0 and has_meta("shellfish"):
			emptied()
	if not has_meta("shellfish"):
		_bleach = minf(_bleach + dt / 600.0, 1.0)
	if has_meta("taken") or has_meta("sink") or has_meta("hunted"):
		_dead_t = 0.0
		return
	_dead_t += dt
	if _dead_t > 900.0 and not has_meta("shellfish"):
		queue_free()


func _apply() -> void:
	position = _pos
	rotation = Vector3(0.0, _yaw, 0.0)
	_pose_body()


## (Its shell: on end at its depth, or lying on its side on the sand.)
func _pose_body() -> void:
	var lie := Basis(Vector3.RIGHT, PI * 0.5) # (on its side: a valve up)
	var stand := Basis(Vector3.BACK, _bury_rot())
	var b := lie.slerp(stand, clampf(_up, 0.0, 1.0)) if _up < 0.999 else stand
	if _mode == "burrow" and not dead: # (rocking as it pulls down)
		b = b * Basis(Vector3.RIGHT, 0.12 * sin(_t * 2.6) * _foot)
	var lying := (W + 0.9 * H * sin(_gape * 0.5)) * size # (on its side: on its lower valve, swung down as it gapes)
	_body.transform = Transform3D(b, Vector3(0.0, -_depth + lying * (1.0 - _up), 0.0))


# --- its mesh -----------------------------------------------------------------------------------

static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/render/clam.gdshader")
		_mat.set_shader_parameter("L", L)
		_mat.set_shader_parameter("hinge_y", HINGE_Y)
		_mat.set_shader_parameter("siphon_ref", SIPHON_REF)
		_mat.set_shader_parameter("siphon_base", SIPHON_BASE)
	return _mat


static func show_mesh() -> Mesh:
	if _show_mesh == null:
		var c := CylinderMesh.new()
		c.top_radius = 0.0035
		c.bottom_radius = 0.0045
		c.height = 0.0008
		c.radial_segments = 10
		c.rings = 1
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.16, 0.13, 0.1)
		m.roughness = 1.0
		c.material = m
		_show_mesh = c
	return _show_mesh


## Its valve's outline at angle th round its middle (x along it, y up: its back).
static func _outline(th: float) -> Vector2:
	var p := Vector2(cos(th) * L * 0.5, sin(th) * H * 0.5)
	if p.x > 0.0: # (its back end a little squared off)
		p.x *= 1.0 - 0.07 * pow(maxf(cos(th), 0.0), 6.0)
	if p.y > 0.0: # (its back rising to the beaks, forward of the middle)
		p.y += 0.04 * H * exp(-pow((th - 1.75) / 0.5, 2.0))
	return p


## A point of a valve: s out from the beak (0..1), u round (0..1); side its
## valve (+1 right, -1 left); inner: its inside face.
static func _valve_pt(s: float, u: float, side: float, inner: bool) -> Vector3:
	var th := PI * 0.5 + 0.12 + u * (TAU - 0.24) # (from just behind its beak round to just before)
	var o := _outline(th)
	var p := UMBO.lerp(o, s)
	var w := W * pow(maxf(1.0 - pow(s, 2.3), 0.0), 0.55) * (1.0 + 0.25 * (1.0 - s))
	if inner:
		w = maxf(w - 0.0016 * (1.0 - pow(s, 6.0)), 0.0) * 0.92
	return Vector3(p.x, p.y, side * w)


static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var NS := 18
	var NU := 44
	for side: float in [-1.0, 1.0]:
		for inner in [false, true]:
			var grid := []
			for i in NS + 1:
				var s := float(i) / NS
				var row := []
				for j in NU + 1:
					row.append(_valve_pt(s, float(j) / NU, side, inner))
				grid.append(row)
			for i in NS:
				for j in NU:
					var quad := [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
					var order: Array = [0, 1, 2, 0, 2, 3]
					if (side > 0.0) == inner:
						order = [0, 2, 1, 0, 3, 2]
					for k: int in order:
						var a: int = quad[k][0]
						var b: int = quad[k][1]
						var p: Vector3 = grid[a][b]
						var pa: Vector3 = grid[mini(a + 1, NS)][b] - grid[maxi(a - 1, 0)][b]
						var pb: Vector3 = grid[a][mini(b + 1, NU)] - grid[a][maxi(b - 1, 0)]
						var n := pa.cross(pb).normalized()
						if n.z * side < 0.0 != inner:
							n = -n
						if n == Vector3.ZERO:
							n = Vector3(0.0, 0.0, side)
						st.set_normal(n)
						st.set_uv(Vector2(float(a) / NS, float(b) / NU))
						st.set_color(Color(0.25 if inner else 0.0, 0.5 + 0.5 * side, 0.0, 1.0))
						st.set_custom(0, Color(0.0, 0.0, 0.0, 0.0))
						st.add_vertex(p)
	# its flesh: its mantle and body, between the valves
	_blob(st, Vector3(0.0, -0.02 * H, 0.0), Vector3(L * 0.34, H * 0.28, W * 0.7), Color(0.5, 0.5, 0.0, 1.0), Color(0, 0, 0, 0))
	# its foot: a tongue out from under its front
	var fd := Vector3(-0.45, -1.0, 0.0).normalized()
	var fb := Vector3(-0.22 * L, -0.3 * H, 0.0)
	var NF := 6
	for i in NF:
		for j in 8:
			var q := []
			for e: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var t := float(e.x) / NF
				var an := TAU * float(e.y) / 8.0
				var side := fd.cross(Vector3.BACK).normalized()
				var r := 0.006 * sin(PI * minf(t * 0.85 + 0.15, 1.0)) + 0.001
				var off := (side * cos(an) * 1.4 + Vector3.BACK * sin(an) * 0.6) * r
				q.append([fb + off, off.normalized(), t])
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.set_normal(q[k][1])
				st.set_uv(Vector2(float(q[k][2]), 0.0))
				st.set_color(Color(0.75, 0.5, 0.0, 1.0))
				st.set_custom(0, Color(float(q[k][2]), fd.x, fd.y, fd.z))
				st.add_vertex(q[k][0])
	# its siphons: fused, two openings at the tip; the incurrent's fringe of tentacles
	var sd := SIPHON_DIR.normalized()
	var sx := Vector3.BACK
	var sy := sd.cross(sx).normalized()
	var NSI := 8
	for i in NSI:
		for j in 12:
			var q := []
			for e: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var t := float(e.x) / NSI
				var an := TAU * float(e.y) / 12.0
				var off := (sx * cos(an) * 1.5 + sy * sin(an)) * 0.0042 * (1.0 - 0.15 * t)
				q.append([SIPHON_BASE + sd * t * SIPHON_REF + off, off.normalized(), t, float(e.y) / 12.0])
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.set_normal(q[k][1])
				st.set_uv(Vector2(float(q[k][2]), float(q[k][3])))
				st.set_color(Color(1.0, 0.5, 0.0, 1.0))
				st.set_custom(0, Color(float(q[k][2]), sd.x, sd.y, sd.z))
				st.add_vertex(q[k][0])
	var tip := SIPHON_BASE + sd * SIPHON_REF
	for hole: float in [-1.0, 1.0]: # (its two openings: a dark cup each)
		var hc := tip + sx * hole * 0.0028
		for j in 10:
			var a0 := TAU * float(j) / 10.0
			var a1 := TAU * float(j + 1) / 10.0
			for v: Vector3 in [hc - sd * 0.002, hc + (sx * cos(a0) + sy * sin(a0)) * 0.0018, hc + (sx * cos(a1) + sy * sin(a1)) * 0.0018]:
				st.set_normal(sd)
				st.set_uv(Vector2(1.0, 0.0))
				st.set_color(Color(1.0, 0.5, 0.0, 1.0))
				st.set_custom(0, Color(1.0, sd.x, sd.y, sd.z))
				st.add_vertex(v)
	for j in 10: # (the incurrent's tentacles)
		var an := TAU * float(j) / 10.0
		var b := tip + sx * 0.0028 + (sx * cos(an) + sy * sin(an)) * 0.0019
		var out := (sd + (sx * cos(an) + sy * sin(an)) * 0.6).normalized()
		var w := sx.cross(out).normalized() * 0.0004
		for v: Array in [[b - w, 0.0], [b + out * 0.003, 1.0], [b + w, 0.0]]:
			st.set_normal(out)
			st.set_uv(Vector2(float(v[1]), float(j) / 10.0))
			st.set_color(Color(0.9, 0.5, 0.0, 1.0))
			st.set_custom(0, Color(1.0, sd.x, sd.y, sd.z))
			st.add_vertex(v[0])
	_mesh = st.commit()
	_mesh.custom_aabb = AABB(Vector3(-0.08, -0.08, -0.04), Vector3(0.16, 0.25, 0.08))
	return _mesh


static func _blob(st: SurfaceTool, c: Vector3, r: Vector3, col: Color, cu: Color) -> void:
	for i in 6:
		for j in 10:
			var q := []
			for e: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var ph := PI * float(e.x) / 6.0
				var th := TAU * float(e.y) / 10.0
				var n := Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th))
				q.append([c + n * r, n, float(e.x) / 6.0])
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.set_normal(q[k][1])
				st.set_uv(Vector2(1.0 - absf(float(q[k][2]) - 0.5) * 2.0, 0.0))
				st.set_color(col)
				st.set_custom(0, cu)
				st.add_vertex(q[k][0])
