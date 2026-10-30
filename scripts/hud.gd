class_name Hud
extends CanvasLayer

var player: Player
var underwater: ColorRect
var info: Label
var status: Label
var _slots: Array[Panel] = []
var _counts: Array[Label] = []


func _ready() -> void:
	underwater = ColorRect.new()
	underwater.color = Color(0.05, 0.25, 0.4, 0.45)
	underwater.set_anchors_preset(Control.PRESET_FULL_RECT)
	underwater.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underwater.visible = false
	add_child(underwater)

	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 26)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position -= Vector2(8, 18)
	add_child(cross)

	info = Label.new()
	info.position = Vector2(12, 8)
	info.add_theme_color_override("font_shadow_color", Color.BLACK)
	add_child(info)

	status = Label.new()
	status.set_anchors_preset(Control.PRESET_CENTER)
	status.position += Vector2(-120, 40)
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_shadow_color", Color.BLACK)
	add_child(status)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-9 * 56 / 2.0, -70)
	add_child(bar)
	for t in Player.HOTBAR:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(52, 52)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.45)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.3, 0.3, 0.3)
		slot.add_theme_stylebox_override("panel", sb)
		var sw := ColorRect.new()
		sw.color = BlockWorld.COLORS[t]
		sw.position = Vector2(10, 8)
		sw.size = Vector2(32, 26)
		slot.add_child(sw)
		var name := Label.new()
		name.text = BlockWorld.NAMES[t]
		name.add_theme_font_size_override("font_size", 10)
		name.position = Vector2(4, 36)
		slot.add_child(name)
		var count := Label.new()
		count.add_theme_font_size_override("font_size", 13)
		count.add_theme_color_override("font_shadow_color", Color.BLACK)
		count.position = Vector2(30, 2)
		slot.add_child(count)
		bar.add_child(slot)
		_slots.append(slot)
		_counts.append(count)


func refresh() -> void:
	for i in _slots.size():
		var sb: StyleBoxFlat = _slots[i].get_theme_stylebox("panel")
		sb.border_color = Color.WHITE if i == player.selected else Color(0.3, 0.3, 0.3)
		_counts[i].text = str(player.inventory[Player.HOTBAR[i]])


func _process(_delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	info.text = "%d fps   x %.0f  y %.1f  z %.0f%s\nWASD move · Space jump/swim · Ctrl sprint · F fly (Space/Shift up/down) · F5 third person\nLMB dig / break · RMB place · 1-9 / wheel select · C craft (log→planks, sand→glass) · Esc release mouse" % [
		Engine.get_frames_per_second(), p.x, p.y, p.z, "   [fly]" if player.flying else ""]
	underwater.visible = player.camera.global_position.y < 0.0
