class_name MapleSeeds
extends Node
## Maple seeds (the sugar maple's samaras: "helicopters") falling from the
## grown maples near the player: those within OakTree.LOD[1] of it (drawn at
## their two most detailed levels). One now and then, about every
## MEAN_INTERVAL seconds among all of them (four times as often as the
## meteors at night: Meteors.mean_interval), day or night: from somewhere in a
## tree's crown, a moment tumbling, then spinning down, its wing out and
## coned up a little, round the seed at its root, drifting a little on the
## air, about a metre a second. Gone where it reaches the ground (the
## ground's height under where it started, taken once: nothing's hit).
## Cheap: a few at most in the air at once, each one small mesh.

const MEAN_INTERVAL := 6.25 ## s between seeds, on average (four times the meteors at night: Meteors.mean_interval 25)
const MATURE := [0, 1, 2, 3] ## MapleTree's standing grown trees (not its stumps, logs, dead or saplings)
const RECHECK := 2.0 ## s between looking for the maples near
const FALL := 0.95 ## m/s, spinning down
const SPIN := 8.0 ## turns a second
const MOST := 12

var main: Node ## (main.gd: its population, its world, its player)
var _trees: Array = []
var _recheck := 0.0
var _seeds: Array = [] # each {node, v (m/s), t, ground, phase, drift, tumble}
var _rng := RandomNumberGenerator.new()
static var _mesh: ArrayMesh


func _ready() -> void:
	_rng.randomize()


func _process(dt: float) -> void:
	if main == null or main.player == null or main.population == null or Origin.root == null:
		return
	var at := Origin.map(main.player.global_position)
	_recheck -= dt
	if _recheck <= 0.0:
		_recheck = RECHECK
		_trees = main.population.trees_near(at, float(OakTree.LOD[1]), MapleTree, MATURE)
	if not _trees.is_empty() and _seeds.size() < MOST and _rng.randf() < dt / MEAN_INTERVAL:
		_drop(_trees[_rng.randi() % _trees.size()])
	for k in range(_seeds.size() - 1, -1, -1):
		var s: Dictionary = _seeds[k]
		var n: Node3D = s.node
		s.t = float(s.t) + dt
		var p: Vector3 = s.p
		var v: Vector3 = s.v
		var tumble := clampf(1.0 - float(s.t) / 0.6, 0.0, 1.0) # (its first moment: tumbling, then spinning)
		var want := Vector3(s.drift.x, -FALL, s.drift.z)
		v = v.lerp(want, 1.0 - exp(-(2.5 + 6.0 * (1.0 - tumble)) * dt)) + Vector3.DOWN * 9.8 * tumble * dt
		p += v * dt
		s.v = v
		s.p = p
		var spin := float(s.phase) + TAU * SPIN * dt * (1.0 - tumble * 0.8)
		s.phase = spin
		# (round the seed at its root, the wing out flat and coned up a little;
		# tumbling, end over end at first)
		var b := Basis(Vector3.UP, spin) * Basis(Vector3.BACK, 0.22 + tumble * float(s.t) * 25.0) * Basis(Vector3.RIGHT, 0.35)
		n.transform = Transform3D(b, p + Basis(Vector3.UP, spin) * Vector3(-0.006, 0.0, 0.0))
		if p.y <= float(s.ground) or float(s.t) > 90.0:
			n.queue_free()
			_seeds.remove_at(k)


## A seed off a tree ({transform, variant}): from somewhere in its crown.
func _drop(tree: Dictionary) -> void:
	var xf: Transform3D = tree.transform
	var crown: Array = (MapleTree.VARIANTS[int(tree.variant)] as Dictionary).crown # [radius, top, bottom]
	var a := _rng.randf() * TAU
	var r := float(crown[0]) * _rng.randf_range(0.4, 0.9)
	var h := lerpf(float(crown[2]), float(crown[1]), _rng.randf_range(0.25, 0.75))
	var p := xf * Vector3(cos(a) * r, h, sin(a) * r)
	var g := float(main.world.height_at(p.x, p.z)) if main.world else 0.0
	if p.y <= g + 0.5:
		return
	var n := MeshInstance3D.new()
	n.mesh = _samara()
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Origin.root.add_child(n)
	var d := _rng.randf() * TAU
	_seeds.append({"node": n, "p": p, "v": Vector3.ZERO, "t": 0.0, "ground": g, "phase": _rng.randf() * TAU,
			"drift": Vector3(cos(d), 0.0, sin(d)) * _rng.randf_range(0.05, 0.35)})


## A samara, life size (3.5 cm): one curved card through its length, its
## outline, its colours and its veins painted (_paint): at its root the
## seed, a plump teardrop, netted, browner at its base; out of it the wing,
## its thick leading edge running along one side, straight-ish, the wing
## broadening to a rounded paddle at its tip, its trailing edge bowed; the
## membrane pale greenish cream, thin, the light through it, its veins
## sweeping out from the leading edge back across it, forking. Cupped a
## little across, bent a little along. Along +x from the seed (at the
## origin), the leading edge -z.
const LEN := 0.036
const WID := 0.014


