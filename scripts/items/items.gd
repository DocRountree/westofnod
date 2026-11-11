class_name Items
## What can be carried: each kind of item, by id. The axe fells trees
## (Felling); the rest, for now, are only things to carry (/give in the chat;
## the pawpaw, crabapple, walnut and acorn picked from their trees, the flowers
## and cattails where they grow, the fungi on the ground and on the wood:
## Foraging; the lily pads and their flowers, LilyPad, once they're placed).
##
## Each: name, stack (how many fit in one slot or hand), and how it looks held
## (a primitive: shape, size in m, colour).

const KINDS := {
	"axe": {"name": "Axe", "stack": 1, "shape": "axe", "size": Vector3.ONE, "color": Color(0.55, 0.56, 0.58)},
	"stick": {"name": "Stick", "stack": 16, "shape": "cylinder", "size": Vector3(0.025, 0.55, 0.025), "color": Color(0.42, 0.3, 0.18)},
	"stone": {"name": "Stone", "stack": 16, "shape": "sphere", "size": Vector3(0.09, 0.07, 0.08), "color": Color(0.5, 0.49, 0.46)},
	"acorn": {"name": "Acorn", "stack": 10, "shape": "acorn", "size": Vector3(0.016, 0.024, 0.016), "color": Color(0.5, 0.36, 0.16), "bears": 18}, # (OakTree: its grown trees bear them, on long stalks, two or three together)
	# fruit (PawpawTree, CrabappleTree, WalnutTree: their trees bear them; and
	# OakTree the acorn, above; bears: how many a tree bears at most, Foraging)
	"pawpaw": {"name": "Pawpaw", "stack": 1, "shape": "pawpaw", "size": Vector3(0.055, 0.11, 0.05), "color": Color(0.55, 0.62, 0.24)},
	"crabapple": {"name": "Crabapple", "stack": 32, "shape": "crabapple", "size": Vector3(0.026, 0.024, 0.026), "color": Color(0.72, 0.16, 0.1)},
	"black_cherry": {"name": "Cherry", "stack": 64, "shape": "cherry", "size": Vector3(0.01, 0.01, 0.01), "color": Color(0.14, 0.03, 0.06), "bears": 20}, # (BlackCherryTree: up in its crown, in drooping clusters)
	"prickly_pear": {"name": "Prickly pear", "stack": 16, "shape": "prickly_pear", "size": Vector3(0.036, 0.054, 0.036), "color": Color(0.5, 0.08, 0.26), "bears": 10}, # (PricklyPear: its tunas on the rims of its top pads)
	"raspberry": {"name": "Raspberry", "stack": 64, "shape": "raspberry", "size": Vector3(0.016, 0.017, 0.016), "color": Color(0.74, 0.08, 0.16), "bears": 18}, # (RaspberryBush)
	"blueberry": {"name": "Blueberry", "stack": 64, "shape": "blueberry", "size": Vector3(0.011, 0.01, 0.011), "color": Color(0.27, 0.32, 0.52), "bears": 22}, # (BlueberryBush: dusky under its bloom)
	"walnut": {"name": "Walnut", "stack": 5, "shape": "walnut", "size": Vector3(0.046, 0.044, 0.046), "color": Color(0.43, 0.5, 0.18)}, # (in its green husk, as picked)
	# flowers and cattails (GroundCover: picked where they grow, Foraging):
	# a stem, its head(s) the petals' colour round the disc's
	"susan": {"name": "Blackeye", "stack": 16, "shape": "flower", "size": Vector3(0.068, 0.5, 1.0), "color": Color(0.96, 0.7, 0.06), "disc": Color(0.17, 0.08, 0.04), "heads": 1},
	"fleabane": {"name": "Fleabane", "stack": 16, "shape": "flower", "size": Vector3(0.022, 0.45, 1.0), "color": Color(0.96, 0.95, 0.96), "disc": Color(0.95, 0.78, 0.12), "heads": 3},
	"coneflower": {"name": "Purplecone", "stack": 16, "shape": "flower", "size": Vector3(0.09, 0.5, 1.0), "color": Color(0.78, 0.42, 0.62), "disc": Color(0.42, 0.2, 0.06), "heads": 1},
	"nettle": {"name": "Nettle", "stack": 16, "shape": "nettle", "size": Vector3(0.1, 0.6, 1.0), "color": Color(0.2, 0.33, 0.11)}, # (the forest's; picked, it doesn't sting)
	"aster": {"name": "Aster", "stack": 16, "shape": "flower", "size": Vector3(0.028, 0.5, 1.0), "color": Color(0.6, 0.45, 0.85), "disc": Color(0.93, 0.72, 0.12), "heads": 4},
	"milkweed": {"name": "Milkweed", "stack": 16, "shape": "flower", "size": Vector3(0.05, 0.6, 1.0), "color": Color(0.86, 0.56, 0.66), "disc": Color(0.93, 0.78, 0.82), "heads": 2},
	"swamp_milkweed": {"name": "Milkweed", "stack": 16, "shape": "flower", "size": Vector3(0.035, 0.55, 1.0), "color": Color(0.85, 0.3, 0.5), "disc": Color(0.95, 0.8, 0.86), "heads": 3},
	"tobacco": {"name": "Baccy", "stack": 16, "shape": "flower", "size": Vector3(0.024, 0.55, 1.0), "color": Color(0.97, 0.97, 0.94), "disc": Color(0.82, 0.86, 0.7), "heads": 3},
	"yampah": {"name": "Yampah", "stack": 16, "shape": "flower", "size": Vector3(0.04, 0.6, 1.0), "color": Color(0.95, 0.95, 0.9), "disc": Color(0.85, 0.86, 0.72), "heads": 3},
	# a pot to catch sap in (Tapping: under a maple's notch), and full
	"clay_pot": {"name": "Pot", "stack": 4, "shape": "pot", "size": Vector3(0.15, 0.15, 0.15), "color": Color(0.66, 0.38, 0.24)},
	"pot_of_sap": {"name": "Pot of sap", "stack": 1, "shape": "pot", "size": Vector3(0.15, 0.15, 0.15), "color": Color(0.66, 0.38, 0.24), "full": Color(0.78, 0.6, 0.3)},
	# fungi (Fungus: picked whole where they grow, Foraging; held, one of them)
	"morel": {"name": "Morel", "stack": 16, "shape": "fungus", "size": Vector3(0.04, 0.1, 0.04), "color": Color(0.7, 0.58, 0.38)},
	"fly_agaric": {"name": "Fly agaric", "stack": 8, "shape": "fungus", "size": Vector3(0.14, 0.18, 0.14), "color": Color(0.8, 0.1, 0.04)},
	"little_brown": {"name": "Browncap", "stack": 32, "shape": "fungus", "size": Vector3(0.025, 0.06, 0.025), "color": Color(0.44, 0.3, 0.17)},
	"chicken_of_the_woods": {"name": "Chicken of the woods", "stack": 4, "shape": "fungus", "size": Vector3(0.14, 0.04, 0.1), "color": Color(0.95, 0.5, 0.08)},
	# water lilies (LilyPad: picked whole where they float; held, one of them)
	"lily_pad": {"name": "Lily pad", "stack": 16, "shape": "lily", "size": Vector3(0.18, 0.2, 0.01), "color": Color(0.22, 0.38, 0.12)},
	"water_lily": {"name": "Water lily", "stack": 8, "shape": "lily", "size": Vector3(0.1, 0.18, 0.1), "color": Color(0.96, 0.95, 0.92)},
	"spatterdock": {"name": "Spatterdock", "stack": 8, "shape": "lily", "size": Vector3(0.05, 0.16, 0.05), "color": Color(0.93, 0.76, 0.1)},
	"cattail": {"name": "Cattail", "stack": 16, "shape": "cattail", "size": Vector3(0.024, 0.75, 0.16), "color": Color(0.36, 0.22, 0.12)},
}


