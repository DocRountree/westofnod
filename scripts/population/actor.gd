class_name Actor
extends Node3D
## Base for NPCs and animals: something that stands on the terrain and moves
## over it. Like the player, it moves against the drawn height field
## (WorldData.height_at), not physics, and steps round props
## (Population.push_out). Override think() for behaviour; the default wanders
## round its home. Population sets world, population, kind, home and rng
## before it enters the tree.

var world: WorldData
var population: Population
var kind: ActorKind
var home := Vector3.ZERO ## Where it was spawned.
var rng := RandomNumberGenerator.new() ## Seeded per actor: the same choices each time it spawns.
var velocity := Vector3.ZERO
var grounded := true

@export var walk_speed := 1.4
@export var turn_speed := 4.0 ## rad/s
@export var radius := 0.35 ## Body radius, for pushing off props.
@export var max_slope := 0.75 ## The steepest ground it will walk up (normal y).
@export var can_swim := false ## Otherwise it stays out of the sea.
@export var wander_radius := 25.0

var _goal := Vector3.INF
var _wait := 0.0


func _physics_process(delta: float) -> void:
	if world == null:
		return
	think(delta)
	_move(delta)


## Behaviour, once a physics frame: set velocity (horizontal; the ground
## takes care of y). The default ambles between random points round home,
## with pauses.
func think(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		velocity = Vector3.ZERO
		return
	if _goal == Vector3.INF or Vector2(_goal.x - position.x, _goal.z - position.z).length() < 1.0:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * wander_radius
		_goal = home + Vector3(cos(a), 0.0, sin(a)) * r
		_wait = rng.randf_range(1.0, 6.0)
		return
	steer_to(_goal, walk_speed)


## Head for target at speed (turning toward it as it goes).
func steer_to(target: Vector3, speed: float) -> void:
	var to := Vector3(target.x - position.x, 0.0, target.z - position.z)
	if to.length() < 0.05:
		velocity = Vector3.ZERO
		return
	velocity = to.normalized() * speed


func _move(delta: float) -> void:
	var hv := Vector2(velocity.x, velocity.z)
	var p := position + Vector3(velocity.x, 0.0, velocity.z) * delta
	if hv.length() > 0.01:
		var n := world.normal_at(p.x, p.z)
		var g := world.height_at(p.x, p.z)
		var blocked := (n.y < max_slope and g > position.y) or (not can_swim and g < 0.2)
		if blocked:
			p = position # too steep or into the water: stay (think() picks again)
			_goal = Vector3.INF
		elif population:
			p = population.push_out(p, radius)
		var want := atan2(-hv.x, -hv.y) # facing -z along the way
		rotation.y = rotate_toward(rotation.y, want, turn_speed * delta)
	p.y = world.height_at(p.x, p.z)
	if can_swim:
		p.y = maxf(p.y, 0.0)
	position = p
