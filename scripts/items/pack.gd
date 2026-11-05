class_name Pack
extends RefCounted
## The knapsack as a thing (metres; its bottom's middle at the origin, its
## front +z, its back, with the carrying cords, -z): a hide bag, made by
## hand, nothing on it but hide and twine. Its body a soft sack, rounder
## low down where its load sags it; a flap of the same hide over its mouth
## and down its front, its edge left as the skin was cut, ragged, fringed;
## its seams laced with a thong. Shut with twine: wound twice round it over
## the flap and knotted at its front, the ends hanging; a twine loop on top
## to carry it by; two cords of twisted twine down its back for the
## shoulders. The hide buckskin (one shader: smoked tan, napped, soft, matte,
## darker where it's been handled and creased); the twine plant fibre,
## twisted (another).
## Worn on the figure's back (Avatar.wear_pack), or set down (Knapsack).

const W := 0.34 ## m across
const H := 0.4 ## m tall
const D := 0.17 ## m deep
const HIDE := Color(0.5, 0.36, 0.22)
const TWINE := Color(0.52, 0.44, 0.29)

static var _sh: Shader
static var _twine_sh: Shader
static var _model_cache: Dictionary = {}


## The bag, built once (instances share its meshes).
static func model() -> Node3D:
	var root := Node3D.new()
	if _model_cache.is_empty():
		_model_cache = _build()
	for part: Array in _model_cache.parts:
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.material_override = part[1]
		root.add_child(mi)
	return root


## Buckskin: smoked tan, mottled, napped (a fine soft fuzz, matte), darker
## where hands have held it and in its creases; along its seams the lacing,
## a thong whipped over the edge (darker slanting stitches).
static func _hide(tone := 1.0, lacing := 1.0) -> ShaderMaterial:
	if _sh == null:
		_sh = Shader.new()
		_sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec3 base : source_color = vec3(0.5, 0.36, 0.22);
