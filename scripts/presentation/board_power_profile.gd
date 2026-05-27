extends RefCounted
class_name BoardPowerProfile

var _board_view: Control

func setup(board_view: Control) -> void:
	_board_view = board_view

func get_particle_amount(base_amount: int) -> int:
	if _board_view == null:
		return base_amount
	
	var qp: Dictionary = _board_view.get("quality_profile")
	if qp.has("background_effect_alpha") and float(qp["background_effect_alpha"]) < 0.6:
		return (base_amount / 2) as int
	
	return base_amount
