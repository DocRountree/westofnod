class_name Player
extends CharacterBody3D
## First/third-person controller (F5 toggles): walk/sprint/jump, swim (as in
## Minecraft, see _swim()), climb rock too steep to walk or a tree's trunk
## (C toggles; see _climb(), _climb_tree()) and an optional fly mode. The figure (Avatar) is animated
## procedurally; the third-person camera never goes inside the terrain.
## Its `position` is where it is on the map (it hangs from Origin.root);
## global positions (the camera's, the head's) are drawn ones (Origin).

const WALK_SPEED := 4.6
const SPRINT_SPEED := 7.5
const FLY_SPEED := 120.0
const DOUBLE_TAP_MS := 300
const JUMP_VELOCITY := 7.6
const GRAVITY := 24.0
const MOUSE_SENS := 0.0025
const FOV := 75.0
const MAX_ZOOM := 8.0
const THIRD_PERSON_DISTANCE := 4.5
const SWIM_SPEED := 4.4
const SWIM_SPRINT_SPEED := 11.2
const SWIM_UP_SPEED := 4.8
const SINK_SPEED := 0.6
const CLIMB_SPEED := 3.5
const SWAMP_SLOW := 0.64 # walking speed in a swamp (wading)
const SWAMP_SINK := Vector2(0.5, 0.9) # m into the mud: knees to hips
const CLIMB_OFFSET := 0.45 # body centre off the rock
const CLIMBABLE := 0.85 # surface normal y below which ground counts as a wall
const BODY_RADIUS := 0.3 # for pushing off trees, rocks and the like (Population.push_out)

var world: WorldData
var population: Population ## Trees, rocks, animals: what the body bumps into (optional).
var head: Node3D # eye point; pitches with the mouse
var camera: Camera3D
var third_person := false
var swimming := false # sprint-swimming
var _arm: SpringArm3D
var avatar: Avatar
var climbing := false
var _was_third_person := false
var _grip_offset := Vector2.ZERO # rock point under the hands, relative to the origin
var _trunk := PackedFloat32Array() # the trunk or limb being climbed (Population climbs_near; empty: rock)
var _trunk_s := 0.0 # how far along its axis the body is (m)
var _trunk_n := Vector3.RIGHT # which way out from its axis the body is (world)
var _switched := 0 # ms of the last change of trunk or limb (they don't chain)
var _cs: CollisionShape3D
var flying := false
var can_fly := true ## Double-tapping Space flies (debug mode only: Session).
## Magnified view (Z; the wheel sets the power): for now a key, later a
## telescope item. 1 = off.
var zoom := 1.0
var zoom_power := 6.0
var grounded := false ## Standing on the ground (see _move).
var sink := 0.0 ## How deep the feet are in the mud (swamps).
var _last_space := -100000 # ms of the last Space press, for double-tap
var frozen := true
var typing := false ## The chat is open: the keys are the chat's.


func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	_cs = CollisionShape3D.new()
	_cs.shape = shape
	_cs.position.y = 0.9
	_cs.disabled = true # (terrain contact is _move's; the shape only keeps the camera's arm off the body)
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
	camera.fov = FOV
	_arm.add_child(camera)
	avatar = Avatar.new()
	avatar.visible = false
	add_child(avatar)
	_arm.shape = SphereShape3D.new() # a ball, not a ray: no peeking through slopes
	_arm.shape.radius = 0.25
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 0.6


func _move_input() -> Vector2:
	return Vector2.ZERO if typing else Input.get_vector("move_left", "move_right", "move_forward", "move_back")


func _held(action: StringName) -> bool:
	return not typing and Input.is_action_pressed(action)


