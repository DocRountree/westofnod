class_name SandDollar
extends "res://scripts/creatures/creature.gd"
## An eccentric sand dollar (Dendraster excentricus), life size: a thin
## disc some 8 cm across, a little domed, alive velvet with its tiny
## spines, purple brown to grey; on its top five petals (the rows of pores
## its gill feet breathe through) set off its middle toward its back;
## beneath, its mouth in the middle and its food grooves branching out to
## the rim. Dead, its test bleached white (the one found on beaches).
## shaders/render/sand_dollar.gdshader.
##
## They live in beds on sand, many together (Species "herd").
## - wander(): ploughing slowly through the sand's top, half under it, on
##   its spines.
## - feed(): stood up on its edge, its front third in the sand, slanted
##   across the current (all of a bed the same way), its spines and tube
##   feet catching what drifts by and passing it to its mouth; in still
##   water, flat, picking over the sand.
## - burrow(): under the sand's top, flush with it (from waves, from what
##   eats it: here, its rest).
## - spawn(): a plume from the five pores on its top (hers eggs, his milt);
##   those near spawning with it (mate(partner): to one, together).
## Its life: eggs, fertilized in the water -> echinoplutei in the plankton
## (Plankton "pluteus") -> settled, tiny, pale -> grown. die(): its spines
## gone, its test bleached, left lying a while.

const R := 0.04 ## m: its radius
const CURRENT_YAW := 0.6 ## (the way the current goes here: a bed stands across it)

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
var _mode := "wander"
var _t := 0.0
var _until := 30.0
var _dir := Vector3.FORWARD
var _goal := Vector3.INF
var _pace := -1.0
var _partner: Node3D
var _plume: CPUParticles3D
var _tilt := 0.0
var _sink := 0.0
var _dead_t := 0.0
var _mi: MeshInstance3D

static var _mesh: ArrayMesh
static var _mat: ShaderMaterial


func _init(young_ := false) -> void:
	young = young_
	male = randf() < 0.5
	_mi = MeshInstance3D.new()
	_mi.mesh = mesh()
	_mi.material_override = material()
	add_child(_mi)
	_mi.set_instance_shader_parameter("seed", randf())
	if young:
		size = randf_range(0.1, 0.4)
		_mi.set_instance_shader_parameter("juvenile", 1.0 - size)
	scale = Vector3.ONE * size
	_yaw = randf() * TAU
	_dir = Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func _p_behaviours() -> PackedStringArray:
	var out := PackedStringArray(["wander", "feed", "burrow"])
	if not young:
		out.append_array(PackedStringArray(["spawn", "mate"]))
	return out


func place(at: Vector3, yaw := 0.0) -> void:
	_pos = at
	_pos.y = _bottom(at)
	_yaw = yaw
	if _home == Vector3.INF:
		_home = _pos
	_apply()


func where() -> Vector3:
	return _pos


func _bottom(p: Vector3) -> float:
	if height.is_valid():
		return float(height.call(p.x, p.z))
	return floor_y if floor_y != 0.0 or p.y == 0.0 else p.y


## (centre: the sandbox's, a place to go about near, its home from now.)
func wander(centre: Variant = null, _radius := -1.0) -> void:
	if centre is Vector3:
		_home = centre
	_to("wander", randf_range(30.0, 60.0))


func feed(secs := -1.0) -> void:
	_to("feed", secs if secs > 0.0 else randf_range(60.0, 120.0))


func burrow(secs := -1.0) -> void:
	_to("burrow", secs if secs > 0.0 else randf_range(40.0, 80.0))


