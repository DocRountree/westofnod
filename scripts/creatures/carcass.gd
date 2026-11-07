class_name Carcass
extends RefCounted
## A big mammal dead of something else (sickness, cold, age, a fall): its
## carcass where it lies, in three stages of decay. For every mammal bigger
## than a beaver on the four-legged make (Carnivore): the grey wolf, the
## black and brown bears, the white-tailed deer, the moose, the bison.
##
## 1 fresh: the animal itself, dead: down on its side, its legs out stiff
##   (rigor), its head along the ground, its mouth a little open, its eyes
##   glazed, its tail out limp.
## 2 rotting: its skin sunk in (between its ribs, over its flanks and belly,
##   round its eyes; its legs thin), its fur slipped off in patches and the
##   skin under it discoloured green grey and purplish, its flesh open and
##   rotting at its belly, its face (its eyes gone) and its rump, wet; the
##   grass dark and dead round it where its fluids ran out, tufts
##   of its fur about (carnivore.gdshader: decay 1).
## 3 bones: its skeleton (built on its own frame where it lay: its skull and
##   lower jaw, its teeth, the antlers or horns still on the skull; its spine,
##   the spines up from its withers; its ribs and breastbone; its shoulder
##   blades and pelvis; each leg's bones, its hooves or claws still on its
##   feet; its tail's vertebrae), its hide dried and shrunk down onto the
##   bones, torn away in ragged holes, tatters of it left, the most along its
##   back and on its lower legs, here and there its fur still on them; dried
##   strips of flesh hanging off its ribs, sinews along its legs; a rib and a
##   vertebra or two fallen from it; the ground under it bare, pale, dead
##   (carnivore.gdshader: decay 2).
##
##   var c := Carcass.make(parent, DeerScript, at, yaw, 2)   # (stage 1..3)
##   Carcass.set_stage(c, 3)                                 # (later: further on)
##
## The carcass is the animal's own node, dead (dead = true, still: its process
## off), carrying meta "carcass" (its stage): eaten as carrion like any kill
## (a hunter's eat(it): stages 1 and 2).

const MM := 0.002
const BONE := Color(0.7, 0.64, 0.52)
const HIDE := Color(0.2, 0.13, 0.08)


## The carcass of an animal of script sc (a Carnivore make's: GreyWolf,
## BlackBear, BrownBear, Deer, Moose, Bison; args: its own _init's, after
## young (a deer's season, a bear's phase)), at `at` (its parent's space, on
## the ground), lying with its back toward yaw's right, at stage 1..3.
static func make(parent: Node, sc: Script, at: Vector3, yaw := 0.0, stage := 1, male := false, args := []) -> Node3D:
	var c: Node3D
	match args.size():
		0:
			c = sc.new(false)
		_:
			c = sc.new(false, args[0])
	c.set("male", male)
	parent.add_child(c)
	c.call("place", at, yaw)
	_lay_out(c)
	c.set_meta("carcass", 1)
	set_stage(c, stage)
	return c


