class_name Player
extends CharacterBody3D
## First/third-person controller (F5 toggles): walk/sprint/jump, swim (as in
## Minecraft, see _swim()), climb rock too steep to walk (C toggles; see
## _climb()) and an optional fly mode. The figure (Avatar) is animated
## procedurally; the third-person camera never goes inside the terrain.

const WALK_SPEED := 4.6
const SPRINT_SPEED := 7.5
const FLY_SPEED := 120.0
const DOUBLE_TAP_MS := 300
const JUMP_VELOCITY := 7.6
const GRAVITY := 24.0
const MOUSE_SENS := 0.0025
const THIRD_PERSON_DISTANCE := 4.5
const SWIM_SPEED := 2.2
const SWIM_SPRINT_SPEED := 5.6
const SWIM_UP_SPEED := 2.4
const SINK_SPEED := 0.6
const CURRENT_SPEED := 1.4 # m/s at full river flow (as river.gdshader's river_speed)
const CLIMB_SPEED := 1.4
const CLIMB_OFFSET := 0.45 # body centre off the rock
const CLIMBABLE := 0.85 # surface normal y below which ground counts as a wall

var world: WorldData
var head: Node3D # eye point; pitches with the mouse
var camera: Camera3D
var third_person := false
var swimming := false # sprint-swimming
var _arm: SpringArm3D
var avatar: Avatar
var climbing := false
var _was_third_person := false
var _grip_offset := Vector2.ZERO # rock point under the hands, relative to the origin
var _cs: CollisionShape3D
var flying := false
var _last_space := -100000 # ms of the last Space press, for double-tap
var frozen := true


func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	_cs = CollisionShape3D.new()
	_cs.shape = shape
	_cs.position.y = 0.9
	add_child(_cs)
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
	camera.far = 120000.0
	camera.near = 0.08
	camera.fov = 75.0
	_arm.add_child(camera)
	avatar = Avatar.new()
	avatar.visible = false
	add_child(avatar)
	_arm.shape = SphereShape3D.new() # a ball, not a ray: no peeking through slopes
	_arm.shape.radius = 0.25
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
			KEY_SPACE: # double-tap toggles fly mode
				var now := Time.get_ticks_msec()
				if now - _last_space < DOUBLE_TAP_MS:
					flying = not flying
					_last_space = -100000
				else:
					_last_space = now
			KEY_F5:
				if not climbing:
					set_third_person(not third_person)
			KEY_C:
				set_climbing(not climbing)


func set_third_person(on: bool) -> void:
	third_person = on
	_arm.spring_length = THIRD_PERSON_DISTANCE if on else 0.0
	_arm.position.x = 0.45 if on else 0.0
	avatar.visible = on


## Climbing grips the rock under (or just in front of) the player, if it is
## steep enough; the view goes third person for the climb.
func set_climbing(on: bool) -> void:
	if on == climbing or world == null:
		return
	if on:
		var fwd := -global_basis.z
		var p := global_position + fwd * 0.6
		if world.normal_at(p.x, p.z).y > CLIMBABLE and world.normal_at(global_position.x, global_position.z).y > CLIMBABLE:
			return # nothing steep here to climb
		flying = false
		_was_third_person = third_person
		set_third_person(true)
		_grip_offset = Vector2(fwd.x, fwd.z) * 0.6
	else:
		set_third_person(_was_third_person)
		velocity = Vector3.ZERO
	climbing = on
	_cs.disabled = on


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var water := world.water_at(global_position.x, global_position.z) if world else Vector3.ZERO
	var depth := water.x - global_position.y # how deep the feet are
	var in_water := depth > 0.6
	var head_under := water.x > head.global_position.y

	if climbing:
		_climb(delta)
		return
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
	# The figure faces where it is going and steps along.
	var hv := Vector3(velocity.x, 0.0, velocity.z)
	if hv.length() > 0.3:
		var want := Basis.looking_at(hv.normalized(), Vector3.UP)
		avatar.global_basis = avatar.global_basis.orthonormalized().slerp(want, minf(1.0, delta * 10.0))
	else:
		avatar.global_basis = Basis(Vector3.UP, avatar.global_rotation.y)
	if avatar.visible:
		avatar.walk(delta, hv.length(), is_on_floor() or flying)


## Climbing: hands and feet on the rock, moving over its surface. W/S climb up
## and down the fall line, A/D traverse; Space lets go. Over the top (or down
## onto ground gentle enough to stand on) the climb ends by itself.
func _climb(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var g := Vector2(global_position.x, global_position.z) + _grip_offset
	var n := world.normal_at(g.x, g.y)
	var up_t := (Vector3.UP - n * n.y).normalized()
	var right := up_t.cross(n)
	var move := (right * input.x - up_t * input.y) * CLIMB_SPEED * delta
	var before := Vector3(g.x, world.height_at(g.x, g.y), g.y)
	g += Vector2(move.x, move.z)
	var surface := Vector3(g.x, world.height_at(g.x, g.y), g.y)
	n = world.normal_at(g.x, g.y)
	up_t = (Vector3.UP - n * n.y).normalized()
	right = up_t.cross(n)
	if Input.is_action_just_pressed("jump") or (n.y > CLIMBABLE + 0.05 and input.length() > 0.1):
		# Let go, or step out onto ground you can stand on.
		global_position = surface + Vector3.UP * 0.05
		set_climbing(false)
		return
	var centre := surface + n * CLIMB_OFFSET
	global_position = centre - up_t * 1.0
	_grip_offset = Vector2(surface.x, surface.z) - Vector2(global_position.x, global_position.z)
	velocity = Vector3.ZERO
	avatar.global_basis = Basis(right, up_t, n)
	avatar.climb(surface, n, up_t, surface - before)


func _process(_delta: float) -> void:
	# Keep the camera above the ground (the spring arm keeps it off slopes).
	if world and third_person:
		var c := camera.global_position
		var h := world.height_at(c.x, c.z) + 0.4
		if c.y < h:
			camera.global_position = Vector3(c.x, h, c.z)


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
