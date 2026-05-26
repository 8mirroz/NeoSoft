extends Control
class_name BoardView

signal cell_pressed(cell: Vector2i)
signal animations_finished()

const BOARD_PADDING: float = 26.0
const MATCH_POP_DURATION: float = 0.38
const MATCH_POP_EXPAND_RATIO: float = 0.32
const FALL_TRAIL_DURATION: float = 0.28
const SPAWN_REVEAL_DURATION: float = 0.34

# Cursor assets from Kenney Starter Kit
@export var cursor_open: Texture2D = preload("res://assets/cursors/cursor-hand-open.png")
@export var cursor_closed: Texture2D = preload("res://assets/cursors/cursor-hand-closed.png")

var board_model: RefCounted
var selected_cell: Vector2i = Vector2i(-1, -1)
var hint_cells: Array[Vector2i] = []
var hammer_targeting: bool = false
var match_pop_fx: Array[Dictionary] = []
var collapse_fx: Array[Dictionary] = []
var spawn_fx: Array[Dictionary] = []
var quality_profile := {
	"gem_glow_multiplier": 1.0,
	"background_effect_alpha": 1.0,
}

# Drag and Swipe state variables
var drag_start_cell: Vector2i = Vector2i(-1, -1)
var drag_start_position: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var _mouse_inside: bool = false

# Juicy visual animation state dictionaries
var gem_offsets: Dictionary = {}
var gem_scales: Dictionary = {}
var gem_scale_velocities: Dictionary = {}
var gem_alphas: Dictionary = {}
var gem_times: Dictionary = {}
var visual_queue: Array[Dictionary] = []
var is_processing_queue: bool = false
var _was_animating: bool = false
var combo_index: int = 0
var screen_shake_amplitude: float = 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	set_process(true)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_mouse_inside = true
	_set_cursor_state(false)

func _on_mouse_exited() -> void:
	_mouse_inside = false
	Input.set_custom_mouse_cursor(null)

func _set_cursor_state(closed: bool) -> void:
	if not _mouse_inside:
		return
	if closed:
		Input.set_custom_mouse_cursor(cursor_closed, Input.CURSOR_ARROW, Vector2(16, 16))
	else:
		Input.set_custom_mouse_cursor(cursor_open, Input.CURSOR_ARROW, Vector2(16, 16))

func setup(model: RefCounted) -> void:
	board_model = model
	match_pop_fx.clear()
	collapse_fx.clear()
	spawn_fx.clear()
	set_process(true)
	queue_redraw()

func refresh() -> void:
	queue_redraw()

func set_selected_cell(cell: Vector2i) -> void:
	selected_cell = cell
	queue_redraw()

func clear_selection() -> void:
	selected_cell = Vector2i(-1, -1)
	queue_redraw()

func set_hint_cells(cells: Array[Vector2i]) -> void:
	hint_cells = cells.duplicate()
	queue_redraw()

func clear_hints() -> void:
	if hint_cells.is_empty():
		return
	hint_cells.clear()
	queue_redraw()

func set_hammer_targeting(active: bool) -> void:
	hammer_targeting = active
	queue_redraw()

func set_quality_profile(profile: Dictionary) -> void:
	quality_profile = quality_profile.merged(profile, true)
	queue_redraw()

func play_match_pop(matches: Array[Dictionary]) -> void:
	if board_model == null or matches.is_empty():
		return
	visual_queue.append({"type": "match", "data": matches})
	_start_processing_queue()

func _get_cell_center(cell: Vector2i) -> Vector2:
	var metrics := _get_board_metrics()
	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	return board_rect.position + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * cell_size

func play_swap_fx(from: Vector2i, to: Vector2i) -> void:
	if board_model == null:
		return
	var pos_from := _get_cell_center(from)
	var pos_to := _get_cell_center(to)
	
	# Compensate for model's instant swap by applying opposite visual offsets
	gem_offsets[from] = pos_to - pos_from
	gem_offsets[to] = pos_from - pos_to
	
	# Apply tactical elastic Squash & Stretch deformation
	gem_scales[from] = Vector2(0.82, 1.18)
	gem_scale_velocities[from] = Vector2.ZERO
	gem_scales[to] = Vector2(0.82, 1.18)
	gem_scale_velocities[to] = Vector2.ZERO
	
	set_process(true)
	queue_redraw()

func play_collapse_fx(movements: Array[Dictionary]) -> void:
	if board_model == null or movements.is_empty():
		return
	visual_queue.append({"type": "collapse", "data": movements})
	_start_processing_queue()

func play_spawn_fx(spawns: Array[Dictionary]) -> void:
	if board_model == null or spawns.is_empty():
		return
	visual_queue.append({"type": "spawn", "data": spawns})
	_start_processing_queue()

func _start_processing_queue() -> void:
	if is_processing_queue:
		return
	is_processing_queue = true
	_process_next_visual_event()

func _process_next_visual_event() -> void:
	if visual_queue.is_empty():
		is_processing_queue = false
		combo_index = 0 # Reset combo index when the cascade terminates
		return

	var event: Dictionary = visual_queue.pop_front()
	match event.get("type", ""):
		"match":
			combo_index += 1
			var matches: Array = event.get("data", [])
			
			# Play cascade pop sound exactly once per match step with combo pitch shift
			SoundManager.play_cascade(combo_index)
			
			# 1. Combo Screen Shake (REQ-COMBO-008)
			_apply_screen_shake(combo_index)
			
			# 2. Combo Floating Neon Label (REQ-COMBO-008)
			if combo_index >= 2:
				_spawn_combo_label(combo_index)
			
			# 3. Populate match_pop_fx and spawn particles (REQ-VFX-009)
			for match_data in matches:
				var piece_id := int(match_data.get("piece_id", 0))
				var cells: Array = match_data.get("cells", [])
				for cell_variant in cells:
					var cell: Vector2i = cell_variant
					if not board_model.is_in_bounds(cell):
						continue
					
					match_pop_fx.append({
						"cell": cell,
						"piece_id": piece_id,
						"age": 0.0,
					})
					
					# Spawn procedural stylized VFX particles for this gem type
					_spawn_unique_vfx(_get_cell_center(cell), piece_id)
			
			queue_redraw()
			# Wait for match pop duration (0.38s) + cascade pause phase (0.25s)
			if is_inside_tree():
				await get_tree().create_timer(MATCH_POP_DURATION + 0.25).timeout
			
		"collapse":
			var movements: Array = event.get("data", [])
			for movement in movements:
				var from: Vector2i = movement.get("from", Vector2i.ZERO)
				var to: Vector2i = movement.get("to", Vector2i.ZERO)
				var pos_from := _get_cell_center(from)
				var pos_to := _get_cell_center(to)
				
				# Offset the falling gem back to its visual starting cell
				gem_offsets[to] = pos_from - pos_to
				
				collapse_fx.append({
					"piece_id": int(movement.get("piece_id", 0)),
					"from": from,
					"to": to,
					"age": 0.0,
				})
			
			queue_redraw()
			# Wait for collapse duration (0.28s)
			if is_inside_tree():
				await get_tree().create_timer(FALL_TRAIL_DURATION).timeout
			
		"spawn":
			var spawns: Array = event.get("data", [])
			var cell_size: float = _get_board_metrics()["cell_size"]
			for spawn in spawns:
				var cell: Vector2i = spawn.get("to", Vector2i.ZERO)
				gem_scales[cell] = Vector2.ZERO
				gem_scale_velocities[cell] = Vector2.ZERO
				gem_alphas[cell] = 0.0
				gem_offsets[cell] = Vector2(0, -cell_size * 1.5)
				
				spawn_fx.append({
					"piece_id": int(spawn.get("piece_id", 0)),
					"cell": cell,
					"age": 0.0,
				})
			
			queue_redraw()
			# Wait for spawn duration (0.34s) + refill pause phase (0.15s)
			if is_inside_tree():
				await get_tree().create_timer(SPAWN_REVEAL_DURATION + 0.15).timeout

	# Proceed to the next visual event in the queue
	_process_next_visual_event()

func _apply_screen_shake(combo: int) -> void:
	if combo < 2:
		screen_shake_amplitude = 0.0
		return
	# Shake amplitude grows progressively with combo level for maximum juice impact
	screen_shake_amplitude = min(4.0 + float(combo) * 2.5, 16.0)

func _spawn_combo_label(combo: int) -> void:
	if not is_inside_tree():
		return
	var label := Label.new()
	var text_val := ""
	var color_val := Color(0.78, 0.58, 1.0) # Purple fallback
	
	match combo:
		2:
			text_val = "Combo x2! Nice!"
			color_val = Color(0.42, 0.84, 1.0) # Cyan
		3:
			text_val = "Combo x3! Spectacular!"
			color_val = Color(0.78, 0.58, 1.0) # Purple
		_:
			text_val = "Combo x" + str(combo) + "! UNSTOPPABLE!"
			color_val = Color(1.0, 0.82, 0.32) # Gold

	label.text = text_val
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pivot_offset = Vector2(200, 30) # Center pivot for scale tween bounce
	label.custom_minimum_size = Vector2(400, 60)
	
	# Center it horizontally on the board frame
	label.position = (size - Vector2(400, 60)) * 0.5 + Vector2(0, -60.0) # Slightly above center
	
	# Glass flat background styling
	var flat_style := StyleBoxFlat.new()
	flat_style.bg_color = Color(0.08, 0.05, 0.12, 0.62)
	flat_style.border_color = color_val.lightened(0.2)
	flat_style.border_width_left = 1
	flat_style.border_width_top = 1
	flat_style.border_width_right = 1
	flat_style.border_width_bottom = 1
	flat_style.corner_radius_top_left = 18
	flat_style.corner_radius_top_right = 18
	flat_style.corner_radius_bottom_right = 18
	flat_style.corner_radius_bottom_left = 18
	flat_style.shadow_color = Color(color_val.r, color_val.g, color_val.b, 0.35)
	flat_style.shadow_size = 12
	flat_style.content_margin_left = 16
	flat_style.content_margin_right = 16
	
	label.set("theme_override_styles/normal", flat_style)
	
	# Text outline neon glow
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", color_val)
	label.add_theme_constant_override("outline_size", 6)
	
	add_child(label)
	
	# Bouncing scale and drift up animation via Tween
	label.scale = Vector2.ZERO
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var fade_tween := create_tween()
	fade_tween.tween_interval(0.55)
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.3)
	
	tween.finished.connect(label.queue_free)

