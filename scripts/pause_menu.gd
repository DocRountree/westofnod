class_name PauseMenu
extends CanvasLayer
## Esc in the game: everything stops, and the mouse is free. Resume (or Esc
## again), save (in a game; it also saves itself), back to the start menu
## (saving first), or quit (saving first).

var main: Node
var _panel: Control
var _save: Button
var _note: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	(_panel as ColorRect).color = Color(0, 0, 0, 0.55)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	add_child(_panel)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(centre)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 10)
	centre.add_child(box)
	var title := Label.new()
	title.text = "Paused" if not Session.debug else "Paused (debug mode)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	_button(box, "Resume", close)
	_save = _button(box, "Save", _on_save)
	_save.visible = not Session.debug
	_button(box, "Main menu", _to_menu)
	_button(box, "Quit", _quit)
	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.modulate = Color(0.7, 0.9, 0.7)
	box.add_child(_note)


func _button(parent: Control, text: String, on: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on)
	parent.add_child(b)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	if main.chat and main.chat.open:
		return
	if _panel.visible:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()


func open() -> void:
	_note.text = ""
	_panel.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_panel.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_save() -> void:
	main.save_game()
	_note.text = "Saved."


func _to_menu() -> void:
	main.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")


func _quit() -> void:
	main.save_game()
	get_tree().quit()
