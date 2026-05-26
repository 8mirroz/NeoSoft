## LevelLoader — загрузка конфигурации уровня из JSON
## Изолирован в data_layer, без зависимости от gameplay кода
extends RefCounted
class_name LevelLoader

## Загрузить уровень из JSON-файла
## Returns Dictionary с конфигом или пустой при ошибке
static func load_level(level_number: int) -> Dictionary:
	var path := "res://data/levels/level_%03d.json" % level_number
	return load_from_path(path)

static func level_exists(level_number: int) -> bool:
	var path := "res://data/levels/level_%03d.json" % level_number
	return FileAccess.file_exists(path)

## Загрузить из произвольного пути
static func load_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("LevelLoader: file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LevelLoader: cannot open: %s" % path)
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("LevelLoader: JSON parse error in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	var data: Dictionary = json.data
	if not _validate(data, path):
		return {}

	return data

## Валидация обязательных полей конфига уровня
static func _validate(data: Dictionary, path: String) -> bool:
	var required_keys := ["level_id", "board", "goals", "moves", "target_score", "tutorial"]
	for key in required_keys:
		if not data.has(key):
			push_error("LevelLoader: missing required key '%s' in %s" % [key, path])
			return false

	var board: Dictionary = data["board"]
	var board_keys := ["width", "height", "gem_kinds", "blocked_cells", "initial_blockers"]
	for key in board_keys:
		if not board.has(key):
			push_error("LevelLoader: board missing key '%s' in %s" % [key, path])
			return false

	if not board.has("width") or not board.has("height"):
		push_error("LevelLoader: board must have 'width' and 'height' in %s" % path)
		return false

	if not data["goals"] is Array:
		push_error("LevelLoader: 'goals' must be an array in %s" % path)
		return false

	if not data["tutorial"] is Dictionary:
		push_error("LevelLoader: 'tutorial' must be a dictionary in %s" % path)
		return false

	if data.has("blockers") and not data["blockers"] is Array:
		push_error("LevelLoader: 'blockers' must be an array in %s" % path)
		return false

	if data.has("modifiers") and not data["modifiers"] is Dictionary:
		push_error("LevelLoader: 'modifiers' must be a dictionary in %s" % path)
		return false

	return true

## Получить баланс-конфиг (scoring, timings)
static func load_balance() -> Dictionary:
	var path := "res://data/balance/scoring.json"
	if not FileAccess.file_exists(path):
		return _default_balance()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _default_balance()

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		return _default_balance()

	return json.data

static func _default_balance() -> Dictionary:
	return {
		"base_match_score": GameConstants.BASE_MATCH_SCORE,
		"extra_gem_bonus": GameConstants.EXTRA_GEM_BONUS,
		"special_gem_bonus": GameConstants.SPECIAL_GEM_BONUS,
		"remaining_move_bonus": GameConstants.REMAINING_MOVE_BONUS,
		"star_thresholds": [
			GameConstants.STAR_1_THRESHOLD,
			GameConstants.STAR_2_THRESHOLD,
			GameConstants.STAR_3_THRESHOLD,
		],
	}

static func load_soft_launch_config() -> Dictionary:
	return _load_json_file("res://config/soft_launch_config.json", _default_soft_launch_config())

static func get_available_level_ids() -> Array[int]:
	var result: Array[int] = []
	var dir := DirAccess.open("res://data/levels")
	if dir == null:
		return result

	dir.list_dir_begin()
	var file_name := dir.get_next()
	var file_name_regex := RegEx.new()
	file_name_regex.compile("^level_(\\d{3})\\.json$")
	while file_name != "":
		if not dir.current_is_dir():
			var file_match := file_name_regex.search(file_name)
			if file_match != null:
				result.append(int(file_match.get_string(1)))
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result

static func get_available_level_count() -> int:
	return get_available_level_ids().size()

static func _load_json_file(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return fallback.duplicate(true)

	return (json.data as Dictionary).duplicate(true)

static func _default_soft_launch_config() -> Dictionary:
	return {
		"version": 1,
		"default_quality_profile": "web_default",
		"analytics": {
			"enabled": true,
			"log_path": "user://analytics_events.jsonl",
		},
		"retention": {
			"enabled": true,
			"streak_bonus_goal": 3,
			"loss_nudge_threshold": 2,
		},
		"quality_profiles": {
			"web_default": {
				"gem_glow_multiplier": 1.0,
				"background_effect_alpha": 1.0,
			},
			"android_safe": {
				"gem_glow_multiplier": 0.72,
				"background_effect_alpha": 0.78,
			},
		},
		"visual_validation": {
			"target_fps_web": 60,
			"target_fps_android": 45,
			"readability_sizes": [64, 96],
		},
	}
