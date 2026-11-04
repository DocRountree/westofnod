class_name Beetles
extends AntColony
## Beetles: dogbane leaf beetles (Chrysochus auratus), drawn at twice life
## size as the ants and the wasp are (about 20 mm long): a domed oval, its
## wing cases and pronotum shining metallic green, glinting copper and gold
## at a glance; its head small, tucked under the pronotum's front; short,
## beaded antennae; stout, short legs, blue-black. Made and moved as the
## ants are (AntColony: one mesh, every beetle an instance, posed by the
## same shader, ant.gdshader), slower and heavier, its antennae sweeping
## less: walking (a tripod gait), and eating (feed: at a leaf, its head down
## to it, mandibles working, its front legs on it; now and then round to
## another place at it). wander(i, centre, radius), feed(i, leaf).


func _init() -> void:
	body_h = 1.6
	top_speed = 0.03 # (a leaf beetle's 1.5 cm/s, twice life size)
	reach = 5.0
	apart = 12.0
	colors = {
		"black": Color(0.05, 0.06, 0.09), # (its underside, blue-black)
		"leg_color": Color(0.06, 0.07, 0.11),
		"shell_a": Color(0.12, 0.5, 0.33), # (green, facing you)
		"shell_b": Color(0.85, 0.48, 0.14), # (copper and gold at a glance)
		"stride_hz": 5.0,
		"sweep": 0.4,
	}


# the legs, the right side's (the left's mirrored): hip, femur, tibia,
# tarsus (mm), home (the foot at rest: x, z): short and stout, the feet
# splayed each into its own part of the round
const B_LEGS := [
	{"hip": Vector3(0.55, -0.75, -1.6), "f": 1.9, "t": 1.8, "s": 1.5, "home": Vector2(3.0, -3.6)},
	{"hip": Vector3(0.8, -0.8, -0.2), "f": 2.0, "t": 1.9, "s": 1.6, "home": Vector2(4.0, 0.3)},
	{"hip": Vector3(1.0, -0.8, 0.8), "f": 2.3, "t": 2.3, "s": 1.9, "home": Vector2(3.8, 3.6)},
]
const B_HEAD := Vector3(0.0, 0.0, -2.55) ## the neck (where the head turns)


