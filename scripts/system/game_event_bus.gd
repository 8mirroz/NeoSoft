# /Users/user/3-line/scripts/system/game_event_bus.gd
extends Node

## Глобальная событийно-ориентированная шина (Autoload).
## Единственный мост взаимодействия между детерминированным ядром (Layers 1-4)
## и Feedback/UI/Telemetry (Layers 5-6). Прямые вызовы между слоями запрещены.

# ──────────────────────────────────────────────
# Ввод игрока (Player Input)
# ──────────────────────────────────────────────
signal swap_requested(from_cell: Vector2i, to_cell: Vector2i)
signal swap_rejected(from_cell: Vector2i, to_cell: Vector2i)
signal swap_resolved(from_cell: Vector2i, to_cell: Vector2i)
signal input_queued(from_cell: Vector2i, to_cell: Vector2i)

# ──────────────────────────────────────────────
# Детерминированное ядро (Layer 1 Core Matches)
# ──────────────────────────────────────────────
## Вызывается при нахождении совпадения. Передает объект MatchEvent.
signal match_detected(event: MatchEvent)

## Вызывается после распознавания геометрической формы (11 типов).
signal shape_classified(coordinates: Array[Vector2i], shape_type: String, priority_score: int)

# ──────────────────────────────────────────────
# Каскады и Управляемые Вероятности (Layer 2)
# ──────────────────────────────────────────────
signal cascade_started(depth: int)

## Вызывается на каждом шаге каскадного опускания. Передает CascadeStep.
signal cascade_step_resolved(step: CascadeStep)

## Вызывается при срабатывании блокировщика каскадов (Governor).
signal cascade_governed(reason: String)

# ──────────────────────────────────────────────
# Fever Meter & Fever Mode
# ──────────────────────────────────────────────
signal fever_meter_changed(pct: float)
signal fever_started(duration: float, multiplier: float)
signal fever_ended()

# ──────────────────────────────────────────────
# Спец-сферы (Layer 4)
# ──────────────────────────────────────────────
signal special_spawned(position: Vector2i, special_type: int)

## Вызывается при взрыве или слиянии спец-сфер. Передает SpecialActivationEvent.
signal special_activated(event: SpecialActivationEvent)

# ──────────────────────────────────────────────
# Уровень и Экономика
# ──────────────────────────────────────────────
signal level_loaded(level_config: Dictionary)
signal level_result_resolved(won: bool, final_score: int, stars: int)
signal moves_updated(remaining: int)
signal score_updated(current: int, stars: int)

# ──────────────────────────────────────────────
# UI & Общие презентационные сигналы
# ──────────────────────────────────────────────
signal gem_selected(cell: Vector2i)
signal gem_deselected()
signal game_paused()
signal game_resumed()
