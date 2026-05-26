# /Users/user/3-line/scripts/contracts/special_activation_event.gd
class_name SpecialActivationEvent
extends RefCounted

## Контракт активации/детонации спец-сферы или слияния комбо-эффекта.
## Передается по EventBus в VFX-директор для триггера взрывов спец-эффектов.

var position: Vector2i = Vector2i.ZERO
var special_type: int = 0 # SpecialSphereType
var affected_cells: Array[Vector2i] = []
var is_combo_trigger: bool = false
var combo_partner_type: int = 0

func _init(p_pos: Vector2i = Vector2i.ZERO, p_type: int = 0, p_cells: Array[Vector2i] = [], p_combo: bool = false, p_partner: int = 0) -> void:
	position = p_pos
	special_type = p_type
	affected_cells = p_cells
	is_combo_trigger = p_combo
	combo_partner_type = p_partner

func serialize() -> Dictionary:
	var cells_arr = []
	for cell in affected_cells:
		cells_arr.append({"x": cell.x, "y": cell.y})
	return {
		"x": position.x,
		"y": position.y,
		"special_type": special_type,
		"affected_cells": cells_arr,
		"is_combo_trigger": is_combo_trigger,
		"combo_partner_type": combo_partner_type
	}

func deserialize(data: Dictionary) -> void:
	position = Vector2i(data.get("x", 0), data.get("y", 0))
	special_type = data.get("special_type", 0)
	is_combo_trigger = data.get("is_combo_trigger", false)
	combo_partner_type = data.get("combo_partner_type", 0)
	affected_cells.clear()
	var cells_arr = data.get("affected_cells", [])
	for c in cells_arr:
		affected_cells.append(Vector2i(c.get("x", 0), c.get("y", 0)))
