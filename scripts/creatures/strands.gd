class_name Strands
extends RefCounted
## Strands standing off a mammal's one skin (MammalSkin): a porcupine's
## quills and guard hairs, an armadillo's sparse bristles. Each grown from a
## point on the skin as it rests, weighted to the same bones as the skin
## there, so it goes wherever the skin goes (bending with its neck, swinging
## with its tail); each a thin tapered tube, laid back along the body the
## way its hair lies (a little off the skin, drooping under its own weight
## if long), and, as the mesh's one blend shape ("erect"), raised: stood up
## off the skin, fanned (a porcupine's quills bristling). Coloured root to
## tip (its vertex colours: strands.gdshader).
##
## grow(skin, n, pick, seed): n strands on skin (the MeshInstance3D
## MammalSkin.finish gave), each where pick says: pick(p, nrm, c0, h) for a
## point on the skin (p its rest place, the body's mm; nrm its normal; c0
## its part, along, face share; h where it is in the head's own space) gives
## {} (none here) or {"w": how likely one grows here (0..1), "len": mm,
## "r": its root's radius (mm), "lie": the way it lies (unit, the body's),
## "up": the way it stands raised (unit), "root": Color, "tip": Color,
## "tip_from": how far along its tip colour starts (0..1), "droop": how far
## its own weight bends it down (0..1), "sides": 3 or 4}.

const UP_SAG := 0.25 ## (raised, how much less it droops)


