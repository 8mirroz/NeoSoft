# Genesis v4 - Version Manifest

**Date**: 2026-05-26
**Status**: Active
**Previous**: v3

## Version Goals
Разработка архитектуры и продуктовых требований для **Combo Fever Engine** — отдельного системного слоя игры, который управляет матчами, вводом во время каскадов, VFX/SFX-градацией (tier ladder), спец-сферами, балансом, телеметрией и интеграцией с целями уровня.

## Major Changes
- Внедрение Resolver Pipeline для обработки фаз матча, гравитации и каскадов.
- Интеграция Input Buffer Controller для поддержки ввода (queued moves) во время каскадов.
- Добавление Match Shape Detector для расширенного распознавания фигур (квадрат 2x2, L/T, 5 в линию, крест, complex 6/7+).
- Определение матрицы создания спец-сфер (Лучевая, Взрывная, Наводящаяся, Призматическая, Динамо, Ядро сингулярности).
- Определение Special Combination Matrix для слияния двух спец-сфер.
- Внедрение Target Priority System для наводящихся сфер по целям уровня.
- Добавление Combo Window и Fever Mode со скоринг-мультипликаторами и динамическим сжатием времени.
- Разработка Feedback Orchestrator с VFX/SFX/UI Tier Ladder и лимитами производительности (performance tiers).
- Определение Balance Telemetry Layer для сбора метрик MVP.

## Doc Checklist
- [x] 00_MANIFEST.md (This file)
- [x] 01_PRD.md
- [x] 02_ARCHITECTURE_OVERVIEW.md
- [x] 03_ADR/ADR_001_TECH_STACK.md
- [x] 03_ADR/ADR_002_RESOLVER_PIPELINE.md
- [x] 03_ADR/ADR_003_INPUT_BUFFER_CONTROLLER.md
- [x] 03_ADR/ADR_004_MATCH_SHAPE_DETECTOR.md
- [x] 03_ADR/ADR_005_TARGET_PRIORITY_SYSTEM.md
- [x] 03_ADR/ADR_006_FEEDBACK_ORCHESTRATOR.md
- [x] 03_ADR/ADR_007_TELEMETRY_BALANCE_SYSTEM.md
- [x] 04_SYSTEM_DESIGN/combo_fever_engine.md
- [x] 06_CHANGELOG.md
- [x] 07_INSTALLED_SKILLS.md
