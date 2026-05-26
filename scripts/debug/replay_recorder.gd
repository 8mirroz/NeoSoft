# /Users/user/3-line/scripts/debug/replay_recorder.gd
class_name ReplayRecorder
extends RefCounted

## Записывает ход игры (seed, входы игрока, снапшоты, метаданные каскадов)
## и экспортирует в формат JSON.

var current_replay: Dictionary = {}
var is_recording: bool = false
var turn_counter: int = 0
var current_turn_moves: Array = []

func start_recording(level_id: String, difficulty: String, seed_val: int, initial_board: BoardSnapshot) -> void:
	current_replay = {
		"protocol_version": "5.1",
		"level_id": level_id,
		"difficulty_profile": difficulty,
		"initial_seed": seed_val,
		"board_dimensions": {
			"width": initial_board.width,
			"height": initial_board.height
		},
		"initial_board_snapshot": initial_board.serialize(),
		"player_moves": [],
		"final_summary": {}
	}
	is_recording = true
	turn_counter = 0
	current_turn_moves.clear()
	
	# Подписываемся на события шины
	GameEventBus.swap_resolved.connect(_on_swap_resolved)
	GameEventBus.input_queued.connect(_on_input_queued)

func record_move(swipe_from: Vector2i, swipe_to: Vector2i) -> void:
	if not is_recording:
		return
	
	var move_record = {
		"turn_index": turn_counter,
		"swipe_from": {"x": swipe_from.x, "y": swipe_from.y},
		"swipe_to": {"x": swipe_to.x, "y": swipe_to.y},
		"queued_inputs_during_turn": [],
		"expected_score_gained": 0,
		"expected_final_board_hash": ""
	}
	current_replay["player_moves"].append(move_record)
	turn_counter += 1

func _on_swap_resolved(from_cell: Vector2i, to_cell: Vector2i) -> void:
	# Фиксируем успешный ход
	pass

func _on_input_queued(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if not is_recording or current_replay["player_moves"].is_empty():
		return
	# Добавляем в последний ход буферизованный ввод
	var last_move = current_replay["player_moves"][-1]
	last_move["queued_inputs_during_turn"].append({
		"swipe_from": {"x": from_cell.x, "y": from_cell.y},
		"swipe_to": {"x": to_cell.x, "y": to_cell.y},
		"delay_msec": 0 # Упрощенно
	})

func finish_recording(won: bool, final_score: int, stars: int, moves_left: int) -> Dictionary:
	if not is_recording:
		return {}
	
	current_replay["final_summary"] = {
		"total_score": final_score,
		"stars_earned": stars,
		"moves_remaining": moves_left,
		"result": "won" if won else "lost"
	}
	
	is_recording = false
	
	# Отписываемся от событий
	if GameEventBus.swap_resolved.is_connected(_on_swap_resolved):
		GameEventBus.swap_resolved.disconnect(_on_swap_resolved)
	if GameEventBus.input_queued.is_connected(_on_input_queued):
		GameEventBus.input_queued.disconnect(_on_input_queued)
		
	return current_replay

func save_to_file(path: String) -> Error:
	var json_str = JSON.stringify(current_replay, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(json_str)
	file.close()
	return OK
