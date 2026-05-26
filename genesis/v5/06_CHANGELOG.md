# Changelog - Genesis v5

> Этот файл фиксирует изменения в архитектуре версий 4 и 5 для игры **Neo Soft Frost**.

## Формат
- **[ADD]** Добавление новых документов или разделов
- **[UPGRADE]** Обновление существующих архитектурных спецификаций
- **[FIX]** Исправление ошибок/несоответствий
- **[REMOVE]** Удаление устаревших разделов

---

## 2026-05-26 - Инициализация v5 (Controlled Cascade Pleasure Engine & UI/UX)
- [ADD] Создание обновленного манифеста `00_MANIFEST.md` для v5.
- [ADD] Разработка PRD для Controlled Cascade Pleasure Engine (CCPE) + UI/UX System `01_PRD.md` (22 функциональных требования).
- [ADD] Создание архитектурного обзора v5 `02_ARCHITECTURE_OVERVIEW.md` с 6-слойной моделью и 15 подсистемами.
- [ADD] Создание новых архитектурных решений (ADRs):
  - `ADR_008_CONTROLLED_CASCADE.md` (Управляемые каскады и Probability Bands)
  - `ADR_009_BALANCE_GOVERNOR.md` (Политика Balance Governor и защита от фейков)
  - `ADR_010_UI_UX_SYSTEM.md` (Архитектура 10 экранов интерфейса Neo Soft Frost)
- [ADD] Создание детального системного дизайна CCPE `04_SYSTEM_DESIGN/controlled_cascade_engine.md` (Layer 2 с GDScript контрактами, псевдокодом, MCTS и FSM).
- [ADD] Создание системного дизайна UI/UX `04_SYSTEM_DESIGN/ui_ux_system.md` (Архитектура UIScreenManager и спецификации экранов).
- [ADD] Создание дизайн-системы `04_SYSTEM_DESIGN/ui-ux-design-system.md` (Neo Soft Frost Design System v1.0, Token layer, Glassmorphism).
- [ADD] Создание motion-системы `04_SYSTEM_DESIGN/motion-animation-system.md` (Навигационные, геймплейные и Fever анимации).
- [UPGRADE] Обновление `07_INSTALLED_SKILLS.md` под требования CCPE v5.

---

## 2026-05-26 - Инициализация v4
- [ADD] Создание манифеста `00_MANIFEST.md` для v4.
- [ADD] Разработка PRD для Combo Fever Engine `01_PRD.md` для v4.
- [ADD] Разработка архитектурного обзора `02_ARCHITECTURE_OVERVIEW.md` для v4.
- [ADD] Создание набора ADR по ключевым подсистемам (ADR_001–ADR_007):
  - `ADR_001_TECH_STACK.md` (Технологический стек ядра Godot 4 / GDScript)
  - `ADR_002_RESOLVER_PIPELINE.md` (Resolver Pipeline и состояния ячеек)
  - `ADR_003_INPUT_BUFFER_CONTROLLER.md` (Очередь ходов во время анимаций)
  - `ADR_004_MATCH_SHAPE_DETECTOR.md` (Матрица распознавания фигур и спец-сферы)
  - `ADR_005_TARGET_PRIORITY_SYSTEM.md` (Приоритет выбора целей для наведения)
  - `ADR_006_FEEDBACK_ORCHESTRATOR.md` (Tier Ladder для VFX/SFX/UI и лимиты)
  - `ADR_007_TELEMETRY_BALANCE_SYSTEM.md` (Сбор игровых метрик и конфиг баланса)
- [ADD] Разработка детального системного дизайна `04_SYSTEM_DESIGN/combo_fever_engine.md`
- [ADD] Добавление `07_INSTALLED_SKILLS.md` с фиксацией активных навыков для Godot Match-3.
