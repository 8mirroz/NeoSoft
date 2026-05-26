extends RefCounted
class_name GenerationSystem

func refill(board: BoardModel, rng: RandomNumberGenerator, piece_kinds: int) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	for y in range(board.height):
		for x in range(board.width):
			var cell := Vector2i(x, y)
			if board.get_piece(cell) >= 0:
				continue

			var piece_id := rng.randi_range(0, piece_kinds - 1)
			board.set_piece(cell, piece_id)

			var attempts := 0
			while _creates_match_at(board, cell, piece_id) and attempts < piece_kinds:
				piece_id = (piece_id + 1) % piece_kinds
				board.set_piece(cell, piece_id)
				attempts += 1

			spawns.append({
				"piece_id": piece_id,
				"to": cell,
			})
	return spawns

func _creates_match_at(board: BoardModel, cell: Vector2i, piece: int) -> bool:
	var x := cell.x
	var y := cell.y

	if x >= 2:
		if board.get_piece(Vector2i(x - 1, y)) == piece and board.get_piece(Vector2i(x - 2, y)) == piece:
			return true

	if y >= 2:
		if board.get_piece(Vector2i(x, y - 1)) == piece and board.get_piece(Vector2i(x, y - 2)) == piece:
			return true

	return false


