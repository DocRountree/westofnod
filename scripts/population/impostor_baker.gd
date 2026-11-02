class_name ImpostorBaker
extends Node
## Photographs each standing oak for its far-off card (OakTree._impostor,
## impostor.gdshader): FRAMES copies of its level-2 mesh side by side, each
## turned a step further round, taken at once from the side by an
## orthographic camera (every level drawn whole: lod_fade.gdshaderinc),
## unlit (the viewport's unshaded drawing: the colours alone), on black
## that's transparent. One tree a frame, as OakTree asks for them; until its
## photograph's in, a tree's card draws nothing.

const FRAMES := 8 ## ways round
const PX := 160 ## each photograph's side (px): a tree 250 m off is about 60 px tall

var _vp: SubViewport
var _cam: Camera3D
var _row: Node3D
var _busy := false


func _ready() -> void:
	process_priority = 100 # (after main.gd has told the materials the night: put back to day for the photograph)
	_vp = SubViewport.new()
	_vp.size = Vector2i(PX * FRAMES, PX)
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	_vp.msaa_3d = Viewport.MSAA_DISABLED
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	_cam.near = 1.0
	_cam.far = 600.0
	_vp.add_child(_cam)
	_row = Node3D.new()
	_vp.add_child(_row)


func _process(_delta: float) -> void:
	if _busy or OakTree.impostor_jobs.is_empty():
		return
	_bake(OakTree.impostor_jobs.pop_front())


func _bake(job: Array) -> void:
	_busy = true
	var mesh: Mesh = job[1]
	var mat: ShaderMaterial = job[2]
	var side: float = job[3]
	var mid: float = job[4]
	for c in _row.get_children():
		c.queue_free()
	for k in FRAMES:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# k: seen from k steps round (toward +x from +z, in its own space)
		mi.position = Vector3((k - (FRAMES - 1) * 0.5) * side, -mid, 0.0)
		mi.rotation.y = -TAU * k / FRAMES
		_row.add_child(mi)
	# (from 250 m, as the level hands over: its cards thinned as there)
	_cam.position = Vector3(0.0, 0.0, 250.0)
	_cam.size = side
	var night := OakTree._night
	OakTree.set_night(0.0) # (its colours by day: the card dims them itself)
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	OakTree.set_night(night)
	var img := _vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	mat.set_shader_parameter("atlas", ImageTexture.create_from_image(img))
	for c in _row.get_children():
		c.queue_free()
	_busy = false
