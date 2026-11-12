class_name Snails
extends AntColony
## Land snails, the make they share (the species: FlamedTigersnails,
## GrassSnails), drawn at twice life size as the insects are. Made and
## moved as the ants are (AntColony: one mesh, every snail an instance of
## it, posed by its shader, snail.gdshader; moved along on the GPU, a
## hundred and fifty or more, else here), only far slower.
##
## The mesh: the foot, one smooth body from its tail to its snout, the
## head rising from it, two pairs of tentacles (the upper long, an eye at
## each tip; the lower short), the mantle's collar at the shell's mouth;
## the shell a coiled tube (_shell: whorls growing as they turn, each
## lapping the last, sinking as they go, the umbilicus open beneath),
## carried on the body's back, its spire up and to the right (dextral:
## coiled clockwise seen from the apex), its mouth ahead of its axis, open
## down onto the body, the mantle filling it.
##
## Their ways (each snail on its own: wander, feed, hide, sleep, mate,
## lay; or steered: member(i), as the ants are):
## - wandering, gliding on its foot (waves down its sole), the head
##   swaying, the upper tentacles feeling about, the lower dabbing; a
##   slime trail left behind it, glistening, drying away
## - feeding (feed(i, at)): the head down, rasping, nodding
## - hiding (withdraw(i, secs): touched, startled): its tentacles drawn in,
##   then its head and foot, into the shell, which settles; out again
##   slowly, the tentacles last. Sleeping (sleep: dry weather, or the
##   winter): withdrawn the same, the mouth sealed with a film of dried
##   mucus (the epiphragm), till woken (wander)
## - mating, sexually (mate(i, j): both hermaphrodites, each the other's
##   mate): they come together head to head, rear up, the fronts of their
##   feet pressed together, swaying, touching tentacles, then joined a
##   while; each goes off carrying eggs (gravid). Or, alone a long while (or
##   told, self_fertilize(i)), one's eggs are its own (asexual: selfing; a
##   lovely grass snail's mostly are)
## - laying (lay(i, at)): its head pushed down into the soil, its eggs
##   (Brood's, egg_kind) left in a clutch in the hole; they hatch on their
##   own a while later (HATCH_SECS) into tiny snails (the colony's, small,
##   growing to full size over grow_secs)
## - dying (die(i)): withdrawn for good, an empty shell left (a firefly
##   larva's prey)

const SHADER := preload("res://shaders/render/snail.gdshader")
const HIDDEN := 6 ## task: withdrawn into its shell (hiding, sleeping)
const COURTING := 7 ## task: mating
const DEAD := 8
const HATCH_SECS := 60.0 ## s after it's laid an egg hatches
const SELF_AFTER := 240.0 ## s alone, grown, before its eggs are its own

## The species' shape (mm, life size; drawn at MM a mm):
## shell: {diam (across), whorls, grow (the radius's growth a whorl), tube
## (the tube's radius, a share of its distance from the axis), round (its
## height, a share of its width), spire (how high the spire, a share of
## the radius), lip (the mouth flared: 0 none), descend (the last whorl's
## drop at the mouth, a share of the radius), apex (the way the apex
## points, on the body: left, up, back), mouth (the mouth's centre on the
## body)};
## body: [[z, the foot's half width, the body's half width, its height,
## (the sole's lift)] ...] tail (+z) to snout (-z); neck (z: where the head
## begins); upper / lower tentacles: [base, way, length, thickness] (the
## right one's); skin_cell (mm: a tubercle's width).
var shape := {}
var clutch := 8 ## eggs laid after mating (selfed: half)
var self_rate := 0.3 ## how readily it selfs, alone (0..1)
var grow_secs := 240.0 ## s a hatchling takes to grow up

# each: its size (a share of full grown), what it's growing to; how far
# withdrawn (0..1) and wanting to be; s till it comes out; whether sealed
# (asleep); its mate (-1 none), the stage (1 coming together, 2 courting,
# 3 joined), how long at it; eggs it carries; s it's been alone, grown
var size := PackedFloat32Array()
var hide_k := PackedFloat32Array()
var hide_want := PackedFloat32Array()
var hide_t := PackedFloat32Array()
var sealed := PackedByteArray()
var mate_of := PackedInt32Array()
var stage := PackedByteArray()
var mate_t := PackedFloat32Array()
var rear_k := PackedFloat32Array()
var gravid := PackedInt32Array()
var alone_t := PackedFloat32Array()
var _was := PackedInt32Array()
var _enc := PackedFloat32Array()
var _laid_at := PackedFloat32Array() # (each egg's: when it was laid, _t)
var mate_secs := 40.0

# the slime trail: dabs on the ground, a ring of them, fading
const TRAIL_N := 2048
var _trail: MultiMeshInstance3D
var _trail_mat: ShaderMaterial
var _trail_k := 0
var _last := PackedVector3Array() # (where each last left a dab)


func _init() -> void:
	shader = SHADER
	body_h = 0.0
	lays = true
	lay_tilt = 0.0


func setup(n: int, c: Vector3, r: float) -> void:
	super(n, c, r)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	custom_aabb = custom_aabb.grow(0.05)
	for i in n:
		size[i] = 1.0
	_make_trail()


