class_name Octopus
extends "res://scripts/creatures/creature.gd"
## An octopus, life size: what the common octopus (CommonOctopus,
## common_octopus.gd) and the giant Pacific octopus (GiantPacificOctopus,
## giant_pacific_octopus.gd) share; each gives its figures (FIG).
##
## Its body: the mantle (the bag behind its head: its gills, its gut, its
## heart), raised or laid back, breathing; the head with its eyes up on its
## sides, gold, the pupil a dark bar always level, a horn of skin over
## each it can raise; the siphon at the mantle's opening; eight arms from
## the crown about its mouth (its beak in the middle, beneath), each with
## two rows of suckers along its underside, smaller and closer to its tip,
## the web between them. One mesh (cached per species); the arms posed in
## shaders/render/octopus.gdshader from their figures here (each a curve
## from its base, its curl, a wave running down it, its tip's own curl):
## nothing of them on the CPU but 24 numbers an arm. Its skin as its
## chromatophores, its iridophores and its papillae make it: dark or pale,
## mottled, passing clouds, matched to the bottom, raised in bumps and
## horns, blanched white with dark round its eyes to startle.
##
## What it does (its own, left to itself; or as it's told, pilot.gd):
## - wander(): crawling over the bottom on its arms, head first, its arms
##   reaching ahead and pulling, waving out to its sides, its mantle
##   trailing.
## - forage(): groping: its arms spread out over the bottom, their tips
##   feeling into every crevice (what it finds: a shrimp it pounces on; a
##   clam it takes home to its den and opens there, the shell left out in
##   its midden).
## - hunt(prey): stalking up to it low and slow, dark clouds passing over
##   its skin; then the pounce: off the bottom and over it, arms and web
##   spread like an umbrella, the web closed over it, held under it and
##   eaten.
## - rest(): in its den (a hollow under rock, by its home; one's made for
##   it), squeezed in, its arms curled round it, matched to the rock,
##   papillae up: still. Sleeping, now and then colours pass over it.
## - flee(from): ink (a cloud, the shape of it, to fool its hunter) and
##   away mantle first on its jet, arms trailing together, then down to
##   the bottom again, matched to it, still.
## - display(): blanched white, dark rings round its eyes, its arms and
##   web spread wide: to startle.
## - mate(partner): he at an arm's length from her, his third right arm
##   (the hectocotylus, its tip spoonlike) reached across, under her mantle.
## - brood(): she, in her den, her eggs hung from its roof in festoons;
##   cleaning them with her arm tips, blowing water over them with her
##   siphon; never leaving them, never eating. When they hatch (hatch())
##   the paralarvae go off into the water (Plankton) and she dies. He dies
##   a while after he's mated (FaunaSim's record: Species "semelparous").
## Its life: eggs brooded (Species "broods": her carrying them is that)
## -> paralarvae in the plankton (Species "plankton") -> settled young,
## small -> grown.

const ARMS := 8
## Each arm's yaw from forward (+ to its left): L1..L4, then R4..R1 (round the crown in order).
const BASE_YAW := [0.3927, 1.1781, 1.9635, 2.7489, -2.7489, -1.9635, -1.1781, -0.3927]
const HECTO := 5 # (R3: a male's mating arm)

## Its figures (a species' FIG): m. ml its mantle's length, al an arm's,
## r0 an arm's radius at its base; its colours.
var FIG := {"ml": 0.2, "al": 0.65, "r0": 0.018, "crown_r": 0.028, "crown_y": 0.035, "web": 0.18, "walk": 0.08, "jet": 1.5,
		"base": Color(0.55, 0.36, 0.25), "dark": Color(0.3, 0.15, 0.09), "spot": Color(0.9, 0.86, 0.78), "spots": 0.25, "horn": 1.0}

var young := false
var male := false
var dead := false
var size := 1.0 # (a settled young one small)
var height: Callable # (x, z) -> the bottom's y
var floor_y := 0.0 # (the bottom, with no height)
var water_y := INF # (the surface)
var den: Node3D # (its den, made by its home)
var make_den := true # (false: none made for it)
var brooding := false
var brood_secs := 600.0 # (left to itself: how long she broods)
var hunting: Node3D
var food: Node3D # (a clam it's taking home)

var _pos := Vector3.ZERO
var _yaw := 0.0
var _home := Vector3.INF
var _mode := "wander"
var _t := 0.0
var _until := 30.0
var _goal := Vector3.INF
var _pace := -1.0
var _from := Vector3.ZERO
var _partner: Node3D
var _check := 0.0
var _phase := 0.0
var _pitch_node := 0.0
var _y_off := 0.0
var _jet_dir := Vector3.FORWARD
var _dead_t := 0.0
var _last_pos := Vector3.ZERO
var _eggs: MultiMeshInstance3D
var _mi: MeshInstance3D
var _mat: ShaderMaterial
var _a: Array[Vector4] = []
var _b: Array[Vector4] = []
var _c: Array[Vector4] = []
var _ta: Array[Vector4] = []
var _tb: Array[Vector4] = []
var _tc: Array[Vector4] = []
var _rnd: Array[float] = []
var _look := {"chroma": 0.5, "mottle": 0.5, "camo": 0.0, "pale": 0.0, "papillae": 0.3, "wave_amp": 0.0, "eye_bar": 0.0, "dead": 0.0,
		"mantle_pitch": 0.0, "mantle_swell": 0.0, "lift": 0.0, "web_sag": 0.15}
var _want := {}
var _camo := Color(0.42, 0.4, 0.34)

static var _meshes := {} # (its species' file -> its mesh)


func _init(young_ := false) -> void:
	young = young_
	male = randf() < 0.5
	_species()
	if young:
		size = randf_range(0.12, 0.35)
	scale = Vector3.ONE * size
	_mi = MeshInstance3D.new()
	_mi.mesh = _mesh()
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/render/octopus.gdshader")
	_mi.material_override = _mat
	add_child(_mi)
	for k: String in ["base", "dark", "spot"]:
		var c: Color = FIG[k]
		_mat.set_shader_parameter(k + "_col", c * randf_range(0.9, 1.1))
	_mat.set_shader_parameter("spots", float(FIG.spots))
	_camo = Color(randf_range(0.38, 0.48), randf_range(0.36, 0.44), randf_range(0.3, 0.36))
	_mat.set_shader_parameter("camo_col", _camo)
	var f := FIG
	_mat.set_shader_parameter("arm_len", float(f.al))
	_mat.set_shader_parameter("arm_r0", float(f.r0))
	_mat.set_shader_parameter("crown_r", float(f.crown_r))
	_mat.set_shader_parameter("crown_y", float(f.crown_y))
	_mat.set_shader_parameter("web_depth", float(f.web))
	_mat.set_shader_parameter("size_k", float(f.ml) / 0.2)
	var ml := float(f.ml)
	var cy := float(f.crown_y)
	_mat.set_shader_parameter("neck", Vector3(0.0, cy + 0.3 * ml, 0.12 * ml))
	_mat.set_shader_parameter("mantle_c", Vector3(0.0, cy + 0.42 * ml, 0.55 * ml))
	_mat.set_shader_parameter("neck_u", 0.42)
	for i in ARMS:
		_a.append(Vector4(BASE_YAW[i], 0.3, 1.2, 0.0))
		_b.append(Vector4(randf() * TAU, 1.0, 0.0, 1.0))
		_c.append(Vector4.ZERO)
		_rnd.append(randf())
	_ta = _a.duplicate()
	_tb = _b.duplicate()
	_tc = _c.duplicate()
	_want = _look.duplicate()
	_yaw = randf() * TAU
	_upload()


## (A species' own: its FIG.)
func _species() -> void:
	pass


func behaviours() -> PackedStringArray:
	return _p_behaviours()


func _p_behaviours() -> PackedStringArray:
	var out := PackedStringArray(["wander", "forage", "eat", "hunt", "rest", "flee", "ink", "display"])
	if not young:
		out.append("mate")
		if not male:
			out.append_array(PackedStringArray(["brood", "hatch"]))
	return out


## Placed at `at` (on the bottom there), facing yaw.
func place(at: Vector3, yaw := 0.0) -> void:
	_pos = at
	_pos.y = _bottom(at)
	_yaw = yaw
	if _home == Vector3.INF:
		_home = _pos
	_apply()


## Its den's place (its record's home): its den made there.
func set_home(at: Vector3) -> void:
	_home = at
	_home.y = _bottom(at)
	if is_instance_valid(den):
		den.position = _home


func where() -> Vector3:
	return _pos


func _bottom(p: Vector3) -> float:
	if height.is_valid():
		return float(height.call(p.x, p.z))
	return floor_y if floor_y != 0.0 or p.y == 0.0 else p.y


# --- what it does ---------------------------------------------------------------------

## (centre, radius: the sandbox's, where to go about: its home's its den's, kept.)
func wander(_centre: Variant = null, _radius := -1.0) -> void:
	_to("wander", randf_range(20.0, 40.0))


func forage(_centre: Variant = null, _radius := -1.0, secs := -1.0) -> void:
	_to("forage", secs if secs > 0.0 else randf_range(20.0, 35.0))


func hunt(prey: Node3D) -> void:
	if prey == null or not is_instance_valid(prey) or dead:
		return
	hunting = prey
	prey.set_meta("hunted", self)
	_to("stalk", 60.0)


func rest(secs := -1.0) -> void:
	_to("to_den" if not young and is_instance_valid(den) and _pos.distance_to(den.position) > 0.08 * size_k() else "rest", secs if secs > 0.0 else randf_range(40.0, 80.0))


func flee(from: Vector3) -> void:
	if dead:
		return
	_from = from
	var away := _pos - from
	away.y = 0.0
	_jet_dir = away.normalized() if away.length() > 0.01 else Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	ink()
	_to("jet", randf_range(1.6, 2.4))


## Its ink: a cloud from its siphon (here, where it is), dark, holding its
## shape a moment, then spreading.
func ink() -> void:
	if get_parent() == null:
		return
	var p := CPUParticles3D.new()
	p.amount = 70
	p.lifetime = 9.0
	p.one_shot = true
	p.explosiveness = 0.8
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 0.03 * size_k()
	p.initial_velocity_max = 0.12 * size_k()
	p.damping_min = 0.05
	p.damping_max = 0.12
	p.gravity = Vector3(0.0, 0.002, 0.0)
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(0.25, 0.8))
	grow.add_point(Vector2(1.0, 1.0))
	p.scale_amount_curve = grow
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.9))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = fade
	var q := QuadMesh.new()
	q.size = Vector2.ONE * 0.12 * size_k() * maxf(size, 0.3)
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
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = blob
	m.albedo_color = Color(0.07, 0.05, 0.04, 0.85)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = m
	p.mesh = q
	get_parent().add_child(p)
	p.position = _pos + Vector3(0.0, float(FIG.crown_y) + 0.2 * float(FIG.ml), 0.0) * size
	p.emitting = true
	p.finished.connect(p.queue_free)


func display() -> void:
	_to("display", randf_range(4.0, 7.0))


func mate(partner: Node3D, _secs := -1.0) -> bool:
	if young or dead or partner == null or not is_instance_valid(partner):
		return false
	_partner = partner
	_to("court", 60.0)
	return true


func is_mating() -> bool:
	return _mode in ["court", "mate"]


## She lays her eggs in her den and broods them (secs: till they hatch;
## left to itself, brood_secs).
func brood(secs := -1.0) -> void:
	if male or young or dead:
		return
	brooding = true
	_to("to_den" if is_instance_valid(den) and _pos.distance_to(den.position) > 0.08 * size_k() else "brood", secs if secs > 0.0 else brood_secs)
	_lay()


## Her eggs hatch: the paralarvae off into the water (left to itself: a
## Plankton cloud of them); she dies.
func hatch() -> void:
	if not brooding:
		return
	brooding = false
	if is_instance_valid(_eggs):
		_eggs.queue_free()
	if not has_meta("sim"): # (with no record: the paralarvae's cloud here; with one, its young are FaunaSim's)
		var pl: Node3D = (load("res://scripts/creatures/plankton.gd") as GDScript).new("octopus", 60)
		pl.set("young_script", (get_script() as Script).resource_path)
		get_parent().add_child(pl)
		pl.position = _pos + Vector3(0.0, 0.2 * size_k(), 0.0)
		pl.call("set_water", _bottom(_pos), water_y if water_y < INF else _pos.y + 2.0)
		die()
		Fauna.report(&"died", self)


func die() -> void:
	if dead:
		return
	dead = true
	brooding = false
	if is_instance_valid(_eggs):
		_eggs.queue_free()
	_to("dead", 1e9)
	_last_pos = _pos


func size_k() -> float:
	return float(FIG.ml) / 0.2


func _to(m: String, secs: float) -> void:
	if dead and m != "dead":
		return
	_mode = m
	_t = 0.0
	_until = secs


# --- steering (pilot.gd) ----------------------------------------------------------------

func is_busy() -> bool:
	return _mode in ["stalk", "pounce", "hold", "jet", "settle", "court", "mate", "brood", "to_den", "home_clam", "open_clam", "display"] or (_pilot != null and _pilot.busy())


func _p_here() -> Vector3:
	return _pos


func _p_heading() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func _p_steer(point: Vector3, speed: float) -> void:
	if _mode in ["jet", "hold", "pounce", "brood"]:
		return
	_goal = point
	_pace = speed
	_to("piloted", 1e9)


func _p_hold() -> void:
	_goal = _pos
	_to("piloted", 1e9)


func _p_mobile() -> bool:
	return not dead and not has_meta("taken") and _mode not in ["brood", "hold", "jet"]


func _p_speed() -> float:
	return float(FIG.walk) * maxf(size, 0.3)


func _p_reach() -> float:
	return 0.15 * size_k() * maxf(size, 0.3)


func _p_act(name: String, args: Dictionary) -> bool:
	if dead:
		return false
	var secs := float(args.get("seconds", -1.0))
	match name:
		"wander":
			wander()
		"forage", "eat":
			var f: Variant = args.get("prey", args.get("food"))
			if f is Node3D and f != self and is_instance_valid(f):
				args.erase("seconds") # (to it, and eaten, however long that takes: its pilot's done when it's done)
				if Diet.kind_of(f) == "clam":
					food = f
					_to("home_clam" if is_instance_valid(den) else "open_clam", 40.0)
				else:
					hunt(f)
			else:
				forage(null, -1.0, secs)
		"hunt":
			var f: Variant = args.get("prey", args.get("target", args.get("food")))
			if not (f is Node3D):
				return false
			hunt(f)
		"rest":
			rest(secs)
		"flee":
			flee(args.get("from", _pos + _p_heading()))
		"ink":
			ink()
		"display":
			display()
		"mate":
			var p: Variant = args.get("partner")
			if not (p is Node3D) or young:
				return false
			mate(p)
		"brood":
			if male or young:
				return false
			brood(secs)
		"hatch":
			hatch()
		_:
			return false
	return true


func _p_act_done(name: String) -> bool:
	match name:
		"forage", "eat": # (what it found: a shrimp hunted, a clam taken home, all one meal)
			return _mode not in ["forage", "home_clam", "open_clam", "stalk", "pounce", "hold"]
		"hunt":
			return _mode not in ["stalk", "pounce", "hold"]
		"rest":
			return _mode not in ["rest", "to_den"]
		"flee":
			return _mode not in ["jet", "settle"]
		"display":
			return _mode != "display"
		"mate":
			return _mode not in ["court", "mate"]
		"brood":
			return not brooding or (_mode == "brood" and _t > _until)
	return true


func _p_act_secs(name: String) -> float:
	return -1.0 # (each done when it's done: a forage that finds a meal goes on till it's eaten)


# --- its frame --------------------------------------------------------------------------

func tick(dt: float) -> void:
	dt = minf(dt, 0.25)
	if _home == Vector3.INF:
		_home = _pos
	if den == null and make_den and not young and not dead and get_parent() != null:
		_make_den()
	_t += dt
	if _pilot and not dead:
		_pilot.tick(dt)
	if dead:
		_dead_frame(dt)
	else:
		if not piloted():
			_threats(dt)
		_doings(dt)
	_pose(dt)
	_apply()


func _threats(dt: float) -> void:
	_check -= dt
	if _check > 0.0 or _mode in ["jet", "settle", "hold", "pounce"]:
		return
	_check = 1.0
	for o: Node in Fauna.near(get_parent(), _pos, 4.0 * size_k()):
		if o == self or not (o is Node3D):
			continue
		var k := Diet.kind_of(o)
		if k in ["shark", "dolphin", "orca"] or (o.get_script() and (o.get_script() as Script).resource_path.ends_with("sea_otter.gd")):
			if Diet.affinity(o, "octopus") > 0.0 or k in ["shark"]:
				if brooding: # (she won't leave her eggs: she startles it)
					if _mode != "display":
						display()
				else:
					flee((o as Node3D).global_position)
				return


