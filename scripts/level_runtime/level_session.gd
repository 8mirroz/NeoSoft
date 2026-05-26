## LevelSession — оркестратор игровой сессии уровня
## Связывает core_match3 + level_runtime через EventBus
## Это единственный узел, который координирует модули
extends Node
class_name LevelSession

const BoardLogicScript := preload("res://scripts/core_match3/board_logic.gd")
const ShapeDetectorScript := preload("res://scripts/core_match3/shape_detector.gd")

@export var level_number: int = 1
@export var fever_mode_enabled: bool = true

# Legacy core
var board_controller: BoardController

# CFE Core Components
var board_state_engine: RefCounted
var combo_controller: ComboFeverController
var input_buffer: InputBufferController
var shape_detector: RefCounted
var sphere_factory: SpecialSphereFactory
var target_priority: TargetPrioritySystem
var telemetry: BalanceTelemetryLayer
var resolve_context: ResolveContext
var pipeline: ResolvePipeline

var score_system := ScoreSystem.new()
var goal_tracker := GoalTracker.new()
var move_counter := MoveCounter.new()
var level_config: Dictionary = {}
var soft_launch_config: Dictionary = {}
var hint_system_timer: float = 0.0
var hint_active: bool = false
var session_finished: bool = false
var session_paused: bool = false

var _selected_cell: Vector2i = Vector2i(-1, -1)
var _undo_snapshot: Dictionary = {}
var _undo_reason: String = ""
var _pending_undo_snapshot: Dictionary = {}

func _ready() -> void:
	if UserData.active_level > 0:
		level_number = UserData.active_level

	level_config = LevelLoader.load_level(level_number)
	soft_launch_config = LevelLoader.load_soft_launch_config()
	if level_config.is_empty():
		push_error("LevelSession: failed to load level %d" % level_number)
		return

	# Инициализация level_runtime
	var board_cfg: Dictionary = level_config["board"]
	move_counter.setup(level_config.get("moves", 20))
	score_system.reset(level_config.get("target_score", 1500))
	goal_tracker.setup(level_config.get("goals", []))

	if fever_mode_enabled:
		# === Combo Fever Engine Path ===
		# Загружаем профиль сложности
		var profiles_data := {}
		if FileAccess.file_exists("res://data/difficulty_profiles.json"):
			var file := FileAccess.open("res://data/difficulty_profiles.json", FileAccess.READ)
			var json_conv := JSON.new()
			if json_conv.parse(file.get_as_text()) == OK:
				profiles_data = json_conv.data.get("profiles", {})
			file.close()
		var level_key := "level_" + str(clamp(level_number, 1, 10))
		var profile: Dictionary = profiles_data.get(level_key, {})

		# Создаем core-объекты CFE
		board_state_engine = BoardLogicScript.new()
		board_state_engine.configure(board_cfg.get("width", 8), board_cfg.get("height", 8), board_cfg.get("gem_kinds", 6))
		_cfe_initial_fill_without_matches(board_cfg.get("gem_kinds", 6))

		combo_controller = ComboFeverController.new()
		if not profile.is_empty():
			combo_controller.base_duration_normal = float(profile.get("base_duration_normal", combo_controller.base_duration_normal))
			combo_controller.simple_match_refresh = float(profile.get("simple_match_refresh", combo_controller.simple_match_refresh))
			combo_controller.shape_match_refresh = float(profile.get("shape_match_refresh", combo_controller.shape_match_refresh))
			combo_controller.special_sphere_refresh = float(profile.get("special_sphere_refresh", combo_controller.special_sphere_refresh))
			combo_controller.invalid_move_penalty = float(profile.get("invalid_move_penalty", combo_controller.invalid_move_penalty))
			combo_controller.fever_combo_threshold = int(profile.get("fever_combo_threshold", combo_controller.fever_combo_threshold))
			combo_controller.fever_duration = float(profile.get("fever_duration", combo_controller.fever_duration))
			combo_controller.score_multiplier_fever = float(profile.get("score_multiplier_fever", combo_controller.score_multiplier_fever))
			combo_controller.combo_window_max = combo_controller.base_duration_normal

		input_buffer = InputBufferController.new()
		shape_detector = ShapeDetectorScript.new()
		sphere_factory = SpecialSphereFactory.new()
		target_priority = TargetPrioritySystem.new()
		telemetry = BalanceTelemetryLayer.new()

		resolve_context = ResolveContext.new(board_state_engine, combo_controller, input_buffer, shape_detector, sphere_factory, target_priority)
		
		var cascade_engine = ControlledCascadeEngine.new()
		var rules_data := {}
		if FileAccess.file_exists("res://data/cascade_rules.json"):
			var file := FileAccess.open("res://data/cascade_rules.json", FileAccess.READ)
			var json_conv := JSON.new()
			if json_conv.parse(file.get_as_text()) == OK:
				rules_data = json_conv.data
			file.close()
		cascade_engine.initialize(rules_data, randi())
		cascade_engine.prepare_for_level(profile)
		resolve_context.set_meta("cascade_engine", cascade_engine)

		pipeline = ResolvePipeline.new(resolve_context)
		pipeline.piece_kinds = board_cfg.get("gem_kinds", 6)

		# Подключаем сигналы pipeline к обработчикам
		pipeline.swap_started.connect(_on_cfe_swap_started)
		pipeline.swap_completed.connect(_on_cfe_swap_completed)
		pipeline.matches_detected.connect(_on_cfe_matches_detected)
		pipeline.gravity_applied.connect(_on_cfe_gravity_applied)
		pipeline.combo_updated.connect(_on_cfe_combo_updated)
		pipeline.pipeline_stabilized.connect(_on_cfe_pipeline_stabilized)
		
	else:
		# === Legacy path ===
		board_controller = BoardController.new()
		board_controller.board_width = board_cfg.get("width", 8)
		board_controller.board_height = board_cfg.get("height", 8)
		board_controller.piece_kinds = board_cfg.get("gem_kinds", 6)
		add_child(board_controller)
		board_controller.initialize()

		board_controller.swap_requested.connect(_on_swap_requested)
		board_controller.swap_rejected.connect(_on_swap_rejected)
		board_controller.swap_resolved.connect(_on_swap_resolved)
		board_controller.matches_resolved.connect(_on_matches_resolved)
		board_controller.board_collapsed.connect(_on_board_collapsed)
		board_controller.pieces_generated.connect(_on_pieces_generated)
		board_controller.turn_finished.connect(_on_turn_finished)

	# Подключить входящие сигналы от EventBus
	EventBus.gem_tapped.connect(_on_gem_tapped)
	EventBus.booster_activated.connect(_on_booster_activated)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)

	# Оповестить о загрузке
	UserData.record_session_start(level_number)
	EventBus.analytics_event_requested.emit("session_started", {
		"level_id": level_number,
		"quality_profile": UserData.quality_profile,
		"total_sessions": UserData.total_sessions,
	})
	EventBus.level_loaded.emit(level_config)
	_emit_status_updates()
	
	if not fever_mode_enabled:
		_ensure_playable_board("level_loaded")

	EventBus.analytics_event_requested.emit("level_started", {
		"level_id": level_number,
		"moves": move_counter.max_moves,
		"target_score": score_system.target_score,
	})

func _process(delta: float) -> void:
	if session_finished or session_paused:
		return
		
	if fever_mode_enabled:
		combo_controller.update(delta)
		# Также если pipeline не IDLE, продвигаем FSM в _process для надежности
		if pipeline.context.state != ResolveContext.State.IDLE:
			_advance_cfe_pipeline()

	# Hint timer (p2.md §22: подсказка через 5 сек бездействия)
	if not hint_active:
		hint_system_timer += delta
		if hint_system_timer >= GameConstants.HINT_DELAY_SECONDS:
			_show_hint()

func _on_gem_tapped(cell: Vector2i) -> void:
	if session_finished or session_paused:
		return
	hint_system_timer = 0.0
	hint_active = false

	if _selected_cell == Vector2i(-1, -1):
		# Первый тап — выбираем
		_selected_cell = cell
		EventBus.gem_selected.emit(cell)
	elif _selected_cell == cell:
		# Тап по тому же — отмена
		_selected_cell = Vector2i(-1, -1)
		EventBus.gem_deselected.emit()
	else:
		# Второй тап — пробуем swap
		var from := _selected_cell
		_selected_cell = Vector2i(-1, -1)
		EventBus.gem_deselected.emit()
		
		if fever_mode_enabled:
			_pending_undo_snapshot = _capture_runtime_snapshot()
			var current_time := Time.get_ticks_msec() / 1000.0
			
			if pipeline.context.state != ResolveContext.State.IDLE:
				# Если идет каскад, кладем в буфер ходов (CFE-04)
				input_buffer.enqueue_move(from, cell, board_state_engine, current_time)
				telemetry.record_queued_move(true, false)
			else:
				pipeline.request_swap(from, cell)
				_advance_cfe_pipeline()
		else:
			_pending_undo_snapshot = _capture_runtime_snapshot()
			board_controller.request_swap(from, cell)

