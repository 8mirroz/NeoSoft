# /Users/user/3-line/scripts/contracts/board_snapshot.gd
class_name BoardSnapshot
extends RefCounted

## Снапшот состояния игрового поля на определенный шаг транзакции.
## Используется для детерминированного replay и MCTS симуляций.

var width: int = 8
var height: int = 8
var cells: Array = [] # Двумерный массив Dictionary-контрактов ячеек

func _init(p_width: int = 8, p_height: int = 8) -> void:
	width = p_width
	height = p_height
	cells.resize(height)
	for y in range(height):
		cells[y] = []
		cells[y].resize(width)
		for x in range(width):
			cells[y][x] = {
				"color": "",
				"state": 0, # CellState (0 = STABLE, 1 = RESERVED, etc.)
				"special_type": 0 # SpecialSphereType
			}

func duplicate_snapshot() -> BoardSnapshot:
	var dup = BoardSnapshot.new(width, height)
	for y in range(height):
		for x in range(width):
			dup.cells[y][x] = cells[y][x].duplicate()
	return dup

func serialize() -> Dictionary:
	return {
		"width": width,
		"height": height,
		"cells": cells
	}

func deserialize(data: Dictionary) -> void:
	width = data.get("width", 8)
	height = data.get("height", 8)
	cells = data.get("cells", [])
