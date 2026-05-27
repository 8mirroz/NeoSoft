extends Node

const BOOT_SCENE := "res://scenes/boot/boot.tscn"
const MENU_SCENE := "res://scenes/menus/main_menu.tscn"
const LOADING_SCENE := "res://scenes/boot/loading_screen.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/menus/world_map.tscn"
const LEVEL_PREVIEW_SCENE := "res://scenes/menus/level_preview.tscn"
const GAMEPLAY_SCENE := "res://scenes/gameplay/gameplay.tscn"

const SAVE_PATH := "user://save_data.cfg"
const SAVE_BACKUP_PATH := "user://save_data.cfg.smoke_backup"
const ANALYTICS_BACKUP_PATH := "user://analytics_events.jsonl.smoke_backup"

const WAIT_STEP_SEC := 0.05

var _analytics_log_path: String = "user://analytics_events.jsonl"
var _had_original_save: bool = false
var _had_original_analytics: bool = false

func _ready() -> void:
	if not _is_smoke_mode():
		return
	await _run_smoke()

func _run_smoke() -> void:
	var checkpoints: Array[String] = []
	var ok := true
	var failure_message := ""

	if not _prepare_runtime_backup():
		ok = false
		failure_message = "Failed to back up runtime files from user://"
	else:
		var result := await _execute_smoke(checkpoints)
		ok = result["ok"]
		failure_message = result["failure"]

	var restore_ok := _restore_runtime_files()
	if not restore_ok and ok:
		ok = false
		failure_message = "Smoke scenarios passed but restore failed"

	if ok:
		print("SOFT LAUNCH SMOKE PASSED")
		print("CHECKPOINTS: %s" % ", ".join(checkpoints))
		get_tree().quit(0)
		return

	push_error("SOFT LAUNCH SMOKE FAILED: %s" % failure_message)
	get_tree().quit(1)

func _execute_smoke(checkpoints: Array[String]) -> Dictionary:
	if not _seed_clean_state():
		return _fail("Unable to seed clean UserData/analytics state")
	checkpoints.append("seed_clean_state")

	var menu_scene := await _verify_boot_to_menu()
	if menu_scene == null:
		return _fail("Boot did not transition to main menu")
	checkpoints.append("boot_to_menu")

	var level_select := await _verify_menu_to_level_select(menu_scene)
	if level_select == null:
		return _fail("Main menu play action did not open level select")
	checkpoints.append("menu_to_level_select")

	var gameplay := await _verify_level_select_to_gameplay(level_select)
	if gameplay == null:
		return _fail("Level select did not open gameplay")
	checkpoints.append("level_select_to_gameplay")

	if not await _verify_pause_resume(gameplay):
		return _fail("Pause/resume smoke check failed")
	checkpoints.append("pause_resume")

	if not await _verify_invalid_swap_rejected(gameplay):
		return _fail("Invalid swap reject check failed")
	checkpoints.append("invalid_swap_reject")

	if not await _verify_valid_move_and_undo(gameplay):
		return _fail("Undo smoke check failed")
	checkpoints.append("undo")

	if not await _verify_dead_board_recovery(gameplay):
		return _fail("Dead-board recovery check failed")
	checkpoints.append("dead_board_recovery")

	if not await _verify_input_blocking_during_vfx(gameplay):
		return _fail("Input blocking during VFX check failed")
	checkpoints.append("input_blocking_during_vfx")

	var retry_ok := await _verify_retry_path(gameplay)
	if not retry_ok["ok"]:
		return _fail(String(retry_ok["failure"]))
	gameplay = retry_ok["gameplay"]
	checkpoints.append("retry_flow")

	var level_select_after_return := await _verify_return_to_level_select(gameplay)
	if level_select_after_return == null:
		return _fail("Return to level select flow failed")
	checkpoints.append("return_to_level_select")

	if not _verify_unlock_and_persistence():
		return _fail("Unlock/persistence checks failed")
	checkpoints.append("unlock_and_persistence")

	if not _verify_logs_exporter():
		return _fail("Telemetry and CSAT log exporter check failed")
	checkpoints.append("logs_exporter")

	if not await _verify_telemetry_baseline([
		"session_started",
		"level_started",
		"undo_used",
		"level_retry_requested",
		"return_to_level_select",
		"dead_board_detected",
		"auto_shuffle_applied",
	]):
		return _fail("Telemetry baseline is missing expected events")
	checkpoints.append("telemetry")

	return {"ok": true, "failure": ""}

