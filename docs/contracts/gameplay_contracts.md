# Gameplay Typed Contracts Registry — Neo Soft Frost

> **Specification Version**: `genesis/v5.1`  
> **Status**: ACTIVE & FROZEN (Architecture Control Plan)

Этот документ содержит спецификацию всех жестко типизированных объектов передачи данных (DTO) в игре **Neo Soft Frost**. Каждый DTO наследуется от `RefCounted` для автоматического управления памятью и реализует метод `.to_dict()` для логгирования, реплеев и телеметрии.

---

## 1. Реестр контрактов (Typed DTOs)

### 1.1 `BoardSnapshot` (`res://scripts/contracts/board_snapshot.gd`)
Служит для фиксации мгновенного снимка игрового поля при возникновении спорных игровых ситуаций или в целях тестирования/воспроизведения реплеев.
- **Поля**:
  - `width: int` — Ширина сетки.
  - `height: int` — Высота сетки.
  - `gems: Array[Array]` — 2D массив строк (типы и цвета фишек).
  - `cell_states: Array[Array]` — 2D массив целых чисел (логические состояния ячеек).
  - `timestamp: float` — Время фиксации снимка в секундах.

### 1.2 `MatchEvent` (`res://scripts/contracts/match_event.gd`)
Служит DTO-контрактом события распознанного и классифицированного совпадения (Match). Передается из детерминированного ядра в Feedback и UI для воспроизведения взрывов и начисления очков.
- **Поля**:
  - `shape_type: String` — Тип распознанной фигуры (например, `CROSS`, `ZIGZAG_6`).
  - `cells: Array[Vector2i]` — Массив координат входящих ячеек.
  - `center_cell: Vector2i` — Ячейка геометрического центра фигуры (центр взрыва VFX).
  - `origin_cell: Vector2i` — Ячейка хода свайпа, которая сформировала фигуру.
  - `gem_color: String` — Цвет совпавших сфер.
  - `score_granted: int` — Полученные очки за матч.

### 1.3 `CascadeStep` (`res://scripts/contracts/cascade_step.gd`)
Описывает единичный шаг осыпания (collapse/drop) гемов во время каскада.
- **Поля**:
  - `step_index: int` — Порядковый индекс шага в текущем каскаде.
  - `drop_mode: int` — Режим выпадения гемов (Natural, Assisted, Cinematic).
  - `generated_gems: Array` — Сгенерированные сферы и их параметры.
  - `approved_by_governor: bool` — Флаг подтверждения со стороны Cascade Governor.

### 1.4 `TelemetryEvent` (`res://scripts/contracts/telemetry_event.gd`)
Формат отправки фоновых событий в BalanceTelemetryLayer для логгирования.
- **Поля**:
  - `event_name: String` — Имя события (например, `fever_activated`).
  - `timestamp: float` — Время фиксации события.
  - `payload: Dictionary` — Ассоциативный массив метрик события.

---

## 2. Правила использования DTO

1. **Запрет raw Dictionary**: Ни один геймплейный класс в `scripts/core_match3/` не имеет права возвращать или принимать сырые словари (raw Dicts) при передаче данных о логических сущностях наружу во внешние слои UI и Feedback. Использование типизированных DTO строго обязательно.
2. **Сериализация**: Метод `to_dict()` должен сохранять только простые JSON-совместимые типы данных (числа, строки, массивы примитивов, плоские словари). Это позволяет прозрачно сериализовать сессии в ReplayRecorder.
3. **Хеширование**: Снимки `BoardSnapshot` могут использоваться для генерации контрольной суммы игрового поля (final hash) с целью проверки рассинхронизации в реплеях.