uniform float lacing = 1.0;
uniform vec3 half_size = vec3(0.17, 0.4, 0.085);
varying vec3 o;
varying vec3 on;
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() { o = VERTEX; on = NORMAL; }
void fragment() {
	float mott = vn(o * 14.0) * 0.55 + vn(o * 40.0) * 0.3 + vn(o * 160.0) * 0.15;
	vec3 c = base * (0.8 + 0.34 * mott);
	// (smoked unevenly: darker in patches; darker in its creases)
	c *= 1.0 - 0.18 * smoothstep(0.5, 0.85, vn(o * 6.0 + 3.0));
	float crease = smoothstep(0.6, 0.85, vn(vec3(o.x * 8.0, o.y * 22.0, o.z * 8.0)));
	c *= 1.0 - 0.2 * crease;
	// (the lacing: a thong whipped over the side seams, slanting stitches a
	// finger apart)
	float side = abs(abs(o.x) - half_size.x * 0.97);
	float along = o.y + o.z * 0.6;
	float st = (1.0 - smoothstep(0.004, 0.007, side)) * smoothstep(0.35, 0.5, abs(fract(along / 0.016) - 0.5) * 2.0) * lacing;
	st *= step(0.015, o.y) * step(o.y, half_size.y - 0.02);
	c = mix(c, base * 0.45, st * 0.85);
	ALBEDO = c;
	// (napped: matte; a soft sheen only where its fuzz catches the light at a glance)
	ROUGHNESS = 0.92;
	SPECULAR = 0.2;
	RIM = 0.25;
	RIM_TINT = 0.6;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _sh
	m.set_shader_parameter("base", Color(HIDE.r * tone, HIDE.g * tone, HIDE.b * tone))
	m.set_shader_parameter("lacing", lacing)
	m.set_shader_parameter("half_size", Vector3(W * 0.5, H, D * 0.5))
	return m


## Twine: plant fibre, two strands twisted (the twist's grooves winding
## along it, by its UV), pale straw brown.
static func _twine() -> ShaderMaterial:
	if _twine_sh == null:
		_twine_sh = Shader.new()
		_twine_sh.code = """shader_type spatial;
uniform vec3 col : source_color;
float h(float x) { return fract(sin(x * 12.9898) * 43758.5453); }
void fragment() {
	float tw = fract(UV.x * 2.0 + UV.y);
	float groove = smoothstep(0.0, 0.25, tw) * (1.0 - smoothstep(0.75, 1.0, tw));
	float fib = 0.85 + 0.3 * h(floor(UV.y * 8.0) + floor(UV.x * 9.0) * 7.0);
	ALBEDO = col * (0.6 + 0.45 * groove) * fib;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
	RIM = 0.3;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _twine_sh
	m.set_shader_parameter("col", TWINE)
	return m


static func _sp(a: float, k: float) -> float:
	return signf(a) * pow(absf(a), k)


## The body's surface at (u round it, v up it: -PI/2 .. PI/2): a soft sack
## (a rounded superellipsoid), fuller low down, its front bellied out, its
## mouth gathered in a little under the flap.
static func _body_at(u: float, v: float) -> Vector3:
	const E := 0.42
	var hw := W * 0.5
	var hd := D * 0.5
	var x := _sp(cos(v), E) * _sp(cos(u), E)
	var y := _sp(sin(v), E)
	var z := _sp(cos(v), E) * _sp(sin(u), E)
	var sag := 1.0 + 0.1 * (1.0 - (y + 1.0) * 0.5) # (wider low, where its load sits)
	var py := H * 0.5 * (1.0 + y)
	var pinch := 1.0 - 0.08 * smoothstep(0.8, 1.0, py / H)
	return Vector3(x * hw * sag * pinch, py, z * hd * sag * (1.0 + 0.14 * (1.0 - y * y) * maxf(z, 0.0)))


## (v at height y)
static func _v_at(y: float) -> float:
	var s := clampf(y / (H * 0.5) - 1.0, -1.0, 1.0)
	return signf(s) * asin(pow(absf(s), 1.0 / 0.42))


static func _body() -> ArrayMesh:
	const NU := 30
	const NV := 20
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in NV + 1:
		var v := -PI * 0.5 + PI * float(j) / NV
		for i in NU + 1:
			st.add_vertex(_body_at(-PI + TAU * float(i) / NU, v))
	for j in NV:
		for i in NU:
			var a := j * (NU + 1) + i
			var b := a + NU + 1
			st.add_index(a); st.add_index(b); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(b); st.add_index(b + 1)
	st.generate_normals()
	return st.commit()


## A strip (the flap, a fringe's thong): along the points path, its half
## width at each point's share along it by wide(t), thick, its face out of
## the plane across `side`.
static func _strip(path: PackedVector3Array, wide: Callable, thick: float, side := Vector3.RIGHT) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := path.size()
	for i in n:
		var t := float(i) / (n - 1)
		var along := (path[mini(i + 1, n - 1)] - path[maxi(i - 1, 0)]).normalized()
		var up := along.cross(side).normalized()
		var w: float = wide.call(t)
		for k: Array in [[-1.0, 1.0], [1.0, 1.0], [1.0, -1.0], [-1.0, -1.0]]:
			st.add_vertex(path[i] + side * w * k[0] + up * thick * 0.5 * k[1])
	for i in n - 1:
		for k in 4:
			var a := i * 4 + k
			var b := i * 4 + (k + 1) % 4
			st.add_index(a); st.add_index(b + 4); st.add_index(b)
			st.add_index(a); st.add_index(a + 4); st.add_index(b + 4)
	for e: Array in [[0, [0, 1, 2, 0, 2, 3]], [(n - 1) * 4, [0, 2, 1, 0, 3, 2]]]:
		for q: int in e[1]:
			st.add_index(int(e[0]) + q)
	st.generate_normals()
	return st.commit()


## A cord along path (r thick): a tube, its UV round it (x) and along it (y:
## one turn of its twist each 1.5 cm or so).
static func _cord(path: PackedVector3Array, r: float, closed := false) -> ArrayMesh:
	const SIDES := 6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := path.size()
	var along := 0.0
	var nrm := Vector3.UP
	for i in n:
		var nx := path[(i + 1) % n] if closed else path[mini(i + 1, n - 1)]
		var pv := path[(i - 1 + n) % n] if closed else path[maxi(i - 1, 0)]
		var t := (nx - pv).normalized()
		if i == 0:
			nrm = t.cross(Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT).normalized()
		else:
			nrm = (nrm - t * nrm.dot(t)).normalized()
			along += path[i].distance_to(path[i - 1])
		var bin := t.cross(nrm)
		for k in SIDES + 1:
			var a := TAU * float(k) / SIDES
			var d := nrm * cos(a) + bin * sin(a)
			st.set_uv(Vector2(float(k) / SIDES, along / 0.015))
			st.set_normal(d)
			st.add_vertex(path[i] + d * r)
	for i in n - 1:
		for k in SIDES:
			var a := i * (SIDES + 1) + k
			var b := a + SIDES + 1
			st.add_index(a); st.add_index(b); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(b); st.add_index(b + 1)
	return st.commit()


static func _blob(at: Vector3, r: float) -> ArrayMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 1.5
	s.radial_segments = 8
	s.rings = 5
	return _baked(s, Transform3D(Basis(), at))


static func _build() -> Dictionary:
	var parts: Array = []
	var hide := _hide()
	var flap_m := _hide(0.9, 0.0)
	var thong := _hide(0.75, 0.0)
	var twine := _twine()
	var hw := W * 0.5
	var hd := D * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	parts.append([_body(), hide])
	# the flap: from behind its mouth, over, and down its front; its edge
	# the skin's as it was cut (ragged), and fringed
	var fz := func(y: float) -> float: return _body_at(PI * 0.5, _v_at(y)).z
	var flap := PackedVector3Array()
	for k in 16:
		var a := float(k) / 15.0
		var p: Vector3
		if a < 0.4: # (over the top)
			var ang := lerpf(-PI * 0.5, PI * 0.45, a / 0.4)
			p = Vector3(0.0, H - 0.01 + cos(ang) * 0.022, sin(ang) * (hd + 0.008))
		else: # (down its front, lying on its belly)
			var y := H - 0.03 - (a - 0.4) / 0.6 * H * 0.46
			p = Vector3(0.0, y, float(fz.call(y)) + 0.006)
		flap.append(p)
	var ragged := func(t: float) -> float: return hw * (0.93 + 0.03 * sin(t * 37.0) + 0.02 * sin(t * 83.0 + 1.0)) * (1.0 if t < 0.82 else lerpf(1.0, 0.62, (t - 0.82) / 0.18))
	parts.append([_strip(flap, ragged, 0.004), flap_m])
	var end := flap[flap.size() - 1]
	for k in 11: # (its fringe: thongs cut along its end, hanging)
		var x := lerpf(-hw * 0.55, hw * 0.55, float(k) / 10.0)
		var l := rng.randf_range(0.05, 0.075)
		var fr := PackedVector3Array()
		for q in 4:
			var f := float(q) / 3.0
			var y := end.y + 0.004 - l * f
			fr.append(Vector3(x + rng.randf_range(-0.003, 0.003) * f, y, float(fz.call(maxf(y, 0.01))) + 0.007 + 0.004 * f))
		parts.append([_strip(fr, func(_t: float) -> float: return 0.0035, 0.002), thong])
	# the twine: wound twice round it, over the flap, knotted at its front
	var r := 0.0026
	for band: float in [H * 0.6, H * 0.645]:
		var ring := PackedVector3Array()
		var v := _v_at(band)
		for k in 41:
			var u := -PI + TAU * float(k) / 40.0
			var p := _body_at(u, v)
			var out := Vector3(p.x, 0.0, p.z).normalized()
			var over_flap := 0.009 * smoothstep(0.0, hd * 0.5, p.z) * (1.0 - smoothstep(hw * 0.94, hw * 1.04, absf(p.x))) # (out over the flap, easing round its edges)
			ring.append(p + out * (r + 0.001 + over_flap))
		parts.append([_cord(ring, r, true), twine])
	var knot := Vector3(0.04, H * 0.622, float(fz.call(H * 0.622)) + 0.017)
	parts.append([_blob(knot, 0.0075), twine])
	for s: float in [-1.0, 1.0]: # (its ends, hanging)
		var tail := PackedVector3Array()
		for q in 6:
			var f := float(q) / 5.0
			tail.append(knot + Vector3(0.004 * s + 0.01 * s * f, -0.075 * f, 0.004 + 0.008 * sin(f * PI)))
		parts.append([_cord(tail, r * 0.9), twine])
	# a twine loop on top, to carry it by
	var loop := PackedVector3Array()
	for k in 13:
		var ang := PI * float(k) / 12.0
		loop.append(Vector3(cos(ang) * 0.045, H + 0.004 + sin(ang) * 0.04, -hd * 0.35))
	parts.append([_cord(loop, r * 1.3), twine])
	# the shoulder cords, twisted twine, down its back, out where the shoulders
	# go; each end tied through a slit in the hide (a wrap of twine there)
	for sx: float in [-1.0, 1.0]:
		var s := PackedVector3Array()
		for k in 15:
			var f := float(k) / 14.0
			s.append(Vector3(sx * lerpf(hw * 0.3, hw * 0.68, f), lerpf(H * 0.92, H * 0.07, f), -hd * 1.05 - 0.008 - 0.045 * sin(f * PI)))
		parts.append([_cord(s, 0.0055), twine])
		parts.append([_blob(s[0] + Vector3(0.0, 0.0, 0.004), 0.011), twine])
		parts.append([_blob(s[s.size() - 1] + Vector3(0.0, 0.0, 0.004), 0.011), twine])
	return {"parts": parts}


static func _baked(m: Mesh, xf: Transform3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.append_from(m, 0, xf)
	return st.commit()