func _doings(dt: float) -> void:
	var walk := _p_speed()
	match _mode:
		"wander":
			var off := _pos - _home
			off.y = 0.0
			var turn := sin(_t * 0.3 + _rnd[0] * 9.0) * 0.4
			if off.length() > 3.0 * size_k():
				turn = wrapf(atan2(off.x, off.z) - _yaw, -PI, PI) * 0.8
			_yaw += turn * dt
			_crawl(_p_heading(), walk * 0.8, dt)
			if _t > _until:
				forage()
		"piloted":
			var to := _goal - _pos
			to.y = 0.0
			if to.length() > 0.01:
				_face(to, dt * 2.0)
				_crawl(to.normalized(), minf((_pace if _pace > 0.0 else walk) * dt, to.length()) / maxf(dt, 1e-4), dt)
		"forage":
			if fmod(_t, 2.0) < dt: # (what its arms find)
				var f := Diet.find(self, 0.9 * size_k() * maxf(size, 0.3), ["shrimp", "clam"])
				if f != null and f != self:
					if Diet.kind_of(f) == "clam":
						food = f
						f.set_meta("hunted", self)
						_to("home_clam" if is_instance_valid(den) else "open_clam", 40.0)
					else:
						hunt(f as Node3D)
					return
			_crawl(_p_heading(), walk * 0.15, dt)
			_yaw += sin(_t * 0.5 + _rnd[1] * 7.0) * 0.3 * dt
			if _t > _until:
				_to("idle", 1e9)
				if not piloted():
					rest()
		"stalk": # (low and slow up to it, clouds passing over it)
			if not is_instance_valid(hunting) or hunting.get("dead") == true:
				_finish()
				wander()
				return
			var to := Diet._at(hunting) - _pos
			to.y = 0.0
			_face(to, dt * 3.0)
			if to.length() < 0.55 * float(FIG.al) * maxf(size, 0.3):
				_from = _pos
				_to("pounce", 0.7)
			else:
				_crawl(to.normalized(), walk * 0.5, dt)
			if _t > _until:
				_finish()
				wander()
		"pounce": # (up and over it, web spread)
			if not is_instance_valid(hunting):
				_to("settle", 1.5)
				return
			var at := Diet._at(hunting)
			var k := clampf(_t / _until, 0.0, 1.0)
			var p := _from.lerp(Vector3(at.x, _pos.y, at.z), k * k * (3.0 - 2.0 * k))
			_pos = Vector3(p.x, _bottom(p), p.z)
			_y_off = sin(k * PI) * 0.15 * size_k() * maxf(size, 0.3)
			if k >= 1.0:
				_y_off = 0.0
				Meal.subdue(hunting, self)
				_to("hold", 30.0)
		"hold": # (under its web, eaten)
			if is_instance_valid(hunting):
				hunting.global_position = global_position + Vector3(0.0, 0.01, 0.0)
				hunting.visible = _t < 2.5 # (drawn in to its beak)
			if _t > _until:
				if is_instance_valid(hunting):
					hunting.queue_free()
				hunting = null
				Fauna.report(&"ate", self, {"kind": "shrimp"})
				_to("idle", 1e9)
				if not piloted():
					rest()
		"home_clam", "open_clam": # (a clam: home with it, opened there, its shell left out)
			if not is_instance_valid(food):
				_to("wander", 20.0)
				return
			if _mode == "home_clam":
				var to := den.position - _pos
				to.y = 0.0
				food.global_position = global_position + Vector3(0.0, 0.02 * size_k(), 0.0)
				if to.length() < 0.06 * size_k():
					_to("open_clam", 25.0)
				else:
					_face(to, dt * 2.0)
					_crawl(to.normalized(), walk * 0.8, dt)
			elif _t > _until:
				var out := _p_heading() * 0.35 * size_k() + Vector3(randf_range(-0.06, 0.06), 0.0, randf_range(-0.06, 0.06)) * size_k()
				food.position = _pos + out
				food.position.y = _bottom(food.position)
				food.rotation = Vector3(randf_range(-0.6, 0.6), randf() * TAU, PI * float(randf() < 0.5)) # (its valves agape, thrown out)
				food.remove_meta("shellfish")
				food.remove_meta("hunted")
				food.set_meta("empty_shell", true)
				food = null
				Fauna.report(&"ate", self, {"kind": "clam"})
				_to("idle", 1e9)
				if not piloted():
					rest()
		"to_den":
			if not is_instance_valid(den):
				_to("brood" if brooding else "rest", _until)
				return
			var to := den.position - _pos
			to.y = 0.0
			if to.length() < 0.05 * size_k():
				_yaw = den.rotation.y
				_to("brood" if brooding else "rest", _until)
			else:
				_face(to, dt * 3.0)
				_crawl(to.normalized(), walk, dt)
		"rest":
			if _t > _until:
				_to("idle", 1e9)
				if not piloted():
					wander()
		"jet":
			var k := _t / _until
			var sp := float(FIG.jet) * maxf(size, 0.4) * (1.0 - 0.5 * k)
			var p := _pos + _jet_dir * sp * dt
			p.y = _bottom(p)
			_pos = p
			_y_off = sin(minf(k, 1.0) * PI) * 0.4 * size_k() * maxf(size, 0.3)
			if water_y < INF:
				_y_off = minf(_y_off, water_y - _pos.y - 0.15 * size_k())
			if _t > _until:
				_to("settle", 2.0)
		"settle": # (down, matched to the bottom, still)
			_y_off = lerpf(_y_off, 0.0, 1.0 - exp(-3.0 * dt))
			if _t > _until:
				_y_off = 0.0
				_to("rest", randf_range(8.0, 16.0))
		"display":
			if _t > _until:
				if brooding:
					_to("brood", brood_secs)
				else:
					_to("idle", 1e9)
					if not piloted():
						wander()
		"court": # (to an arm's length from her)
			if not is_instance_valid(_partner):
				_to("idle", 1e9)
				return
			var to := Diet._at(_partner) - _pos
			to.y = 0.0
			var want := 0.75 * float(FIG.al) * maxf(size, 0.3)
			if to.length() < want:
				_face(to.rotated(Vector3.UP, PI * 0.5), dt * 2.0) # (side on: his right arms toward her)
				_to("mate", randf_range(25.0, 40.0))
			else:
				_face(to, dt * 2.0)
				_crawl(to.normalized(), walk, dt)
		"mate":
			if _t > _until or not is_instance_valid(_partner):
				_partner = null
				_to("idle", 1e9)
				if not piloted():
					wander()
		"brood":
			if _t > _until:
				if has_meta("sim"): # (her time's up: her record's to say they've hatched, and she's done)
					pass
				else:
					hatch()