func add(at: Vector3, yaw_ := 0.0, r := 0.05) -> int:
	var i := super(at, yaw_, r)
	size[i] = 1.0
	return i


## A hatchling at `at` (its egg's place: its own space), tiny, growing up.
func hatchling(at: Vector3) -> int:
	var i := add(at, rng.randf() * TAU, 0.03)
	size[i] = 0.12
	return i


func _resize(n: int) -> void:
	var was := size.size()
	super(n)
	size.resize(n)
	hide_k.resize(n)
	hide_want.resize(n)
	hide_t.resize(n)
	sealed.resize(n)
	mate_of.resize(n)
	stage.resize(n)
	mate_t.resize(n)
	rear_k.resize(n)
	gravid.resize(n)
	alone_t.resize(n)
	_was.resize(n)
	_enc.resize(n)
	_last.resize(n)
	for i in range(was, n):
		mate_of[i] = -1
		size[i] = 1.0
		_last[i] = Vector3.INF


func _length() -> float:
	var b: Array = shape.body
	return float((b[0] as Array)[0]) - float((b[b.size() - 1] as Array)[0])


# --- their ways -------------------------------------------------------------------

func wander(i: int, c: Vector3, r: float) -> void:
	if task.size() > i and task[i] == DEAD:
		return
	super(i, c, r)
	hide_want[i] = 0.0
	sealed[i] = 0
	if mate_of[i] >= 0:
		_part(i)


func feed(i: int, f: Vector3) -> void:
	if task[i] == DEAD:
		return
	super(i, f)
	hide_want[i] = 0.0
	sealed[i] = 0


## Snail i withdrawn into its shell for secs (touched, startled), then out
## again, slowly, back to what it was doing.
func withdraw(i: int, secs := 10.0) -> void:
	if task[i] == DEAD:
		return
	if mate_of[i] >= 0:
		_part(i)
	if task[i] != HIDDEN:
		_was[i] = task[i]
	task[i] = HIDDEN
	hide_want[i] = 0.97
	hide_t[i] = secs
	target[i] = pos[i]


## Snail i asleep in its shell, its mouth sealed (epiphragm), till woken
## (wander).
func sleep(i: int) -> void:
	withdraw(i, INF)
	hide_want[i] = 1.0
	sealed[i] = 1


## Snail i dead: withdrawn for good, its empty shell left.
func die(i: int) -> void:
	if mate_of[i] >= 0:
		_part(i)
	task[i] = DEAD
	hide_want[i] = 1.0
	target[i] = pos[i]
	speed[i] = 0.0


func is_dead(i: int) -> bool:
	return task[i] == DEAD


## Snails i and j mating (both grown, both out and about): false if not.
func mate(i: int, j: int, secs := -1.0) -> bool:
	if i == j or i < 0 or j < 0 or i >= pos.size() or j >= pos.size():
		return false
	for k: int in [i, j]:
		if task[k] in [DEAD, HIDDEN] or mate_of[k] >= 0 or size[k] < 0.8:
			return false
	for k: int in [i, j]:
		_was[k] = task[k] if task[k] != 3 else 0
		task[k] = COURTING
		stage[k] = 1
		mate_t[k] = 0.0
	mate_of[i] = j
	mate_of[j] = i
	mate_secs = secs if secs > 0.0 else mate_secs
	return true


## Snail i's eggs its own (selfing, alone): gravid with a smaller clutch.
func self_fertilize(i: int) -> void:
	if task[i] != DEAD and gravid[i] == 0 and size[i] >= 0.8:
		gravid[i] = maxi(clutch / 2, 1)


## Laying: gravid, its clutch; not yet, its eggs its own first (selfing).
func lay(i: int, at: Vector3) -> void:
	if task[i] == DEAD:
		return
	if gravid[i] <= 0:
		self_fertilize(i)
	if gravid[i] <= 0:
		return
	if mate_of[i] >= 0:
		_part(i)
	super(i, at)
	hide_want[i] = 0.0


func _together(i: int, j: int) -> bool:
	return mate_of[i] == j


func _partner_array() -> PackedInt32Array:
	return mate_of


func _p_behaviours(_i: int) -> PackedStringArray:
	return PackedStringArray(["feed", "lay", "hide", "sleep"])


func _p_act(i: int, name: String, args: Dictionary) -> bool:
	match name:
		"hide":
			withdraw(i, float(args.get("seconds", 10.0)))
			return true
		"sleep":
			sleep(i)
			return true
	return super(i, name, args)


# --- each frame -------------------------------------------------------------------

func _process(dt: float) -> void:
	if multimesh == null or dt <= 0.0:
		return
	var n := pos.size()
	for i in n:
		# growing; drawn in or out; the pose told the shader
		if size[i] < 1.0:
			size[i] = minf(size[i] + dt / grow_secs * 0.88, 1.0)
		var want := hide_want[i]
		if task[i] in [HIDDEN, DEAD] or want > 0.0:
			pass
		hide_k[i] = move_toward(hide_k[i], want, dt * (0.9 if want > hide_k[i] else 0.18))
		var rear := 1.0 if task[i] == COURTING and stage[i] >= 2 else 0.0
		rear_k[i] = move_toward(rear_k[i], rear, dt * 0.25)
		var f := clampf(0.5 + 0.49 * (hide_k[i] - rear_k[i]), 0.0, 0.999)
		_enc[i] = floorf(clampf(size[i], 0.01, 1.0) * 1000.0) + f
	super(dt)
	_hatch_eggs()
	_slime(dt)


