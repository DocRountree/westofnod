class_name Player
extends CharacterBody3D
## First/third-person controller (F5 toggles): walk/sprint/jump, swim, optional
## fly mode, and digging into the terrain.

const WALK_SPEED := 4.6
const SPRINT_SPEED := 7.5
const FLY_SPEED := 30.0
const JUMP_VELOCITY := 7.6
const GRAVITY := 24.0
const REACH := 6.0
const MOUSE_SENS := 0.0025
const THIRD_PERSON_DISTANCE := 4.5

var terrain: TerrainWorld
var head: Node3D # eye point; pitches with the mouse
var camera: Camera3D
var third_person := false
var _arm: SpringArm3D
var _body_mesh: MeshInstance3D
var flying := false
var frozen := true
var _cooldown := 0.0


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
	var in_water := global_position.y + 0.9 < 0.0

	if flying:
		var vy := 0.0
		if Input.is_action_pressed("jump"):
			vy += 1.0
		if Input.is_action_pressed("descend"):
			vy -= 1.0
		var spd := FLY_SPEED * (2.5 if Input.is_action_pressed("sprint") else 1.0)
		velocity = dir * spd + Vector3.UP * vy * spd * 0.6
	else:
		var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		if in_water:
			speed *= 0.6
			velocity.y = move_toward(velocity.y, -1.5, 8.0 * delta)
			if Input.is_action_pressed("jump"):
				velocity.y = 3.2
		else:
			velocity.y -= GRAVITY * delta
			if Input.is_action_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
		var accel := 40.0 if is_on_floor() else 12.0
		velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
	move_and_slide()

	_cooldown -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _cooldown <= 0.0:
		_dig()
		_cooldown = 0.22


func _ray() -> Dictionary:
	var from := head.global_position
	var to := from - head.global_basis.z * REACH
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q)


func _dig() -> void:
	var hit := _ray()
	if not hit.is_empty() and hit.collider.get_meta("kind", "") == "terrain":
		terrain.dig(hit.position)
