extends RefCounted
class_name SheddingSystem

func collapse(board: BoardModel) -> Array[Dictionary]:
	var movements: Array[Dictionary] = []

	for x in range(board.width):
		var write_y := board.height - 1
		for y in range(board.height - 1, -1, -1):
			var from_cell := Vector2i(x, y)
			var piece := board.get_piece(from_cell)
			if piece < 0:
				continue

			var to_cell := Vector2i(x, write_y)
			if from_cell != to_cell:
				board.set_piece(to_cell, piece)
				board.set_piece(from_cell, -1)
				movements.append({
					"piece_id": piece,
					"from": from_cell,
					"to": to_cell,
				})
			write_y -= 1

	return movements

