class_name OchreSeaStar
extends "res://scripts/creatures/creature.gd"
## An ochre sea star (Pisaster ochraceus), life size: five stout arms from a
## thick disc, some 25 cm across; orange, or purple, or brown (a morph each);
## its top rough with short white spines set in a net of lines and rings,
## the madreporite (its water intake's sieve) a pale spot off the middle,
## a red eyespot at each arm's tip; beneath, a groove down each arm packed
## with tube feet, each with its sucker. One mesh (cached), posed by
## shaders/render/sea_star.gdshader: its arms bent each its own way, its
## disc humped, its feet stepping in waves or drawn in.
##
## What it does:
## - wander(): creeping over the bottom on its tube feet (a few cm a minute
##   in life; faster here, to be seen), the arm it's going toward leading,
##   its tip raised a little (its eyespot, its feet there feeling).
## - eat(food): to a clam (or an urchin) and humped over it, its arms round
##   it, its feet pulling the valves apart, its stomach put out through its
##   mouth into the gap: a long meal. The shell's left, empty.
## - rest(): still, its feet drawn in, its arms low.
## - spawn(): up on its arm tips, its disc raised, a plume from the pores
##   between its arms (hers orange eggs, his white milt); those of its kind
##   near spawning with it (mate(partner): to one, and spawning together).
## Its life: spawned eggs, fertilized in the water -> bipinnaria, then
## brachiolaria, in the plankton (Plankton "sea_star") -> settled, a tiny
## star -> growing. die(): limp, grey, gone in a while.

const R := 0.12 ## m: its middle to an arm's tip
const RD := 0.03 ## m: its disc's radius
const LIFT := 0.008 ## m: held up on its tube feet
const MORPHS := [[0.55, Color(0.36, 0.11, 0.28)], [0.33, Color(0.88, 0.47, 0.12)], [0.12, Color(0.5, 0.27, 0.14)]] # (purple, orange, brown: how many of each)

var young := false
var male := false
var dead := false
var size := 1.0
var height: Callable
var floor_y := 0.0
var water_y := INF
var food: Node3D

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
var _dead_t := 0.0
var _last := Vector3.ZERO
var _look := {"hump": 0.0, "feet": 0.5, "stride": 1.0, "dead": 0.0, "lift": 0.0}
var _arms: Array[Vector4] = [Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO]
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
	var r := randf()
	var col: Color = MORPHS[0][1]
	for m: Array in MORPHS:
		r -= float(m[0])
		if r <= 0.0:
			col = m[1]
			break
	_mi.set_instance_shader_parameter("body_col", col * randf_range(0.9, 1.1))
	_mi.set_instance_shader_parameter("seed", randf())
	if young:
		size = randf_range(0.08, 0.35)
	scale = Vector3.ONE * size
	_yaw = randf() * TAU
	_dir = Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func _p_behaviours() -> PackedStringArray:
	var out := PackedStringArray(["wander", "eat", "rest"])
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
	_to("wander", randf_range(40.0, 90.0))


## To food (a clam, an urchin: given, or the nearest), and eaten.
func eat(what: Node3D = null, secs := -1.0) -> bool:
	food = what
	if food == null:
		food = _nearest_food(1.5)
	if food == null:
		return false
	food.set_meta("hunted", self)
	_to("seek", 240.0)
	_meal = secs if secs > 0.0 else randf_range(60.0, 120.0)
	return true


var _meal := 90.0


func rest(secs := -1.0) -> void:
	_to("rest", secs if secs > 0.0 else randf_range(40.0, 90.0))


func spawn(with_others := true) -> void:
	if young or dead:
		return
	_to("spawn", 20.0)
	if with_others: # (one spawning sets off those near it)
		for o: Node in Fauna.near(get_parent(), _pos, 2.5):
			if o != self and o is OchreSeaStar and not o.young and o.get("_mode") != "spawn":
				o.call("spawn", false)
	if _plume == null:
		_plume = Plankton.plume(not male, 120)
		_plume.position = Vector3(0.0, LIFT + 0.03, 0.0)
		add_child(_plume)
	_plume.emitting = true
	if not male and not has_meta("sim"): # (left to itself: her eggs, fertilized if one of his kind's spawning near, drift up, to grow in the plankton)
		var fert := false
		for o: Node in Fauna.near(get_parent(), _pos, 3.0):
			if o is OchreSeaStar and o.male and o.get("_mode") == "spawn":
				fert = true
		if fert:
			var pl: Plankton = Plankton.new("sea_star", 50)
			pl.young_script = (get_script() as Script).resource_path
			get_parent().add_child(pl)
			pl.position = _pos + Vector3(0.0, 0.2, 0.0)
			pl.set_water(_bottom(_pos), water_y if water_y < INF else _pos.y + 1.5)


