class_name Lepidoptera
extends Node3D
## A butterfly or a moth, drawn at twice life size as the wasp and the ants
## are (its parts in model mm: MM): built from parts, posed every frame by
## hand (no clips), its four wings cut to their outlines
## (lepidoptera_wings.gd) and painted (data/creatures/lepidoptera_wings.png,
## both baked by tools/creatures/bake_lepidoptera_wings.py; drawn by
## lepidoptera_wing.gdshader). Not yet in the game: tools/creatures/
## lepidoptera_demo.tscn shows them. The species (HummingbirdMoth, Monarch)
## build their bodies and say what they do (_think: their animations, each
## a method run until another's called); this is the motor under them:
##
## - flight: springing toward a target at up to max_speed, turning to its
##   way (or to `_look` when hovering), banking into turns, pitched as the
##   species says; the wings beating (_flap 1: up and down through `stroke`,
##   beat_hz a second; a blur instead, if they beat faster than the eye can
##   follow) or held (_flap 0: at `_glide`, a shallow V)
## - perched on a surface (land()): standing on its legs over the point,
##   its wings opened (_open 1: spread flat) or closed (0: upright over its
##   back, touching), the legs out
## - the proboscis: coiled (_tongue 0) or uncoiled to `_tongue_at` (1),
##   reaching it if it's near enough
##
## - laying (lay(spots, normals)): to each spot in turn, down onto it (or,
##   hover_lay, hovering at it), the abdomen curled under, an egg left at
##   its tip (Brood's), and on to the next; then the species' own again
## - emerging (emerge(at, normal, head_way)): just out of its pupa, clinging
##   there, its wings crumpled stubs, pumped out to their full size over
##   some seconds as it hangs, the abdomen working; then off
##
## Its position is set every frame: put it under a node that isn't moved.

const MM := 0.002 ## m drawn per model mm (twice life size)
const WINGS := preload("res://scripts/creatures/lepidoptera_wings.gd")
const BroodScript := preload("res://scripts/creatures/brood.gd")

# what the species sets (_init)
var body_len := 25.0 ## mm, head to tail
var wing_len := 22.0 ## mm, a forewing from its hinge to its tip
var wing_w := 11.0 ## mm, its breadth
var hind_len := 15.0
var hind_w := 13.0
var beat_hz := 10.0
var stroke := Vector2(-0.6, 1.3) ## rad: the wings' angle up from level, at the bottom and the top of a beat
var blur_hz := 25.0 ## faster than this, the beat drawn as a blur
var max_speed := 1.0 ## m/s
var accel := 6.0 ## how hard it springs toward its target
var proboscis := 15.0 ## mm, uncoiled
var stand := 3.0 ## mm its middle stands over what it's perched on
var pattern := 0 ## lepidoptera_wing.gdshader's (the blur's colour)
var fore_wing := "monarch_fore" ## lepidoptera_wings.gd's
var hind_wing := "monarch_hind"
var fore_hinge := Vector3(0.9, 1.0, -1.2) ## mm: the right forewing's root on the thorax
var hind_hinge := Vector3(0.9, 1.0, 1.0)

var rng := RandomNumberGenerator.new()
var flying := true
var _pos := Vector3.ZERO # the body's middle (its parent's space)
var _vel := Vector3.ZERO
var _heading := Vector3.FORWARD
var _target := Vector3.ZERO
var _look := Vector3.ZERO # hovering: the way to face (ZERO: as it goes)
var _pitch := 0.0 # rad, nose up (aimed at: _pitch_now follows)
var _pitch_now := 0.0
var _bank := 0.0
var _jitter := 0.0 # m: the hover's unsteadiness
var _t := 0.0
var _phase := 0.0 # the wingbeat's
var _flap := 1.0
var _glide := 0.3 # rad: the wings' angle held, not beating
var _open := 0.0
var _open_now := 0.0
var _flap_now := 1.0
var _tongue := 0.0
var _tongue_now := 0.0
var _tongue_at := Vector3.INF # (its parent's space, as _pos)
var _surface_n := Vector3.UP # perched: the surface's normal
var _surface_p := Vector3.ZERO # and the point under it

