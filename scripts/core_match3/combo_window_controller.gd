# /Users/user/3-line/scripts/core_match3/combo_window_controller.gd
class_name ComboWindowController
extends RefCounted

## Управляет геймплейным окном обратного отсчета для быстрых последовательных ходов игрока.

signal combo_window_tick(remaining_sec: float, pct: float)
signal combo_window_expired()

var combo_duration_sec: float = 1.5
var current_timer_sec: float = 0.0
var is_window_open: bool = false
var current_chain_count: int = 0

func _get_game_event_bus() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("GameEventBus")
	return null

func _emit_game_event(signal_name: String, arg1: Variant = null, arg2: Variant = null) -> void:
	var bus := _get_game_event_bus()
	if bus == null or not bus.has_signal(signal_name):
		return
	if arg1 == null and arg2 == null:
		bus.emit_signal(signal_name)
	elif arg2 == null:
		bus.emit_signal(signal_name, arg1)
	else:
		bus.emit_signal(signal_name, arg1, arg2)

func _init(duration: float = 1.5) -> void:
	combo_duration_sec = duration
	# Подписываемся на успешный свайп
	var bus := _get_game_event_bus()
	if bus != null and bus.has_signal("swap_resolved"):
		bus.connect("swap_resolved", _on_swap_resolved)

func update(delta: float) -> void:
	if not is_window_open:
		return
		
	current_timer_sec -= delta
	if current_timer_sec <= 0.0:
		current_timer_sec = 0.0
			is_window_open = false
			current_chain_count = 0
			emit_signal("combo_window_expired")
			_emit_game_event("fever_ended") # Информируем шину об истечении комбо
	else:
		var pct = current_timer_sec / combo_duration_sec
		emit_signal("combo_window_tick", current_timer_sec, pct)

func open_window() -> void:
	current_timer_sec = combo_duration_sec
	is_window_open = true
	current_chain_count += 1
	_emit_game_event("fever_meter_changed", current_timer_sec / combo_duration_sec * 100.0)

func close_window() -> void:
	current_timer_sec = 0.0
	is_window_open = false
	current_chain_count = 0
	emit_signal("combo_window_expired")

func _on_swap_resolved(from_cell: Vector2i, to_cell: Vector2i) -> void:
	# Каждый успешный свайп обновляет и перезапускает окно комбо
	open_window()