func _fly_array() -> PackedFloat32Array:
	if _enc.size() != pos.size():
		_enc.resize(pos.size())
	return _enc


func _fly_of(i: int) -> float:
	return _enc[i]


func _p_reach(i: int) -> float:
	return reach * MM * size[i] + 0.004


func _think(i: int, dt: float) -> void:
	wait[i] -= dt
	var t := task[i]
	if t == DEAD:
		target[i] = pos[i]
		feed_k[i] = move_toward(feed_k[i], 0.0, dt)
		lay_k[i] = move_toward(lay_k[i], 0.0, dt)
		return
	if t == HIDDEN:
		target[i] = pos[i]
		feed_k[i] = move_toward(feed_k[i], 0.0, dt)
		lay_k[i] = move_toward(lay_k[i], 0.0, dt)
		hide_t[i] -= dt
		if hide_t[i] <= 0.0 and sealed[i] == 0:
			hide_want[i] = 0.0
			if hide_k[i] < 0.05:
				task[i] = _was[i] if _was[i] not in [HIDDEN, COURTING, DEAD] else 0
				wait[i] = 0.0
		return
	if hide_k[i] > 0.3: # (still coming out: not going anywhere)
		target[i] = pos[i]
		return
	if t == COURTING:
		_court(i, dt)
		return
	# alone and grown a long while: its eggs its own (some kinds readily)
	if size[i] >= 0.8 and gravid[i] == 0:
		alone_t[i] += dt
		if alone_t[i] > SELF_AFTER and rng.randf() < self_rate * dt * 0.05:
			self_fertilize(i)
	# carrying eggs: off to lay them, a little way on
	if gravid[i] > 0 and t == 0 and rng.randf() < dt * 0.04:
		var a := rng.randf() * TAU
		lay(i, pos[i] + Vector3(cos(a), 0.0, sin(a)) * _length() * MM * size[i])
		return
	super(i, dt)


## Mating: coming together head to head; then reared up, the fronts of
## their feet pressed together, swaying (stage 2); joined (3), a while;
## then apart, both carrying eggs.
func _court(i: int, dt: float) -> void:
	var j := mate_of[i]
	if j < 0:
		task[i] = 0
		return
	mate_t[i] += dt
	var mid := (pos[i] + pos[j]) * 0.5
	var away := Vector3(pos[i].x - mid.x, 0.0, pos[i].z - mid.z)
	away = away.normalized() if away.length() > 1e-6 else Vector3.RIGHT
	var head := (float(shape.neck) * -1.0 + 4.0) * MM * size[i] # (its snout's reach ahead of its middle)
	var spot := mid + away * head * 0.85 + away.cross(Vector3.UP) * 1.2 * MM * size[i] # (a little to the side: right to right)
	feed_k[i] = move_toward(feed_k[i], 0.0, dt)
	match stage[i]:
		1:
			target[i] = spot
			if Vector2(pos[i].x - spot.x, pos[i].z - spot.z).length() < 0.0025 and stage[j] >= 1:
				stage[i] = 2
				mate_t[i] = 0.0
		2, 3:
			target[i] = pos[i]
			task[i] = COURTING
			# (turned to face it: as feeding faces its food)
			var to := mid - pos[i]
			var turn := wrapf(atan2(-to.x, -to.z) - yaw[i], -PI, PI)
			yaw[i] += clampf(turn, -0.6 * dt, 0.6 * dt)
			if stage[i] == 2 and mate_t[i] > 12.0:
				stage[i] = 3
				mate_t[i] = 0.0
			elif stage[i] == 3 and mate_t[i] > mate_secs:
				if i < j: # (once, for both)
					gravid[i] = clutch
					gravid[j] = clutch
				_part(i)


## Mating over (or broken off): each back to its ways.
func _part(i: int) -> void:
	var j := mate_of[i]
	for k: int in ([i, j] if j >= 0 else [i]):
		mate_of[k] = -1
		stage[k] = 0
		alone_t[k] = 0.0
		if task[k] == COURTING:
			task[k] = 0
			target[k] = pos[k]
			centre[k] = pos[k]
			radius[k] = maxf(radius[k], 0.05)
			wait[k] = rng.randf_range(2.0, 6.0)


## Its eggs, left in a clutch in the hole its head made (under its head).
func _drop_egg(i: int) -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var fwd := Vector3(-sin(yaw[i]), 0.0, -cos(yaw[i]))
	var lead := (-float(shape.neck) + 3.0) * MM * size[i]
	var p := pos[i] + fwd * lead + Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)) * 0.9 * MM * size[i]
	p.y = height.call(p.x, p.z) if height.is_valid() else pos[i].y
	var e := BroodScript.egg(egg_kind)
	var me := self
	e.set("on_hatch", func(at: Vector3) -> void:
		if is_instance_valid(me):
			me.hatchling(me.to_local(parent.to_global(at))))
	parent.add_child(e)
	e.global_transform = Transform3D(Basis(Vector3.UP, rng.randf() * TAU), global_transform * p)
	eggs.append(e)
	_laid_at.append(_t)
	if eggs.size() > 100:
		eggs.pop_front().queue_free()
		_laid_at.remove_at(0)
	gravid[i] -= 1
	if gravid[i] <= 0:
		gravid[i] = 0
		alone_t[i] = 0.0
		wander(i, pos[i], 0.05)