## (Over the bottom: moved along dir at speed, its arms' crawl kept time with it.)
func _crawl(dir: Vector3, speed: float, dt: float) -> void:
	var p := _pos + dir * speed * dt
	p.y = _bottom(p)
	_pos = p
	_phase += speed * dt / maxf(0.2 * float(FIG.al) * maxf(size, 0.3), 0.01) * TAU


func _face(dir: Vector3, k: float) -> void:
	if Vector2(dir.x, dir.z).length() < 0.001:
		return
	var want := atan2(-dir.x, -dir.z)
	_yaw += wrapf(want - _yaw, -PI, PI) * clampf(k, 0.0, 1.0)


## (What it was doing, over: its pilot sees it's done, by _p_act_done.)
func _finish() -> void:
	pass


func _dead_frame(dt: float) -> void:
	_y_off = lerpf(_y_off, 0.0, 1.0 - exp(-dt))
	if global_position.distance_to(_last_pos) > 0.01: # (taken: in a hunter's jaws)
		_dead_t = 0.0
		_last_pos = global_position
		return
	_dead_t += dt
	if _dead_t > 240.0: # (gone to the scavengers)
		queue_free()


# --- its pose: its arms' figures, its colours ------------------------------------------

func _pose(dt: float) -> void:
	var w := _want
	w.lift = 0.0
	w.web_sag = 0.15
	w.mantle_pitch = 0.0
	w.mantle_swell = 0.03 * sin(_t * 1.6) # (breathing)
	w.chroma = 0.55
	w.mottle = 0.55
	w.camo = 0.15
	w.pale = 0.0
	w.papillae = 0.3
	w.wave_amp = 0.0
	w.eye_bar = 0.0
	w.dead = 0.0
	var tt := _t
	for i in ARMS:
		var by: float = BASE_YAW[i]
		var r := _rnd[i]
		var a := Vector4(by, -0.15, 1.3, 0.0)
		var b := Vector4(0.0, 1.0, 0.0, 1.0)
		var c := Vector4(0.0, 1.2, 0.0, 0.0)
		match _mode:
			"wander", "piloted", "to_den", "home_clam", "court": # (crawling: reaching ahead, pulling, waving out to the sides)
				var g := _phase + float(i % 4) * PI * 0.5 + (PI if i >= 4 else 0.0)
				a = Vector4(by + 0.12 * sin(g), -0.2 + 0.08 * sin(g + 1.0), 1.4, 0.35)
				b = Vector4(2.0, 0.8, 0.0, 0.92 + 0.08 * sin(g))
				c = Vector4(0.7 * sin(g * 0.5 + r * 6.0), 1.4 + 0.6 * sin(tt * 0.7 + r * 9.0), 0.0, 0.0)
				if _mode == "home_clam" and (i == 0 or i == 7): # (the clam held to it in its front arms)
					a = Vector4(by * 0.4, 0.4, 3.5, 0.0)
					c = Vector4(0.0, 2.0, 0.0, 0.0)
				w.lift = 0.15 * float(FIG.ml)
			"forage", "open_clam": # (groping: arms out, their tips feeling)
				var s := sin(tt * (0.4 + r * 0.5) + r * 20.0)
				a = Vector4(by + 0.35 * s, -0.05, 0.6 + 0.5 * s, 0.9)
				b = Vector4((2.0 + r * 2.0), 1.4, 0.3 * s, 1.0)
				c = Vector4(0.9 * sin(tt * 0.6 + r * 5.0), 2.5 * maxf(sin(tt * 0.9 + r * 13.0), 0.0), 0.0, 0.0)
				if _mode == "open_clam" and i in [0, 1, 6, 7]: # (pulling its valves apart, under it)
					a = Vector4(by * 0.5, 0.9, 4.0, 0.3)
				w.mottle = 0.7
				w.papillae = 0.45
			"stalk":
				var g := _phase + float(i) * 0.8
				a = Vector4(by * 0.8, 0.0, 2.2, 0.2)
				b = Vector4(1.0, 0.8, 0.0, 0.85 + 0.05 * sin(g))
				c = Vector4(0.3 * sin(g), 2.5, 0.0, 0.0)
				w.chroma = 0.85
				w.wave_amp = 1.0 # (passing clouds: to make it start)
				w.lift = 0.05 * float(FIG.ml)
			"pounce": # (arms and web spread, an umbrella)
				a = Vector4(by * 1.05, -0.05, -0.9, 0.0)
				b = Vector4(0.0, 1.0, 0.0, 0.95)
				c = Vector4(0.0, 0.5, 0.0, 0.0)
				w.web_sag = 0.4
				w.chroma = 0.8
				w.pale = 0.3
			"hold": # (the web closed over it, arms curled in under)
				a = Vector4(by, 0.5, 3.5, 0.3)
				b = Vector4(1.5, 1.0, 0.0, 0.8)
				c = Vector4(0.4 * sin(r * 9.0), 3.0, 0.0, 0.0)
				w.web_sag = 0.35
				w.chroma = 0.7
				w.mantle_pitch = 0.3
			"rest", "settle", "brood": # (squeezed in, arms curled round it; matched to the rock)
				a = Vector4(by, 0.15, 1.0, 0.0)
				b = Vector4(0.0, 1.0, 0.0, 0.8)
				c = Vector4(3.2 * (0.8 + r * 0.4), 2.5, 0.0, 0.0) # (each coiled round, the same way)
				w.camo = 0.85
				w.papillae = 0.85
				w.chroma = 0.5
				w.mantle_pitch = 0.35
				w.mantle_swell = 0.025 * sin(tt * 1.1)
				if _mode == "rest" and fmod(tt + r * 30.0, 45.0) > 37.0: # (its active sleep: colours passing over it, its arms twitching)
					w.camo = 0.3
					w.wave_amp = 0.8
					w.chroma = 0.3 + 0.5 * (0.5 + 0.5 * sin(tt * 3.0))
					c.x += 0.6 * sin(tt * 9.0 + r * 30.0)
				if _mode == "brood": # (her front arms up, cleaning her eggs; her siphon blowing over them)
					w.pale = 0.22 # (paler as the weeks go by, in life)
					w.camo = 0.3
					w.mantle_swell = 0.06 * sin(tt * 2.2)
					if i in [0, 1, 6, 7]:
						a = Vector4(by * 0.7, -1.0 + 0.2 * sin(tt * 0.8 + r * 7.0), 0.8, 0.8)
						b = Vector4(1.2, 1.2, 0.0, 0.75)
						c = Vector4(0.5 * sin(tt * 0.6 + r * 5.0), 1.5, 0.0, 0.0)
			"jet": # (mantle first, arms trailing together)
				a = Vector4(by * 0.12, -0.25, 0.0, 0.25)
				b = Vector4(6.0, 1.5, 0.0, 1.0)
				c = Vector4(0.0, 0.3, 0.0, 0.0)
				w.mantle_swell = -0.12 * (0.5 + 0.5 * sin(tt * 14.0)) # (its jet, pulse on pulse)
				w.pale = 0.5 if tt < 0.4 else 0.0
				w.chroma = 0.9
				w.mantle_pitch = -0.4
			"display": # (blanched; dark round its eyes; arms and web spread up and out)
				a = Vector4(by * 1.1, 0.1, -0.1, 0.15)
				b = Vector4(1.0, 1.0, 0.0, 0.95)
				c = Vector4(0.0, -0.5, 0.0, 0.0)
				w.pale = 0.9
				w.eye_bar = 1.0
				w.papillae = 0.0
				w.web_sag = 0.35
				w.lift = 0.2 * float(FIG.ml)
				w.mantle_swell = 0.1
			"mate": # (his hectocotylus reached across to her; hers: still)
				a = Vector4(by, 0.5, 3.0, 0.0)
				b = Vector4(0.0, 1.0, 0.0, 0.85)
				c = Vector4(0.4 * sin(r * 9.0), 2.5, 0.0, 0.0)
				if i == HECTO and is_instance_valid(_partner):
					var to := global_transform.affine_inverse() * Diet._at(_partner)
					a = Vector4(atan2(-to.x, -to.z), 0.05, 0.25, 0.1)
					b = Vector4(1.0, 1.0, 0.0, 1.08)
					c = Vector4(0.0, 0.0, 0.0, 0.0)
				w.pale = 0.2
			"dead":
				a = Vector4(by + (r - 0.5) * 0.4, 0.1, 0.4 + r, 0.0)
				b = Vector4(0.0, 1.0, 0.0, 0.95)
				c = Vector4((r - 0.5) * 1.5, 1.0 * r, 0.0, 0.0)
				w.dead = 1.0
				w.mantle_swell = -0.15
				w.papillae = 0.0
				w.chroma = 0.0
		_ta[i] = a
		_tb[i] = b
		_tc[i] = c
	if young: # (a young one paler, matched less)
		w.chroma *= 0.8
	var k := 1.0 - exp(-(10.0 if _mode in ["jet", "pounce", "display"] else 3.0) * dt)
	for i in ARMS:
		_a[i] = _a[i].lerp(_ta[i], k)
		var bb := _b[i].lerp(_tb[i], k)
		bb.x = fmod(_b[i].x + _tb[i].x * dt, TAU * 64.0) # (its wave runs on down it: x its pace)
		_b[i] = bb
		_c[i] = _c[i].lerp(_tc[i], k)
	var kc := 1.0 - exp(-(6.0 if _mode in ["jet", "display", "pounce"] else 1.2) * dt) # (its colours: fast; to blanch, faster)
	for key: String in _look:
		var rate := k if key in ["lift", "web_sag", "mantle_pitch", "mantle_swell"] else kc
		_look[key] = lerpf(float(_look[key]), float(w[key]), rate)
	if seen:
		_upload()


