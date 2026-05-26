# /Users/user/3-line/scripts/contracts/match_event.gd
class_name MatchEvent
extends RefCounted

## Контракт найденной группы совпадений (Match-3+).
## Передается по EventBus в VFX и систему начисления очков.

var coordinates: Array[Vector2i] = []
var color: String = ""
var shape_type: String = "line_3" # E.g. line_3, line_4, square_2x2
var score: int = 0

func _init(p_coords: Array[Vector2i] = [], p_color: String = "", p_shape: String = "line_3", p_score: int = 0) -> void:
	coordinates = p_coords
	color = p_color
	shape_type = p_shape
	score = p_score

func serialize() -> Dictionary:
	var coords_arr = []
	for coord in coordinates:
		coords_arr.append({"x": coord.x, "y": coord.y})
	return {
		"coordinates": coords_arr,
		"color": color,
		"shape_type": shape_type,
		"score": score
	}

func deserialize(data: Dictionary) -> void:
	color = data.get("color", "")
	shape_type = data.get("shape_type", "line_3")
	score = data.get("score", 0)
	coordinates.clear()
	var coords_arr = data.get("coordinates", [])
	for c in coords_arr:
		coordinates.append(Vector2i(c.get("x", 0), c.get("y", 0)))