static func grow(skin_mi: MeshInstance3D, n: int, pick: Callable, seed_ := 1) -> MeshInstance3D:
	var src := skin_mi.mesh as ArrayMesh
	var a := src.surface_get_arrays(0)
	var V: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var N: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var B: PackedInt32Array = a[Mesh.ARRAY_BONES]
	var W: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
	var C0: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM0]
	var C3: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM3]
	var I: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if I.is_empty():
		for k in V.size():
			I.append(k)
	var bw := B.size() / maxi(V.size(), 1) # (bones per vertex: 4, or 8)
	# (each triangle by its area: points spread evenly over the skin)
	var tri_n := I.size() / 3
	var cum := PackedFloat32Array()
	cum.resize(tri_n)
	var tot := 0.0
	for t in tri_n:
		var p0 := V[I[t * 3]]
		tot += (V[I[t * 3 + 1]] - p0).cross(V[I[t * 3 + 2]] - p0).length() * 0.5
		cum[t] = tot
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var pos := PackedVector3Array()
	var pos_up := PackedVector3Array()
	var nrm := PackedVector3Array()
	var nrm_up := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var idx := PackedInt32Array()
	var made := 0
	var tries := 0
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	while made < n and tries < n * 30:
		tries += 1
		var x := rng.randf() * tot
		var t := cum.bsearch(x)
		t = mini(t, tri_n - 1)
		var i0 := I[t * 3]
		var i1 := I[t * 3 + 1]
		var i2 := I[t * 3 + 2]
		var u := rng.randf()
		var v := rng.randf()
		if u + v > 1.0:
			u = 1.0 - u
			v = 1.0 - v
		var p := V[i0] * (1.0 - u - v) + V[i1] * u + V[i2] * v
		var nn := (N[i0] * (1.0 - u - v) + N[i1] * u + N[i2] * v).normalized()
		var c0 := Color(C0[i0 * 4], C0[i0 * 4 + 1], C0[i0 * 4 + 2], C0[i0 * 4 + 3])
		var h := Vector3(C3[i0 * 4], C3[i0 * 4 + 1], C3[i0 * 4 + 2]) * (1.0 - u - v) + Vector3(C3[i1 * 4], C3[i1 * 4 + 1], C3[i1 * 4 + 2]) * u + Vector3(C3[i2 * 4], C3[i2 * 4 + 1], C3[i2 * 4 + 2]) * v
		var d: Dictionary = pick.call(p, nn, c0, h)
		if d.is_empty() or rng.randf() > float(d.get("w", 1.0)):
			continue
		# (its bones: the nearest corner's)
		var nearest := i0 if (1.0 - u - v) >= maxf(u, v) else (i1 if u >= v else i2)
		var sb := PackedInt32Array([B[nearest * bw], B[nearest * bw + 1], B[nearest * bw + 2], B[nearest * bw + 3]])
		var sw := PackedFloat32Array([W[nearest * bw], W[nearest * bw + 1], W[nearest * bw + 2], W[nearest * bw + 3]])
		var L := float(d.len) * rng.randf_range(0.75, 1.15)
		var r := float(d.r) * rng.randf_range(0.8, 1.2)
		var droop := float(d.get("droop", 0.0))
		var sides := int(d.get("sides", 4))
		var root := p - nn * r * 2.0 # (set in the skin, not on it)
		var lie: Vector3 = (d.lie as Vector3).normalized()
		var up: Vector3 = (d.up as Vector3).normalized()
		var jit := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * 0.12
		lie = (lie + jit).normalized()
		up = (up + jit * 1.6).normalized()
		var ca: Color = d.root
		var cb: Color = d.tip
		var tf := float(d.get("tip_from", 0.6))
		var segs := 3
		var base := pos.size()
		for e in [0, 1]:
			var dir := lie if e == 0 else up
			var sag := droop * (1.0 if e == 0 else UP_SAG)
			var pts: Array[Vector3] = []
			for s in segs + 1:
				var f := float(s) / segs
				pts.append(root + dir * L * f + Vector3.DOWN * L * sag * f * f * 0.6)
			for s in segs + 1:
				var f := float(s) / segs
				var along := (pts[mini(s + 1, segs)] - pts[maxi(s - 1, 0)]).normalized()
				var side := along.cross(nn if absf(along.dot(nn)) < 0.95 else Vector3.RIGHT).normalized()
				var side2 := along.cross(side).normalized()
				var rr := r * (1.0 - f * 0.92) if s < segs else 0.0
				for k in sides:
					var ang := TAU * k / sides
					var o := side * cos(ang) + side2 * sin(ang)
					var q := pts[s] + o * rr
					if e == 0:
						pos.append(q)
						nrm.append((o + nn * 0.6).normalized())
						var cc := ca.lerp(cb, smoothstep(tf - 0.08, tf + 0.05, f))
						col.append(cc)
						uv.append(Vector2(f, float(d.get("kind", 0))))
						bones.append_array(sb)
						weights.append_array(sw)
						lo = lo.min(q)
						hi = hi.max(q)
					else:
						pos_up.append(q)
						nrm_up.append((o + nn * 0.3).normalized())
						lo = lo.min(q)
						hi = hi.max(q)
		for s in segs:
			for k in sides:
				var k1 := (k + 1) % sides
				var a0 := base + s * sides + k
				var a1 := base + s * sides + k1
				var b0 := base + (s + 1) * sides + k
				var b1 := base + (s + 1) * sides + k1
				idx.append_array(PackedInt32Array([a0, b0, a1, a1, b0, b1]))
		made += 1
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pos
	arrays[Mesh.ARRAY_NORMAL] = nrm
	arrays[Mesh.ARRAY_COLOR] = col
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = idx
	var shape := []
	shape.resize(Mesh.ARRAY_MAX)
	shape[Mesh.ARRAY_VERTEX] = pos_up
	shape[Mesh.ARRAY_NORMAL] = nrm_up
	var m := ArrayMesh.new()
	m.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	m.add_blend_shape("erect")
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [shape])
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/render/strands.gdshader")
	mi.material_override = mat
	var skel := skin_mi.get_parent() as Skeleton3D
	skel.add_child(mi)
	mi.skin = skin_mi.skin
	mi.skeleton = mi.get_path_to(skel)
	var bb := AABB(lo, hi - lo)
	mi.custom_aabb = bb.grow(bb.size.length() * 0.6)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi
