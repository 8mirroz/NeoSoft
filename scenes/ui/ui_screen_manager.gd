extends CanvasLayer

## Single navigation entry point for all user-facing UI screens.

const ROUTES: Dictionary = {
	&"loading": "res://scenes/boot/loading_screen.tscn",
	&"main_menu": "res://scenes/menus/main_menu.tscn",
	&"world_map": "res://scenes/menus/world_map.tscn",
	&"level_select": "res://scenes/menus/world_map.tscn",
	&"level_preview": "res://scenes/menus/level_preview.tscn",
	&"gameplay": "res://scenes/gameplay/gameplay.tscn",
	&"daily_rewards": "res://scenes/menus/daily_rewards.tscn",
	&"shop": "res://scenes/menus/shop.tscn",
	&"rankings": "res://scenes/menus/rankings.tscn",
	&"collection": "res://scenes/menus/collection.tscn",
	&"friends": "res://scenes/menus/friends.tscn",
	&"inbox": "res://scenes/menus/inbox.tscn",
}

var current_quality: String = "HIGH"
var current_screen: StringName = &""
var current_payload: Dictionary = {}
var _history: Array[StringName] = []
var _transition_layer: ColorRect
var _navigating: bool = false
var _queued_screen: StringName = &""
var _queued_payload: Dictionary = {}
var _queued_transition: StringName = &"fade"

func _ready() -> void:
	layer = 100
	var tokens := get_tree().root.get_node_or_null("ThemeTokensAutoload")
	if tokens != null:
		current_quality = String(tokens.performance_value("shader_quality", "HIGH"))
	_build_transition_layer()
	apply_quality_profile(current_quality)

func apply_quality_profile(profile: String) -> void:
	current_quality = profile

func navigate(screen_id: StringName, screen_payload: Dictionary = {}, transition: StringName = &"fade") -> void:
	if _navigating:
		_queued_screen = screen_id
		_queued_payload = screen_payload.duplicate(true)
		_queued_transition = transition
		return
	var path := route_path(screen_id)
	if path.is_empty():
		push_error("UIScreenManager: unknown route '%s'" % String(screen_id))
		return
	if not ResourceLoader.exists(path):
		push_error("UIScreenManager: route scene not found at %s" % path)
		return
	if current_screen != &"" and current_screen != screen_id:
		_history.append(current_screen)
	current_screen = screen_id
	current_payload = screen_payload.duplicate(true)
	_navigating = true
	if transition == &"none":
		_change_scene.call_deferred(path)
		return
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.tween_property(_transition_layer, "color:a", 1.0, 0.16)
	tween.tween_callback(_change_scene.bind(path))

func back() -> void:
	if _history.is_empty():
		navigate(&"main_menu")
		return
	var previous: StringName = _history.pop_back()
	var path := route_path(previous)
	if path.is_empty() or not ResourceLoader.exists(path):
		navigate(&"main_menu")
		return
	current_screen = previous
	current_payload = {}
	_navigating = true
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.tween_property(_transition_layer, "color:a", 1.0, 0.16)
	tween.tween_callback(_change_scene.bind(path))

func payload() -> Dictionary:
	return current_payload.duplicate(true)

func route_path(screen_id: StringName) -> String:
	return String(ROUTES.get(screen_id, ""))

func has_route(screen_id: StringName) -> bool:
	var path := route_path(screen_id)
	return not path.is_empty() and ResourceLoader.exists(path)

func registered_routes() -> Dictionary:
	return ROUTES.duplicate(true)

func load_screen(screen_path: String) -> void:
	# Compatibility for older callers while routing moves to screen identifiers.
	if not ResourceLoader.exists(screen_path):
		push_error("UIScreenManager: failed to load screen at %s" % screen_path)
		return
	_change_scene(screen_path)

func _change_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("UIScreenManager: failed to change scene to %s" % path)
		_navigating = false
		return
	await get_tree().process_frame
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_transition_layer, "color:a", 0.0, 0.22)
	tween.tween_callback(_complete_transition)

func _complete_transition() -> void:
	_transition_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_navigating = false
	if _queued_screen == &"":
		return
	var screen_id := _queued_screen
	var queued_payload := _queued_payload.duplicate(true)
	var transition := _queued_transition
	_queued_screen = &""
	_queued_payload = {}
	_queued_transition = &"fade"
	navigate(screen_id, queued_payload, transition)

func _build_transition_layer() -> void:
	_transition_layer = ColorRect.new()
	_transition_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_layer.color = Color(0.94, 0.92, 0.99, 0.0)
	add_child(_transition_layer)