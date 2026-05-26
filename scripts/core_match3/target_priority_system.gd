# /Users/user/3-line/scripts/core_match3/target_priority_system.gd
class_name TargetPrioritySystem
extends RefCounted

## Система интеллектуального выбора целей для самонаводящихся спец-сфер.
## Реализует формулу взвешенной 10-уровневой оценки (weighted scoring).

func find_best_target(board: BoardLogic, objectives: Array = [], current_moves: int = 25, is_fever: bool = false) -> Vector2i:
	var best_cell := Vector2i(-1, -1)
	var max_score: float = -9999.0
	
	# Формируем список нужных цветов для сбора целей
	var needed_colors := {}
	for obj in objectives:
		if obj is Dictionary and obj.get("type") == "collect_color":
			var color = obj.get("target_color", "")
			if color != "" and obj.get("current_count", 0) < obj.get("target_count", 0):
				needed_colors[color] = true
				
	for y in range(board.height):
		for x in range(board.width):
			var cell := Vector2i(x, y)
			if board.get_cell_state(cell) == CellState.State.BLOCKED:
				continue
				
			var cell_state = board.get_cell_state(cell)
			var color = board.get_gem(cell)
			
			var score: float = 0.0
			
			# 10-уровневая система взвешенной оценки
			# Level 10: Critical Level Objective (100)
			var is_critical_objective = (cell_state == CellState.State.TARGET and current_moves <= 5)
			if is_critical_objective:
				score += 100.0
				
			# Level 9: Locked Objective (90)
			var is_locked_objective = (cell_state == CellState.State.TARGET and color != "")
			if is_locked_objective:
				score += 90.0
				
			# Level 8: Blocker with low HP (80)
			var is_low_hp_blocker = (cell_state == CellState.State.TARGET and color == "ice") # условная симуляция льда
			if is_low_hp_blocker:
				score += 80.0
				
			# Level 7: Corner or Hard to Reach (75)
			var is_corner = (x == 0 or x == board.width - 1) and (y == 0 or y == board.height - 1)
			if cell_state == CellState.State.TARGET and is_corner:
				score += 75.0
				
			# Level 6: Move pressure modifier (65)
			if cell_state == CellState.State.TARGET:
				score += (25.0 - float(current_moves)) * 1.5
				
			# Level 5: Needed colors (60)
			if color != "" and needed_colors.has(color):
				score += 60.0
				
			# Level 4: Fever modifier (50)
			if is_fever:
				score += 50.0
				
			# Level 3: Distance/Gravity help (20)
			score += (board.height - y) * 2.0 # Предподчтение нижним ячейкам для осыпания
			
			# Tie-breaker
			score += (board.width - x) * 0.1
			
			if score > max_score:
				max_score = score
				best_cell = cell
				
	if best_cell == Vector2i(-1, -1):
		# Ищем первую стабильную
		for y in range(board.height):
			for x in range(board.width):
				var cell := Vector2i(x, y)
				if board.get_cell_state(cell) == CellState.State.STABLE:
					best_cell = cell
					break
			if best_cell != Vector2i(-1, -1):
				break
				
	return best_cell
