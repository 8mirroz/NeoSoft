## GameStateMachine — конечный автомат игрового цикла
## Управляет переходами: IDLE → SWAP → MATCH → FALL → SPAWN → CASCADE_CHECK
## Архитектура: M3Engine FSM (master blueprint §7.1)
extends Node
class_name GameStateMachine

var _states: Dictionary = {}
var _current_state: LogicState = null
var _context: Dictionary = {}

signal state_changed(from_id: String, to_id: String)

func register_state(state: LogicState) -> void:
	_states[state.state_id] = state

func set_context(ctx: Dictionary) -> void:
	_context = ctx

func update_context(key: String, value: Variant) -> void:
	_context[key] = value

func start(initial_state_id: String) -> void:
	if not _states.has(initial_state_id):
		push_error("GameStateMachine: unknown state '%s'" % initial_state_id)
		return
	_current_state = _states[initial_state_id]
	_current_state.enter(_context)

func get_current_state_id() -> String:
	if _current_state:
		return _current_state.state_id
	return ""

func _process(delta: float) -> void:
	if _current_state == null:
		return

	var next_id := _current_state.tick(_context, delta)
	if next_id != _current_state.state_id:
		_transition_to(next_id)

func _transition_to(new_state_id: String) -> void:
	if not _states.has(new_state_id):
		push_error("GameStateMachine: unknown state '%s'" % new_state_id)
		return

	var old_id := _current_state.state_id
	_current_state.exit(_context)
	_current_state = _states[new_state_id]
	_current_state.enter(_context)
	emit_signal("state_changed", old_id, new_state_id)
