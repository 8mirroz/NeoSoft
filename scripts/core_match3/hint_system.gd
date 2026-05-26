## HintSystem — система подсказок (p2.md §22)
## Если игрок бездействует 5-7 секунд, подсветить возможную пару
extends RefCounted
class_name HintSystem

## Найти первый доступный ход на поле
## Returns: Array из двух Vector2i (пара для swap), или пустой если ходов нет
static func find_hint(board: BoardModel, match_sys: MatchSystem) -> Array[Vector2i]:
	var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

	for y in range(board.height):
		for x in range(board.width):
			var cell := Vector2i(x, y)
			if board.get_piece(cell) < 0:
				continue

			for dir in directions:
				var neighbor: Vector2i = cell + dir
				if not board.is_in_bounds(neighbor):
					continue
				if board.get_piece(neighbor) < 0:
					continue

				# Пробуем swap
				board.swap_pieces(cell, neighbor)
				var matches := match_sys.find_matches(board)
				# Откатываем
				board.swap_pieces(cell, neighbor)

				if not matches.is_empty():
					return [cell, neighbor]

	return []

## Проверить, есть ли вообще доступные ходы
static func has_valid_moves(board: BoardModel, match_sys: MatchSystem) -> bool:
	return not find_hint(board, match_sys).is_empty()

## Найти первый доступный ход на поле для CFE-режима (BoardLogic + ShapeDetector)
static func find_cfe_hint(board: BoardLogic, detector: ShapeDetector) -> Array[Vector2i]:
	var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

	for y in range(board.height):
		for x in range(board.width):
			var cell := Vector2i(x, y)
			if board.get_gem(cell) == "":
				continue

			for dir in directions:
				var neighbor: Vector2i = cell + dir
				if not board.is_in_bounds(neighbor):
					continue
				if board.get_gem(neighbor) == "":
					continue

				# Пробуем swap
				board.swap_gems(cell, neighbor)
				var matches := detector.detect_shapes(board)
				# Откатываем
				board.swap_gems(cell, neighbor)

				if not matches.is_empty():
					return [cell, neighbor]

	return []