func _spawn_unique_vfx(vfx_center: Vector2, piece_id: int) -> void:
	if not is_inside_tree():
		return
	var particles := CPUParticles2D.new()
	particles.position = vfx_center
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.lifetime = 0.55
	
	var gem_type := wrapi(piece_id, 0, 8)
	var palette := _get_palette(gem_type)
	var accent: Color = palette["accent"]
	var glow: Color = palette["glow"]
	
	# Base configuration
	particles.amount = 16
	if quality_profile.has("background_effect_alpha") and float(quality_profile["background_effect_alpha"]) < 0.6:
		# Android/Mobile Safe Profile: reduce particle count to 8
		particles.amount = 8
		
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 140.0
	particles.scale_amount_min = 3.5
	particles.scale_amount_max = 7.0
	
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color.WHITE,
		accent,
		Color(glow.r, glow.g, glow.b, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	particles.color_ramp = grad
	
	# Sphere-specific particle physics (REQ-VFX-009)
	match gem_type:
		0: # Pink Pearl: Star dust (expanding stars)
			particles.amount = particles.amount + 4
			particles.direction = Vector2.DOWN
			particles.initial_velocity_min = 40.0
			particles.radial_accel_min = 20.0
			particles.radial_accel_max = 40.0
			
		1: # Blue Flow: Splash drops (water drops with gravity)
			particles.gravity = Vector2(0, 150.0)
			particles.initial_velocity_min = 80.0
			particles.initial_velocity_max = 180.0
			particles.damping_min = 30.0
			particles.damping_max = 60.0
			
		2: # Ice Spark: Sharp ice splinters (high speed shards)
			particles.amount = particles.amount - 2
			particles.initial_velocity_min = 120.0
			particles.initial_velocity_max = 220.0
			particles.scale_amount_min = 2.0
			particles.scale_amount_max = 5.0
			particles.damping_min = 120.0
			
		3: # Frost Pearl: Rising bubbles
			particles.gravity = Vector2(0, -90.0)
			particles.spread = 120.0
			particles.initial_velocity_min = 30.0
			particles.initial_velocity_max = 80.0
			particles.scale_amount_min = 4.0
			particles.scale_amount_max = 8.0
			
		4: # Mint Shiver: Energy rays (fast horizontal spikes)
			particles.spread = 60.0
			particles.initial_velocity_min = 110.0
			particles.initial_velocity_max = 190.0
			particles.damping_min = 90.0
			
		5: # Gold Aurora: Warm sparks (heavy circular expansion)
			particles.amount = particles.amount + 6
			particles.initial_velocity_min = 50.0
			particles.initial_velocity_max = 100.0
			particles.linear_accel_min = -20.0
			
		6: # Amethyst Haze: Expansion rings (spin particles)
			particles.angular_velocity_min = 180.0
			particles.angular_velocity_max = 360.0
			particles.damping_min = 40.0
			
		7: # Rose Glow: Spiral rose vortex
			particles.amount = particles.amount + 2
			particles.radial_accel_min = -40.0
			particles.radial_accel_max = -20.0
			particles.angular_velocity_min = 90.0
			particles.angular_velocity_max = 180.0

	add_child(particles)
	
	var timer := get_tree().create_timer(particles.lifetime + 0.1)
	timer.timeout.connect(particles.queue_free)

func _process(delta: float) -> void:
	# Decay screen shake (REQ-COMBO-008)
	if screen_shake_amplitude > 0.05:
		screen_shake_amplitude = lerpf(screen_shake_amplitude, 0.0, 10.0 * delta)
		var shake_offset := Vector2(
			randf_range(-screen_shake_amplitude, screen_shake_amplitude),
			randf_range(-screen_shake_amplitude, screen_shake_amplitude)
		)
		position = shake_offset
	else:
		screen_shake_amplitude = 0.0
		position = Vector2.ZERO

	var active := false
	
	# Smoothly interpolate gem positional offsets (sliding and falling)
	for cell in gem_offsets.keys():
		var current: Vector2 = gem_offsets[cell]
		if current.length_squared() > 0.01:
			var next_pos = current.lerp(Vector2.ZERO, 15.0 * delta)
			# Ground impact check for squash & stretch trigger
			if next_pos.length_squared() < 64.0 and current.length_squared() >= 64.0:
				gem_scales[cell] = Vector2(1.22, 0.78)
				gem_scale_velocities[cell] = Vector2.ZERO
				# Musical row-based pitch shifting from Kenney Starter Kit
				SoundManager.play_land_juicy(cell.y)
			gem_offsets[cell] = next_pos
			active = true
		else:
			gem_offsets.erase(cell)
			
	# Spring physics for Squash & Stretch scaling
	for cell in gem_scales.keys():
		var current: Vector2 = gem_scales[cell]
		if (current - Vector2.ONE).length_squared() > 0.0001:
			var velocity: Vector2 = gem_scale_velocities.get(cell, Vector2.ZERO)
			var force = (Vector2.ONE - current) * 380.0 # spring stiffness
			velocity += force * delta
			velocity *= 0.82 # spring damping
			gem_scale_velocities[cell] = velocity
			gem_scales[cell] = current + velocity * delta
			active = true
		else:
			gem_scales.erase(cell)
			gem_scale_velocities.erase(cell)
			
	# Smoothly fade in alphas
	for cell in gem_alphas.keys():
		var current: float = gem_alphas[cell]
		if abs(current - 1.0) > 0.01:
			gem_alphas[cell] = lerpf(current, 1.0, 12.0 * delta)
			active = true
		else:
			gem_alphas.erase(cell)
	
	_advance_effects(match_pop_fx, MATCH_POP_DURATION, delta)
	_advance_effects(collapse_fx, FALL_TRAIL_DURATION, delta)
	_advance_effects(spawn_fx, SPAWN_REVEAL_DURATION, delta)

	var has_effects := _has_active_effects()
	if has_effects and mouse_filter != MOUSE_FILTER_IGNORE:
		mouse_filter = MOUSE_FILTER_IGNORE
		Input.set_custom_mouse_cursor(null)
	elif not has_effects and mouse_filter == MOUSE_FILTER_IGNORE:
		mouse_filter = MOUSE_FILTER_STOP
		_set_cursor_state(false)

	# Dynamic idle animation times for all cells
	if board_model != null:
		for y in range(board_model.height):
			for x in range(board_model.width):
				var cell := Vector2i(x, y)
				if not gem_times.has(cell):
					gem_times[cell] = randf_range(0.0, 100.0)
				gem_times[cell] += delta

	# Process remains active always to support idle static animations
	queue_redraw()

	var is_currently_animating := active or has_effects or is_processing_queue
	if _was_animating and not is_currently_animating:
		_was_animating = false
		emit_signal("animations_finished")
	elif not _was_animating and is_currently_animating:
		_was_animating = true

func _gui_input(event: InputEvent) -> void:
	if board_model == null:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				var cell := _cell_from_local(mouse_event.position)
				if cell != Vector2i(-1, -1):
					drag_start_cell = cell
					drag_start_position = mouse_event.position
					is_dragging = true
					_set_cursor_state(true) # Closed fist cursor
					cell_pressed.emit(cell)
					accept_event()
			else:
				if is_dragging:
					is_dragging = false
					drag_start_cell = Vector2i(-1, -1)
					_set_cursor_state(false) # Open hand cursor
					accept_event()

	elif event is InputEventMouseMotion and is_dragging:
		var motion_event := event as InputEventMouseMotion
		if drag_start_cell != Vector2i(-1, -1):
			var difference := motion_event.position - drag_start_position
			if difference.length() > 32.0:
				var dir := Vector2i.ZERO
				if abs(difference.x) > abs(difference.y):
					dir.x = 1 if difference.x > 0 else -1
				else:
					dir.y = 1 if difference.y > 0 else -1
				
				var target_cell := drag_start_cell + dir
				if board_model.is_in_bounds(target_cell):
					# Emitting target cell press automatically initiates exchange in gameplay.gd
					cell_pressed.emit(target_cell)
				
				# Finish drag transaction to prevent cascading swipes
				is_dragging = false
				drag_start_cell = Vector2i(-1, -1)
				_set_cursor_state(false)
				accept_event()

	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			var cell := _cell_from_local(touch_event.position)
			if cell != Vector2i(-1, -1):
				drag_start_cell = cell
				drag_start_position = touch_event.position
				is_dragging = true
				cell_pressed.emit(cell)
				accept_event()
		else:
			is_dragging = false
			drag_start_cell = Vector2i(-1, -1)
			accept_event()

	elif event is InputEventScreenDrag and is_dragging:
		var drag_event := event as InputEventScreenDrag
		if drag_start_cell != Vector2i(-1, -1):
			var difference := drag_event.position - drag_start_position
			if difference.length() > 32.0:
				var dir := Vector2i.ZERO
				if abs(difference.x) > abs(difference.y):
					dir.x = 1 if difference.x > 0 else -1
				else:
					dir.y = 1 if difference.y > 0 else -1
				
				var target_cell := drag_start_cell + dir
				if board_model.is_in_bounds(target_cell):
					cell_pressed.emit(target_cell)
				
				is_dragging = false
				drag_start_cell = Vector2i(-1, -1)
				accept_event()

func _draw() -> void:
	if board_model == null:
		return

	var metrics := _get_board_metrics()
	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	var gem_radius: float = cell_size * 0.34

	_draw_board_backdrop(board_rect)

	for y in range(board_model.height):
		for x in range(board_model.width):
			var cell := Vector2i(x, y)
			var cell_rect := Rect2(
				board_rect.position + Vector2(x * cell_size, y * cell_size),
				Vector2(cell_size, cell_size)
			).grow(-4.0)
			_draw_cell_slot(cell_rect, cell)

			var piece_id: int = board_model.get_piece(cell)
			if piece_id < 0:
				continue

			var offset: Vector2 = gem_offsets.get(cell, Vector2.ZERO)
			var scale_factor: Vector2 = gem_scales.get(cell, Vector2.ONE)
			var alpha: float = gem_alphas.get(cell, 1.0)
			var time_val: float = gem_times.get(cell, 0.0)
			_draw_gem(cell_rect.get_center() + offset, gem_radius * scale_factor.x, piece_id, alpha, time_val)

	_draw_collapse_effects(metrics, gem_radius)
	_draw_spawn_effects(metrics, gem_radius)
	_draw_match_pop_effects(metrics, gem_radius)

func _draw_board_backdrop(board_rect: Rect2) -> void:
	var background_alpha := float(quality_profile.get("background_effect_alpha", 1.0))
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = Color(0.96, 0.96, 1.0, 0.42 * background_alpha)
	outer_style.border_color = Color(0.88, 0.83, 1.0, 0.75 * background_alpha)
	outer_style.border_width_left = 3
	outer_style.border_width_top = 3
	outer_style.border_width_right = 3
	outer_style.border_width_bottom = 3
	outer_style.corner_radius_top_left = 42
	outer_style.corner_radius_top_right = 42
	outer_style.corner_radius_bottom_right = 42
	outer_style.corner_radius_bottom_left = 42
	outer_style.shadow_color = Color(0.72, 0.6, 0.95, 0.22 * background_alpha)
	outer_style.shadow_size = 20
	draw_style_box(outer_style, board_rect)

	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color(1.0, 1.0, 1.0, 0.18 * background_alpha)
	inner_style.border_color = Color(1.0, 1.0, 1.0, 0.48 * background_alpha)
	inner_style.border_width_left = 2
	inner_style.border_width_top = 2
	inner_style.border_width_right = 2
	inner_style.border_width_bottom = 2
	inner_style.corner_radius_top_left = 34
	inner_style.corner_radius_top_right = 34
	inner_style.corner_radius_bottom_right = 34
	inner_style.corner_radius_bottom_left = 34
	draw_style_box(inner_style, board_rect.grow(-16.0))

func _draw_cell_slot(cell_rect: Rect2, cell: Vector2i) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.08) # Ультра-прозрачное стекло
	style.border_color = Color(1.0, 1.0, 1.0, 0.45) # Яркая глянцевая рамка
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	
	# Мягкое неоновое свечение в глубине ячейки
	style.shadow_color = Color(0.82, 0.78, 1.0, 0.12)
	style.shadow_size = 6

	if cell == selected_cell:
		style.bg_color = Color(0.98, 0.95, 1.0, 0.26)
		style.border_color = Color(1.0, 0.91, 0.7, 0.92)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.shadow_color = Color(1.0, 0.9, 0.6, 0.28)
		style.shadow_size = 10
	elif cell in hint_cells:
		style.bg_color = Color(0.93, 0.97, 1.0, 0.2)
		style.border_color = Color(0.62, 0.92, 1.0, 0.84)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.shadow_color = Color(0.5, 0.9, 1.0, 0.24)
		style.shadow_size = 10
	elif hammer_targeting:
		style.bg_color = Color(1.0, 0.94, 0.96, 0.18)
		style.border_color = Color(1.0, 0.74, 0.68, 0.52)

	draw_style_box(style, cell_rect)


