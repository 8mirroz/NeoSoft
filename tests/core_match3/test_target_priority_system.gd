extends "res://addons/gut/test.gd"

# Юнит-тесты для TargetPrioritySystem

func test_priority_objective_target_first() -> void:
	var board := BoardStateEngine.new()
	board.configure(4, 4, 1)
	
	# Ячейка (0,0) - это цель уровня (TARGET)
	board.set_cell_state(Vector2i(0, 0), CellState.State.TARGET)
	
	var system := TargetPrioritySystem.new()
	var best := system.find_best_target(board)
	
	assert_eq(best, Vector2i(0, 0), "Цель уровня должна быть выбрана в первую очередь")

func test_priority_locked_objective() -> void:
	var board := BoardStateEngine.new()
	board.configure(4, 4, 1)
	
	# Ячейка (1,1) - обычная цель уровня
	board.set_cell_state(Vector2i(1, 1), CellState.State.TARGET)
	board.set_piece(Vector2i(1, 1), -1) # без фишки
	
	# Ячейка (2,2) - заблокированная цель (есть фишка/лед сверху)
	board.set_cell_state(Vector2i(2, 2), CellState.State.TARGET)
	board.set_piece(Vector2i(2, 2), 2)
	
	var system := TargetPrioritySystem.new()
	var best := system.find_best_target(board)
	
	assert_eq(best, Vector2i(2, 2), "Заблокированная цель должна иметь более высокий приоритет")

func test_priority_corner_target() -> void:
	var board := BoardStateEngine.new()
	board.configure(4, 4, 1)
	
	# Ячейка (2,1) - цель в центре поля
	board.set_cell_state(Vector2i(2, 1), CellState.State.TARGET)
	
	# Ячейка (3,3) - цель в углу поля
	board.set_cell_state(Vector2i(3, 3), CellState.State.TARGET)
	
	var system := TargetPrioritySystem.new()
	var best := system.find_best_target(board)
	
	assert_eq(best, Vector2i(3, 3), "Угловая цель должна иметь преимущество над центральной")

func test_deterministic_tie_breaker() -> void:
	var board := BoardStateEngine.new()
	board.configure(4, 4, 1)
	
	# Создаем две одинаковые цели в строках 1 и 2
	board.set_cell_state(Vector2i(0, 1), CellState.State.TARGET)
	board.set_cell_state(Vector2i(0, 2), CellState.State.TARGET)
	
	var system := TargetPrioritySystem.new()
	var best_first := system.find_best_target(board)
	var best_second := system.find_best_target(board)
	
	assert_eq(best_first, best_second, "Выбор целей должен быть абсолютно детерминированным")
	assert_eq(best_first, Vector2i(0, 1), "Ячейка выше должна быть выбрана для помощи в осыпании")
