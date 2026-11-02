class_name Session
## What the game was started as, and the saved games. The start menu
## (menu.gd) sets it before loading main.tscn; main.gd reads it. Run
## main.tscn on its own (the editor's "run current scene", the test tools)
## and it's debug mode, as before there was a menu.
##
## A game has a mode (MODES: survival, not defined yet; god: flying and the
## time keys) and allows commands or not (chosen when it's made; without,
## only /help, /pos and /clear; with, /mode switches the mode). It saves
## itself (where you are and look, the time and day, what has been taken
## from the world, its mode) every minute, on leaving it and on quitting.
## Debug mode: god mode, every command, the frame rate and coordinates on
## screen, F6; nothing is saved.
## Saves are JSON files in user://saves/.

const DIR := "user://saves/"
const VERSION := 1

const MODES := ["survival", "god"] ## A game's mode (main.gd set_mode(); /mode switches).

static var debug := true
static var game_name := "" ## The game being played ("" in debug mode).
static var data := {} ## Its saved state, as loaded; a new game's only {mode, commands}.


## The saved games, the one played last first: [{name, file, saved (unix
## seconds), play_seconds}].
static func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string(DIR + f))
		if d is Dictionary:
			out.append({"name": d.get("name", f.get_basename()), "file": DIR + f,
					"saved": float(d.get("saved", 0.0)), "play_seconds": float(d.get("play_seconds", 0.0)),
					"mode": d.get("mode", "survival"), "commands": bool(d.get("commands", false))})
	out.sort_custom(func(a, b): return a.saved > b.saved)
	return out


## Starts the game called name (its save loaded if there is one).
static func play(name: String) -> void:
	debug = false
	game_name = name
	data = {}
	var f := file_for(name)
	if FileAccess.file_exists(f):
		var d = JSON.parse_string(FileAccess.get_file_as_string(f))
		if d is Dictionary:
			data = d


## Starts a new game called name: its mode (MODES) and whether commands
## are allowed in it.
static func play_new(name: String, mode: String, commands: bool) -> void:
	debug = false
	game_name = name
	data = {"mode": mode, "commands": commands}


static func play_debug() -> void:
	debug = true
	game_name = ""
	data = {}


static func save(d: Dictionary) -> void:
	if debug or game_name == "":
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	d.version = VERSION
	d.name = game_name
	d.saved = Time.get_unix_time_from_system()
	var f := FileAccess.open(file_for(game_name), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "\t"))
	data = d


static func delete(name: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file_for(name)))


static func rename(name: String, to: String) -> bool:
	if to == "" or exists(to):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(file_for(name)))
	if not d is Dictionary:
		return false
	d.name = to
	var f := FileAccess.open(file_for(to), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "\t"))
	f.close()
	delete(name)
	return true


static func exists(name: String) -> bool:
	return FileAccess.file_exists(file_for(name))


## A name not taken yet: "Game 1", "Game 2", ...
static func free_name() -> String:
	var n := 1
	while exists("Game %d" % n):
		n += 1
	return "Game %d" % n


static func file_for(name: String) -> String:
	return DIR + name.strip_edges().validate_filename() + ".json"