## Its stage now (1 fresh, 2 rotting, 3 bones): further on (or back).
static func set_stage(c: Node3D, stage: int) -> void:
	stage = clampi(stage, 1, 3)
	c.set_meta("carcass", stage)
	var S: Dictionary = c.get("S")
	var decay := float(stage - 1)
	for mi in _meshes(c):
		var m := mi.material_override
		if m is ShaderMaterial and (m as ShaderMaterial).shader.resource_path.ends_with("carnivore.gdshader"):
			var sm := m as ShaderMaterial
			sm.set_shader_parameter("decay", decay)
			sm.set_shader_parameter("sink_mm", float(S.body_w))
			sm.set_shader_parameter("rib_mm", float(S.body_len) / 17.0)
	# its eyes: glazed, fresh; sunk away after
	for e: MeshInstance3D in c.get("_eyes"):
		e.visible = stage == 1
		if e.material_override is StandardMaterial3D and not e.has_meta("glazed"):
			e.set_meta("glazed", true)
			var em := (e.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			em.albedo_color = em.albedo_color.lerp(Color(0.42, 0.44, 0.42), 0.55)
			em.clearcoat = 0.2
			e.material_override = em
	# what's soft and goes first: its ears, its nose, its whiskers, its tongue (bones)
	var keep_parts := _bony_parts(c)
	for mi in _meshes(c):
		if mi.has_meta("carcass_bone") or keep_parts.has(mi) or mi == c.get("_torso"):
			continue
		if (c.get("_eyes") as Array).has(mi):
			continue
		if not mi.has_meta("carcass_vis"):
			mi.set_meta("carcass_vis", mi.visible) # (as the animal had it)
		mi.visible = false if stage == 3 else bool(mi.get_meta("carcass_vis"))
	var bones: Node3D = (c.get_meta("carcass_bones") if c.has_meta("carcass_bones") else null)
	if stage >= 2 and bones == null: # (inside it from the second stage: seen where it's rotted through)
		bones = _skeleton(c)
		c.set_meta("carcass_bones", bones)
	if bones:
		bones.visible = stage >= 2
		var bm: StandardMaterial3D = bones.get_meta("bone_mat")
		bm.albedo_color = Color(0.5, 0.3, 0.23) if stage == 2 else BONE # (still bloody, flesh on it; then bare)
		bm.roughness = 0.45 if stage == 2 else 0.75
	for b in _meshes(c): # (rotting: only a few broken bits of rib, and the meat, show through; then all of it)
		if b.has_meta("carcass_bone"):
			b.visible = stage == 3 or (stage == 2 and b.has_meta("rotting_shows"))
	_ground(c, stage)


## Down on its side, stiff: its legs out straight from its belly, its head
## along the ground, its mouth a little open, its tail out; then still.
static func _lay_out(c: Node3D) -> void:
	var S: Dictionary = c.get("S")
	var legs: Array = c.get("legs")
	c.set("dead", true)
	c.set("_mode", "carcass")
	c.set("_side", 1.37) # (its roll: 1.15 * this, a right angle: flat on its side)
	c.set("_lie_to", 1.0)
	c.set("_lie", 1.0)
	c.set("_sit", 0.0)
	c.set("_sit_to", 0.0)
	c.set("_curl", 0.0)
	c.set("_crouch", 0.0)
	c.set("_neck_to", Vector2(0.15, 0.0))
	c.set("_look_to", Vector2(0.1, 0.0))
	c.set("_jaw_to", 0.12)
	c.set("_tail_mode", "out")
	var bh: float = c.get("body_h")
	for k in 40:
		c.set("_lie", 1.0)
		c.call("_pose", 0.25)
		c.set("_lift", float(S.body_w) * 0.98 - bh) # (its middle half its width up: on its side)
		c.call("_place")
		# (its legs out straight as it stood, posed with its body upright so they
		# bend as a standing leg does, then its body rolled back over: stiff,
		# out from its belly, as rigor holds them)
		# (and each foot let down onto the ground: the upper pair fallen across
		# toward the lower, all four on the ground)
		var feet: Array = c.get("_pose_foot")
		var B: Transform3D = c.transform * (c.get("_body") as Node3D).transform
		var ground_y: float = (c.get("_pos") as Vector3).y
		for i in 4:
			var L: Dictionary = legs[i / 2]
			var side := 1.0 if i % 2 == 1 else -1.0
			var hm: Vector2 = L.home
			var home := Vector3(hm.x * side, -bh, hm.y + (-0.06 if i < 2 else 0.06) * float(S.body_len))
			var h := (B * home).y - ground_y - float(L.r) * MM * float(c.get("size")) * 0.6 # (its foot's sole on the ground, not its middle)
			feet[i] = home + B.basis.inverse() * Vector3(0.0, -h, 0.0)
		var roll: float = c.get("_roll")
		c.set("_roll", 0.0)
		c.call("_place")
		c.set("_lie", 0.0)
		c.call("_pose_legs")
		c.set("_roll", roll)
		c.call("_place")
	c.set("_lie", 1.0)
	c.set_process(false)
	c.set_physics_process(false)


static func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for ch in n.get_children():
		if ch is MeshInstance3D:
			out.append(ch)
		out.append_array(_meshes(ch))
	return out


## (The parts that last: horn, antler, claw, hoof (coat parts 7 and 4), and
## whatever's on its feet.)
static func _bony_parts(c: Node3D) -> Array:
	var out := []
	for mi in _meshes(c):
		var m := mi.material_override
		if m is ShaderMaterial:
			var pt := int((m as ShaderMaterial).get_shader_parameter("part"))
			if pt == 7 or pt == 4:
				out.append(mi)
	for x: Array in c.get("_legx"):
		for mi in _meshes(x[1] as Node):
			out.append(mi)
	return out


## Its skeleton, on its own frame as it lies (its body's mm, posed).
static func _skeleton(c: Node3D) -> Node3D:
	var S: Dictionary = c.get("S")
	var body: Node3D = c.get("_body")
	var root := Node3D.new()
	root.name = "bones"
	body.add_child(root)
	var bone := StandardMaterial3D.new()
	bone.albedo_color = BONE
	bone.roughness = 0.75
	root.set_meta("bone_mat", bone)
	var stained := StandardMaterial3D.new()
	stained.albedo_color = BONE.lerp(Color(0.45, 0.36, 0.24), 0.45)
	stained.roughness = 0.8
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.06, 0.045, 0.035)
	var hide := StandardMaterial3D.new()
	hide.albedo_color = HIDE
	hide.roughness = 0.65
	var bw := float(S.body_w)
	var bl := float(S.body_len)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(bl)
	var flesh: Array[StandardMaterial3D] = [] # (rotting flesh, still on it: dark red brown, wet; drier, darker)
	for fc: Color in [Color(0.3, 0.1, 0.07), Color(0.22, 0.09, 0.06), Color(0.26, 0.15, 0.09)]:
		var fm := StandardMaterial3D.new()
		fm.albedo_color = fc
		fm.roughness = 0.38
		fm.metallic_specular = 0.6
		flesh.append(fm)
	var meat := func(at: Vector3, size: Vector3, parent: Node3D) -> void: # (a lump of it, a little off round)
		var m: MeshInstance3D = c.call("_part", at, size * Vector3(rng.randf_range(0.8, 1.15), rng.randf_range(0.8, 1.15), rng.randf_range(0.85, 1.1)), flesh[rng.randi() % flesh.size()], parent)
		m.set_meta("carcass_bone", true)
		m.set_meta("rotting_shows", true)
	var stick := func(a: Vector3, b: Vector3, r: float, m: Material, parent: Node3D) -> MeshInstance3D:
		var mi: MeshInstance3D = c.call("_stick", a, b, r, m, parent)
		mi.set_meta("carcass_bone", true)
		return mi
	var ball := func(at: Vector3, size: Vector3, m: Material, parent: Node3D) -> MeshInstance3D:
		var mi: MeshInstance3D = c.call("_part", at, size, m, parent)
		mi.set_meta("carcass_bone", true)
		return mi
	# its body's keys: the spine along its back, the ribs round its chest
	var keys: Array = (S.body as Array).duplicate()
	keys.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var key_at := func(z: float) -> Vector3: # (y, half width, half height at z)
		var lo: Array = keys[0]
		var hi: Array = keys[keys.size() - 1]
		for k in keys.size() - 1:
			if z >= float(keys[k][0]) and z <= float(keys[k + 1][0]):
				lo = keys[k]
				hi = keys[k + 1]
				break
		var f := 0.0 if float(hi[0]) == float(lo[0]) else clampf((z - float(lo[0])) / (float(hi[0]) - float(lo[0])), 0.0, 1.0)
		return Vector3(lerpf(lo[1], hi[1], f), lerpf(lo[2], hi[2], f), lerpf(lo[3], hi[3], f))
	var F: Dictionary = S.fore
	var H: Dictionary = S.hind
	var z_front := float(keys[0][0]) + bl * 0.06
	var z_back := float(keys[keys.size() - 1][0]) - bl * 0.03
	var spine_y := func(z: float) -> float:
		var k: Vector3 = key_at.call(z)
		return k.x + k.z * 0.6
	# the spine: its vertebrae, their spines up (tallest over the withers: a
	# bison's hump is its spines)
	var nv := 26
	var withers := float(F.hip.z) + bl * 0.05
	var hump := 0.55 if float(S.get("body_h", 0.0)) > 900.0 and bw > 300.0 else 0.25
	for k in nv:
		var z := lerpf(z_front, z_back, float(k) / (nv - 1))
		var y: float = spine_y.call(z)
		var kz: Vector3 = key_at.call(z)
		ball.call(Vector3(0.0, y, z), Vector3(bw * 0.16, kz.z * 0.17, bl / nv * 0.85), bone, root)
		var up := kz.z * lerpf(0.1, hump, exp(-pow((z - withers) / (bl * 0.18), 2.0)))
		if rng.randf() < 0.8: # (the meat along its back, either side of the spines, rotting on it)
			for side: float in [-1.0, 1.0]:
				meat.call(Vector3(side * bw * 0.2, y + kz.z * 0.05, z), Vector3(bw * 0.3, kz.z * 0.32, bl / nv * 1.3), root)
		stick.call(Vector3(0.0, y, z), Vector3(0.0, y + up + kz.z * 0.08, z + bl / nv * 0.6), bw * 0.025, bone, root)
		if z > float(H.hip.z) - bl * 0.3 and z < float(H.hip.z) - bl * 0.05: # (the loins: the transverse processes out flat)
			for side: float in [-1.0, 1.0]:
				stick.call(Vector3(0.0, y, z), Vector3(side * bw * 0.32, y - kz.z * 0.05, z), bw * 0.02, bone, root)
	# the ribs: thirteen or so pairs, curving down and back round its chest
	# to the breastbone; the hindmost short (floating)
	var r_front := float(F.hip.z) - bl * 0.04
	var r_back := lerpf(float(F.hip.z), float(H.hip.z), 0.6)
	var nr := 13
	var fallen := rng.randi_range(2, nr - 2)
	var low := Vector3.ZERO
	for k in nr:
		var z := lerpf(r_front, r_back, float(k) / (nr - 1))
		var kz: Vector3 = key_at.call(z)
		var ys: float = spine_y.call(z)
		var last := 0.98 if k < nr - 3 else lerpf(0.75, 0.55, float(k - (nr - 3)) / 2.0)
		for side: float in [-1.0, 1.0]:
			if k == fallen and side > 0.0:
				continue # (that one fallen out of it, on the ground)
			var prev := Vector3(side * bw * 0.08, ys - kz.z * 0.05, z)
			for j in range(1, 8):
				var th := PI * float(j) / 7.0 * last
				var p := Vector3(side * sin(th) * kz.y * 0.84, kz.x + cos(th) * kz.z * 0.8, z + float(j) / 7.0 * bl / nr * 1.1)
				var seg: MeshInstance3D = stick.call(prev, p, bw * 0.03, bone, root)
				if j >= 2 and j <= 5 and rng.randf() < 0.2:
					seg.set_meta("rotting_shows", true) # (a bit of it showing through the rotted flank, the second stage)
				prev = p
			if k < nr - 3:
				low = prev
				var mid := Vector3(side * kz.y * 0.8, kz.x, z + bl / nr * 0.5)
				if rng.randf() < 0.65: # (a strip of flesh hanging off it)
					var g := (body.global_basis.inverse() * Vector3.DOWN).normalized()
					stick.call(mid, mid + g * bw * rng.randf_range(0.25, 0.7) + Vector3(0.0, 0.0, bw * 0.05), bw * rng.randf_range(0.03, 0.06), hide if rng.randf() < 0.4 else flesh[rng.randi() % flesh.size()], root)
				if rng.randf() < 0.4: # (meat still between its ribs)
					meat.call(mid * Vector3(0.95, 1.0, 1.0), Vector3(bw * 0.12, kz.z * 0.35, bl / nr * 1.1), root)
	var k0: Vector3 = key_at.call(r_front)
	var k1: Vector3 = key_at.call(lerpf(r_front, r_back, 0.75))
	stick.call(Vector3(0.0, k0.x - k0.z * 0.78, r_front + bl * 0.02), Vector3(0.0, k1.x - k1.z * 0.8, lerpf(r_front, r_back, 0.75)), bw * 0.06, bone, root) # (the breastbone)
	# the shoulder blades and the pelvis
	for side: float in [-1.0, 1.0]:
		var sh: Vector3 = F.hip
		var top := Vector3(side * bw * 0.55, spine_y.call(sh.z + bl * 0.05) - bw * 0.05, sh.z + bl * 0.07)
		var blade: MeshInstance3D = ball.call((Vector3(sh.x * side * 0.9, sh.y, sh.z) + top) * 0.5, Vector3(bw * 0.08, 1.0, bl * 0.12), bone, root)
		var d := top - Vector3(sh.x * side * 0.9, sh.y, sh.z)
		blade.transform = Transform3D(Basis(Vector3(bw * 0.08, 0.0, 0.0), d, Vector3(0.0, 0.0, bl * 0.12)), blade.position) # (flat, long: up the shoulder)
		var hp: Vector3 = H.hip
		var ilium := Vector3(side * bw * 0.4, spine_y.call(hp.z - bl * 0.08), hp.z - bl * 0.1)
		stick.call(Vector3(hp.x * side * 0.85, hp.y, hp.z), ilium, bw * 0.09, bone, root)
		stick.call(Vector3(hp.x * side * 0.85, hp.y, hp.z), Vector3(side * bw * 0.25, hp.y - bw * 0.1, hp.z + bl * 0.07), bw * 0.06, bone, root) # (the ischium, back)
		meat.call((Vector3(hp.x * side * 0.85, hp.y, hp.z) + ilium) * 0.5 + Vector3(side * bw * 0.08, 0.0, 0.0), Vector3(bw * 0.45, bw * 0.55, bl * 0.16), root) # (the haunch's meat on the pelvis)
		meat.call((Vector3(sh.x * side * 0.9, sh.y, sh.z) + top) * 0.5 + Vector3(side * bw * 0.06, 0.0, 0.0), Vector3(bw * 0.3, bw * 0.6, bl * 0.12), root) # (the shoulder's, on the blade)
	# each leg's bones, its joints knobbed; a sinew along it, dried
	var legs: Array = c.get("legs")
	var joints: Array = c.get("_joints")
	for i in 4:
		var J: Array = joints[i]
		if J == null or J.size() < 5:
			continue
		var L: Dictionary = legs[i / 2]
		var r := float(L.r)
		var radii := [0.42, 0.34, 0.26, 0.2]
		for q in 4:
			var a: Vector3 = J[q]
			var b: Vector3 = J[q + 1]
			stick.call(a, b, r * float(radii[q]), bone if q < 3 else stained, root)
			ball.call(a, Vector3.ONE * r * float(radii[q]) * 2.6, bone, root)
			if q < 2: # (its upper legs' meat, rotting on the bone)
				var thick := r * (1.6 if q == 0 else 0.9)
				meat.call(a.lerp(b, 0.45), Vector3(thick, thick, a.distance_to(b) * 0.8), root)
				var mi: MeshInstance3D = root.get_child(root.get_child_count() - 1)
				mi.look_at_from_position(mi.position, b, Vector3.UP if absf((b - a).normalized().y) < 0.9 else Vector3.RIGHT)
				mi.scale = Vector3(thick, thick, a.distance_to(b) * 0.8)
			if q < 2 and rng.randf() < 0.6:
				stick.call(a.lerp(b, 0.15) + Vector3(0.0, r * 0.3, 0.0), a.lerp(b, 0.85) + Vector3(0.0, r * 0.3, 0.0), r * 0.08, hide, root)
	# the neck's vertebrae
	var neck: Node3D = c.get("_neck")
	var nk: Array = S.neck
	for j in nk.size():
		var k: Array = nk[j]
		var nxt: Array = nk[mini(j + 1, nk.size() - 1)]
		var a := Vector3(0.0, float(k[1]) + float(k[3]) * 0.2, float(k[0]))
		var b := Vector3(0.0, float(nxt[1]) + float(nxt[3]) * 0.2, float(nxt[0])) if j + 1 < nk.size() else a + Vector3(0.0, 0.0, -float(k[3]) * 0.6)
		stick.call(a, b, float(k[2]) * 0.22, bone, neck)
		ball.call(a, Vector3(float(k[2]) * 0.55, float(k[3]) * 0.5, float(k[3]) * 0.5), bone, neck)
		meat.call(a + Vector3(0.0, float(k[3]) * 0.3, 0.0), Vector3(float(k[2]) * 0.9, float(k[3]) * 0.75, a.distance_to(b) * 1.1 + 1.0), neck)
	# the skull: its cranium and muzzle, narrower than the head was (no
	# muscle, no skin), its eye sockets empty, its nose open; its teeth; and
	# the lower jaw
	var head: Node3D = c.get("_head")
	var sc_: Dictionary = S.get("sculpt", {})
	if not sc_.is_empty():
		var zs: Array = sc_.z
		var tops: Array = sc_.top
		var bots: Array = sc_.bot
		var ws: Array = sc_.w
		for j in zs.size() - 1:
			var za := float(zs[j])
			var zb := float(zs[j + 1])
			var yc := (float(tops[j]) + float(bots[j]) + float(tops[j + 1]) + float(bots[j + 1])) * 0.25
			var h := (float(tops[j]) - float(bots[j]) + float(tops[j + 1]) - float(bots[j + 1])) * 0.5 * 0.72
			var w := (float(ws[j]) + float(ws[j + 1])) * 0.72
			ball.call(Vector3(0.0, yc + h * 0.05, (za + zb) * 0.5), Vector3(w, h, absf(zb - za) * 1.5), bone, head)
		var eye: Vector3 = sc_.eye
		var er := float(sc_.eye_r)
		for side: float in [-1.0, 1.0]:
			ball.call(Vector3(eye.x * side * 0.8, eye.y, eye.z), Vector3.ONE * er * 2.4, dark, head) # (its eye socket, empty)
			ball.call(Vector3(eye.x * side * 0.86, eye.y + er * 1.1, eye.z), Vector3(er * 1.4, er * 0.5, er * 2.6), bone, head) # (the bone over it)
		var zt := float(zs[zs.size() - 1])
		var ytip := (float(tops[tops.size() - 1]) + float(bots[bots.size() - 1])) * 0.5
		ball.call(Vector3(0.0, ytip, zt + 2.0), Vector3(float(ws[ws.size() - 1]) * 1.1, (float(tops[tops.size() - 1]) - float(bots[bots.size() - 1])) * 0.5, 6.0), dark, head) # (its nose, open)
		var tooth := StandardMaterial3D.new()
		tooth.albedo_color = Color(0.9, 0.86, 0.72)
		tooth.roughness = 0.4
		for side: float in [-1.0, 1.0]:
			for t in 6:
				var z := lerpf(float(zs[3]), lerpf(float(zs[3]), zt, 0.75), float(t) / 5.0)
				var j := 0
				while j < zs.size() - 1 and float(zs[j + 1]) > z:
					j += 1
				var bt := float(bots[j])
				var w := float(ws[j]) * 0.5
				ball.call(Vector3(side * w, bt * 0.85, z), Vector3(w * 0.35, absf(bt) * 0.18, absf(zt - float(zs[3])) / 7.0), tooth, head)
	# the lower jaw: its two halves, joined at the chin
	var jaw: Node3D = c.get("_jaw")
	var jk: Array = S.jaw
	var j0: Array = jk[0]
	var jl: Array = jk[jk.size() - 1]
	for side: float in [-1.0, 1.0]:
		stick.call(Vector3(side * float(j0[2]) * 0.6, float(j0[1]), float(j0[0])), Vector3(side * float(jl[2]) * 0.3, float(jl[1]), float(jl[0])), float(j0[3]) * 0.35, bone, jaw)
		stick.call(Vector3(side * float(j0[2]) * 0.6, float(j0[1]), float(j0[0])), Vector3(side * float(j0[2]) * 0.6, float(j0[1]) + float(j0[3]) * 1.6, float(j0[0]) + float(j0[3]) * 0.4), float(j0[3]) * 0.3, bone, jaw) # (up to its hinge)
	ball.call(Vector3(0.0, float(jl[1]), float(jl[0])), Vector3(float(jl[2]) * 0.8, float(jl[3]) * 0.7, float(jl[3]) * 1.2), bone, jaw)
	# the tail's vertebrae, smaller to its tip
	var tail: Array = c.get("_tail")
	var T: Dictionary = S.tail
	var radii_t: Array = T.radii
	for k in tail.size():
		var tn: Node3D = tail[k]
		var rr := float(radii_t[k]) * 0.3
		ball.call(Vector3(0.0, 0.0, float(T.seg) * 0.5), Vector3(rr * 1.6, rr * 1.6, float(T.seg) * 0.8), bone, tn)
	return root


