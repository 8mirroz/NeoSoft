# /Users/user/3-line/scripts/system/game_event_bus.gd
extends Node

## Глобальная централизованная шина событий (Autoload: GameEventBus).
## Единственный мост между core, UI, feedback и telemetry.

# ──────────────────────────────────────────────
# Ввод и Буфер
# ──────────────────────────────────────────────
signal swap_requested(from_cell: Vector2i, to_cell: Vector2i)
signal input_queued(from_cell: Vector2i, to_cell: Vector2i)
signal swap_rejected(from_cell: Vector2i, to_cell: Vector2i)
signal swap_resolved(from_cell: Vector2i, to_cell: Vector2i)

# ──────────────────────────────────────────────
# Матчи и Спец-сферы
# ──────────────────────────────────────────────
signal match_detected(match_data: MatchEvent)
signal shape_classified(shape_data: MatchShapeResult)
signal special_spawned(pos: Vector2i, type: String)
signal special_activated(pos: Vector2i, type: String)

# ──────────────────────────────────────────────
# Каскады и Гравитация
# ──────────────────────────────────────────────
signal cascade_started()
signal cascade_step_resolved(step_data: CascadeStep)
signal cascade_governed(reason: String)
signal board_collapsed(movements: Array)
signal pieces_generated(spawns: Array)

# ──────────────────────────────────────────────
# Fever & Комбо-окно
# ──────────────────────────────────────────────
signal combo_window_updated(remaining: float, chain: int)
signal fever_meter_changed(percent: float)
signal fever_started(duration: float, multiplier: float)
signal fever_ended()

# ──────────────────────────────────────────────
# Игры и Состояние уровня
# ──────────────────────────────────────────────
signal turn_finished()
signal level_loaded(config: Dictionary)
signal level_finished(result: Dictionary)
signal dead_board_detected(payload: Dictionary)
signal auto_shuffle_applied(payload: Dictionary)
signal undo_used(payload: Dictionary)
signal game_paused()
signal game_resumed()

# ──────────────────────────────────────────────
# Визуальные сигналы презентации
# ──────────────────────────────────────────────
signal gem_tapped(cell: Vector2i)
signal gem_selected(cell: Vector2i)
signal gem_deselected()
signal hint_requested(cells: Array[Vector2i])
signal booster_activated(booster_type: int, target_cell: Vector2i)
