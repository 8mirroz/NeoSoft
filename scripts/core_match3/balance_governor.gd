# /Users/user/3-line/scripts/core_match3/balance_governor.gd
class_name BalanceGovernor
extends RefCounted

## Регулятор баланса и честности ассистов каскадов.
## Препятствует слишком легким победам и отключает ассисты при перегрузках.

var _rules: Dictionary
var _diff_profile: Dictionary
var _fail_streak: int = 0
var _objective_cascade_destruction_count: int = 0

func _init(rules: Dictionary) -> void:
	_rules = rules

func configure_for_level(difficulty_profile: Dictionary) -> void:
	_diff_profile = difficulty_profile
	_objective_cascade_destruction_count = 0

func update_fail_streak(streak: int) -> void:
	_fail_streak = streak

func determine_drop_mode(last_move_meta: Dictionary, triggers_count: int, cooldown: int) -> int:
	if not _diff_profile.get("assisted_drop_enabled", true):
		return ControlledCascadeEngine.DropMode.NATURAL
		
	if last_move_meta.get("is_fever_active", false) or last_move_meta.get("is_last_move_drama", false):
		return ControlledCascadeEngine.DropMode.CINEMATIC
		
	var max_assisted = _rules.get("default_settings", {}).get("assisted_drop_max_per_level", 4)
	if triggers_count >= max_assisted:
		return ControlledCascadeEngine.DropMode.NATURAL
		
	if cooldown > 0:
		return ControlledCascadeEngine.DropMode.NATURAL
		
	var shape_type = last_move_meta.get("shape_type", "line_3")
	var is_complex_shape = shape_type != "line_3"
	var fail_streak_trigger = _fail_streak >= _diff_profile.get("fail_streak_assist_trigger", 2)
	
	if is_complex_shape or fail_streak_trigger:
		# Защита от авто-побед: если слишком много целей сбито каскадами, убираем ассист
		if _objective_cascade_destruction_count >= 10: # Лимит 10 сбитых целей каскадами
			return ControlledCascadeEngine.DropMode.NATURAL
		return ControlledCascadeEngine.DropMode.ASSISTED
		
	return ControlledCascadeEngine.DropMode.NATURAL

func get_biased_weights(board_state: Array, empty_cells: Array[Vector2i], default_weights: Dictionary, last_move_meta: Dictionary) -> Dictionary:
	var biased_weights = default_weights.duplicate()
	var dominant_color = last_move_meta.get("dominant_color", "")
	if dominant_color != "" and biased_weights.has(dominant_color):
		var multiplier = 1.2
		var shape = last_move_meta.get("shape_type", "line_3")
		
		if shape == "line_4" or shape == "square_2x2":
			multiplier = 1.2
		elif shape == "l_5" or shape == "t_5" or shape == "line_5":
			multiplier = 1.5
		elif last_move_meta.get("is_fever_active", false):
			multiplier = 1.8
			
		biased_weights[dominant_color] = default_weights[dominant_color] * multiplier
		
	return biased_weights

func register_objective_destroyed_by_cascade() -> void:
	_objective_cascade_destruction_count += 1
