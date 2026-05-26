# Soft Launch Release Checklist

Use this checklist before a soft-launch candidate is approved.

## Runtime And Progression

- [x] Start from boot and reach main menu cleanly. (automated)
- [x] Main menu opens level select. (automated)
- [x] Level select opens gameplay for unlocked levels. (automated)
- [x] Retry flow returns to the same level correctly. (automated)
- [x] Winning a level unlocks the next level. (automated method-level check)
- [x] Save/load persistence survives app restart. (automated method-level check)

## Gameplay Safety

- [x] Valid swap resolves correctly. (automated through undo snapshot creation path)
- [ ] Invalid swap is rejected with visible feedback. (logic rejection is automated; visual readability remains manual)
- [ ] Match, collapse, spawn, and cascade feedback remain readable.
- [x] Pause and resume do not corrupt board state. (automated)
- [x] Undo restores the previous playable state. (automated)
- [x] Dead-board recovery reshuffles successfully. (automated)

## Automated Gate Commands

Run these before manual device QA:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/user/3-line --scene res://scenes/boot/boot.tscn -- --smoke-soft-launch
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/user/3-line --script res://scripts/validation/validate_content.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/user/3-line --script res://scripts/validation/validate_visuals.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/user/3-line --script res://scripts/validation/simulate_levels.gd
```

## Telemetry Baseline

- [x] `session_started`
- [x] `level_started`
- [x] `booster_used`
- [x] `undo_used`
- [x] `level_finished`
- [x] `dead_board_detected`
- [x] `auto_shuffle_applied`
- [x] `level_retry_requested`
- [x] `return_to_level_select`

Analytics events are written by `AnalyticsTracker` to `user://analytics_events.jsonl` when analytics are enabled in `config/soft_launch_config.json`.

## Quality Profiles

- [x] `web_default` exists
- [x] `android_safe` exists
- [ ] Manual verification completed with `web_default`
- [ ] Manual verification completed with `android_safe`

## Export And Release

- [x] Export presets are committed.
- [x] CI workflows exist for export lanes.
- [ ] Local Web export succeeds.
- [ ] Local Android export succeeds.
- [ ] Release artifacts are smoke-tested after export.