func _verify_boot_to_menu() -> Control:
	await _wait_for_frames(1)
	var err := get_tree().change_scene_to_file(BOOT_SCENE)
	if err != OK:
		return null
	var loading := await _await_scene(LOADING_SCENE, 2.5)
	if loading == null or not loading.has_method("_on_start_pressed"):
		return null
	loading.call("_on_start_pressed")
	return await _await_scene(MENU_SCENE, 4.5)

func _verify_menu_to_level_select(menu_scene: Control) -> Control:
	if not menu_scene.has_method("_on_play_pressed"):
		return null
	menu_scene.call("_on_play_pressed")
	return await _await_scene(LEVEL_SELECT_SCENE, 2.5)

func _verify_level_select_to_gameplay(level_select: Control) -> Control:
	if not level_select.has_method("_open_level_preview"):
		return null
	level_select.call("_open_level_preview", 1)
	var preview := await _await_scene(LEVEL_PREVIEW_SCENE, 2.5)
	if preview == null or not preview.has_method("_start_level"):
		return null
	preview.call("_start_level")
	var gameplay := await _await_scene(GAMEPLAY_SCENE, 3.0)
	if gameplay == null:
		return null
	await _wait_for_frames(3)
	return gameplay

func _verify_pause_resume(gameplay: Control) -> bool:
	if not gameplay.has_method("_on_pause_pressed"):
		return false
	var session: LevelSession = gameplay.level_session
	if session == null:
		return false

	gameplay.call("_on_pause_pressed")
	await _wait_for_frames(2)
	if not bool(session.get("session_paused")):
		return false

	gameplay.call("_on_pause_pressed")
	await _wait_for_frames(2)
	if bool(session.get("session_paused")):
		return false

	return true

func _verify_valid_move_and_undo(gameplay: Control) -> bool:
	if not gameplay.has_method("_on_undo_pressed"):
		return false
	var event_bus := _event_bus()
	if event_bus == null:
		return false
	var session: LevelSession = gameplay.level_session
	if session == null:
		return false
	var board_controller: BoardController = session.board_controller
	if board_controller == null:
		return false

	var hint: Array[Vector2i] = HintSystem.find_hint(board_controller.board, board_controller.match_system)
	if hint.size() < 2:
		return false

	event_bus.gem_tapped.emit(hint[0])
	await _wait_for_frames(1)
	event_bus.gem_tapped.emit(hint[1])
	if not await _wait_until(func() -> bool: return session.has_undo_available(), 1.8):
		return false

	gameplay.call("_on_undo_pressed")
	if not await _wait_until(func() -> bool: return not session.has_undo_available(), 1.8):
		return false

	return true

func _verify_invalid_swap_rejected(gameplay: Control) -> bool:
	var event_bus := _event_bus()
	if event_bus == null:
		return false
	var session: LevelSession = gameplay.level_session
	if session == null or session.board_controller == null:
		return false

	var invalid_swap := _find_invalid_adjacent_swap(session.board_controller)
	if invalid_swap.is_empty():
		return false

	var moves_before: int = session.move_counter.moves_used
	var undo_before := session.has_undo_available()

	event_bus.gem_tapped.emit(invalid_swap[0])
	await _wait_for_frames(1)
	event_bus.gem_tapped.emit(invalid_swap[1])
	await _wait_for_frames(3)

	if session.move_counter.moves_used != moves_before:
		return false
	if session.has_undo_available() != undo_before:
		return false
	return true

func _verify_dead_board_recovery(gameplay: Control) -> bool:
	var session: LevelSession = gameplay.level_session
	if session == null:
		return false
	var board_controller: BoardController = session.board_controller
	if board_controller == null:
		return false

	_force_no_moves_layout(board_controller)
	if board_controller.has_valid_moves():
		return false
	if not board_controller.match_system.find_matches(board_controller.board).is_empty():
		return false

	if not session.has_method("_ensure_playable_board"):
		return false
	session.call("_ensure_playable_board", "smoke_dead_board")
	await _wait_for_frames(2)

	if not board_controller.has_valid_moves():
		return false

	return true

func _verify_retry_path(gameplay: Control) -> Dictionary:
	if not gameplay.has_method("_retry_level"):
		return _fail("Gameplay script has no _retry_level method")
	var user_data := _user_data()
	if user_data == null:
		return _fail("UserData autoload is missing")

	var retries_before := int(user_data.total_retries)
	gameplay.call("_retry_level")
	var retried_gameplay := await _await_scene(GAMEPLAY_SCENE, 3.0)
	if retried_gameplay == null:
		return _fail("Retry flow did not return to gameplay scene")
	await _wait_for_frames(2)

	if int(user_data.total_retries) != retries_before + 1:
		return _fail("Retry flow did not increment total_retries")

	return {
		"ok": true,
		"failure": "",
		"gameplay": retried_gameplay,
	}

