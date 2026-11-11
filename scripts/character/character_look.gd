class_name CharacterLook
extends RefCounted
## How a figure looks: the player's (chosen in the character picker when a
## game is made: CharacterPicker; kept with the game) and, later, anyone
## else's (random(): an NPC's, the same every time from the same seed).
## Avatar builds the figure from it (CharacterParts).
##
## A look is its values by field (FIELDS: a colour, or one of a field's
## options). To add something to choose (a field, an option, a palette,
## a colour): add it here, and build it in CharacterParts; the picker lays
## itself out from FIELDS, and random() and the saved games go by them too.

## The colours to pick from, by palette.
const PALETTES := {
	"skin": ["#fbe3d0", "#f3cfb3", "#e8b894", "#dba57c", "#cd9366", "#bd8255", "#a86f47", "#93603c", "#7b4e31", "#633d27", "#4c2e1e", "#382116"],
	"hair": ["#0e0b0a", "#1f1611", "#35241a", "#4f3523", "#6b4a2e", "#8a6239", "#a8562a", "#c4722f", "#d8ae6a", "#ead9a8", "#9a9794", "#e6e3df"],
	"eyes": ["#3b2414", "#5a3a1e", "#7a5a2c", "#6f7f3a", "#4d7a5a", "#4f7f9a", "#3f5f8f", "#6f7780"],
	"dyes": ["#f1ead9", "#d8c9a6", "#b99a6b", "#8a623a", "#5d4027", "#2e2620", "#a13a26", "#c8662d", "#d9a23a", "#7a8a3c", "#3f6b4a", "#2f6f7a", "#2c4f8a", "#4a3a7a", "#7a3a5f", "#8f8f8a"],
	"colors": ["#ffffff", "#bfbfbf", "#808080", "#1a1a1a", "#e53935", "#fb8c00", "#fdd835", "#7cb342", "#00897b", "#00acc1", "#1e88e5", "#3949ab", "#8e24aa", "#d81b60", "#6d4c41", "#f48fb1"],
}

## What's chosen, in the picker's order: key, the picker's label and
## section; type "color" (palettes: the first its own, any after it other
## palettes to pick from too) or "choice" (options: the first what a
## plain figure has).
const FIELDS := [
	{"key": "skin", "label": "Skin", "section": "Body", "type": "color", "palettes": ["skin", "colors"], "default": "#cd9366"},
	{"key": "build", "label": "Build", "section": "Body", "type": "choice", "options": ["average", "slender", "stocky"]},
	{"key": "eyes", "label": "Eyes", "section": "Body", "type": "color", "palettes": ["eyes", "colors"], "default": "#5a3a1e"},
	{"key": "hair_style", "label": "Hairstyle", "section": "Hair", "type": "choice",
		"options": ["short", "bald", "buzz", "medium", "long", "ponytail", "braids", "bun", "mohawk"]},
	{"key": "curl", "label": "Curl", "section": "Hair", "type": "choice", "options": ["straight", "wavy", "curly", "coily"]},
	{"key": "hair", "label": "Hair colour", "section": "Hair", "type": "color", "palettes": ["hair", "colors"], "default": "#1f1611"},
	{"key": "facial_hair", "label": "Facial hair", "section": "Hair", "type": "choice",
		"options": ["none", "stubble", "moustache", "goatee", "beard", "long_beard", "sideburns"]},
	{"key": "shirt", "label": "Shirt", "section": "Clothes", "type": "choice", "options": ["long_sleeves", "none", "tee", "vest", "tunic"]},
	{"key": "shirt_color", "label": "Shirt colour", "section": "Clothes", "type": "color", "palettes": ["dyes", "colors"], "default": "#a13a26"},
	{"key": "pattern", "label": "Shirt pattern", "section": "Clothes", "type": "choice",
		"options": ["plain", "chief_bands", "stepped_diamonds", "eye_dazzler", "morning_star", "arrow_chevrons", "mountain_triangles",
			"basket_steps", "ribbon_bands", "four_directions", "lightning"]},
	{"key": "pattern_color", "label": "Pattern colour", "section": "Clothes", "type": "color", "palettes": ["dyes", "colors"], "default": "#f1ead9"},
	{"key": "pattern_color2", "label": "Pattern's second colour", "section": "Clothes", "type": "color", "palettes": ["dyes", "colors"], "default": "#2e2620"},
	{"key": "pants", "label": "Pants", "section": "Clothes", "type": "choice", "options": ["trousers", "shorts", "fringed_leggings"]},
	{"key": "pants_color", "label": "Pants colour", "section": "Clothes", "type": "color", "palettes": ["dyes", "colors"], "default": "#2c4f8a"},
	{"key": "glasses", "label": "Glasses", "section": "Accessories", "type": "choice", "options": ["none", "round", "square", "sunglasses"]},
	{"key": "hat", "label": "Hat", "section": "Accessories", "type": "choice", "options": ["none", "wide_brim", "straw", "knit_cap", "headband", "cap"]},
	{"key": "hat_color", "label": "Hat colour", "section": "Accessories", "type": "color", "palettes": ["dyes", "colors"], "default": "#5d4027"},
]

