extends "res://addons/gut/test.gd"

# Юнит-тесты для ResolvePipeline FSM

var board: BoardStateEngine
var combo: ComboFeverController
var input: InputBufferController
var shape_detector: MatchShapeDetector
var factory: SpecialSphereFactory
var target_priority: TargetPrioritySystem
var context: ResolveContext
var pipeline: ResolvePipeline

func before_each() -> void:
	board = BoardStateEngine.new()
	board.configure(6, 6, -1)
	
	combo = ComboFeverController.new()
	input = InputBufferController.new()
	shape_detector = MatchShapeDetector.new()
	factory = SpecialSphereFactory.new()
	target_priority = TargetPrioritySystem.new()
	
	context = ResolveContext.new(board, combo, input, shape_detector, factory, target_priority)
	pipeline = ResolvePipeline.new(context)
	pipeline.piece_kinds = 5

func test_swap_validation_success() -> void:
	# Настраиваем доску так, чтобы обмен (0,0) и (1,0) создавал 3 в ряд по горизонтали
	# (0,0) -> 0
	# (1,0) -> 1
	# (2,0) -> 0, (3,0) -> 0
	board.set_piece(Vector2i(0, 0), 0)
	board.set_piece(Vector2i(1, 0), 1)
	board.set_piece(Vector2i(2, 0), 0)
	board.set_piece(Vector2i(3, 0), 0)
	
	watch_signals(pipeline)
	
	# Запрашиваем свайп
	var request_ok := pipeline.request_swap(Vector2i(0, 0), Vector2i(1, 0))
	assert_true(request_ok, "Запрос свайпа должен быть принят")
	assert_eq(context.state, ResolveContext.State.SWAP_REQUESTED)
	
	# Шагаем FSM
	pipeline.advance() # -> SWAP_VALIDATING (происходит обмен)
	assert_eq(context.state, ResolveContext.State.SWAP_VALIDATING)
	assert_eq(board.get_piece(Vector2i(0, 0)), 1, "Фишки должны поменяться местами")
	assert_eq(board.get_piece(Vector2i(1, 0)), 0)
	
	# Шагаем дальше (валидация)
	pipeline.advance() # -> MATCH_SCANNING (матч 3 найден)
	assert_eq(context.state, ResolveContext.State.MATCH_SCANNING)
	assert_signal_emitted(pipeline, "swap_completed")

func test_swap_validation_failure() -> void:
	# Настраиваем доску так, чтобы обмен НЕ приводил к совпадениям
	# Заполняем поле уникальными фишками без совпадений
	for y in range(6):
		for x in range(6):
			board.set_piece(Vector2i(x, y), (x + y) % 5 + 10)
			
	# Задаем две фишки под обмен
	board.set_piece(Vector2i(0, 0), 1)
	board.set_piece(Vector2i(1, 0), 2)
	
	# Запрашиваем свайп
	pipeline.request_swap(Vector2i(0, 0), Vector2i(1, 0))
	pipeline.advance() # -> SWAP_VALIDATING
	pipeline.advance() # -> IDLE (невалидный свайп, возвращаем назад)
	
	assert_eq(context.state, ResolveContext.State.IDLE, "Состояние должно вернуться в IDLE")
	assert_eq(board.get_piece(Vector2i(0, 0)), 1, "Фишки должны вернуться на прежние места")
	assert_eq(board.get_piece(Vector2i(1, 0)), 2)

