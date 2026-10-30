class_name RiverMeshes
extends RefCounted
## River surfaces as ribbons along each centreline (not a water-level map, so
## rivers never fold into each other): flat across at the river's water level,
## a little wider than the channel so the edges tuck under the banks. Each
## vertex carries the downstream direction and speed (COLOR) and how far along
## the river it is (UV.y), so the shader can make the water flow.

const OVERLAP := 1.25 # ribbon half-width / channel half-width


static func build(world: WorldData) -> ArrayMesh:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var idx := PackedInt32Array()
	for r in world.rivers:
		var pts: PackedVector2Array = r.pts
		var lev: PackedFloat32Array = r.level
		var wid: PackedFloat32Array = r.width
		var n := pts.size()
		if n < 2:
			continue
		var base := verts.size()
		var along := 0.0
		for i in n:
			var down := (pts[maxi(i - 1, 0)] - pts[mini(i + 1, n - 1)]).normalized() # index 0 is downstream
			var side := Vector2(-down.y, down.x)
			if i > 0:
				along += pts[i].distance_to(pts[i - 1])
			# Steeper reaches run faster.
			var j := mini(i + 3, n - 1)
			var k := maxi(i - 3, 0)
			var slope := (lev[j] - lev[k]) / maxf(pts[j].distance_to(pts[k]), 1.0)
			var speed := clampf(0.25 + slope * 25.0, 0.25, 1.0)
			var hw := wid[i] * 0.5 * OVERLAP + 0.5
			for s in [-1.0, 1.0]:
				var p: Vector2 = pts[i] + side * hw * s
				verts.append(Vector3(p.x, lev[i], p.y))
				uvs.append(Vector2((s + 1.0) * 0.5, along))
				colors.append(Color(down.x * 0.5 + 0.5, down.y * 0.5 + 0.5, speed, wid[i] / 60.0))
				normals.append(Vector3.UP)
		for i in n - 1:
			var a := base + i * 2
			idx.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh
