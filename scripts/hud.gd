class_name Hud
extends CanvasLayer

var player: Player
var underwater: ColorRect
var info: Label
var status: Label


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


func _process(_delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var place := ""
	var cfg := WorldConfig.current()
	var clk := GameClock.current()
	if clk:
		place = "   %s   %.1f°%s %.1f°%s" % [clk.time_text(), absf(cfg.latitude), "N" if cfg.latitude >= 0.0 else "S",
				absf(cfg.longitude), "E" if cfg.longitude >= 0.0 else "W"]
	info.text = "%d fps   x %.0f  y %.1f  z %.0f%s%s\nWASD move · Space jump/swim · Ctrl sprint · Space×2 fly (Space/Shift up/down) · F5 third person · C climb\nZ magnify (wheel: power) · [ ] time · F6 aurora every night · Esc release mouse" % [
		Engine.get_frames_per_second(), p.x, p.y, p.z, ("   [fly]" if player.flying else "") + ("   [%.1fx]" % player.zoom if player.zoom > 1.0 else ""), place]
	var cam := player.camera.global_position
	underwater.visible = player.world != null and cam.y < player.world.water_at(cam.x, cam.z).x