const ACORN_CUP := Color(0.42, 0.37, 0.27) ## an acorn's cup


static func exists(id: String) -> bool:
	return KINDS.has(id)


static func name_of(id: String) -> String:
	return KINDS[id].name if KINDS.has(id) else id


static func stack_of(id: String) -> int:
	return int(KINDS[id].stack) if KINDS.has(id) else 1


static func color_of(id: String) -> Color:
	return KINDS[id].color if KINDS.has(id) else Color.MAGENTA


## The item as held: a small model, centred on the grip.
static func model(id: String) -> Node3D:
	var k: Dictionary = KINDS.get(id, {"shape": "box", "size": Vector3.ONE * 0.05, "color": Color.MAGENTA})
	if k.shape == "axe":
		return _axe()
	if id == "stick":
		return _stick()
	if k.shape in ["pawpaw", "crabapple", "walnut", "acorn", "cherry", "raspberry", "blueberry", "prickly_pear"]:
		return _fruit(k)
	if k.shape == "flower":
		return _flower(k)
	if k.shape == "cattail":
		return _cattail(k)
	if k.shape == "nettle":
		return _nettle(k)
	if k.shape == "pot":
		return _pot(k)
	if k.shape == "fungus": # (one of them, as it grew: Fungus)
		var fm := MeshInstance3D.new()
		fm.mesh = Fungus.held(id)
		fm.position.y = -k.size.y * 0.4
		fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var holder := Node3D.new()
		holder.add_child(fm)
		return holder
	if k.shape == "lily": # (a pad by its stalk, a flower on its: LilyPad)
		var lm := MeshInstance3D.new()
		lm.mesh = LilyPad.held(id)
		lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var lh := Node3D.new()
		lh.add_child(lm)
		return lh
	var mesh: PrimitiveMesh
	match k.shape:
		"cylinder":
			mesh = CylinderMesh.new()
			mesh.top_radius = 0.5
			mesh.bottom_radius = 0.5
			mesh.height = 1.0
			mesh.radial_segments = 8
		"sphere":
			mesh = SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 1.0
			mesh.radial_segments = 10
			mesh.rings = 6
		_:
			mesh = BoxMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = k.size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = k.color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## An axe, of stone: a stick for a handle, 60 cm, held a third of the way
