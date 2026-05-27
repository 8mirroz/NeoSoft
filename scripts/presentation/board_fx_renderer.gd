extends RefCounted
class_name BoardFxRenderer

var _board_view: Control # Dynamic BoardView

func setup(board_view: Control) -> void:
	_board_view = board_view

func draw_board(metrics: Dictionary) -> void:
	var board_model: RefCounted = _board_view.get("board_model")
	if board_model == null:
		return

	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	var gem_radius: float = cell_size * 0.34

	_draw_board_backdrop(board_rect)

	var selected_cell: Vector2i = _board_view.get("selected_cell")
	var hint_cells: Array = _board_view.get("hint_cells")
	var hammer_targeting: bool = _board_view.get("hammer_targeting")

	for y in range(board_model.call("get_height") if board_model.has_method("get_height") else board_model.get("height")):
		for x in range(board_model.call("get_width") if board_model.has_method("get_width") else board_model.get("width")):
			var cell := Vector2i(x, y)
			var cell_rect := Rect2(
				board_rect.position + Vector2(x * cell_size, y * cell_size),
				Vector2(cell_size, cell_size)
			).grow(-4.0)
			_draw_cell_slot(cell_rect, cell, selected_cell, hint_cells, hammer_targeting)

	_draw_collapse_effects(metrics, gem_radius)
	_draw_spawn_effects(metrics, gem_radius)
	_draw_match_pop_effects(metrics, gem_radius)
	
	# Draw premium visual match & line effects
	_draw_connection_threads()
	_draw_laser_lines()
	_draw_shockwaves()
	_draw_homing_projectiles()

func _draw_board_backdrop(board_rect: Rect2) -> void:
	var background_alpha: float = float(_board_view.get("quality_profile").get("background_effect_alpha", 1.0))
	
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = _board_view.call("_tc", "gameplay.surface.board.bg", Color(0.96, 0.96, 1.0, 0.42))
	outer_style.bg_color.a *= background_alpha
	outer_style.border_color = _board_view.call("_tc", "gameplay.surface.board.border", Color(0.88, 0.83, 1.0, 0.75))
	outer_style.border_color.a *= background_alpha
	outer_style.border_width_left = 3
	outer_style.border_width_top = 3
	outer_style.border_width_right = 3
	outer_style.border_width_bottom = 3
	outer_style.corner_radius_top_left = 42
	outer_style.corner_radius_top_right = 42
	outer_style.corner_radius_bottom_right = 42
	outer_style.corner_radius_bottom_left = 42
	outer_style.shadow_color = _board_view.call("_tc", "gameplay.surface.board.shadow.color", Color(0.72, 0.6, 0.95, 0.22))
	outer_style.shadow_color.a *= background_alpha
	outer_style.shadow_size = 26
	_board_view.draw_style_box(outer_style, board_rect)

	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = _board_view.call("_tc", "gameplay.board.inner_bg", Color(0.93, 0.95, 1.0, 0.24))
	inner_style.bg_color.a *= background_alpha
	inner_style.border_color = _board_view.call("_tc", "gameplay.board.inner_border", Color(1.0, 1.0, 1.0, 0.52))
	inner_style.border_color.a *= background_alpha
	inner_style.border_width_left = 2
	inner_style.border_width_top = 2
	inner_style.border_width_right = 2
	inner_style.border_width_bottom = 2
	inner_style.corner_radius_top_left = 34
	inner_style.corner_radius_top_right = 34
	inner_style.corner_radius_bottom_right = 34
	inner_style.corner_radius_bottom_left = 34
	_board_view.draw_style_box(inner_style, board_rect.grow(-10.0))

