extends Node3D
## A tank of sailfin mollies (Mollies: every fish drawn by the shader, a
## school a draw call), sand, stones and eelgrass:
## godot --path . res://tools/creatures/molly_demo.tscn
##
## 1 all schooling   2 all down to graze   3 the males display
## S scatter them (from a point by the glass)   M the school to another spot
## P one steered (pilot.gd): along, down to graze, back
## + / - more or fewer fish   Space slow motion   drag: turn round   wheel: nearer / further

const MolliesScript := preload("res://scripts/creatures/mollies.gd")
const TANK_MIN := Vector3(-0.6, 0.0, -0.3)
const TANK_MAX := Vector3(0.6, 0.5, 0.3)

var school: MolliesScript
var cam: Camera3D
var _yaw := 0.3
var _pitch := -0.2
var _dist := 1.3
var _count := 60
var _label: Label


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-60), deg_to_rad(-30), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 4.0
	add_child(sun)
	# the floor under the tank, the sand in it, a few stones, eelgrass
	_box(Vector3(0.0, -0.03, 0.0), Vector3(3.0, 0.02, 2.0), Color(0.3, 0.27, 0.22), 0.9)
	_box(Vector3(0.0, 0.01, 0.0), Vector3(1.2, 0.02, 0.6), Color(0.76, 0.68, 0.52), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 6:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		s.mesh = sm
		var r := rng.randf_range(0.03, 0.07)
		s.scale = Vector3(r * 1.4, r * 0.8, r)
		s.position = Vector3(rng.randf_range(-0.5, 0.5), 0.02, rng.randf_range(-0.22, 0.22))
		s.material_override = _mat(Color(0.45, 0.43, 0.4).darkened(rng.randf() * 0.3), 0.8)
		add_child(s)
	for k in 40:
		var at := Vector3(rng.randf_range(-0.55, 0.55), 0.02, rng.randf_range(-0.25, -0.1) if k % 3 else rng.randf_range(0.1, 0.25))
		var h := rng.randf_range(0.15, 0.4)
		var g := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.006, h, 0.0008)
		g.mesh = b
		g.position = at + Vector3(0.0, h * 0.5, 0.0)
		g.rotation = Vector3(rng.randf_range(-0.15, 0.15), rng.randf() * TAU, rng.randf_range(-0.15, 0.15))
		g.material_override = _mat(Color(0.25, 0.45, 0.18).lerp(Color(0.35, 0.5, 0.2), rng.randf()), 0.6)
		add_child(g)
	# the water, faintly green; the glass
	var water := _box((TANK_MIN + TANK_MAX) * 0.5 + Vector3(0.0, -0.01, 0.0), TANK_MAX - TANK_MIN - Vector3(0.0, 0.02, 0.0), Color(0.55, 0.75, 0.7, 0.16), 0.1)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glass := _box((TANK_MIN + TANK_MAX) * 0.5, TANK_MAX - TANK_MIN + Vector3(0.01, 0.0, 0.01), Color(0.85, 0.95, 0.95, 0.06), 0.05)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cam = Camera3D.new()
	cam.near = 0.005
	cam.far = 50.0
	cam.fov = 50.0
	add_child(cam)
	_label = Label.new()
	_label.position = Vector2(12, 8)
	add_child(_label)
	_make()


func _make() -> void:
	if school:
		school.queue_free()
	school = MolliesScript.new()
	school.tank_min = TANK_MIN + Vector3(0.0, 0.02, 0.0)
	school.tank_max = TANK_MAX - Vector3(0.0, 0.03, 0.0)
	add_child(school)
	school.setup(_count, Vector3(0.0, 0.25, 0.0), 0.15)
	_label.text = "%d sailfin mollies   1 school   2 graze   3 the males display   S scatter   M move the school   P one steered   + / - more or fewer   Space slow motion   drag: turn round   wheel: nearer / further" % _count


func _sequence(c: Object, orders: Array) -> void:
	var left := orders.duplicate()
	var next := func(_name := "", _ok := true) -> void:
		if not left.is_empty():
			(left.pop_front() as Callable).call()
	c.connect("action_finished", next)
	next.call()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				for i in _count:
					school.rejoin(i)
			KEY_2:
				for i in _count:
					school.graze(i)
			KEY_3:
				for i in _count:
					school.display(i)
			KEY_S:
				school.scatter(Vector3(randf_range(-0.4, 0.4), 0.25, 0.3))
			KEY_M:
				school.swim_to(Vector3(randf_range(-0.45, 0.45), randf_range(0.12, 0.4), randf_range(-0.18, 0.18)))
			KEY_P:
				var f: Object = school.member(0)
				_sequence(f, [
					func() -> void: f.go(Vector3.RIGHT, -1.0, 3.0),
					func() -> void: f.act("graze", {"seconds": 4.0}),
					func() -> void: f.go_to(Vector3(-0.3, 0.3, 0.0)),
				])
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				_count = mini(_count * 2, 1920)
				_make()
			KEY_MINUS, KEY_KP_SUBTRACT:
				_count = maxi(_count / 2, 1)
				_make()
			KEY_SPACE:
				Engine.time_scale = 0.2 if Engine.time_scale > 0.5 else 1.0
	elif e is InputEventMouseMotion and e.button_mask != 0:
		_yaw -= e.relative.x * 0.008
		_pitch = clampf(_pitch - e.relative.y * 0.008, -1.4, 1.2)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist * 0.85, 0.08)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist / 0.85, 6.0)


func _process(_dt: float) -> void:
	var focus := Vector3(0.0, 0.22, 0.0)
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = focus + off
	cam.look_at(focus, Vector3.UP)


func _box(at: Vector3, size: Vector3, c: Color, rough: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = at
	mi.material_override = _mat(c, rough)
	add_child(mi)
	return mi


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