## The options' names in the picker, where not their own (underscores to
## spaces).
const NAMES := {
	"long_sleeves": "Long sleeves", "tee": "Short sleeves", "none": "None", "long_beard": "Long beard",
	"chief_bands": "Chief bands", "eye_dazzler": "Eye dazzler", "wide_brim": "Wide brim", "knit_cap": "Knit cap",
	"fringed_leggings": "Fringed leggings",
}

## The shirt's patterns as the cloth's shader numbers them
## (character_cloth.gdshader).
const PATTERN_IDS := {"plain": 0, "chief_bands": 1, "stepped_diamonds": 2, "eye_dazzler": 3, "morning_star": 4, "arrow_chevrons": 5,
	"mountain_triangles": 6, "basket_steps": 7, "ribbon_bands": 8, "four_directions": 9, "lightning": 10}

var values := {} ## field key -> its value: a Color, or an option (a String)


func _init() -> void:
	for f: Dictionary in FIELDS:
		values[f.key] = default_of(f)


static func default_of(f: Dictionary) -> Variant:
	return Color.html(f.default) if f.type == "color" else f.options[0]


static func field(key: String) -> Dictionary:
	for f: Dictionary in FIELDS:
		if f.key == key:
			return f
	return {}


## An option's name, as the picker shows it.
static func name_of(option: String) -> String:
	return NAMES.get(option, option.replace("_", " ").capitalize())


## A field's colour (a "color" field).
func color(key: String) -> Color:
	var v: Variant = values.get(key)
	return v if v is Color else Color.WHITE


## A field's option (a "choice" field).
func option(key: String) -> String:
	return str(values.get(key, ""))


func put(key: String, value: Variant) -> void:
	values[key] = value


func copy() -> CharacterLook:
	var l := CharacterLook.new()
	l.values = values.duplicate()
	return l


## As a saved game keeps it (colours as "#rrggbb").
func to_dict() -> Dictionary:
	var d := {}
	for key: String in values:
		d[key] = "#" + (values[key] as Color).to_html(false) if values[key] is Color else values[key]
	return d


## A look from what a saved game kept (anything missing or no longer an
## option: as a plain figure has it).
static func from_dict(d: Dictionary) -> CharacterLook:
	var l := CharacterLook.new()
	for f: Dictionary in FIELDS:
		if not d.has(f.key):
			continue
		var v := str(d[f.key])
		if f.type == "color":
			if Color.html_is_valid(v):
				l.values[f.key] = Color.html(v)
		elif v in f.options:
			l.values[f.key] = v
	return l


## Somebody: every field picked by chance (an NPC's look; the same from the
## same seed), its colours from each field's own palette (skin from the
## skin tones, hair from the hair's), most with no hat, glasses or pattern.
## set_: fields given outright ({key: value}).
static func random(rng: RandomNumberGenerator, set_ := {}) -> CharacterLook:
	var l := CharacterLook.new()
	for f: Dictionary in FIELDS:
		if f.type == "color":
			var pal: Array = PALETTES[f.palettes[0]]
			l.values[f.key] = Color.html(pal[rng.randi() % pal.size()])
		else:
			var opts: Array = f.options
			var plain: bool = f.key in ["glasses", "hat", "facial_hair", "pattern"] and rng.randf() < 0.6
			l.values[f.key] = opts[0] if plain else opts[rng.randi() % opts.size()]
	if l.option("hair_style") == "bald" and rng.randf() < 0.7:
		l.values["hair_style"] = "short"
	if l.option("shirt") == "none" and rng.randf() < 0.8:
		l.values["shirt"] = "long_sleeves"
	for key: String in set_:
		l.values[key] = set_[key]
	return l