func mate(partner: Node3D, _secs := -1.0) -> bool:
	if young or dead or partner == null or not is_instance_valid(partner):
		return false
	_partner = partner
	_to("court", 240.0)
	return true


func is_mating() -> bool:
	return _mode in ["court", "spawn"]


func die() -> void:
	if dead:
		return
	dead = true
	_to("dead", 1e9)
	_last = global_position


func _to(m: String, secs: float) -> void:
	if dead and m != "dead":
		return
	if _plume and m != "spawn":
		_plume.emitting = false
	_mode = m
	_t = 0.0
	_until = secs


func _nearest_food(r: float) -> Node3D:
	var f := Diet.find(self, r, ["clam", "urchin"])
	if f != null and f != self:
		return f
	for o: Node in Fauna.near(get_parent(), _pos, r): # (a live urchin, too)
		if o is SeaUrchin and not o.has_meta("hunted"):
			return o
	return null


# --- steering (pilot.gd) --------------------------------------------------------------------

func is_busy() -> bool:
	return _mode in ["seek", "eat", "spawn", "court"] or (_pilot != null and _pilot.busy())


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
	return 0.01 * maxf(size, 0.4)


func _p_reach() -> float:
	return 0.05 * maxf(size, 0.4)


func _p_act(name: String, args: Dictionary) -> bool:
	if dead:
		return false
	var secs := float(args.get("seconds", -1.0))
	match name:
		"wander":
			wander()
		"eat":
			args.erase("seconds") # (its creep there is slow: done when it's eaten, not before; secs its meal)
			var f: Variant = args.get("food", args.get("prey"))
			return eat(f if f is Node3D and f != self else null, secs)
		"rest":
			rest(secs)
		"spawn":
			spawn()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"eat":
			return _mode not in ["seek", "eat"]
		"rest":
			return _mode != "rest"
		"spawn":
			return _mode != "spawn"
	return true


func _p_act_secs(name: String) -> float:
	return -1.0


# --- its frame --------------------------------------------------------------------------------

func tick(dt: float) -> void:
	dt = minf(dt, 0.5)
	if _home == Vector3.INF:
		_home = _pos
	_t += dt
	if _pilot and not dead:
		_pilot.tick(dt)
	var sp := _p_speed()
	var moving := false
	match _mode:
		"wander":
			_dir = _dir.rotated(Vector3.UP, randf_range(-0.25, 0.25) * dt)
			var off := _pos - _home
			off.y = 0.0
			if off.length() > 1.5:
				_dir = _dir.lerp(-off.normalized(), clampf(dt * 0.5, 0.0, 1.0)).normalized()
			_move(_dir, sp * 0.7, dt)
			moving = true
			if _t > _until:
				if not piloted():
					if not eat():
						rest()
		"piloted":
			var to := _goal - _pos
			to.y = 0.0
			if to.length() > 0.005:
				_dir = _dir.lerp(to.normalized(), clampf(dt, 0.0, 1.0)).normalized()
				_move(to.normalized(), minf((_pace if _pace > 0.0 else sp), to.length() / maxf(dt, 1e-4)), dt)
				moving = true
		"seek":
			if not is_instance_valid(food):
				_to("wander", 30.0)
			else:
				var to := Diet._at(food) - _pos
				to.y = 0.0
				if to.length() < 0.02 * maxf(size, 0.5):
					_to("eat", _meal)
					if food is Clam: # (its valves pulled apart, its stomach put in: killed)
						food.call("crack", self)
					elif food is Creature:
						Meal.subdue(food, self) # (an urchin: its spines no help; held, digested where it is)
				else:
					_dir = _dir.lerp(to.normalized(), clampf(dt, 0.0, 1.0)).normalized()
					_move(to.normalized(), sp, dt)
					moving = true
		"eat": # (humped over it, its stomach out round it)
			if _t > _until:
				if is_instance_valid(food):
					if food is Clam:
						food.call("emptied")
					elif food is Creature:
						food.queue_free()
					else:
						food.remove_meta("shellfish")
						food.remove_meta("hunted")
						food.set_meta("empty_shell", true)
						food.rotation.x += 0.5 # (its valves gaping)
				food = null
				Fauna.report(&"ate", self, {"kind": "clam"})
				if not piloted():
					rest()
				else:
					_to("idle", 1e9)
		"rest":
			if _t > _until and not piloted():
				wander()
		"spawn":
			if _t > _until:
				_to("idle" if piloted() else "wander", 30.0)
		"court": # (to her, and spawning, the two together)
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
					_dir = _dir.lerp(to.normalized(), clampf(dt, 0.0, 1.0)).normalized()
					_move(to.normalized(), sp, dt)
					moving = true
		"idle":
			pass
		"dead":
			if global_position.distance_to(_last) > 0.01:
				_last = global_position
				_dead_t = 0.0
			else:
				_dead_t += dt
				if _dead_t > 240.0:
					queue_free()
					return
	_pose(dt, moving)
	_apply()