## up; at its top a sharp stone, knapped to an edge, set in a split in it
## and lashed there with twine, wound round above and below it and across;
## the edge forward (-z).
static func _axe() -> Node3D:
	var root := Node3D.new()
	var wood := Color(0.47, 0.36, 0.24)
	# the stick: a little crooked, thicker at its foot, a knot or two; its
	# bark (a shader: streaked, fissured, lenticels), and the twine painted on
	# where it's wound round, above and below the stone, tight, turn on turn
	var low := _part(CylinderMesh.new(), Vector3(0.03, 0.34, 0.03), wood)
	low.material_override = _stick_mat(wood, -0.03, 0.34)
	low.position.y = -0.03
	root.add_child(low)
	var high := _part(CylinderMesh.new(), Vector3(0.027, 0.36, 0.027), wood)
	high.material_override = _stick_mat(wood.darkened(0.06), 0.31, 0.36)
	high.position = Vector3(0.0, 0.31, 0.004)
	high.rotation.x = -0.03
	root.add_child(high)
	for k in [[Vector3(0.012, 0.08, 0.0), 0.012], [Vector3(-0.011, 0.25, 0.006), 0.01]]:
		var knot := _part(SphereMesh.new(), Vector3.ONE * float(k[1]), wood.darkened(0.25))
		knot.position = k[0]
		root.add_child(knot)
	# the stone: a flattened, tapering blade, its edge thinner and paler
	# (knapped); the lashing painted across it where it's bound to the stick
	var stone := Color(0.33, 0.32, 0.3)
	var head := _part(SphereMesh.new(), Vector3(0.032, 0.085, 0.16), stone)
	head.material_override = _stone_mat(stone, 0.22)
	head.position = Vector3(0.0, 0.41, -0.035)
	root.add_child(head)
	var edge := _part(SphereMesh.new(), Vector3(0.012, 0.075, 0.06), stone.lightened(0.25))
	edge.position = Vector3(0.0, 0.41, -0.1)
	(edge.material_override as StandardMaterial3D).roughness = 0.5
	root.add_child(edge)
	var butt := _part(SphereMesh.new(), Vector3(0.03, 0.06, 0.05), stone.darkened(0.1))
	butt.material_override = _stone_mat(stone.darkened(0.1), -0.7)
	butt.position = Vector3(0.0, 0.41, 0.035)
	root.add_child(butt)
	return root


