class_name Archipelago
extends RefCounted
## Infinite, deterministic island layout, in two levels. A very low-frequency
## density field decides where the sea is open and where island chains cluster;
## each 6 km cell then draws 0-4 candidate islands, more where it is dense, with
## radii from a heavy-tailed distribution (150 m islets to 5 km small
## continents). A candidate is dropped if a bigger one sits too close, so the
## spacing ranges from tight clusters to wide open ocean.
##
## Islands are self-contained: each is simulated on its own grid and its
## coastline closes before the edge of that grid. That locality is what makes
## the world infinite (and later lets the layout move onto a sphere).

const CELL := 6000.0
const MIN_R := 140.0
const MAX_R := 5000.0
const LAND_EXTENT := 1.5 # land never reaches beyond this many radii from the centre
const SHELF := 700.0 # sea margin around the land, out to where the sea floor flattens

var seed := 1337
var _density := FastNoiseLite.new()
var _cands := {} # Vector2i -> Array[Dictionary]
var _kept := {} # island id -> bool
var _mutex := Mutex.new()


func _init(s: int = 1337) -> void:
	seed = s
	_density.seed = s
	_density.frequency = 1.0 / 40000.0
	_density.fractal_octaves = 2


## 0 (open ocean) .. 1 (crowded archipelago).
func density(p: Vector2) -> float:
	return clampf(_density.get_noise_2dv(p) * 1.4 + 0.5, 0.0, 1.0)


## Half the side of an island's square simulation domain.
static func half_extent(r: float) -> float:
	return r * LAND_EXTENT + SHELF


func _candidates(c: Vector2i) -> Array:
	if _cands.has(c):
		return _cands[c]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(c.x, c.y, seed))
	var dens := density((Vector2(c) + Vector2(0.5, 0.5)) * CELL)
	# Poisson-ish count: open sea is mostly empty, archipelagos are crowded.
	var lam := 0.15 + 2.6 * dens * dens
	var k := 0
	var p := exp(-lam)
	var cdf := p
	var u := rng.randf()
	while u > cdf and k < 4:
		k += 1
		p *= lam / k
		cdf += p
	var out := []
	for i in k:
		# Heavy tail: mostly islets and small islands, rare large ones, larger in
		# denser regions.
		var t := pow(rng.randf(), 2.2 - 0.9 * dens)
		var r := MIN_R * pow(MAX_R / MIN_R, t)
		var ctr := (Vector2(c) + Vector2(rng.randf(), rng.randf())) * CELL
		out.append({"id": hash(Vector4i(c.x, c.y, i, seed)), "center": ctr, "r": r,
				"prio": r + rng.randf(), "seed": rng.randi(), "cell": c})
	if c == Vector2i.ZERO:
		# A guaranteed medium-large island at the origin to spawn on.
		out = [{"id": hash(Vector4i(0, 0, 99, seed)), "center": Vector2(CELL * 0.5, CELL * 0.5),
				"r": 2200.0, "prio": 1e9, "seed": seed * 31 + 7, "cell": c}]
	_cands[c] = out
	return out


func _is_kept(isl: Dictionary) -> bool:
	if _kept.has(isl.id):
		return _kept[isl.id]
	var ok := true
	var c: Vector2i = isl.cell
	var reach := ceili(2.0 * (MAX_R * LAND_EXTENT + 600.0) / CELL)
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			for o in _candidates(c + Vector2i(dx, dz)):
				if o.id == isl.id or o.prio <= isl.prio:
					continue
				# Land of the two must not touch: keep a channel of open water.
				var need: float = LAND_EXTENT * (isl.r + o.r) + 300.0 + 0.15 * isl.r
				if isl.center.distance_to(o.center) < need:
					ok = false
	_kept[isl.id] = ok
	return ok


## Islands whose simulation domain intersects rect.
func islands_in(rect: Rect2) -> Array:
	_mutex.lock()
	var out := []
	var g := rect.grow(half_extent(MAX_R))
	var c0 := Vector2i(floori(g.position.x / CELL), floori(g.position.y / CELL))
	var c1 := Vector2i(floori(g.end.x / CELL), floori(g.end.y / CELL))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			for isl in _candidates(Vector2i(cx, cz)):
				var he := half_extent(isl.r)
				var dom := Rect2(isl.center - Vector2(he, he), Vector2(2.0 * he, 2.0 * he))
				if dom.intersects(rect) and _is_kept(isl):
					out.append(isl)
	_mutex.unlock()
	return out