func spawn(with_others := true) -> void:
	if young or dead:
		return
	_to("spawn", 15.0)
	if with_others:
		for o: Node in Fauna.near(get_parent(), _pos, 2.0):
			if o != self and o is SandDollar and not o.young and o.get("_mode") != "spawn":
				o.call("spawn", false)
	if _plume == null:
		_plume = Plankton.plume(not male, 80)
		_plume.position = Vector3(0.0, 0.008, 0.009)
		add_child(_plume)
	_plume.emitting = true
	if not male and not has_meta("sim"): # (left to itself: her eggs, if he's spawning near, to the plankton)
		for o: Node in Fauna.near(get_parent(), _pos, 3.0):
			if o is SandDollar and o.male and o.get("_mode") == "spawn":
				var pl: Plankton = Plankton.new("pluteus", 50)
				pl.young_script = (get_script() as Script).resource_path
				get_parent().add_child(pl)
				pl.position = _pos + Vector3(0.0, 0.2, 0.0)
				pl.set_water(_bottom(_pos), water_y if water_y < INF else _pos.y + 1.5)
				break


func mate(partner: Node3D, _secs := -1.0) -> bool:
	if young or dead or partner == null or not is_instance_valid(partner):
		return false
	_partner = partner
	_to("court", 300.0)
	return true


func is_mating() -> bool:
	return _mode in ["court", "spawn"]


func die() -> void:
	if dead:
		return
	dead = true
	_to("dead", 1e9)
	_mi.set_instance_shader_parameter("dead", 1.0)


func _to(m: String, secs: float) -> void:
	if dead and m != "dead":
		return
	if _plume and m != "spawn":
		_plume.emitting = false
	_mode = m
	_t = 0.0
	_until = secs


# --- steering (pilot.gd) --------------------------------------------------------------------

func is_busy() -> bool:
	return _mode in ["spawn", "court"] or (_pilot != null and _pilot.busy())


func _p_here() -> Vector3:
	return _pos


func _p_heading() -> Vector3:
	return _dir


func _p_steer(point: Vector3, speed: float) -> void:
	_goal = point
	_pace = speed
	_to("piloted", 1e9)


func _p_hold() -> void:
	_goal = _pos
	_to("piloted", 1e9)


func _p_mobile() -> bool:
	return not dead and not has_meta("taken")


func _p_speed() -> float:
	return 0.004 * maxf(size, 0.4)


func _p_reach() -> float:
	return 0.03


func _p_act(name: String, args: Dictionary) -> bool:
	if dead:
		return false
	var secs := float(args.get("seconds", -1.0))
	match name:
		"wander":
			wander()
		"feed":
			feed(secs)
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
			return _mode != "feed"
		"burrow":
			return _mode != "burrow"
		"spawn":
			return _mode != "spawn"
	return true


# --- its frame ----------------------------------------------------------------------------------

func tick(dt: float) -> void:
	dt = minf(dt, 0.5)
	if _home == Vector3.INF:
		_home = _pos
	_t += dt
	if _pilot and not dead:
		_pilot.tick(dt)
	var tilt := 0.0
	var sink := 0.0015 # (its underside a little in the sand)
	var stir := 0.3
	var sp := _p_speed()
	match _mode:
		"wander":
			_dir = _dir.rotated(Vector3.UP, randf_range(-0.2, 0.2) * dt)
			var off := _pos - _home
			off.y = 0.0
			if off.length() > 0.8:
				_dir = _dir.lerp(-off.normalized(), clampf(dt * 0.5, 0.0, 1.0)).normalized()
			_move(_dir, sp, dt)
			sink = 0.003
			stir = 1.0
			if _t > _until and not piloted():
				feed()
		"piloted":
			var to := _goal - _pos
			to.y = 0.0
			if to.length() > 0.003:
				_dir = to.normalized()
				_move(_dir, minf((_pace if _pace > 0.0 else sp), to.length() / maxf(dt, 1e-4)), dt)
				stir = 1.0
			sink = 0.003
		"feed": # (up on its edge, across the current)
			tilt = 1.05
			sink = R * 0.55
			stir = 0.6
			_yaw = lerp_angle(_yaw, CURRENT_YAW + (float(get_instance_id() % 7) - 3.0) * 0.04, 1.0 - exp(-dt))
			if _t > _until and not piloted():
				burrow()
		"burrow": # (its rim and its top just showing through the sand)
			sink = 0.0045
			stir = 0.1
			if _t > _until and not piloted():
				wander()
		"spawn":
			stir = 0.5
			if _t > _until:
				_to("burrow" if not piloted() else "idle", 40.0)
		"court":
			if not is_instance_valid(_partner):
				_to("idle", 1e9)
			else:
				var to := Diet._at(_partner) - _pos
				to.y = 0.0
				if to.length() < 0.6: # (near enough: what they spawn drifts, and meets)
					spawn(false)
					if _partner.has_method("spawn"):
						_partner.call("spawn", false)
				else:
					_dir = to.normalized()
					_move(_dir, sp, dt)
		"dead":
			stir = 0.0
			sink = 0.0
			_dead_t += dt
			if _dead_t > 600.0:
				queue_free()
				return
	var k := 1.0 - exp(-0.8 * dt)
	_tilt = lerpf(_tilt, tilt, k)
	_sink = lerpf(_sink, sink, k)
	if seen:
		_mi.set_instance_shader_parameter("stir", stir)
	_apply()


