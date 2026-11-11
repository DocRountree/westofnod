extends Node3D
## A tick's egg mass (Ticks.lay): thousands of tiny glossy eggs heaped
## before the female, as she lays them (grow_to: 0..1, her laying);
## hatch(): a swarm of larvae out of it into her colony, the shells left
## pale, fading. Hatches on its own a while after it's laid (HATCH_SECS).
## Drawn at twice life size (the heap about a centimetre across): one
## MultiMesh of beads.

const MM := 0.002
const BEADS := 420
const HATCH_SECS := 90.0
var colony: Node ## (its Ticks)
var yellow := Color(0.55, 0.32, 0.12)
var _mm: MultiMeshInstance3D
var _k := 0.0
var _t := 0.0
var _hatched := false
var _fade := -1.0


func _ready() -> void:
	_mm = MultiMeshInstance3D.new()
	var m := MultiMesh.new()
	m.transform_format = MultiMesh.TRANSFORM_3D
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 6
	s.rings = 4
	m.mesh = s
	m.instance_count = BEADS
	m.visible_instance_count = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(get_instance_id())
	for k in BEADS:
		# (heaped: the first at the bottom, the last on top, a rounded pile)
		var f := float(k) / BEADS
		var r := sqrt(rng.randf()) * (0.9 + 2.6 * sqrt(f)) * MM
		var a := rng.randf() * TAU
		var h := (1.0 - (r / ((0.9 + 2.6 * sqrt(f)) * MM)) * 0.8) * 2.2 * f * MM
		m.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3.ONE * 0.55 * MM * rng.randf_range(0.9, 1.1)), Vector3(cos(a) * r, h + 0.25 * MM, sin(a) * r - 1.2 * f * MM)))
	_mm.multimesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = yellow
	mat.roughness = 0.15
	mat.specular = 0.8
	mat.rim_enabled = true
	mat.rim = 0.4
	_mm.material_override = mat
	add_child(_mm)


## Laid this far (0..1 of all her eggs).
func grow_to(k: float) -> void:
	_k = maxf(_k, k)
	_mm.multimesh.visible_instance_count = int(BEADS * _k)


func hatch() -> void:
	if _hatched or _k <= 0.0:
		return
	_hatched = true
	if is_instance_valid(colony):
		colony.call("hatch_larvae", position, 30 + int(30 * _k))
	var mat := (_mm.material_override as StandardMaterial3D)
	mat.albedo_color = Color(0.85, 0.82, 0.74, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fade = 0.0


func _process(dt: float) -> void:
	_t += dt
	if not _hatched and _k >= 0.99 and _t > HATCH_SECS:
		hatch()
	if _fade >= 0.0:
		_fade += dt
		(_mm.material_override as StandardMaterial3D).albedo_color.a = clampf(1.0 - _fade / 20.0, 0.0, 1.0)
		if _fade > 20.0:
			queue_free()
