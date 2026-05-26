# Task Plan WBS — Genesis v4.1

## Combo Fever Engine for Neo Soft Frost

---

## 0. System Role

**Combo Fever Engine** — центральный real-time gameplay acceleration layer для match-3 игры со сферами.

Он отвечает за:
```text
- распознавание фигур матчей;
- создание спец-сфер;
- обработку каскадов;
- ввод во время анимаций;
- Combo Window;
- Fever Mode;
- спец-комбинации;
- VFX/SFX tier ladder;
- target priority;
- телеметрию баланса;
- защиту от softlock и рассинхрона.
```

---

## 1. Source of Truth Artifacts

```text
genesis/v4/01_PRD.md
genesis/v4/02_ARCHITECTURE_OVERVIEW.md
genesis/v4/03_ADR/
genesis/v4/04_SYSTEM_DESIGN/combo_fever_engine.md
res://data/combo_fever_config.json
res://data/combo_special_matrix.json
res://data/combo_vfx_tiers.json
res://tests/core_match3/
```

---

## 2. Global Quality Gates

Перед merge любой CFE-задачи должны пройти:
```text
- GUT unit tests
- no hardcoded balance values
- no direct visual mutation from logic layer
- no cyclic dependency between BoardStateEngine and BoardVisual
- all public methods documented
- all new signals listed in API contract
- all risky systems behind feature flags
```

Feature flags:
```json
{
  "combo_window_enabled": true,
  "fever_mode_enabled": true,
  "input_buffer_enabled": true,
  "special_combos_enabled": true,
  "advanced_shapes_enabled": true,
  "telemetry_enabled": true,
  "vfx_tier_ladder_enabled": true
}
```

---

# Phase 1 — Foundation

## CFE-01 — Board State Engine

**Goal:**
Создать логическую сетку, независимую от визуала.

**Output:**
```text
scripts/core_match3/cell_state.gd
scripts/core_match3/board_state_engine.gd
tests/core_match3/test_board_state_engine.gd
```

**Required states:**
```text
STABLE
LOCKED
FALLING
SPAWNING
RESOLVING
RESERVED
BLOCKED
TARGET
```

**Signals:**
```text
cell_state_changed(cell, old_state, new_state)
cell_gem_changed(cell, old_gem, new_gem)
board_stabilized()
board_softlock_detected()
```

**Definition of Done:**
```text
- State transition matrix implemented.
- Invalid transitions blocked.
- Board can serialize current state.
- Board can force-stabilize after failure.
- Tests cover valid and invalid transitions.
```

---

## CFE-02 — Match Shape Detector

**Goal:**
Распознавать фигуры за O(N) без привязки к визуалу.

**Output:**
```text
scripts/core_match3/match_shape_detector.gd
scripts/core_match3/match_shape_result.gd
tests/core_match3/test_match_shape_detector.gd
```

**Detected shapes:**
```text
LINE_3
LINE_4
LINE_5
SQUARE_2X2
L_SHAPE
T_SHAPE
CROSS
COMPLEX_6
COMPLEX_7_PLUS
DOUBLE_MATCH
```

**Definition of Done:**
```text
- Detector returns shape type, cells, origin cell, center cell, direction, weight.
- Overlapping shapes resolved by priority.
- 2x2 square detection works independently from lines.
- Tests include edge/corner cases.
```

---

## CFE-03 — Special Sphere Factory

**Goal:**
Создавать спец-сферы из распознанных фигур.

**Output:**
```text
scripts/core_match3/special_sphere_factory.gd
scripts/core_match3/special_sphere_type.gd
res://data/combo_special_matrix.json
tests/core_match3/test_special_sphere_factory.gd
```

**Shape mapping:**
```text
LINE_4        → BEAM_SPHERE
SQUARE_2X2    → HOMING_SPHERE
L_SHAPE       → BLAST_SPHERE
T_SHAPE       → BLAST_SPHERE_PLUS
LINE_5        → PRISM_SPHERE
COMPLEX_6     → DYNAMO_SPHERE
COMPLEX_7_PLUS → SINGULARITY_CORE
```

