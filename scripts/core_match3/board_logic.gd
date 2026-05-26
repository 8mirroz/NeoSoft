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

func configure(p_width: int, p_height: int, default_color: Variant = "red") -> void:
	width = p_width
	height = p_height
	cells.clear()
	states.clear()
	cells.resize(height)
	states.resize(height)
	
	var default_str := "red"
	if typeof(default_color) == TYPE_INT:
		match default_color:
			-1: default_str = ""
			0: default_str = "red"
			1: default_str = "blue"
			2: default_str = "green"
			3: default_str = "yellow"
			4: default_str = "purple"
			5: default_str = "white"
			_: default_str = str(default_color)
	elif typeof(default_color) == TYPE_STRING:
		default_str = default_color
		
	for y in range(height):
		cells[y] = []
		states[y] = []
		cells[y].resize(width)
		states[y].resize(width)
		for x in range(width):
			cells[y][x] = default_str
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
		if not _is_valid_transition(old_state, new_state):
			return false
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

func _is_valid_transition(from_state: int, to_state: int) -> bool:
	if from_state == to_state:
		return true
	if to_state == CellState.State.RESERVED or to_state == CellState.State.RESOLVING:
		return true
	match from_state:
		CellState.State.STABLE:
			return to_state != CellState.State.SPAWNING and to_state != CellState.State.FALLING
		CellState.State.RESERVED:
			return to_state == CellState.State.STABLE or to_state == CellState.State.RESOLVING
		CellState.State.RESOLVING:
			return to_state == CellState.State.LOCKED or to_state == CellState.State.STABLE
		CellState.State.LOCKED:
			return to_state == CellState.State.FALLING or to_state == CellState.State.STABLE or to_state == CellState.State.SPAWNING
		CellState.State.FALLING:
			return to_state == CellState.State.STABLE
		CellState.State.SPAWNING:
			return to_state == CellState.State.STABLE
	return true

func get_piece(cell: Vector2i) -> int:
	var gem := get_gem(cell)
	match gem:
		"red": return 0
		"blue": return 1
		"green": return 2
		"yellow": return 3
		"purple": return 4
		"white": return 5
		"": return -1
		_:
			if gem.is_valid_int():
				return gem.to_int()
			return 0

func set_piece(cell: Vector2i, piece_id: int) -> bool:
	var color := ""
	match piece_id:
		-1: color = ""
		0: color = "red"
		1: color = "blue"
		2: color = "green"
		3: color = "yellow"
		4: color = "purple"
		5: color = "white"
		_: color = str(piece_id)
	return set_gem(cell, color)
