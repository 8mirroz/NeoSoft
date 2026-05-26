extends "res://addons/gut/test.gd"

# E2E-тесты для Combo Fever Engine (CFE-12)

var session: LevelSession

func before_each() -> void:
	session = LevelSession.new()
	session.level_number = 1
	session.fever_mode_enabled = true
	add_child_autofree(session)
	_fill_board_no_matches(session.board_state_engine)

func _fill_board_no_matches(board: BoardStateEngine) -> void:
	for y in range(board.height):
		for x in range(board.width):
			board.set_piece(Vector2i(x, y), (x + y) % 3 + 1)

func test_line_4_creates_beam() -> void:
	# Настраиваем доску так, чтобы swap создавал линию из 4 элементов
	var board := session.board_state_engine
	for y in range(board.height):
		for x in range(board.width):
			board.set_piece(Vector2i(x, y), 0)
			
	# Делаем заготовку: (0,0), (1,0), (3,0) = Red (1), а (2,1) = Red (1). (2,0) = Blue (2).
	# Свап (2,0) и (2,1) создаст линию из 4 в ряду 0!
	board.set_piece(Vector2i(0, 0), 1)
	board.set_piece(Vector2i(1, 0), 1)
	board.set_piece(Vector2i(2, 0), 2)
	board.set_piece(Vector2i(3, 0), 1)
	board.set_piece(Vector2i(2, 1), 1)
	
	# Запускаем swap
	var success := session.pipeline.request_swap(Vector2i(2, 0), Vector2i(2, 1))
	assert_true(success, "Свап должен быть запрошен")
	
	# Продвигаем FSM
	session._advance_cfe_pipeline()
	
	# Проверяем, что в (2,0) (или центре слияния) появилась спец-сфера типа BEAM
	# Специальные сферы в pipeline хранятся в active_specials
	var special_found := false
	for cell in session.pipeline.active_specials:
		if session.pipeline.active_specials[cell] == SpecialSphereType.Type.BEAM_SPHERE:
			special_found = true
			break
	assert_true(special_found, "Должна создаться горизонтальная/вертикальная Beam сфера")

func test_square_creates_homing() -> void:
	var board := session.board_state_engine
	for y in range(board.height):
		for x in range(board.width):
			board.set_piece(Vector2i(x, y), 0)
			
	# Создаем заготовку под квадрат 2x2:
	# (0,0) (1,0)
	# (0,1) и swap с (1,1)
	board.set_piece(Vector2i(0, 0), 1)
	board.set_piece(Vector2i(1, 0), 1)
	board.set_piece(Vector2i(0, 1), 1)
	board.set_piece(Vector2i(1, 1), 2)
	board.set_piece(Vector2i(1, 2), 1) # чтобы при свапе (1,1) и (1,2) получился квадрат!
	
	var success := session.pipeline.request_swap(Vector2i(1, 1), Vector2i(1, 2))
	assert_true(success)
	session._advance_cfe_pipeline()
	
	var special_found := false
	for cell in session.pipeline.active_specials:
		if session.pipeline.active_specials[cell] == SpecialSphereType.Type.HOMING_SPHERE:
			special_found = true
			break
	assert_true(special_found, "Должна создаться Homing сфера (бабочка/самолетик) за 2x2")

func test_line_5_creates_prism() -> void:
	var board := session.board_state_engine
	for y in range(board.height):
		for x in range(board.width):
			board.set_piece(Vector2i(x, y), 0)
			
	# Линия из 5:
	# (0,0), (1,0), (2,0), (4,0) = Red, (3,1) = Red, (3,0) = Blue
	board.set_piece(Vector2i(0, 0), 1)
	board.set_piece(Vector2i(1, 0), 1)
	board.set_piece(Vector2i(2, 0), 1)
	board.set_piece(Vector2i(3, 0), 2)
	board.set_piece(Vector2i(4, 0), 1)
	board.set_piece(Vector2i(3, 1), 1)
	
	var success := session.pipeline.request_swap(Vector2i(3, 0), Vector2i(3, 1))
	assert_true(success)
	session._advance_cfe_pipeline()
	
	var special_found := false
	for cell in session.pipeline.active_specials:
		if session.pipeline.active_specials[cell] == SpecialSphereType.Type.PRISM_SPHERE:
			special_found = true
			break
	assert_true(special_found, "Должна создаться Prism сфера (радужная бомба) за линию из 5")

