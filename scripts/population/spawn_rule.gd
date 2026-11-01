class_name SpawnRule
extends Resource
## Where a kind of thing grows or lives: how common it is in each biome, and
## the ground it needs. Shared by PropKind (trees, rocks, grass) and ActorKind
## (NPCs, animals).

## Biome name -> how common: props per hectare (PropKind), groups per square
## kilometre (ActorKind). "*" is every biome not named; "" is land with no
## biome. Biome names: WorldData.biome_names (forest, mesa, prairie, swamp,
## tundra, taiga, plateau, volcano, mountains, island, coast).
@export var density := {}
## Ground height range (m above sea level).
@export var height_range := Vector2(0.5, 10000.0)
## The steepest ground: the least surface normal y (1 flat, 0 a wall).
@export_range(-1.0, 1.0) var min_normal_y := 0.7

var _by_biome := PackedFloat32Array() # density by biome index; the last entry is "no biome"
var _peak := 0.0


## Resolves the names to biome indices (Population does this before use).
func resolve(names: Array) -> void:
	_by_biome.resize(names.size() + 1)
	var fallback := float(density.get("*", 0.0))
	for i in names.size():
		_by_biome[i] = float(density.get(names[i], fallback))
	_by_biome[names.size()] = float(density.get("", fallback))
	_peak = 0.0
	for d in _by_biome:
		_peak = maxf(_peak, d)


## Density in biome b (-1: none). resolve() first.
func density_in(b: int) -> float:
	return _by_biome[b if b >= 0 else _by_biome.size() - 1]


## The highest density in any biome. resolve() first.
func peak() -> float:
	return _peak


## Can it stand here (height h, ground normal n)?
func fits(h: float, n: Vector3) -> bool:
	return h >= height_range.x and h <= height_range.y and n.y >= min_normal_y
