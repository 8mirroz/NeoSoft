# Product Requirements Document (PRD) — Версия 5.0

# Controlled Cascade Pleasure Engine + UI/UX System

Этот документ описывает продуктовые требования к **Controlled Cascade Pleasure Engine (CCPE)** — production-ready эволюции Combo Fever Engine (v4) для Match-3 игры **Neo Soft Frost**. Фокус v5 — полная каскадная система с governance, расширенная экономика спец-сфер, premium feedback и 10 UI-экранов.

---

## 1. Executive Summary

### Проблема
v4 Combo Fever Engine заложил фундамент (9 подсистем, FSM pipeline, input buffer), но для production-уровня не хватает:
- **Controlled Cascade** — управляемых каскадов с Natural/Assisted/Cinematic Drop
- **Shape Economy** — расширенной системы форм (11 vs 7) с читаемой связью "форма → награда"
- **Balance Governance** — жёстких лимитов против "игра играет сама"
- **Premium Feedback** — juicy VFX/SFX по каскад-лестнице (x1–x5+)
- **UI/UX** — полноценной системы экранов

### Решение
**Controlled Cascade Pleasure** = controlled drop + shape merge + readable special creation + escalating VFX/SFX + player agency during cascades.

### Формула игры
```
Умный ход игрока
→ читаемая форма
→ спец-сфера
→ каскад сверху
→ cascade-born бонус
→ escalating VFX/SFX
→ Fever заряд
→ новый быстрый ход в Combo Window
→ поле оживает, но игрок остаётся главным источником силы
```

---

## 2. Бизнес-цели

1. **Controlled Cascade Pleasure**: каждый умный ход запускает живое поле без ощущения фейка
2. **Shape → Reward Predictability**: игрок всегда понимает, что получит за конкретную форму (как Candy Crush)
3. **Anti-Auto-Win**: победа никогда не выглядит полностью автоматической
4. **Premium Juicy Feel**: VFX/SFX-градация создаёт ощущение мастерства
5. **Production UI/UX**: 10 экранов в стиле "мягкий морозный luxe" — glassmorphism, holographic spheres, dreamy palette

---

## 3. 6-Layer Architecture Model

```
Layer 1. Deterministic Core       — матчи, формы, падения, цели, блокеры
Layer 2. Controlled Probability   — Assisted/Lucky/Cinematic Drop под BalanceGovernor
Layer 3. Shape Economy            — 11 форм, ценность, награда, прогрессивное открытие
Layer 4. Special Sphere Ecosystem — 10 спец-сфер + 15 комбинаций + target priority
Layer 5. Juicy Feedback Director  — VFX/SFX/slow-mo/camera/haptics/titles
Layer 6. Telemetry + Auto-Balance — метрики, анализ, авто-корректировка
```

---

## 4. Детальные функциональные требования

### [REQ-CCPE-501] Controlled Cascade Engine
- **Описание**: Три режима выпадения сфер после очистки.
- **Natural Drop**: честное выпадение, assisted_probability = 0.0
- **Assisted Drop**: мягко повышает шанс каскада после хорошего хода
  - `allowed_when`: player_created_shape, combo_power_above_threshold, not_recently_assisted, not_near_auto_win_abuse
- **Cinematic Drop**: редкий постановочный каскад
  - `allowed_when`: fever_active, final_move_drama, tutorial_showcase, boss_level_moment
- **Acceptance Criteria**:
  - *Given*: Игрок создал L-форму (blast sphere)
  - *When*: CascadeEngine проверяет assisted_drop
  - *Then*: Если cooldown прошёл и win_probability < threshold, допускается мягкий assisted drop с cascade_chance [0.30, 0.45]

### [REQ-CCPE-502] Cascade Probability Bands
- **Описание**: Вероятности автокаскада зависят от мощности хода.
- **Bands**:
  - basic_move: [0.10, 0.18]
  - line_4_or_square_2x2: [0.20, 0.30]
  - l_t_or_line_5: [0.30, 0.45]
  - fever: [0.45, 0.65]
  - final_near_goal: [0.50, 0.75] (ограничения: только если близко к цели, max 1/level)
- **Acceptance Criteria**:
  - *Given*: Fever активен
  - *When*: Происходит каскад
  - *Then*: Вероятность следующего автокаскада в диапазоне [0.45, 0.65]

### [REQ-CCPE-503] Shape Merge Matrix 2.1 (11 форм → 10 спец-сфер)
- **Описание**: Полная матрица распознавания форм и создания спец-сфер.
- **Mapping**:

