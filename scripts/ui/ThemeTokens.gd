# /Users/user/3-line/scripts/ui/ThemeTokens.gd
extends Node

## Синглтон автозагрузки токенов оформления Neo Soft Frost темы.
## Загружает и предоставляет доступ к цветам, motion-параметрам и профилям качества.

var colors: Dictionary = {}
var motion: Dictionary = {}
var audio: Dictionary = {}
var performance: Dictionary = {}

func _ready() -> void:
	load_tokens()

func load_tokens() -> void:
	var path = "res://data/ui/theme_tokens.json"
	if not FileAccess.file_exists(path):
		printerr("ThemeTokens: data file not found at ", path, ". Loading fallbacks.")
		_load_fallbacks()
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_err = json.parse(json_str)
	if parse_err != OK:
		printerr("ThemeTokens: JSON parsing error. Loading fallbacks.")
		_load_fallbacks()
		return
		
	var data = json.data
	colors = data.get("colors", {})
	motion = data.get("motion", {})
	audio = data.get("audio", {})
	performance = data.get("performance", {})
	
	print("ThemeTokens loaded successfully.")

func _load_fallbacks() -> void:
	colors = {
		"primary": "#CCECFF",
		"secondary": "#D8CCFF",
		"accent": "#FFD4E8",
		"gold": "#FFD700",
		"white": "#F8F6FF",
		"dark_blur": "#1A1829"
	}
	motion = {
		"fade_duration": 0.25,
		"scale_duration": 0.35,
		"modal_bounce_duration": 0.45,
		"combo_tier_1": 0.2,
		"combo_tier_2": 0.3,
		"combo_tier_3": 0.4
	}
	audio = {
		"ping_volume": -6.0,
		"chime_volume": -4.0,
		"music_fever_volume": 0.0
	}
	performance = {
		"shader_quality": "SAFE"
	}
