extends RefCounted
class_name MatchSystem

func find_matches(board: BoardModel) -> Array[Dictionary]:
	var horizontal_matches := _find_linear_matches(board, Vector2i.RIGHT)
	var vertical_matches := _find_linear_matches(board, Vector2i.DOWN)

	var merged_matches: Array[Dictionary] = []
	var h_merged := {}
	var v_merged := {}

	# Find intersections (T/L shapes)
	for h_idx in range(horizontal_matches.size()):
		var h_match: Dictionary = horizontal_matches[h_idx]
		var h_cells: Array = h_match["cells"]

		for v_idx in range(vertical_matches.size()):
			if v_merged.has(v_idx):
				continue

			var v_match: Dictionary = vertical_matches[v_idx]
			var v_cells: Array = v_match["cells"]

			if h_match["piece_id"] != v_match["piece_id"]:
				continue

			var intersection: Vector2i = Vector2i(-1, -1)
			for hc in h_cells:
				if hc in v_cells:
					intersection = hc
					break

			if intersection != Vector2i(-1, -1):
				h_merged[h_idx] = true
				v_merged[v_idx] = true

				var combined_cells: Array[Vector2i] = []
				for c in h_cells:
					if not c in combined_cells:
						combined_cells.append(c)
				for c in v_cells:
					if not c in combined_cells:
						combined_cells.append(c)

				merged_matches.append({
					"piece_id": h_match["piece_id"],
					"cells": combined_cells,
					"length": combined_cells.size(),
					"axis": "intersection",
					"intersection_cell": intersection,
					"horizontal_length": h_cells.size(),
					"vertical_length": v_cells.size(),
				})
				break

	# Add remaining unmerged horizontal matches
	for h_idx in range(horizontal_matches.size()):
		if not h_merged.has(h_idx):
			merged_matches.append(horizontal_matches[h_idx])

	# Add remaining unmerged vertical matches
	for v_idx in range(vertical_matches.size()):
		if not v_merged.has(v_idx):
			merged_matches.append(vertical_matches[v_idx])

	return merged_matches

func _find_linear_matches(board: BoardModel, step: Vector2i) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var visited: Dictionary = {}

	for y in range(board.height):
		for x in range(board.width):
			var origin := Vector2i(x, y)
			if visited.has(origin):
				continue

			var piece := board.get_piece(origin)
			if piece < 0:
				continue

			var cells: Array[Vector2i] = [origin]
			var cursor := origin + step
			while board.is_in_bounds(cursor) and board.get_piece(cursor) == piece:
				cells.append(cursor)
				cursor += step

			if cells.size() >= 3:
				for cell in cells:
					visited[cell] = true
				matches.append({
					"piece_id": piece,
					"cells": cells,
					"length": cells.size(),
					"axis": "horizontal" if step == Vector2i.RIGHT else "vertical",
				})

	return matches


