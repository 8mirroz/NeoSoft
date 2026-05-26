## SwapSystem — валидация и выполнение swap
## Отделён от BoardController для чистоты архитектуры
extends RefCounted
class_name SwapSystem

## Проверить, являются ли ячейки соседями (ортогональными)
static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta := a - b
	return absi(delta.x) + absi(delta.y) == 1

## Выполнить swap на модели, проверить match, откатить если нет
## Returns: { valid: bool, matches: Array[Dictionary] }
static func try_swap(board: BoardModel, match_sys: MatchSystem, from: Vector2i, to: Vector2i) -> Dictionary:
	if not is_adjacent(from, to):
		return { "valid": false, "matches": [] }

	if not board.is_in_bounds(from) or not board.is_in_bounds(to):
		return { "valid": false, "matches": [] }

	# Проверяем, что обе ячейки содержат фишки
	if board.get_piece(from) < 0 or board.get_piece(to) < 0:
		return { "valid": false, "matches": [] }

	# Выполняем swap
	board.swap_pieces(from, to)

	# Проверяем наличие совпадений
	var matches := match_sys.find_matches(board)

	if matches.is_empty():
		# Откат — swap недопустим
		board.swap_pieces(from, to)
		return { "valid": false, "matches": [] }

	return { "valid": true, "matches": matches }
