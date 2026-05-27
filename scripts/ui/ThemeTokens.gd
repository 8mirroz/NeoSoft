extends Node

## Autoload singleton for Neo Soft Frost visual tokens.
## Supports legacy flat colors plus semantic path-based token access.

var tokens: Dictionary = {}
var colors: Dictionary = {}
var motion: Dictionary = {}
var audio: Dictionary = {}
var performance: Dictionary = {}
var _missing_keys_logged: Dictionary = {}

func _ready() -> void:
	load_tokens()

func load_tokens() -> void:
	var path := "res://data/ui/theme_tokens.json"
	if not FileAccess.file_exists(path):
		printerr("ThemeTokens: data file not found at ", path, ". Loading fallbacks.")
		_load_fallbacks()
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_str) != OK:
		printerr("ThemeTokens: JSON parsing error. Loading fallbacks.")
		_load_fallbacks()
		return

	tokens = json.data
	colors = _normalize_color_map(tokens.get("colors", {}))
	motion = tokens.get("motion", {})
	audio = tokens.get("audio", {})
	performance = tokens.get("performance", {})
	_missing_keys_logged.clear()
	print("ThemeTokens loaded successfully.")

func _load_fallbacks() -> void:
	tokens = {
		"colors": {
			"primary": "#CCECFF",
			"secondary": "#D8CCFF",
			"accent": "#FFD4E8",
			"gold": "#FFD700",
			"white": "#F8F6FF",
			"dark_blur": "#1A1829"
		},
		"shared": {
			"colors": {
				"bg_top": "#F4ECFA",
				"bg_bottom": "#EAF1FF",
				"text_primary": "#352F4D",
				"text_secondary": "#575071",
				"text_muted": "#6F6891",
				"text_inverse": "#FFFFFF",
				"accent_primary": "#7A90FF",
				"accent_secondary": "#7ADFC6",
				"accent_warning": "#B56E1B",
				"accent_danger": "#B03B57",
				"accent_gold": "#E8B94A",
				"glass_bg": "#FFFFFF57",
				"glass_border": "#FFFFFFAD",
				"shadow": "#6B5EA326"
			},
			"radius": {"sm": 14, "md": 22, "lg": 30, "xl": 38},
			"spacing": {"xs": 4, "sm": 8, "md": 12, "lg": 18, "xl": 24},
			"font": {"caption": 13, "body": 16, "title": 24, "hero": 44}
		}
	}
	colors = _normalize_color_map(tokens.get("colors", {}))
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
	_missing_keys_logged.clear()

func color(key: String, fallback: Color = Color.WHITE) -> Color:
	if colors.has(key):
		var v = colors.get(key)
		if v is Color:
			return v
	if key.find(".") != -1:
		return color_path(key, fallback)
	return fallback

func color_path(path: String, fallback: Color = Color.WHITE) -> Color:
	var value: Variant = _value_at_path(path)
	if value == null:
		_warn_missing(path)
		return fallback
	if value is Color:
		return value
	if value is String:
		return Color(String(value))
	return fallback

func number(path: String, fallback: float = 0.0) -> float:
	var value: Variant = _value_at_path(path)
	if value == null:
		_warn_missing(path)
		return fallback
	return float(value)

func int_value(path: String, fallback: int = 0) -> int:
	var value: Variant = _value_at_path(path)
	if value == null:
		_warn_missing(path)
		return fallback
	return int(value)

func spacing(path: String, fallback: int = 0) -> int:
	return int_value(path, fallback)

func radius(path: String, fallback: int = 0) -> int:
	return int_value(path, fallback)

func motion_value(key: String, fallback: float = 0.0) -> float:
	return float(motion.get(key, fallback))

func audio_value(key: String, fallback: float = 0.0) -> float:
	return float(audio.get(key, fallback))

func performance_value(key: String, fallback: Variant = null) -> Variant:
	return performance.get(key, fallback)

func make_panel_style(path_prefix: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color_path("%s.bg" % path_prefix, color_path("shared.colors.glass_bg", Color(1, 1, 1, 0.34)))
	style.border_color = color_path("%s.border" % path_prefix, color_path("shared.colors.glass_border", Color(1, 1, 1, 0.66)))
	var border_width := int_value("%s.border_width" % path_prefix, 2)
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width

	var corner_radius := radius("%s.radius" % path_prefix, radius("shared.radius.md", 22))
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius

	style.shadow_color = color_path("%s.shadow.color" % path_prefix, color_path("shared.colors.shadow", Color(0.42, 0.36, 0.64, 0.14)))
	style.shadow_size = int_value("%s.shadow.size" % path_prefix, 14)
	style.shadow_offset = Vector2(number("%s.shadow.offset_x" % path_prefix, 0.0), number("%s.shadow.offset_y" % path_prefix, 4.0))
	style.content_margin_left = int_value("%s.margin.left" % path_prefix, 14)
	style.content_margin_top = int_value("%s.margin.top" % path_prefix, 12)
	style.content_margin_right = int_value("%s.margin.right" % path_prefix, 14)
	style.content_margin_bottom = int_value("%s.margin.bottom" % path_prefix, 12)
	return style

func make_button_style(path_prefix: String, state: String = "normal") -> StyleBoxFlat:
	return make_panel_style("%s.%s" % [path_prefix, state])

func _value_at_path(path: String) -> Variant:
	if path.is_empty():
		return null
	var parts := path.split(".")
	var current: Variant = tokens
	for part in parts:
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			return null
	return current

func _warn_missing(path: String) -> void:
	if _missing_keys_logged.has(path):
		return
	_missing_keys_logged[path] = true
	push_warning("ThemeTokens missing key: %s" % path)

func _normalize_color_map(source: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for key in source.keys():
		var value = source[key]
		if value is Color:
			normalized[key] = value
		elif value is String:
			normalized[key] = Color(String(value))
		else:
			normalized[key] = Color.WHITE
	return normalized
