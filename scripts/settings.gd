class_name Settings
## The player's settings, the same for every game: kept in
## user://settings.cfg, loaded at the start (menu.gd), changed in the
## settings screen (SettingsPanel: from the start menu and from Esc in the
## game). The window's and the renderer's own (window mode, V-sync, the
## frame rate cap, the render scale) apply at once (apply()); the game's
## (the field of view, the shadows) by main.gd's apply_settings(); the
## mouse's read by the player as it looks. The trees' and the grass's
## distances when a world is loaded (Population, GroundCover). The keys
## (KEYS: each game action and its key, rebindable: KeybindingsPanel) set
## in the InputMap.

const PATH := "user://settings.cfg"
const WINDOW_MODES := ["Windowed", "Fullscreen", "Borderless fullscreen"]
const FPS_CAPS := [0, 30, 60, 90, 120, 144, 240] ## (0: none)
const SHADOWS := ["Off", "Low", "High"]
const SHADOW_DIST := [0.0, 100.0, 200.0] ## m the sun's reach, by SHADOWS
const SHADOW_ATLAS := [1024, 2048, 4096] ## px
const TREES_VIEW := 600.0 ## m: the standard reach of the trees' far cards (OakTree.VIEW)
## The game's actions, in the keybindings screen's order: [action, its name,
## its key by default (physical)].
const KEYS := [
	["move_forward", "Forward", KEY_W], ["move_back", "Back", KEY_S],
	["move_left", "Left", KEY_A], ["move_right", "Right", KEY_D],
	["jump", "Jump / swim up / fly up (twice: fly)", KEY_SPACE], ["descend", "Crouch / dive / fly down", KEY_SHIFT],
	["sprint", "Sprint", KEY_CTRL], ["climb", "Climb", KEY_C],
	["knapsack", "Knapsack", KEY_E], ["pack", "Take off / put on the knapsack", KEY_Q], ["magnify", "Magnify", KEY_Z],
	["third_person", "Third person", KEY_F5], ["chat", "Chat", KEY_ENTER],
	["command", "Command", KEY_SLASH], ["time_backward", "Time back (god)", KEY_BRACKETLEFT],
	["time_forward", "Time on (god)", KEY_BRACKETRIGHT], ["toggle_shadows", "Shadows on/off", KEY_L],
]

static var mouse_sens := 1.0 ## times the standard
static var invert_y := false
static var fov := 75.0 ## degrees, vertical
static var window_mode := 0 ## WINDOW_MODES
static var vsync := true
static var fps_cap := 0 ## frames a second (0: none)
static var render_scale := 1.0 ## the 3D view's resolution, of the window's
static var shadows := 2 ## SHADOWS
static var show_fps := false
static var tree_distance := TREES_VIEW ## m: the far trees' cards out to this
static var grass_distance := 1.0 ## the grass and flowers' reach, times the standard
static var volume := 80.0 ## %, everything
static var keys := {} ## action -> physical keycode (those changed from KEYS')

static var _loaded := false


static func load_settings() -> void:
	_loaded = true
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	mouse_sens = clampf(float(c.get_value("controls", "mouse_sens", mouse_sens)), 0.1, 4.0)
	invert_y = bool(c.get_value("controls", "invert_y", invert_y))
	fov = clampf(float(c.get_value("view", "fov", fov)), 50.0, 110.0)
	window_mode = clampi(int(c.get_value("display", "window_mode", window_mode)), 0, WINDOW_MODES.size() - 1)
	vsync = bool(c.get_value("display", "vsync", vsync))
	fps_cap = int(c.get_value("display", "fps_cap", fps_cap))
	render_scale = clampf(float(c.get_value("display", "render_scale", render_scale)), 0.5, 1.0)
	shadows = clampi(int(c.get_value("graphics", "shadows", shadows)), 0, SHADOWS.size() - 1)
	show_fps = bool(c.get_value("view", "show_fps", show_fps))
	tree_distance = clampf(float(c.get_value("graphics", "tree_distance", tree_distance)), 300.0, 1500.0)
	grass_distance = clampf(float(c.get_value("graphics", "grass_distance", grass_distance)), 0.5, 2.0)
	volume = clampf(float(c.get_value("audio", "volume", volume)), 0.0, 100.0)
	keys = {}
	if c.has_section("keys"):
		for a in c.get_section_keys("keys"):
			keys[a] = int(c.get_value("keys", a))


static func save_settings() -> void:
	var c := ConfigFile.new()
	c.set_value("controls", "mouse_sens", mouse_sens)
	c.set_value("controls", "invert_y", invert_y)
	c.set_value("view", "fov", fov)
	c.set_value("view", "show_fps", show_fps)
	c.set_value("display", "window_mode", window_mode)
	c.set_value("display", "vsync", vsync)
	c.set_value("display", "fps_cap", fps_cap)
	c.set_value("display", "render_scale", render_scale)
	c.set_value("graphics", "shadows", shadows)
	c.set_value("graphics", "tree_distance", tree_distance)
	c.set_value("graphics", "grass_distance", grass_distance)
	c.set_value("audio", "volume", volume)
	if c.has_section("keys"):
		c.erase_section("keys")
	for a in keys:
		c.set_value("keys", a, keys[a])
	c.save(PATH)


static func ensure_loaded() -> void:
	if not _loaded:
		load_settings()


## The window's and renderer's own, now (vp: the root viewport).
static func apply(vp: Viewport) -> void:
	ensure_loaded()
	if not DisplayServer.get_name() == "headless":
		var want: int = [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_FULLSCREEN][window_mode]
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = fps_cap
	if vp != null:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR if render_scale >= 0.999 else Viewport.SCALING_3D_MODE_FSR
		vp.scaling_3d_scale = render_scale
	RenderingServer.directional_shadow_atlas_set_size(SHADOW_ATLAS[shadows], true)
	AudioServer.set_bus_mute(0, volume <= 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume / 100.0, 0.0001)))
	apply_keys()


## An action's key now (physical keycode).
static func key_of(action: String) -> int:
	for k: Array in KEYS:
		if k[0] == action:
			return int(keys.get(action, k[2]))
	return 0


## The InputMap as the keys are: each action made if it isn't yet, its key
## the chosen one.
static func apply_keys() -> void:
	for k: Array in KEYS:
		var a: String = k[0]
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.5)
		InputMap.action_erase_events(a)
		var e := InputEventKey.new()
		e.physical_keycode = key_of(a) as Key
		InputMap.action_add_event(a, e)
		if a == "chat" and key_of(a) == KEY_ENTER: # (the keypad's Enter too)
			var e2 := InputEventKey.new()
			e2.physical_keycode = KEY_KP_ENTER
			InputMap.action_add_event(a, e2)


## A key's name, as shown.
static func key_name(code: int) -> String:
	return OS.get_keycode_string(code) if code != 0 else "(none)"
