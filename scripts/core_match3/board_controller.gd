extends Node
class_name BoardController

signal swap_requested(from_cell: Vector2i, to_cell: Vector2i)
signal swap_rejected(from_cell: Vector2i, to_cell: Vector2i)
signal swap_resolved(from_cell: Vector2i, to_cell: Vector2i)
signal matches_resolved(matches: Array[Dictionary])
signal board_collapsed(movements: Array[Dictionary])
signal pieces_generated(spawns: Array[Dictionary])
signal turn_finished

@export var board_width: int = 8
@export var board_height: int = 8
@export var piece_kinds: int = 6
@export var random_seed: int = 0

var rng := RandomNumberGenerator.new()
var board := BoardModel.new()
var match_system := MatchSystem.new()
var shedding_system := SheddingSystem.new()
var generation_system := GenerationSystem.new()
var _initialized: bool = false

func _ready() -> void:
	initialize()

func initialize() -> void:
	if _initialized:
		return
	_initialized = true
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed

	board.configure(board_width, board_height, -1)
	_initial_fill_without_matches()

func request_swap(from_cell: Vector2i, to_cell: Vector2i) -> void:
	emit_signal("swap_requested", from_cell, to_cell)
	if not _is_adjacent(from_cell, to_cell):
		emit_signal("swap_rejected", from_cell, to_cell)
		return

	if not board.swap_pieces(from_cell, to_cell):
		emit_signal("swap_rejected", from_cell, to_cell)
		return

	var matches := match_system.find_matches(board)
	if matches.is_empty():
		board.swap_pieces(from_cell, to_cell)
		emit_signal("swap_rejected", from_cell, to_cell)
		return

	emit_signal("swap_resolved", from_cell, to_cell)
	_resolve_turn(matches)

func resolve_board_if_needed() -> bool:
	var matches := match_system.find_matches(board)
	if matches.is_empty():
		return false
	_resolve_turn(matches)
	return true

func has_valid_moves() -> bool:
	return HintSystem.has_valid_moves(board, match_system)

func shuffle_board(max_attempts: int = 12) -> bool:
	var original_cells := board.snapshot()
	var source_pieces := _collect_pieces()
	if source_pieces.is_empty():
		return false

	for _attempt in range(max_attempts):
		var pool: Array[int] = source_pieces.duplicate()
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := pool[i]
			pool[i] = pool[j]
			pool[j] = tmp

		board.configure(board.width, board.height, GameConstants.EMPTY_CELL)
		if not _fill_from_piece_pool(pool):
			continue

		if match_system.find_matches(board).is_empty() and has_valid_moves():
			return true

	board.restore_from_snapshot(original_cells)
	return false

func snapshot() -> Dictionary:
	return {
		"width": board.width,
		"height": board.height,
		"cells": board.snapshot(),
		"rng_state": rng.state,
	}

func restore(state: Dictionary) -> void:
	board_width = int(state.get("width", board_width))
	board_height = int(state.get("height", board_height))
	board.configure(board_width, board_height, GameConstants.EMPTY_CELL)
	board.restore_from_snapshot(state.get("cells", []))
	if state.has("rng_state"):
		rng.state = int(state["rng_state"])

func _resolve_turn(initial_matches: Array[Dictionary]) -> void:
	var matches := initial_matches
	while not matches.is_empty():
		emit_signal("matches_resolved", matches)
		_clear_matches(matches)

		var movements := shedding_system.collapse(board)
		emit_signal("board_collapsed", movements)

		var spawns := generation_system.refill(board, rng, piece_kinds)
		emit_signal("pieces_generated", spawns)

		matches = match_system.find_matches(board)

	emit_signal("turn_finished")

func _clear_matches(matches: Array[Dictionary]) -> void:
	for match in matches:
		var cells: Array = match.get("cells", [])
		for cell_variant in cells:
			var cell: Vector2i = cell_variant
			board.set_piece(cell, -1)

func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta := a - b
	return abs(delta.x) + abs(delta.y) == 1

func _initial_fill_without_matches() -> void:
	for y in range(board.height):
		for x in range(board.width):
			var cell := Vector2i(x, y)
			var piece_id := rng.randi_range(0, piece_kinds - 1)
			board.set_piece(cell, piece_id)
			while _creates_match_at(cell, piece_id):
				piece_id = (piece_id + 1) % piece_kinds
				board.set_piece(cell, piece_id)

func _creates_match_at(cell: Vector2i, piece: int = GameConstants.EMPTY_CELL) -> bool:
	if piece == GameConstants.EMPTY_CELL:
		piece = board.get_piece(cell)
	if piece < 0:
		return false

	var x := cell.x
	var y := cell.y

	if x >= 2:
		if board.get_piece(Vector2i(x - 1, y)) == piece and board.get_piece(Vector2i(x - 2, y)) == piece:
			return true

	if y >= 2:
		if board.get_piece(Vector2i(x, y - 1)) == piece and board.get_piece(Vector2i(x, y - 2)) == piece:
			return true

	return false

func _collect_pieces() -> Array[int]:
	var pieces: Array[int] = []
	for y in range(board.height):
		for x in range(board.width):
			var piece := board.get_piece(Vector2i(x, y))
			if piece >= 0:
				pieces.append(piece)
	return pieces

func _fill_from_piece_pool(pool: Array[int]) -> bool:
	for y in range(board.height):
		for x in range(board.width):
			var cell := Vector2i(x, y)
			var chosen_index := _find_piece_candidate_index(pool, cell)
			if chosen_index < 0:
				return false
			var piece_id := pool[chosen_index]
			pool.remove_at(chosen_index)
			board.set_piece(cell, piece_id)
	return true

func _find_piece_candidate_index(pool: Array[int], cell: Vector2i) -> int:
	for index in range(pool.size()):
		if not _creates_match_at(cell, pool[index]):
			return index
	return -1
