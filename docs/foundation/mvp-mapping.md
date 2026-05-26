# MVP Feature-to-Module Mapping

This mapping enforces one owner module and one delivery phase per MVP capability.

| MVP Capability (`p2.md`) | Owner Module | Delivery Phase | Research Evidence (NotebookLM) |
| --- | --- | --- | --- |
| 8x8 board runtime | `core_match3` | Phase B | `[e27f8572-e6fb-4bd2-b027-396057b58482]` (Procedural Persona & Core) |
| Adjacent swap validation | `core_match3` | Phase B | `[e27f8572-e6fb-4bd2-b027-396057b58482]` (Procedural Persona & Core) |
| Match detection (3/4/5) | `core_match3` | Phase B | `[e27f8572-e6fb-4bd2-b027-396057b58482]` (Procedural Persona & Core) |
| Gravity and refill | `core_match3` | Phase B | `[e27f8572-e6fb-4bd2-b027-396057b58482]` (Procedural Persona & Core) |
| Cascade handling | `core_match3` | Phase B | `[e27f8572-e6fb-4bd2-b027-396057b58482]` (Procedural Persona & Core) |
| Goal tracking | `level_runtime` | Phase D | `[ab6a6583-bd54-4613-969d-804b0348302e]` (Architectural paradigms) |
| Move counter | `level_runtime` | Phase D | `[ab6a6583-bd54-4613-969d-804b0348302e]` (Architectural paradigms) |
| Score and stars | `level_runtime` | Phase D | `[ab6a6583-bd54-4613-969d-804b0348302e]` (Architectural paradigms) |
| Win/Lose state | `level_runtime` | Phase B | `[ab6a6583-bd54-4613-969d-804b0348302e]` (Architectural paradigms) |
| Pause screen | `presentation_layer` | Phase D | `[bbfb76b8-f87f-4ed7-a5c6-d3a0fe6b4a1f]` (Motion Design & UX) |
| Main menu / basic shell | `presentation_layer` | Phase D | `[bbfb76b8-f87f-4ed7-a5c6-d3a0fe6b4a1f]` (Motion Design & UX) |
| Save/load progress | `level_runtime` | Phase D | `[ab6a6583-bd54-4613-969d-804b0348302e]` (Architectural boundaries) |
| 10 level content pack | `data_layer` | Phase D | `[e27f8572-e6fb-4bd2-b027-396057b58482]` (Procedural Persona & Levels) |
| Base boosters set | `level_runtime` + `presentation_layer` | Phase D | `[ab6a6583-bd54-4613-969d-804b0348302e]` (Architectural boundaries) |
| Web export path | `presentation_layer` + build pipeline | Phase D | `[288e4620-53cb-45a6-ac3f-cad07dd64fa7]`, `[237d9ee0-aebc-4ec7-a3cb-ea67f87a274e]` (Godot CI Actions) |
| Android export path | `presentation_layer` + build pipeline | Phase D | `[288e4620-53cb-45a6-ac3f-cad07dd64fa7]`, `[237d9ee0-aebc-4ec7-a3cb-ea67f87a274e]` (Godot CI Actions) |
| Level simulator / auto-playtest (MCTS) | `validation` | Phase E | `[03b9112d-7407-46a1-b78f-428d7aa986e2]` (Automated Playtesting of Matching Tile Games) |
| Product Telemetry / Analytics | `meta_layer` | Phase F | `[bbfb76b8-f87f-4ed7-a5c6-d3a0fe6b4a1f]`, `[13a98938-bc9f-40a4-88ce-6c2fa14473c3]` (UX & Player Motivation) |
| Quality & Performance Profiles | `meta_layer` + `presentation_layer` | Phase F | `[bb43a60a-4b88-4c51-87dc-479046d564e7]` (Quality Profiles - Godot Asset Store) |

---

## Исследовательский бэклог (Research Backlog)

Обязательные исследовательские вехи и критерии приемки, извлеченные из `research_backlog.json`:

### Фаза A — Pre-production
*   **Задача**: Перенести ключевые исследовательские данные по CI/CD в чеклист реализации.
*   **Критерии приемки**:
    *   Решения зафиксированы в `decision-log.md`.
    *   Созданы TODO на уровне модулей в скриптах.
    *   Скрипты сборки привязаны к воротам качества (Quality Gates).