| Форма | Спец-сфера | Эффект | Spawn Rule |
|---|---|---|---|
| line_4 | Beam Sphere | clear_row_or_column | moved_cell |
| square_2x2 | Homing Sphere | fly_to_priority_target | geometric_center |
| l_5 | Blast Sphere | radius_explosion | elbow_cell |
| t_5 | Pulse Sphere | cross_plus_micro_blast | center_cell |
| line_5 | Prism Sphere | remove_or_convert_color_type | moved_cell |
| cross_5 | Cross Sphere | row_column_center_burst | center_cell |
| hook_6 | Gravity Sphere | pull_then_match | elbow_cell |
| zigzag_6 | Lightning Sphere | chain_hit_priority_targets | highest_value_cell |
| rectangle_2x3 | Field Sphere | clear_2x3_or_3x2_area | geometric_center |
| complex_7_plus | Dynamo Sphere | large_radius_blast | strategic_cell |
| rare_9_plus | Singularity Core | board_wave_and_layer_strip | center_or_strategic_cell |

- **Acceptance Criteria**:
  - *Given*: Игрок создаёт zigzag-6 форму
  - *When*: ShapeDetector классифицирует как ZIGZAG_6
  - *Then*: SpecialFactory создаёт Lightning Sphere в ячейке с наибольшей стратегической ценностью

### [REQ-CCPE-504] Spawn Location Rules
- **Описание**: 5 детерминированных правил размещения спец-сфер.
1. **Manual Match**: спец-сфера в клетке swap
2. **Cascade Match**: в геометрическом центре формы
3. **Complex Shape**: клетка с max стратегической ценностью
4. **Goal Adjacent**: если рядом с целью, spawn смещается ближе
5. **Conflict**: если клетка заблокирована, ближайшая валидная
- **Acceptance Criteria**:
  - *Given*: Cascade match формирует L-форму
  - *When*: Center cell заблокирована льдом
  - *Then*: Spawn смещается на ближайшую валидную ячейку

### [REQ-CCPE-505] Special Combo Matrix (15 комбинаций)
- **Описание**: Объединение двух спец-сфер свайпом.
- **Matrix**:

| Комбинация | Эффект |
|---|---|
| beam+beam | clear_row_and_column |
| beam+blast | clear_3_rows_and_3_columns |
| blast+blast | radius_4_explosion |
| homing+beam | carry_beam_to_priority_target |
| homing+blast | carry_blast_to_priority_target |
| homing+homing | spawn_3_homing_spheres |
| prism+beam | convert_most_common_color_to_beams |
| prism+blast | convert_most_common_color_to_blasts |
| prism+homing | convert_most_common_color_to_homing |
| prism+prism | clear_board_and_strip_one_blocker_layer |
| gravity+blast | pull_then_large_explosion |
| lightning+beam | chain_5_targets_plus_row_clear |
| lightning+blast | chain_5_targets_plus_radius_blast |
| singularity+any | amplify_target_special_to_board_scale |
| cross+prism | convert_color_to_crosses_then_activate |

- **Acceptance Criteria**:
  - *Given*: Prism + Beam на соседних ячейках
  - *When*: Игрок свайпает между ними
  - *Then*: Все сферы самого частого цвета конвертируются в Beam Spheres и активируются

### [REQ-CCPE-506] Balance Governor
- **Описание**: Жёсткие лимиты для контроля честности.
- **Parameters**:
  - max_cascade_depth_default: 5
  - max_cascade_depth_fever: 8
  - lucky_drop_max_per_level: 2
  - lucky_drop_min_turn_gap: 5
  - assisted_drop_cooldown_turns: 3
  - assisted_drop_max_per_level: 4
  - cinematic_drop_max_per_level: 1
  - anti_fake_rules: never_guarantee_paid_recovery, never_force_loss_state, never_auto_complete_major_objective
- **Acceptance Criteria**:
  - *Given*: Cascade depth = 5 (max)
  - *When*: Новый потенциальный cascade match найден
  - *Then*: CascadeGovernor блокирует и стабилизирует поле

### [REQ-CCPE-507] Target Priority System 2.0
- **Описание**: Расширенная система приоритетов для наводящихся сфер.
- **Priority Order** (score):
  - 100: level_objective_critical
  - 90: locked_objective
  - 80: blocker_with_1_hp
  - 75: corner_or_hard_to_reach_goal
  - 65: portal_blocker
  - 60: infection_source
  - 50: ancient_core_charge_cell
  - 40: highest_combo_potential_cell
  - 20: useful_random