func _draw_cell_slot(cell_rect: Rect2, cell: Vector2i, selected_cell: Vector2i, hint_cells: Array, hammer_targeting: bool) -> void:
	var style := StyleBoxFlat.new()
	var checker_variant := ((cell.x + cell.y) % 2) == 0
	style.bg_color = _board_view.call("_tc", "gameplay.board.cell_bg_primary", Color(1.0, 1.0, 1.0, 0.12)) if checker_variant else _board_view.call("_tc", "gameplay.board.cell_bg_secondary", Color(0.93, 0.97, 1.0, 0.14))
	style.border_color = _board_view.call("_tc", "gameplay.board.cell_border", Color(1.0, 1.0, 1.0, 0.54))
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	
	style.shadow_color = _board_view.call("_tc", "gameplay.board.cell_shadow", Color(0.82, 0.78, 1.0, 0.14))
	style.shadow_size = 6

	if cell == selected_cell:
		style.bg_color = _board_view.call("_tc", "gameplay.board.cell_selected_bg", Color(0.98, 0.95, 1.0, 0.3))
		style.border_color = _board_view.call("_tc", "gameplay.board.cell_selected_border", Color(1.0, 0.91, 0.7, 0.92))
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.shadow_color = _board_view.call("_tc", "gameplay.board.cell_selected_shadow", Color(1.0, 0.9, 0.6, 0.28))
		style.shadow_size = 10
	elif cell in hint_cells:
		style.bg_color = _board_view.call("_tc", "gameplay.board.cell_hint_bg", Color(0.93, 0.97, 1.0, 0.22))
		style.border_color = _board_view.call("_tc", "gameplay.board.cell_hint_border", Color(0.62, 0.92, 1.0, 0.84))
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.shadow_color = _board_view.call("_tc", "gameplay.board.cell_hint_shadow", Color(0.5, 0.9, 1.0, 0.24))
		style.shadow_size = 10
	elif hammer_targeting:
		style.bg_color = _board_view.call("_tc", "gameplay.board.cell_hammer_bg", Color(1.0, 0.94, 0.96, 0.18))
		style.border_color = _board_view.call("_tc", "gameplay.board.cell_hammer_border", Color(1.0, 0.74, 0.68, 0.52))

	_board_view.draw_style_box(style, cell_rect)

func _draw_match_pop_effects(metrics: Dictionary, gem_radius: float) -> void:
	var match_pop_fx: Array = _board_view.get("match_pop_fx")
	if match_pop_fx.is_empty():
		return

	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	var duration: float = _board_view.get("MATCH_POP_DURATION")
	var expand: float = _board_view.get("MATCH_POP_EXPAND_RATIO")

	for item in match_pop_fx:
		var age: float = float(item.get("age", 0.0))
		var t: float = clamp(age / duration, 0.0, 1.0)
		var fade: float = 1.0 - t
		var growth: float = 1.0 + expand * t
		var cell: Vector2i = item.get("cell", Vector2i.ZERO)
		var center: Vector2 = board_rect.position + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * cell_size
		var piece_id: int = int(item.get("piece_id", 0))
		var palette: Dictionary = _board_view.call("_get_palette", piece_id)
		var accent: Color = palette["accent"]
		var glow: Color = palette["glow"]

		glow.a = 0.32 * fade
		accent.a = 0.66 * fade
		_board_view.draw_circle(center, gem_radius * 1.08 * growth, glow)
		_board_view.draw_arc(center, gem_radius * 0.96 * growth, 0.0, TAU, 30, accent, 2.4, true)

func _draw_collapse_effects(metrics: Dictionary, gem_radius: float) -> void:
	var collapse_fx: Array = _board_view.get("collapse_fx")
	if collapse_fx.is_empty():
		return

	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	var duration: float = _board_view.get("FALL_TRAIL_DURATION")

	for item in collapse_fx:
		var age: float = float(item.get("age", 0.0))
		var t: float = clamp(age / duration, 0.0, 1.0)
		var fade: float = 1.0 - t
		var from_cell: Vector2i = item.get("from", Vector2i.ZERO)
		var to_cell: Vector2i = item.get("to", Vector2i.ZERO)
		var from_center: Vector2 = board_rect.position + (Vector2(from_cell.x, from_cell.y) + Vector2(0.5, 0.5)) * cell_size
		var to_center: Vector2 = board_rect.position + (Vector2(to_cell.x, to_cell.y) + Vector2(0.5, 0.5)) * cell_size
		var piece_id: int = int(item.get("piece_id", 0))
		var trail_color: Color = _board_view.call("_get_palette", piece_id)["glow"]
		trail_color.a = 0.24 * fade
		_board_view.draw_line(from_center, to_center, trail_color, max(2.0, gem_radius * 0.22))
		_board_view.draw_circle(to_center, gem_radius * (0.22 + 0.18 * fade), trail_color)