func _draw_gem(center: Vector2, radius: float, piece_id: int, alpha: float = 1.0, time_val: float = 0.0) -> void:
	var palette := _get_palette(piece_id)
	var glow_multiplier := float(quality_profile.get("gem_glow_multiplier", 1.0))
	
	var glow_color: Color = palette["glow"]
	glow_color.a *= glow_multiplier * alpha
	var shadow_color: Color = palette["shadow"]
	shadow_color.a *= glow_multiplier * alpha
	
	var core_color: Color = palette["core"]
	core_color.a *= alpha
	var rim_color: Color = palette["rim"]
	rim_color.a *= alpha
	var inner_rim_color: Color = palette["inner_rim"]
	inner_rim_color.a *= alpha
	var accent_color: Color = palette["accent"]
	accent_color.a *= alpha

	# 1. Idle breathing scale calculation (REQ-VISUAL-006: 1.8 frequency)
	var breath := 1.0 + sin(time_val * 1.8) * 0.038
	var r := radius * breath

	# 2. Premium multi-layered highlights and deep soft drop shadows (Glassmorphism contrast)
	draw_circle(center + Vector2(0, r * 0.16), r * 1.08, Color(0.0, 0.0, 0.0, 0.22 * alpha)) # Soft drop shadow
	draw_circle(center, r * 1.26, glow_color) # Neon under-glow
	draw_circle(center + Vector2(0, r * 0.08), r * 1.1, shadow_color) # Deep contact shadow
	
	# Crisp high-contrast ambient occlusion outline (highly visible against any color)
	draw_circle(center, r + 1.2, Color(0.11, 0.08, 0.16, 0.48 * alpha))
	
	# Liquid glass base layer
	draw_circle(center, r, Color(1.0, 1.0, 1.0, 0.88 * alpha))
	draw_circle(center + Vector2(0, r * 0.12), r * 0.9, core_color) # Rich glowing core
	
	# Glossy crystalline rim reflections
	draw_arc(center, r * 0.96, -PI * 0.1, PI * 1.85, 32, rim_color, 2.2, true)
	draw_arc(center + Vector2(r * 0.05, r * 0.08), r * 0.78, PI * 0.2, PI * 1.42, 24, inner_rim_color, 1.6, true)
	
	# Dual-glare specular highlights for that luxury wet shine look
	draw_circle(center + Vector2(-r * 0.28, -r * 0.34), r * 0.18, Color(1.0, 1.0, 1.0, 0.82 * alpha)) # Primary glare
	draw_circle(center + Vector2(-r * 0.40, -r * 0.40), r * 0.08, Color(1.0, 1.0, 1.0, 0.92 * alpha)) # Secondary micro-glare
	draw_arc(center + Vector2(-r * 0.1, -r * 0.18), r * 0.5, -PI * 0.15, PI * 0.55, 20, Color(1.0, 1.0, 1.0, 0.45 * alpha), 1.8, true)
	
	# === Opal Shimmer Overlay: iridescent chromatic rainbow sheen ===
	var hue_shift := fmod(time_val * 0.12 + float(piece_id) * 0.125, 1.0)
	var shimmer_col := Color.from_hsv(hue_shift, 0.22, 1.0, 0.12 * alpha)
	draw_circle(center + Vector2(r * 0.12, -r * 0.08), r * 0.68, shimmer_col)
	# Secondary chromatic rim arc
	var hue2 := fmod(hue_shift + 0.33, 1.0)
	var rim_shimmer := Color.from_hsv(hue2, 0.18, 1.0, 0.08 * alpha)
	draw_arc(center, r * 0.92, -PI * 0.6 + time_val * 0.2, PI * 0.8 + time_val * 0.2, 20, rim_shimmer, 2.0, true)

	match wrapi(piece_id, 0, 8):
		0:
			_draw_star_dust(center, r, accent_color, time_val)
		1:
			_draw_pearl_rings(center, r, accent_color, time_val)
		2:
			_draw_wave_bands(center, r, accent_color, time_val)
		3:
			_draw_pulse_core(center, r, accent_color, time_val)
		4:
			_draw_line_ribbons(center, r, accent_color, time_val)
		5:
			_draw_bubble_cluster(center, r, accent_color, time_val)
		6:
			_draw_octagon_rings(center, r, accent_color, alpha, time_val)
		_:
			_draw_rose_spiral(center, r, accent_color, alpha, time_val)

