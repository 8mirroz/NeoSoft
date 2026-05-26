# /Users/user/3-line/scripts/core_match3/shape_classifier.gd
class_name ShapeClassifier
extends RefCounted

# Классифицирует фигуру по набору ячеек
static func classify_shape(cells: Array[Vector2i], origin: Vector2i = Vector2i(-1, -1)) -> MatchShapeResult:
	var size = cells.size()
	if size < 3:
		return MatchShapeResult.new("LINE_3", cells, origin, origin, Vector2i.ZERO, 1.0)
		
	# Находим bounding box
	var min_x = cells[0].x
	var max_x = cells[0].x
	var min_y = cells[0].y
	var max_y = cells[0].y
	
	for c in cells:
		if c.x < min_x: min_x = c.x
		if c.x > max_x: max_x = c.x
		if c.y < min_y: min_y = c.y
		if c.y > max_y: max_y = c.y
		
	var width = max_x - min_x + 1
	var height = max_y - min_y + 1
	
	# Проверка на линейные фигуры
	var is_collinear_h = height == 1
	var is_collinear_v = width == 1
	
	if is_collinear_h:
		var dir = Vector2i.RIGHT
		if size == 3:
			return MatchShapeResult.new("LINE_3", cells, _get_center(cells, origin), _get_center(cells, origin), dir, 1.0)
		elif size == 4:
			return MatchShapeResult.new("LINE_4", cells, _get_center(cells, origin), _get_center(cells, origin), dir, 2.0)
		elif size >= 5:
			return MatchShapeResult.new("LINE_5", cells, _get_center(cells, origin), _get_center(cells, origin), dir, 4.0)
			
	if is_collinear_v:
		var dir = Vector2i.DOWN
		if size == 3:
			return MatchShapeResult.new("LINE_3", cells, _get_center(cells, origin), _get_center(cells, origin), dir, 1.0)
		elif size == 4:
			return MatchShapeResult.new("LINE_4", cells, _get_center(cells, origin), _get_center(cells, origin), dir, 2.0)
		elif size >= 5:
			return MatchShapeResult.new("LINE_5", cells, _get_center(cells, origin), _get_center(cells, origin), dir, 4.0)
			
	# Проверка на SQUARE_2X2
	if size == 4 and width == 2 and height == 2:
		return MatchShapeResult.new("SQUARE_2X2", cells, _get_center(cells, origin), _get_center(cells, origin), Vector2i.ZERO, 2.5)
		
	# Проверка на RECTANGLE_2X3 / 3x2 (Field Sphere)
	if size == 6 and ((width == 2 and height == 3) or (width == 3 and height == 2)):
		return MatchShapeResult.new("RECTANGLE_2X3", cells, _get_center(cells, origin), _get_center(cells, origin), Vector2i.ZERO, 5.0)
		
	# Ищем точку пересечения для пересекающихся фигур
	var intersection = _find_intersection(cells)
	if intersection != Vector2i(-1, -1):
		# Это L_SHAPE (l_5), T_SHAPE (t_5) или CROSS (cross_5)
		var center = intersection
		var origin_cell = origin if origin in cells else center
		
		if size == 5:
			# Классифицируем по расположению точки пересечения относительно краев
			var is_h_end = false
			var is_v_end = false
			
			var h_line = []
			var v_line = []
			for c in cells:
				if c.y == center.y: h_line.append(c)
				if c.x == center.x: v_line.append(c)
				
			h_line.sort()
			v_line.sort()
			
			if h_line.size() > 0 and (center == h_line[0] or center == h_line[-1]):
				is_h_end = true
			if v_line.size() > 0 and (center == v_line[0] or center == v_line[-1]):
				is_v_end = true
				
			if is_h_end and is_v_end:
				return MatchShapeResult.new("L_SHAPE", cells, origin_cell, center, Vector2i.ZERO, 3.0)
			elif not is_h_end and not is_v_end:
				return MatchShapeResult.new("CROSS", cells, origin_cell, center, Vector2i.ZERO, 4.0)
			else:
				return MatchShapeResult.new("T_SHAPE", cells, origin_cell, center, Vector2i.ZERO, 3.5)
				
		if size == 6:
			# Hook-6 (Gravity Sphere)
			return MatchShapeResult.new("HOOK_6", cells, origin_cell, center, Vector2i.ZERO, 4.5)
			
	# Zigzag-6 (Lightning Sphere)
	if size == 6 and width >= 3 and height >= 2:
		return MatchShapeResult.new("ZIGZAG_6", cells, _get_center(cells, origin), _get_center(cells, origin), Vector2i.ZERO, 4.8)
		
	# Длинные сложные фигуры
	if size >= 9:
		return MatchShapeResult.new("RARE_9_PLUS", cells, _get_center(cells, origin), _get_center(cells, origin), Vector2i.ZERO, 7.0)
	elif size >= 7:
		return MatchShapeResult.new("COMPLEX_7_PLUS", cells, _get_center(cells, origin), _get_center(cells, origin), Vector2i.ZERO, 6.0)
		
	# Default fallback
	return MatchShapeResult.new("LINE_3", cells, _get_center(cells, origin), _get_center(cells, origin), Vector2i.ZERO, 1.0)

# Вспомогательный метод нахождения геометрического центра
static func _get_center(cells: Array[Vector2i], origin: Vector2i) -> Vector2i:
	if origin in cells:
		return origin
	var sum_x = 0
	var sum_y = 0
	for c in cells:
		sum_x += c.x
		sum_y += c.y
	var avg_cell = Vector2i(round(float(sum_x) / cells.size()), round(float(sum_y) / cells.size()))
	
	# Находим ближайшую реальную ячейку к среднему
	var closest = cells[0]
	var min_dist = 9999.0
	for c in cells:
		var dist = avg_cell.distance_to(c)
		if dist < min_dist:
			min_dist = dist
			closest = c
	return closest

# Вспомогательный метод нахождения точки пересечения
static func _find_intersection(cells: Array[Vector2i]) -> Vector2i:
	var x_counts = {}
	var y_counts = {}
	for c in cells:
		x_counts[c.x] = x_counts.get(c.x, 0) + 1
		y_counts[c.y] = y_counts.get(c.y, 0) + 1
		
	# Точка пересечения — это ячейка, у которой и по X, и по Y есть перпендикулярные ветки
	for c in cells:
		if x_counts.get(c.x, 0) >= 3 and y_counts.get(c.y, 0) >= 3:
			return c
	return Vector2i(-1, -1)