static func _samara() -> ArrayMesh:
	if _mesh:
		return _mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const NU := 10
	const NV := 4
	var vert := func(i: int, k: int) -> Array:
		var u := float(i) / NU
		var v := float(k) / NV
		var z := (v - 0.5) * WID
		var y := 0.0012 * (1.0 - pow((v - 0.5) * 2.0, 2.0)) + 0.002 * sin(PI * u) # (cupped across, bowed along)
		var p := Vector3(u * LEN, y, z + 0.0035 * u * u) # (its whole length curving back a little)
		return [p, Vector2(u, v)]
	for i in NU:
		for k in NV:
			var q := [vert.call(i, k), vert.call(i + 1, k), vert.call(i + 1, k + 1), vert.call(i, k + 1)]
			for t: Array in [[0, 2, 1], [0, 3, 2]]:
				for j: int in t:
					st.set_normal(Vector3.UP)
					st.set_uv(q[j][1])
					st.add_vertex(q[j][0])
	st.generate_normals()
	var m := StandardMaterial3D.new()
	m.albedo_texture = _paint()
	m.alpha_scissor_threshold = 0.5
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.75
	m.backlight_enabled = true # (thin: the light through it)
	m.backlight = Color(0.55, 0.5, 0.32)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mesh = st.commit()
	_mesh.surface_set_material(0, m)
	return _mesh


## (Its painting: u along it (0 the seed's base .. 1 the wing's tip), v
## across (0 the leading edge's side); alpha its outline.)
static func _paint() -> ImageTexture:
	const W := 64
	const H := 256
	var img := Image.create(H, W, false, Image.FORMAT_RGBA8)
	var membrane := Color(0.8, 0.8, 0.64)
	var vein := Color(0.66, 0.6, 0.4)
	var edge := Color(0.6, 0.53, 0.34)
	var seed := Color(0.72, 0.62, 0.42)
	var base := Color(0.45, 0.33, 0.18)
	for x in H:
		var u := (float(x) + 0.5) / H
		# its edges across it (v): the leading edge near one side, straight,
		# coming in a little at the tip; the trailing edge bowed out, the
		# wing broadening from the seed to a rounded tip
		var lead := 0.22 - 0.1 * u + 0.25 * pow(maxf(u - 0.85, 0.0) / 0.15, 2.0)
		var seed_w := 0.34 * pow(sin(PI * clampf(u / 0.42, 0.0, 1.0)), 0.6) # (the seed's swell)
		var wing_w := 0.24 + 0.54 * smoothstep(0.22, 0.72, u) if u > 0.2 else 0.0
		var trail := lead + maxf(seed_w, wing_w)
		if u > 0.82: # (its tip rounded)
			var f := (u - 0.82) / 0.18
			trail = lerpf(trail, lead + 0.02, f * f * f)
		if u < 0.04: # (its base: the stalk's scar, a point)
			trail = lead + (trail - lead) * u / 0.04
		for y in W:
			var v := (float(y) + 0.5) / W
			var a := 1.0 if v > lead and v < trail else 0.0
			var c := membrane
			var into := (v - lead) / maxf(trail - lead, 1e-3)
			# the seed: netted, browner toward its base
			var in_seed := (1.0 - smoothstep(0.28, 0.38, u)) * (1.0 - smoothstep(0.75, 1.0, into))
			var net := absf(sin(u * 70.0 + sin(v * 40.0) * 1.5)) * absf(sin(v * 55.0 - u * 20.0))
			var sc := seed.lerp(base, 1.0 - smoothstep(0.02, 0.2, u)).darkened(0.15 * smoothstep(0.85, 1.0, 1.0 - net))
			c = c.lerp(sc, in_seed)
			# the veins: out from the leading edge, sweeping back across, forking
			var q := u * 30.0 - into * 9.0 + 0.6 * sin(into * 7.0 + u * 11.0)
			var vn := 1.0 - smoothstep(0.05, 0.13, absf(fposmod(q, 1.0) - 0.5))
			c = c.lerp(vein, vn * 0.8 * (1.0 - in_seed))
			c = c.lerp(membrane.lightened(0.08), (1.0 - vn) * 0.3 * (0.5 + 0.5 * sin(u * 300.0 + v * 170.0)) * (1.0 - in_seed)) # (the membrane between, crinkled)
			# the leading edge: thick, darker, along its side
			c = c.lerp(edge, (1.0 - smoothstep(0.0, 0.16, into)) * smoothstep(0.15, 0.3, u))
			c = c.darkened(0.25 * (1.0 - smoothstep(0.0, 0.06, minf(into, 1.0 - into)))) # (its rim)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
