# /Users/user/3-line/scripts/config/config_loader.gd
class_name ConfigLoader
extends RefCounted

## Загружает JSON-конфигурации баланса с диска.
## При ошибках автоматически подставляет безопасный fallback профиль.

static func load_cascade_rules(path: String = "res://data/cascade_rules.json") -> Dictionary:
	var data = _read_json(path)
	if data.is_empty() or not ConfigValidator.validate_cascade_rules(data):
		printerr("ConfigLoader: Failed to load cascade rules at ", path, ". Using fallback.")
		return _get_cascade_fallback()
	return data

static func load_shape_rules(path: String = "res://data/shape_rules.json") -> Dictionary:
	var data = _read_json(path)
	if data.is_empty() or not ConfigValidator.validate_shape_rules(data):
		return _get_shape_fallback()
	return data

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		return {}
	return json.data if json.data is Dictionary else {}

static func _get_cascade_fallback() -> Dictionary:
	return {
		"system_id": "controlled-cascade-engine",
		"version": "5.0-fallback",
		"default_settings": {
			"max_cascade_depth_default": 5,
			"max_cascade_depth_fever": 8,
			"assisted_drop_cooldown_turns": 3,
			"assisted_drop_max_per_level": 4,
			"cinematic_drop_max_per_level": 1
		}
	}

static func _get_shape_fallback() -> Dictionary:
	return {
		"system_id": "shape-detector",
		"version": "5.1-fallback",
		"shape_mappings": {
			"line_4": "beam",
			"square_2x2": "homing"
		}
	}