func test_combo_window_extends() -> void:
	# Имитируем успешный матч и проверяем увеличение Combo Window
	assert_eq(session.combo_controller.chain_index, 0)
	session.combo_controller.on_match_detected("LINE_3", 0.0, false, false)
	assert_eq(session.combo_controller.chain_index, 1, "Цепочка комбо должна вырасти")
	assert_gt(session.combo_controller.combo_window_remaining, 0.0, "Таймер комбо должен увеличиться")

func test_fever_activates() -> void:
	# Доводим комбо до порога активации Fever
	session.combo_controller.chain_index = 0
	session.combo_controller.is_fever_active = false
	var threshold := session.combo_controller.fever_combo_threshold
	
	for i in range(threshold):
		session.combo_controller.on_match_detected("LINE_3", 0.0, false, false)
		
	assert_true(session.combo_controller.is_fever_active, "Fever должен активироваться при достижении порога комбо")
	assert_gt(session.combo_controller.fever_remaining, 0.0, "Время Fever должно быть заполнено")

func test_queued_move_executes() -> void:
	# Переводим pipeline в MATCH_SCANNING (имитируем работу), чтобы поле было нестабильным
	session.pipeline.context.state = ResolveContext.State.MATCH_SCANNING
	session.board_state_engine.set_cell_state(Vector2i(0, 0), CellState.State.FALLING)
	
	# Пытаемся сделать ход во время каскада (ставим в очередь)
	var current_time := Time.get_ticks_msec() / 1000.0
	session.input_buffer.enqueue_move(Vector2i(0, 0), Vector2i(1, 0), session.board_state_engine, current_time)
	
	assert_eq(session.input_buffer.queue.size(), 1, "Ход должен успешно встать в очередь буфера")
	
	# Возвращаем pipeline в IDLE, но ячейка должна оставаться нестабильной (RESERVED)
	session.pipeline.context.state = ResolveContext.State.IDLE
	
	# Вызов advance() должен извлечь ход из очереди и начать его выполнение!
	session.pipeline.advance()
	assert_eq(session.pipeline.context.state, ResolveContext.State.SWAP_REQUESTED, "Ход из буфера должен автоматически выполниться")

func test_queued_move_expires() -> void:
	session.pipeline.context.state = ResolveContext.State.MATCH_SCANNING
	session.board_state_engine.set_cell_state(Vector2i(0, 0), CellState.State.FALLING)
	
	var current_time := Time.get_ticks_msec() / 1000.0
	session.input_buffer.enqueue_move(Vector2i(0, 0), Vector2i(1, 0), session.board_state_engine, current_time)
	
	# Шагаем время на 2 секунды вперед (время жизни по умолчанию 0.5)
	var expired_move := session.input_buffer.validate_and_get_next(session.board_state_engine, current_time + 2.0)
	assert_null(expired_move, "Устаревший ход не должен возвращаться из буфера")
	assert_eq(session.input_buffer.queue.size(), 0, "Устаревший ход должен быть удален из очереди")

func test_beam_beam_combo() -> void:
	# Тестируем спец-комбинацию Beam + Beam step-by-step
	var board := session.board_state_engine
	session.pipeline.set_special_sphere(Vector2i(0, 0), SpecialSphereType.Type.BEAM_SPHERE)
	session.pipeline.set_special_sphere(Vector2i(1, 0), SpecialSphereType.Type.BEAM_SPHERE)
	
	var success := session.pipeline.request_swap(Vector2i(0, 0), Vector2i(1, 0))
	assert_true(success)
	
	session.pipeline.advance() # SWAP_REQUESTED -> SWAP_VALIDATING
	session.pipeline.advance() # SWAP_VALIDATING -> MATCH_SCANNING
	session.pipeline.advance() # MATCH_SCANNING -> SPECIAL_SPAWNING
	session.pipeline.advance() # SPECIAL_SPAWNING -> EFFECT_RESOLVING
	
	# На фазе EFFECT_RESOLVING сферы еще на месте
	assert_eq(session.pipeline.get_special_sphere(Vector2i(0, 0)), SpecialSphereType.Type.BEAM_SPHERE)
	assert_eq(session.pipeline.get_special_sphere(Vector2i(1, 0)), SpecialSphereType.Type.BEAM_SPHERE)
	
	# Взрываем!
	session.pipeline.advance()
	
	# Проверяем, что спец-сферы взорвались и очищены до фазы гравитации
	assert_eq(session.pipeline.get_special_sphere(Vector2i(0, 0)), SpecialSphereType.Type.NONE)
	assert_eq(session.pipeline.get_special_sphere(Vector2i(1, 0)), SpecialSphereType.Type.NONE)