## A stick, picked up or broken off a limb (55 cm, along y, its middle at
## the origin): a little crooked (two lengths meeting at a slight angle),
## thicker at its foot, tapering; a knot or two, a twig's stub; its bark the
## axe handle's (_stick_mat: streaked, fissured, lenticels, a little
## lichen; no twine); each end broken, the pale wood showing.
static func _stick() -> Node3D:
	var root := Node3D.new()
	var wood := Color(0.47, 0.36, 0.24)
	var joint := Vector3(0.0, 0.01, 0.0) # (where its two lengths meet: a node, turned a little there)
	var bend := -0.06
	var segs := [[joint - Vector3(0.0, 0.145, 0.0), 0.29, 0.0135, 0.012, 0.0], [joint + Vector3(0.0, cos(bend), sin(bend)) * 0.14, 0.28, 0.012, 0.0095, bend]]
	for i in segs.size():
		var g: Array = segs[i]
		var cm := CylinderMesh.new()
		cm.height = float(g[1])
		cm.bottom_radius = float(g[2])
		cm.top_radius = float(g[3])
		cm.radial_segments = 10
		cm.rings = 4
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = _stick_mat(wood.darkened(0.05 * i), 5.0 + float(i), 1.0) # (well away from where the axe's twine is painted)
		mi.position = g[0]
		mi.rotation.x = float(g[4])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	var node := MeshInstance3D.new() # (the node where it bends: a little swollen)
	var nm := SphereMesh.new()
	nm.radius = 0.0128
	nm.height = 0.03
	nm.radial_segments = 10
	nm.rings = 6
	node.mesh = nm
	node.material_override = _stick_mat(wood.darkened(0.03), 6.0, 1.0)
	node.position = joint
	root.add_child(node)
	# its knots, a twig's stub
	for kn: Array in [[Vector3(0.011, -0.06, 0.002), 0.009], [Vector3(-0.009, 0.17, 0.008), 0.008]]:
		var knot := _part(SphereMesh.new(), Vector3(1.0, 0.7, 1.0) * float(kn[1]), wood.darkened(0.3))
		knot.position = kn[0]
		root.add_child(knot)
	var stub := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.height = 0.035
	sm.bottom_radius = 0.0045
	sm.top_radius = 0.003
	sm.radial_segments = 6
	stub.mesh = sm
	stub.material_override = _stick_mat(wood.darkened(0.1), 7.0, 0.1)
	stub.position = Vector3(0.012, 0.04, 0.0)
	stub.rotation.z = -0.9
	root.add_child(stub)
	# its ends, broken: the pale wood, a little splintered
	for e: Array in [[Vector3(0.0, -0.28, 0.0), 0.0125], [joint + Vector3(0.0, cos(bend), sin(bend)) * 0.28, 0.0092]]:
		var end := _part(SphereMesh.new(), Vector3(2.0, 0.6, 2.0) * float(e[1]), Color(0.72, 0.6, 0.42))
		end.position = e[0]
		root.add_child(end)
	return root


const TWINE := Color(0.62, 0.52, 0.34)
static var _stick_sh: Shader
static var _stone_sh: Shader


