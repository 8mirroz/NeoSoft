extends Control
class_name BoardView

signal cell_pressed(cell: Vector2i)
signal animations_finished()

const BOARD_PADDING: float = 18.0
const MATCH_POP_DURATION: float = 0.38
const MATCH_POP_EXPAND_RATIO: float = 0.32
const FALL_TRAIL_DURATION: float = 0.28
const SPAWN_REVEAL_DURATION: float = 0.34
const USE_SCENE_SPHERES := true

# Cursor assets from Kenney Starter Kit
@export var cursor_open: Texture2D = preload("res://assets/cursors/cursor-hand-open.png")
@export var cursor_closed: Texture2D = preload("res://assets/cursors/cursor-hand-closed.png")

@export var allow_input_during_cascade: bool = false
@export var max_screen_shake_amplitude: float = 16.0

var board_model: RefCounted
var selected_cell: Vector2i = Vector2i(-1, -1)
var hint_cells: Array[Vector2i] = []
var hammer_targeting: bool = false
var match_pop_fx: Array[Dictionary] = []
var collapse_fx: Array[Dictionary] = []
var spawn_fx: Array[Dictionary] = []
var active_laser_lines: Array[Dictionary] = []
var active_shockwaves: Array[Dictionary] = []
var active_homing_projectiles: Array[Dictionary] = []
var active_connection_threads: Array[Dictionary] = []
var quality_profile := {
	"gem_glow_multiplier": 1.0,
	"background_effect_alpha": 1.0,
}

# Drag and Swipe state variables
var drag_start_cell: Vector2i = Vector2i(-1, -1)
var is_dragging: bool = false

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
var hovered_cell: Vector2i = Vector2i(-1, -1)
var _gems: Dictionary = {} # cell (Vector2i) -> GemView

var _visual_generation: int = 0
var _cascade_input_mode: StringName = &"blocking"

# Visual snapshot buffer — decouples rendering from board_model
# GemPool reads from this snapshot instead of board_model directly.
# This prevents premature recoloring during match resolution animations.
var _visual_snapshot: Dictionary = {} # Vector2i -> int (cell -> piece_id)
var _pending_removals: Dictionary = {} # Vector2i -> true (cells being cleared)
var _visual_snapshot_ready: bool = false

# Subsystems using preload to bypass Godot 4 headless compilation indexing delay
const BoardThemeAdapterScript = preload("res://scripts/presentation/board_theme_adapter.gd")
const BoardPowerProfileScript = preload("res://scripts/presentation/board_power_profile.gd")
const BoardInputControllerScript = preload("res://scripts/presentation/board_input_controller.gd")
const BoardGemPoolScript = preload("res://scripts/presentation/board_gem_pool.gd")
const BoardFxDirectorScript = preload("res://scripts/presentation/board_fx_director.gd")
const BoardFxRendererScript = preload("res://scripts/presentation/board_fx_renderer.gd")

var _theme_adapter: RefCounted
var _power_profile: RefCounted
var _input_controller: RefCounted
var _gem_pool: RefCounted
var _fx_director: RefCounted
var _fx_renderer: RefCounted

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	set_process(true)
	
	_theme_adapter = BoardThemeAdapterScript.new()
	_theme_adapter.setup(self)
	
	_power_profile = BoardPowerProfileScript.new()
	_power_profile.setup(self)
	
	_input_controller = BoardInputControllerScript.new()
	_input_controller.setup(self)
	
	_gem_pool = BoardGemPoolScript.new()
	_gem_pool.setup(self)
	
	_fx_director = BoardFxDirectorScript.new()
	_fx_director.setup(self)
	
	_fx_renderer = BoardFxRendererScript.new()
	_fx_renderer.setup(self)
	
	mouse_entered.connect(_input_controller.on_mouse_entered)
	mouse_exited.connect(_input_controller.on_mouse_exited)
	
	# Connect to the centralized GameEventBus for special gem activation visual effects
	var bus: Node = Engine.get_main_loop().root.get_node_or_null("GameEventBus")
	if bus != null:
		bus.special_activated.connect(_on_special_activated)

func _tc(path: String, fallback: Color) -> Color:
	if _theme_adapter != null:
		return _theme_adapter.tc(path, fallback)
	return fallback

func setup(model: RefCounted) -> void:
	_visual_generation += 1
	if _fx_director != null:
		_fx_director.cancel_previous_sequences()
	board_model = model

	selected_cell = Vector2i(-1, -1)
	hovered_cell = Vector2i(-1, -1)
	drag_start_cell = Vector2i(-1, -1)
	is_dragging = false
	combo_index = 0
	screen_shake_amplitude = 0.0
	position = Vector2.ZERO

	match_pop_fx.clear()
	collapse_fx.clear()
	spawn_fx.clear()
	active_laser_lines.clear()
	active_shockwaves.clear()
	active_homing_projectiles.clear()
	active_connection_threads.clear()
	visual_queue.clear()
	is_processing_queue = false

	_clear_visual_transients()
	snapshot_take_from_model()
	set_process(true)
	queue_redraw()

