extends RefCounted
class_name BoardModel

var width: int = 0
var height: int = 0
var cells: Array[int] = []

func configure(p_width: int, p_height: int, fill_value: int = -1) -> void:
	width = p_width
	height = p_height
	cells.clear()
	cells.resize(width * height)
	for i in range(cells.size()):
		cells[i] = fill_value

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func get_index(cell: Vector2i) -> int:
	return cell.y * width + cell.x

func get_piece(cell: Vector2i) -> int:
	if not is_in_bounds(cell):
		return -1
	return cells[get_index(cell)]

func set_piece(cell: Vector2i, piece_id: int) -> bool:
	if not is_in_bounds(cell):
		return false
	cells[get_index(cell)] = piece_id
	return true

func swap_pieces(a: Vector2i, b: Vector2i) -> bool:
	if not is_in_bounds(a) or not is_in_bounds(b):
		return false
	var ai := get_index(a)
	var bi := get_index(b)
	var tmp := cells[ai]
	cells[ai] = cells[bi]
	cells[bi] = tmp
	return true

func snapshot() -> Array[int]:
	return cells.duplicate()

func restore_from_snapshot(snapshot_cells: Array[int]) -> void:
	if snapshot_cells.size() != width * height:
		return
	cells = snapshot_cells.duplicate()
