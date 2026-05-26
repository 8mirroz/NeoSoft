# /Users/user/3-line/scripts/core_match3/combo_fever_controller.gd
extends RefCounted
class_name ComboFeverController

## Контроллер Fever Mode и накопления Fever Meter.
## Переводит события Fever в шину GameEventBus.

signal combo_window_opened
signal combo_expired
signal fever_activated

var config_path: String = "res://data/ui/theme_tokens.json"

var base_duration_normal: float = 1.5
var fever_combo_threshold: int = 5
var fever_duration: float = 6.0
var score_multiplier_fever: float = 2.5
var min_power: float = 100.0
var max_power: float = 1500.0

var simple_match_refresh: float = 0.50
var shape_match_refresh: float = 0.70
var special_sphere_refresh: float = 0.90
var invalid_move_penalty: float = 0.30

var chain_index: int = 0
var combo_window_remaining: float = 0.0
var combo_window_max: float = 1.5
var fever_meter: float = 0.0
var fever_remaining: float = 0.0
var is_fever_active: bool = false

func _emit_game_event(signal_name: String, arg1: Variant = null, arg2: Variant = null) -> void:
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return
	var bus := (loop as SceneTree).root.get_node_or_null("GameEventBus")
	if bus == null or not bus.has_signal(signal_name):
		return
	if arg1 == null and arg2 == null:
		bus.emit_signal(signal_name)
	elif arg2 == null:
		bus.emit_signal(signal_name, arg1)
	else:
		bus.emit_signal(signal_name, arg1, arg2)

func _init() -> void:
	combo_window_max = base_duration_normal

func update(delta: float) -> void:
	if combo_window_remaining > 0.0:
		combo_window_remaining -= delta
		if combo_window_remaining <= 0.0:
			combo_window_remaining = 0.0
			chain_index = 0
			emit_signal("combo_expired")
			_emit_game_event("fever_ended") # Упрощенное уведомление шины
			
	if is_fever_active and fever_remaining > 0.0:
		fever_remaining -= delta
		if fever_remaining <= 0.0:
			fever_remaining = 0.0
			is_fever_active = false
			_emit_game_event("fever_ended")

func on_match_detected(shape_type: String, base_score: float = 100.0, is_cascade: bool = false, is_special: bool = false) -> float:
	chain_index += 1
	
	var refresh_val := simple_match_refresh
	if is_special:
		refresh_val = special_sphere_refresh
	elif shape_type != "LINE_3":
		refresh_val = shape_match_refresh
		
	var is_opening := (combo_window_remaining <= 0.0)
	combo_window_remaining = min(combo_window_remaining + refresh_val, combo_window_max)
	
	if is_opening:
		emit_signal("combo_window_opened")
		
	fever_meter = clamp(fever_meter + (100.0 / float(fever_combo_threshold)), 0.0, 100.0)
	_emit_game_event("fever_meter_changed", fever_meter)
	
	if chain_index >= fever_combo_threshold and not is_fever_active:
		is_fever_active = true
		fever_remaining = fever_duration
		fever_meter = 0.0
		emit_signal("fever_activated")
		_emit_game_event("fever_started", fever_duration, score_multiplier_fever)
	elif is_fever_active:
		fever_remaining = fever_duration
		
	var chain_bonus := float(chain_index) * 25.0
	var mult := 3.0 if is_special else 1.0
	var raw_power := (base_score * mult) + chain_bonus + (50.0 if is_cascade else 0.0)
	
	return clamp(raw_power, min_power, max_power)

func on_invalid_move() -> void:
	combo_window_remaining = max(0.0, combo_window_remaining - invalid_move_penalty)
	if combo_window_remaining <= 0.0:
		chain_index = 0
		emit_signal("combo_expired")
		_emit_game_event("fever_ended")

func sigmoid_curve(x: float) -> float:
	var raw := min_power + (max_power - min_power) / (1.0 + exp(-x / 10.0))
	return clamp(raw, min_power, max_power)
