extends RefCounted
class_name MatchShapeResult

var shape_type: String = "" # "LINE_3", "LINE_4", "LINE_5", "SQUARE_2X2", "L_SHAPE", "T_SHAPE", "CROSS", etc.
var cells: Array[Vector2i] = []
var origin_cell: Vector2i = Vector2i(-1, -1)
var center_cell: Vector2i = Vector2i(-1, -1)
var direction: Vector2i = Vector2i.ZERO # Vector2i.RIGHT или Vector2i.DOWN для линий
var weight: float = 1.0

func _init(p_type: String = "", p_cells: Array[Vector2i] = [], p_origin: Vector2i = Vector2i(-1, -1), p_center: Vector2i = Vector2i(-1, -1), p_dir: Vector2i = Vector2i.ZERO, p_weight: float = 1.0) -> void:
	shape_type = p_type
	cells = p_cells
	origin_cell = p_origin
	center_cell = p_center
	direction = p_dir
	weight = p_weight
