extends RefCounted
class_name GameplayCFEController

var _scene: Control
var _session: Node
var _board: Control

var combo_ring: ComboWindowRing
var fever_overlay: FeverOverlay

func setup(scene: Control, session: Node, board: Control) -> void:
	_scene = scene
	_session = session
	_board = board

func initialize_cfe() -> void:
	if not _session.get("fever_mode_enabled"):
		return
		
	combo_ring = ComboWindowRing.new()
	var parent_node: Node = null
	if _scene.has_node("BoardArea/BoardFrame/BoardPadding"):
		parent_node = _scene.get_node("BoardArea/BoardFrame/BoardPadding")
	else:
		parent_node = _board
		
	if parent_node != null:
		parent_node.add_child(combo_ring)
	combo_ring.size = _board.size
	
	fever_overlay = FeverOverlay.new()
	_scene.add_child(fever_overlay)
	fever_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	EventBus.combo_window_opened.connect(_on_combo_window_opened)
	EventBus.combo_window_updated.connect(_on_combo_window_updated)
	EventBus.combo_expired.connect(_on_combo_expired)
	EventBus.fever_activated.connect(_on_fever_activated)
	EventBus.fever_expired.connect(_on_fever_expired)

func _on_combo_window_opened(duration: float) -> void:
	if combo_ring != null:
		combo_ring.setup_combo(duration)
		
	# Switch InputRouter to LIVE_COMBO mode
	var input_router: RefCounted = _scene.get("input_router")
	if input_router != null:
		input_router.set("mode", 2) # LIVE_COMBO enum

func _on_combo_window_updated(remaining: float, chain: int) -> void:
	if combo_ring != null:
		combo_ring.update_combo(remaining, chain)
		
	var tier := _resolve_intensity_tier(chain)
	EventBus.emit_signal("combo_intensity_changed", tier)

func _on_combo_expired() -> void:
	if combo_ring != null:
		combo_ring.expire()
		
	# Switch InputRouter to NORMAL mode
	var input_router: RefCounted = _scene.get("input_router")
	if input_router != null:
		input_router.set("mode", 0) # NORMAL enum

func _on_fever_activated(duration: float, _multiplier: float) -> void:
	if fever_overlay != null:
		fever_overlay.activate(duration)

func _on_fever_expired() -> void:
	if fever_overlay != null:
		fever_overlay.deactivate()

func _resolve_intensity_tier(chain: int) -> String:
	if chain >= 12:
		return "MYTHIC"
	if chain >= 8:
		return "EPIC"
	if chain >= 5:
		return "RARE"
	if chain >= 3:
		return "BOOSTED"
	return "BASE"