func _move(dir: Vector3, speed: float, dt: float) -> void:
	var p := _pos + dir * speed * dt
	p.y = _bottom(p)
	_pos = p


func _apply() -> void:
	position = _pos + Vector3(0.0, (-_sink + sin(_tilt) * R * 0.95) * size, 0.0)
	rotation = Vector3(0.0, _yaw, 0.0)
	_mi.rotation = Vector3(_tilt, 0.0, 0.0) # (its front edge down into the sand)


# --- its mesh -----------------------------------------------------------------------------------

static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/render/sand_dollar.gdshader")
	return _mat


static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var NR := 16
	var NA := 64
	for top in [true, false]:
		var grid := []
		for i in NR + 1:
			var f := float(i) / NR
			var row := []
			for j in NA + 1:
				var a := TAU * float(j) / NA
				var dx := sin(a)
				var dz := -cos(a)
				var r := f * R
				var y: float
				var n: Vector3
				if top: # (a low dome, thin to its rim)
					y = 0.0012 + 0.0048 * pow(maxf(1.0 - f * f, 0.0), 0.8)
					var slope := 0.0048 * 0.8 * pow(maxf(1.0 - f * f, 0.001), -0.2) * 2.0 * f / R
					n = Vector3(dx * slope, 1.0, dz * slope).normalized()
				else:
					y = 0.0004 + 0.0006 * (1.0 - f * f)
					n = Vector3.DOWN
				row.append([Vector3(dx * r, y, dz * r), n, Vector2(dx * f, dz * f), 1.0 if top else 0.0])
			grid.append(row)
		for i in NR:
			for j in NA:
				var q: Array = [grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]
				var order: Array = [0, 1, 2, 0, 2, 3] if top else [0, 2, 1, 0, 3, 2]
				for k: int in order:
					var e: Array = q[k]
					st.set_normal(e[1])
					st.set_uv(e[2])
					st.set_color(Color(float(e[3]), 0.0, 0.0, 1.0))
					st.add_vertex(e[0])
	# its rim: round from top to bottom
	for j in NA:
		var a0 := TAU * float(j) / NA
		var a1 := TAU * float(j + 1) / NA
		var p := []
		for a: float in [a0, a1]:
			var d := Vector3(sin(a), 0.0, -cos(a))
			p.append([d * R + Vector3(0.0, 0.0012, 0.0), d * R + Vector3(0.0, 0.0004, 0.0), d, Vector2(d.x, d.z)])
		var quad: Array = [[p[0][0], p[0][2], p[0][3]], [p[1][0], p[1][2], p[1][3]], [p[1][1], p[1][2], p[1][3]], [p[0][1], p[0][2], p[0][3]]]
		for k: int in [0, 1, 2, 0, 2, 3]:
			st.set_normal(quad[k][1])
			st.set_uv(quad[k][2])
			st.set_color(Color(1.0, 0.0, 0.0, 1.0))
			st.add_vertex(quad[k][0])
	_mesh = st.commit()
	return _mesh
