# Карта сигналов и событий (Event Signal Map) — Genesis v5.1

Центральным звеном событийно-ориентированной архитектуры проекта **Neo Soft Frost** является автозагружаемый синглтон **GameEventBus** (`scripts/system/game_event_bus.gd`).

Этот документ служит машиночитаемым и человекочитаемым контрактом для всех разработчиков и автономных агентов. Он описывает, какие сигналы доступны в шине, кто является их источником (Publisher) и кто на них подписывается (Subscriber), а также форматы передаваемых аргументов.

---

## 1. Карта сигналов (Signal Map)

| Сигнал | Аргументы | Publisher | Subscriber | Описание |
|---|---|---|---|---|
| `swap_requested` | `from_cell: Vector2i`, `to_cell: Vector2i` | `HUD / BoardVisual` | `InputBufferController` | Игрок совершил физический свайп на поле. |
| `input_queued` | `from_cell: Vector2i`, `to_cell: Vector2i` | `InputBufferController` | `HUD / BoardVisual` | Ход буферизован во время анимации каскадов. |
| `swap_resolved` | `from_cell: Vector2i`, `to_cell: Vector2i` | `ResolvePipeline` | `HUD / BoardVisual` | Обмен подтвержден детерминированным ядром. |
| `match_detected` | `event: MatchEvent` | `MatchDetector` | `FeedbackDirector / Telemetry` | Найдена группа 3+ гемов одного цвета. |
| `shape_classified` | `coordinates: Array[Vector2i]`, `shape_type: String`, `priority_score: int` | `ShapeClassifier` | `SpecialSphereFactory` | Распознана одна из 11 геометрических форм. |
| `cascade_step_resolved` | `step: CascadeStep` | `ControlledCascadeEngine` | `FeedbackDirector / BoardVisual` | Завершено падение гемов каскада на определенной глубине. |
| `cascade_governed` | `reason: String` | `CascadeGovernor` | `Telemetry / HUD` | Каскадный цикл принудительно остановлен из-за перегрузки. |
| `special_spawned` | `position: Vector2i`, `special_type: int` | `SpecialSphereFactory` | `BoardVisual / Telemetry` | На игровом поле создана новая спец-сфера. |
| `special_activated` | `event: SpecialActivationEvent` | `SpecialComboResolver` | `FeedbackDirector / HUD` | Произошла детонация или слияние спец-сфер. |
| `fever_meter_changed` | `pct: float` | `ComboFeverController` | `HUD / Telemetry` | Изменилось значение очков Fever (0.0 - 100.0). |
| `fever_started` | `duration: float`, `multiplier: float` | `ComboFeverController` | `HUD / FeedbackDirector` | Активирован режим Fever Mode. |
| `level_result_resolved` | `won: bool`, `final_score: int`, `stars: int` | `LevelSession` | `UIScreenManager / Telemetry` | Текущий уровень завершен. |

---

## 2. Архитектурные требования к подписке

1. **Динамическая отписка**: Все UI-компоненты при удалении с экрана (`_exit_tree()`) обязаны явно отписаться от сигналов `GameEventBus`, если они подключались через анонимные callable-функции, во избежание утечек памяти.
2. **Исключение перекрестных сигналов**: UI-компонентам запрещено посылать сигналы "вместо" логического ядра. Только авторизованные Publisher-модули имеют право вызывать `emit_signal`.