func _move(dir: Vector3, speed: float, dt: float) -> void:
	var p := _pos + dir * speed * dt
	p.y = _bottom(p)
	_pos = p


func _pose(dt: float, moving: bool) -> void:
	var w := {"hump": 0.0, "feet": 0.5, "stride": 1.0, "dead": 0.0, "lift": 0.0}
	var lead := -1
	if moving: # (the arm it's going toward leading, its tip up)
		w.feet = 1.0
		var local := (Basis(Vector3.UP, _yaw).inverse() * _dir)
		var ang := fposmod(atan2(local.x, -local.z), TAU)
		lead = int(roundf(ang / (TAU / 5.0))) % 5
	var want: Array[Vector4] = []
	for i in 5:
		var a := Vector4(0.0, 0.1, 0.0, 0.0)
		match _mode:
			"eat": # (humped, arms round it)
				a = Vector4(-0.3, 0.6, 0.15 * sin(float(i) * 2.0), 0.0)
			"rest":
				a = Vector4(-0.1, 0.2, 0.0, 0.0)
			"spawn": # (up on its arm tips)
				a = Vector4(-0.6, -0.2, 0.0, 0.0)
			"dead":
				a = Vector4(-0.15, 0.0, 0.2 * sin(float(i) * 3.0), 0.0)
		if i == lead:
			a.x += 0.45
			a.z += 0.15 * sin(_t * 0.5)
		want.append(a)
	match _mode:
		"eat":
			w.hump = 0.022
			w.feet = 0.85
			w.stride = 0.3
		"rest":
			w.feet = 0.1
			w.lift = -0.005
		"spawn":
			w.hump = 0.03
			w.feet = 0.6
			w.lift = 0.006
		"dead":
			w.dead = 1.0
			w.feet = 0.0
			w.lift = -0.006
	var k := 1.0 - exp(-1.5 * dt)
	for i in 5:
		_arms[i] = _arms[i].lerp(want[i], k)
	for key: String in _look:
		_look[key] = lerpf(float(_look[key]), float(w[key]), k)
	if seen:
		for i in 5:
			_mi.set_instance_shader_parameter("arm%d" % i, _arms[i])
		for key: String in ["hump", "feet", "stride", "dead"]:
			_mi.set_instance_shader_parameter(key, float(_look[key]))


func _apply() -> void:
	position = _pos + Vector3(0.0, float(_look.lift) * size, 0.0)
	rotation = Vector3(0.0, _yaw, 0.0)


# --- its mesh -----------------------------------------------------------------------------------

static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/render/sea_star.gdshader")
		_mat.set_shader_parameter("R", R)
		_mat.set_shader_parameter("rd", RD)
		_mat.set_shader_parameter("foot_len", LIFT)
	return _mat


static func _v(st: SurfaceTool, p: Vector3, n: Vector3, cu: Color) -> void:
	st.set_normal(n)
	st.set_custom(0, cu)
	st.add_vertex(p)