## (Its eggs hatching on their own, HATCH_SECS after they were laid.)
func _hatch_eggs() -> void:
	for k in range(eggs.size() - 1, -1, -1):
		if k < _laid_at.size() and _t - _laid_at[k] > HATCH_SECS:
			var e := eggs[k]
			if is_instance_valid(e):
				e.call("hatch")
			eggs.remove_at(k)
			_laid_at.remove_at(k)


# --- the slime trail ------------------------------------------------------------

func _make_trail() -> void:
	if _trail:
		return
	_trail = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	q.orientation = PlaneMesh.FACE_Y
	mm.mesh = q
	mm.instance_count = TRAIL_N
	mm.visible_instance_count = 0
	_trail.multimesh = mm
	_trail_mat = ShaderMaterial.new()
	_trail_mat.shader = preload("res://shaders/render/slime.gdshader")
	_trail.material_override = _trail_mat
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_trail.custom_aabb = custom_aabb
	add_child(_trail)


## A dab of slime under each that's moved its foot's width since its last.
func _slime(_dt: float) -> void:
	if _trail == null:
		return
	_trail_mat.set_shader_parameter("now", _t)
	var w := float((shape.body[shape.body.size() / 2] as Array)[1]) * 2.0 * MM
	var mm := _trail.multimesh
	for i in pos.size():
		if task[i] in [DEAD, HIDDEN] or speed[i] <= 0.0:
			continue
		var s := size[i]
		var gap := w * s * 0.55
		var p := pos[i]
		if _last[i] == Vector3.INF:
			_last[i] = p
			continue
		var d := p - _last[i]
		d.y = 0.0
		if d.length() < gap:
			continue
		var mid := (p + _last[i]) * 0.5
		var b := Basis(Vector3.UP, atan2(-d.x, -d.z)) * Basis.from_scale(Vector3(w * s * 0.7, 1.0, d.length() * 1.6))
		mm.set_instance_transform(_trail_k, Transform3D(b, mid + Vector3.UP * 0.0005))
		mm.set_instance_custom_data(_trail_k, Color(_t, rng.randf(), 0.0, 0.0))
		_trail_k = (_trail_k + 1) % TRAIL_N
		mm.visible_instance_count = maxi(mm.visible_instance_count, _trail_k if mm.visible_instance_count < TRAIL_N else TRAIL_N)
		_last[i] = p
	_trail.custom_aabb = custom_aabb


# --- the mesh -------------------------------------------------------------------

