## GoalTracker — отслеживание целей уровня
## Поддержка нескольких целей одновременно (p2.md §10)
extends RefCounted
class_name GoalTracker

## Массив активных целей
## Каждая цель: { type: GoalType, gem_type: int(-1=any), target: int, current: int }
var goals: Array[Dictionary] = []

## Инициализация из конфига уровня
func setup(goal_configs: Array) -> void:
	goals.clear()
	for config in goal_configs:
		goals.append({
			"type": int(config.get("type", GameConstants.GoalType.SCORE)),
			"gem_type": int(config.get("gem_type", -1)),
			"target": int(config.get("target", 0)),
			"current": 0,
		})

## Обработать результат match — обновить все подходящие цели
## Returns: true если хотя бы одна цель обновлена
func process_match(match_data: Dictionary) -> bool:
	var updated := false
	var piece_id: int = match_data.get("piece_id", -1)
	var cell_count: int = match_data.get("length", 0)

	for goal in goals:
		if _is_goal_completed(goal):
			continue

		match goal["type"]:
			GameConstants.GoalType.COLLECT_GEM:
				if goal["gem_type"] == piece_id or goal["gem_type"] == -1:
					goal["current"] = mini(goal["current"] + cell_count, goal["target"])
					updated = true
			GameConstants.GoalType.BREAK_BLOCKER:
				# Обработка блокеров отдельно через process_blocker_broken()
				pass
	return updated

## Обработать разрушение блокера
func process_blocker_broken(blocker_type: int) -> bool:
	var updated := false
	for goal in goals:
		if _is_goal_completed(goal):
			continue
		if goal["type"] == GameConstants.GoalType.BREAK_BLOCKER:
			if goal["gem_type"] == blocker_type or goal["gem_type"] == -1:
				goal["current"] = mini(goal["current"] + 1, goal["target"])
				updated = true
	return updated

## Обновить цель типа SCORE
func process_score(current_score: int) -> bool:
	var updated := false
	for goal in goals:
		if _is_goal_completed(goal):
			continue
		if goal["type"] == GameConstants.GoalType.SCORE:
			goal["current"] = mini(current_score, goal["target"])
			updated = true
	return updated

## Все ли цели выполнены?
func all_completed() -> bool:
	for goal in goals:
		if not _is_goal_completed(goal):
			return false
	return true

## Получить массив целей для UI (с полем completed)
func get_goals_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for goal in goals:
		var g := goal.duplicate()
		g["completed"] = _is_goal_completed(goal)
		result.append(g)
	return result

func snapshot() -> Array[Dictionary]:
	return goals.duplicate(true)

func restore(state: Array[Dictionary]) -> void:
	goals = state.duplicate(true)

func _is_goal_completed(goal: Dictionary) -> bool:
	return goal["current"] >= goal["target"]
