class_name ActorKind
extends SpawnRule
## A kind of NPC or animal. Population spawns groups of them in the chunks
## near the player (density: groups per square kilometre), the same groups in
## the same places each time, and frees them when the player is far away. Save
## one as a .tres in data/population/actors/ (or Population.register_actor()).

@export var id: StringName
## The actor: a scene whose root is an Actor (or extends it). With none, a
## plain Actor (no body: for testing behaviour).
@export var scene: PackedScene
@export var group_size := Vector2i(1, 1) ## Members per group, at random in this range.
@export var group_spread := 6.0 ## Metres the members of a group start apart.
## Persistent actors (named NPCs) are not freed with their chunk; they keep
## their state and go on living where they are.
@export var persistent := false