**Definition of Done:**
```text
- Spawn cell is deterministic.
- Move-origin priority supported.
- Center-cell fallback supported.
- All mappings are config-driven.
```

---

# Phase 2 — Control Layer

## CFE-04 — Input Buffer Controller

**Goal:**
Разрешить игроку двигать сферы во время каскадов в стабильных зонах.

**Output:**
```text
scripts/core_match3/input_buffer_controller.gd
scripts/core_match3/queued_move.gd
tests/core_match3/test_input_buffer_controller.gd
```

**QueuedMove contract:**
```text
from_cell
to_cell
created_at
expires_at
priority
expected_from_gem_id
expected_to_gem_id
source
```

**Definition of Done:**
```text
- STABLE cells can move during cascades.
- LOCKED/FALLING/SPAWNING cells cannot move.
- Invalid queued moves expire safely.
- expected_gem_id prevents desync.
- Queue length is capped.
```

---

## CFE-05 — Combo Fever Controller

**Goal:**
Реализовать Combo Window, ComboPower и Fever Mode.

**Output:**
```text
scripts/core_match3/combo_fever_controller.gd
res://data/combo_fever_config.json
tests/core_match3/test_combo_fever_controller.gd
```

**Core formula:**
```text
RawComboPower =
BaseMatchValue
+ ChainIndex * ChainMultiplier
+ ShapeWeight
+ SpecialSphereWeight
+ ManualSpeedBonus
+ CascadeBonus
+ LevelObjectiveBonus

ComboPower = clamp(curve(RawComboPower), min_power, max_power)
```

**Definition of Done:**
```text
- Combo Window opens after first match.
- Timer refresh depends on shape complexity.
- Invalid fast move reduces window.
- Fever activates at Combo x5 or threshold.
- Fever has duration cap and multiplier cap.
```

---

## CFE-06 — Target Priority System

**Goal:**
Сделать наводящуюся сферу полезной для целей уровня.

**Output:**
```text
scripts/core_match3/target_priority_system.gd
tests/core_match3/test_target_priority_system.gd
```

**Priority order:**
```text
1. objective target
2. locked objective
3. corner target
4. low hp blocker
5. strategic blocker
6. random useful cell
```

**Definition of Done:**
```text
- Homing sphere never chooses useless target if objective exists.
- Target scoring is visible in debug overlay.
- Tie-breaker is deterministic.
```

---

# Phase 3 — Orchestration & Views

## CFE-07 — Resolve Pipeline FSM

**Goal:**
Создать центральный транзакционный автомат обработки поля.

**Output:**
```text
scripts/core_match3/resolve_pipeline.gd
scripts/core_match3/resolve_context.gd
tests/core_match3/test_resolve_pipeline.gd
```

**FSM:**
```text
IDLE
SWAP_REQUESTED
SWAP_VALIDATING
MATCH_SCANNING
SPECIAL_SPAWNING
EFFECT_RESOLVING
GRAVITY_APPLYING
CASCADE_CHECKING
COMBO_UPDATING
STABILIZING
FAILED_RECOVERY
```

**Definition of Done:**
```text
- 1000 random move simulation without softlock.
- Max cascade depth implemented.
- Failed state can force-stabilize board.
- Pipeline emits debug trace.
```

---

## CFE-08 — Feedback Orchestrator

**Goal:**
Управлять VFX/SFX/UI/haptic по tier ladder.

**Output:**
```text
scripts/core_match3/feedback_orchestrator.gd
res://data/combo_vfx_tiers.json
tests/core_match3/test_feedback_orchestrator.gd
```

**Budgets:**
```text
particle_budget
camera_shake_budget
title_spam_limiter
sound_polyphony_cap
haptic_cooldown
```

**Definition of Done:**
```text
- 8 tiers supported.
- Android safe profile throttles excessive particles.
- UI title cannot spam more than allowed.
- Signature effects triggered only for Tier 7–8.
```

---

## CFE-09 — BoardView and GemView Sync

**Goal:**
Синхронизировать визуал с логикой без обратного контроля.

