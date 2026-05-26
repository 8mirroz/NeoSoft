extends RefCounted
class_name LogicState

var state_id: String

func _init(p_state_id: String) -> void:
	state_id = p_state_id

func enter(context: Dictionary) -> void:
	pass

func tick(context: Dictionary, delta: float) -> String:
	return state_id

func exit(context: Dictionary) -> void:
	pass