func _draw_star_dust(center: Vector2, radius: float, accent: Color, time_val: float) -> void:
	var offsets := [
		Vector2(-0.3, -0.08),
		Vector2(0.08, -0.24),
		Vector2(0.24, 0.16),
		Vector2(-0.12, 0.18),
		Vector2(0.0, 0.0),
	]
	for i in range(offsets.size()):
		var offset: Vector2 = offsets[i]
		# Slow drift movement
		var drift := Vector2(
			sin(time_val + i) * 0.06,
			cos(time_val * 0.8 + i) * 0.06
		)
		draw_circle(center + (offset + drift) * radius, radius * 0.06, accent)

func _draw_pearl_rings(center: Vector2, radius: float, accent: Color, time_val: float) -> void:
	var pulse1 := 1.0 + sin(time_val * 2.2) * 0.06
	var pulse2 := 1.0 + cos(time_val * 1.8) * 0.08
	draw_arc(center, radius * 0.44 * pulse1, 0.0, TAU, 28, accent, 1.6, true)
	draw_arc(center + Vector2(radius * 0.06, radius * 0.02), radius * 0.2 * pulse2, 0.0, TAU, 18, accent.lightened(0.12), 1.4, true)

func _draw_wave_bands(center: Vector2, radius: float, accent: Color, time_val: float) -> void:
	_draw_wave(center, radius, radius * 0.09, accent, 2.2, -radius * 0.12, time_val * 2.5, 0.04)
	_draw_wave(center, radius, radius * 0.08, accent.lightened(0.2), 1.9, radius * 0.08, -time_val * 2.2, -0.03)

