# /Users/user/3-line/scripts/core_match3/resolve_pipeline.gd
extends RefCounted
class_name ResolvePipeline

## Управляющий FSM конвейер транзакционного расчета ходов и каскадов.
## Полностью изолирован от визуализации и взаимодействует через EventBus.

signal state_changed(old_state: int, new_state: int)
signal pipeline_stabilized()

var context: ResolveContext
var active_specials: Dictionary = {} # Vector2i -> int
var piece_kinds: int = 5
var rng := RandomNumberGenerator.new()
var fsm_timer_sec: float = 0.0

func _init(p_context: ResolveContext) -> void:
	context = p_context
	rng.randomize()

func set_special_sphere(cell: Vector2i, type: int) -> void:
	if type == 0:
		active_specials.erase(cell)
	else:
		active_specials[cell] = type

func get_special_sphere(cell: Vector2i) -> int:
	return active_specials.get(cell, 0)

func request_swap(from: Vector2i, to: Vector2i) -> bool:
	if context.state != ResolveContext.State.IDLE:
		return false
		
	if abs(from.x - to.x) + abs(from.y - to.y) != 1:
		return false
		
	if not context.board.is_in_bounds(from) or not context.board.is_in_bounds(to):
		return false
		
	if not context.board.is_cell_stable(from) or not context.board.is_cell_stable(to):
		return false
		
	context.active_swap_from = from
	context.active_swap_to = to
	
	_transition_to(ResolveContext.State.SWAP_REQUESTED)
	return true

