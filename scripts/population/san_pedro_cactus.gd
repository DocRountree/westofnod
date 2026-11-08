class_name SanPedroCactus
extends RefCounted
## The San Pedro cactus (Echinopsis pachanoi), built whole (PlantMesh), life
## size, four variants: a big clump (seven stems, to about 3.5 m), a
## smaller one (four), a young single stem, and a clump in flower. In the mesa country, not up on the
## plateau: data/population/props/san_pedro.tres; the sandbox's trees and bushes
## (tools/creatures/ecology_demo.gd).
##
## What makes it read as San Pedro: columns rising from the base, the outer
## ones leaning out and curving up, each a hand across, smooth, frosted blue
## green; six to eight broad, rounded ribs, the grooves between them
## narrow; along each rib's crest the areoles every few cm, little cushions
## of white felt in a notch, each with a few short brownish spines (or
## none); the stems pinched a little where each year's growth began; the
## tips domed, paler, new; the oldest stems corky grey brown at their foot;
## the flowers huge, white, funnel shaped, on long dark hairy tubes from
## near the tips (at night).

const PM := preload("res://scripts/population/plant_mesh.gd") # (by path: found whether or not the editor has seen the class yet)

const VARIANTS := [
	{"stems": 7, "height": 3.4, "r": 0.075, "ribs": 7, "seed": 801},
	{"stems": 4, "height": 2.1, "r": 0.065, "ribs": 6, "seed": 823},
	{"stems": 1, "height": 0.75, "r": 0.055, "ribs": 6, "seed": 839},
	{"stems": 5, "height": 2.6, "r": 0.07, "ribs": 7, "seed": 857, "flowers": 4},
]

const SKIN := Color(0.33, 0.5, 0.42)
const NEW := Color(0.45, 0.6, 0.36)
const CORK := Color(0.5, 0.44, 0.36)
const FELT := Color(0.88, 0.86, 0.8)
const SPINE := Color(0.6, 0.46, 0.25)
const SPINE_TIP := Color(0.32, 0.22, 0.12)

static var _cache := {}


static func build(variant := 0) -> Mesh:
	return build_lods(variant)[0]


## Its levels of detail: whole; no spines, fewer areoles; the far one
## (fewer sides, no areoles).
static func build_lods(variant := 0) -> Array[Mesh]:
	if not _cache.has(variant):
		var lods: Array[Mesh] = []
		for lod in 3:
			lods.append(_make(VARIANTS[variant], lod))
		_cache[variant] = lods
	return _cache[variant]