func _draw_pulse_core(center: Vector2, radius: float, accent: Color, time_val: float) -> void:
	var core_pulse := 1.0 + sin(time_val * 3.5) * 0.1
	var ring_pulse := 1.0 + cos(time_val * 2.0) * 0.06
	draw_circle(center, radius * 0.22 * core_pulse, accent)
	draw_arc(center, radius * 0.38 * ring_pulse, 0.0, TAU, 28, accent.lightened(0.12), 1.8, true)
	draw_arc(center, radius * 0.54 * ring_pulse, -PI * 0.4, PI * 1.3, 24, accent.darkened(0.12), 1.4, true)

func _draw_line_ribbons(center: Vector2, radius: float, accent: Color, time_val: float) -> void:
	_draw_wave(center, radius, radius * 0.06, accent, 2.2, -radius * 0.02, time_val * 1.8, -0.32)
	_draw_wave(center, radius, radius * 0.04, accent.lightened(0.18), 1.6, radius * 0.18, -time_val * 1.5, -0.3)

func _draw_bubble_cluster(center: Vector2, radius: float, accent: Color, time_val: float) -> void:
	var offset1 := Vector2(sin(time_val) * radius * 0.06, cos(time_val * 0.8) * radius * 0.06)
	var offset2 := Vector2(cos(time_val * 1.1) * radius * 0.05, sin(time_val * 0.9) * radius * 0.05)
	var offset3 := Vector2(sin(time_val * 0.7) * radius * 0.04, cos(time_val * 1.3) * radius * 0.04)
	draw_circle(center + Vector2(-radius * 0.22, radius * 0.06) + offset1, radius * 0.1, accent)
	draw_circle(center + Vector2(radius * 0.16, -radius * 0.12) + offset2, radius * 0.08, accent.lightened(0.18))
	draw_circle(center + Vector2(radius * 0.02, radius * 0.22) + offset3, radius * 0.06, accent.darkened(0.08))

func _draw_octagon_rings(center: Vector2, radius: float, accent: Color, alpha: float, time_val: float) -> void:
	var points := PackedVector2Array()
	var rot_angle := time_val * 0.2
	for i in range(8):
		var angle := i * PI / 4.0 + rot_angle
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var fill_color := accent
	fill_color.a *= 0.42 * alpha
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, accent.lightened(0.2), 1.8, true)
	
	var ring_rad := radius * (0.45 + sin(time_val * 1.5) * 0.08)
	draw_arc(center, ring_rad, 0.0, TAU, 24, Color(1, 1, 1, 0.38 * alpha), 1.2, true)

