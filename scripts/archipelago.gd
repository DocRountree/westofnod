class_name Archipelago
extends RefCounted
## Infinite, deterministic island layout. Each 6.5 km cell holds 0-3 candidate
## islands (often none, sometimes a cluster) with radii spread log-wise from
## 150 m to 3.3 km. A candidate is dropped if a bigger one sits too close, so
## spacing is irregular but islands stay well apart. Plans are built lazily.

const CELL := 6500.0
const MAX_R := 3300.0
const EXTENT := 2.0 # max coast distance from centre, in radii

var seed := 1337
var _cands := {} # Vector2i -> Array[Dictionary]
var _kept := {} # island id -> bool
var _plans := {} # island id -> IslandPlanner


func _candidates(c: Vector2i) -> Array:
	if _cands.has(c):
		return _cands[c]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(c.x, c.y, seed))
	var out := []
	var u := rng.randf()
	var k := 0 if u < 0.25 else (1 if u < 0.62 else (2 if u < 0.88 else 3))
	for i in k:
		var r := 150.0 * pow(22.0, pow(rng.randf(), 1.7))
		var ctr := (Vector2(c) + Vector2(rng.randf(), rng.randf())) * CELL
		out.append({"id": hash(Vector4i(c.x, c.y, i, seed)), "center": ctr, "r": r,
				"prio": r + rng.randf(), "seed": rng.randi(), "cell": c})
	if c == Vector2i.ZERO:
		# A guaranteed medium-large island at the origin to spawn on.
		out.append({"id": hash(Vector4i(0, 0, 99, seed)), "center": Vector2.ZERO, "r": 1500.0,
				"prio": 1e9, "seed": seed * 31 + 7, "cell": c})
	_cands[c] = out
	return out


func _is_kept(isl: Dictionary) -> bool:
	if _kept.has(isl.id):
		return _kept[isl.id]
	var ok := true
	var c: Vector2i = isl.cell
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			for o in _candidates(c + Vector2i(dx, dz)):
				if o.id == isl.id or o.prio <= isl.prio:
					continue
				var need: float = 1.2 * (isl.r + o.r) + 600.0 + 0.25 * (isl.r + o.r)
				if isl.center.distance_to(o.center) < need:
					ok = false
	_kept[isl.id] = ok
	return ok


## Islands whose possible extent intersects rect.
func islands_in(rect: Rect2) -> Array:
	var out := []
	var g := rect.grow(MAX_R * EXTENT)
	var c0 := Vector2i(floori(g.position.x / CELL), floori(g.position.y / CELL))
	var c1 := Vector2i(floori(g.end.x / CELL), floori(g.end.y / CELL))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			for isl in _candidates(Vector2i(cx, cz)):
				var ext: float = isl.r * EXTENT
				var near := Vector2(clampf(isl.center.x, rect.position.x, rect.end.x),
						clampf(isl.center.y, rect.position.y, rect.end.y))
				if near.distance_to(isl.center) < ext and _is_kept(isl):
					out.append(isl)
	return out


func plan(isl: Dictionary) -> IslandPlanner:
	if not _plans.has(isl.id):
		_plans[isl.id] = IslandPlanner.new(isl.center, isl.r, isl.seed).build()
	return _plans[isl.id]