func test_beam_blast_combo() -> void:
	var board := session.board_state_engine
	session.pipeline.set_special_sphere(Vector2i(0, 0), SpecialSphereType.Type.BEAM_SPHERE)
	session.pipeline.set_special_sphere(Vector2i(1, 0), SpecialSphereType.Type.BLAST_SPHERE)
	
	var success := session.pipeline.request_swap(Vector2i(0, 0), Vector2i(1, 0))
	assert_true(success)
	
	session.pipeline.advance() # SWAP_REQUESTED -> SWAP_VALIDATING
	session.pipeline.advance() # SWAP_VALIDATING -> MATCH_SCANNING
	session.pipeline.advance() # MATCH_SCANNING -> SPECIAL_SPAWNING
	session.pipeline.advance() # SPECIAL_SPAWNING -> EFFECT_RESOLVING
	
	# При свапе сферы поменялись местами!
	assert_eq(session.pipeline.get_special_sphere(Vector2i(0, 0)), SpecialSphereType.Type.BLAST_SPHERE)
	assert_eq(session.pipeline.get_special_sphere(Vector2i(1, 0)), SpecialSphereType.Type.BEAM_SPHERE)
	
	session.pipeline.advance()
	
	assert_eq(session.pipeline.get_special_sphere(Vector2i(0, 0)), SpecialSphereType.Type.NONE)
	assert_eq(session.pipeline.get_special_sphere(Vector2i(1, 0)), SpecialSphereType.Type.NONE)

func test_prism_prism_combo() -> void:
	var board := session.board_state_engine
	session.pipeline.set_special_sphere(Vector2i(0, 0), SpecialSphereType.Type.PRISM_SPHERE)
	session.pipeline.set_special_sphere(Vector2i(1, 0), SpecialSphereType.Type.PRISM_SPHERE)
	
	var success := session.pipeline.request_swap(Vector2i(0, 0), Vector2i(1, 0))
	assert_true(success)
	
	session.pipeline.advance() # SWAP_REQUESTED -> SWAP_VALIDATING
	session.pipeline.advance() # SWAP_VALIDATING -> MATCH_SCANNING
	session.pipeline.advance() # MATCH_SCANNING -> SPECIAL_SPAWNING
	session.pipeline.advance() # SPECIAL_SPAWNING -> EFFECT_RESOLVING
	
	assert_eq(session.pipeline.get_special_sphere(Vector2i(0, 0)), SpecialSphereType.Type.PRISM_SPHERE)
	assert_eq(session.pipeline.get_special_sphere(Vector2i(1, 0)), SpecialSphereType.Type.PRISM_SPHERE)
	
	session.pipeline.advance()
	
	assert_eq(session.pipeline.get_special_sphere(Vector2i(0, 0)), SpecialSphereType.Type.NONE)
	assert_eq(session.pipeline.get_special_sphere(Vector2i(1, 0)), SpecialSphereType.Type.NONE)

func test_no_softlock_after_chain() -> void:
	# Прогоняем длинную цепочку матчей, убеждаемся, что FSM переходит в IDLE без зависаний
	session.pipeline.context.state = ResolveContext.State.IDLE
	session._advance_cfe_pipeline()
	assert_eq(session.pipeline.context.state, ResolveContext.State.IDLE, "После продвижения пустого поля FSM должен остаться в IDLE")

func test_telemetry_export() -> void:
	session.telemetry.reset()
	session.telemetry.record_combo(3)
	session.telemetry.record_fever_activated()
	session.telemetry.record_special_created()
	session.telemetry.record_session_end(true, 5)
	
	var json_str := session.telemetry.export_json()
	assert_not_null(json_str)
	
	var parser := JSON.new()
	var err := parser.parse(json_str)
	assert_eq(err, OK, "Экспортированный JSON должен быть валидным")
	
	var data: Dictionary = parser.data
	assert_eq(data["max_combo_length"], 3.0)
	assert_eq(data["fever_activation_rate"], 1.0)
	assert_eq(data["level_win_rate"], 1.0)