func _draw_rose_spiral(center: Vector2, radius: float, accent: Color, alpha: float, time_val: float) -> void:
	var points := PackedVector2Array()
	var rot_angle := time_val * 0.35
	for i in range(12):
		var r := radius if i % 3 == 0 else radius * (0.62 + sin(time_val * 2.5 + i) * 0.04)
		var angle := i * PI / 6.0 + rot_angle
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	var fill_color := accent
	fill_color.a *= 0.48 * alpha
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, accent.lightened(0.12), 1.6, true)
	
	var rot_p1 := center + Vector2(cos(rot_angle), sin(rot_angle)) * radius * 0.3
	var rot_p2 := center + Vector2(cos(rot_angle + PI), sin(rot_angle + PI)) * radius * 0.3
	draw_line(rot_p1, rot_p2, Color(1, 1, 1, 0.45 * alpha), 2.0)
	draw_circle(center, radius * 0.2, Color(1, 1, 1, 0.38 * alpha))

func _draw_wave(center: Vector2, radius: float, amplitude: float, color: Color, width: float, vertical_offset: float, phase: float, diagonal: float) -> void:
	var points := PackedVector2Array()
	var steps := 18
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := lerpf(-radius * 0.72, radius * 0.72, t)
		var y := sin((t * TAU) + phase) * amplitude + vertical_offset + x * diagonal
		points.append(center + Vector2(x, y))
	draw_polyline(points, color, width, true)

func _draw_match_pop_effects(metrics: Dictionary, gem_radius: float) -> void:
	if match_pop_fx.is_empty():
		return

	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	for item in match_pop_fx:
		var age := float(item.get("age", 0.0))
		var t: float = clamp(age / MATCH_POP_DURATION, 0.0, 1.0)
		var fade: float = 1.0 - t
		var growth: float = 1.0 + MATCH_POP_EXPAND_RATIO * t
		var cell: Vector2i = item.get("cell", Vector2i.ZERO)
		var center := board_rect.position + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * cell_size
		var piece_id := int(item.get("piece_id", 0))
		var palette := _get_palette(piece_id)
		var accent: Color = palette["accent"]
		var glow: Color = palette["glow"]

		glow.a = 0.32 * fade
		accent.a = 0.66 * fade
		draw_circle(center, gem_radius * 1.08 * growth, glow)
		draw_arc(center, gem_radius * 0.96 * growth, 0.0, TAU, 30, accent, 2.4, true)

		# Draw the shrinking gem dissolving in the center
		var shrink_factor := clampf(1.0 - (age / (MATCH_POP_DURATION * 0.70)), 0.0, 1.0)
		if shrink_factor > 0.0:
			_draw_gem(center, gem_radius * shrink_factor, piece_id, shrink_factor)

func _draw_collapse_effects(metrics: Dictionary, gem_radius: float) -> void:
	if collapse_fx.is_empty():
		return

	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	for item in collapse_fx:
		var age := float(item.get("age", 0.0))
		var t: float = clamp(age / FALL_TRAIL_DURATION, 0.0, 1.0)
		var fade: float = 1.0 - t
		var from_cell: Vector2i = item.get("from", Vector2i.ZERO)
		var to_cell: Vector2i = item.get("to", Vector2i.ZERO)
		var from_center := board_rect.position + (Vector2(from_cell.x, from_cell.y) + Vector2(0.5, 0.5)) * cell_size
		var to_center := board_rect.position + (Vector2(to_cell.x, to_cell.y) + Vector2(0.5, 0.5)) * cell_size
		var trail_color: Color = _get_palette(int(item.get("piece_id", 0)))["glow"]
		trail_color.a = 0.24 * fade
		draw_line(from_center, to_center, trail_color, max(2.0, gem_radius * 0.22))
		draw_circle(to_center, gem_radius * (0.22 + 0.18 * fade), trail_color)

