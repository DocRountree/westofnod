extends Node3D
## A plain to watch beetles on, June bugs (JuneBeetles) and convergent lady
## beetles (LadyBeetles), their two animations on keys:
## godot --path . res://tools/creatures/beetle_demo.tscn
##
## 1 all walking about   2 all to the leaves, eating   3 half and half
## + / - more or fewer of each (every one drawn by the shader)
## Space slow motion   drag: turn round   wheel: nearer / further
## For the scale, a pawpaw and a black-eyed Susan lying by (Items).

const JuneScript := preload("res://scripts/creatures/june_beetles.gd")
const LadyScript := preload("res://scripts/creatures/lady_beetles.gd")
var colonies: Array = [] # the June bugs, the lady beetles
var cam: Camera3D
var _yaw := 0.7
var _pitch := -0.6
var _dist := 0.35
var _count := 6
var _label: Label

const CRUMBS := [Vector3(0.09, 0.0, -0.06), Vector3(-0.1, 0.0, 0.07)] # (the leaves)


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
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 2.0
	add_child(sun)
	var ground := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(3, 0.01, 3)
	ground.mesh = b
	ground.position.y = -0.005
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.42, 0.36, 0.26)
	gm.roughness = 0.95
	ground.material_override = gm
	add_child(ground)
	for c in CRUMBS:
		var cr := Beetles.leaf()
		cr.position = Vector3(c.x, 0.0, c.z)
		add_child(cr)
	for t in [["pawpaw", Vector3(-0.16, 0.028, -0.08), Vector3(0, 0.4, PI * 0.5)], ["susan", Vector3(0.15, 0.006, 0.1), Vector3(0, -0.3, PI * 0.5)]]:
		var m := Items.model(t[0])
		m.position = t[1]
		m.rotation = t[2]
		add_child(m)
	cam = Camera3D.new()
	cam.near = 0.001
	cam.far = 50.0
	cam.fov = 50.0
	add_child(cam)
	_label = Label.new()
	_label.position = Vector2(12, 8)
	add_child(_label)
	_make()


func _make() -> void:
	for c in colonies:
		c.queue_free()
	colonies = [JuneScript.new(), LadyScript.new()]
	for c in colonies:
		add_child(c)
		c.setup(_count, Vector3.ZERO, 0.22)
	_label.text = "%d June bugs and %d lady beetles   1 walk about   2 eat at the leaves   3 half and half   + / - more or fewer   Space slow motion   drag: turn round   wheel: nearer / further" % [_count, _count]


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				for c in colonies:
					for i in _count:
						c.wander(i, Vector3.ZERO, 0.22)
			KEY_2, KEY_3:
				for c in colonies:
					for i in _count:
						if e.keycode == KEY_3 and i % 2 == 1:
							c.wander(i, Vector3.ZERO, 0.22)
						else:
							# (each its own place on its leaf)
							var leaf: Vector3 = CRUMBS[i % CRUMBS.size()]
							c.feed(i, leaf + Vector3(randf_range(-0.02, 0.02), 0.0, randf_range(-0.035, 0.035)))
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				_count = mini(_count * 2, 1280)
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
			_dist = maxf(_dist * 0.85, 0.02)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist / 0.85, 3.0)


func _process(_dt: float) -> void:
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = off
	cam.look_at(Vector3.ZERO, Vector3.UP)