func _verify_return_to_level_select(gameplay: Control) -> Control:
	if not gameplay.has_method("_go_to_level_select"):
		return null
	gameplay.call("_go_to_level_select")
	return await _await_scene(LEVEL_SELECT_SCENE, 3.0)

func _verify_unlock_and_persistence() -> bool:
	var user_data := _user_data()
	if user_data == null:
		return false
	user_data.unlocked_level = 1
	user_data.active_level = 1
	user_data.level_stars.clear()
	user_data.level_scores.clear()
	user_data.total_sessions = maxi(user_data.total_sessions, 0)
	user_data.total_retries = maxi(user_data.total_retries, 0)
	user_data.coins = maxi(user_data.coins, 0)

	user_data.complete_level(1, 1800, 2)
	if int(user_data.unlocked_level) < 2:
		return false

	var expected_unlocked := int(user_data.unlocked_level)
	var expected_active := int(user_data.active_level)
	var expected_sessions := int(user_data.total_sessions)
	var expected_retries := int(user_data.total_retries)
	var expected_coins := int(user_data.coins)

	user_data.save_data()

	user_data.unlocked_level = 1
	user_data.active_level = 99
	user_data.total_sessions = 0
	user_data.total_retries = 0
	user_data.coins = 0

	user_data.load_data()

	if int(user_data.unlocked_level) != expected_unlocked:
		return false
	if int(user_data.active_level) != expected_active:
		return false
	if int(user_data.total_sessions) != expected_sessions:
		return false
	if int(user_data.total_retries) != expected_retries:
		return false
	if int(user_data.coins) != expected_coins:
		return false

	return true

func _verify_telemetry_baseline(required_events: Array[String]) -> bool:
	await _wait_for_frames(2)
	if not FileAccess.file_exists(_analytics_log_path):
		return false

	var file := FileAccess.open(_analytics_log_path, FileAccess.READ)
	if file == null:
		return false

	var found: Dictionary = {}
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var json := JSON.new()
		if json.parse(line) != OK:
			continue
		var payload: Dictionary = json.data
		var event_name := String(payload.get("event_name", ""))
		if not event_name.is_empty():
			found[event_name] = true
	file.close()

	for event_name in required_events:
		if not bool(found.get(event_name, false)):
			return false
	return true

func _seed_clean_state() -> bool:
	var user_data := _user_data()
	if user_data == null:
		return false
	var config := LevelLoader.load_soft_launch_config()
	var analytics_cfg: Dictionary = config.get("analytics", {})
	_analytics_log_path = String(analytics_cfg.get("log_path", "user://analytics_events.jsonl"))
	_had_original_analytics = FileAccess.file_exists(_analytics_log_path)

	if FileAccess.file_exists(_analytics_log_path):
		if not _remove_file(_analytics_log_path):
			return false

	user_data.unlocked_level = 1
	user_data.level_stars.clear()
	user_data.level_scores.clear()
	user_data.active_level = 1
	user_data.coins = 1000
	user_data.booster_inventory = {
		"hammer": 3,
		"shuffle": 3,
		"undo": 3,
	}
	user_data.daily_streak = 0
	user_data.last_played_on = ""
	user_data.total_sessions = 0
	user_data.total_retries = 0
	user_data.last_failure_streak = 0
	user_data.quality_profile = "web_default"
	user_data.sound_enabled = true
	user_data.music_enabled = true
	user_data.save_data()
	return true

func _prepare_runtime_backup() -> bool:
	_had_original_save = FileAccess.file_exists(SAVE_PATH)
	if _had_original_save:
		if not _copy_file(SAVE_PATH, SAVE_BACKUP_PATH):
			return false

	var config := LevelLoader.load_soft_launch_config()
	var analytics_cfg: Dictionary = config.get("analytics", {})
	_analytics_log_path = String(analytics_cfg.get("log_path", "user://analytics_events.jsonl"))
	_had_original_analytics = FileAccess.file_exists(_analytics_log_path)
	if _had_original_analytics:
		if not _copy_file(_analytics_log_path, ANALYTICS_BACKUP_PATH):
			return false

	return true

func _restore_runtime_files() -> bool:
	var ok := true

	if _had_original_save:
		ok = _copy_file(SAVE_BACKUP_PATH, SAVE_PATH) and ok
	else:
		ok = _remove_file(SAVE_PATH) and ok
	ok = _remove_file(SAVE_BACKUP_PATH) and ok

	if _had_original_analytics:
		ok = _copy_file(ANALYTICS_BACKUP_PATH, _analytics_log_path) and ok
	else:
		ok = _remove_file(_analytics_log_path) and ok
	ok = _remove_file(ANALYTICS_BACKUP_PATH) and ok

	return ok

