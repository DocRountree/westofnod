extends Node3D
## An egg (Brood.egg(kind)): a rice grain, its kind's size and colour
## (EGGS), its origin where it touches what it's laid on. hatch(after):
## it rocks a moment (the larva working inside), then the larva's out
## (Larva: a hatchling, small, growing to full size over a minute or so):
## a caterpillar turns and eats its shell, as monarch and hawk moth
## caterpillars do, then crawls off; any other's shell collapses, goes
## pale and fades; after.call(larva). Cheap: one shared mesh and material
## per kind till it hatches.

const MM := 0.002 ## m drawn per mm (twice life size)
const LarvaScript := preload("res://scripts/creatures/larva.gd")
## kind: [length, width (mm), colour, stood on end]
const EGGS := {
	"wasp": [6.0, 4.9, Color(0.93, 0.92, 0.86), false], # (a paper wasp's: one to a cell, filling it)
	"carpenter": [0.9, 0.45, Color(0.95, 0.94, 0.9), false], # (the queen's, in a pile)
	"harvester": [0.6, 0.35, Color(0.95, 0.93, 0.88), false],
	"june": [2.6, 2.0, Color(0.92, 0.9, 0.84), false], # (pearly, round, in the soil)
	"lady": [1.2, 0.5, Color(0.98, 0.72, 0.12), true], # (yellow-orange, stood on end in clusters)
	"monarch": [1.2, 0.9, Color(0.93, 0.9, 0.74), true], # (cream, one to a leaf)
	"hemaris": [1.0, 0.9, Color(0.72, 0.85, 0.6), false], # (glassy pale green, one at a time)
	"swallowtail": [1.0, 1.0, Color(0.96, 0.86, 0.38), false], # (a yellow pearl, one to a leaf)
	"luna": [1.8, 1.5, Color(0.86, 0.82, 0.68), false], # (big, whitish, flecked brown, a few to a leaf)
	"grasshopper": [4.5, 1.1, Color(0.8, 0.66, 0.4), true], # (tan, long, packed upright in a pod in the soil: Grasshopper.Pod)
}
## kind: the hatchling's size (a share of full grown), seconds to grow up
const HATCHLING := {
	"wasp": [0.25, 60.0], "carpenter": [0.35, 50.0], "harvester": [0.35, 50.0], "june": [0.25, 80.0],
	"lady": [0.25, 50.0], "monarch": [0.12, 90.0], "hemaris": [0.12, 90.0],
	"swallowtail": [0.12, 90.0], "luna": [0.1, 100.0],
}

static var _meshes := {}
static var _mats := {}

var kind := "wasp"
var larva: Node3D ## once out
var _rock: Node3D
var _shell: MeshInstance3D
var _state := ""
var _t := 0.0
var _after := Callable()
var _shell_scale := Vector3.ONE
var _meal: Node3D # (its shell, eaten by its caterpillar: Meal)


func _init(k := "wasp") -> void:
	kind = k
	var e: Array = EGGS[k]
	var l: float = e[0]
	var w: float = e[1]
	if not _meshes.has(k):
		var m := CapsuleMesh.new()
		m.radius = w * 0.5 * MM
		m.height = maxf(l, w) * MM
		m.radial_segments = 10
		m.rings = 3
		_meshes[k] = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = e[2]
		mat.roughness = 0.35
		mat.rim_enabled = true # (a pearly sheen)
		mat.rim = 0.3
		_mats[k] = mat
	_rock = Node3D.new()
	add_child(_rock)
	_shell = MeshInstance3D.new()
	_shell.mesh = _meshes[k]
	_shell.material_override = _mats[k]
	if e[3]: # (stood on end: the capsule's along y)
		_shell.position = Vector3(0.0, maxf(l, w) * 0.5 * MM, 0.0)
	else: # (lying: turned onto its side)
		_shell.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		_shell.position = Vector3(0.0, w * 0.5 * MM, 0.0)
	_rock.add_child(_shell)


## Hatching: see the top.
func hatch(after := Callable()) -> void:
	if _state != "":
		return
	_state = "rocking"
	_t = 0.0
	_after = after


func _process(dt: float) -> void:
	if _state == "":
		return
	_t += dt
	match _state:
		"rocking": # (the larva working inside)
			_rock.rotation = Vector3(0.0, 0.0, sin(_t * 14.0) * 0.12 * minf(_t, 1.0))
			if _t > 1.6:
				_out()
		"eaten": # (the caterpillar eating its shell, bit by bit, into its mouth)
			if is_instance_valid(larva):
				if _meal == null:
					_meal = load("res://scripts/creatures/meal.gd").of(_shell, 3, 0)
				var head: Node3D = larva.get("_head")
				if _meal and head:
					_meal.call("tear", clampf((_t - 0.3) / 2.8, 0.0, 1.0), head.global_position)
			if _t > 4.0:
				if is_instance_valid(larva): # (and on to the leaf it's on: feeding where it is)
					larva.call("eat")
				queue_free()
		"empty": # (the shell collapsed, pale, fading)
			var m := _shell.material_override as StandardMaterial3D
			m.albedo_color.a = clampf(1.0 - (_t - 2.0) / 5.0, 0.0, 1.0)
			if _t > 7.0:
				queue_free()


func _out() -> void:
	_rock.rotation = Vector3.ZERO
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var h: Array = HATCHLING[kind]
	var lv := LarvaScript.new(kind, h[0])
	parent.add_child(lv)
	larva = lv
	var at := parent.to_local(global_position)
	var facing := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	var crawler: bool = LarvaScript.KINDS[kind].style == "crawl"
	if kind in ["monarch", "hemaris", "swallowtail", "luna"]:
		# beside its shell, turned to it, eating it
		lv.place(at - facing * float(LarvaScript.KINDS[kind].len) * MM * h[0] * 0.15, facing)
		lv.eat()
		_state = "eaten"
	else:
		lv.place(at, facing)
		if crawler:
			lv.wander(at, 0.03)
		_state = "empty"
		var m := (_shell.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = Color(0.9, 0.9, 0.86, 1.0)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shell.material_override = m
		_shell.scale = Vector3(1.0, 0.6, 1.0)
	_shell_scale = _shell.scale
	lv.grow(1.0, h[1])
	_t = 0.0
	if _after.is_valid():
		_after.call(lv)
