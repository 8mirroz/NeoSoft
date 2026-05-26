# /Users/user/3-line/scripts/contracts/board_snapshot.gd
extends RefCounted
class_name BoardSnapshot

## Контракт снимка логического состояния игрового поля (Read-Only DTO).

var width: int = 8
var height: int = 8
var gems: Array[Array] = [] # 2D Array of String (color names or empty)
var cell_states: Array[Array] = [] # 2D Array of int (CellState.State enum values)
var timestamp: float = 0.0

func _init(p_width: int, p_height: int, p_gems: Array[Array], p_states: Array[Array]) -> void:
	width = p_width
	height = p_height
	gems = p_gems
	cell_states = p_states
	timestamp = Time.get_ticks_msec() / 1000.0

## Сериализация снимка в плоский JSON-совместимый словарь для Replay/Telemetry
func to_dict() -> Dictionary:
	return {
		"width": width,
		"height": height,
		"gems": gems,
		"cell_states": cell_states,
		"timestamp": timestamp
	}
