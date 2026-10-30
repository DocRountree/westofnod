class_name Player
extends CharacterBody3D
## First/third-person controller (F5 toggles): walk/sprint/jump, swim (as in
## Minecraft, see _swim()) and an optional fly mode.

const WALK_SPEED := 4.6
const SPRINT_SPEED := 7.5
const FLY_SPEED := 30.0
const JUMP_VELOCITY := 7.6
const GRAVITY := 24.0
const MOUSE_SENS := 0.0025
const THIRD_PERSON_DISTANCE := 4.5
const SWIM_SPEED := 2.2
const SWIM_SPRINT_SPEED := 5.6
const SWIM_UP_SPEED := 2.4
const SINK_SPEED := 0.6
const CURRENT_SPEED := 1.4 # m/s at full river flow (as inland_water.gdshader's river_speed)

var island: IslandData
var head: Node3D # eye point; pitches with the mouse
var camera: Camera3D
var third_person := false
var swimming := false # sprint-swimming
var _arm: SpringArm3D
var _body_mesh: MeshInstance3D
var flying := false
var frozen := true


func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position.y = 0.9
	add_child(cs)
	head = Node3D.new()
	head.position.y = 1.62
	add_child(head)
	# Third person: the spring arm pulls the camera back behind the head and in
	# front of any terrain in the way. First person: zero length.
	_arm = SpringArm3D.new()
	_arm.spring_length = 0.0
	_arm.margin = 0.2
	_arm.add_excluded_object(get_rid())
	head.add_child(_arm)
	camera = Camera3D.new()
	camera.far = 7000.0
	camera.near = 0.08
	camera.fov = 75.0
	_arm.add_child(camera)
	_body_mesh = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.8
	_body_mesh.mesh = cap
	_body_mesh.position.y = 0.9
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.75, 0.32, 0.18)
	_body_mesh.material_override = body_mat
	_body_mesh.visible = false
	add_child(_body_mesh)
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 0.6


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * MOUSE_SENS, -1.55, 1.55)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_F:
				flying = not flying
			KEY_F5:
				set_third_person(not third_person)


func set_third_person(on: bool) -> void:
	third_person = on
	_arm.spring_length = THIRD_PERSON_DISTANCE if on else 0.0
	_arm.position.x = 0.45 if on else 0.0
	_body_mesh.visible = on


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var water := island.water_at(global_position.x, global_position.z) if island else Vector3.ZERO
	var depth := water.x - global_position.y # how deep the feet are
	var in_water := depth > 0.6
	var head_under := water.x > head.global_position.y

	if flying:
		var vy := 0.0
		if Input.is_action_pressed("jump"):
			vy += 1.0
		if Input.is_action_pressed("descend"):
			vy -= 1.0
		var spd := FLY_SPEED * (2.5 if Input.is_action_pressed("sprint") else 1.0)
		velocity = dir * spd + Vector3.UP * vy * spd * 0.6
		swimming = false
	elif in_water:
		_swim(delta, dir, depth, head_under, Vector2(water.y, water.z))
	else:
		swimming = false
		var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		velocity.y -= GRAVITY * delta
		if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		var accel := 40.0 if is_on_floor() else 12.0
		velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
	move_and_slide()


## Swimming, as in Minecraft: you slowly sink unless you hold jump, which swims
## you up (and bobs you at the surface); descend sinks faster; movement is slow.
## Sprinting with your head under water swims fast wherever you look, up and
## down included. Swimming into a bank with jump held climbs out. Rivers carry
## you downstream.
func _swim(delta: float, dir: Vector3, depth: float, head_under: bool, flow: Vector2) -> void:
	var look := -head.global_basis.z
	var forward := Input.get_vector("move_left", "move_right", "move_forward", "move_back").y < -0.3
	swimming = head_under and forward and Input.is_action_pressed("sprint")
	var target := Vector3.ZERO
	if swimming:
		target = look * SWIM_SPRINT_SPEED
	else:
		target = dir * SWIM_SPEED
		if Input.is_action_pressed("jump"):
			target.y = SWIM_UP_SPEED
		elif Input.is_action_pressed("descend"):
			target.y = -SWIM_UP_SPEED
		else:
			target.y = -SINK_SPEED
	# The current carries you along; water is thick, so velocities ease toward
	# the target (and a dive is braked).
	target += Vector3(flow.x, 0.0, flow.y) * CURRENT_SPEED
	velocity = velocity.move_toward(target, 9.0 * delta)
	if Input.is_action_pressed("jump") and is_on_wall() and depth < 1.6:
		velocity.y = 4.2 # climb out onto the bank
