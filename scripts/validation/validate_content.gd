extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	var level_ids := LevelLoader.get_available_level_ids()
	if level_ids.size() < 10:
		errors.append("Expected at least 10 levels, found %d." % level_ids.size())

	for level_id in level_ids:
		var level := LevelLoader.load_level(level_id)
		if level.is_empty():
			errors.append("Level %03d failed to load." % level_id)
			continue
		_validate_level(level, errors)

	var soft_launch := LevelLoader.load_soft_launch_config()
	if not soft_launch.has("quality_profiles"):
		errors.append("soft_launch_config missing quality_profiles.")

	if errors.is_empty():
		print("CONTENT VALIDATION PASSED (%d levels)." % level_ids.size())
		quit(0)
		return

	for error in errors:
		push_error(error)
	quit(1)

func _validate_level(level: Dictionary, errors: Array[String]) -> void:
	var level_id := int(level.get("level_id", -1))
	var board: Dictionary = level.get("board", {})
	var width := int(board.get("width", 0))
	var height := int(board.get("height", 0))
	var gem_kinds := int(board.get("gem_kinds", 0))
	var moves := int(level.get("moves", 0))
	var target_score := int(level.get("target_score", 0))
	var tutorial: Dictionary = level.get("tutorial", {})
	var goals: Array = level.get("goals", [])

	if width < 8 or height < 8:
		errors.append("Level %03d board too small (%dx%d)." % [level_id, width, height])
	if gem_kinds < 5 or gem_kinds > 8:
		errors.append("Level %03d gem_kinds must be 5..8, got %d." % [level_id, gem_kinds])
	if moves < 14 or moves > 30:
		errors.append("Level %03d moves out of range: %d." % [level_id, moves])
	if target_score <= 0:
		errors.append("Level %03d target_score must be positive." % level_id)
	if tutorial.get("enabled", false) and (not tutorial.has("steps") or tutorial.get("steps", []).is_empty()):
		errors.append("Level %03d tutorial is enabled but steps are empty." % level_id)
	if goals.is_empty():
		errors.append("Level %03d has no goals." % level_id)

	var score_per_move := float(target_score) / float(maxi(moves, 1))
	if score_per_move < 60.0 or score_per_move > 380.0:
		errors.append("Level %03d score-per-move sanity check failed: %.2f." % [level_id, score_per_move])

	for goal in goals:
		var goal_type := int(goal.get("type", -1))
		var target := int(goal.get("target", 0))
		if target <= 0:
			errors.append("Level %03d has goal with non-positive target." % level_id)
		if goal_type == GameConstants.GoalType.COLLECT_GEM and target > moves * 3:
			errors.append("Level %03d collect goal target too high for moves budget." % level_id)
