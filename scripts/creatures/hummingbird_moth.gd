class_name HummingbirdMoth
extends "res://scripts/creatures/lepidoptera.gd" # (by path: found whether or not the editor has seen the class yet)
## A hummingbird clearwing (Hemaris thysbe), at twice life size (about 5 cm
## long, its wings 9 cm across): a stout, densely furred body, olive above,
## cream beneath the thorax and the head, two burgundy segments across the
## abdomen, a fan of a tail tuft, dark with yellowish edges; big dark eyes;
## stout black antennae thickening to a hooked tip; pale legs; clear,
## glassy wings, their veins, a dark bar closing the cell and a broad
## border toothed along the veins reddish brown, the bases olive and furred
## (bake_lepidoptera_wings.py), beating too fast to see (a blur, ~40 a
## second); a long proboscis. It never settles: it feeds hovering, like a hummingbird.
## Not yet in the game (tools/creatures/lepidoptera_demo.tscn).
##
## - search(centre, radius, flowers): darting about from hover to hover,
##   quick and straight, now and then hovering a moment in front of one of
##   the flowers (their heads, its parent's space) to look it over
## - feed(florets): hovering in front of a flower's florets one after
##   another, body tipped up, the proboscis in each (its parent's space),
##   holding there, the tail tuft fanned to steady it; on to another floret
##   every second or two

var _mode := ""
var _centre := Vector3.ZERO
var _radius := 0.5
var _flowers: Array = []
var _florets: Array = []
var _wait := 0.0
var _at := -1 # the floret it's at
var _tuft: Node3D


func _init() -> void:
	body_len = 25.0
	wing_len = 23.0
	wing_w = 9.0
	hind_len = 12.0
	hind_w = 8.0
	beat_hz = 40.0
	stroke = Vector2(-0.5, 1.2)
	max_speed = 2.2
	accel = 11.0
	proboscis = 24.0
	pattern = 1
	fore_wing = "hemaris_fore"
	hind_wing = "hemaris_hind"
	fore_hinge = Vector3(2.0, 2.2, -4.6)
	hind_hinge = Vector3(1.9, 1.9, -1.2)
	abdomen_at = Vector3(0.0, -0.1, 0.0)
	abdomen_tip = Vector3(0.0, -0.5, 12.5)
	egg_kind = "hemaris"
	hover_lay = true # (laying hovering, the tip just touched to the leaf)
	_head_at = Vector3(0.0, -0.8, -12.0)