**Output:**
```text
scenes/gameplay/board_visual.gd
scenes/gameplay/gem_view.gd
tests/scene/test_board_visual_sync.gd
```

**Rules:**
```text
BoardLogic emits.
BoardVisual listens.
Visual never mutates board directly.
Animation completion reports back through controlled callback.
```

**Definition of Done:**
```text
- Falling animation smooth.
- Locked cells visibly marked.
- GemView reacts to special type.
- Visual completion unlocks cells only through pipeline.
```

---

# Phase 4 — Integration & Launch

## CFE-10 — HUD and Combo Window UI

**Goal:**
Добавить контур Combo Window, Fever overlay и combo titles.

**Output:**
```text
scenes/gameplay/gameplay.tscn
scenes/gameplay/gameplay.gd
scenes/ui/combo_window_ring.tscn
scenes/ui/fever_overlay.tscn
```

**Definition of Done:**
```text
- Combo Window visible around board.
- Timer decay readable.
- Fever activation clear but not blinding.
- UI scales for mobile aspect ratios.
```

---

## CFE-11 — Balance Telemetry Layer

**Goal:**
Собирать метрики баланса и экспортировать JSON.

**Output:**
```text
scripts/core_match3/balance_telemetry_layer.gd
res://debug/telemetry_schema.json
```

**Metrics:**
```text
average_combo_length
max_combo_length
fever_activation_rate
queued_move_success_rate
queued_move_expire_rate
invalid_fast_move_rate
player_idle_time_during_cascade
special_sphere_creation_rate
special_combo_usage_rate
level_win_rate
moves_left_on_win
```

**Definition of Done:**
```text
- Debug export works.
- Metrics reset per level session.
- JSON schema validated.
- Telemetry can be disabled by config.
```

---

## CFE-12 — E2E Integration & Calibration

**Goal:**
Интегрировать CFE в `level_session.gd` и откалибровать 10 профилей сложности.

**Output:**
```text
scripts/gameplay/level_session.gd
res://data/difficulty_profiles.json
tests/e2e/test_combo_fever_e2e.gd
```

**Required E2E tests:**
```text
test_line_4_creates_beam
test_square_creates_homing
test_line_5_creates_prism
test_combo_window_extends
test_fever_activates
test_queued_move_executes
test_queued_move_expires
test_beam_beam_combo
test_beam_blast_combo
test_prism_prism_combo
test_no_softlock_after_chain
test_telemetry_export
```

**Definition of Done:**
```text
- All 12 E2E tests pass.
- 10 difficulty profiles load correctly.
- Gameplay session can run 20 levels without fatal error.
- CFE can be disabled via feature flag.
```

---

### 5. ULTRA PROMPT FOR CODEX / HERMES