func _just(action: StringName) -> bool:
	return not typing and Input.is_action_just_pressed(action)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and zoom > 1.0:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_power = clampf(zoom_power * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 2.0, MAX_ZOOM)
			set_zoom(zoom_power)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := MOUSE_SENS / zoom # the view moves as fast on screen, magnified or not
		rotate_y(-event.relative.x * sens)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * sens, -1.55, 1.55)
	if event is InputEventKey and event.pressed and not event.echo and not typing:
		match event.keycode:
			KEY_SPACE: # double-tap toggles fly mode
				if not can_fly:
					return
				var now := Time.get_ticks_msec()
				if now - _last_space < DOUBLE_TAP_MS:
					set_flying(not flying)
					_last_space = -100000
				else:
					_last_space = now
			KEY_F5:
				if not climbing:
					set_third_person(not third_person)
			KEY_C:
				set_climbing(not climbing)
			KEY_Z:
				set_zoom(1.0 if zoom > 1.0 else zoom_power)


## Landing from flight: keep only a walking pace of the flying velocity, so
## you don't carry 100+ m/s into the ground.
func set_flying(on: bool) -> void:
	if on == flying:
		return
	flying = on
	if not on:
		var hv := Vector2(velocity.x, velocity.z).limit_length(SPRINT_SPEED)
		velocity = Vector3(hv.x, minf(velocity.y, 0.0) * 0.1, hv.y)


## Magnify the view by z (1 = normal). Looking through it is first person.
func set_zoom(z: float) -> void:
	zoom = maxf(z, 1.0)
	camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(FOV) * 0.5) / zoom))
	_arm.spring_length = 0.0 if zoom > 1.0 or not third_person else THIRD_PERSON_DISTANCE
	_arm.position.x = 0.0 if zoom > 1.0 or not third_person else 0.45
	avatar.visible = third_person and zoom <= 1.0


func set_third_person(on: bool) -> void:
	third_person = on
	_arm.spring_length = THIRD_PERSON_DISTANCE if on else 0.0
	_arm.position.x = 0.45 if on else 0.0
	avatar.visible = on


## Climbing grips a tree's trunk within reach, or else the rock under (or
## just in front of) the player, if it is steep enough; the view goes third
## person for the climb.
func set_climbing(on: bool) -> void:
	if on == climbing or world == null:
		return
	if not on and not _trunk.is_empty():
		_leave_tree()
	_trunk = PackedFloat32Array()
	avatar.trunk = _trunk
	if on and population:
		var chest := position + Vector3.UP * 1.2
		var tr := population.trunk_near(chest, 0.9)
		var at := chest
		if tr.is_empty(): # (standing on a limb: the limb under your feet)
			at = position + Vector3.UP * 0.1
			tr = population.trunk_near(at, 0.4)
		if not tr.is_empty():
			_grip(tr, at)
			set_flying(false)
			_was_third_person = third_person
			set_third_person(true)
			climbing = true
			return
	if on:
		var fwd := -global_basis.z
		var p := position + fwd * 0.6
		if world.normal_at(p.x, p.z).y > CLIMBABLE and world.normal_at(position.x, position.z).y > CLIMBABLE:
			return # nothing steep here to climb
		set_flying(false)
		_was_third_person = third_person
		set_third_person(true)
		_grip_offset = Vector2(fwd.x, fwd.z) * 0.6
	else:
		set_third_person(_was_third_person)
		velocity = Vector3.ZERO
	climbing = on


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var input := _move_input()
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var water := world.water_at(position.x, position.z) if world else Vector3.ZERO
	var depth := water.x - position.y # how deep the feet are
	var in_water := depth > 0.6
	var head_under := water.x > head.global_position.y

	if climbing:
		if _trunk.is_empty():
			_climb(delta)
		else:
			_climb_tree(delta)
		return
	if flying:
		var vy := 0.0
		if _held("jump"):
			vy += 1.0
		if _held("descend"):
			vy -= 1.0
		var spd := FLY_SPEED * (2.5 if _held("sprint") else 1.0)
		velocity = dir * spd + Vector3.UP * vy * spd * 0.6
		swimming = false
	elif in_water:
		_swim(delta, dir, depth, head_under)
	else:
		swimming = false
		var speed := SPRINT_SPEED if _held("sprint") else WALK_SPEED
		if world.biome_index_at(position.x, position.z) == world.swamp:
			speed *= SWAMP_SLOW
		velocity.y -= GRAVITY * delta
		if _held("jump") and grounded:
			velocity.y = JUMP_VELOCITY
			grounded = false
		var accel := 40.0 if grounded else 12.0
		velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
	_move(delta, in_water)
	# The figure faces where it is going and steps along; sprint-swimming,
	# it lies out along its way and swims (as in Minecraft).
	var hv := Vector3(velocity.x, 0.0, velocity.z)
	if in_water and swimming and not flying and velocity.length() > 1.0:
		var way := velocity.normalized()
		var back := (Vector3.UP - way * way.y).normalized() if absf(way.y) < 0.98 else -global_basis.z
		var prone := Basis(way.cross(back).normalized(), way, back) # up along the way, back to the sky
		avatar.global_basis = avatar.global_basis.orthonormalized().slerp(prone, minf(1.0, delta * 6.0))
		if avatar.visible:
			avatar.swim(delta, velocity.length())
		return
	if hv.length() > 0.3:
		var want := Basis.looking_at(hv.normalized(), Vector3.UP)
		avatar.global_basis = avatar.global_basis.orthonormalized().slerp(want, minf(1.0, delta * 10.0))
	else:
		avatar.global_basis = Basis(Vector3.UP, avatar.global_rotation.y)
	if avatar.visible:
		avatar.sink = sink
		avatar.walk(delta, hv.length(), grounded or flying)