## The snail at rest, out and gliding (metres): every part tagged for the
## shader (CUSTOM0: its part; along it (a tentacle's 0 base .. 1 tip; the
## shell's whorls from the apex; the body's way round, 0 its sole's middle
## .. 1 its back's); the shell's way round its tube (0..1), or 1 at an eye;
## 1 on the shell's lip. UV.x: on the shell, how open to the light, 0 down
## in a suture .. 1); its joints (the shader's uniforms): [mesh, pivots].
func _build_mesh() -> Array:
	var S: Dictionary = shape
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 14
	sphere.rings = 8
	var SA := sphere.get_mesh_arrays()
	_body(st, S.body)
	# the shell
	var sh: Dictionary = S.shell
	var placed := _shell(st, sh)
	var ap: Vector3 = placed[0] # (its mouth's middle)
	var ax: Vector3 = placed[1] # (the way out of it)
	var rim: Array = placed[2]
	var spin: Basis = placed[3]
	var RN := rim.size()
	var a_ap := 0.0 # (its mouth's radius, the flare left out)
	for p: Vector3 in rim:
		a_ap += (p - ap).length() / RN
	a_ap /= 1.0 + float(sh.get("lip", 0.0))
	var inner := func(j: int, share: float) -> Vector3: # (a point inside the rim, by the mouth's own radius)
		var d: Vector3 = (rim[j % RN] as Vector3) - ap
		return d.normalized() * minf(d.length(), a_ap * 1.05) * share
	# the mantle: the body's stalk up from its back into the shell's mouth,
	# filling it; its collar a thick soft ring just inside the lip
	var zb := clampf(ap.z, float((S.body[S.body.size() - 1] as Array)[0]) * 0.6, float((S.body[0] as Array)[0]) * 0.6)
	var foot := Vector3(0.0, _height_at(zb) * 0.5, zb)
	var top := ap - ax * a_ap * 0.5
	var rb := _width_at(zb) * 0.95
	var pts := []
	var nrm := []
	var cus := []
	var uvs := []
	for i in 9:
		var f := float(i) / 8.0
		var c := foot.lerp(top, f)
		var row := []
		var nrow := []
		var crow := []
		var urow := []
		for j in RN + 1:
			var d_top: Vector3 = inner.call(j, 0.92)
			var d_low := Vector3(d_top.x, 0.0, d_top.z)
			d_low = (d_low.normalized() if d_low.length() > 1e-5 else Vector3.RIGHT) * rb * Vector3(1.0, 0.0, 1.5)
			var d := d_low.lerp(d_top, smoothstep(0.0, 0.85, f))
			row.append(c + d)
			nrow.append(d.normalized())
			crow.append(Color(6, f * 0.4, 0, 0))
			urow.append(Vector2.ONE)
		pts.append(row)
		nrm.append(nrow)
		cus.append(crow)
		uvs.append(urow)
	_grid(st, pts, nrm, cus, uvs)
	pts = []
	nrm = []
	cus = []
	uvs = []
	for k in RN + 1: # (a ring round the mouth, a little inside it)
		var dir: Vector3 = inner.call(k, 1.0)
		var row := []
		var nrow := []
		var crow := []
		var urow := []
		for j in 11:
			var b := TAU * j / 10.0
			var nn := (dir.normalized() * cos(b) + ax * sin(b)).normalized()
			row.append(ap - ax * a_ap * 0.42 + dir * 0.84 + nn * a_ap * 0.13)
			nrow.append(nn)
			crow.append(Color(6, 1.0, 1.0, 0))
			urow.append(Vector2.ONE)
		pts.append(row)
		nrm.append(nrow)
		cus.append(crow)
		uvs.append(urow)
	_grid(st, pts, nrm, cus, uvs)
	# its breathing pore, in the collar, by the lip (its right, up)
	var pore_dir: Vector3 = inner.call(RN / 8, 0.78)
	_put(st, SA, Transform3D(Basis(Quaternion(Vector3.UP, ax)) * Basis.from_scale(Vector3(a_ap * 0.26, a_ap * 0.08, a_ap * 0.26)), ap - ax * a_ap * 0.14 + pore_dir), Color(8, 0, 0, 0))
	# the epiphragm: a film over the mouth (drawn only sealed)
	for k in RN:
		for q: Vector3 in [ap + ax * a_ap * 0.03, ap - ax * a_ap * 0.04 + inner.call(k, 0.98), ap - ax * a_ap * 0.04 + inner.call(k + 1, 0.98)]:
			st.set_normal(ax)
			st.set_uv(Vector2.ONE)
			st.set_custom(0, Color(9, 0, 0, 0))
			st.add_vertex(q * MM)
	# the tentacles: the upper (long, tapering, an eye in the bulb at each
	# tip) and the lower (short), each one smooth stalk swelling from the head
	var bases := []
	var ways := []
	for which: int in [0, 1]:
		var tdef: Array = S.upper if which == 0 else S.lower
		for s: int in [0, 1]:
			var side := 1.0 if s == 1 else -1.0
			var b: Vector3 = tdef[0]
			b = Vector3(b.x * side, b.y, b.z)
			var w: Vector3 = tdef[1]
			w = Vector3(w.x * side, w.y, w.z).normalized()
			var ln: float = tdef[2]
			var r: float = tdef[3]
			var part := 2 + which * 2 + s
			var sx := w.cross(Vector3.UP).normalized()
			var sy := sx.cross(w).normalized()
			var droop := 0.07 if which == 0 else 0.0
			pts = []
			nrm = []
			cus = []
			uvs = []
			var segs := 12
			for k in segs + 1:
				var f := float(k) / segs
				var c := b + w * ln * (f * 1.06 - 0.06) - Vector3.UP * ln * droop * f * f + sx * side * ln * 0.04 * sin(f * PI)
				# (swelling into the head at its root, slimming, the bulb at its tip)
				var rr := r * (lerpf(1.0, 0.55, smoothstep(0.0, 0.9, f)) + 0.35 * pow(1.0 - f, 5.0))
				var row := []
				var nrow := []
				var crow := []
				var urow := []
				for j in 11:
					var ang := TAU * j / 10.0
					var d := sx * cos(ang) + sy * sin(ang)
					row.append(c + d * rr)
					nrow.append(d)
					crow.append(Color(part, f, 0, 0))
					urow.append(Vector2.ONE)
				pts.append(row)
				nrm.append(nrow)
				cus.append(crow)
				uvs.append(urow)
			_grid(st, pts, nrm, cus, uvs)
			var tip := b + w * ln - Vector3.UP * ln * droop
			var bulb := r * (0.72 if which == 0 else 0.62)
			_put(st, SA, Transform3D(Basis.from_scale(Vector3.ONE * bulb * 2.0), tip), Color(part, 1.0, 0, 0))
			if which == 0: # (its eye: a black dot in the bulb, up and out)
				_put(st, SA, Transform3D(Basis.from_scale(Vector3.ONE * bulb * 1.05), tip + (w * 0.5 + Vector3(side * 0.5, 0.7, 0.0)).normalized() * bulb * 0.58), Color(part, 1.0, 1.0, 0))
			bases.append(b * MM)
			ways.append(w)
	var neck_z: float = S.neck
	var head_h := _height_at(neck_z)
	var pivots := {
		"neck": Vector3(0.0, head_h * 0.5, neck_z) * MM,
		"mid": Vector3(0.0, 0.0, neck_z * 0.25) * MM,
		"ap": ap * MM,
		"ap_out": ax,
		"tent_base": PackedVector3Array(bases),
		"tent_dir": PackedVector3Array(ways),
		"snout_z": float((S.body[S.body.size() - 1] as Array)[0]) * MM,
		"tail_z": float((S.body[0] as Array)[0]) * MM,
		"shell_axis": spin * Vector3.UP,
		"shell_drop": float(placed[4]) * MM,
		"shell_whorls": float(sh.whorls),
		"shell_grow": float(sh.grow),
		"skin_cell": float(S.get("skin_cell", 0.8)) * MM,
	}
	st.generate_tangents()
	return [st.commit(), pivots]


