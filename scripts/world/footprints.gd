class_name Footprints
extends Node
## The player's footprints: pressed into the mud (the forest's damp patches,
## the prairie's lowlands: WorldData.mud_at), and, the boots muddy from it,
## mud carried on in prints onto the forest's floor and its grass, less
## each step. Only near: a print is gone once the player's DESPAWN m off.
## Nothing kept.
##
## Each step is drawn once into a small texture over the WINDOW m round the
## player (a SubViewport, redrawn only when a step's taken or the window
## moves): R how deep it's pressed, B the rim the mud's squeezed up into,
## G the mud carried. The terrain (terrain.gdshader) reads it once a pixel,
## and only where there's a print works out the mud there and bends its
## normal by the print's slopes; the forest's grass (ground_cover: its
## trodden layer) once a clump: trodden flat, and muddied.

const WINDOW := 32.0 ## m across the texture covers
const PX := 1024 ## its pixels across (3 cm each)
const RECENTRE := 3.0 ## m the player goes from the window's middle before it follows
const DESPAWN := 12.0 ## m off a print is gone (inside the window, whichever way it's moved: WINDOW / 2 - RECENTRE)
const STRIDE := 0.72 ## m between steps (one foot, then the other)
const FOOT_APART := 0.1 ## m each foot from the line walked
const SOLE := Vector2(0.29, 0.105) ## m: a boot's print, long and wide
const MUD_KEPT := 0.78 ## of the mud on the boots left for the next step (the rest on the ground)
const MOST := 160 ## prints at most
const STAMP_MARGIN := 1.35 ## the stamp's size over the sole's (room for the rim)

var world: WorldData
var materials: Array[ShaderMaterial] = [] ## those that read the prints (terrain, the trodden grass)
var _prints: Array = [] # [Vector2 at (map), angle (rad, the toe's way, x toward z), left, pressed 0..1, mud 0..1]
var _vp: SubViewport
var _canvas: Node2D
var _stamp: ImageTexture
var _centre := Vector2.INF # the window's middle (map)
var _last := Vector2.INF # where the last step was taken
var _walked := 0.0 # m since
var _left := false
var _boots := 0.0 # mud on the boots, 0..1
var _dirty := false


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(PX, PX)
	_vp.disable_3d = true
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_canvas = Node2D.new()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD # (prints over prints: deeper, muddier)
	_canvas.material = add
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_canvas.draw.connect(_draw_prints)
	_vp.add_child(_canvas)
	add_child(_vp)
	_stamp = _make_stamp()
	for m in materials:
		m.set_shader_parameter("print_tex", _vp.get_texture())


## Each frame: the player's feet (map position), on the ground or not.
func update(feet: Vector3, on_ground: bool) -> void:
	var at := Vector2(feet.x, feet.z)
	if _centre == Vector2.INF or at.distance_to(_centre) > RECENTRE:
		var px := WINDOW / PX
		_centre = Vector2(snappedf(at.x, px), snappedf(at.y, px))
		_forget_far(at)
		_dirty = true
		var corner := _centre - Vector2(WINDOW, WINDOW) * 0.5
		for m in materials:
			m.set_shader_parameter("print_window", Vector3(corner.x, corner.y, WINDOW))
	if not on_ground:
		_last = Vector2.INF # (a jump, a swim, a flight: a fresh start where it lands)
	elif _last == Vector2.INF:
		_last = at
		_walked = 0.0
	else:
		var d := at.distance_to(_last)
		if d > STRIDE * 3.0:
			_last = at # (carried: no steps over the gap)
		elif d >= STRIDE:
			_step(_last, at)
			_last = at
	if _dirty:
		_dirty = false
		_canvas.queue_redraw()
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


## A step, from a to b: the foot down at b, beside the line walked.
func _step(a: Vector2, b: Vector2) -> void:
	var dir := (b - a).normalized()
	_left = not _left
	var side := Vector2(-dir.y, dir.x) * (FOOT_APART if _left else -FOOT_APART)
	var at := b + side
	var mud := world.mud_at(at.x, at.y) if world else 0.0
	# in the mud, pressed in and the boots muddied; out of it, the boots'
	# mud left in the print (only where it shows: not in the mud itself)
	var carried := _boots * (1.0 - mud)
	_boots = maxf(_boots * MUD_KEPT, mud)
	if mud <= 0.0 and carried < 0.04:
		return # (dry ground, clean boots: nothing to see)
	_prints.append([at, dir.angle(), _left, mud, carried])
	if _prints.size() > MOST:
		_prints.pop_front()
	_forget_far(b)
	_dirty = true


func _forget_far(at: Vector2) -> void:
	var kept: Array = []
	for p: Array in _prints:
		if (p[0] as Vector2).distance_to(at) <= DESPAWN:
			kept.append(p)
	if kept.size() != _prints.size():
		_prints = kept
		_dirty = true


func _draw_prints() -> void:
	var px := PX / WINDOW # pixels a metre
	var corner := _centre - Vector2(WINDOW, WINDOW) * 0.5
	var size := SOLE * px * STAMP_MARGIN
	for p: Array in _prints:
		var at: Vector2 = ((p[0] as Vector2) - corner) * px
		_canvas.draw_set_transform(at, p[1], Vector2(1.0, -1.0 if p[2] else 1.0)) # (the left foot the right's mirror)
		_canvas.draw_texture_rect(_stamp, Rect2(-size * 0.5, size), false, Color(p[3], p[4], p[3], 1.0))
	_canvas.draw_set_transform(Vector2.ZERO)


## A boot's sole, toe toward +x: R pressed in (the forefoot and the heel,
## a gap at the arch, cross-bars of tread), B the rim pushed up round it,
## G its shape (the mud left in it).
static func _make_stamp() -> ImageTexture:
	const W := 64
	const H := 24
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var u := ((x + 0.5) / W * 2.0 - 1.0) * STAMP_MARGIN # -1 heel .. 1 toe
			var v := ((y + 0.5) / H * 2.0 - 1.0) * STAMP_MARGIN
			# the forefoot and the heel, ovals, the arch narrower between
			var fore := Vector2((u - 0.38) / 0.62, v / (0.98 if u > 0.0 else 0.9)).length()
			var heel := Vector2((u + 0.66) / 0.34, v / 0.78).length()
			var arch := Vector2(u / 0.4 + 0.3, v / 0.55).length()
			var d := minf(minf(fore, heel), arch)
			var inside := 1.0 - smoothstep(0.8, 1.0, d)
			var tread := 0.82 + 0.18 * signf(sin(u * 38.0)) * (1.0 if arch > 1.0 else 0.0)
			var rim := smoothstep(0.85, 1.05, d) * (1.0 - smoothstep(1.05, 1.5, d))
			var shape := 1.0 - smoothstep(0.85, 1.0, d)
			img.set_pixel(x, y, Color(inside * tread, shape, rim, 1.0))
	return ImageTexture.create_from_image(img)
