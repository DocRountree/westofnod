@tool
class_name WorldConfig
extends Resource
## Facts about a world that many systems share: its seed (procedural
## generation), where it sits on the planet (latitude) and the one calendar
## day that repeats forever. A level assigns one; systems read it through
## WorldConfig.current(), which falls back to the defaults in the editor.

@export var world_seed := 1              ## Master seed; systems derive their own from it.
@export_range(-89.0, 89.0) var latitude := 0.0   ## Degrees north.
## Julian date of the repeating day's midnight (default: 2026 winter solstice).
@export var day_jd := 2461395.5
@export var planet_radius_m := 6400000.0 ## For horizon distance, sky and atmosphere maths.
## How fast Mars, Jupiter, Saturn and Uranus cross the stars: 0 = real (weeks
## to see a change), 1 = about as fast as the moon (13 degrees a day).
@export_range(0.0, 1.0) var outer_planet_pace := 1.0
## Game days from new moon to new moon (real: 29.53). 8 gives each of the
## eight named phases one day.
@export_range(1.0, 60.0) var lunar_cycle_days := 8.0

## Where the player is on the planet (degrees; main.gd moves these as they
## travel over the spherically wrapped map). Astronomy reads the latitude; the
## longitude shifts the clock (it keeps local time).
var longitude := 0.0

static var _default: WorldConfig
static var active: WorldConfig     ## The running world's config (set by main.gd).
static var clock: GameClock        ## The running world's clock.


## The running world's config, or defaults (editor previews, standalone tests).
static func current() -> WorldConfig:
	if active:
		return active
	if _default == null:
		_default = WorldConfig.new()
	return _default


## A per-system seed, so systems stay independent but reproducible.
func seed_for(system: String) -> int:
	return hash(str(world_seed) + ":" + system)