## Moving over the terrain. It is a height field, so the body moves against
## the exact surface that is drawn (WorldData.height_at), not a physics
## approximation of it: nothing to snag on, nothing to sink into. On foot, the
## feet follow the ground (down slopes too, within a step); ground steeper
## than floor_max_angle can't be walked up and slides you down it. Flying and
## swimming only keep you above it. (The physics collider is for the camera.)
func _move(delta: float, in_water: bool) -> void:
	var p := position + velocity * delta
	if population and not flying:
		# round the trunks and boulders; logs too high to step onto (measured
		# from the mud's surface when wading: you step up out of it)
		var up := Vector3(0.0, sink, 0.0)
		p = population.push_out(p + up, BODY_RADIUS) - up
	var g := world.height_at(p.x, p.z)
	var n := world.normal_at(p.x, p.z)
	var steep := n.y < cos(floor_max_angle)
	if flying or in_water:
		sink = 0.0
		if p.y < g:
			p.y = g
			velocity.y = maxf(velocity.y, 0.0)
		grounded = false
	else:
		# a fallen log or stump under foot (stepped up onto, if no higher than
		# a step above the ground, or the mud's surface)
		var deck := population.deck_at(p, position.y + sink + Population.STEP_UP) if population else -INF
		# a swamp swallows you to the knees or hips (deeper here, shallower
		# there), easing in and out at its edge
		var want := 0.0
		if deck <= g and world.biome_index_at(p.x, p.z) == world.swamp:
			want = lerpf(SWAMP_SINK.x, SWAMP_SINK.y, WorldData.vnoise(p.x / 7.0, p.z / 7.0))
		sink = move_toward(sink, want, delta)
		g -= sink
		if deck > g:
			g = deck
			steep = false
		var uphill := -Vector2(n.x, n.z).normalized()
		if steep and g > position.y + 0.05:
			# too steep to walk up: keep only the motion along (or down) it
			var hv := Vector2(velocity.x, velocity.z)
			var up := hv.dot(uphill)
			if up > 0.0:
				hv -= uphill * up
				velocity.x = hv.x
				velocity.z = hv.y
				p = position + velocity * delta
				g = world.height_at(p.x, p.z) - sink
				n = world.normal_at(p.x, p.z)
				steep = n.y < cos(floor_max_angle)
		var snap := 0.6 if grounded and velocity.y <= 0.0 else 0.0
		if p.y <= g + snap:
			p.y = g
			velocity.y = 0.0
			grounded = not steep
			if steep: # slide down
				velocity.x += n.x * GRAVITY * delta
				velocity.z += n.z * GRAVITY * delta
		else:
			grounded = false
	position = p