func _upload() -> void:
	_mat.set_shader_parameter("arm_a", PackedVector4Array(_a))
	_mat.set_shader_parameter("arm_b", PackedVector4Array(_b))
	_mat.set_shader_parameter("arm_c", PackedVector4Array(_c))
	for key: String in _look:
		_mat.set_shader_parameter(key, float(_look[key]))
	_mat.set_shader_parameter("floor_on", 0.0 if _mode == "jet" or _y_off > 0.05 * float(FIG.ml) else 1.0)


func _apply() -> void:
	position = _pos + Vector3(0.0, _y_off, 0.0)
	var face := _yaw
	if _mode == "jet": # (mantle first: its back to where it's going)
		face = atan2(_jet_dir.x, _jet_dir.z)
	rotation = Vector3(0.0, face, 0.0)


# --- its den and its eggs -----------------------------------------------------------------

func _make_den() -> void:
	for o in get_parent().get_children(): # (one by its home already: its own)
		if o is Node3D and o.has_meta("octopus_den") and (o as Node3D).position.distance_to(_home) < 0.3 * size_k() and not is_instance_valid(o.get_meta("octopus_den")):
			den = o
			den.set_meta("octopus_den", self)
			return
	den = Octopus.den_node(size_k(), randi())
	den.set_meta("octopus_den", self)
	get_parent().add_child(den)
	den.position = _home
	den.rotation.y = randf() * TAU