var _body: Node3D # the model, in mm
var _hinges: Array[Node3D] = [] # fore left, fore right, hind left, hind right
var _fans: Array[MeshInstance3D] = [] # the blur, a side each
var _wing_mats: Array[ShaderMaterial] = []
var _tongue_node: Node3D
var _tongue_mesh: MeshInstance3D
var _coil: MeshInstance3D
var _legs: Array[Node3D] = []
var _head_at := Vector3(0.0, 0.0, -10.0) # mm: where the proboscis leaves the head

# the abdomen (the species builds it under _abdomen, its pivot: curled
# under to lay)
var _abdomen: Node3D
var abdomen_at := Vector3.ZERO ## mm: its joint with the thorax
var abdomen_tip := Vector3(0.0, 0.0, 12.0) ## mm, from abdomen_at: where an egg leaves it
var egg_kind := "monarch" ## Brood's
var hover_lay := false ## laying hovering (the clearwing), not settled
var eggs: Array[Node3D] = [] ## the eggs it's laid (in its parent)
var _curl := 0.0
var _curl_now := 0.0
var _lay_spots: Array = []
var _lay_normals: Array = []
var _lay_i := -1
var _lay_stage := 0
var _lay_t := 0.0
var _after := Callable()
var _grow := 1.0 # its wings: 0 crumpled stubs (just out of the pupa) .. 1 full
var _emerging := false
var _emerge_t := 0.0


func _ready() -> void:
	rng.randomize()
	_body = Node3D.new()
	_body.scale = Vector3.ONE * MM
	add_child(_body)
	_abdomen = Node3D.new()
	_abdomen.position = abdomen_at
	_body.add_child(_abdomen)
	_build()
	_build_wings()
	_build_tongue()


## Starts it at `at`, flying (its parent's space).
func place(at: Vector3) -> void:
	_pos = at
	_target = at
	_vel = Vector3.ZERO
	flying = true


# ---- for the species ----------------------------------------------------------

## The species builds its body here (under _body, in mm; -z forward, +y up).
func _build() -> void:
	pass


## The species decides what to do, each frame (where to fly, when to land,
## how to hold its wings and tongue).
func _think(_dt: float) -> void:
	pass


