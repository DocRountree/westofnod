class_name Brood
extends RefCounted
## Eggs, of every creature so far: rice grains, each kind its own size and
## colour (drawn at twice life size, as the adults are), lying on their
## sides or stood on end. One mesh and one material per kind, shared.
## Brood.egg(kind) -> a Node3D, its origin where it touches.

const MM := 0.002 ## m drawn per mm (twice life size)
## kind: [length, width (mm), colour, stood on end]
const EGGS := {
	"wasp": [1.5, 0.55, Color(0.93, 0.92, 0.86), false], # (a paper wasp's: one at the bottom of each cell)
	"carpenter": [0.9, 0.45, Color(0.95, 0.94, 0.9), false], # (the queen's, in a pile)
	"harvester": [0.6, 0.35, Color(0.95, 0.93, 0.88), false],
	"june": [2.6, 2.0, Color(0.92, 0.9, 0.84), false], # (pearly, round, in the soil)
	"lady": [1.2, 0.5, Color(0.98, 0.72, 0.12), true], # (yellow-orange, stood on end in clusters)
	"monarch": [1.2, 0.9, Color(0.93, 0.9, 0.74), true], # (cream, one to a leaf, its underside)
	"hemaris": [1.0, 0.9, Color(0.72, 0.85, 0.6), false], # (glassy pale green, one at a time)
}

static var _meshes := {}
static var _mats := {}


## An egg of kind (EGGS'), its origin where it touches what it's laid on
## (its own up: away from that).
static func egg(kind: String) -> Node3D:
	var e: Array = EGGS[kind]
	if not _meshes.has(kind):
		var m := CapsuleMesh.new()
		var l: float = e[0]
		var w: float = e[1]
		m.radius = w * 0.5 * MM
		m.height = maxf(l, w) * MM
		m.radial_segments = 10
		m.rings = 3
		_meshes[kind] = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = e[2]
		mat.roughness = 0.35
		mat.rim_enabled = true # (a pearly sheen)
		mat.rim = 0.3
		_mats[kind] = mat
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[kind]
	mi.material_override = _mats[kind]
	var l2: float = e[0]
	var w2: float = e[1]
	if e[3]: # (stood on end: the capsule's along y)
		mi.position = Vector3(0.0, maxf(l2, w2) * 0.5 * MM, 0.0)
	else: # (lying: turned onto its side)
		mi.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		mi.position = Vector3(0.0, w2 * 0.5 * MM, 0.0)
	var root := Node3D.new()
	root.add_child(mi)
	return root as Node3D