## The body's keys at z (mm): [foot's half width, body's half width, height, lift].
func _body_at(z: float) -> Array:
	var b: Array = shape.body
	for k in b.size() - 1:
		var k0: Array = b[k]
		var k1: Array = b[k + 1]
		if z <= float(k0[0]) and z >= float(k1[0]):
			var f := (z - float(k0[0])) / (float(k1[0]) - float(k0[0]))
			return [lerpf(k0[1], k1[1], f), lerpf(k0[2], k1[2], f), lerpf(k0[3], k1[3], f)]
	var e: Array = b[b.size() - 1] if z < float((b[b.size() - 1] as Array)[0]) else b[0]
	return [e[1], e[2], e[3]]


## The body's height (mm) at z.
func _height_at(z: float) -> float:
	return _body_at(z)[2]


func _width_at(z: float) -> float:
	return _body_at(z)[1]


static func _cr(p0: float, p1: float, p2: float, p3: float, f: float) -> float:
	return 0.5 * (2.0 * p1 + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)


## The body, tail (+z) to snout (-z), one smooth skin: its sole flat on the
## ground, the foot's fringe a soft rim round it, creased above; the back
## rising from inside the rim, narrower, a dome; the tail low and pointed,
## the neck tall, the head a rounded lobe over the foot's front, its snout
## lifted. keys: [[z, the foot's half width, the body's half width, its
## height, (the sole's lift)] ...] (mm).
func _body(st: SurfaceTool, keys: Array) -> void:
	var K := keys.size()
	var steps := 76
	var SUB := 2
	var pts := []
	var cus := []
	var uvs := []
	var mids := []
	var key_at := func(j: int, c: int) -> float:
		var k: Array = keys[clampi(j, 0, K - 1)]
		return float(k[c]) if c < k.size() else 0.0
	for i in steps + 1:
		# (closer set toward both ends, where it's rounding off)
		var e := float(i) / steps
		var t := (e + 0.12 * sin(TAU * e) / TAU * -1.0) * (K - 1)
		var j := mini(int(t), K - 2)
		var f := t - j
		var kv := [0.0, 0.0, 0.0, 0.0, 0.0]
		for c in 5:
			kv[c] = _cr(key_at.call(j - 1, c), key_at.call(j, c), key_at.call(j + 1, c), key_at.call(j + 2, c), f)
		var z: float = kv[0]
		var fw := maxf(kv[1], 0.004)
		var bw := maxf(kv[2], 0.004)
		var bh := maxf(kv[3], 0.008)
		var lift := maxf(kv[4], 0.0)
		var fh := minf(bh * 0.3, fw * 0.45)
		var cp: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.55 * fw, 0.0), Vector2(0.9 * fw, 0.02 * fh), Vector2(fw, 0.42 * fh),
				Vector2(lerpf(bw, fw, 0.62), 0.92 * fh), Vector2(lerpf(bw, fw, 0.12), 1.08 * fh), Vector2(bw, fh + 0.32 * (bh - fh)),
				Vector2(0.93 * bw, fh + 0.62 * (bh - fh)), Vector2(0.7 * bw, fh + 0.86 * (bh - fh)), Vector2(0.36 * bw, fh + 0.97 * (bh - fh)),
				Vector2(0.0, bh)]
		var n := cp.size()
		var half: Array[Vector2] = []
		for a in n - 1:
			var p0 := cp[a - 1] if a > 0 else Vector2(-cp[1].x, cp[1].y)
			var p3 := cp[a + 2] if a + 2 < n else Vector2(-cp[n - 2].x, cp[n - 2].y)
			for q in SUB:
				var g := float(q) / SUB
				half.append(Vector2(_cr(p0.x, cp[a].x, cp[a + 1].x, p3.x, g), _cr(p0.y, cp[a].y, cp[a + 1].y, p3.y, g)))
		half.append(cp[n - 1])
		var H := half.size() - 1
		var row := []
		var crow := []
		var urow := []
		for k in 2 * H + 1: # (right side up from the sole's middle, over the back, down the left)
			var a := k if k <= H else 2 * H - k
			var sd := 1.0 if k <= H else -1.0
			var q := half[a]
			var y := lift + maxf(q.y, 0.0) * (bh - lift) / bh
			row.append(Vector3(maxf(q.x, 0.0) * sd, y, z))
			crow.append(Color(0, float(a) / H, 0, 0))
			urow.append(Vector2.ONE)
		pts.append(row)
		cus.append(crow)
		uvs.append(urow)
		mids.append(Vector3(0.0, lift + (bh - lift) * 0.45, z))
	# normals: across the grid, outward
	var nrm := []
	var R: int = (pts[0] as Array).size()
	for i in steps + 1:
		var nrow := []
		for k in R:
			var pa: Vector3 = (pts[mini(i + 1, steps)] as Array)[k]
			var pb: Vector3 = (pts[maxi(i - 1, 0)] as Array)[k]
			var pc: Vector3 = (pts[i] as Array)[(k + 1) % (R - 1)]
			var pd: Vector3 = (pts[i] as Array)[(k - 1 + R - 1) % (R - 1)]
			var nn := (pa - pb).cross(pc - pd)
			var p: Vector3 = (pts[i] as Array)[k]
			var away: Vector3 = p - (mids[i] as Vector3)
			if away.length() < 0.02: # (the ends, drawn to a point: along the body)
				away = Vector3(0.0, 0.0, 1.0 if i < steps / 2 else -1.0)
			if nn.length_squared() < 1e-10:
				nn = away
			elif nn.dot(away) < 0.0:
				nn = -nn
			nrow.append(nn.normalized())
		nrm.append(nrow)
	_grid(st, pts, nrm, cus, uvs)


