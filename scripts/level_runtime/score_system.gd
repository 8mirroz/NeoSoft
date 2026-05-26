## ScoreSystem — подсчёт очков и звёзд
## Формулы из p2.md §23 и NotebookLM balance sources
extends RefCounted
class_name ScoreSystem

var score: int = 0
var cascade_depth: int = 0
var target_score: int = 1000

## Подсчёт очков за один match
## match_length: количество фишек в совпадении (3, 4, 5+)
## Returns: очки за этот конкретный match
func calculate_match_score(match_length: int) -> int:
	# Base: 60 for match-3 (20 per gem × 3)
	# Each extra gem above 3 adds +10
	var base: int = GameConstants.BASE_MATCH_SCORE
	var extra: int = max(0, match_length - 3) * GameConstants.EXTRA_GEM_BONUS
	var subtotal: int = base + extra

	# Cascade multiplier: depth 0 = ×1, depth 1 = ×2, etc.
	var multiplier: int = cascade_depth + 1
	return subtotal * multiplier

## Добавить очки за match и вернуть дельту
func add_match_score(match_length: int) -> int:
	var points := calculate_match_score(match_length)
	score += points
	return points

## Добавить бонус за создание спецгема
func add_special_gem_bonus() -> int:
	var points := GameConstants.SPECIAL_GEM_BONUS * (cascade_depth + 1)
	score += points
	return points

## Бонус за оставшиеся ходы (вызывается при победе)
func add_remaining_moves_bonus(moves_left: int) -> int:
	var points := moves_left * GameConstants.REMAINING_MOVE_BONUS
	score += points
	return points

## Увеличить глубину каскада (вызывать при каждом каскадном match)
func increment_cascade() -> void:
	cascade_depth += 1

## Сбросить каскад (вызывать после завершения хода)
func reset_cascade() -> void:
	cascade_depth = 0

## Получить количество звёзд на текущий момент
func get_stars() -> int:
	if target_score <= 0:
		return 0
	var ratio := float(score) / float(target_score)
	if ratio >= GameConstants.STAR_3_THRESHOLD:
		return 3
	elif ratio >= GameConstants.STAR_2_THRESHOLD:
		return 2
	elif ratio >= GameConstants.STAR_1_THRESHOLD:
		return 1
	return 0

## Полный сброс для нового уровня
func reset(p_target_score: int) -> void:
	score = 0
	cascade_depth = 0
	target_score = p_target_score

func snapshot() -> Dictionary:
	return {
		"score": score,
		"cascade_depth": cascade_depth,
		"target_score": target_score,
	}

func restore(state: Dictionary) -> void:
	score = int(state.get("score", score))
	cascade_depth = int(state.get("cascade_depth", cascade_depth))
	target_score = int(state.get("target_score", target_score))
