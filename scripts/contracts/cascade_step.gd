# /Users/user/3-line/scripts/contracts/cascade_step.gd
extends RefCounted
class_name CascadeStep

## Контракт шага каскадного осыпания (Cascade Step DTO).

var step_index: int = 1
var drop_mode: int = 0 # ControlledCascadeEngine.DropMode (NATURAL, ASSISTED, CINEMATIC)
var generated_gems: Array = [] # Array of Dictionary {"position": Vector2i, "gem_type": String, "is_assisted": bool}
var approved_by_governor: bool = true

func _init(p_idx: int, p_mode: int, p_gems: Array, p_approved: bool = true) -> void:
	step_index = p_idx
	drop_mode = p_mode
	generated_gems = p_gems
	approved_by_governor = p_approved

func to_dict() -> Dictionary:
	var flat_gems = []
	for g in generated_gems:
		var pos = g.get("position", Vector2i(-1, -1))
		flat_gems.append({
			"x": pos.x,
			"y": pos.y,
			"gem_type": g.get("gem_type", ""),
			"is_assisted": g.get("is_assisted", false)
		})
	return {
		"step_index": step_index,
		"drop_mode": drop_mode,
		"generated_gems": flat_gems,
		"approved_by_governor": approved_by_governor
	}
