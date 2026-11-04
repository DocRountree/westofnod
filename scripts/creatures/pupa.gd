class_name Pupa
extends Node3D
## The lepidopterans' pupae, drawn at twice life size, and their hatching
## (eclosion):
## - monarch: the chrysalis, hanging from a black stalk (the cremaster, in
##   a pad of silk) under a leaf or a twig: jade green, plump, a black band
##   round its top edged with gold dots, a few gold dots more. Ripening, it
##   goes dark and clear, the wings' orange and black showing through
## - hemaris: the clearwing's, lying in the litter in a loose cocoon of
##   silk: dark brown, its abdomen ringed, twitching now and then
## eclose(after): it ripens, splits, and the adult comes out (a Monarch, a
## HummingbirdMoth: added to this one's parent), clings to the empty case,
## its wings pumped out to their full size (Lepidoptera.emerge); then
## after.call(adult) (e.g. to send it flying). Cheap: a few spheres.
## Its origin: the monarch's, the stalk's top (hang it from there); the
## clearwing's, the ground under it.

const MM := 0.002
const MONARCH := preload("res://scripts/creatures/monarch.gd")
const MOTH := preload("res://scripts/creatures/hummingbird_moth.gd")

var kind := "monarch"
var adult: Node3D ## once out
var _shell: Array[MeshInstance3D] = []
var _skin: StandardMaterial3D
var _ripe := 0.0
var _state := "" # "", "ripening", "out"
var _t := 0.0
var _twitch := 0.0
var _body: Node3D
var _after := Callable()
static var _sphere: SphereMesh
static var _stick: CylinderMesh


func _init(k := "monarch") -> void:
	kind = k


func _ready() -> void:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 14
		_sphere.rings = 8
		_stick = CylinderMesh.new()
		_stick.top_radius = 0.5
		_stick.bottom_radius = 0.5
		_stick.height = 1.0
		_stick.radial_segments = 5
		_stick.rings = 1
	_body = Node3D.new()
	add_child(_body)
	_skin = StandardMaterial3D.new()
	_skin.roughness = 0.28
	if kind == "monarch":
		_skin.albedo_color = Color(0.36, 0.64, 0.38)
		var black := _plain(Color(0.03, 0.03, 0.03), 0.4)
		var gold := _plain(Color(0.95, 0.75, 0.25), 0.2)
		gold.metallic = 1.0
		# the stalk, then the case hanging from it (mm, life size; down -y)
		_put(_stick, Vector3(0.0, -1.5, 0.0), Vector3(0.8, 3.0, 0.8), black)
		_shell.append(_put(_sphere, Vector3(0.0, -15.5, 0.0), Vector3(11.0, 20.0, 10.0), _skin))
		_shell.append(_put(_sphere, Vector3(0.0, -7.0, 0.0), Vector3(8.0, 8.0, 7.5), _skin))
		_shell.append(_put(_sphere, Vector3(0.0, -24.0, 0.0), Vector3(6.0, 5.0, 5.5), _skin))
		# the black band round its top, gold dots along it, and a few more
		_put(_sphere, Vector3(0.0, -9.6, 0.0), Vector3(9.9, 0.9, 9.3), black)
		for k in 10:
			var a := TAU * k / 10.0
			_put(_sphere, Vector3(cos(a) * 4.95, -9.0, sin(a) * 4.65), Vector3.ONE * 0.75, gold)
		for p in [Vector3(1.8, -21.0, 4.0), Vector3(-1.8, -21.0, 4.0), Vector3(3.6, -16.0, 3.0), Vector3(-3.6, -16.0, 3.0), Vector3(0.0, -6.0, 3.7)]:
			_put(_sphere, p, Vector3.ONE * 0.7, gold)
	else:
		_skin.albedo_color = Color(0.3, 0.18, 0.09)
		# lying along z, the head forward (-z): the case, its tongue's
		# sheath along the front, the abdomen ringed, tapering to its point
		_shell.append(_put(_sphere, Vector3(0.0, 4.0, -3.0), Vector3(8.0, 7.5, 13.0), _skin))
		for k in 4:
			var z := 3.5 + k * 2.6
			var r := 7.2 - k * 1.4
			_shell.append(_put(_sphere, Vector3(0.0, 3.8 - k * 0.3, z), Vector3(r, r * 0.95, 3.4), _skin))
		_put(_sphere, Vector3(0.0, 1.0, -6.0), Vector3(1.6, 1.4, 9.0), _plain(Color(0.24, 0.14, 0.07), 0.3))
		# the cocoon: a loose, pale, see-through bag of silk round it
		var silk := _plain(Color(0.85, 0.82, 0.72, 0.35), 0.9)
		silk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		silk.cull_mode = BaseMaterial3D.CULL_DISABLED
		_put(_sphere, Vector3(0.0, 5.0, 0.0), Vector3(14.0, 11.0, 28.0), silk)


func _put(mesh: Mesh, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = at * MM
	mi.scale = size * MM
	mi.material_override = mat
	_body.add_child(mi)
	return mi


static func _plain(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


## Ripening, splitting, the adult out: see the top.
func eclose(after := Callable()) -> void:
	if _state != "":
		return
	_state = "ripening"
	_t = 0.0
	_after = after


func _process(dt: float) -> void:
	_t += dt
	if _state == "ripening":
		# (the monarch's case going dark and clear, the wings showing)
		_ripe = clampf(_t / 3.0, 0.0, 1.0)
		if kind == "monarch":
			_skin.albedo_color = Color(0.36, 0.64, 0.38).lerp(Color(0.2, 0.1, 0.04), _ripe)
		else:
			_skin.albedo_color = Color(0.3, 0.18, 0.09).lerp(Color(0.18, 0.1, 0.05), _ripe)
		_body.rotation.z = sin(_t * 9.0) * 0.06 * _ripe # (working inside it)
		if _t > 3.0:
			_split()
	elif _state == "":
		# the clearwing's twitching now and then (the monarch's still)
		if kind != "monarch":
			_twitch -= dt
			if _twitch <= 0.0:
				_twitch = randf_range(3.0, 7.0)
			_body.rotation.y = sin((0.6 - _twitch) * 18.0) * 0.08 if _twitch < 0.6 else 0.0


## The case splits, empty (pale, see-through); the adult out of it,
## clinging to it.
func _split() -> void:
	_state = "out"
	_body.rotation = Vector3.ZERO
	_skin.albedo_color = Color(0.85, 0.85, 0.78, 0.45)
	_skin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_skin.cull_mode = BaseMaterial3D.CULL_DISABLED
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var a: Node3D
	var at: Vector3
	var n: Vector3
	var head: Vector3
	if kind == "monarch":
		a = MONARCH.new()
		# clinging to the empty case's side, head up, hanging
		n = (global_transform.basis * Vector3.BACK).normalized()
		at = parent.to_local(global_transform * (Vector3(0.0, -22.0, 6.0) * MM))
		head = Vector3.UP
	else:
		a = MOTH.new()
		# on top of the cocoon, head forward
		n = Vector3.UP
		at = parent.to_local(global_transform * (Vector3(0.0, 10.5, -2.0) * MM))
		head = (global_transform.basis * Vector3.FORWARD).normalized()
	parent.add_child(a)
	a.call("place", at + n * 0.01)
	a.call("emerge", at, n, head, func() -> void:
		if _after.is_valid():
			_after.call(a))
	adult = a