```text
Ты — Senior Godot Gameplay Engineer, Match-3 Systems Architect и Gameplay QA Automation Lead.

Контекст:
Есть WBS Genesis v4.1 для реализации Combo Fever Engine в match-3 игре Neo Soft Frost. Нужно внедрить систему без архитектурного хаоса, с разделением BoardLogic и BoardVisual, data-driven балансом, тестами, rollback flags и performance budget.

Главная цель:
Реализовать production-ready Combo Fever Engine, который позволяет игроку делать ходы во время каскадов, поддерживает Combo Window, Fever Mode, спец-сферы, спец-комбинации, VFX/SFX tier ladder, target priority и telemetry.

Рабочий алгоритм:
1. Проведи аудит текущего проекта.
2. Найди существующие файлы board, gem, match, swap, gravity, level_session, gameplay scene.
3. Составь file map: какие файлы уже есть, какие нужно создать.
4. Не переписывай проект хаотично. Внедряй CFE слоями.
5. Сначала создай BoardStateEngine и CellState.
6. Затем MatchShapeDetector.
7. Затем SpecialSphereFactory.
8. Параллельно добавь InputBufferController, ComboFeverController, TargetPrioritySystem.
9. После этого создай ResolvePipeline FSM.
10. Затем подключи FeedbackOrchestrator.
11. Только после стабильной логики подключай BoardVisual/GemView.
12. HUD, telemetry и E2E tests.

Строгие правила:
- BoardLogic является source of truth.
- BoardVisual не имеет права напрямую менять логическое состояние поля.
- Все числа баланса выноси в JSON/config.
- Все risky-механики закрывай feature flags.
- Любой queued move должен проверять expected_gem_id.
- Любой resolve cycle должен иметь max depth.
- При ошибке pipeline должен переходить в FAILED_RECOVERY и стабилизировать поле.
- Нельзя добавлять визуальные эффекты без budget-контроля.
- Нельзя merge без тестов.

Файлы создать:
- scripts/core_match3/cell_state.gd
- scripts/core_match3/board_state_engine.gd
- scripts/core_match3/match_shape_detector.gd
- scripts/core_match3/match_shape_result.gd
- scripts/core_match3/special_sphere_factory.gd
- scripts/core_match3/input_buffer_controller.gd
- scripts/core_match3/queued_move.gd
- scripts/core_match3/combo_fever_controller.gd
- scripts/core_match3/target_priority_system.gd
- scripts/core_match3/resolve_pipeline.gd
- scripts/core_match3/resolve_context.gd
- scripts/core_match3/feedback_orchestrator.gd
- scripts/core_match3/balance_telemetry_layer.gd
- res://data/combo_fever_config.json
- res://data/combo_special_matrix.json
- res://data/combo_vfx_tiers.json
- res://data/difficulty_profiles.json

Тесты создать:
- test_board_state_engine.gd
- test_match_shape_detector.gd
- test_special_sphere_factory.gd
- test_input_buffer_controller.gd
- test_combo_fever_controller.gd
- test_target_priority_system.gd
- test_resolve_pipeline.gd
- test_feedback_orchestrator.gd
- test_combo_fever_e2e.gd

Quality gates:
- все unit-тесты проходят;
- 1000 random moves без softlock;
- queued moves не ломают поле;
- disabled feature flags возвращают игру в базовый режим;
- performance profile android_safe не превышает particle budget;
- telemetry JSON валиден;
- нет hardcoded balance numbers.

Формат финального отчета:
1. Что найдено в проекте.
2. Какие файлы созданы.
3. Какие файлы изменены.
4. Какие тесты добавлены.
5. Какие тесты прошли.
6. Какие риски остались.
7. Что делать в следующей фазе.
```

---

### 6. SYSTEM EVOLUTION PLAN

**Phase 5 — Advanced Special Economy**
```text
- Динамо-сфера
- Ядро сингулярности
- усиленные версии спец-сфер во время Fever
- редкие board-wide события
```

**Phase 6 — Adaptive Difficulty**
```text
- автонастройка Combo Window;
- снижение сложности после серии поражений;
- усиление целей для сильных игроков;
- adaptive hint system.
```

**Phase 7 — LiveOps Balance Dashboard**
```text
- экспорт telemetry;
- heatmap уровня;
- combo distribution;
- win-rate by level;
- special combo frequency;
- remote config.
```

**Phase 8 — Premium Feel Layer**
```text
- haptic patterns;
- layered music;
- unique signature sounds;
- cinematic combo titles;
- device-based VFX scaling.
```

---

### 7. RISKS & FAIL-SAFE

| Риск                        | Последствие            | Fail-safe                  |
| --------------------------- | ---------------------- | -------------------------- |
| Рассинхрон логики и визуала | сломанное поле         | BoardLogic source of truth |
| Бесконечный cascade         | softlock               | max cascade depth          |
| Очередь ходов устаревает    | неправильный swap      | expected_gem_id            |
| VFX перегружает экран       | FPS drop               | particle budget            |
| Fever слишком сильный       | уровень проходит сам   | multiplier cap             |
| Спец-комбо ломают баланс    | слишком легкая игра    | config tuning              |
| Targeting кажется случайным | игрок не доверяет игре | debug target scoring       |
| Ошибка FSM                  | зависание уровня       | FAILED_RECOVERY state      |

Итог: текущий документ можно считать **v4 WBS draft**, а усиленную версию выше — **v4.1 production execution plan**.