static func _make(V: Dictionary, lod: int) -> Mesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(V.seed)
	var skin := PM.begin()
	var bits := PM.begin()
	var flowers := PM.begin()
	var n: int = V.stems
	var H: float = V.height
	var ribs: int = V.ribs
	var tips := []
	for s in n:
		# (the middle one straight up, the rest round it leaning out, then
		# curving up; shorter the further out)
		var out := 0.0 if s == 0 else rng.randf_range(0.3, 0.6)
		var a := TAU * float(s) / maxf(n - 1, 1) + rng.randf_range(-0.3, 0.3)
		var base := Vector3(cos(a), 0.0, sin(a)) * (0.0 if s == 0 else rng.randf_range(0.05, 0.12))
		var dir := Vector3(cos(a) * sin(out), cos(out), sin(a) * sin(out)).normalized()
		var h := H * (1.0 if s == 0 else rng.randf_range(0.55, 0.95))
		var r := float(V.r) * rng.randf_range(0.88, 1.08)
		var pts := []
		var radii := []
		var p := base
		var step := 0.05
		var count := int(h / step)
		var pinch := rng.randf_range(0.4, 0.6) # (where a year's growth began)
		for i in count + 1:
			pts.append(p)
			var z := float(i) * step
			var squeeze := 1.0 - 0.07 * exp(-pow(fmod(z, pinch) / 0.04 - 0.5, 2.0))
			radii.append(r * squeeze * (1.08 if i == 0 else 1.0))
			dir = dir.lerp(Vector3.UP, 0.05).normalized()
			p += dir * step
		var sides: int = [ribs * 6, ribs * 4, ribs * 2][lod]
		var count_f := float(count)
		var paint := func(i: int, _ang: float, g: float) -> Color:
			var up := float(i) / count_f
			var c := SKIN.lerp(NEW, smoothstep(0.88, 1.0, up)) # (the new growth at its tip)
			c = c.lerp(CORK, 1.0 - smoothstep(0.0, 0.36 / maxf(h, 0.1), up)) # (its corky foot)
			return c * (1.0 - 0.28 * g)
		PM.tube(skin, pts, radii, sides, paint, {"n": ribs, "depth": 0.13, "sharp": 0.45}, 0.07)
		# the areoles along each rib's crest, felted, their few spines
		if lod < 2:
			var gap := 0.03 if lod == 0 else 0.06
			var right := Vector3.ZERO
			var walked := 0.0
			var next := gap * 0.5
			for i in range(1, pts.size()):
				var q0: Vector3 = pts[i - 1]
				var q1: Vector3 = pts[i]
				var d := (q1 - q0).normalized()
				right = PM._carry(right if i > 1 else Vector3.ZERO, d)
				var upv := d.cross(right).normalized()
				walked += step
				if walked < next:
					continue
				next += gap
				var R: float = radii[i]
				var left := h - walked
				if left < 0.07:
					R *= sqrt(maxf(1.0 - pow(1.0 - left / 0.07, 2.0), 0.0))
				for k in ribs:
					var ang := TAU * float(k) / ribs # (on the crest)
					var o := right * cos(ang) + upv * sin(ang)
					var at := q1 + o * R
					PM.blob(bits, at, Basis(o * 0.003, d * 0.005, o.cross(d) * 0.004), FELT, 5, 3)
					if lod == 0:
						var sp := rng.randi_range(0, 4)
						for m in sp:
							var sd := (o + d * rng.randf_range(-0.6, 0.6) + o.cross(d) * rng.randf_range(-0.7, 0.7)).normalized()
							PM.spine(bits, at, sd, rng.randf_range(0.006, 0.018), 0.0006, SPINE, SPINE_TIP)
		tips.append([pts[pts.size() - 1], dir, r])
	# flowers, near the tips: on long dark tubes, the white funnel opening
	var nf := int(V.get("flowers", 0))
	for f in mini(nf, tips.size()):
		var t: Array = tips[f]
		var tip: Vector3 = t[0]
		var dir: Vector3 = t[1]
		var r: float = t[2]
		var out := dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD).normalized().rotated(dir, rng.randf() * TAU)
		var foot := tip - dir * rng.randf_range(0.08, 0.25) + out * r
		var way := (out * 0.7 + dir * 0.7).normalized()
		var mouth := foot + way * 0.14
		PM.tube(flowers, [foot, foot + way * 0.07, mouth], [0.012, 0.016, 0.03], 8, func(_i: int, _a: float, _g: float) -> Color:
			return Color(0.25, 0.28, 0.18))
		var a := way.cross(Vector3.UP if absf(way.y) < 0.9 else Vector3.RIGHT).normalized()
		var b := way.cross(a)
		for k in 18: # (the petals: two rings, the outer greener)
			var ring := k % 2
			var ang := TAU * float(k) / 18.0
			var pd := ((a * cos(ang) + b * sin(ang)) * (0.8 + 0.25 * ring) + way * (0.75 - 0.3 * ring)).normalized()
			var col := Color(0.97, 0.97, 0.94) if ring == 0 else Color(0.88, 0.9, 0.8)
			PM.blade(flowers, mouth, pd, way, 0.075, 0.035, 0.003, col, col, false)
		PM.blob(flowers, mouth + way * 0.01, Basis().scaled(Vector3.ONE * 0.012), Color(0.92, 0.88, 0.55), 6, 4)
	var parts := [[skin, PM.painted(0.48, 0.25)], [bits, PM.painted(0.85)]]
	if nf > 0:
		parts.append([flowers, PM.painted(0.6, 0.1, false)])
	return PM.finish(parts)