## A stick's bark: grey brown, streaked along its length, fine fissures
## and lenticels, a little lichen; and where twine's wound round it (y0: its
## middle's height on the axe, ys its length: the bands at 0.35-0.385 and
## 0.435-0.47), the twine, turn on turn, tight, each turn's groove shaded.
static func _stick_mat(c: Color, y0: float, ys: float) -> ShaderMaterial:
	if _stick_sh == null:
		_stick_sh = Shader.new()
		_stick_sh.code = """shader_type spatial;
uniform vec3 wood : source_color;
uniform vec3 twine : source_color;
uniform float y0 = 0.0;
uniform float ys = 1.0;
varying vec3 o;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void vertex() { o = VERTEX; }
void fragment() {
	float y = y0 + o.y * ys; // (its height on the axe, m)
	float a = atan(o.x, o.z) / 6.2832 + 0.5; // (round it, 0 .. 1)
	vec2 g = vec2(a * 9.0, y * 40.0); // (bark: streaks along it)
	float streak = vn(g * vec2(1.0, 0.25)) * 0.6 + vn(g * vec2(2.3, 0.6) + 7.0) * 0.4;
	float fiss = smoothstep(0.58, 0.72, vn(vec2(a * 26.0, y * 10.0) + 3.0)) * smoothstep(0.3, 0.6, vn(vec2(a * 5.0, y * 50.0))); // (fine fissures along it, dark)
	float lent = smoothstep(0.86, 0.92, vn(vec2(a * 60.0, y * 220.0))); // (lenticels: short pale dashes across)
	vec3 c = wood * (0.6 + 0.75 * streak);
	c = mix(c, mix(wood, vec3(0.42, 0.4, 0.36), 0.5), smoothstep(0.55, 0.8, vn(vec2(a * 3.0, y * 6.0) + 21.0)) * 0.45); // (grey patches of its outer bark)
	c = mix(c, wood * 0.32, fiss * 0.9);
	c = mix(c, wood * 1.6 + vec3(0.06), lent * 0.75);
	c = mix(c, vec3(0.5, 0.52, 0.42), smoothstep(0.7, 0.85, vn(vec2(a * 4.0, y * 9.0) + 11.0)) * 0.25); // (a little lichen)
	float rough = 0.85;
	// (the twine: wound tight, turn on turn, round it in two bands)
	float band = step(0.35, y) * step(y, 0.385) + step(0.435, y) * step(y, 0.47);
	if (band > 0.0) {
		float turn = fract(y / 0.0032 + a * 1.0); // (a helix: a turn every 3 mm)
		float groove = smoothstep(0.0, 0.35, min(turn, 1.0 - turn));
		float fib = vn(vec2(a * 140.0, y * 900.0)); // (its fibres, twisted)
		c = twine * (0.55 + 0.45 * groove) * (0.85 + 0.25 * fib);
		rough = 0.95;
	}
	ALBEDO = c;
	ROUGHNESS = rough;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _stick_sh
	m.set_shader_parameter("wood", c)
	m.set_shader_parameter("twine", TWINE)
	m.set_shader_parameter("y0", y0)
	m.set_shader_parameter("ys", ys)
	return m


## The stone's: knapped facets (flat patches, a little paler at their
## edges); and the lashing across it where it's bound to the stick (at z
## stick_z: the part's own, -0.5 .. 0.5), two bands crossing, each its turns.
static func _stone_mat(c: Color, stick_z: float) -> ShaderMaterial:
	if _stone_sh == null:
		_stone_sh = Shader.new()
		_stone_sh.code = """shader_type spatial;
uniform vec3 stone : source_color;
uniform vec3 twine : source_color;
uniform float stick_z = 0.0;
varying vec3 o;
float h(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void vertex() { o = VERTEX; }
void fragment() {
	// (its facets: the nearest of a few points, each patch its own shade)
	vec3 q = o * 7.0;
	vec3 cell = floor(q);
	float best = 9.0; float second = 9.0; vec3 id = cell;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 k = cell + vec3(float(x), float(y), float(z));
		float d = length(q - k - vec3(h(k), h(k + 3.1), h(k + 5.7)));
		if (d < best) { second = best; best = d; id = k; } else if (d < second) { second = d; }
	}
	vec3 c = stone * (0.85 + 0.3 * h(id));
	c = mix(c, stone * 1.35, (1.0 - smoothstep(0.0, 0.06, second - best)) * 0.5); // (the ridges between them)
	float rough = 0.7;
	// (the lashing: two bands crossing over it at the stick, its turns)
	float dz = o.z - stick_z;
	float near = 1.0 - smoothstep(0.16, 0.2, abs(dz));
	float d1 = abs(o.y - dz * 1.4);
	float d2 = abs(o.y + dz * 1.4);
	float lash = max(1.0 - smoothstep(0.05, 0.065, d1), 1.0 - smoothstep(0.05, 0.065, d2)) * near;
	if (lash > 0.5) {
		float along = d1 < d2 ? (o.y + dz) : (o.y - dz);
		float turn = fract(along / 0.035);
		float groove = smoothstep(0.0, 0.35, min(turn, 1.0 - turn));
		c = twine * (0.55 + 0.45 * groove);
		rough = 0.95;
	}
	ALBEDO = c;
	ROUGHNESS = rough;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _stone_sh
	m.set_shader_parameter("stone", c)
	m.set_shader_parameter("twine", TWINE)
	m.set_shader_parameter("stick_z", stick_z)
	return m


## A ring of twine (a torus): radius r, thickness t.
static func _ring(r: float, t: float, c: Color) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = r - t
	m.outer_radius = r + t
	m.rings = 12
	m.ring_segments = 5
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.95
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A clay pot (a lathe's round: a narrow foot, a full belly, a shoulder, a
## lip), its middle at the origin; with sap in it to near its shoulder if
## it's full.
static func _pot(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var h: float = k.size.y
	var prof := [Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.056, 0.012), Vector2(0.07, 0.05), Vector2(0.072, 0.088),
			Vector2(0.062, 0.122), Vector2(0.052, 0.138), Vector2(0.058, 0.15), Vector2(0.054, 0.15), Vector2(0.047, 0.138), Vector2(0.056, 0.12), Vector2(0.064, 0.088), Vector2(0.062, 0.05), Vector2(0.05, 0.016), Vector2(0.0, 0.012)] # (out, up the outside, over the lip, down the inside)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const N := 20
	for i in prof.size() - 1:
		var a: Vector2 = prof[i]
		var b: Vector2 = prof[i + 1]
		for j in N:
			var t0 := TAU * j / N
			var t1 := TAU * (j + 1) / N
			var q := [Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x), Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x),
					Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x), Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x)]
			for idx in [0, 2, 1, 0, 3, 2]:
				st.add_vertex((q[idx] as Vector3) * (h / 0.15) - Vector3.UP * h * 0.5)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = k.color
	mat.roughness = 0.9
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	if k.has("full"):
		var sap := _part(CylinderMesh.new(), Vector3(0.11, 0.004, 0.11) * (h / 0.15), k.full)
		sap.position.y = h * 0.3
		(sap.material_override as StandardMaterial3D).roughness = 0.08
		root.add_child(sap)
	return root


