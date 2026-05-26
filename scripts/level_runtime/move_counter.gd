## MoveCounter — счётчик ходов уровня
extends RefCounted
class_name MoveCounter

var max_moves: int = 0
var moves_used: int = 0

## Инициализация для нового уровня
func setup(p_max_moves: int) -> void:
	max_moves = p_max_moves
	moves_used = 0

## Использовать ход. Returns false если ходы закончились.
func use_move() -> bool:
	if moves_used >= max_moves:
		return false
	moves_used += 1
	return true

## Остаток ходов
func remaining() -> int:
	return maxi(0, max_moves - moves_used)

## Ходы закончились?
func is_exhausted() -> bool:
	return moves_used >= max_moves

func snapshot() -> Dictionary:
	return {
		"max_moves": max_moves,
		"moves_used": moves_used,
	}

func restore(state: Dictionary) -> void:
	max_moves = int(state.get("max_moves", max_moves))
	moves_used = int(state.get("moves_used", moves_used))
