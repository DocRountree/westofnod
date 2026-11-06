class_name Molt
extends Node3D
## A nymph's moult to grown (one moult, here: a real one takes several): it
## stops and grips where it is, its body swelling and easing as it works for
## a few seconds; its skin splits along its back and the adult works its way
## out of it, head and thorax first, nose up, drawn up and forward out of
## the old skin till its legs come free; soft and small at first, its body
## and wings swelling out to their full size as it walks off. The cast skin
## (the exuvia) is left where it was, pale, papery, see-through, a while.
##
##   Molt.begin(nymph, after)   # after.call(adult), once it's out
##
## The nymph's own script makes the adult (Script.new(false, 1.0): a
## Grasshopper's, a Mantis's, any hexapod's that has a nymph).

const SWELL := 2.5 ## s working, still, before the skin splits
const OUT := 3.5 ## s working its way out
const EXUVIA_SECS := 120.0 ## s the cast skin's left there
const GROW_SECS := 8.0 ## s the adult takes to swell to its full size

var nymph: Node3D
var adult: Node3D
var after := Callable()
var _t := 0.0
var _from := Transform3D()
var _len := 0.05
var _done := false
static var _skin_mat: StandardMaterial3D


## The moult begun (null, if it's no nymph).
static func begin(n: Node3D, after_ := Callable()) -> Node3D:
	if n == null or not is_instance_valid(n) or n.get("nymph") != true or n.get_parent() == null:
		return null
	var m: Node3D = load("res://scripts/creatures/molt.gd").new()
	m.set("nymph", n)
	m.set("after", after_)
	n.get_parent().add_child(m)
	m.top_level = true
	m.global_transform = Transform3D.IDENTITY
	m.process_priority = 1000 # (after the adult's placed itself: drawn back into its old skin from there)
	m.call("_start")
	return m


func _start() -> void:
	nymph.set_process(false) # (still, gripping)
	_from = nymph.global_transform
	var d: Vector2 = load("res://scripts/creatures/personal_space.gd")._dims(nymph)
	_len = d.x if d.x > 0.0 else 0.05


func _process(dt: float) -> void:
	_t += dt
	if _t < SWELL:
		if is_instance_valid(nymph): # (working: swelling and easing, a little more each time)
			var k := sin(_t * 5.0) * 0.035 * minf(_t, 1.0)
			nymph.global_transform = _from * Transform3D(Basis.from_scale(Vector3(1.0 + k, 1.0 + k * 1.4, 1.0 - k * 0.4)), Vector3.ZERO)
		return
	if adult == null and not _done:
		_split()
	var k := clampf((_t - SWELL) / OUT, 0.0, 1.0)
	if is_instance_valid(adult) and k < 1.0:
		# (still part in its old skin: drawn back into it, nose up, coming
		# up and forward out of it)
		var off := 1.0 - smoothstep(0.0, 1.0, k)
		var g := adult.global_transform
		var right := g.basis.x.normalized()
		var back := g.basis.z.normalized()
		adult.global_transform = Transform3D(g.basis.rotated(right, 0.7 * off), g.origin + back * _len * 0.45 * off + Vector3.UP * _len * 0.18 * off)
	if k >= 1.0 and not _done:
		_done = true
		if is_instance_valid(adult):
			adult.call("grow", 1.0, GROW_SECS * 0.6)
			if after.is_valid():
				after.call(adult)
	if _t > SWELL + OUT + EXUVIA_SECS:
		queue_free()


## The skin split: left where it was, pale and empty; the adult in it.
func _split() -> void:
	if not is_instance_valid(nymph):
		_done = true
		return
	nymph.global_transform = _from
	var skin := Node3D.new()
	skin.name = "exuvia"
	add_child(skin)
	if _skin_mat == null:
		_skin_mat = StandardMaterial3D.new()
		_skin_mat.albedo_color = Color(0.8, 0.72, 0.52, 0.55)
		_skin_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_skin_mat.roughness = 0.55
		_skin_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mi: MeshInstance3D in _meshes(nymph):
		var c := MeshInstance3D.new()
		c.mesh = mi.mesh
		c.material_override = _skin_mat
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		skin.add_child(c)
		c.global_transform = mi.global_transform
	# the adult, its own kind's, in its place
	var sc: Script = nymph.get_script()
	adult = sc.new(false, 1.0)
	var pos: Vector3 = nymph.get("_pos")
	var yaw: float = nymph.get("_yaw")
	var h = nymph.get("height")
	if h is Callable:
		adult.set("height", h)
	nymph.get_parent().add_child(adult)
	adult.call("place", pos, yaw)
	adult.set("size", minf(float(nymph.get("size")) * 1.15, 1.0)) # (soft, small: swelling out to full size)
	adult.call("grow", minf(float(nymph.get("size")) * 1.4, 1.0), OUT)
	nymph.queue_free()


static func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for c in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and (c as MeshInstance3D).is_visible_in_tree():
			out.append(c)
		out.append_array(_meshes(c))
	return out