func _exit_tree() -> void:
	if is_instance_valid(den) and den.get_meta("octopus_den", null) == self:
		den.queue_free()


## Her eggs, hung in festoons from her den's roof (or, with no den, over her).
func _lay() -> void:
	if is_instance_valid(_eggs):
		return
	var k := size_k()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var egg := CapsuleMesh.new()
	egg.radius = 0.0012 * k * 1.5
	egg.height = 0.0045 * k * 1.5
	egg.radial_segments = 6
	egg.rings = 2
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.93, 0.9, 0.8, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.3
	egg.material = m
	mm.mesh = egg
	var strings := 26
	var per := 36
	mm.instance_count = strings * per
	var roof := 0.26 * k
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id()
	var n := 0
	for s in strings:
		var at := Vector3(rng.randf_range(-0.12, 0.12) * k, roof, rng.randf_range(-0.1, 0.1) * k)
		var ln := rng.randf_range(0.05, 0.1) * k
		for e in per:
			var f := float(e) / per
			var p := at + Vector3(rng.randf_range(-0.004, 0.004) * k * (0.3 + f), -f * ln, rng.randf_range(-0.004, 0.004) * k * (0.3 + f))
			mm.set_instance_transform(n, Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))), p))
			n += 1
	_eggs = MultiMeshInstance3D.new()
	_eggs.multimesh = mm
	_eggs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if is_instance_valid(den):
		den.add_child(_eggs)
	else:
		get_parent().add_child(_eggs)
		_eggs.position = _pos
		_eggs.position.y += 0.05 * k


## A den: a hollow under a slab of rock on boulders, its mouth one way
## (-z), rocks piled at its sides (an octopus heaps them there). k: its
## size (a common octopus's 1). Meta "octopus_den".
static func den_node(k: float, seed_ := 0) -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rocks := [[Vector3(0.0, 0.3, 0.02), Vector3(0.34, 0.07, 0.3)]] # (the slab: its middle, its half sizes)
	for s in [-1.0, 1.0]:
		rocks.append([Vector3(s * 0.24, 0.12, 0.08), Vector3(0.1, 0.14, 0.16)])
		rocks.append([Vector3(s * 0.2, 0.08, -0.18), Vector3(0.08, 0.09, 0.08)])
	rocks.append([Vector3(0.0, 0.13, 0.26), Vector3(0.22, 0.15, 0.09)])
	for i in 4: # (stones piled out front by its mouth)
		rocks.append([Vector3(rng.randf_range(-0.3, 0.3), 0.03, rng.randf_range(-0.42, -0.3)), Vector3.ONE * rng.randf_range(0.03, 0.06)])
	for rk: Array in rocks:
		var c: Vector3 = rk[0] * k
		var hs: Vector3 = rk[1] * k
		var sm := SphereMesh.new()
		sm.radial_segments = 14
		sm.rings = 8
		var arr := sm.get_mesh_arrays()
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var off := rng.randf() * 100.0
		for i in ix:
			var v: Vector3 = vs[i] * 2.0
			var bump := 1.0 + 0.12 * sin(v.x * 5.0 + off) * sin(v.y * 4.0 + off * 1.3) * sin(v.z * 6.0 + off * 0.7)
			var p := c + Vector3(v.x * hs.x, v.y * hs.y, v.z * hs.z) * bump
			st.set_normal(Vector3(v.x / hs.x, v.y / hs.y, v.z / hs.z).normalized())
			st.set_color(Color(1, 1, 1).lerp(Color(0.6, 0.75, 0.5), clampf(v.y, 0.0, 1.0) * 0.6)) # (green with what grows on its top)
			st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42, 0.4, 0.36)
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	mi.material_override = m
	root.add_child(mi)
	root.set_meta("octopus_den", null)
	return root


# --- its mesh -------------------------------------------------------------------------------

func _mesh() -> ArrayMesh:
	var key := (get_script() as Script).resource_path
	if _meshes.has(key):
		return _meshes[key]
	var m := Octopus.build(FIG)
	_meshes[key] = m
	return m


static func _v(st: SurfaceTool, p: Vector3, n: Vector3, cu: Color, uv := Vector2.ZERO) -> void:
	st.set_normal(n)
	st.set_uv(uv)
	st.set_custom(0, cu)
	st.add_vertex(p)


static func _quads(st: SurfaceTool, grid: Array, rows: int, cols: int) -> void:
	for i in rows:
		for j in cols:
			var q: Array = [grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]
			for k: int in [0, 1, 2, 0, 2, 3]:
				var e: Array = q[k]
				_v(st, e[0], e[1], e[2], e[3])