# ──────────────────────────────────────────────
# Board event handlers → EventBus bridge
# ──────────────────────────────────────────────

func _on_swap_requested(from: Vector2i, to: Vector2i) -> void:
	EventBus.swap_requested.emit(from, to)

func _on_swap_rejected(from: Vector2i, to: Vector2i) -> void:
	_pending_undo_snapshot.clear()
	EventBus.swap_rejected.emit(from, to)

func _on_swap_resolved(from: Vector2i, to: Vector2i) -> void:
	# Ход засчитан
	move_counter.use_move()
	_commit_pending_undo("swap")
	EventBus.swap_resolved.emit(from, to)

func _on_matches_resolved(matches: Array[Dictionary]) -> void:
	# Подсчитать очки за каждый match
	for m in matches:
		var length: int = m.get("length", 3)
		score_system.add_match_score(length)
		goal_tracker.process_match(m)

	# Обновить цель типа SCORE
	goal_tracker.process_score(score_system.score)

	EventBus.match_resolved.emit(matches)
	_emit_status_updates()

func _on_board_collapsed(movements: Array[Dictionary]) -> void:
	EventBus.board_collapsed.emit(movements)

func _on_pieces_generated(spawns: Array[Dictionary]) -> void:
	EventBus.pieces_generated.emit(spawns)
	score_system.increment_cascade()
	EventBus.cascade_completed.emit(score_system.cascade_depth)

func _on_turn_finished() -> void:
	score_system.reset_cascade()
	EventBus.turn_finished.emit()
	if _check_end_conditions():
		return
	_ensure_playable_board("turn_finished")
	_emit_status_updates()

# ──────────────────────────────────────────────
# End conditions
# ──────────────────────────────────────────────

func _check_end_conditions() -> bool:
	if goal_tracker.all_completed():
		# ПОБЕДА
		score_system.add_remaining_moves_bonus(move_counter.remaining())
		UserData.complete_level(level_number, score_system.score, score_system.get_stars())
		session_finished = true
		_emit_status_updates()
		var result := {
			"won": true,
			"score": score_system.score,
			"stars": score_system.get_stars(),
			"moves_used": move_counter.moves_used,
			"moves_remaining": move_counter.remaining(),
			"level_id": level_number,
		}
		EventBus.level_finished.emit(result)
		EventBus.analytics_event_requested.emit("level_finished", result)
		return true
	if move_counter.is_exhausted():
		# ПОРАЖЕНИЕ
		UserData.record_failure(level_number)
		session_finished = true
		var result := {
			"won": false,
			"score": score_system.score,
			"stars": score_system.get_stars(),
			"moves_used": move_counter.moves_used,
			"moves_remaining": 0,
			"level_id": level_number,
			"fail_reason": "moves_exhausted",
		}
		EventBus.level_finished.emit(result)
		EventBus.analytics_event_requested.emit("level_finished", result)
		return true
	return false

# ──────────────────────────────────────────────
# Status updates
# ──────────────────────────────────────────────

func _emit_status_updates() -> void:
	EventBus.moves_updated.emit(move_counter.remaining(), move_counter.moves_used)
	EventBus.score_updated.emit(score_system.score, score_system.get_stars())
	EventBus.goals_updated.emit(goal_tracker.get_goals_snapshot())

# ──────────────────────────────────────────────
# Hint
# ──────────────────────────────────────────────

func _show_hint() -> void:
	hint_active = true
	var hint_cells: Array[Vector2i] = []
	if fever_mode_enabled:
		hint_cells = HintSystem.find_cfe_hint(board_state_engine, shape_detector)
	else:
		hint_cells = HintSystem.find_hint(board_controller.board, board_controller.match_system)
		
	if not hint_cells.is_empty():
		EventBus.hint_requested.emit(hint_cells)
	else:
		_ensure_playable_board("hint_scan")

# ──────────────────────────────────────────────
# Boosters (MVP: hammer, shuffle, undo)
# ──────────────────────────────────────────────

func _on_booster_activated(booster_type: int, target_cell: Vector2i) -> void:
	if session_finished or session_paused:
		return
	match booster_type:
		GameConstants.BoosterType.HAMMER:
			_commit_undo_snapshot("hammer")
			_use_hammer(target_cell)
		GameConstants.BoosterType.SHUFFLE:
			_commit_undo_snapshot("shuffle")
			_use_shuffle()
		GameConstants.BoosterType.UNDO:
			_use_undo()