## Climbing: hands and feet on the rock, moving over its surface. W/S climb up
## and down the fall line, A/D traverse; Space lets go. Over the top (or down
## onto ground gentle enough to stand on) the climb ends by itself.
func _climb(delta: float) -> void:
	var input := _move_input()
	var g := Vector2(position.x, position.z) + _grip_offset
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
	if _just("jump") or (n.y > CLIMBABLE + 0.05 and input.length() > 0.1):
		# Let go, or step out onto ground you can stand on.
		position = surface + Vector3.UP * 0.05
		set_climbing(false)
		return
	var centre := surface + n * CLIMB_OFFSET
	position = centre - up_t * 1.0
	_grip_offset = Vector2(surface.x, surface.z) - Vector2(position.x, position.z)
	velocity = Vector3.ZERO
	avatar.global_basis = Basis(right, up_t, n)
	avatar.climb(surface, n, up_t, surface - before)


## Climbing a tree: hands and feet on the bark. W/S along the trunk or limb
## (up and down; out and back), A/D round it; Space lets go. Where a limb
## leaves the trunk, moving its way (or, just under it, W) goes out along
## it; back at its root, on down the trunk. Down at the foot, the climb ends
## by itself; C on top of a limb stands you on it (_leave_tree).
func _climb_tree(delta: float) -> void:
	var input := _move_input()
	var f := Population.trunk_frame(_trunk, _trunk_s)
	var n := _trunk_out(f)
	var up_t: Vector3 = f[2]
	var right := up_t.cross(n)
	var surface: Vector3 = (f[0] as Vector3) + n * (f[1] as float)
	var before := surface
	if input.length() > 0.1:
		var move := (up_t * -input.y + right * input.x).normalized()
		if _switch_line(surface, n, move, input):
			f = Population.trunk_frame(_trunk, _trunk_s)
	var top := Population.trunk_length(_trunk) - 0.3
	var s_was := _trunk_s
	_trunk_s = clampf(_trunk_s - input.y * CLIMB_SPEED * 0.7 * delta, 0.0, top)
	# round it (A/D): turning the way out about the axis
	_trunk_n = _trunk_out(f).rotated((f[2] as Vector3).normalized(), input.x * CLIMB_SPEED * 0.7 * delta / maxf(f[1] as float + CLIMB_OFFSET, 0.3))
	f = Population.trunk_frame(_trunk, _trunk_s)
	up_t = f[2]
	n = _trunk_out(f)
	surface = (f[0] as Vector3) + n * (f[1] as float)
	right = up_t.cross(n)
	var on_trunk := _is_trunk()
	# back down a limb to where it leaves the trunk: on down the trunk
	if not on_trunk and input.y > 0.1 and _trunk_s <= 0.0 and s_was <= 0.05:
		var others := population.climbs_near(surface, 0.6)
		for o in others:
			var tr: PackedFloat32Array = o[0]
			if tr != _trunk:
				_grip(tr, surface + n * 0.3)
				_switched = Time.get_ticks_msec()
				return
	var feet := surface + n * CLIMB_OFFSET - up_t * 1.0
	var ground := world.height_at(feet.x, feet.z)
	if _just("jump") or (on_trunk and input.y > 0.1 and feet.y <= ground + 0.05):
		# let go (falling, pushed off the bark a little), or down at the foot
		position = Vector3(feet.x, maxf(feet.y, ground), feet.z)
		_trunk = PackedFloat32Array()
		set_climbing(false)
		velocity = n * 1.5
		return
	position = Vector3(feet.x, maxf(feet.y, ground), feet.z)
	velocity = Vector3.ZERO
	avatar.global_basis = Basis(right, up_t, n)
	avatar.climb(surface, n, up_t, surface - before)


## The line being climbed is a trunk (it starts at the ground: lower than
## any of the lines near its start), not a limb.
func _is_trunk() -> bool:
	return absf(_trunk[1] - world.height_at(_trunk[0], _trunk[2])) < 1.0


## Takes hold of a trunk or limb at the point of it nearest p.
func _grip(tr: PackedFloat32Array, p: Vector3) -> void:
	_trunk = tr
	avatar.trunk = tr
	_trunk_s = clampf(Population.trunk_nearest(tr, p), 0.0, Population.trunk_length(tr) - 0.3)
	var f := Population.trunk_frame(tr, _trunk_s)
	_trunk_n = p - (f[0] as Vector3)
	_trunk_n = _trunk_out(f)


## From the trunk onto a limb leaving it by the hands: one that heads the
## way you're moving, or, just under it, pressing W. (Only from the trunk,
## and not again for a moment: from limb to limb to limb it skipped you up
## the tree in a blink.)
func _switch_line(surface: Vector3, n: Vector3, move: Vector3, input: Vector2) -> bool:
	if not _is_trunk() or Time.get_ticks_msec() - _switched < 600:
		return false
	var hands := surface + (Population.trunk_frame(_trunk, _trunk_s)[2] as Vector3) * 0.6
	for o in population.climbs_near(hands, 0.5):
		var tr: PackedFloat32Array = o[0]
		if tr == _trunk:
			continue
		var s := Population.trunk_nearest(tr, hands)
		if s > 1.2:
			continue # (not near where it leaves)
		var t: Vector3 = Population.trunk_frame(tr, s)[2]
		var under := input.y < -0.1 and t.dot(n) > 0.3 # (it leaves on your side, above)
		if move.dot(t) > 0.7 or under:
			var f := Population.trunk_frame(tr, Population.trunk_nearest(tr, surface))
			if surface.distance_to(f[0]) - (f[1] as float) > 0.6:
				continue # (its bark not within reach of where you are)
			_grip(tr, surface)
			_switched = Time.get_ticks_msec()
			return true
	return false


## Out from the axis toward the climber (_trunk_n, kept square to the axis)
## at a frame of the line.
func _trunk_out(f: Array) -> Vector3:
	var axis: Vector3 = (f[2] as Vector3).normalized()
	var n := _trunk_n - axis * _trunk_n.dot(axis)
	if n.length() < 1e-3: # (along the axis: any way square to it)
		n = axis.cross(Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT)
	return n.normalized()


## Leaving a tree with C: on top of a limb, you stand on it; otherwise
## (on the trunk, or under a limb) you drop.
func _leave_tree() -> void:
	var f := Population.trunk_frame(_trunk, _trunk_s)
	var axis: Vector3 = f[0]
	var n := _trunk_out(f)
	if not _is_trunk() and n.y > 0.3:
		position = axis + Vector3.UP * ((f[1] as float) + 0.02)
		grounded = true
	velocity = Vector3.ZERO


func _process(_delta: float) -> void:
	# Keep the camera above the ground (the spring arm keeps it off slopes).
	if world and third_person:
		var c := camera.global_position
		var m := Origin.map(c) # (drawn: Origin)
		var h := world.height_at(m.x, m.z) + 0.4
		if c.y < h:
			camera.global_position = Vector3(c.x, h, c.z)


## Swimming, as in Minecraft: you slowly sink unless you hold jump, which swims
## you up (and bobs you at the surface); descend sinks faster; movement is slow.
## Sprinting with your head under water swims fast wherever you look, up and
## down included. Swimming into a bank with jump held climbs out.
func _swim(delta: float, dir: Vector3, depth: float, head_under: bool) -> void:
	var look := -head.global_basis.z
	var forward := _move_input().y < -0.3
	swimming = forward and _held("sprint") # (Ctrl + forward: swim flat out, as in Minecraft)
	var target := Vector3.ZERO
	if swimming:
		target = look * SWIM_SPRINT_SPEED
	else:
		target = dir * SWIM_SPEED
		if _held("jump"):
			target.y = SWIM_UP_SPEED
		elif _held("descend"):
			target.y = -SWIM_UP_SPEED
		else:
			target.y = -SINK_SPEED
	# Water is thick: velocities ease toward the target (and a dive is braked).
	velocity = velocity.move_toward(target, 36.0 * delta)
	var ahead := position + Vector3(dir.x, 0.0, dir.z) * 0.6
	if _held("jump") and depth < 1.6 and world.height_at(ahead.x, ahead.z) > position.y:
		velocity.y = 4.2 # climb out onto the bank