## A fruit: its body (a pawpaw's long, a little lopsided, green going
## yellow; a crabapple's a small round apple, red; a walnut's a round green
## husk, dull, freckled with paler spots, on a short, stout stalk), and its
## stalk.
static func _fruit(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var body := _part(SphereMesh.new(), k.size, k.color)
	(body.material_override as StandardMaterial3D).roughness = 0.45 if k.shape == "crabapple" else (0.8 if k.shape == "walnut" else (0.35 if k.shape == "acorn" else 0.6))
	root.add_child(body)
	if k.shape == "acorn":
		# its cup: scaly, grey brown, over its top third; its point below; its
		# long stalk (an English oak's: pedunculate)
		var cup := _part(SphereMesh.new(), (k.size as Vector3) * Vector3(1.12, 0.55, 1.12), ACORN_CUP)
		cup.position.y = k.size.y * 0.3
		(cup.material_override as StandardMaterial3D).roughness = 0.95
		root.add_child(cup)
		var tip := _part(SphereMesh.new(), Vector3(0.003, 0.004, 0.003), (k.color as Color).darkened(0.4))
		tip.position.y = -k.size.y * 0.5
		root.add_child(tip)
		var stalk := _part(CylinderMesh.new(), Vector3(0.0022, 0.03, 0.0022), Color(0.36, 0.32, 0.2))
		stalk.position.y = k.size.y * 0.5 + 0.014
		root.add_child(stalk)
		return root
	if k.shape == "cherry": # (glossy; its long stalk)
		(body.material_override as StandardMaterial3D).roughness = 0.2
		var cs := _part(CylinderMesh.new(), Vector3(0.0012, 0.03, 0.0012), Color(0.35, 0.4, 0.18))
		cs.position.y = 0.019
		root.add_child(cs)
		return root
	if k.shape == "raspberry": # (a cap of drupelets)
		(body.material_override as StandardMaterial3D).roughness = 0.5
		for i in 26:
			var y := lerpf(-0.9, 0.85, fposmod(i * 0.618, 1.0))
			var a := i * 2.4
			var dir := Vector3(cos(a) * sqrt(1.0 - y * y), y, sin(a) * sqrt(1.0 - y * y))
			var dr := _part(SphereMesh.new(), Vector3.ONE * 0.0055, (k.color as Color).lightened(0.08 * fposmod(i * 0.37, 1.0)))
			(dr.material_override as StandardMaterial3D).roughness = 0.35
			dr.position = dir * (k.size as Vector3) * 0.47
			root.add_child(dr)
		return root
	if k.shape == "prickly_pear": # (a tuna: egg shaped, wine red, its areoles dotted over it, each a tuft of fine brown glochids; its top a flat cupped scar)
		(body.material_override as StandardMaterial3D).roughness = 0.55
		for i in 18:
			var y := lerpf(-0.8, 0.75, fposmod(i * 0.618, 1.0))
			var a := i * 2.4
			var dir := Vector3(cos(a) * sqrt(1.0 - y * y), y, sin(a) * sqrt(1.0 - y * y))
			var ar := _part(SphereMesh.new(), Vector3.ONE * 0.003, Color(0.32, 0.22, 0.12))
			(ar.material_override as StandardMaterial3D).roughness = 0.95
			ar.position = dir * (k.size as Vector3) * 0.5
			root.add_child(ar)
		var scar := _part(CylinderMesh.new(), Vector3(0.016, 0.004, 0.016), (k.color as Color).darkened(0.35))
		scar.position.y = (k.size as Vector3).y * 0.48
		root.add_child(scar)
		return root
	if k.shape == "blueberry": # (dusky under its bloom; the little crown at its tip)
		(body.material_override as StandardMaterial3D).roughness = 0.85
		var cr := _part(SphereMesh.new(), Vector3(0.0045, 0.0015, 0.0045), (k.color as Color).darkened(0.5))
		cr.position.y = (k.size as Vector3).y * 0.48
		root.add_child(cr)
		return root
	if k.shape == "walnut":
		# the husk's freckles: a few small pale spots round it
		for i in 7:
			var a := TAU * i / 7.0 + 0.4
			var y := 0.35 * sin(i * 2.3)
			var dir := Vector3(cos(a) * sqrt(1.0 - y * y), y, sin(a) * sqrt(1.0 - y * y))
			var dot := _part(SphereMesh.new(), Vector3.ONE * 0.006, (k.color as Color).lightened(0.35))
			dot.position = dir * (k.size as Vector3) * 0.48
			root.add_child(dot)
		var stem := _part(CylinderMesh.new(), Vector3(0.005, 0.02, 0.005), Color(0.33, 0.3, 0.16))
		stem.position.y = k.size.y * 0.5 + 0.008
		root.add_child(stem)
		return root
	if k.shape == "pawpaw":
		# lopsided: a second, smaller lobe to one side, and the dark scar at the stalk end
		var lobe := _part(SphereMesh.new(), k.size * Vector3(0.85, 0.7, 0.85), Color(0.6, 0.64, 0.26))
		lobe.position = Vector3(0.006, -0.02, 0.0)
		root.add_child(lobe)
		var scar := _part(CylinderMesh.new(), Vector3(0.012, 0.01, 0.012), Color(0.25, 0.2, 0.12))
		scar.position.y = k.size.y * 0.5
		root.add_child(scar)
	else:
		var stalk := _part(CylinderMesh.new(), Vector3(0.0025, 0.035, 0.0025), Color(0.35, 0.27, 0.15))
		stalk.position.y = k.size.y * 0.5 + 0.015
		stalk.rotation.z = 0.25
		root.add_child(stalk)
	return root


## A flower, picked: its stem (size.y long, held near its foot), and at
## its top a head or a few (size.x across): the petals a flat disc, the
## middle a small dome.
static func _flower(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var len: float = k.size.y
	var stem := _part(CylinderMesh.new(), Vector3(0.005, len, 0.005), Color(0.3, 0.42, 0.15))
	stem.position.y = len * 0.5 - 0.06
	root.add_child(stem)
	var n: int = k.get("heads", 1)
	var w: float = k.size.x
	for i in n:
		var a := TAU * i / n
		var off := Vector3(cos(a), 0.0, sin(a)) * (0.0 if n == 1 else w * 1.4)
		var top := Vector3(0.0, len - 0.06 + (0.0 if n == 1 else -0.02 * (i % 2)), 0.0) + off
		var petals := _part(CylinderMesh.new(), Vector3(w, 0.004, w), k.color)
		petals.position = top
		root.add_child(petals)
		var disc := _part(SphereMesh.new(), Vector3(w * 0.38, w * 0.3, w * 0.38), k.disc)
		disc.position = top + Vector3.UP * 0.003
		root.add_child(disc)
	return root


## A stinging nettle, picked: its square stem (size.y long), its leaves in
## pairs up it, each pair square to the last, heart shaped, pointed,
## drooping, toothed; tassels of tiny green flowers hanging from the upper
## axils.
static func _nettle(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var len: float = k.size.y
	var green: Color = k.color
	var stem := _part(BoxMesh.new(), Vector3(0.005, len, 0.005), green.darkened(0.15)) # (square)
	stem.position.y = len * 0.5 - 0.06
	root.add_child(stem)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = green
	leaf_mat.roughness = 0.8
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 6:
		var f := float(i) / 5.0
		var y := lerpf(0.05, len - 0.08, f)
		var turn := float(i) * PI * 0.5
		var l := lerpf(0.1, 0.05, f)
		for sd: float in [-1.0, 1.0]:
			var holder := Node3D.new()
			holder.position = Vector3(0.0, y, 0.0)
			holder.rotation = Vector3(0.0, turn + (0.0 if sd > 0.0 else PI), 0.0)
			root.add_child(holder)
			var leaf := MeshInstance3D.new()
			leaf.mesh = _nettle_leaf(l, l * 0.55)
			leaf.material_override = leaf_mat
			leaf.rotation.z = -0.35 # (drooping)
			holder.add_child(leaf)
			if f > 0.35 and f < 0.95: # (a tassel of its flowers)
				var tassel := _part(CylinderMesh.new(), Vector3(0.004, 0.05, 0.004), green.lightened(0.15))
				tassel.position = Vector3(0.025, -0.02, 0.012)
				tassel.rotation.z = 0.5
				holder.add_child(tassel)
	return root


## A nettle's leaf (along +x from its stalk, l long, w wide): heart shaped,
## pointed, its edge toothed.
static func _nettle_leaf(l: float, w: float) -> ArrayMesh:
	const N := 14
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3] = [Vector3.ZERO]
	for i in N + 1: # (round one side of it to its tip, and back down the other)
		var t := float(i) / N
		var half := w * 0.5 * sin(PI * pow(t, 0.75)) * (1.0 + 0.12 * (1.0 - absf(fmod(t * 9.0, 1.0) * 2.0 - 1.0))) # (its teeth)
		pts.append(Vector3(t * l, 0.0, half))
	for i in range(N - 1, 0, -1):
		var t := float(i) / N
		var half := w * 0.5 * sin(PI * pow(t, 0.75)) * (1.0 + 0.12 * (1.0 - absf(fmod(t * 9.0, 1.0) * 2.0 - 1.0)))
		pts.append(Vector3(t * l, 0.0, -half))
	var mid := Vector3(l * 0.4, 0.0, 0.0)
	for i in range(1, pts.size()):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i % (pts.size() - 1)) + 1]
		st.set_normal(Vector3.UP)
		st.add_vertex(mid)
		st.set_normal(Vector3.UP)
		st.add_vertex(a)
		st.set_normal(Vector3.UP)
		st.add_vertex(b)
	return st.commit()


## A cattail, picked: its stalk (size.y long) and the brown head near its
## top (size.x across, size.z long), a thin spike above.
static func _cattail(k: Dictionary) -> Node3D:
	var root := Node3D.new()
	var len: float = k.size.y
	var stalk := _part(CylinderMesh.new(), Vector3(0.012, len, 0.012), Color(0.38, 0.45, 0.2))
	stalk.position.y = len * 0.5 - 0.1
	root.add_child(stalk)
	var head := _part(CylinderMesh.new(), Vector3(k.size.x, k.size.z, k.size.x), k.color)
	head.position.y = len - 0.1 - 0.06 - k.size.z * 0.5
	root.add_child(head)
	var spike := _part(CylinderMesh.new(), Vector3(0.004, 0.08, 0.004), Color(0.45, 0.4, 0.25))
	spike.position.y = len - 0.1 + 0.02
	root.add_child(spike)
	return root


static func _part(mesh: PrimitiveMesh, size: Vector3, c: Color) -> MeshInstance3D:
	if mesh is CylinderMesh:
		mesh.top_radius = 0.5
		mesh.bottom_radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 8
	elif mesh is SphereMesh:
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 12
		mesh.rings = 8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.6
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
