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

func _get_game_event_bus() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("GameEventBus")
	return null

func _connect_bus_signal(signal_name: String, callable: Callable) -> void:
	var bus := _get_game_event_bus()
	if bus == null or not bus.has_signal(signal_name):
		return
	if not bus.is_connected(signal_name, callable):
		bus.connect(signal_name, callable)

func _init(p_enabled: bool = true) -> void:
	enabled = p_enabled
	if enabled:
		# Подписываемся на события EventBus
		_connect_bus_signal("match_detected", _on_match_detected)
		_connect_bus_signal("special_spawned", _on_special_spawned)
		_connect_bus_signal("special_activated", _on_special_activated)
		_connect_bus_signal("fever_started", _on_fever_started)
		_connect_bus_signal("level_result_resolved", _on_level_finished)

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
	var length = event.cells.size()
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

func record_queued_move(_success: bool, _expired: bool) -> void:
	# Заглушка для записи отложенных ходов
	pass

func record_combo(combo_count: int) -> void:
	total_combos += 1
	sum_combo_lengths += combo_count
	max_combo_length = max(max_combo_length, combo_count)

func record_fever_activated() -> void:
	fever_activations += 1

func record_special_created() -> void:
	special_spheres_created += 1

func record_session_end(won: bool, moves_left: int) -> void:
	session_ended = true
	session_won = won
	session_moves_left = moves_left

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