func refresh() -> void:
	# During active animation pipeline, do NOT reset the snapshot from board_model.
	# The FxDirector manages snapshot updates step by step.
	# Only sync snapshot when the visual queue is fully empty (safe idle state).
	if not is_processing_queue and visual_queue.is_empty() and not _has_active_effects():
		snapshot_take_from_model()
	queue_redraw()

func force_snapshot_sync() -> void:
	"""Force-sync snapshot from board_model — use ONLY for undo, shuffle, board reset."""
	snapshot_take_from_model()
	queue_redraw()

# ─── VISUAL SNAPSHOT BUFFER ──────────────────────────────────────────────────
# These methods manage the visual snapshot that decouples rendering from logic.
# The board_model is the source of truth; the snapshot is what gets rendered.

func snapshot_take_from_model() -> void:
	"""Capture a full snapshot from board_model — used at setup, refresh, undo, shuffle."""
	_visual_snapshot.clear()
	_pending_removals.clear()
	if board_model == null:
		_visual_snapshot_ready = false
		return
	var height: int = board_model.call("get_height") if board_model.has_method("get_height") else board_model.get("height")
	var width: int = board_model.call("get_width") if board_model.has_method("get_width") else board_model.get("width")
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			var piece_id: int = board_model.call("get_piece", cell)
			_visual_snapshot[cell] = piece_id
	_visual_snapshot_ready = true

func apply_visual_clear(cells: Array) -> void:
	"""Mark cells as pending removal (gem still visible during dissolve animation)."""
	for cell_variant in cells:
		var cell: Vector2i = cell_variant
		_pending_removals[cell] = true

func commit_visual_removal() -> void:
	"""Actually remove pending cells from snapshot (after clear animation finishes)."""
	for cell in _pending_removals.keys():
		_visual_snapshot[cell] = -1
	_pending_removals.clear()

func apply_visual_collapse(movements: Array) -> void:
	"""Move gems in visual snapshot from old to new positions."""
	for movement in movements:
		var from: Vector2i = movement.get("from", Vector2i.ZERO)
		var to_cell: Vector2i = movement.get("to", Vector2i.ZERO)
		var piece_id: int = _visual_snapshot.get(from, -1)
		if movement.has("piece_id"):
			piece_id = int(movement["piece_id"])
		_visual_snapshot[to_cell] = piece_id
		_visual_snapshot[from] = -1

func apply_visual_spawn(spawns: Array) -> void:
	"""Add newly spawned gems to visual snapshot."""
	for spawn in spawns:
		var cell: Vector2i = spawn.get("to", spawn.get("position", Vector2i.ZERO))
		var piece_id: int = -1
		if spawn.has("piece_id"):
			piece_id = int(spawn["piece_id"])
		elif spawn.has("gem_type"):
			var gem_str = spawn["gem_type"]
			match gem_str:
				"red": piece_id = 0
				"blue": piece_id = 1
				"green": piece_id = 2
				"yellow": piece_id = 3
				"purple": piece_id = 4
				"white": piece_id = 5
				_:
					if gem_str.is_valid_int():
						piece_id = gem_str.to_int()
		_visual_snapshot[cell] = piece_id

func get_visual_piece(cell: Vector2i) -> int:
	"""Get piece_id from visual snapshot (used by GemPool instead of board_model)."""
	if _visual_snapshot_ready:
		return _visual_snapshot.get(cell, -1)
	# Fallback to board_model if snapshot not initialized
	if board_model != null:
		return board_model.call("get_piece", cell)
	return -1

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

func set_cascade_input_policy(allow_parallel: bool) -> void:
	allow_input_during_cascade = allow_parallel
	_cascade_input_mode = &"parallel" if allow_parallel else &"blocking"

func play_match_pop(matches: Array[Dictionary]) -> void:
	if board_model == null or matches.is_empty():
		return
	visual_queue.append({"type": "match", "data": matches})
	if _fx_director != null:
		_fx_director.start_processing_queue()

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
	
	# Update visual snapshot to match the model's swap
	var piece_from: int = _visual_snapshot.get(from, -1)
	var piece_to: int = _visual_snapshot.get(to, -1)
	_visual_snapshot[from] = piece_to
	_visual_snapshot[to] = piece_from
	
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
	if _fx_director != null:
		_fx_director.start_processing_queue()

func play_spawn_fx(spawns: Array[Dictionary]) -> void:
	if board_model == null or spawns.is_empty():
		return
	visual_queue.append({"type": "spawn", "data": spawns})
	if _fx_director != null:
		_fx_director.start_processing_queue()