## The ground under it: dark and wet with its fluids, the grass dead (rotting);
## bare, pale (bones); tufts of its fur about; a rib, a vertebra fallen.
static func _ground(c: Node3D, stage: int) -> void:
	var old: Node3D = (c.get_meta("carcass_ground") if c.has_meta("carcass_ground") else null)
	if old:
		old.queue_free()
		c.remove_meta("carcass_ground")
	if stage == 1:
		return
	var S: Dictionary = c.get("S")
	var size := float(c.get("size")) * MM
	var bl := float(S.body_len) * size
	var bw := float(S.body_w) * size
	var root := Node3D.new()
	root.top_level = true
	c.add_child(root)
	c.set_meta("carcass_ground", root)
	var p: Vector3 = c.get("_pos")
	var yaw: float = c.get("_yaw")
	root.global_transform = Transform3D(Basis(Vector3.UP, yaw), p)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(S.body_len) + stage
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.001
	disc.radial_segments = 18
	var stain_c := Color(0.13, 0.1, 0.06) if stage == 2 else Color(0.42, 0.36, 0.26)
	for k in 7: # (the stain: blotched, longer than wide, under it and its belly's side)
		var mi := MeshInstance3D.new()
		mi.mesh = disc
		var m := StandardMaterial3D.new()
		m.albedo_color = stain_c.lerp(Color(0.3, 0.27, 0.15), rng.randf() * 0.35)
		m.roughness = 0.4 if stage == 2 else 0.95
		mi.material_override = m
		var off := Vector3(rng.randf_range(-0.5, 0.5) * bw * 2.5, 0.0012 + 0.0002 * k, rng.randf_range(-0.45, 0.45) * bl)
		mi.position = off
		mi.scale = Vector3(bw * rng.randf_range(2.5, 4.0), 1.0, bl * rng.randf_range(0.5, 0.9))
		root.add_child(mi)
	var fur := StandardMaterial3D.new() # (tufts of its fur)
	fur.albedo_color = Color(0.35, 0.28, 0.2)
	fur.roughness = 1.0
	var tuft := SphereMesh.new()
	tuft.radius = 0.5
	tuft.height = 0.6
	for k in 14:
		var mi := MeshInstance3D.new()
		mi.mesh = tuft
		mi.material_override = fur
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.6, 1.4)
		mi.position = Vector3(cos(a) * bw * 2.2 * r, 0.004, sin(a) * bl * 0.6 * r)
		mi.scale = Vector3(bw * 0.25, bw * 0.06, bw * 0.18) * rng.randf_range(0.5, 1.2)
		mi.rotation.y = rng.randf() * TAU
		root.add_child(mi)
	if stage == 3: # (a rib and two vertebrae fallen from it, lying about)
		var bone := StandardMaterial3D.new()
		bone.albedo_color = BONE
		bone.roughness = 0.75
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 0.5
		cyl.height = 1.0
		cyl.radial_segments = 6
		var rib := MeshInstance3D.new()
		rib.mesh = cyl
		rib.material_override = bone
		rib.position = Vector3(bw * 2.6, bw * 0.06, bl * 0.1)
		rib.rotation = Vector3(PI * 0.5, rng.randf() * TAU, 0.0)
		rib.scale = Vector3(bw * 0.06, bw * 1.6, bw * 0.06)
		root.add_child(rib)
		var sph := SphereMesh.new()
		sph.radius = 0.5
		sph.height = 1.0
		for k in 2:
			var v := MeshInstance3D.new()
			v.mesh = sph
			v.material_override = bone
			v.position = Vector3(-bw * (2.0 + k), bw * 0.08, bl * (0.3 - 0.25 * k))
			v.scale = Vector3(bw * 0.3, bw * 0.2, bw * 0.22)
			root.add_child(v)