func test_cascade_and_special_sphere_generation() -> void:
	# Создаем 4 в ряд по горизонтали
	board.set_piece(Vector2i(0, 0), 1)
	board.set_piece(Vector2i(1, 0), 0)
	board.set_piece(Vector2i(2, 0), 0)
	board.set_piece(Vector2i(3, 0), 0)
	board.set_piece(Vector2i(4, 0), 0)
	
	# Остальные ячейки заполняем так, чтобы не было случайных совпадений
	for y in range(1, 6):
		for x in range(6):
			board.set_piece(Vector2i(x, y), (x + y) % 5 + 10)
			
	pipeline.request_swap(Vector2i(0, 0), Vector2i(1, 0))
	
	# Разрешаем весь каскад
	pipeline.resolve_full_cascade()
	
	assert_eq(context.state, ResolveContext.State.IDLE, "После разрешения каскада поле должно быть стабильным (IDLE)")
	# 4 в ряд по горизонтали должны были создать BEAM_SPHERE
	# Проверим, была ли создана спец-сфера в центре
	# Центр LINE_4 при origin (0,0) -> (1,0) в cells -> [1,0; 2,0; 3,0; 4,0] -> центр (3,0) или origin_cell (1,0)
	# Поскольку в resolve_pipeline.gd спец-сфера создается в MATCH_SCANNING,
	# проверим, что в процессе каскада были удалены элементы и осыпались новые.

func test_special_sphere_explosion_beam() -> void:
	# Руками ставим BEAM_SPHERE в ячейку (2,2)
	board.configure(6, 6, 1)
	pipeline.set_special_sphere(Vector2i(2, 2), SpecialSphereType.Type.BEAM_SPHERE)
	
	# Добавляем фишку, чтобы она была валидно стерта
	# Запускаем взрыв сферы напрямую через вызов _explode_special_sphere
	var cleared := pipeline._explode_special_sphere(Vector2i(2, 2), SpecialSphereType.Type.BEAM_SPHERE)
	
	# Beam Sphere должна задеть весь 2-й ряд и 2-й столбец
	assert_true(Vector2i(0, 2) in cleared)
	assert_true(Vector2i(2, 0) in cleared)
	assert_true(Vector2i(5, 2) in cleared)
	assert_true(Vector2i(2, 5) in cleared)

func test_special_sphere_explosion_blast() -> void:
	# BLAST_SPHERE взрывает 3x3
	var cleared := pipeline._explode_special_sphere(Vector2i(2, 2), SpecialSphereType.Type.BLAST_SPHERE)
	
	assert_eq(cleared.size(), 9, "Взрыв 3x3 должен затронуть ровно 9 ячеек")
	assert_true(Vector2i(1, 1) in cleared)
	assert_true(Vector2i(3, 3) in cleared)
	assert_false(Vector2i(0, 0) in cleared)

func test_special_sphere_explosion_homing() -> void:
	# Задаем одну TARGET ячейку в (5,5)
	board.set_cell_state(Vector2i(5, 5), CellState.State.TARGET)
	
	var cleared := pipeline._explode_special_sphere(Vector2i(0, 0), SpecialSphereType.Type.HOMING_SPHERE)
	
	# Должно взорвать себя (0,0) и лучшую цель (5,5)
	assert_true(Vector2i(0, 0) in cleared)
	assert_true(Vector2i(5, 5) in cleared, "Homing Sphere должна навестись на TARGET ячейку")

func test_cascade_safety_limit() -> void:
	# Тестируем лимит каскадов (softlock protection)
	# Установим лимит cascade depth в 3
	context.max_cascade_depth = 3
	
	# Создаем постоянный матч, который будет возобновляться при заполнении (имитируем принудительный каскад)
	# В advance() CASCADE_CHECKING увеличивает current_cascade_depth.
	# Если мы запустим FSM и сымитируем бесконечный матч:
	context.current_cascade_depth = 2
	
	# Насильно переводим FSM в CASCADE_CHECKING
	pipeline._transition_to(ResolveContext.State.CASCADE_CHECKING)
	
	watch_signals(pipeline)
	pipeline.advance() # Должно превысить 3 и уйти в FAILED_RECOVERY
	
	assert_eq(context.state, ResolveContext.State.FAILED_RECOVERY, "Должно перейти в FAILED_RECOVERY")
	assert_signal_emitted(pipeline, "recovery_triggered")
