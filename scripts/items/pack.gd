class_name Pack
extends RefCounted
## The knapsack as a thing (metres; its bottom's middle at the origin, its
## front +z, its back, with the shoulder straps, -z): a leather bag, its
## body soft-cornered and a little bulged, a flap over its top and down its
## front, closed by two straps through brass buckles, a carrying loop on
## top; the two shoulder straps down its back. All of it leather (one
## shader): oiled brown, its grain pebbled, darker in its creases and worn
## paler on its edges and corners, stitched along its seams.
## Worn on the figure's back (Avatar.wear_pack), or set down (PackCarry).

const W := 0.34 ## m across
const H := 0.42 ## m tall
const D := 0.17 ## m deep
const LEATHER := Color(0.4, 0.24, 0.12)

static var _sh: Shader
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


static func _leather(tone := 1.0, seam := 1.0) -> ShaderMaterial:
	if _sh == null:
		_sh = Shader.new()
		_sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec3 base : source_color = vec3(0.42, 0.26, 0.14);
uniform float stitches = 1.0;
varying vec3 o;
varying vec3 on;
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float vn(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float cellv(vec3 p) { // (the grain's pebbles: distance to the nearest of scattered points)
	vec3 i = floor(p);
	float best = 9.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 k = i + vec3(float(x), float(y), float(z));
		best = min(best, length(p - k - vec3(h3(k), h3(k + 1.3), h3(k + 2.7))));
	}
	return best;
}
void vertex() { o = VERTEX; on = NORMAL; }
void fragment() {
	// (oiled brown, mottled; darker in its creases (the big soft folds), worn
	// paler where it's rubbed: its edges and corners, the curve of its belly)
	float mott = vn(o * 18.0) * 0.6 + vn(o * 55.0) * 0.4;
	vec3 c = base * (0.82 + 0.3 * mott);
	float crease = smoothstep(0.55, 0.8, vn(vec3(o.x * 9.0, o.y * 26.0, o.z * 9.0)));
	c *= 1.0 - 0.22 * crease;
	float edge = 1.0 - smoothstep(0.004, 0.025, min(min(abs(abs(o.x) - 0.17), abs(o.y - 0.42)), abs(o.y)));
	c = mix(c, base * 1.45 + vec3(0.04, 0.03, 0.02), edge * 0.5 * (0.6 + 0.4 * mott));
	// (its stitches: short pale dashes along its seams, a little in from the edges)
	float sx = abs(abs(o.x) - 0.155);
	float sy = abs(o.y - 0.405);
	float along = abs(on.x) < 0.5 ? (sx < sy ? o.y : o.x) : o.z;
	float near = min(sx, sy);
	float dash = step(0.45, fract(along / 0.007));
	float st = (1.0 - smoothstep(0.0012, 0.0022, near)) * dash * stitches;
	c = mix(c, vec3(0.6, 0.5, 0.36), st * 0.75);
	ALBEDO = c;
	// (the grain: pebbled, bumped)
	float g = smoothstep(0.0, 1.0, 1.0 - cellv(o * 420.0));
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);
	vec3 r1 = cross(dpy, NORMAL);
	vec3 r2 = cross(NORMAL, dpx);
	float det = dot(dpx, r1);
	vec3 grad = sign(det) * (dFdx(g) * r1 + dFdy(g) * r2);
	float far = 1.0 - smoothstep(0.12, 0.45, length(VERTEX)); // (faded out further off, where it would shimmer)
	NORMAL = normalize(abs(det) * NORMAL - grad * 0.025 * far);
	ROUGHNESS = 0.55 - 0.15 * edge - 0.1 * mott; // (oiled: a soft sheen, glossier where it's rubbed)
	SPECULAR = 0.4;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _sh
	m.set_shader_parameter("base", Color(LEATHER.r * tone, LEATHER.g * tone, LEATHER.b * tone))
	m.set_shader_parameter("stitches", seam)
	return m


## A soft-cornered box (a superellipsoid: e how square, 0 a box .. 1 round),
## centred c, half sizes h.
static func _pillow(c: Vector3, h: Vector3, e := 0.28, nu := 28, nv := 18) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sp := func(a: float, k: float) -> float: return signf(a) * pow(absf(a), k)
	for j in nv + 1:
		var v := -PI * 0.5 + PI * float(j) / nv
		for i in nu + 1:
			var u := -PI + TAU * float(i) / nu
			var x: float = sp.call(cos(v), e) * sp.call(cos(u), e)
			var y: float = sp.call(sin(v), e)
			var z: float = sp.call(cos(v), e) * sp.call(sin(u), e)
			st.add_vertex(c + Vector3(x * h.x, y * h.y, z * h.z * (1.0 + 0.12 * (1.0 - y * y) * maxf(z, 0.0)))) # (its front bellied out)
	for j in nv:
		for i in nu:
			var a := j * (nu + 1) + i
			var b := a + nu + 1
			st.add_index(a); st.add_index(b); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(b); st.add_index(b + 1)
	st.generate_normals()
	return st.commit()


