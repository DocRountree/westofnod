class_name Brood
extends RefCounted
## Eggs, of every creature so far: rice grains, each kind its own size and
## colour (drawn at twice life size, as the adults are), lying on their
## sides or stood on end; each can hatch (egg.gd: the larva out, small,
## growing up). Brood.egg(kind) -> the egg (a Node3D, its origin where it
## touches; .hatch(after)).

const EggScript := preload("res://scripts/creatures/egg.gd")
const EGGS := EggScript.EGGS


## An egg of kind (EGGS').
static func egg(kind: String) -> Node3D:
	return EggScript.new(kind)