func advance() -> void:
	# Предотвращение зависаний: если в одном состоянии находимся слишком долго, принудительно восстанавливаем поле
	fsm_timer_sec += 0.016
	if fsm_timer_sec > 2.0 and context.state != ResolveContext.State.IDLE:
		printerr("ResolvePipeline: FSM timeout! Forcing stabilization.")
		_transition_to(ResolveContext.State.FAILED_RECOVERY)
		fsm_timer_sec = 0.0
		
	match context.state:
		ResolveContext.State.IDLE:
			fsm_timer_sec = 0.0
			if context.input_buffer != null:
				var current_time := Time.get_ticks_msec() / 1000.0
				var move = context.input_buffer.validate_and_get_next(context.board, current_time)
				if move != null:
					context.active_swap_from = move.from_cell
					context.active_swap_to = move.to_cell
					_transition_to(ResolveContext.State.SWAP_REQUESTED)
					
		ResolveContext.State.SWAP_REQUESTED:
			context.board.set_cell_state(context.active_swap_from, CellState.State.RESOLVING)
			context.board.set_cell_state(context.active_swap_to, CellState.State.RESOLVING)
			
			var spec_from = get_special_sphere(context.active_swap_from)
			var spec_to = get_special_sphere(context.active_swap_to)
			set_special_sphere(context.active_swap_from, spec_to)
			set_special_sphere(context.active_swap_to, spec_from)
			
			context.board.swap_gems(context.active_swap_from, context.active_swap_to)
			_transition_to(ResolveContext.State.SWAP_VALIDATING)
			
		ResolveContext.State.SWAP_VALIDATING:
			var shapes = context.shape_detector.detect_shapes(context.board, context.active_swap_from)
			var is_special_act = get_special_sphere(context.active_swap_from) != 0 or get_special_sphere(context.active_swap_to) != 0
			context.is_special_swap = is_special_act
			
			if not shapes.is_empty() or is_special_act:
				context.pending_matches = shapes
				_transition_to(ResolveContext.State.MATCH_SCANNING)
			else:
				# Возвращаем на место при невалидном свайпе
				var spec_from = get_special_sphere(context.active_swap_from)
				var spec_to = get_special_sphere(context.active_swap_to)
				set_special_sphere(context.active_swap_from, spec_to)
				set_special_sphere(context.active_swap_to, spec_from)
				context.board.swap_gems(context.active_swap_from, context.active_swap_to)
				
				context.board.set_cell_state(context.active_swap_from, CellState.State.STABLE)
				context.board.set_cell_state(context.active_swap_to, CellState.State.STABLE)
				
				_transition_to(ResolveContext.State.IDLE)
				
		ResolveContext.State.MATCH_SCANNING:
			if context.pending_matches.is_empty():
				context.pending_matches = context.shape_detector.detect_shapes(context.board)
				
			if not context.pending_matches.is_empty() or context.is_special_swap:
				context.pending_specials.clear()
				var cleared_cells: Array[Vector2i] = []
				
				for shape in context.pending_matches:
					# Публикуем событие MatchEvent в EventBus
					var match_coords: Array[Vector2i] = []
					match_coords.assign(shape.cells)
					var match_event = MatchEvent.new(match_coords, context.board.get_gem(shape.cells[0]), shape.shape_type, 100)
					GameEventBus.emit_signal("match_detected", match_event)
					
					for cell in shape.cells:
						if not cell in cleared_cells:
							cleared_cells.append(cell)
							context.board.set_cell_state(cell, CellState.State.RESOLVING)
							
					# Создаем спец-сферу
					if shape.shape_type != "LINE_3":
						var special = context.sphere_factory.create_special_sphere(shape)
						if special.get("special_type", 0) != 0:
							context.pending_specials.append(special)
							
				for cell in cleared_cells:
					context.board.set_cell_state(cell, CellState.State.LOCKED)
					
				_transition_to(ResolveContext.State.SPECIAL_SPAWNING)
			else:
				_transition_to(ResolveContext.State.CASCADE_CHECKING)
				
		ResolveContext.State.SPECIAL_SPAWNING:
			if not context.pending_specials.is_empty():
				for spec in context.pending_specials:
					var cell: Vector2i = spec["cell"]
					var special_type: int = spec["special_type"]
					set_special_sphere(cell, special_type)
					if context.board.get_cell_state(cell) == CellState.State.LOCKED:
						context.board.set_cell_state(cell, CellState.State.STABLE)
						
					# Публикуем спавн спец-сферы
					GameEventBus.emit_signal("special_spawned", cell, special_type)
				context.pending_specials.clear()
				
			_transition_to(ResolveContext.State.EFFECT_RESOLVING)
			
		ResolveContext.State.EFFECT_RESOLVING:
			var cleared_cells: Array[Vector2i] = []
			for y in range(context.board.height):
				for x in range(context.board.width):
					var cell := Vector2i(x, y)
					if context.board.get_cell_state(cell) == CellState.State.LOCKED:
						cleared_cells.append(cell)
						
			var i = 0
			while i < cleared_cells.size():
				var cell = cleared_cells[i]
				var special_type = get_special_sphere(cell)
				if special_type != 0:
					var secondary_cells = _explode_special_sphere(cell, special_type)
					set_special_sphere(cell, 0)
					
					# Публикуем взрыв спец-сферы
					var act_coords: Array[Vector2i] = []
					act_coords.assign(secondary_cells)
					var act_event = SpecialActivationEvent.new(cell, special_type, act_coords)
					GameEventBus.emit_signal("special_activated", act_event)
					
					for sc in secondary_cells:
						if not sc in cleared_cells and context.board.is_in_bounds(sc):
							if context.board.get_cell_state(sc) != CellState.State.BLOCKED:
								cleared_cells.append(sc)
								context.board.set_cell_state(sc, CellState.State.LOCKED)
				i += 1
				
			for cell in cleared_cells:
				context.board.set_gem(cell, "")
				set_special_sphere(cell, 0)
				context.board.set_cell_state(cell, CellState.State.STABLE)
				
			context.pending_matches.clear()
			context.is_special_swap = false
			_transition_to(ResolveContext.State.GRAVITY_APPLYING)
			
		ResolveContext.State.GRAVITY_APPLYING:
			# Гравитация и Refill
			for x in range(context.board.width):
				var write_y = context.board.height - 1
				for y in range(context.board.height - 1, -1, -1):
					var from_cell = Vector2i(x, y)
					if context.board.get_cell_state(from_cell) == CellState.State.BLOCKED:
						continue
					var gem = context.board.get_gem(from_cell)
					if gem == "":
						continue
						
					var to_cell = Vector2i(x, write_y)
					while to_cell.y > y and (context.board.get_gem(to_cell) != "" or context.board.get_cell_state(to_cell) == CellState.State.BLOCKED):
						to_cell.y -= 1
						
					if from_cell != to_cell and to_cell.y > y:
						context.board.set_gem(to_cell, gem)
						context.board.set_gem(from_cell, "")
						
						var spec_type = get_special_sphere(from_cell)
						set_special_sphere(to_cell, spec_type)
						set_special_sphere(from_cell, 0)
						
						context.board.set_cell_state(to_cell, CellState.State.FALLING)
					write_y = to_cell.y - 1
					
			# Накатываем новые гемы через ControlledCascadeEngine
			var empty_cells: Array[Vector2i] = []
			for x in range(context.board.width):
				for y in range(context.board.height):
					var cell = Vector2i(x, y)
					if context.board.get_gem(cell) == "":
						empty_cells.append(cell)
						
			if not empty_cells.is_empty():
				# Симулируем Assisted Drop
				var last_meta = {"shape_type": "line_3", "dominant_color": "blue"}
				var drop_results = []
				if context.has_meta("cascade_engine"):
					var engine = context.get_meta("cascade_engine")
					# Приводим к плоскому массиву для расчета
					var board_arr = []
					drop_results = engine.fill_empty_cells(board_arr, empty_cells, last_meta)
				else:
					# Fallback
					for cell in empty_cells:
						drop_results.append({"position": cell, "gem_type": "blue"})
						
				for drop in drop_results:
					var pos: Vector2i = drop["position"]
					var gem: String = drop["gem_type"]
					context.board.set_gem(pos, gem)
					context.board.set_cell_state(pos, CellState.State.SPAWNING)
					
			_transition_to(ResolveContext.State.CASCADE_CHECKING)
			
		ResolveContext.State.CASCADE_CHECKING:
			context.current_cascade_depth += 1
			GameEventBus.emit_signal("cascade_started", context.current_cascade_depth)
			
			if context.current_cascade_depth >= context.max_cascade_depth:
				_transition_to(ResolveContext.State.FAILED_RECOVERY)
				return
				
			var shapes = context.shape_detector.detect_shapes(context.board)
			if not shapes.is_empty():
				context.pending_matches = shapes
				_transition_to(ResolveContext.State.MATCH_SCANNING)
			else:
				_transition_to(ResolveContext.State.COMBO_UPDATING)
				
		ResolveContext.State.COMBO_UPDATING:
			if context.combo_controller != null:
				# Сохраняем Fever Meter
				pass
			_transition_to(ResolveContext.State.STABILIZING)
			
		ResolveContext.State.STABILIZING:
			context.board.force_stabilize()
			context.current_cascade_depth = 0
			context.active_swap_from = Vector2i(-1, -1)
			context.active_swap_to = Vector2i(-1, -1)
			
			emit_signal("pipeline_stabilized")
			_transition_to(ResolveContext.State.IDLE)
			
		ResolveContext.State.FAILED_RECOVERY:
			context.board.force_stabilize()
			context.current_cascade_depth = 0
			context.pending_matches.clear()
			context.pending_specials.clear()
			active_specials.clear()
			context.active_swap_from = Vector2i(-1, -1)
			context.active_swap_to = Vector2i(-1, -1)
			
			emit_signal("pipeline_stabilized")
			_transition_to(ResolveContext.State.IDLE)

func resolve_full_cascade() -> void:
	var safety_counter := 0
	while context.state != ResolveContext.State.IDLE and safety_counter < 1000:
		advance()
		safety_counter += 1
	if safety_counter >= 1000:
		_transition_to(ResolveContext.State.FAILED_RECOVERY)
		advance()

func _transition_to(new_state: int) -> void:
	var old_state = context.state
	context.state = new_state
	emit_signal("state_changed", old_state, new_state)

func _explode_special_sphere(cell: Vector2i, type: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	match type:
		1: # BEAM
			for x in range(context.board.width):
				result.append(Vector2i(x, cell.y))
			for y in range(context.board.height):
				result.append(Vector2i(cell.x, y))
		2: # BLAST
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					result.append(cell + Vector2i(dx, dy))
	return result