## A strap (or the flap: a strip): along the points path, wide (its half
## width at each point's share along it, by wide(t)), thick; its face turned
## to `face` (a point it bends round).
static func _strip(path: PackedVector3Array, wide: Callable, thick: float, side := Vector3.RIGHT) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := path.size()
	for i in n:
		var t := float(i) / (n - 1)
		var along := (path[mini(i + 1, n - 1)] - path[maxi(i - 1, 0)]).normalized()
		var up := along.cross(side).normalized() # (out of its face)
		var w: float = wide.call(t)
		for k: Array in [[-1.0, 1.0], [1.0, 1.0], [1.0, -1.0], [-1.0, -1.0]]:
			st.add_vertex(path[i] + side * w * k[0] + up * thick * 0.5 * k[1])
	for i in n - 1:
		for k in 4:
			var a := i * 4 + k
			var b := i * 4 + (k + 1) % 4
			st.add_index(a); st.add_index(b + 4); st.add_index(b)
			st.add_index(a); st.add_index(a + 4); st.add_index(b + 4)
	for e: Array in [[0, [0, 1, 2, 0, 2, 3]], [(n - 1) * 4, [0, 2, 1, 0, 3, 2]]]: # (its ends)
		for q: int in e[1]:
			st.add_index(int(e[0]) + q)
	st.generate_normals()
	return st.commit()


static func _build() -> Dictionary:
	var parts: Array = []
	var body := _leather()
	var dark := _leather(0.72, 1.0)
	var strap := _leather(0.62, 0.0)
	var hw := W * 0.5
	var hd := D * 0.5
	# the body
	parts.append([_pillow(Vector3(0.0, H * 0.5, 0.0), Vector3(hw, H * 0.5, hd)), body])
	# the flap: from behind its top, over, and down its front, its end rounded
	var flap := PackedVector3Array()
	for k in 15:
		var a := float(k) / 14.0
		var p: Vector3
		if a < 0.45: # (over the top, a curve)
			var ang := lerpf(-PI * 0.5, PI * 0.42, a / 0.45)
			p = Vector3(0.0, H - 0.012 + cos(ang) * 0.02, sin(ang) * (hd + 0.006))
		else: # (down the front, the bag's belly under it)
			var f := (a - 0.45) / 0.55
			p = Vector3(0.0, H - 0.03 - f * H * 0.42, hd + 0.012 + 0.016 * sin(f * PI) + 0.004)
		flap.append(p)
	parts.append([_strip(flap, func(t: float) -> float: return hw * 0.97 * (1.0 if t < 0.85 else sqrt(maxf(1.0 - pow((t - 0.85) / 0.15, 2.0) * 0.75, 0.0))), 0.005), dark])
	# the front straps, down over the flap's end to buckles, their tongues on through
	for sx: float in [-1.0, 1.0]:
		var x := sx * hw * 0.48
		var s := PackedVector3Array()
		for k in 9:
			var f := float(k) / 8.0
			s.append(Vector3(x, lerpf(H * 0.34, H * 0.62, f), hd + 0.022 + 0.015 * sin(f * PI * 0.9)))
		parts.append([_strip(s, func(_t: float) -> float: return 0.016, 0.004), strap])
		var tongue := PackedVector3Array([Vector3(x, H * 0.66, hd + 0.03), Vector3(x, H * 0.7, hd + 0.02), Vector3(x, H * 0.74, hd + 0.012)])
		parts.append([_strip(tongue, func(t: float) -> float: return 0.016 * (1.0 - 0.3 * t), 0.004), strap])
		# its buckle: a brass frame, its prong across
		var brass := StandardMaterial3D.new()
		brass.albedo_color = Color(0.72, 0.56, 0.26)
		brass.metallic = 0.85
		brass.roughness = 0.38
		for b: Array in [[Vector3(0.0, 0.016, 0.0), Vector3(0.042, 0.005, 0.005)], [Vector3(0.0, -0.016, 0.0), Vector3(0.042, 0.005, 0.005)],
				[Vector3(-0.019, 0.0, 0.0), Vector3(0.005, 0.037, 0.005)], [Vector3(0.019, 0.0, 0.0), Vector3(0.005, 0.037, 0.005)], [Vector3(0.0, 0.0, 0.002), Vector3(0.003, 0.03, 0.003)]]:
			var bm := BoxMesh.new()
			bm.size = b[1]
			var mt := Transform3D(Basis(), Vector3(x, H * 0.63, hd + 0.034) + (b[0] as Vector3))
			parts.append([_baked(bm, mt), brass])
	# the carrying loop on top
	var loop := PackedVector3Array()
	for k in 11:
		var ang := PI * float(k) / 10.0
		loop.append(Vector3(cos(ang) * 0.05, H + 0.005 + sin(ang) * 0.035, -hd * 0.35))
	parts.append([_strip(loop, func(_t: float) -> float: return 0.012, 0.005, Vector3.BACK), strap])
	# the shoulder straps, down its back, out a little where the shoulders go
	for sx: float in [-1.0, 1.0]:
		var s := PackedVector3Array()
		for k in 13:
			var f := float(k) / 12.0
			s.append(Vector3(sx * lerpf(hw * 0.35, hw * 0.62, f), lerpf(H * 0.93, H * 0.08, f), -hd - 0.008 - 0.045 * sin(f * PI)))
		parts.append([_strip(s, func(t: float) -> float: return lerpf(0.026, 0.017, t), 0.006), strap])
	return {"parts": parts}


static func _baked(m: Mesh, xf: Transform3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.append_from(m, 0, xf)
	return st.commit()
