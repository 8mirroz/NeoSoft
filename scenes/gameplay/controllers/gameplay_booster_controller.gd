extends RefCounted
class_name GameplayBoosterController

var _scene: Control
var _session: Node
var _board: Control
var _refs: GameplayNodeRefs

const BOOSTER_PRICES := {
	"shuffle": 150,
	"hammer": 250,
	"undo": 200
}

func setup(scene: Control, session: Node, board: Control, refs: GameplayNodeRefs) -> void:
	_scene = scene
	_session = session
	_board = board
	_refs = refs

func request_shuffle() -> void:
	if _scene.get("session_finished") or _scene.get("session_paused"):
		return
		
	var count := UserData.get_booster_count("shuffle")
	if count <= 0:
		if UserData.buy_booster("shuffle", BOOSTER_PRICES["shuffle"]):
			_scene.call("_show_status", "Bought Shuffle for 150 🪙!", false, 0.9)
			_scene.call("_refresh_booster_styles")
		else:
			_scene.call("_show_status", "Not enough coins! Need 150 🪙.", true, 0.9)
			return

	if UserData.use_booster("shuffle"):
		EventBus.booster_activated.emit(GameConstants.BoosterType.SHUFFLE, Vector2i(-1, -1))
		_board.call("refresh")
		_scene.call("_show_status", "Field reshuffled.", false, 0.9)
		_scene.call("_refresh_booster_styles")

func toggle_hammer_mode() -> void:
	if _scene.get("session_finished") or _scene.get("session_paused"):
		return
		
	var active: bool = not _scene.get("hammer_mode")
	if active:
		var count := UserData.get_booster_count("hammer")
		if count <= 0:
			if UserData.buy_booster("hammer", BOOSTER_PRICES["hammer"]):
				_scene.call("_show_status", "Bought Hammer for 250 🪙!", false, 0.9)
				_scene.call("_refresh_booster_styles")
			else:
				_scene.call("_show_status", "Not enough coins! Need 250 🪙.", true, 0.9)
				return
		
		_scene.set("hammer_mode", true)
		_board.call("set_hammer_targeting", true)
		_scene.call("_show_status", "Select one orb to break.", false, 0.9)
	else:
		_scene.set("hammer_mode", false)
		_board.call("set_hammer_targeting", false)
		_scene.call("_show_status", "Hammer cancelled.", false, 0.75)
		
	_scene.call("_refresh_booster_styles")

func apply_hammer_booster(cell: Vector2i) -> void:
	if UserData.use_booster("hammer"):
		EventBus.booster_activated.emit(GameConstants.BoosterType.HAMMER, cell)
		_board.call("refresh")
		_scene.set("hammer_mode", false)
		_board.call("set_hammer_targeting", false)
		_scene.call("_show_status", "Hammer activated.", false, 0.9)
		_scene.call("_refresh_booster_styles")
	else:
		_scene.set("hammer_mode", false)
		_board.call("set_hammer_targeting", false)
		_scene.call("_show_status", "No Hammers left!", true, 0.9)
		_scene.call("_refresh_booster_styles")

func request_undo() -> void:
	if _scene.get("session_finished") or _scene.get("session_paused"):
		return
	if not _session.call("has_undo_available"):
		_scene.call("_show_status", "Nothing to undo yet.", true, 0.9)
		return
		
	var count := UserData.get_booster_count("undo")
	if count <= 0:
		if UserData.buy_booster("undo", BOOSTER_PRICES["undo"]):
			_scene.call("_show_status", "Bought Undo for 200 🪙!", false, 0.9)
			_scene.call("_refresh_booster_styles")
		else:
			_scene.call("_show_status", "Not enough coins! Need 200 🪙.", true, 0.9)
			return

	if UserData.use_booster("undo"):
		EventBus.booster_activated.emit(GameConstants.BoosterType.UNDO, Vector2i(-1, -1))
		_scene.call("_show_status", "Previous state restored.", false, 0.92)
		_scene.call("_refresh_booster_styles")
