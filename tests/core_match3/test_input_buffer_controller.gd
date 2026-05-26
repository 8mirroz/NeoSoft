extends "res://addons/gut/test.gd"

# Юнит-тесты для InputBufferController

func test_enqueue_on_unstable_cells() -> void:
	var board := BoardStateEngine.new()
	board.configure(4, 4, 1)
	
	# Имитируем падение ячеек
	board.set_cell_state(Vector2i(0, 0), CellState.State.FALLING)
	
	var controller := InputBufferController.new()
	var success := controller.enqueue_move(
		Vector2i(0, 0),
		Vector2i(1, 0),
		board,
		0.0,
		0.5
	)
	
	assert_true(success, "Ход должен успешно добавиться в буфер, так как ячейка нестабильна")
	assert_eq(board.get_cell_state(Vector2i(0, 0)), CellState.State.RESERVED, "Состояние должно измениться на RESERVED")
	assert_eq(board.get_cell_state(Vector2i(1, 0)), CellState.State.RESERVED, "Состояние должно измениться на RESERVED")

func test_expiration() -> void:
	var board := BoardStateEngine.new()
	board.configure(4, 4, 1)
	
	board.set_cell_state(Vector2i(0, 0), CellState.State.FALLING)
	
	var controller := InputBufferController.new()
	controller.enqueue_move(Vector2i(0, 0), Vector2i(1, 0), board, 0.0, 0.5)
	
	# Проверяем очистку по истечении времени
	controller.clear_expired(board, 0.6)
	
	assert_eq(controller.queue.size(), 0, "Очередь должна быть пустой")
	assert_eq(board.get_cell_state(Vector2i(0, 0)), CellState.State.STABLE, "Ячейка должна вернуться в STABLE")
	assert_eq(board.get_cell_state(Vector2i(1, 0)), CellState.State.STABLE, "Ячейка должна вернуться в STABLE")

func test_validation_success() -> void:
	var board := BoardStateEngine.new()
	board.configure(4, 4, 1) # Фишки заполнены единицами (1)
	
	board.set_cell_state(Vector2i(0, 0), CellState.State.FALLING)
	
	var controller := InputBufferController.new()
	controller.enqueue_move(Vector2i(0, 0), Vector2i(1, 0), board, 0.0, 0.5)
	
	# Пробуем валидировать
	var next_move := controller.validate_and_get_next(board, 0.1)
	
	assert_not_null(next_move, "Ход должен быть валидным")
	assert_eq(board.get_cell_state(Vector2i(0, 0)), CellState.State.RESOLVING, "Ячейка должна перейти в RESOLVING")
	assert_eq(board.get_cell_state(Vector2i(1, 0)), CellState.State.RESOLVING, "Ячейка должна перейти в RESOLVING")

func test_validation_gem_desync() -> void:
	var board := BoardStateEngine.new()
	board.configure(4, 4, 1)
	
	board.set_cell_state(Vector2i(0, 0), CellState.State.FALLING)
	
	var controller := InputBufferController.new()
	controller.enqueue_move(Vector2i(0, 0), Vector2i(1, 0), board, 0.0, 0.5)
	
	# Изменяем тип фишки в ячейке, имитируя приземление другой фишки
	board.set_piece(Vector2i(0, 0), 99)
	
	var next_move := controller.validate_and_get_next(board, 0.1)
	
	assert_null(next_move, "Ход должен быть отменен из-за десинхронизации фишек")
	assert_eq(board.get_cell_state(Vector2i(0, 0)), CellState.State.STABLE, "Ячейка должна сброситься в STABLE")

func test_queue_limit_and_multiple_enqueues() -> void:
	var board := BoardStateEngine.new()
	board.configure(6, 6, 1)
	
	# Имитируем падение во всем поле
	for x in range(6):
		for y in range(6):
			board.set_cell_state(Vector2i(x, y), CellState.State.FALLING)
			
	var controller := InputBufferController.new()
	
	# Добавляем 1-й ход
	var s1 := controller.enqueue_move(Vector2i(0, 0), Vector2i(1, 0), board, 0.0, 0.5)
	assert_true(s1, "Первый ход должен добавиться")
	assert_eq(controller.queue.size(), 1)
	
	# Попытка добавить ход на те же ячейки (RESERVED) — должна быть отклонена
	var s_dup := controller.enqueue_move(Vector2i(0, 0), Vector2i(1, 0), board, 0.0, 0.5)
	assert_false(s_dup, "Ход на уже резервированные ячейки должен быть отклонен")
	
	# Добавляем 2-й ход в другой части поля
	var s2 := controller.enqueue_move(Vector2i(2, 2), Vector2i(3, 2), board, 0.0, 0.5)
	assert_true(s2, "Второй ход должен добавиться")
	assert_eq(controller.queue.size(), 2)
	
	# Добавляем 3-й ход
	var s3 := controller.enqueue_move(Vector2i(4, 4), Vector2i(5, 4), board, 0.0, 0.5)
	assert_true(s3, "Третий ход должен добавиться")
	assert_eq(controller.queue.size(), 3)
	
	# Попытка добавить 4-й ход — должна быть отклонена (лимит = 3)
	var s4 := controller.enqueue_move(Vector2i(0, 4), Vector2i(1, 4), board, 0.0, 0.5)
	assert_false(s4, "Четвертый ход должен быть отклонен (лимит 3)")
	assert_eq(controller.queue.size(), 3)

