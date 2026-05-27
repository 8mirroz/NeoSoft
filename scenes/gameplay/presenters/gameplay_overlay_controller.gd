extends RefCounted
class_name GameplayOverlayController

const PauseScene := preload("res://scenes/gameplay/pause_menu.tscn")
const CompleteScene := preload("res://scenes/gameplay/level_complete.tscn")
const MovesScene := preload("res://scenes/gameplay/out_of_moves.tscn")

var _scene: Control
var _refs: GameplayNodeRefs
var active_overlay: Control = null

func setup(scene: Control, refs: GameplayNodeRefs) -> void:
	_scene = scene
	_refs = refs

func initialize_overlays() -> void:
	# Overlays are now modularly instantiated. Main scene bindings occur dynamically.
	pass

func open_overlay(mode: String, title: String, body: String, primary_text: String, secondary_text: String, tertiary_text: String) -> void:
	hide_overlay()
	_scene.overlay_mode = mode
	
	if mode == "pause":
		var inst := PauseScene.instantiate()
		_scene.add_child(inst)
		inst.resume_requested.connect(_scene._resume_session)
		inst.restart_requested.connect(_scene._retry_level)
		inst.home_requested.connect(_scene._go_to_level_select)
		active_overlay = inst
		
	elif mode == "win":
		var inst := CompleteScene.instantiate()
		_scene.add_child(inst)
		inst.next_level_requested.connect(_scene._on_overlay_primary_pressed)
		inst.share_requested.connect(_scene._share_result)
		inst.home_requested.connect(_scene._go_to_level_select)
		
		# Build payload for score rollout and stars
		var payload: Dictionary = _scene.overlay_payload.duplicate(true)
		payload["is_new_best"] = bool(payload.get("is_new_best", false))
		payload["coins_won"] = int(payload.get("coins_won", 250))
		payload["stars_won"] = int(payload.get("stars_won", 3))
		inst.setup_data(payload)
		
		active_overlay = inst
		
	elif mode == "lose":
		var inst := MovesScene.instantiate()
		_scene.add_child(inst)
		inst.retry_requested.connect(_scene._retry_level)
		inst.add_moves_requested.connect(_scene._continue_with_extra_moves)
		inst.home_requested.connect(_scene._go_to_level_select)
		
		# Binds targets checklists and coin costs
		inst.setup_data(_scene.current_goals, UserData.get_extra_moves_cost())
		
		active_overlay = inst
		
	if _scene.get("pause_button") != null:
		_scene.pause_button.text = "Resume" if mode == "pause" else "Pause"

func hide_overlay() -> void:
	_scene.overlay_mode = ""
	if active_overlay != null and is_instance_valid(active_overlay):
		active_overlay.queue_free()
	active_overlay = null
	if _scene.get("pause_button") != null:
		_scene.pause_button.text = "Pause"

func build_retention_line() -> String:
	var summary: Dictionary = UserData.get_retention_summary()
	return "Streak %d day(s) • %d levels cleared • %d 🪙" % [
		int(summary.get("daily_streak", 0)),
		int(summary.get("completed_levels", 0)),
		UserData.coins
	]