## Its half width and its height (m) at s (m out from its middle).
static func _section(s: float) -> Vector2:
	var u := clampf((s - RD) / (R - RD), 0.0, 1.0)
	var hw := lerpf(0.021, 0.0065, pow(u, 0.9)) if s > RD else lerpf(0.026, 0.021, s / RD)
	var h := lerpf(0.022, 0.009, pow(u, 0.8)) if s > RD else lerpf(0.028, 0.022, s / RD)
	var tip := 0.92 * R
	if s > tip: # (its tip rounded)
		var f := sqrt(maxf(1.0 - pow((s - tip) / (R - tip), 2.0), 0.0))
		hw *= f
		h *= maxf(f, 0.25)
	return Vector2(hw, h)


static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var NS := 26
	var NC := 16
	for a in 5:
		var ang := TAU * float(a) / 5.0
		var ax := Vector3(sin(ang), 0.0, -cos(ang))
		var sd := Vector3(cos(ang), 0.0, sin(ang))
		var grid := []
		for i in NS + 1:
			var s := R * float(i) / NS
			var sec := _section(s)
			var row := []
			for j in NC + 1:
				var f := float(j) / NC # (round it: 0..0.5 over its top, side to side; 0.5..1 back under it)
				var p: Vector3
				var n: Vector3
				var top := 0.0
				if f <= 0.5:
					var psi := f * 2.0 * PI
					var x := cos(psi) * sec.x
					var y := LIFT + 0.002 + sin(psi) * (sec.y - 0.002) * (1.0 + 0.04 * sin(s * 300.0 + x * 500.0))
					p = ax * s + sd * x + Vector3(0.0, y, 0.0)
					n = (sd * cos(psi) / maxf(sec.x, 0.001) + Vector3.UP * sin(psi) / maxf(sec.y, 0.001)).normalized()
					top = clampf(sin(psi) * 1.2, 0.0, 1.0)
				else:
					var x := lerpf(-sec.x, sec.x, (f - 0.5) * 2.0)
					var groove := 0.003 * exp(-pow(x / maxf(sec.x * 0.35, 0.0005), 2.0)) # (its ambulacral groove)
					p = ax * s + sd * x + Vector3(0.0, LIFT + 0.002 + groove, 0.0)
					n = Vector3.DOWN
				row.append([p, n, Color(float(a), s / R, -1.0, top)])
			grid.append(row)
		for i in NS:
			for j in NC:
				var q: Array = [grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]]
				for k: int in [0, 1, 2, 0, 2, 3]:
					_v(st, q[k][0], q[k][1], q[k][2])
		# its tube feet: four rows down its groove
		for row in 4:
			var xf := [-0.6, -0.22, 0.22, 0.6][row] as float
			var n := 22
			for e in n:
				var s := lerpf(RD * 0.6, 0.94 * R, (float(e) + 0.5 * float(row % 2)) / n)
				var sec := _section(s)
				var base := ax * s + sd * xf * sec.x * 0.8 + Vector3(0.0, LIFT + 0.002, 0.0)
				var ph := rng.randf()
				var r := 0.0011 * lerpf(1.0, 0.6, s / R)
				var cu := func(t: float) -> Color: return Color(float(a), s / R, t, ph)
				var rings := [[0.0, r], [0.75, r * 0.9], [0.93, r * 1.25], [1.0, 0.0]]
				for k in rings.size() - 1:
					for m in 5:
						var a0 := TAU * float(m) / 5.0
						var a1 := TAU * float(m + 1) / 5.0
						var t0 := float(rings[k][0])
						var t1 := float(rings[k + 1][0])
						var r0 := float(rings[k][1])
						var r1 := float(rings[k + 1][1])
						var o0 := Vector3(cos(a0), 0.0, sin(a0))
						var o1 := Vector3(cos(a1), 0.0, sin(a1))
						var p00 := base + Vector3(0.0, -t0 * LIFT, 0.0) + o0 * r0
						var p01 := base + Vector3(0.0, -t0 * LIFT, 0.0) + o1 * r0
						var p10 := base + Vector3(0.0, -t1 * LIFT, 0.0) + o0 * r1
						var p11 := base + Vector3(0.0, -t1 * LIFT, 0.0) + o1 * r1
						for v: Array in [[p00, o0, t0], [p10, o0, t1], [p11, o1, t1], [p00, o0, t0], [p11, o1, t1], [p01, o1, t0]]:
							_v(st, v[0], v[1], cu.call(v[2]))
	_mesh = st.commit()
	_mesh.custom_aabb = AABB(Vector3(-R * 1.3, -0.02, -R * 1.3), Vector3(R * 2.6, 0.12, R * 2.6))
	return _mesh
