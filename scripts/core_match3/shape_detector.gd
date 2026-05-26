# /Users/user/3-line/scripts/core_match3/shape_detector.gd
extends RefCounted
class_name ShapeDetector

## Сканирует игровое поле для поиска геометрических совпадений 11 продвинутых форм.

func detect_shapes(board: BoardLogic, origin: Vector2i = Vector2i(-1, -1)) -> Array[MatchShapeResult]:
	var results: Array[MatchShapeResult] = []
	
	# Находим базовые горизонтальные и вертикальные линии
	var h_lines = _find_linear_matches(board, Vector2i.RIGHT)
	var v_lines = _find_linear_matches(board, Vector2i.DOWN)
	
	var all_lines: Array[Dictionary] = []
	all_lines.append_array(h_lines)
	all_lines.append_array(v_lines)
	
	var components: Array[Array] = []
	var component_colors: Array[String] = []
	
	for line in all_lines:
		var line_cells: Array[Vector2i] = line["cells"]
		var color: String = line["color"]
		
		var intersecting_indices: Array[int] = []
		for i in range(components.size()):
			if component_colors[i] != color:
				continue
			var intersects = false
			for c in line_cells:
				if c in components[i]:
					intersects = true
					break
			if intersects:
				intersecting_indices.append(i)
				
		if intersecting_indices.size() == 0:
			var new_comp: Array[Vector2i] = []
			new_comp.assign(line_cells)
			components.append(new_comp)
			component_colors.append(color)
		else:
			var target_idx = intersecting_indices[0]
			for c in line_cells:
				if not c in components[target_idx]:
					components[target_idx].append(c)
					
			for k in range(intersecting_indices.size() - 1, 0, -1):
				var merge_idx = intersecting_indices[k]
				for c in components[merge_idx]:
					if not c in components[target_idx]:
						components[target_idx].append(c)
				components.remove_at(merge_idx)
				component_colors.remove_at(merge_idx)
				
	for i in range(components.size()):
		var comp_cells: Array[Vector2i] = []
		comp_cells.assign(components[i])
		var shape_res = ShapeClassifier.classify_shape(comp_cells, origin)
		results.append(shape_res)
		
	# Поиск квадратов 2x2
	var squares = _find_squares_2x2(board)
	for sq_cells_untyped in squares:
		var sq_cells: Array[Vector2i] = []
		sq_cells.assign(sq_cells_untyped)
		
		var already_matched = false
		for res in results:
			if res.shape_type != "LINE_3" and res.shape_type != "LINE_4" and res.shape_type != "LINE_5":
				var all_in = true
				for c in sq_cells:
					if not c in res.cells:
						all_in = false
						break
				if all_in:
					already_matched = true
					break
					
		if not already_matched:
			var center = sq_cells[0]
			if origin in sq_cells:
				center = origin
			var origin_cell = origin if origin in sq_cells else center
			# Создаем MatchShapeResult для квадрата
			var match_res = ShapeClassifier.classify_shape(sq_cells, origin_cell)
			results.append(match_res)
			
	results.sort_custom(func(a, b): return a.weight > b.weight)
	return results

func _find_linear_matches(board: BoardLogic, step: Vector2i) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var visited: Dictionary = {}
	
	for y in range(board.height):
		for x in range(board.width):
			var origin = Vector2i(x, y)
			if visited.has(origin):
				continue
				
			var color = board.get_gem(origin)
			if color == "":
				continue
				
			var cells: Array[Vector2i] = [origin]
			var cursor = origin + step
			while board.is_in_bounds(cursor) and board.get_gem(cursor) == color:
				cells.append(cursor)
				cursor += step
				
			if cells.size() >= 3:
				for cell in cells:
					visited[cell] = true
				matches.append({
					"color": color,
					"cells": cells,
				})
				
	return matches

func _find_squares_2x2(board: BoardLogic) -> Array[Array]:
	var squares: Array[Array] = []
	var used_in_squares = {}
	
	for y in range(board.height - 1):
		for x in range(board.width - 1):
			var p00 = Vector2i(x, y)
			var p10 = Vector2i(x + 1, y)
			var p01 = Vector2i(x, y + 1)
			var p11 = Vector2i(x + 1, y + 1)
			
			var gem = board.get_gem(p00)
			if gem == "":
				continue
				
			if board.get_gem(p10) == gem and board.get_gem(p01) == gem and board.get_gem(p11) == gem:
				if not used_in_squares.has(p00) or not used_in_squares.has(p10) or not used_in_squares.has(p01) or not used_in_squares.has(p11):
					squares.append([p00, p10, p01, p11])
					used_in_squares[p00] = true
					used_in_squares[p10] = true
					used_in_squares[p01] = true
					used_in_squares[p11] = true
					
	return squares
