# MVP Checklist

Use this document as the release-truth checklist for Phase D.

## Gameplay Core

- [x] 8x8 board runtime exists in `core_match3`.
- [x] Adjacent swap validation is enforced.
- [x] Match detection, clear, gravity, refill, and cascades are implemented.
- [x] Win/lose states are driven by `level_runtime`.

## Player-Facing MVP

- [x] Score, stars, moves, and goals are shown in gameplay HUD.
- [x] Pause, retry, next level, and level select flows exist.
- [x] Base boosters exist: `Hammer`, `Shuffle`, `Undo`.
- [x] Progress persistence exists through `UserData`.
- [x] Main menu and level select flows exist.
- [x] Ten JSON-authored levels exist in `data/levels/`.

## Quality Gates

- [x] Headless syntax check passes.
- [x] Content validation passes.
- [x] Visual validation passes.
- [x] Simulation validation passes for levels `001-010`.

## Export Readiness

- [x] `export_presets.cfg` includes `Web` and `Android`.
- [x] GitHub Actions workflows exist for Web and Android export lanes.
- [ ] Local Web export verified on this machine.
- [ ] Local Android export verified on this machine.

Local export remains blocked by missing Godot export templates and missing Android SDK/JDK editor configuration. See `export-readiness.md`.
