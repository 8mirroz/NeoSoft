# /Users/user/3-line/scripts/core_match3/combo_fever_controller.gd
extends RefCounted
class_name ComboFeverController

## Контроллер Fever Mode и накопления Fever Meter.
## Переводит события Fever в шину GameEventBus.

var config_path: String = "res://data/ui/theme_tokens.json"

var base_duration_normal: float = 1.5
var fever_combo_threshold: int = 5
var fever_duration: float = 6.0
var score_multiplier_fever: float = 2.5
var min_power: float = 100.0
var max_power: float = 1500.0

var chain_index: int = 0
var combo_window_remaining: float = 0.0
var combo_window_max: float = 1.5
var fever_meter: float = 0.0
var fever_remaining: float = 0.0
var is_fever_active: bool = false

func _init() -> void:
	combo_window_max = base_duration_normal

func update(delta: float) -> void:
	if combo_window_remaining > 0.0:
		combo_window_remaining -= delta
		if combo_window_remaining <= 0.0:
			combo_window_remaining = 0.0
			chain_index = 0
			GameEventBus.emit_signal("fever_ended") # Упрощенное уведомление шины
			
	if is_fever_active and fever_remaining > 0.0:
		fever_remaining -= delta
		if fever_remaining <= 0.0:
			fever_remaining = 0.0
			is_fever_active = false
			GameEventBus.emit_signal("fever_ended")

func on_match_detected(shape_type: String, is_cascade: bool = false) -> float:
	chain_index += 1
	
	fever_meter = clamp(fever_meter + (100.0 / float(fever_combo_threshold)), 0.0, 100.0)
	GameEventBus.emit_signal("fever_meter_changed", fever_meter)
	
	if chain_index >= fever_combo_threshold and not is_fever_active:
		is_fever_active = true
		fever_remaining = fever_duration
		fever_meter = 0.0
		GameEventBus.emit_signal("fever_started", fever_duration, score_multiplier_fever)
	elif is_fever_active:
		fever_remaining = fever_duration
		
	var base_match_val = 100.0
	var chain_bonus = float(chain_index) * 25.0
	var raw_power = base_match_val + chain_bonus + (15.0 if is_cascade else 0.0)
	
	return clamp(raw_power, min_power, max_power)