func _build() -> void:
	var olive := Color(0.27, 0.28, 0.1)
	var olive_hi := Color(0.38, 0.37, 0.15) # (the fur's paler tips, over the shoulders)
	var cream := Color(0.56, 0.5, 0.3)
	var burgundy := Color(0.2, 0.045, 0.045)
	var dark := Color(0.04, 0.032, 0.026)
	# the thorax: big and round, densely furred olive above, cream beneath;
	# the shoulder flaps (tegulae) a paler olive
	# (one smooth furred body, not parts stacked: a loft, its colours by
	# where on it: _fur)
	var thorax := MeshInstance3D.new()
	thorax.mesh = HEX._loft([[-7.6, 0.4, 1.6, 1.5], [-6.6, 0.4, 3.0, 2.9], [-4.6, 0.3, 3.6, 3.3], [-2.0, 0.3, 3.7, 3.4], [0.0, 0.1, 3.4, 3.2], [1.2, 0.0, 2.6, 2.5], [1.8, 0.0, 1.0, 1.0]])
	thorax.material_override = _fur(olive, cream, burgundy, -100.0, -100.0)
	_body.add_child(thorax)
	for side: float in [-1.0, 1.0]:
		var teg := _part(Vector3(2.4 * side, 2.0, -3.8), Vector3(2.6, 2.2, 5.4), olive_hi, 0.95, null, 0.6)
		teg.rotation.z = -0.4 * side
	# the head: olive, the big dark eyes; cream palps under the face, the
	# coiled proboscis between
	_part(Vector3(0.0, 0.4, -8.0), Vector3(5.0, 4.4, 4.0), olive, 0.95, null, 0.5)
	for side: float in [-1.0, 1.0]:
		_part(Vector3(1.95 * side, 0.6, -8.6), Vector3(2.3, 3.1, 2.9), dark, 0.2)
	_part(Vector3(0.0, -1.5, -9.4), Vector3(3.2, 1.9, 2.4), cream, 0.95, null, 0.5)
	# the abdomen: stout, tapering, in segments: olive, then the two
	# burgundy ones, then olive-yellow; beneath, cream forward, dark
	# burgundy behind
	# (one smooth shell on the abdomen's joint, abdomen_at: it curls under
	# to lay; the burgundy band across segments four and five, the
	# segments' joints faint creases)
	var ab := MeshInstance3D.new()
	ab.mesh = HEX._loft([[-0.5, 0.0, 2.6, 2.5], [0.6, 0.0, 3.3, 3.1], [3.0, 0.0, 3.35, 3.15], [6.0, -0.15, 3.1, 2.9], [8.5, -0.25, 2.7, 2.5], [10.5, -0.35, 2.2, 2.0], [12.0, -0.4, 1.2, 1.1], [12.6, -0.4, 0.3, 0.3]])
	ab.material_override = _fur(olive, cream, burgundy, 5.0, 9.6)
	_abdomen.add_child(ab)
	# the tail fan: dark in the middle, yellowish at its edges, spread from
	# the tip (fanned wider to steady it, hovering: _think)
	_tuft = Node3D.new()
	_tuft.position = Vector3(0.0, -0.3, 11.8)
	_abdomen.add_child(_tuft)
	for k in 5:
		var a := (k - 2) * 0.32
		var col := dark if absi(k - 2) < 2 else olive_hi.darkened(0.15)
		var hair := _part(Vector3(sin(a) * 1.4, 0.0, cos(a) * 1.4), Vector3(1.3, 0.8, 3.2), col, 0.95, _tuft, 0.5)
		hair.rotation.y = a
	# stout black antennae, thickening along their length to a hooked tip
	_antennae(Vector3(1.0, 1.9, -9.4), 8.5, 0.8, dark, 0.3, 0.55, true)
	# pale legs
	_legs_at(Vector3(0.0, -2.8, -2.6), 4.5, cream.darkened(0.15))


const HEX := preload("res://scripts/creatures/hexapod.gd") # (its loft)
static var _fur_shader: Shader


