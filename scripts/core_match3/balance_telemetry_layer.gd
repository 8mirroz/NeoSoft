# /Users/user/3-line/scripts/core_match3/balance_telemetry_layer.gd
extends RefCounted
class_name BalanceTelemetryLayer

## Записывает метрики баланса игрового процесса, считывая шину GameEventBus.
## Передает логи сессий в MCTS симулятор и сохраняет в JSON.

var enabled: bool = true

var total_combos: int = 0
var sum_combo_lengths: int = 0
var max_combo_length: int = 0
var fever_activations: int = 0
var special_spheres_created: int = 0
var special_combos_used: int = 0
var session_ended: bool = false
var session_won: bool = false
var session_moves_left: int = 0

func _init(p_enabled: bool = true) -> void:
	enabled = p_enabled
	if enabled:
		# Подписываемся на события EventBus
		GameEventBus.match_detected.connect(_on_match_detected)
		GameEventBus.special_spawned.connect(_on_special_spawned)
		GameEventBus.special_activated.connect(_on_special_activated)
		GameEventBus.fever_started.connect(_on_fever_started)
		GameEventBus.level_result_resolved.connect(_on_level_finished)

func reset() -> void:
	total_combos = 0
	sum_combo_lengths = 0
	max_combo_length = 0
	fever_activations = 0
	special_spheres_created = 0
	special_combos_used = 0
	session_ended = false
	session_won = false
	session_moves_left = 0

func _on_match_detected(event: MatchEvent) -> void:
	total_combos += 1
	var length = event.coordinates.size()
	sum_combo_lengths += length
	max_combo_length = max(max_combo_length, length)

func _on_special_spawned(position: Vector2i, type: int) -> void:
	special_spheres_created += 1

func _on_special_activated(event: SpecialActivationEvent) -> void:
	if event.is_combo_trigger:
		special_combos_used += 1

func _on_fever_started(duration: float, multiplier: float) -> void:
	fever_activations += 1

func _on_level_finished(won: bool, final_score: int, stars: int) -> void:
	session_ended = true
	session_won = won

func get_metrics() -> Dictionary:
	var avg_combo: float = 0.0
	if total_combos > 0:
		avg_combo = float(sum_combo_lengths) / float(total_combos)
		
	return {
		"average_combo_length": avg_combo,
		"max_combo_length": max_combo_length,
		"fever_activation_rate": fever_activations,
		"special_sphere_creation_rate": special_spheres_created,
		"special_combo_usage_rate": special_combos_used,
		"level_win_rate": 1.0 if (session_ended and session_won) else 0.0
	}

func export_json() -> String:
	return JSON.stringify(get_metrics(), "\t")

func save_report(path: String) -> Error:
	var dir = DirAccess.open("user://")
	dir.make_dir_recursive(path.get_base_dir())
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(export_json())
	file.close()
	return OK
