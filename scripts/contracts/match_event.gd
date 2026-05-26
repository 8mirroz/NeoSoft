# /Users/user/3-line/scripts/contracts/match_event.gd
extends RefCounted
class_name MatchEvent

## Контракт события совпадения (Match Event DTO).

var shape_type: String = "LINE_3" # LINE_3, LINE_4, SQUARE_2X2, CROSS, ZIGZAG_6, etc.
var cells: Array[Vector2i] = []
var center_cell: Vector2i = Vector2i(-1, -1)
var origin_cell: Vector2i = Vector2i(-1, -1)
var gem_color: String = ""
var score_granted: int = 0

func _init(p_type: String, p_cells: Array[Vector2i], p_center: Vector2i, p_origin: Vector2i, p_color: String, p_score: int) -> void:
	shape_type = p_type
	cells = p_cells
	center_cell = p_center
	origin_cell = p_origin
	gem_color = p_color
	score_granted = p_score

func to_dict() -> Dictionary:
	var flat_cells = []
	for c in cells:
		flat_cells.append({"x": c.x, "y": c.y})
	return {
		"shape_type": shape_type,
		"cells": flat_cells,
		"center_cell": {"x": center_cell.x, "y": center_cell.y},
		"origin_cell": {"x": origin_cell.x, "y": origin_cell.y},
		"gem_color": gem_color,
		"score_granted": score_granted
	}