func _clear_visual_transients() -> void:
	if _fx_director != null:
		_fx_director.clear_visual_transients()

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
			var next_pos := current.lerp(Vector2.ZERO, 15.0 * delta)
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
			var force := (Vector2.ONE - current) * 380.0 # spring stiffness
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
	
	# Advance premium visual match & line effects
	_advance_custom_effects(active_laser_lines, 0.4, delta)
	_advance_custom_effects(active_shockwaves, 0.5, delta)
	_advance_custom_effects(active_homing_projectiles, 0.6, delta)
	_advance_custom_effects(active_connection_threads, 0.35, delta)

	var has_effects := _has_active_effects()
	var should_block_input := has_effects and not allow_input_during_cascade and _cascade_input_mode != &"parallel"
	
	if should_block_input and mouse_filter != MOUSE_FILTER_IGNORE:
		mouse_filter = MOUSE_FILTER_IGNORE
		Input.set_custom_mouse_cursor(null)
		is_dragging = false
		drag_start_cell = Vector2i(-1, -1)
		hovered_cell = Vector2i(-1, -1)
	elif not should_block_input and mouse_filter == MOUSE_FILTER_IGNORE:
		mouse_filter = MOUSE_FILTER_STOP
		if _input_controller != null:
			_input_controller.set_cursor_state(false)

	# Dynamic idle animation times for all cells
	if board_model != null:
		var height: int = board_model.call("get_height") if board_model.has_method("get_height") else board_model.get("height")
		var width: int = board_model.call("get_width") if board_model.has_method("get_width") else board_model.get("width")
		for y in range(height):
			for x in range(width):
				var cell := Vector2i(x, y)
				if not gem_times.has(cell):
					gem_times[cell] = randf_range(0.0, 100.0)
				gem_times[cell] += delta

	if _gem_pool != null:
		_gem_pool.update_gems_visibility()

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
	if _input_controller != null:
		_input_controller.process_gui_input(event)

func _draw() -> void:
	if board_model == null:
		return
	var metrics := _get_board_metrics()
	if _fx_renderer != null:
		_fx_renderer.draw_board(metrics)

func _advance_effects(effect_list: Array[Dictionary], duration: float, delta: float) -> void:
	for i in range(effect_list.size() - 1, -1, -1):
		var item := effect_list[i]
		item["age"] = float(item.get("age", 0.0)) + delta
		if float(item["age"]) >= duration:
			effect_list.remove_at(i)
			continue
		effect_list[i] = item

func _has_active_effects() -> bool:
	return not match_pop_fx.is_empty() \
		or not collapse_fx.is_empty() \
		or not spawn_fx.is_empty() \
		or not active_laser_lines.is_empty() \
		or not active_shockwaves.is_empty() \
		or not active_homing_projectiles.is_empty() \
		or not active_connection_threads.is_empty()

func _get_board_metrics() -> Dictionary:
	if board_model == null:
		return {
			"board_rect": Rect2(Vector2.ZERO, size),
			"cell_size": 64.0
		}
	var width: int = max(board_model.call("get_width") if board_model.has_method("get_width") else board_model.get("width"), 1)
	var height: int = max(board_model.call("get_height") if board_model.has_method("get_height") else board_model.get("height"), 1)
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
	if board_model.call("is_in_bounds", cell):
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

func _on_special_activated(event: SpecialActivationEvent) -> void:
	if board_model == null or not is_inside_tree():
		return
	var center_pos := _get_cell_center(event.position)
	var piece_id: int = board_model.call("get_piece", event.position)
	if piece_id < 0:
		piece_id = 0
	var palette := _get_palette(piece_id)
	var color: Color = palette["accent"]
	
	match event.special_type:
		SpecialSphereType.Type.BEAM_SPHERE: # BEAM (Row & Col)
			active_laser_lines.append({
				"pos": center_pos,
				"is_row": true,
				"age": 0.0,
				"color": color
			})
			active_laser_lines.append({
				"pos": center_pos,
				"is_row": false,
				"age": 0.0,
				"color": color
			})
			if _fx_director != null:
				_fx_director.apply_screen_shake(4.0)
			SoundManager.play("laser" if SoundManager.has_method("play") else "")
		SpecialSphereType.Type.BLAST_SPHERE, SpecialSphereType.Type.BLAST_SPHERE_PLUS: # BLAST (3x3 area)
			var metrics := _get_board_metrics()
			var cell_size: float = metrics["cell_size"]
			active_shockwaves.append({
				"center": center_pos,
				"max_radius": cell_size * 2.2,
				"age": 0.0,
				"color": color
			})
			if _fx_director != null:
				_fx_director.apply_screen_shake(6.0)
			SoundManager.play("explosion" if SoundManager.has_method("play") else "")
		SpecialSphereType.Type.HOMING_SPHERE: # HOMING (Butterfly projectile)
			var metrics := _get_board_metrics()
			var cell_size: float = metrics["cell_size"]
			active_shockwaves.append({
				"center": center_pos,
				"max_radius": cell_size * 0.8,
				"age": 0.0,
				"color": color
			})
			for cell in event.affected_cells:
				if cell != event.position:
					active_homing_projectiles.append({
						"from": center_pos,
						"to": _get_cell_center(cell),
						"age": 0.0,
						"color": color
					})
			SoundManager.play("rocket" if SoundManager.has_method("play") else "")
	queue_redraw()

func _advance_custom_effects(effect_list: Array[Dictionary], duration: float, delta: float) -> void:
	for i in range(effect_list.size() - 1, -1, -1):
		var item := effect_list[i]
		item["age"] = float(item.get("age", 0.0)) + delta
		if float(item["age"]) >= duration:
			effect_list.remove_at(i)
			continue
		effect_list[i] = item
