extends RefCounted
class_name BoardGemPool

var _board_view: Control # Dynamic BoardView

func setup(board_view: Control) -> void:
	_board_view = board_view

func update_gems_visibility() -> void:
	var model: RefCounted = _board_view.get("board_model")
	var gems: Dictionary = _board_view.get("_gems")
	
	if model == null:
		# Free all gems if board model is cleared
		for cell in gems.keys():
			var g: Node = gems[cell]
			if is_instance_valid(g):
				g.queue_free()
		gems.clear()
		return

	var metrics: Dictionary = _board_view.call("_get_board_metrics")
	var cell_size: float = metrics["cell_size"]
	var board_rect: Rect2 = metrics["board_rect"]
	
	# Read from visual snapshot instead of board_model to prevent color flashing
	var pending_removals: Dictionary = _board_view.get("_pending_removals")
	
	var active_cells := {}

	for y in range(model.call("get_height") if model.has_method("get_height") else model.get("height")):
		for x in range(model.call("get_width") if model.has_method("get_width") else model.get("width")):
			var cell := Vector2i(x, y)
			# Use visual snapshot instead of board_model — this is the core fix
			var piece_id: int = _board_view.call("get_visual_piece", cell)
			
			if piece_id >= 0:
				active_cells[cell] = true
				var gem: GemView
				if gems.has(cell) and is_instance_valid(gems[cell]):
					gem = gems[cell]
				else:
					gem = GemView.new()
					gem.name = "Gem_%d_%d" % [cell.x, cell.y]
					_board_view.add_child(gem)
					gems[cell] = gem
				
				gem.size = cell_size
				gem.set_piece(piece_id)
				gem.set_sphere_type(SphereFactory.get_sphere_type_for_piece(piece_id))
				
				var selected_cell: Vector2i = _board_view.get("selected_cell")
				gem.set_selected(cell == selected_cell)
				
				# Base scale is squash & stretch spring
				var gem_scales: Dictionary = _board_view.get("gem_scales")
				var scale_factor: Vector2 = gem_scales.get(cell, Vector2.ONE)
				
				# Tactical hover bulge effect (Rule-002 premium UX)
				var hovered_cell: Vector2i = _board_view.get("hovered_cell")
				var is_dragging: bool = _board_view.get("is_dragging")
				if cell == hovered_cell and not is_dragging:
					scale_factor *= 1.08
				
				gem.custom_scale = scale_factor
				
				var gem_offsets: Dictionary = _board_view.get("gem_offsets")
				var offset: Vector2 = gem_offsets.get(cell, Vector2.ZERO)
				
				var gem_alphas: Dictionary = _board_view.get("gem_alphas")
				var alpha: float = gem_alphas.get(cell, 1.0)
				
				# Hide gems that are pending removal (dissolve animation handles their visual)
				if pending_removals.has(cell):
					alpha = 0.0
				
				var cell_rect := Rect2(
					board_rect.position + Vector2(cell.x * cell_size, cell.y * cell_size),
					Vector2(cell_size, cell_size)
				)
				gem.position = cell_rect.get_center() + offset
				gem.modulate.a = alpha
				gem.visible = true

	# Cleanup gems for empty/deleted cells
	for cell in gems.keys():
		if not active_cells.has(cell):
			var g: Node = gems[cell]
			if is_instance_valid(g):
				g.queue_free()
			gems.erase(cell)

func clear_gems() -> void:
	var gems: Dictionary = _board_view.get("_gems")
	for cell in gems.keys():
		var g: Node = gems[cell]
		if is_instance_valid(g):
			g.queue_free()
	gems.clear()
