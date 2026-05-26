# /Users/user/3-line/scripts/core_match3/controlled_cascade_engine.gd
class_name ControlledCascadeEngine
extends RefCounted

## Ядро Controlled Cascade Engine.
## Реализует три режима каскадов: Natural, Assisted, Cinematic.

signal cascade_calculated(step_index: int, drop_mode: int, generated_gems: Array)
signal cascade_blocked_by_governor(reason: String)

enum DropMode {
	NATURAL = 0,
	ASSISTED = 1,
	CINEMATIC = 2
}

var current_mode: int = DropMode.NATURAL
var assisted_cooldown_counter: int = 0
var assisted_triggers_this_level: int = 0
var cinematic_triggers_this_level: int = 0

var _rng_ctrl: DropRngController
var _casc_gov: CascadeGovernor
var _bal_gov: BalanceGovernor
var _rules: Dictionary = {}

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

func initialize(rules_json: Dictionary, seed_val: int) -> void:
	_rules = rules_json
	_rng_ctrl = DropRngController.new(seed_val)
	_casc_gov = CascadeGovernor.new(rules_json.get("default_settings", {}))
	_bal_gov = BalanceGovernor.new(rules_json)

func prepare_for_level(difficulty_profile: Dictionary) -> void:
	current_mode = DropMode.NATURAL
	assisted_cooldown_counter = 0
	assisted_triggers_this_level = 0
	cinematic_triggers_this_level = 0
	_rng_ctrl.reset()
	_casc_gov.reset()
	_bal_gov.configure_for_level(difficulty_profile)

func fill_empty_cells(board_state: Array, empty_cells: Array[Vector2i], last_move_meta: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	var mode = _bal_gov.determine_drop_mode(last_move_meta, assisted_triggers_this_level, assisted_cooldown_counter)
	current_mode = mode
	
	if not _casc_gov.allow_next_step():
		emit_signal("cascade_blocked_by_governor", "Max depth cap reached")
		mode = DropMode.NATURAL
		
	var color_weights = _calculate_color_weights(board_state, empty_cells, mode, last_move_meta)
	
	for cell in empty_cells:
		var gem_type = _rng_ctrl.roll_gem_type(color_weights)
		result.append({
			"position": cell,
			"gem_type": gem_type,
			"is_assisted": (mode == DropMode.ASSISTED or mode == DropMode.CINEMATIC)
		})
		
	if mode == DropMode.ASSISTED:
		assisted_triggers_this_level += 1
		assisted_cooldown_counter = _rules.get("default_settings", {}).get("assisted_drop_cooldown_turns", 3)
	elif mode == DropMode.CINEMATIC:
		cinematic_triggers_this_level += 1
		
	if assisted_cooldown_counter > 0 and mode == DropMode.NATURAL:
		assisted_cooldown_counter -= 1
		
	_casc_gov.increment_depth()
	
	# Публикуем типизированный контракт CascadeStep в EventBus
	var step_contract = CascadeStep.new(_casc_gov.current_depth, mode, result)
	_emit_game_event("cascade_step_resolved", step_contract)
	
	emit_signal("cascade_calculated", _casc_gov.current_depth, mode, result)
	return result

func notify_turn_ended() -> void:
	_casc_gov.reset()

func _calculate_color_weights(board_state: Array, empty_cells: Array[Vector2i], mode: int, last_move_meta: Dictionary) -> Dictionary:
	var default_weights = {"red": 1.0, "blue": 1.0, "green": 1.0, "yellow": 1.0, "purple": 1.0}
	if mode == DropMode.NATURAL:
		return default_weights
	return _bal_gov.get_biased_weights(board_state, empty_cells, default_weights, last_move_meta)
