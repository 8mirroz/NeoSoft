extends SceneTree

const RouterScript := preload("res://scenes/ui/ui_screen_manager.gd")
const ActionRegistry := preload("res://scripts/ui/ui_action_registry.gd")

func _initialize() -> void:
	var router := RouterScript.new()
	var routes: Dictionary = router.registered_routes()
	router.free()
	var failures: Array[String] = []
	for screen_id in routes.keys():
		var scene_path := String(routes[screen_id])
		if not ResourceLoader.exists(scene_path):
			failures.append("Missing route scene %s -> %s" % [String(screen_id), scene_path])
	for action_id in ActionRegistry.actions().keys():
		var target: StringName = ActionRegistry.target_for(action_id)
		if target != &"local" and not routes.has(target):
			failures.append("Action %s targets missing route %s" % [String(action_id), String(target)])
	if failures.is_empty():
		print("UI ROUTE VALIDATION PASSED: %d routes, %d actions" % [routes.size(), ActionRegistry.actions().size()])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
