# /Users/user/3-line/scripts/core_match3/special_combo_resolver.gd
class_name SpecialComboResolver
extends RefCounted

## Закодированная логика объединения спец-сфер при свайпе.
## Управляется внешним файлом special_combo_matrix.json.

var combo_data: Dictionary = {}

func _init() -> void:
	_load_config()

func _load_config() -> void:
	var path = "res://data/special_combo_matrix.json"
	if not FileAccess.file_exists(path):
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(text) == OK:
		combo_data = json.data.get("combos", {})

func resolve_combo(type_a: int, type_b: int, cell_a: Vector2i, cell_b: Vector2i, board: BoardLogic) -> Array[Vector2i]:
	var key = _get_combo_key(type_a, type_b)
	var result: Array[Vector2i] = []
	
	if not combo_data.has(key):
		# Fallback: просто взрываем обе сферы по отдельности
		return result
		
	var combo_spec = combo_data[key]
	var effect = combo_spec.get("effect", "")
	
	match effect:
		"clear_row_and_column":
			for x in range(board.width):
				result.append(Vector2i(x, cell_a.y))
			for y in range(board.height):
				result.append(Vector2i(cell_a.x, y))
		"clear_3_rows_and_3_columns":
			for dy in range(-1, 2):
				var target_y = cell_a.y + dy
				if target_y >= 0 and target_y < board.height:
					for x in range(board.width):
						result.append(Vector2i(x, target_y))
			for dx in range(-1, 2):
				var target_x = cell_a.x + dx
				if target_x >= 0 and target_x < board.width:
					for y in range(board.height):
						result.append(Vector2i(target_x, y))
		"radius_4_explosion":
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					var cell = cell_a + Vector2i(dx, dy)
					if board.is_in_bounds(cell):
						result.append(cell)
		"clear_board_and_strip_one_blocker_layer":
			for y in range(board.height):
				for x in range(board.width):
					result.append(Vector2i(x, y))
					
	return result

func _get_combo_key(type_a: int, type_b: int) -> String:
	var name_a = _get_sphere_name(type_a)
	var name_b = _get_sphere_name(type_b)
	if name_a < name_b:
		return name_a + "+" + name_b
	return name_b + "+" + name_a

func _get_sphere_name(type: int) -> String:
	match type:
		1: return "beam"
		2: return "homing"
		3: return "blast"
		4: return "pulse"
		5: return "prism"
		6: return "cross"
		7: return "gravity"
		8: return "lightning"
		9: return "field"
		10: return "dynamo"
		11: return "singularity"
	return "none"