func _copy_file(source_path: String, destination_path: String) -> bool:
	if not FileAccess.file_exists(source_path):
		return false
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return false
	var bytes := source.get_buffer(source.get_length())
	source.close()

	var target := FileAccess.open(destination_path, FileAccess.WRITE)
	if target == null:
		return false
	target.store_buffer(bytes)
	target.close()
	return true

func _remove_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

func _find_invalid_adjacent_swap(board_controller: BoardController) -> Array[Vector2i]:
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
	var board: BoardModel = board_controller.board
	var match_system: MatchSystem = board_controller.match_system

	for y in range(board.height):
		for x in range(board.width):
			var from_cell := Vector2i(x, y)
			if board.get_piece(from_cell) < 0:
				continue
			for direction in directions:
				var to_cell := from_cell + direction
				if not board.is_in_bounds(to_cell):
					continue
				if board.get_piece(to_cell) < 0:
					continue

				board.swap_pieces(from_cell, to_cell)
				var matches: Array[Dictionary] = match_system.find_matches(board)
				board.swap_pieces(from_cell, to_cell)
				if matches.is_empty():
					return [from_cell, to_cell]

	var empty: Array[Vector2i] = []
	return empty

func _force_no_moves_layout(board_controller: BoardController) -> void:
	var kinds := maxi(board_controller.piece_kinds, 1)
	for y in range(board_controller.board.height):
		for x in range(board_controller.board.width):
			board_controller.board.set_piece(Vector2i(x, y), (x + y) % kinds)

func _await_scene(scene_path: String, timeout_sec: float) -> Control:
	var elapsed := 0.0
	while elapsed <= timeout_sec:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == scene_path:
			return scene
		await get_tree().create_timer(WAIT_STEP_SEC).timeout
		elapsed += WAIT_STEP_SEC
	return null

func _wait_for_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func _wait_until(predicate: Callable, timeout_sec: float) -> bool:
	var elapsed := 0.0
	while elapsed <= timeout_sec:
		if predicate.call():
			return true
		await get_tree().create_timer(WAIT_STEP_SEC).timeout
		elapsed += WAIT_STEP_SEC
	return false

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")

func _user_data() -> Node:
	return get_tree().root.get_node_or_null("UserData")

func _fail(message: String) -> Dictionary:
	return {
		"ok": false,
		"failure": message,
	}

func _is_smoke_mode() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == "--smoke-soft-launch":
			return true
	return false

func _verify_input_blocking_during_vfx(gameplay: Control) -> bool:
	var event_bus := _event_bus()
	if event_bus == null:
		return false
	var session: LevelSession = gameplay.level_session
	var board_visual: BoardView = gameplay.board_visual
	
	var hint: Array[Vector2i] = HintSystem.find_hint(session.board_controller.board, session.board_controller.match_system)
	if hint.size() < 2:
		return false
		
	event_bus.gem_tapped.emit(hint[0])
	await _wait_for_frames(1)
	event_bus.gem_tapped.emit(hint[1])
	await _wait_for_frames(1)
	
	if not board_visual._has_active_effects():
		return false
		
	if board_visual.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return false
		
	var other_cell := Vector2i(0, 0) if hint[0] != Vector2i(0, 0) else Vector2i(1, 1)
	gameplay.call("_on_board_cell_pressed", other_cell)
	await _wait_for_frames(1)
	
	if board_visual.selected_cell == other_cell:
		return false
		
	if not await _wait_until(func() -> bool: return not board_visual._has_active_effects(), 2.5):
		return false
		
	if board_visual.mouse_filter != Control.MOUSE_FILTER_STOP:
		return false
		
	return true

func _verify_logs_exporter() -> bool:
	var user_data := _user_data()
	if user_data == null:
		return false
		
	user_data.call("save_feedback", 9, 5, "Fabulous experience!")
	
	var logs_json: String = user_data.call("get_formatted_test_logs")
	if logs_json.is_empty():
		return false
		
	var json := JSON.new()
	if json.parse(logs_json) != OK:
		return false
		
	var data: Dictionary = json.data
	if not data.has("device_info") or not data.has("visual_settings") or not data.has("csat_feedback") or not data.has("analytics_events"):
		return false
		
	var csat: Dictionary = data.get("csat_feedback", {})
	if not csat.has("9") or int(csat["9"].get("rating")) != 5 or csat["9"].get("comment") != "Fabulous experience!":
		return false
		
	return true