## A part: an ellipsoid at `at` (mm), `size` across (mm), coloured.
## fur: how furry it looks (0 bare, 1 furred: a soft sheen at its rim, as
## light catches the hairs round its edge).
func _part(at: Vector3, size: Vector3, color: Color, rough := 0.7, parent: Node3D = null, fur := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _SPHERE
	mi.position = at
	mi.scale = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if fur > 0.0:
		m.rim_enabled = true
		m.rim = fur
		m.rim_tint = 0.6
	mi.material_override = m
	(parent if parent else _body).add_child(mi)
	return mi


static var _SPHERE: SphereMesh = _sphere()


static func _sphere() -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 16
	s.rings = 10
	return s


## A stick (a leg's segment, an antenna) from a to b (mm), r thick.
func _stick(a: Vector3, b: Vector3, r: float, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	c.radial_segments = 5
	c.rings = 1
	mi.mesh = c
	var d := b - a
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	mi.transform = Transform3D(Basis(x * r * 2.0, y * d.length(), z * r * 2.0), (a + b) * 0.5)
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	mi.material_override = m
	(parent if parent else _body).add_child(mi)
	return mi


## A pair of antennae from the head at `base` (mm, the right one's socket),
## `length` long, swept up, out and forward and curving a little up: thin,
## thickening over their last `club_len` (a share) to `club` mm across; a
## hook: their tips bent back (a hawk moth's).
func _antennae(base: Vector3, length: float, club: float, color: Color, thick := 0.18, club_len := 0.22, hook := false) -> void:
	const N := 10
	for side: float in [-1.0, 1.0]:
		var p := Vector3(base.x * side, base.y, base.z)
		var d := Vector3(0.38 * side, 0.55, -0.74).normalized()
		for k in N:
			var t := float(k + 1) / N
			var r := thick
			var into := clampf((t - (1.0 - club_len)) / club_len, 0.0, 1.0)
			r = lerpf(thick, club * 0.5, into * into)
			var dd := d
			if hook and k == N - 1:
				dd = (d + Vector3(0.25 * side, -0.5, 0.9)).normalized() # (the hooked tip)
				r = thick * 0.7
			var q := p + dd * length / N
			_stick(p, q, r, color)
			if into > 0.0 and not (hook and k == N - 1):
				_part(q, Vector3.ONE * r * 2.0, color, 0.5) # (round the club's joints)
			p = q
			d = (d + Vector3(0.0, 0.035, 0.03)).normalized() # (curving up a little, as they go)


## Three pairs of legs under the thorax (mm: their hips' middle, how long),
## each its own node (stretched out perched, tucked flying: _legs): a femur
## out and up to the knee, a tibia down, a tarsus to the foot on the
## surface (stand under the body). reduced_front: the forelegs small and
## folded up against the chest, unused (a brush-footed butterfly's).
func _legs_at(hip: Vector3, length: float, color: Color, reduced_front := false) -> void:
	for pair in 3:
		for side: float in [-1.0, 1.0]:
			var leg := Node3D.new()
			leg.position = hip + Vector3(0.6 * side, 0.0, (pair - 1) * 1.6)
			_body.add_child(leg)
			if reduced_front and pair == 0:
				var f := Vector3(0.5 * side, -0.6, -1.6)
				_stick(Vector3.ZERO, f, 0.22, color, leg)
				_stick(f, f + Vector3(0.1 * side, 0.5, -1.0), 0.18, color, leg)
				leg.set_meta("side", side)
				_legs.append(leg)
				continue
			var s := length / 5.0
			var spread := (pair - 1) * 1.0 # (the forelegs reach forward, the hind back)
			var knee := Vector3(1.9 * side * s, 0.9 * s, spread * 0.9 * s)
			var drop := -stand - hip.y
			var ankle := Vector3(2.8 * side * s, lerpf(0.9 * s, drop, 0.8), spread * 2.0 * s)
			var foot := Vector3(3.3 * side * s, drop, spread * 2.6 * s)
			_stick(Vector3.ZERO, knee, 0.26, color, leg)
			_part(knee, Vector3.ONE * 0.5, color, 0.6, leg)
			_stick(knee, ankle, 0.2, color, leg)
			_stick(ankle, foot, 0.13, color, leg)
			leg.set_meta("side", side)
			_legs.append(leg)


func _build_wings() -> void:
	var shader: Shader = load("res://shaders/render/lepidoptera_wing.gdshader")
	var tex := _wings_texture()
	for k in 4:
		var hind := k >= 2
		var side := 1.0 if k % 2 == 1 else -1.0
		var w: Dictionary = WINGS.WINGS[hind_wing if hind else fore_wing]
		var at := hind_hinge if hind else fore_hinge
		var hinge := Node3D.new()
		hinge.position = Vector3(at.x * side, at.y, at.z)
		_body.add_child(hinge)
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("wings", tex)
		m.set_shader_parameter("under", w.under)
		m.set_shader_parameter("pattern", pattern)
		_wing_mats.append(m)
		var mi := MeshInstance3D.new()
		mi.mesh = _wing_mesh(w, side)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		hinge.add_child(mi)
		_hinges.append(hinge)
	# the blur, a fan each side round the hinges, through the stroke
	for side: float in [-1.0, 1.0]:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("pattern", pattern)
		m.set_shader_parameter("blur", true)
		var fan := MeshInstance3D.new()
		fan.mesh = _fan_mesh(wing_len, side)
		fan.material_override = m
		fan.position = Vector3(fore_hinge.x * side, fore_hinge.y, (fore_hinge.z + hind_hinge.z) * 0.5)
		fan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fan.visible = false
		_body.add_child(fan)
		_fans.append(fan)


static var _wings_tex: Texture2D


## The wings' atlas: imported (the editor's), or, not yet imported (run
## from the command line before the editor has seen it), read straight
## from the PNG.
static func _wings_texture() -> Texture2D:
	if _wings_tex == null:
		const PATH := "res://data/creatures/lepidoptera_wings.png"
		if ResourceLoader.exists(PATH):
			_wings_tex = load(PATH)
		if _wings_tex == null:
			var img := Image.load_from_file(PATH)
			img.generate_mipmaps()
			_wings_tex = ImageTexture.create_from_image(img)
	return _wings_tex


## A wing (mm, its hinge at the origin): its outline (lepidoptera_wings.gd's
## w) fanned from its middle, out along x (side: +1 the right, -1 the left:
## mirrored), back along z, a little cupped (the costa stiff and straight,
## the rest dipping a touch behind it); UV on the atlas; the upper side the
## front face: clockwise seen from above (the outline walks so; the
## mirrored left wing's triangles taken the other way round).
static func _wing_mesh(w: Dictionary, side: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline: Array = w.outline
	var mid: Vector2 = w.middle
	var uv0: Vector2 = w.uv_origin
	var per: Vector2 = w.uv_per_mm
	var z_min := INF
	var z_max := -INF
	for p: Vector2 in outline:
		z_min = minf(z_min, p.y)
		z_max = maxf(z_max, p.y)
	var depth := (z_max - z_min) * 0.035
	const RINGS := 3
	var at := func(p: Vector2) -> Array:
		var across := (p.y - z_min) / maxf(z_max - z_min, 1e-3)
		return [Vector3(p.x * side, -depth * across * across, p.y), uv0 + p * per]
	for i in outline.size():
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % outline.size()]
		# (in rings out from the middle, so the cupping bends it)
		for r in RINGS:
			var t0 := float(r) / RINGS
			var t1 := float(r + 1) / RINGS
			var quad := [mid.lerp(a, t0), mid.lerp(a, t1), mid.lerp(b, t1), mid.lerp(b, t0)]
			var tris := [[0, 1, 2], [0, 2, 3]] if r > 0 else [[0, 1, 2]]
			for tri: Array in tris:
				var order: Array = tri if side > 0.0 else [tri[0], tri[2], tri[1]]
				for q: int in order:
					var v: Array = at.call(quad[q])
					st.set_uv(v[1])
					st.set_normal(Vector3.UP)
					st.add_vertex(v[0])
	return st.commit()


## The blur's fan (mm): the wing's span swept round the hinge from the
## stroke's bottom to its top, in the plane across the body.
func _fan_mesh(length: float, side: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const N := 10
	for i in N:
		var a0 := lerpf(stroke.x, stroke.y, float(i) / N)
		var a1 := lerpf(stroke.x, stroke.y, float(i + 1) / N)
		var p0 := Vector3(cos(a0) * side, sin(a0), 0.0) * length
		var p1 := Vector3(cos(a1) * side, sin(a1), 0.0) * length
		for q in [[Vector3.ZERO, Vector2(0.0, float(i) / N)], [p0, Vector2(1.0, float(i) / N)], [p1, Vector2(1.0, float(i + 1) / N)]]:
			st.set_uv(q[1])
			st.set_normal(Vector3.BACK)
			st.add_vertex(q[0])
	return st.commit()


func _build_tongue() -> void:
	_tongue_node = Node3D.new()
	_tongue_node.position = _head_at
	_body.add_child(_tongue_node)
	_tongue_mesh = _stick(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), 0.12, Color(0.18, 0.12, 0.08), _tongue_node)
	_coil = _part(_head_at + Vector3(0.0, -0.7, -0.3), Vector3(0.9, 0.9, 0.5), Color(0.18, 0.12, 0.08), 0.5)


# ---- the motor ----------------------------------------------------------------

## Lands it on the point at, the surface there facing n (its parent's space).
func land(at: Vector3, n: Vector3) -> void:
	flying = false
	_surface_p = at
	_surface_n = n.normalized()
	_vel = Vector3.ZERO


## Off again, a little up from where it was.
func take_off() -> void:
	if not flying:
		flying = true
		_vel = _surface_n * 0.3
		_target = _pos + _surface_n * 0.05


func _process(dt: float) -> void:
	if dt <= 0.0 or _body == null:
		return
	_t += dt
	if _lay_i >= 0:
		_lay_think(dt)
	elif _emerging:
		_emerge_think(dt)
	else:
		_think(dt)
	if flying:
		var to := _target - _pos
		var want := to * accel * 0.6
		if want.length() > max_speed:
			want = want.normalized() * max_speed
		var acc := (want - _vel) * accel
		_vel += acc * dt
		_pos += _vel * dt
		var hv := Vector3(_vel.x, 0.0, _vel.z)
		var face := _heading
		if _look != Vector3.ZERO and Vector2(_look.x, _look.z).length() > 1e-4:
			face = Vector3(_look.x, 0.0, _look.z).normalized()
		elif hv.length() > 0.08:
			face = hv.normalized()
		var turn := _heading.signed_angle_to(face, Vector3.UP)
		_heading = _heading.rotated(Vector3.UP, clampf(turn, -8.0 * dt, 8.0 * dt))
		_bank = lerpf(_bank, clampf(-turn * 1.2, -0.7, 0.7), 1.0 - exp(-6.0 * dt))
	else:
		_pos = _pos.lerp(_surface_p + _surface_n * stand * MM, 1.0 - exp(-14.0 * dt))
		_bank = lerpf(_bank, 0.0, 1.0 - exp(-8.0 * dt))
	var k := 1.0 - exp(-8.0 * dt)
	_pitch_now = lerpf(_pitch_now, _pitch, k)
	_open_now = lerpf(_open_now, _open, 1.0 - exp(-5.0 * dt))
	_flap_now = lerpf(_flap_now, _flap if flying else 0.0, 1.0 - exp(-12.0 * dt))
	_tongue_now = move_toward(_tongue_now, _tongue, dt * 2.5)
	_place_body()
	_curl_now = lerpf(_curl_now, _curl, 1.0 - exp(-6.0 * dt))
	_abdomen.rotation.x = _curl_now * 0.9
	_pose_wings(dt)
	_pose_tongue()
	for leg in _legs:
		leg.rotation = Vector3(0.0, 0.0, 0.0) if not flying else Vector3(0.9, 0.0, -0.5 * float(leg.get_meta("side")))


func _place_body() -> void:
	var up := Vector3.UP if flying else _surface_n
	var fwd := (_heading - up * _heading.dot(up)).normalized()
	if fwd.length_squared() < 1e-6:
		fwd = up.cross(Vector3.RIGHT).normalized()
	var b := Basis.looking_at(fwd, up)
	b = b * Basis(Vector3.RIGHT, _pitch_now) * Basis(Vector3.BACK, _bank)
	var jit := Vector3.ZERO
	if flying and _jitter > 0.0:
		jit = Vector3(sin(_t * 23.0) + 0.5 * sin(_t * 41.0), sin(_t * 19.0 + 1.0), sin(_t * 29.0 + 2.0)) * _jitter
	transform = Transform3D(b, _pos + jit)


func _pose_wings(dt: float) -> void:
	_phase += TAU * beat_hz * dt * _flap_now
	var blurred := flying and beat_hz > blur_hz and _flap_now > 0.5
	for f in _fans:
		f.visible = blurred
	for k in 4:
		var hinge := _hinges[k]
		var hind := k >= 2
		var side := 1.0 if k % 2 == 1 else -1.0
		var up: float
		if flying:
			var beat := lerpf(stroke.x, stroke.y, 0.5 + 0.5 * sin(_phase - (0.35 if hind else 0.0)))
			up = lerpf(_glide, beat, _flap_now)
		else:
			# closed upright over its back (a little past, touching) .. spread flat
			up = lerpf(PI * 0.5 - 0.04, -0.03, _open_now)
		var sweep := (-0.15 if hind else 0.12) + (0.18 * sin(_phase + 1.2) * _flap_now if flying else 0.0)
		hinge.transform.basis = Basis(Vector3.UP, -sweep * side) * Basis(Vector3.BACK, up * side)
		if _grow < 0.999: # (just out: small, crumpled, filling out)
			var crumple := (1.0 - _grow) * (0.5 if k % 2 == 0 else -0.4)
			hinge.transform.basis = hinge.transform.basis * Basis(Vector3.RIGHT, crumple) * Basis.from_scale(Vector3(lerpf(0.22, 1.0, _grow), 1.0, lerpf(0.35, 1.0, _grow)))
		hinge.visible = not blurred


func _pose_tongue() -> void:
	var out := _tongue_now > 0.02
	_tongue_node.visible = out
	_coil.visible = not out or _tongue_now < 0.4
	if not out:
		return
	var reach := proboscis * _tongue_now
	var dir := Vector3(0.0, -0.6, -1.0).normalized()
	if _tongue_at != Vector3.INF:
		# (to the point, in its parent's space as _pos is, if it's in reach)
		var head := transform * (_head_at * MM)
		var to := _tongue_at - head
		var d := to.length() / MM
		reach = minf(d, proboscis) * _tongue_now
		if d > 0.01:
			dir = (transform.basis.inverse() * to).normalized()
	# the stick runs from 0 to -z: turn -z onto dir, stretch it to reach
	var z := -dir
	var x := Vector3.UP.cross(z)
	if x.length_squared() < 1e-6:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x)
	_tongue_node.transform = Transform3D(Basis(x, y, z * reach), _head_at)


# ---- laying, emerging -----------------------------------------------------------

## Laying an egg at each of spots (points, its parent's space; the surface
## there facing normals'), one after another; then after (if given: the
## species' own doing again).
func lay(spots: Array, normals: Array, after := Callable()) -> void:
	if spots.is_empty():
		return
	_lay_spots = spots
	_lay_normals = normals
	_lay_i = 0
	_lay_stage = 0
	_lay_t = 0.0
	_after = after
	_tongue = 0.0
	_tongue_at = Vector3.INF
	_emerging = false
	take_off()


func _lay_think(dt: float) -> void:
	var spot: Vector3 = _lay_spots[_lay_i]
	var n: Vector3 = (_lay_normals[_lay_i] as Vector3).normalized()
	_jitter = 0.0008 if hover_lay else 0.0
	_look = Vector3.ZERO
	match _lay_stage:
		0: # up and over it
			_flap = 1.0
			_target = spot + n * 0.07
			_pitch = 0.2
			if _pos.distance_to(_target) < 0.02:
				_lay_stage = 1
		1: # down to it
			_flap = 1.0
			_target = spot + n * (stand + (3.0 if hover_lay else 0.0)) * MM
			_pitch = 0.1
			if _pos.distance_to(_target) < 0.008:
				if not hover_lay:
					land(spot, n)
					_open = 0.0
				_lay_stage = 2
				_lay_t = 0.0
		2: # the abdomen curled under, the egg out
			_curl = 1.0
			_lay_t += dt
			if _lay_t > 1.0:
				_drop_egg(spot, n)
				_lay_stage = 3
				_lay_t = 0.0
		3: # and away to the next
			_curl = 0.0
			_lay_t += dt
			if _lay_t > 0.4:
				take_off()
				_lay_i += 1
				_lay_stage = 0
				if _lay_i >= _lay_spots.size():
					_lay_i = -1
					if _after.is_valid():
						_after.call()


## An egg under its abdomen's tip, on the surface (spot, n).
func _drop_egg(spot: Vector3, n: Vector3) -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var tip := parent.to_local(_abdomen.global_transform * abdomen_tip)
	var on := tip - n * (tip - spot).dot(n)
	var e := BroodScript.egg(egg_kind)
	parent.add_child(e)
	e.transform = Transform3D(_up_basis(n), on)
	eggs.append(e)


## A basis whose y is n.
static func _up_basis(n: Vector3) -> Basis:
	var x := n.cross(Vector3.FORWARD if absf(n.z) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(x, n, x.cross(n))


## Just out of its pupa: clinging at `at` (the surface there facing normal),
## its head toward head_way, its wings crumpled; they fill out over some
## seconds as it hangs there, the abdomen pumping; then after (the species'
## own doing).
func emerge(at: Vector3, normal: Vector3, head_way: Vector3, after := Callable()) -> void:
	_lay_i = -1
	_emerging = true
	_emerge_t = 0.0
	_grow = 0.0
	_after = after
	land(at, normal)
	_pos = at + normal.normalized() * stand * MM
	_heading = head_way.normalized()
	_open = 0.0
	_flap = 0.0
	_tongue = 0.0
	_tongue_at = Vector3.INF


func _emerge_think(dt: float) -> void:
	_emerge_t += dt
	_grow = clampf((_emerge_t - 1.0) / 7.0, 0.0, 1.0)
	_grow = _grow * _grow * (3.0 - 2.0 * _grow)
	_curl = 0.12 + 0.1 * sin(_emerge_t * 2.5) * (1.0 - _grow) # (pumping blood into the wings)
	_open = 0.0 if _emerge_t < 9.0 else 0.4 + 0.3 * sin(_emerge_t * 0.8) # (drying: opening and closing them)
	if _emerge_t > 12.0:
		_emerging = false
		_grow = 1.0
		_curl = 0.0
		if _after.is_valid():
			_after.call()


# ---- helpers for the species ------------------------------------------------

## The way across the ground from a to b (unit; ZERO if b's straight above).
static func _flat(a: Vector3, b: Vector3) -> Vector3:
	var d := Vector3(b.x - a.x, 0.0, b.z - a.z)
	return d.normalized() if d.length() > 1e-5 else Vector3.ZERO


## A point round centre within radius, h above it in [lo, hi] (m).
func _somewhere(centre: Vector3, radius: float, lo: float, hi: float) -> Vector3:
	var a := rng.randf() * TAU
	var r := sqrt(rng.randf()) * radius
	return centre + Vector3(cos(a) * r, rng.randf_range(lo, hi), sin(a) * r)
