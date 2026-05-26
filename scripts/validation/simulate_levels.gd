extends SceneTree

const RUNS_PER_LEVEL := 5
const MAX_TURNS := 128

func _init() -> void:
	var summaries: Array[String] = []
	var failing_levels: Array[int] = []

	for level_id in LevelLoader.get_available_level_ids():
		var level := LevelLoader.load_level(level_id)
		if level.is_empty():
			failing_levels.append(level_id)
			continue

		var wins := 0
		var total_moves_left := 0
		var fail_modes: Dictionary = {}
		for run_index in range(RUNS_PER_LEVEL):
			var outcome := _simulate_single_level(level, level_id * 100 + run_index + 1)
			if outcome.get("won", false):
				wins += 1
				total_moves_left += int(outcome.get("moves_left", 0))
			else:
				var fail_mode := String(outcome.get("fail_mode", "unknown"))
				fail_modes[fail_mode] = int(fail_modes.get(fail_mode, 0)) + 1
		var avg_moves_left := float(total_moves_left) / float(maxi(wins, 1))
		summaries.append(
			"Level %03d win_rate=%.2f avg_moves_left=%.2f fail_modes=%s" % [
				level_id,
				float(wins) / float(RUNS_PER_LEVEL),
				avg_moves_left,
				JSON.stringify(fail_modes),
			]
		)
		if wins == 0:
			failing_levels.append(level_id)

	for summary in summaries:
		print(summary)

	if failing_levels.is_empty():
		print("SIMULATION PASSED")
		quit(0)
		return

	push_error("Simulation found failing levels: %s" % JSON.stringify(failing_levels))
	quit(1)

func _simulate_single_level(level: Dictionary, seed: int) -> Dictionary:
	var board_cfg: Dictionary = level.get("board", {})
	var controller := BoardController.new()
	controller.board_width = int(board_cfg.get("width", 8))
	controller.board_height = int(board_cfg.get("height", 8))
	controller.piece_kinds = int(board_cfg.get("gem_kinds", 6))
	controller.random_seed = seed
	controller.initialize()

	var score_system := ScoreSystem.new()
	score_system.reset(int(level.get("target_score", 1000)))
	var goal_tracker := GoalTracker.new()
	goal_tracker.setup(level.get("goals", []))
	var move_counter := MoveCounter.new()
	move_counter.setup(int(level.get("moves", 20)))

	controller.swap_resolved.connect(func(_from: Vector2i, _to: Vector2i) -> void:
		move_counter.use_move()
	)
	controller.matches_resolved.connect(func(matches: Array[Dictionary]) -> void:
		for match in matches:
			score_system.add_match_score(int(match.get("length", 3)))
			goal_tracker.process_match(match)
		goal_tracker.process_score(score_system.score)
	)
	controller.pieces_generated.connect(func(_spawns: Array[Dictionary]) -> void:
		score_system.increment_cascade()
	)
	controller.turn_finished.connect(func() -> void:
		score_system.reset_cascade()
	)

	var turns := 0
	while turns < MAX_TURNS:
		if goal_tracker.all_completed():
			return _finish_simulation(controller, {
				"won": true,
				"moves_left": move_counter.remaining(),
			})
		if move_counter.is_exhausted():
			return _finish_simulation(controller, {
				"won": false,
				"fail_mode": "moves_exhausted",
			})

		var move := _find_best_move(controller, goal_tracker)
		if move.is_empty():
			if not controller.shuffle_board():
				return _finish_simulation(controller, {
					"won": false,
					"fail_mode": "dead_board",
				})
			continue

		controller.request_swap(move[0], move[1])
		turns += 1

	return _finish_simulation(controller, {
		"won": goal_tracker.all_completed(),
		"moves_left": move_counter.remaining(),
		"fail_mode": "turn_budget_exceeded",
	})

func _find_best_move(controller: BoardController, goal_tracker: GoalTracker) -> Array[Vector2i]:
	var best_move: Array[Vector2i] = []
	var best_score := -1.0
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]

	for y in range(controller.board.height):
		for x in range(controller.board.width):
			var cell := Vector2i(x, y)
			if controller.board.get_piece(cell) < 0:
				continue
			for direction in directions:
				var neighbor: Vector2i = cell + direction
				if not controller.board.is_in_bounds(neighbor):
					continue
				if controller.board.get_piece(neighbor) < 0:
					continue

				controller.board.swap_pieces(cell, neighbor)
				var matches := controller.match_system.find_matches(controller.board)
				controller.board.swap_pieces(cell, neighbor)

				if matches.is_empty():
					continue

				var heuristic := _score_candidate(matches, goal_tracker)
				if heuristic > best_score:
					best_score = heuristic
					best_move = [cell, neighbor]

	return best_move if not best_move.is_empty() else HintSystem.find_hint(controller.board, controller.match_system)

func _score_candidate(matches: Array[Dictionary], goal_tracker: GoalTracker) -> float:
	var score := 0.0
	for match_data in matches:
		var piece_id := int(match_data.get("piece_id", -1))
		var length := int(match_data.get("length", 3))
		score += float(length * length)

		for goal in goal_tracker.goals:
			if int(goal.get("current", 0)) >= int(goal.get("target", 0)):
				continue
			match int(goal.get("type", -1)):
				GameConstants.GoalType.COLLECT_GEM:
					if int(goal.get("gem_type", -1)) == piece_id or int(goal.get("gem_type", -1)) == -1:
						score += float(length * 100)
				GameConstants.GoalType.SCORE:
					score += float(length * 2)

	return score

func _finish_simulation(controller: BoardController, outcome: Dictionary) -> Dictionary:
	controller.free()
	return outcome
