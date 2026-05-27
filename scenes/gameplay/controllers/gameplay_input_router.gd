extends RefCounted
class_name GameplayInputRouter

enum InputMode {
	NORMAL,
	SOFT_LOCK,
	LIVE_COMBO,
	HARD_LOCK,
	BOOSTER_TARGETING,
	PAUSED,
	FINISHED
}

var _scene: Control
var _session: Node # LevelSession
var _board: Control # BoardView
var mode: InputMode = InputMode.NORMAL
var pending_moves: Array[Vector2i] = []
var max_pending_moves: int = 2

func setup(scene: Control, session: Node, board: Control) -> void:
	_scene = scene
	_session = session
	_board = board

func on_cell_pressed(cell: Vector2i) -> void:
	if _scene.get("session_finished") or _scene.get("session_paused"):
		return
		
	if mode == InputMode.HARD_LOCK or mode == InputMode.PAUSED or mode == InputMode.FINISHED:
		return

	if mode == InputMode.BOOSTER_TARGETING or _scene.get("hammer_mode"):
		var boosters: RefCounted = _scene.get("boosters")
		if boosters != null and boosters.has_method("apply_hammer_booster"):
			boosters.call("apply_hammer_booster", cell)
		return

	if mode == InputMode.LIVE_COMBO:
		_try_queue_live_combo_input(cell)
		return

	# Normal tap behavior
	EventBus.gem_tapped.emit(cell)

func _try_queue_live_combo_input(cell: Vector2i) -> void:
	if pending_moves.size() >= max_pending_moves:
		return

	pending_moves.append(cell)

func process_pending_queue() -> void:
	if pending_moves.is_empty():
		return
	
	var cell: Vector2i = pending_moves.pop_front()
	EventBus.gem_tapped.emit(cell)