## Its mesh from its figures (f: FIG): the head and mantle, the eyes and
## their horns, the siphon, the arms and the web (these two only placed
## roughly: the shader puts them where they are).
static func build(f: Dictionary) -> ArrayMesh:
	var ml := float(f.ml)
	var al := float(f.al)
	var cy := float(f.crown_y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	# the head and the mantle: round an axis from the crown up through the head, back along the mantle
	var axis := [[0.0, Vector3(0.0, 0.0, 0.0), 0.15], [0.12, Vector3(0.0, 0.1, 0.0), 0.2], [0.26, Vector3(0.0, 0.2, 0.02), 0.22],
			[0.42, Vector3(0.0, 0.29, 0.1), 0.19], [0.58, Vector3(0.0, 0.38, 0.3), 0.3], [0.78, Vector3(0.0, 0.44, 0.6), 0.31],
			[0.93, Vector3(0.0, 0.45, 0.88), 0.18], [1.0, Vector3(0.0, 0.445, 0.97), 0.0]]
	var NR := 30
	var NA := 22
	var grid := []
	for j in NR + 1:
		var g := float(j) / NR * (axis.size() - 1)
		var i0 := mini(int(g), axis.size() - 2)
		var fr := g - i0
		var pre: Array = axis[maxi(i0 - 1, 0)]
		var a0: Array = axis[i0]
		var a1: Array = axis[i0 + 1]
		var post: Array = axis[mini(i0 + 2, axis.size() - 1)]
		var p := (a0[1] as Vector3).cubic_interpolate(a1[1], pre[1], post[1], fr) * ml + Vector3(0.0, cy, 0.0)
		var r := maxf(cubic_interpolate(float(a0[2]), float(a1[2]), float(pre[2]), float(post[2]), fr), 0.0) * ml
		var u := lerpf(float(a0[0]), float(a1[0]), fr)
		var g2 := minf(g + 0.05, axis.size() - 1.001)
		var j0 := mini(int(g2), axis.size() - 2)
		var pn := (axis[j0][1] as Vector3).lerp(axis[j0 + 1][1], g2 - j0) * ml + Vector3(0.0, cy, 0.0)
		var tg := (pn - p).normalized() if j < NR else (p - (axis[axis.size() - 2][1] as Vector3) * ml - Vector3(0.0, cy, 0.0)).normalized()
		var x := Vector3.RIGHT
		var up := tg.cross(x).normalized() * -1.0
		var row := []
		for k in NA + 1:
			var an := TAU * float(k) / NA
			var o := x * cos(an) * 1.06 + up * sin(an)
			row.append([p + o * r, o.normalized(), Color(0.0, u, 0.0, 0.0), Vector2(float(k) / NA, u)])
		grid.append(row)
	_quads(st, grid, NR, NA)
	var mouth := Vector3(0.0, cy - 0.01 * ml, 0.0) # (beneath: closed over its mouth)
	for k in NA:
		var e0: Array = grid[0][k]
		var e1: Array = grid[0][k + 1]
		_v(st, mouth, Vector3.DOWN, Color(0.0, 0.0, 0.0, 0.0))
		_v(st, e1[0], e1[1], e1[2])
		_v(st, e0[0], e0[1], e0[2])
	# its eyes, and a horn over each
	for s in [-1.0, 1.0]:
		var ec := Vector3(s * 0.205 * ml, cy + 0.21 * ml, 0.0)
		var er := 0.075 * ml
		var eg := []
		for i in 9:
			var row := []
			var ph := PI * float(i) / 8.0
			for j in 13:
				var th := TAU * float(j) / 12.0
				var n := Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th))
				row.append([ec + n * er, n, Color(3.0, n.x, n.y, n.z), Vector2.ZERO])
			eg.append(row)
		_quads(st, eg, 8, 12)
		var hb := ec + Vector3(0.0, er * 0.85, 0.0)
		var hr := 0.03 * ml * float(f.horn)
		var hh := 0.07 * ml * float(f.horn)
		for j in 6:
			var a0 := TAU * float(j) / 6.0
			var a1 := TAU * float(j + 1) / 6.0
			var cu := Color(5.0, hb.x, hb.y, hb.z)
			var b0 := hb + Vector3(cos(a0), 0.0, sin(a0)) * hr
			var b1 := hb + Vector3(cos(a1), 0.0, sin(a1)) * hr
			var tip := hb + Vector3(s * 0.01 * ml, hh, 0.0)
			var n := (b0 - hb + b1 - hb).normalized()
			_v(st, b0, n, cu)
			_v(st, tip, Vector3.UP, cu)
			_v(st, b1, n, cu)
	# the siphon: out of the mantle's opening, on its right
	var s0 := Vector3(0.13 * ml, cy + 0.16 * ml, 0.1 * ml)
	var sd := Vector3(1.0, -0.15, -0.25).normalized()
	var sx := sd.cross(Vector3.UP).normalized()
	var sy := sx.cross(sd)
	var sg := []
	for i in 3:
		var row := []
		for j in 9:
			var an := TAU * float(j) / 8.0
			var o := sx * cos(an) + sy * sin(an)
			row.append([s0 + sd * 0.1 * ml * float(i) / 2.0 + o * 0.035 * ml * (1.0 - 0.25 * float(i) / 2.0), o, Color(4.0, 0.0, 0.0, 0.0), Vector2.ZERO])
		sg.append(row)
	_quads(st, sg, 2, 8)
	# the arms: rings along each (placed by the shader)
	var NT := 44
	var NS := 10
	for a in ARMS:
		var d := Vector3(-sin(float(BASE_YAW[a])), 0.0, -cos(float(BASE_YAW[a])))
		var ag := []
		for i in NT + 1:
			var t := float(i) / NT
			var row := []
			for j in NS + 1:
				var th := TAU * float(j) / NS
				row.append([Vector3(0.0, cy, 0.0) + d * (float(f.crown_r) + t * al), Vector3.UP, Color(1.0, float(a), t, th), Vector2.ZERO])
			ag.append(row)
		_quads(st, ag, NT, NS)
	# the web: arm to arm
	for a in ARMS:
		var wg := []
		for i in 6:
			var row := []
			for j in 7:
				row.append([Vector3(0.0, cy, 0.0), Vector3.UP, Color(2.0, float(a), float(j) / 6.0, float(i) / 5.0), Vector2.ZERO])
			wg.append(row)
		_quads(st, wg, 5, 6)
	var mesh := st.commit()
	var reach := al + 0.3 * ml
	mesh.custom_aabb = AABB(Vector3(-reach, -0.1 * ml, -reach), Vector3(reach * 2.0, reach + ml, reach * 2.0))
	return mesh