## The beetle at rest, standing (in metres), as the ant's (the same parts
## for the shader): [mesh, pivots].
func _build_mesh() -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 16
	sphere.rings = 9
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	var S := sphere.get_mesh_arrays()
	var C := cyl.get_mesh_arrays()
	var ball := func(at: Vector3, size: Vector3, part: int, b := Basis()) -> void:
		_add(st, S, Transform3D(b * Basis.from_scale(size), at), part, 0, false)
	var stick := func(a: Vector3, b: Vector3, r: float, part: int, seg := 0) -> void:
		_add(st, C, _seg(a, b, r), part, seg, false)
	# the underside, and over it the shell: the pronotum, and the two wing
	# cases meeting down its middle, domed
	ball.call(Vector3(0.0, -0.35, 0.9), Vector3(3.9, 1.5, 6.2), 0)
	ball.call(Vector3(0.0, 0.25, -1.45), Vector3(3.8, 1.9, 2.3), 16)
	for side: float in [-1.0, 1.0]:
		ball.call(Vector3(1.0 * side, 0.45, 1.45), Vector3(2.15, 2.5, 5.9), 16)
	ball.call(Vector3(0.0, 0.95, -0.15), Vector3(0.5, 0.25, 0.6), 16) # (the scutellum)
	# the head: small, tucked under the pronotum's front, the eyes on its sides
	var h := B_HEAD
	ball.call(h + Vector3(0.0, -0.15, -0.6), Vector3(2.3, 1.6, 1.6), 1)
	ball.call(h + Vector3(0.0, -0.45, -1.25), Vector3(1.3, 0.9, 0.8), 1)
	var sockets := []
	var elbows := []
	var mands := []
	for s in 2:
		var side := 1.0 if s == 1 else -1.0
		ball.call(h + Vector3(1.0 * side, 0.0, -0.75), Vector3(0.45, 0.75, 0.65), 15)
		var mp := h + Vector3(0.35 * side, -0.75, -1.5)
		mands.append(mp)
		var mb := Basis(Vector3.UP, 0.5 * side)
		ball.call(mp + mb * Vector3(0.0, 0.0, -0.3), Vector3(0.35, 0.25, 0.7), 2 + s, mb)
		# an antenna: a short scape, then beads thickening outward, curving down
		var base := h + Vector3(0.6 * side, 0.15, -1.3)
		var elbow := base + _dir(0.55, 0.35, side) * 0.8
		sockets.append(base)
		elbows.append(elbow)
		stick.call(base, elbow, 0.1, 4 + s)
		var p: Vector3 = elbow
		var fp := 0.1
		for k in 6:
			var q := p + _dir(0.45, fp, side) * 0.55
			ball.call((p + q) * 0.5, Vector3.ONE * (0.24 + 0.04 * k) + Vector3(0.0, 0.0, 0.25), 6 + s, Basis.looking_at(q - p, Vector3.UP))
			p = q
			fp -= 0.12
	# the legs, standing: as the ant's
	var hips := []
	var knees := []
	var dirs := []
	var up := Vector3.UP
	for i in 6:
		var pair := i / 2
		var side := 1.0 if i % 2 == 1 else -1.0
		var L: Dictionary = B_LEGS[pair]
		var hip0 := Vector3(L.hip.x * side, L.hip.y, L.hip.z)
		var hip := hip0 + Vector3(0.3 * side, -0.2, 0.0)
		var home: Vector2 = L.home
		var foot := Vector3(home.x * side, -body_h + 0.1, home.y)
		var out := Vector3(foot.x - hip.x, 0.0, foot.z - hip.z).normalized()
		var ankle := foot + (-out * 0.9 + up * 0.42) * float(L.s)
		var aout := Vector3(ankle.x - hip.x, 0.0, ankle.z - hip.z).normalized()
		var knee := _knee(hip, ankle, L.f, L.t, up + aout * 0.6)
		stick.call(hip0, hip, 0.3, 8 + i, 0)
		stick.call(hip, knee, 0.24, 8 + i, 1) # (stout)
		stick.call(knee, ankle, 0.17, 8 + i, 2)
		stick.call(ankle, foot, 0.12, 8 + i, 3)
		_add(st, S, Transform3D(Basis.from_scale(Vector3(0.3, 0.14, 0.4)), foot), 8 + i, 3, false) # (its broad pad)
		hips.append(hip0 * MM)
		knees.append(knee * MM)
		dirs.append(out)
	var pivots := {
		"hips": PackedVector3Array(hips), "knees": PackedVector3Array(knees), "leg_dirs": PackedVector3Array(dirs),
		"sockets": PackedVector3Array(sockets.map(func(v): return v * MM)), "elbows": PackedVector3Array(elbows.map(func(v): return v * MM)),
		"mand_pivots": PackedVector3Array(mands.map(func(v): return v * MM)), "neck": B_HEAD * MM,
		"petiole": Vector3(0.0, 0.0, 99.0), # (no gaster to pump: its abdomen's under the wing cases)
	}
	st.generate_tangents()
	return [st.commit(), pivots]


## A leaf, for them to eat at: a flat green oval about 8 cm (twice life
## size), its origin at its middle, lying on the ground.
static func leaf() -> Node3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 16
	s.rings = 6
	mi.mesh = s
	mi.scale = Vector3(0.05, 0.002, 0.085)
	mi.position.y = 0.001
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.48, 0.16)
	m.roughness = 0.6
	mi.material_override = m
	var root := Node3D.new()
	root.add_child(mi)
	return root
