extends "res://addons/gut/test.gd"

# Юнит-тесты для ShapeDetector

func test_line_3() -> void:
	var board := BoardLogic.new()
	board.configure(5, 5, -1)
	
	# Создаем горизонтальный Line-3
	board.set_piece(Vector2i(0, 0), 1)
	board.set_piece(Vector2i(1, 0), 1)
	board.set_piece(Vector2i(2, 0), 1)
	
	var detector := ShapeDetector.new()
	var results := detector.detect_shapes(board)
	
	assert_eq(results.size(), 1, "Должна быть найдена одна фигура")
	assert_eq(results[0].shape_type, "LINE_3", "Тип фигуры должен быть LINE_3")
	assert_eq(results[0].weight, 1.0, "Вес должен быть 1.0")

func test_line_4() -> void:
	var board := BoardLogic.new()
	board.configure(5, 5, -1)
	
	# Создаем вертикальный Line-4
	board.set_piece(Vector2i(0, 0), 2)
	board.set_piece(Vector2i(0, 1), 2)
	board.set_piece(Vector2i(0, 2), 2)
	board.set_piece(Vector2i(0, 3), 2)
	
	var detector := ShapeDetector.new()
	var results := detector.detect_shapes(board)
	
	assert_eq(results.size(), 1)
	assert_eq(results[0].shape_type, "LINE_4")
	assert_eq(results[0].weight, 2.0)

func test_square_2x2() -> void:
	var board := BoardLogic.new()
	board.configure(5, 5, -1)
	
	# Создаем квадрат 2x2
	board.set_piece(Vector2i(1, 1), 3)
	board.set_piece(Vector2i(2, 1), 3)
	board.set_piece(Vector2i(1, 2), 3)
	board.set_piece(Vector2i(2, 2), 3)
	
	var detector := ShapeDetector.new()
	var results := detector.detect_shapes(board)
	
	assert_eq(results.size(), 1)
	assert_eq(results[0].shape_type, "SQUARE_2X2")
	assert_eq(results[0].weight, 2.5)

func test_l_shape() -> void:
	var board := BoardLogic.new()
	board.configure(5, 5, -1)
	
	# Создаем L-shape из 5 сфер (пересечение на краях)
	# Горизонтальная линия: (0,0), (1,0), (2,0)
	board.set_piece(Vector2i(0, 0), 4)
	board.set_piece(Vector2i(1, 0), 4)
	board.set_piece(Vector2i(2, 0), 4)
	# Вертикальная линия: (0,0), (0,1), (0,2)
	board.set_piece(Vector2i(0, 1), 4)
	board.set_piece(Vector2i(0, 2), 4)
	
	var detector := ShapeDetector.new()
	var results := detector.detect_shapes(board)
	
	assert_eq(results.size(), 1)
	assert_eq(results[0].shape_type, "L_SHAPE")
	assert_eq(results[0].weight, 3.0)
	assert_eq(results[0].center_cell, Vector2i(0, 0), "Точка пересечения L-shape должна быть центром")

func test_t_shape() -> void:
	var board := BoardLogic.new()
	board.configure(5, 5, -1)
	
	# Создаем T-shape из 5 сфер
	# Горизонтальная: (0,1), (1,1), (2,1)
	board.set_piece(Vector2i(0, 1), 1)
	board.set_piece(Vector2i(1, 1), 1)
	board.set_piece(Vector2i(2, 1), 1)
	# Вертикальная: (1,1), (1,2), (1,3) (пересечение на конце вертикальной, но посередине горизонтальной)
	board.set_piece(Vector2i(1, 2), 1)
	board.set_piece(Vector2i(1, 3), 1)
	
	var detector := ShapeDetector.new()
	var results := detector.detect_shapes(board)
	
	assert_eq(results.size(), 1)
	assert_eq(results[0].shape_type, "T_SHAPE")
	assert_eq(results[0].weight, 3.5)
	assert_eq(results[0].center_cell, Vector2i(1, 1))

func test_cross_shape() -> void:
	var board := BoardLogic.new()
	board.configure(5, 5, -1)
	
	# Создаем Cross (+) пересечение посередине обеих линий
	# Горизонтальная: (1,2), (2,2), (3,2)
	board.set_piece(Vector2i(1, 2), 2)
	board.set_piece(Vector2i(2, 2), 2)
	board.set_piece(Vector2i(3, 2), 2)
	# Вертикальная: (2,1), (2,2), (2,3)
	board.set_piece(Vector2i(2, 1), 2)
	board.set_piece(Vector2i(2, 3), 2)
	
	var detector := ShapeDetector.new()
	var results := detector.detect_shapes(board)
	
	assert_eq(results.size(), 1)
	assert_eq(results[0].shape_type, "CROSS")
	assert_eq(results[0].weight, 4.0)

func test_line_5() -> void:
	var board := BoardLogic.new()
	board.configure(5, 5, -1)
	
	# Создаем Line-5
	board.set_piece(Vector2i(0, 0), 3)
	board.set_piece(Vector2i(1, 0), 3)
	board.set_piece(Vector2i(2, 0), 3)
	board.set_piece(Vector2i(3, 0), 3)
	board.set_piece(Vector2i(4, 0), 3)
	
	var detector := ShapeDetector.new()
	var results := detector.detect_shapes(board)
	
	assert_eq(results.size(), 1)
	assert_eq(results[0].shape_type, "LINE_5")
	assert_eq(results[0].weight, 4.0)