func _use_hammer(cell: Vector2i) -> void:
	if board_controller.board.get_piece(cell) < 0:
		return
	board_controller.board.set_piece(cell, GameConstants.EMPTY_CELL)
	var movements := board_controller.shedding_system.collapse(board_controller.board)
	EventBus.board_collapsed.emit(movements)
	var spawns := board_controller.generation_system.refill(
		board_controller.board, board_controller.rng, board_controller.piece_kinds
	)
	EventBus.pieces_generated.emit(spawns)
	board_controller.resolve_board_if_needed()
	_ensure_playable_board("hammer")
	_emit_status_updates()
	EventBus.analytics_event_requested.emit("booster_used", {
		"level_id": level_number,
		"type": "hammer",
		"target_cell": {"x": cell.x, "y": cell.y},
	})

func _use_shuffle() -> void:
	if board_controller.shuffle_board():
		var empty_movements: Array[Dictionary] = []
		var empty_spawns: Array[Dictionary] = []
		EventBus.board_collapsed.emit(empty_movements)
		EventBus.pieces_generated.emit(empty_spawns)
		EventBus.analytics_event_requested.emit("booster_used", {
			"level_id": level_number,
			"type": "shuffle",
		})
	_emit_status_updates()
	_ensure_playable_board("shuffle")

func has_undo_available() -> bool:
	return not _undo_snapshot.is_empty()

func _use_undo() -> void:
	if _undo_snapshot.is_empty():
		return
	_restore_runtime_snapshot(_undo_snapshot)
	EventBus.undo_used.emit({
		"level_id": level_number,
		"reason": _undo_reason,
	})
	EventBus.analytics_event_requested.emit("undo_used", {
		"level_id": level_number,
		"reason": _undo_reason,
	})
	_undo_snapshot.clear()
	_undo_reason = ""
	_emit_status_updates()
	var empty_movements: Array[Dictionary] = []
	var empty_spawns: Array[Dictionary] = []
	EventBus.board_collapsed.emit(empty_movements)
	EventBus.pieces_generated.emit(empty_spawns)

func _commit_undo_snapshot(reason: String) -> void:
	_undo_snapshot = _capture_runtime_snapshot()
	_undo_reason = reason

func _commit_pending_undo(reason: String) -> void:
	if _pending_undo_snapshot.is_empty():
		return
	_undo_snapshot = _pending_undo_snapshot.duplicate(true)
	_undo_reason = reason
	_pending_undo_snapshot.clear()

func _capture_runtime_snapshot() -> Dictionary:
	var board_snap = null
	if board_controller != null:
		board_snap = board_controller.snapshot()
	elif board_state_engine != null:
		board_snap = board_state_engine.create_snapshot()
		
	return {
		"board": board_snap,
		"score": score_system.snapshot(),
		"goals": goal_tracker.snapshot(),
		"moves": move_counter.snapshot(),
		"selected_cell": _selected_cell,
		"hint_timer": hint_system_timer,
		"hint_active": hint_active,
	}

func _restore_runtime_snapshot(snapshot: Dictionary) -> void:
	var board_snap = snapshot.get("board")
	if board_controller != null:
		board_controller.restore(board_snap if board_snap != null else {})
	elif board_state_engine != null and board_snap != null:
		board_state_engine.load_snapshot(board_snap)
		
	score_system.restore(snapshot.get("score", {}))
	goal_tracker.restore(snapshot.get("goals", []))
	move_counter.restore(snapshot.get("moves", {}))
	_selected_cell = snapshot.get("selected_cell", Vector2i(-1, -1))
	hint_system_timer = float(snapshot.get("hint_timer", 0.0))
	hint_active = bool(snapshot.get("hint_active", false))
	EventBus.gem_deselected.emit()

func _ensure_playable_board(reason: String) -> void:
	if board_controller == null:
		return
	if board_controller.has_valid_moves():
		return
	EventBus.dead_board_detected.emit({
		"level_id": level_number,
		"reason": reason,
	})
	EventBus.analytics_event_requested.emit("dead_board_detected", {
		"level_id": level_number,
		"reason": reason,
	})
	if board_controller.shuffle_board():
		EventBus.auto_shuffle_applied.emit({
			"level_id": level_number,
			"reason": reason,
		})
		var empty_movements: Array[Dictionary] = []
		var empty_spawns: Array[Dictionary] = []
		EventBus.board_collapsed.emit(empty_movements)
		EventBus.pieces_generated.emit(empty_spawns)
		EventBus.analytics_event_requested.emit("auto_shuffle_applied", {
			"level_id": level_number,
			"reason": reason,
		})