func _draw_spawn_effects(metrics: Dictionary, gem_radius: float) -> void:
	if spawn_fx.is_empty():
		return

	var board_rect: Rect2 = metrics["board_rect"]
	var cell_size: float = metrics["cell_size"]
	for item in spawn_fx:
		var age := float(item.get("age", 0.0))
		var t: float = clamp(age / SPAWN_REVEAL_DURATION, 0.0, 1.0)
		var fade: float = 1.0 - t
		var growth: float = 0.72 + 0.42 * t
		var cell: Vector2i = item.get("cell", Vector2i.ZERO)
		var center := board_rect.position + (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * cell_size
		var palette := _get_palette(int(item.get("piece_id", 0)))
		var glow: Color = palette["glow"]
		var accent: Color = palette["accent"]
		glow.a = 0.42 * fade
		accent.a = 0.58 * fade
		draw_circle(center, gem_radius * 1.18 * growth, glow)
		draw_arc(center, gem_radius * 0.84 * growth, 0.0, TAU, 28, accent, 2.0, true)

func _advance_effects(effect_list: Array[Dictionary], duration: float, delta: float) -> void:
	for i in range(effect_list.size() - 1, -1, -1):
		var item := effect_list[i]
		item["age"] = float(item.get("age", 0.0)) + delta
		if float(item["age"]) >= duration:
			effect_list.remove_at(i)
			continue
		effect_list[i] = item

func _has_active_effects() -> bool:
	return not match_pop_fx.is_empty() or not collapse_fx.is_empty() or not spawn_fx.is_empty()

func _get_board_metrics() -> Dictionary:
	var width: int = max(board_model.width, 1)
	var height: int = max(board_model.height, 1)
	var available_size: Vector2 = size - Vector2.ONE * BOARD_PADDING * 2.0
	var cell_size: float = min(available_size.x / float(width), available_size.y / float(height))
	var board_size: Vector2 = Vector2(cell_size * width, cell_size * height)
	var board_pos: Vector2 = (size - board_size) * 0.5
	return {
		"board_rect": Rect2(board_pos, board_size),
		"cell_size": cell_size,
	}

func _cell_from_local(local_pos: Vector2) -> Vector2i:
	var metrics := _get_board_metrics()
	var board_rect: Rect2 = metrics["board_rect"]
	if not board_rect.has_point(local_pos):
		return Vector2i(-1, -1)

	var cell_size: float = metrics["cell_size"]
	var local := local_pos - board_rect.position
	var cell := Vector2i(
		int(floor(local.x / cell_size)),
		int(floor(local.y / cell_size))
	)
	if board_model.is_in_bounds(cell):
		return cell
	return Vector2i(-1, -1)

func _get_palette(piece_id: int) -> Dictionary:
	match wrapi(piece_id, 0, 8):
		0: # Pink Pearl: soft opalescent rose
			return {
				"core": Color(0.96, 0.72, 0.82, 0.88),
				"rim": Color(0.98, 0.82, 0.92, 0.82),
				"inner_rim": Color(0.98, 0.94, 1.0, 0.85),
				"accent": Color(1.0, 0.85, 0.95, 0.92),
				"glow": Color(0.98, 0.62, 0.82, 0.18),
				"shadow": Color(0.45, 0.15, 0.28, 0.12),
			}
		1: # Blue Flow: translucent sapphire opal
			return {
				"core": Color(0.55, 0.78, 0.96, 0.88),
				"rim": Color(0.72, 0.88, 0.98, 0.82),
				"inner_rim": Color(0.88, 0.94, 1.0, 0.85),
				"accent": Color(0.78, 0.90, 1.0, 0.92),
				"glow": Color(0.42, 0.72, 0.98, 0.18),
				"shadow": Color(0.12, 0.22, 0.42, 0.12),
			}
		2: # Ice Spark: crystalline aqua pearl
			return {
				"core": Color(0.48, 0.90, 0.94, 0.88),
				"rim": Color(0.68, 0.95, 0.98, 0.82),
				"inner_rim": Color(0.86, 0.98, 1.0, 0.85),
				"accent": Color(0.58, 0.94, 1.0, 0.92),
				"glow": Color(0.32, 0.88, 0.96, 0.18),
				"shadow": Color(0.08, 0.25, 0.35, 0.12),
			}
		3: # Frost Pearl: iridescent lavender
			return {
				"core": Color(0.82, 0.72, 0.96, 0.88),
				"rim": Color(0.88, 0.80, 0.98, 0.82),
				"inner_rim": Color(0.94, 0.90, 1.0, 0.85),
				"accent": Color(0.90, 0.82, 1.0, 0.92),
				"glow": Color(0.72, 0.55, 0.98, 0.18),
				"shadow": Color(0.25, 0.15, 0.42, 0.12),
			}
		4: # Mint Shiver: pearlescent seafoam green
			return {
				"core": Color(0.48, 0.88, 0.76, 0.88),
				"rim": Color(0.65, 0.94, 0.85, 0.82),
				"inner_rim": Color(0.85, 0.98, 0.94, 0.85),
				"accent": Color(0.72, 0.96, 0.88, 0.92),
				"glow": Color(0.28, 0.86, 0.68, 0.18),
				"shadow": Color(0.08, 0.28, 0.18, 0.12),
			}
		5: # Gold Aurora: warm pearlescent amber
			return {
				"core": Color(0.98, 0.85, 0.52, 0.88),
				"rim": Color(0.99, 0.92, 0.65, 0.82),
				"inner_rim": Color(1.0, 0.96, 0.78, 0.85),
				"accent": Color(1.0, 0.94, 0.68, 0.92),
				"glow": Color(0.96, 0.82, 0.38, 0.18),
				"shadow": Color(0.42, 0.30, 0.08, 0.12),
			}
		6: # Amethyst Haze: deep pearlescent violet
			return {
				"core": Color(0.72, 0.55, 0.94, 0.88),
				"rim": Color(0.82, 0.68, 0.98, 0.82),
				"inner_rim": Color(0.90, 0.82, 1.0, 0.85),
				"accent": Color(0.85, 0.72, 1.0, 0.92),
				"glow": Color(0.65, 0.38, 0.96, 0.18),
				"shadow": Color(0.22, 0.10, 0.38, 0.12),
			}
		7: # Rose Glow: translucent coral opal
			return {
				"core": Color(0.96, 0.55, 0.65, 0.88),
				"rim": Color(0.98, 0.72, 0.78, 0.82),
				"inner_rim": Color(1.0, 0.86, 0.90, 0.85),
				"accent": Color(0.98, 0.78, 0.84, 0.92),
				"glow": Color(0.96, 0.38, 0.52, 0.18),
				"shadow": Color(0.42, 0.12, 0.18, 0.12),
			}
		_:
			return {
				"core": Color(0.95, 0.88, 0.98, 0.86),
				"rim": Color(0.98, 0.78, 0.92, 0.82),
				"inner_rim": Color(0.82, 0.96, 1.0, 0.85),
				"accent": Color(1.0, 0.94, 0.98, 0.92),
				"glow": Color(0.97, 0.75, 0.94, 0.18),
				"shadow": Color(0.38, 0.25, 0.38, 0.12),
			}
