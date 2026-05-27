# Genesis v6 - Version Manifest

**Date**: 2026-05-27
**Status**: Active
**Previous**: v5

## Version Goals
Премиум UI/UX Soft Frost полировка всех **10 экранов геймплея и меню** 1к1 по референсам:
- Модуляризация оверлеев геймплея: вынос Паузы (Pause Menu), Победы (Level Complete) и Поражения (Out of Moves) в отдельные `.tscn` сцены.
- Полная визуальная полировка существующих экранов (Loading, Main Menu, World Map, Level Preview, HUD, Daily Rewards, Shop) под стиль "мягкого морозного люкса".
- Применение токенов из `res://data/ui/theme_tokens.json` и `ThemeTokens.gd` для исключения design drift.

## Major Changes
- [NEW] `scenes/gameplay/pause_menu.tscn` / `pause_menu.gd`
- [NEW] `scenes/gameplay/level_complete.tscn` / `level_complete.gd`
- [NEW] `scenes/gameplay/out_of_moves.tscn` / `out_of_moves.gd`
- [UPGRADE] Refactored `gameplay.gd` and `gameplay_overlay_controller.gd` to load the modular overlay scenes dynamically.
- [UPGRADE] Overhaul all existing menus and gameplay HUD interfaces to match 1-to-1 with reference mockups.

## Doc Checklist
- [x] 00_MANIFEST.md (This file)
- [x] concept_model.json
- [x] 01_PRD.md
- [x] 02_ARCHITECTURE_OVERVIEW.md
- [x] 03_ADR/
- [x] 04_SYSTEM_DESIGN/
- [x] 05_TASKS.md
- [x] 06_CHANGELOG.md
- [x] 07_INSTALLED_SKILLS.md
