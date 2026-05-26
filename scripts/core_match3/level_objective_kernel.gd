# /Users/user/3-line/scripts/core_match3/level_objective_kernel.gd
class_name LevelObjectiveKernel
extends RefCounted

## Изолированное от UI ядро отслеживания прогресса целей уровня.
## Слушает GameEventBus и отправляет сигналы завершения уровня.

var level_id: String = ""
var moves_remaining: int = 25
var score_current: int = 0
var stars_earned: int = 0

var objectives: Array = []
var score_targets: Dictionary = {}

func initialize(path: String = "res://data/level_objectives.json") -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("LevelObjectiveKernel: Config file not found at ", path)
		return
		
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		printerr("LevelObjectiveKernel: JSON parsing error.")
		return
		
	var data = json.data
	level_id = data.get("level_id", "default_level")
	moves_remaining = data.get("moves_limit", 25)
	score_targets = data.get("score_targets", {"1_star": 1000})
	
	objectives = data.get("objectives", [])
	score_current = 0
	stars_earned = 0
	
	# Подписываемся на события шины
	GameEventBus.match_detected.connect(_on_match_detected)
	GameEventBus.special_activated.connect(_on_special_activated)

func get_objective_progress() -> Array:
	return objectives

func decrease_moves() -> void:
	if moves_remaining > 0:
		moves_remaining -= 1
		GameEventBus.emit_signal("moves_updated", moves_remaining)
		_check_level_status()

func add_score(amount: int) -> void:
	score_current += amount
	_update_stars()
	GameEventBus.emit_signal("score_updated", score_current, stars_earned)
	_check_level_status()

func _update_stars() -> void:
	if score_current >= score_targets.get("3_stars", 5000):
		stars_earned = 3
	elif score_current >= score_targets.get("2_stars", 2500):
		stars_earned = 2
	elif score_current >= score_targets.get("1_star", 1000):
		stars_earned = 1
	else:
		stars_earned = 0

func _on_match_detected(event: MatchEvent) -> void:
	# Вычитаем прогресс по цвету гемов
	for obj in objectives:
		if obj.get("type") == "collect_color" and obj.get("target_color") == event.color:
			var count = event.coordinates.size()
			obj["current_count"] = min(obj["current_count"] + count, obj["target_count"])
			
	add_score(event.score)

func _on_special_activated(event: SpecialActivationEvent) -> void:
	# Если спец-сфера задела ледяной блок
	for obj in objectives:
		if obj.get("type") == "clear_blocker" and obj.get("target_blocker") == "ice":
			# Проверим, были ли задеты координаты
			var count = 0
			for cell in event.affected_cells:
				# Симуляция нахождения блока льда
				count += 1
			obj["current_count"] = min(obj["current_count"] + count, obj["target_count"])

func _check_level_status() -> void:
	var won = true
	for obj in objectives:
		if obj["current_count"] < obj["target_count"]:
			won = false
			break
			
	if won:
		GameEventBus.emit_signal("level_result_resolved", true, score_current, stars_earned)
		_disconnect_events()
	elif moves_remaining <= 0:
		GameEventBus.emit_signal("level_result_resolved", false, score_current, stars_earned)
		_disconnect_events()

func _disconnect_events() -> void:
	if GameEventBus.match_detected.is_connected(_on_match_detected):
		GameEventBus.match_detected.disconnect(_on_match_detected)
	if GameEventBus.special_activated.is_connected(_on_special_activated):
		GameEventBus.special_activated.disconnect(_on_special_activated)