- **Acceptance Criteria**:
  - *Given*: На поле есть лёд в углу (0,0) с score=75 и обычная цель (4,4) с score=100
  - *When*: Активируется Homing Sphere
  - *Then*: Летит к (4,4) — level_objective_critical имеет высший приоритет

### [REQ-CCPE-508] Queued Input System + Combo Window
- **Описание**: Во время каскада игрок может поставить swap в очередь.
- **Queued Input**:
  - enabled: true
  - allowed_during: clear_animation, drop_animation, vfx_non_blocking
  - blocked_when: cell_is_falling, cell_is_exploding, cell_is_locked, board_is_resolving_special_combo
  - reward: fast_chain_bonus, combo_window_extension +0.8
- **Combo Window**:
  - duration_sec: 1.2 after first combo
  - visual: radial_countdown_bar
  - successful_fast_move: combo_multiplier + fever_charge_bonus + special_spawn_modifier_chance
  - failed_window: обычная игра продолжается без наказания
- **Acceptance Criteria**:
  - *Given*: Каскад с clear_animation идёт
  - *When*: Игрок свайпает в стабильной зоне
  - *Then*: Swap ставится в очередь и выполняется как только cells стабилизируются

### [REQ-CCPE-509] Cascade Reward Psychology (VFX/SFX Ladder)
- **Описание**: Эскалация обратной связи по каскад-лестнице.
- **Tiers**:
  - x1 "Nice": small_flash, soft_ping, fever_charge 1.0
  - x2 "Combo": ripple_wave, layered_chime, fever_charge 1.4
  - x3 "Chain Reaction": board_pulse, rising_tone, fever_charge 1.9
  - x4 "Cascade Surge": energy_lines, bass_impact, fever_charge 2.6
  - x5+ "Fever Spark": mini_fever_aura, signature_combo_hit, fever_charge 3.5
- **Acceptance Criteria**:
  - *Given*: Cascade chain index = 4
  - *When*: Следующий автоматический матч
  - *Then*: Показывается "Cascade Surge" title, energy_lines VFX, bass_impact SFX

### [REQ-CCPE-510] Fever Meter & Fever Mode
- **Описание**: Fever активируется при Combo x5+ или при накоплении Fever Meter.
- **Parameters**:
  - threshold: 5 combo или meter >= 100%
  - duration: 5–8 seconds
  - multiplier: x2.5
  - fever_rain: увеличенная вероятность спец-сфер в drop
  - cascade_depth_override: 8 (vs default 5)
- **Acceptance Criteria**:
  - *Given*: Combo counter = x5
  - *When*: Порог достигнут
  - *Then*: Fever Mode активируется, множитель x2.5, cascade depth = 8

### [REQ-CCPE-511] Telemetry Layer
- **Описание**: Расширенный набор метрик для баланса и аналитики.
- **Core metrics**: move_count, match_count, cascade_frequency, cascade_depth_average, max_cascade_depth, cascade_born_special_rate, special_sphere_creation_rate
- **Psychology metrics**: combo_window_success_rate, player_idle_time_during_cascade, queued_input_usage_rate, fever_activation_rate
- **Balance metrics**: assisted_drop_usage_rate, lucky_drop_rate, level_win_rate_delta, fail_streak_before_assist, no_move_shuffle_rate, objective_completion_source_manual_vs_cascade_vs_special
- **Readability metrics**: vfx_overlap_duration, input_block_time, board_stabilization_time

### [REQ-CCPE-512] Level Mechanics Expansion
- **Описание**: Прогрессивное открытие механик по уровням.
- **Phase Unlock Order**:
  - Levels 1–10: 3-match, line-4, Beam Sphere
  - Levels 11–20: L/T, Blast/Pulse Sphere, simple blockers
  - Levels 21–35: 2×2 Homing Sphere, target priority objectives, ice layers
  - Levels 36–50: Prism Sphere, special+special combos, chain locks
  - Levels 51–75: portals, resonance cells, cascade contracts
  - Levels 76–100: Gravity Sphere, infection/shadow cells, ancient cores
  - 100+: directional gravity, boss-level cascade puzzles, singularity events

---

## 5. UI/UX Requirements (10 Screens)

### [REQ-UI-601] Loading Screen
- Logo "Neo Soft Frost" с holographic сферой
- Tagline: "Match the magic. Restore the light."
- Progress bar с gradient (blue→pink→gold)
- "Tap to Start" prompt
- Стиль: dreamy clouds, floating bubbles, sparkle particles