## A grid of points (rows of them, mm) into st, each triangle turned to
## face the way its normals do.
static func _grid(st: SurfaceTool, pts: Array, nrm: Array, cus: Array, uvs: Array, xf := Transform3D.IDENTITY) -> void:
	for i in pts.size() - 1:
		var n: int = (pts[i] as Array).size()
		for j in n - 1:
			var quad := [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var vs := []
				for e: int in tri:
					vs.append(quad[e])
				var a: Vector3 = xf * (pts[vs[0][0]][vs[0][1]] as Vector3)
				var b: Vector3 = xf * (pts[vs[1][0]][vs[1][1]] as Vector3)
				var c: Vector3 = xf * (pts[vs[2][0]][vs[2][1]] as Vector3)
				var face := -(b - a).cross(c - a)
				if face.length_squared() < 1e-14:
					continue
				var want: Vector3 = xf.basis * ((nrm[vs[0][0]][vs[0][1]] as Vector3) + (nrm[vs[1][0]][vs[1][1]] as Vector3) + (nrm[vs[2][0]][vs[2][1]] as Vector3))
				var order := [0, 1, 2] if face.dot(want) >= 0.0 else [0, 2, 1]
				for o: int in order:
					var g: Array = vs[o]
					st.set_normal((xf.basis * (nrm[g[0]][g[1]] as Vector3)).normalized())
					st.set_uv(uvs[g[0]][g[1]])
					st.set_custom(0, cus[g[0]][g[1]])
					st.add_vertex((xf * (pts[g[0]][g[1]] as Vector3)) * MM)


## A primitive (a unit sphere's arrays) into st, placed by xf (mm), its
## CUSTOM0 c (along: c.y, or along(its own unit y) if given).
static func _put(st: SurfaceTool, arrays: Array, xf: Transform3D, c: Color, along := Callable()) -> void:
	var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var nb := xf.basis.inverse().transposed()
	for k in idx:
		st.set_normal((nb * ns[k]).normalized())
		st.set_uv(Vector2.ONE)
		var cc := c
		if along.is_valid():
			cc.g = along.call(vs[k].y)
		st.set_custom(0, cc)
		st.add_vertex((xf * vs[k]) * MM)


## The shell (sh: the species'), coiled, placed on the body: a tube along
## a growing spiral, from the apex out to the mouth, each whorl lapping the
## last. Its CUSTOM0: 7, the whorls from the apex, the way round the tube
## (0 its outside, 0.25 its top, the apex's side, 0.5 its inside, 0.75
## beneath), 1 on the lip; UV.x how open (0 down in a suture, under the
## next whorl .. 1). Carried as a dextral snail's is: its apex up and to
## the right (sh.apex), its mouth ahead of its axis (sh.mouth_side), the
## last whorl coming over the top and the left, down to the mouth, which
## opens down and to the right onto the body's back; the mouth's centre at
## sh.mouth (mm, on the body), cut slanting (sh.oblique, turns: its upper
## lip reaching on past its lower, so it opens downward). [its mouth's
## middle, the way out of it, its rim (points round it), the shell's turn
## (its own axis: the spire's), how far it settles, withdrawn (mm)].
func _shell(st: SurfaceTool, sh: Dictionary) -> Array:
	var whorls: float = sh.whorls
	var E: float = sh.grow
	var alpha: float = sh.tube
	var hq: float = sh.round
	var D: float = sh.spire
	var lip: float = sh.get("lip", 0.0)
	var descend: float = sh.get("descend", 0.0)
	var keel: float = sh.get("keel", 0.0)
	var R: float = float(sh.diam) * 0.5 / (1.0 + alpha * (1.0 + lip * 0.5)) # (the mouth's distance from the axis)
	var T := whorls * TAU
	var k := log(E) / TAU
	var ring := 28
	var steps := int(whorls * 64.0)
	var lip_span := 0.1 * TAU
	var t_min := 0.15
	# the mouth cut slanting (its upper lip reaching on past its lower: it
	# opens downward): where the tube ends, round it
	var cut: float = float(sh.get("oblique", 0.0)) * TAU
	var end_at := func(ph: float) -> float:
		return T - cut * (1.0 - sin(ph)) * 0.5
	# the tube's centre, radius, its frame, at t (te: where it ends, there)
	var at := func(t: float, te: float) -> Array:
		var r := R * exp(k * (t - T))
		var a := alpha * r
		var y := D * (R - r)
		if descend > 0.0: # (the last whorl dropping toward the mouth)
			y -= descend * R * smoothstep(T - 0.4 * TAU, T, t)
		var flare := 0.0
		if lip > 0.0 and t > te - lip_span:
			var f := (t - (te - lip_span)) / lip_span
			flare = lip * f * f
		return [Vector3(r * cos(t), y, r * sin(t)), a * (1.0 + flare), Vector3(cos(t), 0.0, sin(t)), flare, r] # (dextral: clockwise out from the apex)
	# a point round the tube (ph: 0 out, a quarter turn up), from the tube's middle
	var round_at := func(ph: float, a: float) -> Vector2:
		var c := cos(ph)
		var s := sin(ph)
		var out_k := 1.0 + keel * pow(maxf(c, 0.0), 6.0) # (its outside a little angled)
		return Vector2(c * a * out_k, s * a * hq)
	var pts := []
	var nrm := []
	var cus := []
	var uvs := []
	for i in steps + 1:
		var ti := maxf(float(i) / steps * T, t_min)
		var row := []
		var nrow := []
		var crow := []
		var urow := []
		for j in ring + 1:
			var ph := TAU * float(j) / ring
			var te: float = end_at.call(ph)
			var t := minf(ti, te)
			var c: Array = at.call(t, te)
			var radial: Vector3 = c[2]
			var q: Vector2 = round_at.call(ph, c[1])
			var p: Vector3 = (c[0] as Vector3) + radial * q.x + Vector3.UP * q.y
			row.append(p)
			nrow.append((radial * cos(ph) * hq + Vector3.UP * sin(ph)).normalized())
			crow.append(Color(7, t / TAU, float(j) / ring, clampf(float(c[3]) / maxf(lip, 1e-4), 0.0, 1.0) if lip > 0.0 else 0.0))
			# how open: its distance out of the whorls either side of it
			var open := 1.0
			for dt: float in [-TAU, TAU]:
				var t2: float = t + dt
				if t2 < t_min or t2 > te:
					continue
				var c2: Array = at.call(t2, te)
				var rho := float(c[4]) + q.x - float(c2[4])
				var dy: float = (c[0] as Vector3).y + q.y - (c2[0] as Vector3).y
				var a2: float = c2[1]
				var d := sqrt(rho * rho / (a2 * a2) + dy * dy / (a2 * a2 * hq * hq))
				open = minf(open, smoothstep(0.96, 1.3, d))
			urow.append(Vector2(open, 0.0))
		pts.append(row)
		nrm.append(nrow)
		cus.append(crow)
		uvs.append(urow)
	var end: Array = at.call(T, T)
	var mouth: Vector3 = end[0]
	# its own frame turned so its mouth is at +x, its tube opening along +z;
	# then on the body: its apex the species' way, its mouth to mouth_side
	# of its axis
	var canon := Basis(Vector3.UP, atan2(mouth.z, mouth.x))
	var apex: Vector3 = (sh.apex as Vector3).normalized()
	var side: Vector3 = (sh.get("mouth_side", Vector3(0.0, -0.2, -1.0)) as Vector3)
	side = (side - apex * side.dot(apex)).normalized()
	var spin := Basis(side, apex, side.cross(apex)) * canon
	var to: Vector3 = (sh.mouth as Vector3) - spin * mouth
	var xf := Transform3D(spin, to)
	_grid(st, pts, nrm, cus, uvs, xf)
	# the apex closed: a small cap
	var c0: Array = at.call(t_min, T)
	var cap_c := xf * (c0[0] as Vector3)
	var cap_r: float = c0[1]
	var sp := SphereMesh.new()
	sp.radius = 0.5
	sp.height = 1.0
	sp.radial_segments = 8
	sp.rings = 5
	_put(st, sp.get_mesh_arrays(), Transform3D(spin * Basis.from_scale(Vector3(2.0, 2.0 * hq, 2.0) * cap_r * 1.15), cap_c), Color(7, 0.0, 0.25, 0.0))
	# how far it settles, withdrawn: down till its lowest point's on the ground
	var low := INF
	for row: Array in pts:
		for p: Vector3 in row:
			low = minf(low, (xf * p).y)
	if low < 0.0:
		push_warning("snail shell under the ground by %.2f mm" % -low)
	# its mouth's rim (the tube's end, round it), its middle, the way out
	var rim := []
	var mid := Vector3.ZERO
	for j in ring:
		var p: Vector3 = xf * ((pts[steps] as Array)[j] as Vector3)
		rim.append(p)
		mid += p / ring
	var n_out := Vector3.ZERO
	for j in ring:
		n_out += ((rim[j] as Vector3) - mid).cross((rim[(j + 1) % ring] as Vector3) - mid)
	n_out = n_out.normalized()
	if n_out.dot(spin * (canon * Vector3(0.0, 0.0, 1.0))) < 0.0:
		n_out = -n_out
	return [mid, n_out, rim, spin, maxf(low, 0.0)]