func _on_game_paused() -> void:
	session_paused = true

func _on_game_resumed() -> void:
	session_paused = false

# ──────────────────────────────────────────────
# CFE Helper Methods and Event Handlers
# ──────────────────────────────────────────────

func _advance_cfe_pipeline() -> void:
	if not fever_mode_enabled:
		return
	
	# Продвигаем до состояния, требующего ожидания visual анимации, или до IDLE
	while true:
		var prev_state: int = pipeline.context.state
		pipeline.advance()
		var curr_state: int = pipeline.context.state
		
		if curr_state == ResolveContext.State.IDLE:
			break
			
		# Проверяем состояния, требующие визуального ожидания
		if curr_state == ResolveContext.State.SWAP_REQUESTED or \
		   curr_state == ResolveContext.State.GRAVITY_APPLYING:
			break
			
		if prev_state == curr_state:
			break

func _cfe_initial_fill_without_matches(gem_kinds: int) -> void:
	var width: int = board_state_engine.width
	var height: int = board_state_engine.height
	var rng_obj := RandomNumberGenerator.new()
	rng_obj.randomize()
	
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			var piece_id := rng_obj.randi_range(0, gem_kinds - 1)
			board_state_engine.set_piece(cell, piece_id)
			while _cfe_creates_match_at(cell, piece_id):
				piece_id = (piece_id + 1) % gem_kinds
				board_state_engine.set_piece(cell, piece_id)

func _cfe_creates_match_at(cell: Vector2i, piece: int) -> bool:
	var x := cell.x
	var y := cell.y

	if x >= 2:
		if board_state_engine.get_piece(Vector2i(x - 1, y)) == piece and board_state_engine.get_piece(Vector2i(x - 2, y)) == piece:
			return true

	if y >= 2:
		if board_state_engine.get_piece(Vector2i(x, y - 1)) == piece and board_state_engine.get_piece(Vector2i(x, y - 2)) == piece:
			return true

	return false

func _on_cfe_swap_started(from: Vector2i, to: Vector2i) -> void:
	EventBus.swap_requested.emit(from, to)

func _on_cfe_swap_completed(from: Vector2i, to: Vector2i, success: bool) -> void:
	if success:
		move_counter.use_move()
		_commit_pending_undo("swap")
		EventBus.swap_resolved.emit(from, to)
		telemetry.record_queued_move(true, false)
	else:
		_pending_undo_snapshot.clear()
		EventBus.swap_rejected.emit(from, to)
		telemetry.record_queued_move(false, false)

func _on_cfe_matches_detected(matches: Array[MatchShapeResult]) -> void:
	var matches_dict: Array[Dictionary] = []
	for m in matches:
		var m_dict := {
			"piece_id": board_state_engine.get_piece(m.cells[0]) if not m.cells.is_empty() else 0,
			"cells": m.cells,
			"length": m.cells.size(),
			"match_type": m.shape_type
		}
		matches_dict.append(m_dict)
		
		# Записываем телеметрию
		telemetry.record_special_created()
		
		# Подсчет очков и целей
		score_system.add_match_score(m.cells.size())
		goal_tracker.process_match(m_dict)
		
	goal_tracker.process_score(score_system.score)
	EventBus.match_resolved.emit(matches_dict)
	_emit_status_updates()

func _on_cfe_gravity_applied(movements: Array[Dictionary], spawns: Array[Dictionary]) -> void:
	EventBus.board_collapsed.emit(movements)
	EventBus.pieces_generated.emit(spawns)
	score_system.increment_cascade()
	EventBus.cascade_completed.emit(score_system.cascade_depth)

func _on_cfe_combo_updated(combo_count: int, fever_active: bool) -> void:
	telemetry.record_combo(combo_count)
	if fever_active:
		telemetry.record_fever_activated()
	
	# Транслируем события комбо и Fever
	EventBus.combo_window_updated.emit(combo_controller.combo_window_remaining, combo_count)
	if fever_active:
		EventBus.fever_activated.emit(combo_controller.fever_duration, combo_controller.score_multiplier_fever)
	_emit_status_updates()

func _on_cfe_pipeline_stabilized() -> void:
	score_system.reset_cascade()
	EventBus.turn_finished.emit()
	if _check_end_conditions():
		return
	_emit_status_updates()
