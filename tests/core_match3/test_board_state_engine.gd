extends "res://addons/gut/test.gd"

# Юнит-тесты для BoardLogic

func test_configure() -> void:
	var board := BoardLogic.new()
	board.configure(8, 8, 5)
	
	assert_eq(board.width, 8, "Ширина должна быть 8")
	assert_eq(board.height, 8, "Высота должна быть 8")
	assert_eq(board.get_piece(Vector2i(0, 0)), 5, "Дефолтная фишка должна быть 5")
	assert_eq(board.get_cell_state(Vector2i(0, 0)), CellState.State.STABLE, "Начальное состояние должно быть STABLE")

func test_valid_state_transitions() -> void:
	var board := BoardLogic.new()
	board.configure(4, 4, 1)
	var cell := Vector2i(0, 0)
	
	# Проверка цепочки: STABLE -> RESERVED -> STABLE
	assert_true(board.set_cell_state(cell, CellState.State.RESERVED), "STABLE -> RESERVED должно быть валидно")
	assert_eq(board.get_cell_state(cell), CellState.State.RESERVED)
	
	assert_true(board.set_cell_state(cell, CellState.State.STABLE), "RESERVED -> STABLE должно быть валидно")
	assert_eq(board.get_cell_state(cell), CellState.State.STABLE)
	
	# Проверка цепочки: STABLE -> RESOLVING -> LOCKED -> FALLING -> STABLE
	assert_true(board.set_cell_state(cell, CellState.State.RESOLVING), "STABLE -> RESOLVING должно быть валидно")
	assert_true(board.set_cell_state(cell, CellState.State.LOCKED), "RESOLVING -> LOCKED должно быть валидно")
	assert_true(board.set_cell_state(cell, CellState.State.FALLING), "LOCKED -> FALLING должно быть валидно")
	assert_true(board.set_cell_state(cell, CellState.State.STABLE), "FALLING -> STABLE должно быть валидно")

func test_invalid_state_transitions() -> void:
	var board := BoardLogic.new()
	board.configure(4, 4, 1)
	var cell := Vector2i(0, 0)
	
	# Нельзя переходить напрямую из STABLE в SPAWNING
	assert_false(board.set_cell_state(cell, CellState.State.SPAWNING), "STABLE -> SPAWNING должно быть невалидно")
	assert_eq(board.get_cell_state(cell), CellState.State.STABLE)
	
	# Переводим в RESERVED
	board.set_cell_state(cell, CellState.State.RESERVED)
	# Нельзя переходить из RESERVED напрямую в FALLING или LOCKED
	assert_false(board.set_cell_state(cell, CellState.State.FALLING), "RESERVED -> FALLING должно быть заблокировано")
	assert_false(board.set_cell_state(cell, CellState.State.LOCKED), "RESERVED -> LOCKED должно быть заблокировано")

func test_force_stabilize() -> void:
	var board := BoardLogic.new()
	board.configure(4, 4, 1)
	
	# Переводим несколько ячеек в нестабильные состояния в обход проверок (или через валидные)
	board.set_cell_state(Vector2i(0, 0), CellState.State.RESOLVING)
	board.set_cell_state(Vector2i(1, 1), CellState.State.RESERVED)
	
	# Вызываем экстренную стабилизацию
	board.force_stabilize()
	
	assert_eq(board.get_cell_state(Vector2i(0, 0)), CellState.State.STABLE, "Должно сброситься в STABLE")
	assert_eq(board.get_cell_state(Vector2i(1, 1)), CellState.State.STABLE, "Должно сброситься в STABLE")

func test_stabilization_signal() -> void:
	var board := BoardLogic.new()
	board.configure(4, 4, 1)
	
	# Переводим ячейку в RESOLVING
	board.set_cell_state(Vector2i(0, 0), CellState.State.RESOLVING)
	
	watch_signals(board)
	
	# Перевод обратно в STABLE должен вызвать сигнал board_stabilized
	board.set_cell_state(Vector2i(0, 0), CellState.State.STABLE)
	
	assert_signal_emitted(board, "board_stabilized", "Сигнал board_stabilized должен быть отправлен")
