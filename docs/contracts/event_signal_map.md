# EventBus Signal Map Specification — Neo Soft Frost

> **Specification Version**: `genesis/v5.1`  
> **Status**: ACTIVE & FROZEN (Architecture Control Plan)

Этот документ содержит спецификацию всех глобальных сигналов, транслируемых через центральный `GameEventBus` (`res://scripts/system/game_event_bus.gd`). Он служит единым источником правды для проектирования взаимодействия модулей.

---

## 1. Сигналы и сигнатуры вызовов (Signal Map)

### 1.1 Ввод и Буферизация (Input & Buffer)
* **`swap_requested(from_cell: Vector2i, to_cell: Vector2i)`**  
  Вызывается при первоначальном свайпе игрока. Направляется в FSM `ResolvePipeline` для первичной валидации смежности.
* **`input_queued(from_cell: Vector2i, to_cell: Vector2i)`**  
  Вызывается, когда свайп игрока буферизован очередью во время проигрывания каскадов.
* **`swap_rejected(from_cell: Vector2i, to_cell: Vector2i)`**  
  Вызывается при невалидном свайпе (ячейки не смежные или не образовали совпадений).
* **`swap_resolved(from_cell: Vector2i, to_cell: Vector2i)`**  
  Вызывается при подтверждении успешного свайпа.

### 1.2 Матчи и Спец-сферы (Matches & Specials)
* **`match_detected(match_data: MatchEvent)`**  
  Вызывается после нахождения совпадений MatchDetector. Передает типизированное DTO `MatchEvent`.
* **`shape_classified(shape_data: MatchShapeResult)`**  
  Вызывается при завершении классификации геометрического компонента.
* **`special_spawned(pos: Vector2i, type: String)`**  
  Вызывается при создании спец-сферы на поле.
* **`special_activated(pos: Vector2i, type: String)`**  
  Вызывается в начале детонации/активации спец-сферы.

### 1.3 Каскады и Гравитация (Cascades & Collapses)
* **`cascade_started()`**  
  Вызывается в начале каскадного осыпания.
* **`cascade_step_resolved(step_data: CascadeStep)`**  
  Вызывается по завершении единичного осыпания с детальными результатами DTO `CascadeStep`.
* **`cascade_governed(reason: String)`**  
  Вызывается при достижении лимита каскадов CascadeGovernor и принудительном Color Interlocking.

### 1.4 Fever и Комбо-окно (Fever & Combo Window)
* **`combo_window_updated(remaining: float, chain: int)`**  
  Транслирует оставшееся время Combo Window и текущую длину комбо-цепочки.
* **`fever_meter_changed(percent: float)`**  
  Транслирует прогресс заполнения Fever шкалы в процентах (0.0–100.0).
* **`fever_started(duration: float, multiplier: float)`**  
  Вызывается при активации режима Fever Mode.
* **`fever_ended()`**  
  Вызывается по истечении действия Fever Mode.

---

## 2. Шаблон интеграции сигналов (Integration Snippet)

Все модули-подписчики (например, `VfxDirector`, `HUD`) должны осуществлять подписку в `_ready()` следующим образом:

```gdscript
func _ready() -> void:
	# Подписка на глобальную шину GameEventBus
	GameEventBus.match_detected.connect(_on_match_detected)
	GameEventBus.fever_started.connect(_on_fever_started)

func _on_match_detected(match_data: MatchEvent) -> void:
	# Безопасное проигрывание эффекта на основе DTO контракта
	VfxPlayer.play_match_burst(match_data.center_cell, match_data.shape_type)

func _on_fever_started(duration: float, multiplier: float) -> void:
	# Запуск эпических визуальных эффектов Fever Mode
	FeverVfx.pulse_aura(duration)
```
