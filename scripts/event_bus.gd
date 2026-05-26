## EventBus — глобальная шина событий (autoload)
## Единственный мост между модулями. Прямые вызовы запрещены (RULE-005).
## Сигналы группированы по модулям-источникам.
extends Node

# ──────────────────────────────────────────────
# core_match3 events
# ──────────────────────────────────────────────

## Игрок запросил swap двух ячеек
signal swap_requested(from_cell: Vector2i, to_cell: Vector2i)

## Swap отклонён (не соседи или нет match)
signal swap_rejected(from_cell: Vector2i, to_cell: Vector2i)

## Swap выполнен успешно (модель обновлена)
signal swap_resolved(from_cell: Vector2i, to_cell: Vector2i)

## Найдены и удалены совпадения
## matches: Array[Dictionary] — { piece_id, cells, length, match_type }
signal match_resolved(matches: Array[Dictionary])

## Спецгем создан
## gem_data: { type: SpecialGemType, cell: Vector2i, source_match: Dictionary }
signal special_gem_created(gem_data: Dictionary)

## Гемы упали (гравитация)
## movements: Array[Dictionary] — { piece_id, from, to }
signal board_collapsed(movements: Array[Dictionary])

## Новые гемы сгенерированы
## spawns: Array[Dictionary] — { piece_id, to }
signal pieces_generated(spawns: Array[Dictionary])

## Каскад завершён (все падения + refill + проверки)
signal cascade_completed(cascade_depth: int)

## Ход полностью завершён (все каскады обработаны)
signal turn_finished()

## На поле не осталось валидных ходов
signal dead_board_detected(payload: Dictionary)

## Автоматическое спасение поля после dead-board
signal auto_shuffle_applied(payload: Dictionary)

## Undo выполнен и игровое состояние восстановлено
signal undo_used(payload: Dictionary)

# ──────────────────────────────────────────────
# level_runtime events
# ──────────────────────────────────────────────

## Цели уровня обновлены
## goals: Array[Dictionary] — { type: GoalType, target, current, completed }
signal goals_updated(goals: Array[Dictionary])

## Счётчик ходов обновлён
signal moves_updated(remaining: int, used: int)

## Очки обновлены
signal score_updated(score: int, stars: int)

## Уровень завершён
## result: { won: bool, score, stars, moves_used, moves_remaining }
signal level_finished(result: Dictionary)

## Уровень загружен и готов к игре
signal level_loaded(level_config: Dictionary)

## Runtime просит зафиксировать аналитическое событие
signal analytics_event_requested(event_name: String, payload: Dictionary)

# ──────────────────────────────────────────────
# CFE (Combo Fever Engine) events
# ──────────────────────────────────────────────
signal combo_window_opened(duration: float)
signal combo_window_updated(remaining: float, chain: int)
signal combo_expired()
signal fever_activated(duration: float, multiplier: float)
signal fever_expired()

# ──────────────────────────────────────────────
# presentation events
# ──────────────────────────────────────────────

## Игрок нажал на гем (input → controller)
signal gem_tapped(cell: Vector2i)

## Игрок выбрал гем (первый тап)
signal gem_selected(cell: Vector2i)

## Игрок убрал выбор
signal gem_deselected()

## Подсказка должна быть показана
signal hint_requested(cells: Array[Vector2i])

## Бустер активирован
signal booster_activated(booster_type: int, target_cell: Vector2i)

## Пауза/возобновление
signal game_paused()
signal game_resumed()

# ──────────────────────────────────────────────
# meta_layer events (post-MVP, зарезервированы)
# ──────────────────────────────────────────────

## Награда получена
signal reward_claimed(reward: Dictionary)

## Жизни обновлены
signal lives_updated(remaining: int)
