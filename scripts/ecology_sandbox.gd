class_name EcologySandbox
extends CanvasLayer
## Debug mode's ecology sandbox: the creature toolkit (tools/creatures/
## ecology_demo: the list, placing, selecting, the act keys) opened over the
## game, F9 or /sandbox, and closed again the same way (or its button). It
## has its own world (its plain, its sky and sun, its camera: a SubViewport
## with its own World3D), so nothing put down there gets into the game; the
## game stops underneath while it's open (paused, its 3D not drawn) and goes
## on as it was when it's closed. What's in the sandbox stays there, waiting,
## for the next time it's opened.
##
## While it's open: the trees whole (no levels of detail), day and clear air
## (the game's night and underwater not carried in), its own flower sway for
## the butterflies; all as they were again on closing.

const DEMO := "res://tools/creatures/ecology_demo.tscn"
const KEY := KEY_F9

var is_open := false
var _box: SubViewportContainer
var _view: SubViewport
var _demo: Node
var _mouse := Input.MOUSE_MODE_CAPTURED
var _was_3d := true


func _ready() -> void:
	layer = 8 # (over the HUD and the chat; under the pause menu)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = SubViewportContainer.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.stretch = true
	_box.visible = false
	add_child(_box)
	_view = SubViewport.new()
	_view.own_world_3d = true
	_view.handle_input_locally = true
	_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_view.process_mode = Node.PROCESS_MODE_DISABLED
	_box.add_child(_view)
	var back := Button.new()
	back.text = "Back to the world (F9)"
	back.focus_mode = Control.FOCUS_NONE
	back.anchor_left = 1.0 # (bottom right: clear of its panel and its key list)
	back.anchor_right = 1.0
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_left = -200.0
	back.offset_right = -8.0
	back.offset_top = -40.0
	back.offset_bottom = -8.0
	back.pressed.connect(close)
	_box.add_child(back)


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_was_3d = not get_viewport().disable_3d
	get_viewport().disable_3d = true # (the game's world, unseen under it: not drawn)
	_keep_globals()
	_box.visible = true
	_view.process_mode = Node.PROCESS_MODE_ALWAYS
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if _demo == null:
		_demo = (load(DEMO) as PackedScene).instantiate() # (its _ready: the trees whole, the sway)
		_view.add_child(_demo)
	else:
		OakTree.set_lod_fade(false)
		Lepidoptera.sway_of = Callable(_demo, "_sway_of")


func close() -> void:
	if not is_open:
		return
	is_open = false
	_box.visible = false
	_view.process_mode = Node.PROCESS_MODE_DISABLED
	_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	Engine.time_scale = 1.0 # (its slow motion, Space, not carried out)
	OakTree.set_lod_fade(true)
	Lepidoptera.sway_of = Callable()
	_put_globals_back()
	get_viewport().disable_3d = not _was_3d
	get_tree().paused = false
	Input.mouse_mode = _mouse


## The sandbox's own day, in clear air: the game's night and its
## underwater (global shader parameters) not carried in. (Godot can't read a
## global back outside the editor: the game's own are put back from where
## it keeps them, OakTree's night and main's set_global.)
func _keep_globals() -> void:
	RenderingServer.global_shader_parameter_set("night", 0.0)
	RenderingServer.global_shader_parameter_set("underwater", false)


func _put_globals_back() -> void:
	RenderingServer.global_shader_parameter_set("night", maxf(OakTree._night_sent, 0.0))
	var main := get_parent()
	var g: Dictionary = main.get("_globals") if main and main.get("_globals") is Dictionary else {}
	RenderingServer.global_shader_parameter_set("underwater", bool(g.get("underwater", false)))


## Open: every key the sandbox's (F9 closes it); none gets through to the
## game under it (Esc, the chat, the pause menu). The mouse goes through the
## container to it.
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY:
			close()
		else:
			_view.push_input(event)
		get_viewport().set_input_as_handled()
