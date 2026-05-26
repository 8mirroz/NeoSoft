# Спецификация контрактов данных и событий геймплея — Genesis v5.1

Для обеспечения слабой связности (loose coupling) и исключения хаотичного обмена неструктурированными словарями Dictionary между логическим ядром, шиной EventBus, UI и Feedback-директором, все события в проекте **Neo Soft Frost** строго типизированы в виде объектов-контрактов, наследуемых от `RefCounted`.

Все контракты размещаются в каталоге `scripts/contracts/` и снабжены методами сериализации (`serialize()`) и десериализации (`deserialize()`) для поддержки replay-системы и безголовых (headless) MCTS симуляций.

---

## 1. Реестр утвержденных контрактов

### 1.1 `BoardSnapshot`
* **Файл**: [board_snapshot.gd](file:///Users/user/3-line/scripts/contracts/board_snapshot.gd)
* **Назначение**: Полный снимок состояния игрового поля на определенный шаг транзакции.
* **Поля**:
  * `width` (`int`): Ширина доски (по умолчанию 8).
  * `height` (`int`): Высота доски (по умолчанию 8).
  * `cells` (`Array`): Двумерный массив метаданных ячеек (цвет, логическое состояние, тип спец-сферы).

### 1.2 `MatchEvent`
* **Файл**: [match_event.gd](file:///Users/user/3-line/scripts/contracts/match_event.gd)
* **Назначение**: Содержит информацию о найденных и очищенных комбинациях 3+ гемов.
* **Поля**:
  * `coordinates` (`Array[Vector2i]`): Координаты ячеек, вовлеченных в матч.
  * `color` (`String`): Цвет сматченных гемов.
  * `shape_type` (`String`): Классифицированная форма (например, `line_3`, `line_4`, `square_2x2`).
  * `score` (`int`): Начисленные за этот конкретный матч очки.

### 1.3 `CascadeStep`
* **Файл**: [cascade_step.gd](file:///Users/user/3-line/scripts/contracts/cascade_step.gd)
* **Назначение**: Шаг каскадного опускания гемов. Используется FeedbackDirector для эскалации VFX/SFX нарастающего комбо.
* **Поля**:
  * `depth_level` (`int`): Текущий индекс каскадной глубины (1, 2, 3 и т.д.).
  * `generated_gems` (`Array`): Сгенерированные гели-заменители с флагами Assisted.
  * `drop_mode` (`int`): Режим падения (Natural, Assisted, Cinematic).

### 1.4 `SpecialActivationEvent`
* **Файл**: [special_activation_event.gd](file:///Users/user/3-line/scripts/contracts/special_activation_event.gd)
* **Назначение**: Передача данных о взрыве спец-сферы или слиянии двух спец-сфер.
* **Поля**:
  * `position` (`Vector2i`): Логическая ячейка активации.
  * `special_type` (`int`): Логический тип спец-сферы.
  * `affected_cells` (`Array[Vector2i]`): Все ячейки игрового поля, затронутые зоной взрыва.
  * `is_combo_trigger` (`bool`): Является ли активация слиянием двух спец-сфер.
  * `combo_partner_type` (`int`): Тип партнерской спец-сферы при слиянии.

### 1.5 `TelemetryEvent`
* **Файл**: [telemetry_event.gd](file:///Users/user/3-line/scripts/contracts/telemetry_event.gd)
* **Назначение**: Метрики одного игрового хода для баланса и симуляций MCTS.
* **Поля**:
  * `timestamp` (`int`): Время создания события.
  * `turn_index` (`int`): Порядковый номер хода.
  * `move_type` (`String`): Тип хода (manual, combo_window, replay).
  * `score_gained` (`int`): Очки, полученные за весь ход со всеми его каскадами.
  * `cascade_depth` (`int`): Максимальная глубина каскада, достигнутая в этом ходу.
  * `special_created_count` (`int`): Сколько спец-сфер родилось в ходе.
  * `fever_active` (`bool`): Был ли активен Fever Mode в момент совершения хода.