func _draw_spawn_effects(metrics: Dictionary, gem_radius: float) -> void:
	var spawn_fx: Array = _board_view.get("spawn_fx")
	if spawn_fx.is_empty():
		return

	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	var duration: float = _board_view.get("SPAWN_REVEAL_DURATION")

	for item in spawn_fx:
		var age: float = float(item.get("age", 0.0))
		var t: float = clamp(age / duration, 0.0, 1.0)
		var fade: float = 1.0 - t
		var growth: float = 0.72 + 0.42 * t
		var cell: Vector2i = item.get("cell", Vector2i.ZERO)
		var center: Vector2 = board_rect.position + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * cell_size
		var piece_id: int = int(item.get("piece_id", 0))
		var palette: Dictionary = _board_view.call("_get_palette", piece_id)
		var glow: Color = palette["glow"]
		var accent: Color = palette["accent"]
		glow.a = 0.42 * fade
		accent.a = 0.58 * fade
		_board_view.draw_circle(center, gem_radius * 1.18 * growth, glow)
		_board_view.draw_arc(center, gem_radius * 0.84 * growth, 0.0, TAU, 28, accent, 2.0, true)

func _draw_laser_lines() -> void:
	var active_laser_lines: Array = _board_view.get("active_laser_lines")
	for item in active_laser_lines:
		var age: float = item["age"]
		var t := clampf(age / 0.4, 0.0, 1.0)
		var alpha := 1.0 - t
		var pos: Vector2 = item["pos"]
		var color: Color = item["color"]
		color.a = alpha
		
		var thickness := 32.0 * (1.0 - t * 0.6)
		if item["is_row"]:
			_board_view.draw_line(Vector2(0, pos.y), Vector2(_board_view.size.x, pos.y), Color(color.r, color.g, color.b, 0.28 * alpha), thickness * 1.6)
			_board_view.draw_line(Vector2(0, pos.y), Vector2(_board_view.size.x, pos.y), color, thickness * 0.8)
			_board_view.draw_line(Vector2(0, pos.y), Vector2(_board_view.size.x, pos.y), Color.WHITE, thickness * 0.3)
		else:
			_board_view.draw_line(Vector2(pos.x, 0), Vector2(pos.x, _board_view.size.y), Color(color.r, color.g, color.b, 0.28 * alpha), thickness * 1.6)
			_board_view.draw_line(Vector2(pos.x, 0), Vector2(pos.x, _board_view.size.y), color, thickness * 0.8)
			_board_view.draw_line(Vector2(pos.x, 0), Vector2(pos.x, _board_view.size.y), Color.WHITE, thickness * 0.3)

func _draw_shockwaves() -> void:
	var active_shockwaves: Array = _board_view.get("active_shockwaves")
	for item in active_shockwaves:
		var age: float = item["age"]
		var t := clampf(age / 0.5, 0.0, 1.0)
		var alpha := 1.0 - t
		var center: Vector2 = item["center"]
		var max_radius: float = item["max_radius"]
		var color: Color = item["color"]
		var r := max_radius * (0.15 + 0.85 * t)
		
		_board_view.draw_circle(center, r, Color(color.r, color.g, color.b, 0.16 * alpha))
		_board_view.draw_arc(center, r, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.78 * alpha), 5.0 * alpha)
		_board_view.draw_arc(center, r - 3.0, 0.0, TAU, 36, Color.WHITE, 1.8 * alpha)

func _draw_homing_projectiles() -> void:
	var active_homing_projectiles: Array = _board_view.get("active_homing_projectiles")
	for item in active_homing_projectiles:
		var age: float = item["age"]
		var t := clampf(age / 0.6, 0.0, 1.0)
		var from: Vector2 = item["from"]
		var to: Vector2 = item["to"]
		var color: Color = item["color"]
		
		var mid := from.lerp(to, 0.5) + Vector2(0, -90.0)
		var current_pos := from.lerp(mid, t).lerp(mid.lerp(to, t), t)
		
		_board_view.draw_circle(current_pos, 7.5 * (1.0 - t * 0.25), Color(color.r, color.g, color.b, 0.26))
		_board_view.draw_circle(current_pos, 3.8, Color.WHITE)

func _draw_connection_threads() -> void:
	var active_connection_threads: Array = _board_view.get("active_connection_threads")
	for item in active_connection_threads:
		var age: float = item["age"]
		var t := clampf(age / 0.35, 0.0, 1.0)
		var from: Vector2 = item["from"]
		var to: Vector2 = item["to"]
		var color: Color = item["color"]
		var alpha := 1.0 - t
		
		_board_view.draw_line(from, to, Color(color.r, color.g, color.b, 0.45 * alpha), 3.4)
		_board_view.draw_line(from, to, Color.WHITE, 1.2)