## The furred body's colours: olive above, cream under the front, a
## burgundy band from band0 to band1 (mm along z), dark burgundy beneath
## behind it; faint creases at the segments' joints; a soft sheen at the
## rim (the fur catching the light round its edge).
static func _fur(olive: Color, cream: Color, burgundy: Color, band0: float, band1: float) -> ShaderMaterial:
	if _fur_shader == null:
		_fur_shader = Shader.new()
		_fur_shader.code = """shader_type spatial;
uniform vec3 olive : source_color;
uniform vec3 cream : source_color;
uniform vec3 burgundy : source_color;
uniform vec2 band = vec2(-100.0);
varying vec3 o;
void vertex() { o = VERTEX; }
void fragment() {
	float under = smoothstep(-0.8, -2.0, o.y); // (beneath)
	vec3 c = mix(olive, cream, under * (1.0 - smoothstep(4.0, 6.0, o.z)));
	float b = smoothstep(band.x - 0.4, band.x + 0.4, o.z) * (1.0 - smoothstep(band.y - 0.4, band.y + 0.4, o.z));
	c = mix(c, burgundy, b);
	c = mix(c, burgundy * 0.7, under * smoothstep(5.0, 6.0, o.z));
	if (o.z > 0.5) // (the abdomen's segments: faint creases)
		c *= 1.0 - 0.18 * smoothstep(0.82, 0.98, fract((o.z - 0.5) / 2.3));
	c *= 0.93 + 0.07 * sin(o.x * 9.0) * sin(o.z * 7.0 + o.y * 5.0); // (the fur's unevenness)
	ALBEDO = c;
	ROUGHNESS = 0.95;
	RIM = 0.6;
	RIM_TINT = 0.6;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _fur_shader
	m.set_shader_parameter("olive", olive)
	m.set_shader_parameter("cream", cream)
	m.set_shader_parameter("burgundy", burgundy)
	m.set_shader_parameter("band", Vector2(band0, band1))
	return m


## Its behaviours (a state machine's: pilot.gd): search {centre, radius,
## flowers, seconds}, feed {florets, seconds}, lay {spots, normals}.
func _p_behaviours() -> PackedStringArray:
	return PackedStringArray(["search", "feed", "mate"]) if male else PackedStringArray(["search", "feed", "lay", "mate"])


func _after_mate() -> void:
	search(_centre, _radius, _flowers)


func _p_act(name: String, args: Dictionary) -> bool:
	match name:
		"search":
			search(args.get("centre", _pos), float(args.get("radius", 0.5)), args.get("flowers", []))
		"feed":
			var f: Array = args.get("florets", [])
			if f.is_empty():
				return false
			feed(f)
		_:
			return super(name, args)
	return true


## Darting about round centre (within radius), now and then hovering in
## front of one of `flowers` (their heads: points, its parent's space).
func search(centre: Vector3, radius: float, flowers := []) -> void:
	_mode = "search"
	_centre = centre
	_radius = radius
	_flowers = flowers
	_wait = 0.0
	_tongue = 0.0
	_tongue_at = Vector3.INF


## Feeding at florets (points, its parent's space), one after another.
func feed(florets: Array) -> void:
	_mode = "feed"
	_florets = florets
	_at = -1
	_wait = 0.0


func _think(dt: float) -> void:
	_wait -= dt
	_jitter = 0.0015
	var hovering := (_target - _pos).length() < 0.02
	if _mode == "search":
		_tongue = 0.0
		if hovering and _wait <= 0.0:
			if not _flowers.is_empty() and rng.randf() < 0.45:
				# up to a flower, a few cm in front of it, facing it
				var f: Vector3 = _flowers[rng.randi() % _flowers.size()]
				var away := _flat(f, _pos)
				if away == Vector3.ZERO:
					away = Vector3.BACK
				_target = f + away * 0.07 + Vector3.UP * 0.01
				_look = -away
				_wait = rng.randf_range(0.5, 1.1)
			else:
				_target = _somewhere(_centre, _radius, 0.15, 0.9)
				_look = Vector3.ZERO
				_wait = rng.randf_range(0.3, 1.0)
		# darting: tipped forward going fast; hovering, tipped up, the tail down
		var speed := _vel.length()
		_pitch = lerpf(0.45, -0.25, clampf(speed / max_speed, 0.0, 1.0))
	elif _mode == "feed":
		if _florets.is_empty():
			return
		if _at < 0 or _wait <= 0.0:
			# on to another floret: one near the last, mostly
			var next := rng.randi() % _florets.size()
			if _at >= 0:
				var here: Vector3 = _florets[_at]
				for tries in 6:
					var c := rng.randi() % _florets.size()
					if c != _at and (_florets[c] as Vector3).distance_to(here) < 0.06:
						next = c
						break
			_at = next
			_wait = rng.randf_range(1.0, 2.4)
			_tongue = 0.0 # (out of the old one, into the next)
		var p: Vector3 = _florets[_at]
		# hovering in front of it, the head just over a proboscis' length off,
		# a little above, tipped up
		var away := _flat(p, _pos)
		if away == Vector3.ZERO:
			away = Vector3.BACK
		var off := (proboscis * 0.75 + 11.0) * MM
		_target = p + away * off + Vector3.UP * 0.012
		_look = -away
		_pitch = 0.5
		var there := (_target - _pos).length() < 0.01
		_tongue = 1.0 if there else 0.0
		_tongue_at = p
	# the tail tuft fanned out to steady it, holding still
	if _tuft:
		var spread := 1.0 + 0.6 * clampf(1.0 - _vel.length() / 0.4, 0.0, 1.0)
		_tuft.scale = Vector3(spread, 1.0, 1.0)
