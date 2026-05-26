# /Users/user/3-line/scripts/core_match3/input_buffer_controller.gd
extends RefCounted
class_name InputBufferController

## Управляет очередью свайпов во время проигрывания каскадных анимаций.
## Позволяет буферизовать до 3-х ходов и предотвращает рассинхронизацию.

var queue: Array = [] # Массив QueuedMove
var max_queue_size: int = 3
var fast_chain_bonus_eligible: bool = false

func enqueue_move(from: Vector2i, to: Vector2i, board: BoardLogic, current_time: float, lifetime: float = 0.5) -> bool:
	if not _is_adjacent(from, to):
		return false
		
	if not board.is_in_bounds(from) or not board.is_in_bounds(to):
		return false
		
	if board.get_cell_state(from) == CellState.State.BLOCKED or board.get_cell_state(to) == CellState.State.BLOCKED:
		return false
		
	if board.is_cell_stable(from) and board.is_cell_stable(to):
		return false
		
	if board.get_cell_state(from) == CellState.State.RESERVED or board.get_cell_state(to) == CellState.State.RESERVED:
		return false
		
	clear_expired(board, current_time)
	
	if queue.size() >= max_queue_size:
		return false
		
	var from_gem = board.get_gem(from)
	var to_gem = board.get_gem(to)
	
	var queued = QueuedMove.new(
		from,
		to,
		current_time,
		current_time + lifetime,
		0, # expected_from_gem_id (устаревшее в v5.1)
		0,
		0,
		"buffered"
	)
	# Храним строковые типы гемов в метаданных кастомно
	queued.set_meta("expected_from_color", from_gem)
	queued.set_meta("expected_to_color", to_gem)
	
	board.set_cell_state(from, CellState.State.RESERVED)
	board.set_cell_state(to, CellState.State.RESERVED)
	
	queue.append(queued)
	fast_chain_bonus_eligible = true
	
	# Публикуем событие в EventBus
	GameEventBus.emit_signal("input_queued", from, to)
	return true

func validate_and_get_next(board: BoardLogic, current_time: float) -> QueuedMove:
	clear_expired(board, current_time)
	
	if queue.is_empty():
		return null
		
	var move = queue[0]
	var from_state = board.get_cell_state(move.from_cell)
	var to_state = board.get_cell_state(move.to_cell)
	
	if from_state == CellState.State.RESERVED and to_state == CellState.State.RESERVED:
		var curr_from = board.get_gem(move.from_cell)
		var curr_to = board.get_gem(move.to_cell)
		
		var exp_from = move.get_meta("expected_from_color") if move.has_meta("expected_from_color") else ""
		var exp_to = move.get_meta("expected_to_color") if move.has_meta("expected_to_color") else ""
		
		if curr_from == exp_from and curr_to == exp_to:
			queue.remove_at(0)
			board.set_cell_state(move.from_cell, CellState.State.STABLE)
			board.set_cell_state(move.to_cell, CellState.State.STABLE)
			
			board.set_cell_state(move.from_cell, CellState.State.RESOLVING)
			board.set_cell_state(move.to_cell, CellState.State.RESOLVING)
			return move
		else:
			queue.remove_at(0)
			board.set_cell_state(move.from_cell, CellState.State.STABLE)
			board.set_cell_state(move.to_cell, CellState.State.STABLE)
			
	return null

func clear_expired(board: BoardLogic, current_time: float) -> void:
	var i = 0
	while i < queue.size():
		var move = queue[i]
		if current_time >= move.expires_at:
			if board.get_cell_state(move.from_cell) == CellState.State.RESERVED:
				board.set_cell_state(move.from_cell, CellState.State.STABLE)
			if board.get_cell_state(move.to_cell) == CellState.State.RESERVED:
				board.set_cell_state(move.to_cell, CellState.State.STABLE)
			queue.remove_at(i)
		else:
			i += 1

func _force_clear_queue(board: BoardLogic) -> void:
	for move in queue:
		if board.get_cell_state(move.from_cell) == CellState.State.RESERVED:
			board.set_cell_state(move.from_cell, CellState.State.STABLE)
		if board.get_cell_state(move.to_cell) == CellState.State.RESERVED:
			board.set_cell_state(move.to_cell, CellState.State.STABLE)
	queue.clear()

func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta = a - b
	return abs(delta.x) + abs(delta.y) == 1
