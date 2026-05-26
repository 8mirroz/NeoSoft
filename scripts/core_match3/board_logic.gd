# /Users/user/3-line/scripts/core_match3/board_logic.gd
extends RefCounted
class_name BoardLogic

## Логическое детерминированное ядро сетки игрового поля.
## Не зависит от визуальных представлений и шейдеров.

signal cell_state_changed(cell: Vector2i, old_state: int, new_state: int)
signal cell_gem_changed(cell: Vector2i, old_gem: String, new_gem: String)
signal board_stabilized()

var width: int = 8
var height: int = 8
var cells: Array = [] # Двумерный массив String цветов гемов
var states: Array = [] # Двумерный массив int состояний CellState.State

func configure(p_width: int, p_height: int, default_color: String = "red") -> void:
	width = p_width
	height = p_height
	cells.clear()
	states.clear()
	cells.resize(height)
	states.resize(height)
	
	for y in range(height):
		cells[y] = []
		states[y] = []
		cells[y].resize(width)
		states[y].resize(width)
		for x in range(width):
			cells[y][x] = default_color
			states[y][x] = CellState.State.STABLE

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func get_gem(cell: Vector2i) -> String:
	if not is_in_bounds(cell):
		return ""
	return cells[cell.y][cell.x]

func set_gem(cell: Vector2i, gem_type: String) -> bool:
	if not is_in_bounds(cell):
		return false
	var old_gem = cells[cell.y][cell.x]
	if old_gem != gem_type:
		cells[cell.y][cell.x] = gem_type
		emit_signal("cell_gem_changed", cell, old_gem, gem_type)
	return true

func get_cell_state(cell: Vector2i) -> int:
	if not is_in_bounds(cell):
		return CellState.State.BLOCKED
	return states[cell.y][cell.x]

func set_cell_state(cell: Vector2i, new_state: int) -> bool:
	if not is_in_bounds(cell):
		return false
	var old_state = states[cell.y][cell.x]
	if old_state != new_state:
		states[cell.y][cell.x] = new_state
		emit_signal("cell_state_changed", cell, old_state, new_state)
		if new_state == CellState.State.STABLE:
			_check_stabilization()
	return true

func is_cell_stable(cell: Vector2i) -> bool:
	return get_cell_state(cell) == CellState.State.STABLE

func swap_gems(a: Vector2i, b: Vector2i) -> bool:
	if not is_in_bounds(a) or not is_in_bounds(b):
		return false
	var gem_a = cells[a.y][a.x]
	var gem_b = cells[b.y][b.x]
	cells[a.y][a.x] = gem_b
	cells[b.y][b.x] = gem_a
	emit_signal("cell_gem_changed", a, gem_a, gem_b)
	emit_signal("cell_gem_changed", b, gem_b, gem_a)
	return true

func load_snapshot(snapshot: BoardSnapshot) -> void:
	width = snapshot.width
	height = snapshot.height
	cells.clear()
	states.clear()
	cells.resize(height)
	states.resize(height)
	
	for y in range(height):
		cells[y] = []
		states[y] = []
		cells[y].resize(width)
		states[y].resize(width)
		for x in range(width):
			var cell_data = snapshot.cells[y][x]
			cells[y][x] = cell_data.get("color", "red")
			states[y][x] = cell_data.get("state", CellState.State.STABLE)

func create_snapshot() -> BoardSnapshot:
	var snapshot = BoardSnapshot.new(width, height)
	for y in range(height):
		for x in range(width):
			snapshot.cells[y][x] = {
				"color": cells[y][x],
				"state": states[y][x],
				"special_type": 0
			}
	return snapshot

func force_stabilize() -> void:
	for y in range(height):
		for x in range(width):
			states[y][x] = CellState.State.STABLE
	emit_signal("board_stabilized")

func _check_stabilization() -> void:
	for y in range(height):
		for x in range(width):
			var s = states[y][x]
			if s != CellState.State.STABLE and s != CellState.State.BLOCKED and s != CellState.State.TARGET:
				return
	emit_signal("board_stabilized")