### [REQ-UI-602] Main Menu
- Центральная holographic сфера на стеклянном подиуме
- Кнопка "Play" — glassmorphic pill с gradient
- 4 quick-access: Levels, Events, Shop, Settings
- Top bar: Coins (gold) + Stars (yellow) + Inbox (envelope с badge)
- Bottom nav: Home, Rankings, Collection, Friends, Inbox
- Стиль: мягкие лавандово-розовые тона, подвешенные кристаллы, bubble декор

### [REQ-UI-603] World Map
- Название текущего мира: "Dreamy Skies"
- Извилистый путь из стеклянных сфер-нодов (уровни 1–12+)
- Звёзды под каждой сферой (0–3 ★)
- Locked уровни с иконкой замка
- "You are here" tooltip на текущем уровне
- Боковые кнопки: Events, Leaderboard
- "Next World" preview card (e.g., "Crystal Vale ★ 0/36")
- Bottom nav: Home, Rankings, World, Collection, Inbox

### [REQ-UI-604] Level Preview
- Заголовок "Level N" + Difficulty badge (Easy/Medium/Hard)
- Mission target: 3 типа сфер с количеством
- Level preview: миниатюрное поле с блокерами
- Select boosters: Shuffle (x12), Hammer (x15), Rainbow Orb (x8)
- Rewards preview: Coins + Stars
- Кнопка "Start" — gradient pill

### [REQ-UI-605] Gameplay HUD
- Top bar: "Neo Soft Frost" | Mission target (3 icons + counts) | "Moves: N" | "Score: N"
- Progress bar с rainbow gradient + 3 звезды
- Игровое поле 8×8 в glassmorphic frame
- Bottom target panel: 3 объектива с progress bars
- Bottom boosters: Shuffle, Hammer, Undo с badge counts
- Боковые diamond markers (左右) для активации спец-эффектов
- Combo Window: radial glow ring вокруг поля

### [REQ-UI-606] Pause Menu
- Blurred gameplay background
- Glassmorphic modal с 3 кнопками: Resume, Restart, Home
- Sound settings: Music slider, Sound slider, Haptics toggle
- Close (X) button
- Diamond separators

### [REQ-UI-607] Level Complete
- Заголовок "Level Complete" с confetti
- 3 звезды (animated fill)
- Score display + "Best Score" + "NEW BEST!" badge
- Rewards: Coins + Stars
- "Next Level >" button
- "Share" button

### [REQ-UI-608] Out of Moves
- Star icon (sad/empty)
- Заголовок "Out of Moves"
- Subtitle: "You're so close! Try again or add a few more moves."
- Mission target с checkmarks
- "Retry" primary button
- "Add 5 Moves" — 900 coins option
- "Home" button

### [REQ-UI-609] Daily Rewards
- 7-day calendar strip (Day 1–7)
- Claimed/current/future states
- Today's Featured Reward showcase (e.g., Premium Bubble на подиуме)
- "Claim" button
- Daily Quests section: 4 задания с progress bars и звёздными наградами

### [REQ-UI-610] Shop
- Tabs: Coins | Boosters | Specials
- Coin Packs: Pile ($1.99) → Stack ($4.99) → Chest ($9.99) → Vault ($19.99)
- Booster Bundles: Starter (150 coins) → Power (250) → Pro (450)
- Featured items: Rainbow Orb (400 coins), Blossom Season Pack ($7.99 "Best Value")
- Bottom nav: Home, Rankings, Collection, Friends, Inbox

---

## 6. Нефункциональные требования

- **Performance**: max 40 particle systems active, camera shake max 2x/3sec, VFX budget enforced
- **Governance**: all balance numbers in JSON, feature flags per subsystem
- **Safety**: forced stabilization on any pipeline failure, max cascade depth enforced
- **Accessibility**: colorblind sphere shapes, sound alternatives for visual cues
- **Monetization**: "Add 5 Moves" never guarantees win, never force loss state

---

## 7. Design Language

- **Palette**: Lavender (#D8CCFF), Soft Pink (#FFD4E8), Ice Blue (#CCECFF), Warm Gold (#FFD700), Crystal White (#F8F6FF)
- **Typography**: Rounded sans-serif (похоже на Nunito/Comfortaa/Quicksand)
- **UI Style**: Glassmorphism — frosted glass panels, soft shadows, iridescent borders
- **Sphere Style**: Holographic, transparent with internal refractions, soft glow
- **Decorations**: Floating bubbles, diamond crystals, sparkle particles, dreamy clouds
- **Animations**: Bounce-in for modals, fade+scale for transitions, particle burst on match

---

## 8. Вне скоупа (Out of Scope)

- Multiplayer / real-time PvP
- Story mode / narrative chapters
- Full 3D rendering pipeline
- Server-side match validation
- A/B testing infrastructure
- Cross-platform save sync
