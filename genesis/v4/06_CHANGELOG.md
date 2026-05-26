# Changelog - Genesis v4

> Этот файл фиксирует изменения в архитектуре версии 4 (Combo Fever Engine — Advanced Match-3 Mechanics System).

## Формат
- **[ADD]** Добавление новых документов или разделов
- **[CHANGE]** Корректировка существующих архитектурных документов
- **[FIX]** Исправление ошибок/несоответствий
- **[REMOVE]** Удаление устаревших разделов

---

## 2026-05-26 - Инициализация v4
- [ADD] Создание манифеста `00_MANIFEST.md`
- [ADD] Разработка PRD для Combo Fever Engine `01_PRD.md`
- [ADD] Разработка архитектурного обзора `02_ARCHITECTURE_OVERVIEW.md`
- [ADD] Создание набора ADR по ключевым подсистемам:
  - `ADR_001_TECH_STACK.md` (Технологический стек ядра Godot 4 / GDScript)
  - `ADR_002_RESOLVER_PIPELINE.md` (Resolver Pipeline и состояния ячеек)
  - `ADR_003_INPUT_BUFFER_CONTROLLER.md` (Очередь ходов во время анимаций)
  - `ADR_004_MATCH_SHAPE_DETECTOR.md` (Матрица распознавания фигур и спец-сферы)
  - `ADR_005_TARGET_PRIORITY_SYSTEM.md` (Приоритет выбора целей для наведения)
  - `ADR_006_FEEDBACK_ORCHESTRATOR.md` (Tier Ladder для VFX/SFX/UI и лимиты)
  - `ADR_007_TELEMETRY_BALANCE_SYSTEM.md` (Сбор игровых метрик и конфиг баланса)
- [ADD] Разработка детального системного дизайна `04_SYSTEM_DESIGN/combo_fever_engine.md`
- [ADD] Добавление `07_INSTALLED_SKILLS.md` с фиксацией активных навыков для Godot Match-3
