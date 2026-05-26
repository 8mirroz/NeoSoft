# /Users/user/3-line/scripts/debug/replay_player.gd
class_name ReplayPlayer
extends RefCounted

## Загружает и воспроизводит сохраненные JSON-реплеи на игровой логике.
## Используется для регрессионного автоматического тестирования и MCTS валидации.

var replay_data: Dictionary = {}
var is_playing: bool = false
var current_move_index: int = 0

signal replay_step_completed(turn_index: int)
signal replay_finished(desync_error: bool, reason: String)

func _emit_game_event(signal_name: String, arg1: Variant = null, arg2: Variant = null) -> void:
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return
	var bus := (loop as SceneTree).root.get_node_or_null("GameEventBus")
	if bus == null or not bus.has_signal(signal_name):
		return
	if arg1 == null and arg2 == null:
		bus.emit_signal(signal_name)
	elif arg2 == null:
		bus.emit_signal(signal_name, arg1)
	else:
		bus.emit_signal(signal_name, arg1, arg2)

func load_replay_file(path: String) -> Error:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return FileAccess.get_open_error()
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_err = json.parse(json_str)
	if parse_err != OK:
		return ERR_PARSE_ERROR
		
	replay_data = json.data
	return OK

func start_replay(board_logic_node: Node, drop_rng_node: Node) -> void:
	if replay_data.is_empty():
		emit_signal("replay_finished", true, "Replay data is empty")
		return
	
	is_playing = true
	current_move_index = 0
	
	# 1. Замораживаем сид генератора
	var seed_val = replay_data.get("initial_seed", 42)
	if drop_rng_node and drop_rng_node.has_method("reset_seed"):
		drop_rng_node.reset_seed(seed_val)
	
	# 2. Инициализируем доску из снапшота
	var snapshot_data = replay_data.get("initial_board_snapshot", {})
	var snapshot = BoardSnapshot.new()
	snapshot.deserialize(snapshot_data)
	
	if board_logic_node and board_logic_node.has_method("load_snapshot"):
		board_logic_node.load_snapshot(snapshot)
	
	_play_next_step(board_logic_node)

func _play_next_step(board_logic_node: Node) -> void:
	var moves = replay_data.get("player_moves", [])
	if current_move_index >= moves.size():
		is_playing = false
		emit_signal("replay_finished", false, "All moves replayed successfully")
		return
	
	var move = moves[current_move_index]
	var from_cell = Vector2i(move.swipe_from.x, move.swipe_from.y)
	var to_cell = Vector2i(move.swipe_to.x, move.swipe_to.y)
	
	# Эмулируем свайп
	_emit_game_event("swap_requested", from_cell, to_cell)
	
	# Симулируем буферизованные ввода (с задержкой или сразу)
	var queued_inputs = move.get("queued_inputs_during_turn", [])
	for qi in queued_inputs:
		var q_from = Vector2i(qi.swipe_from.x, qi.swipe_from.y)
		var q_to = Vector2i(qi.swipe_to.x, qi.swipe_to.y)
		_emit_game_event("input_queued", q_from, q_to)
		
	current_move_index += 1
	emit_signal("replay_step_completed", current_move_index)
	
	# Запускаем следующий ход (обычно подвязывается под сигнал turn_finished от ResolvePipeline)
	# В тестах мы вызываем его последовательно.