*   **Источники**: `[ab6a6583-bd54-4613-969d-804b0348302e]`, `[288e4620-53cb-45a6-ac3f-cad07dd64fa7]`, `[1e94ae18-1e9c-43c9-ac4e-4b05b0a456c4]`, `[237d9ee0-aebc-4ec7-a3cb-ea67f87a274e]`

### Фаза B — Prototype Core Loop
*   **Задача**: Интегрировать результаты исследований процедурной генерации контента для тестирования кор-лупа.
*   **Критерии приемки**:
    *   Наличие автоматического агента/имитатора игры для тестирования проходимости уровней.
    *   Фиксация балансовых метрик в логе решений.
*   **Источники**: `[e27f8572-e6fb-4bd2-b027-396057b58482]` (Conditional GANs для Match-3)

### Фаза C — Visual Integration
*   **Задача**: Интегрировать правила микро-анимаций и плавного motion-дизайна для мобильного UX.
*   **Критерии приемки**:
    *   Внедрение пружинящих (elastic) анимаций и шлейфов (trails) при swap-операциях.
    *   Соответствие таймингов анимации диапазонам из `master-blueprint-rules.md` (Select: 0.18s–0.35s, Swap: 0.22s–0.35s).
*   **Источники**: `[bbfb76b8-f87f-4ed7-a5c6-d3a0fe6b4a1f]` (Влияние motion-дизайна на удержание пользователей)

### Фаза D — MVP Production
*   **Задача**: Разработка и структурирование 10-уровневого контент-пака с поддержкой модификаторов и блокаторов.
*   **Критерии приемки**:
    *   Все 10 уровней проходят автоматические тесты `validate_content.gd` (размеры доски ≥8x8, ходы 14..30, положительный скор).
*   **Источники**: `[ab6a6583-bd54-4613-969d-804b0348302e]` (Архитектурные границы)

### Фаза E — Balance and Playtest
*   **Задача**: Интеграция исследовательских подходов для непрерывного playtesting-а и симуляции сложности баланса.
*   **Критерии приемки**:
    *   Интеграция скрипта симуляции `simulate_levels.gd` для проверки проходимости всех 10 уровней сходимости баланса.
    *   Логирование калибровочных решений и прохождения ботов в логе решений (`decision-log.md`).
*   **Источники**: `[03b9112d-7407-46a1-b78f-428d7aa986e2]` (Automated Playtesting of Matching Tile Games - arXiv)

### Фаза F — Soft Launch Prep
*   **Задача**: Интеграция профилей качества, телеметрии удержания и этичных принципов монетизации перед мягким запуском.
*   **Критерии приемки**:
    *   Наличие `soft_launch_config.json` с профилями качества (`web_default`, `android_safe`) и лимитами производительности.
    *   Запись 9 типов событий в локальный лог телеметрии `AnalyticsTracker`.
    *   Автоматическая валидация через `--smoke-soft-launch` сценарии.
*   **Источники**: `[bbfb76b8-f87f-4ed7-a5c6-d3a0fe6b4a1f]` (The Impact of Motion Design on UX), `[d9a3ab01-7ff6-481e-bb0f-28120d4a2f7b]` (Perceived Values and Dark Patterns), `[13a98938-bc9f-40a4-88ce-6c2fa14473c3]` (Player motivation to purchase)

---

## Этические принципы и ограничения монетизации (Game Design Ethics)

Согласно результатам анализа удержания и манипулятивных механик из NotebookLM Deushare, в проекте устанавливаются следующие обязательные принципы:
1.  **Никаких скрытых циклов давления**: Запрещается использовать скрытые вероятности или искусственные ограничения, вынуждающие совершать внутриигровые покупки.
2.  **Запрет фейковых скидок и ложных якорей цен**: Цены на косметические наборы должны быть честными и прозрачными (запрещена механика фейкового зачёркивания цен).
3.  **Прозрачность вероятностей**: Если используются случайные награды или дроп-эффекты, их вероятности должны быть явно раскрыты игроку. Без paywall-only progression.
4.  **Фокус на честном удержании (Fair Retention)**: Удержание игроков строится на интересной прогрессии, качественном медитативном UX и тактильной обратной связи, а не на навязчивых таймерах ожидания жизней (в MVP жизни исключены для поддержания calm-атмосферы).


