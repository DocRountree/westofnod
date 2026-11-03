extends Node3D
## A plain to watch the wasp (Wasp) on, each of its animations on a key:
## godot --path . res://tools/creatures/wasp_demo.tscn
##
## 1 seek food (flying about)   2 feed on the flower   3 catch and eat the
## caterpillar (R puts a fresh one back on its leaf)   4 land on the plank
## (walk about, settle)   5 sting the red ball   Space slow motion
## Mouse: drag to turn round it, wheel to come nearer or go off; the camera
## follows the wasp (F: or not).

var wasp: Wasp
var cam: Camera3D
var prey: Node3D
var _yaw := 0.6
var _pitch := -0.35
var _dist := 0.12
var _follow := true
var _focus := Vector3.ZERO
var _label: Label

const FLOWER := Vector3(0.3, 0.0, -0.2)
const FLOWER_H := 0.45
const LEAF := Vector3(-0.3, 0.2, 0.0)
const PLANK := Vector3(0.0, 0.06, 0.4)
const BALL := Vector3(-0.35, 0.025, 0.35)


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
	sun.directional_shadow_max_distance = 4.0
	add_child(sun)
	_box(Vector3(0, -0.005, 0), Vector3(4, 0.01, 4), Color(0.33, 0.4, 0.2))
	# the flower: a stem, petals round a dark middle
	var stem := _box(FLOWER + Vector3(0, FLOWER_H * 0.5, 0), Vector3(0.005, FLOWER_H, 0.005), Color(0.3, 0.42, 0.15))
	stem.name = "stem"
	var petals := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.035
	disc.bottom_radius = 0.035
	disc.height = 0.002
	petals.mesh = disc
	petals.position = FLOWER + Vector3(0, FLOWER_H - 0.001, 0)
	petals.material_override = _mat(Color(0.96, 0.7, 0.06))
	add_child(petals)
	var middle := MeshInstance3D.new()
	var dome := CylinderMesh.new()
	dome.top_radius = 0.011
	dome.bottom_radius = 0.012
	dome.height = 0.004
	middle.mesh = dome
	middle.position = FLOWER + Vector3(0, FLOWER_H - 0.001, 0)
	middle.material_override = _mat(Color(0.17, 0.08, 0.04))
	add_child(middle)
	# the leaf the caterpillar's on, on a stalk
	_box(LEAF + Vector3(0, -0.1, 0), Vector3(0.004, 0.2, 0.004), Color(0.3, 0.42, 0.15))
	_box(LEAF + Vector3(0, 0.001, 0), Vector3(0.12, 0.002, 0.07), Color(0.25, 0.45, 0.15))
	# a plank to land on, and a ball to sting
	_box(PLANK, Vector3(0.3, 0.02, 0.1), Color(0.55, 0.42, 0.28))
	var ball := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.025
	s.height = 0.05
	ball.mesh = s
	ball.position = BALL
	ball.material_override = _mat(Color(0.7, 0.12, 0.1))
	add_child(ball)
	_new_prey()
	wasp = Wasp.new()
	add_child(wasp)
	wasp.place(Vector3(0.0, 0.3, 0.0))
	cam = Camera3D.new()
	cam.near = 0.001
	cam.far = 100.0
	cam.fov = 50.0
	add_child(cam)
	_focus = wasp.global_position
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.text = "1 seek food   2 feed on the flower   3 catch the caterpillar (R: a new one)   4 land on the plank   5 sting the ball\nSpace slow motion   F follow on/off   drag: turn round   wheel: nearer / further"
	add_child(_label)
	wasp.seek_food(Vector3.ZERO, 0.6)


func _new_prey() -> void:
	if prey:
		if wasp:
			wasp.release()
		prey.queue_free()
	prey = Wasp.caterpillar()
	add_child(prey)
	prey.position = LEAF + Vector3(0.02, 0.0035, 0.01)
	prey.rotation.y = 0.7


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1:
				wasp.seek_food(Vector3.ZERO, 0.6)
			KEY_2:
				wasp.feed_on_flower(FLOWER + Vector3(0, FLOWER_H + 0.001, 0), Vector3.UP, 0.03)
			KEY_3:
				wasp.feed_on_insect(prey, LEAF + Vector3(0, 0.002, 0), Vector3.UP)
			KEY_4:
				wasp.land(PLANK + Vector3(0, 0.01, 0), Vector3.UP)
			KEY_5:
				wasp.sting(BALL + Vector3(0, 0.02, 0))
			KEY_R:
				_new_prey()
			KEY_F:
				_follow = not _follow
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


func _process(dt: float) -> void:
	if _follow:
		_focus = _focus.lerp(wasp.global_position, 1.0 - exp(-6.0 * dt / maxf(Engine.time_scale, 0.01)))
	var off := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist
	cam.global_position = _focus + off
	cam.look_at(_focus, Vector3.UP)


func _box(at: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = at
	mi.material_override = _mat(c)
	add_child(mi)
	return mi


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m
