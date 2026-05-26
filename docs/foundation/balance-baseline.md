# Balance Baseline

This file records the current accepted balance baseline after the latest content-only tuning pass.

## Acceptance Threshold

- Every shipped level must have a non-zero automated win rate.
- `scripts/validation/simulate_levels.gd` is the primary regression gate.
- Content data is tuned first; scoring logic changes are deferred unless content-only tuning is insufficient.

## Current Baseline

Validation command:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/user/3-line --script res://scripts/validation/simulate_levels.gd
```

Accepted outcome:

- Level `001`: `win_rate=1.00`, `avg_moves_left=14.00`
- Level `002`: `win_rate=1.00`, `avg_moves_left=21.20`
- Level `003`: `win_rate=1.00`, `avg_moves_left=6.00`
- Level `004`: `win_rate=1.00`, `avg_moves_left=13.00`
- Level `005`: `win_rate=1.00`, `avg_moves_left=11.80`
- Level `006`: `win_rate=1.00`, `avg_moves_left=19.20`
- Level `007`: `win_rate=1.00`, `avg_moves_left=6.20`
- Level `008`: `win_rate=1.00`, `avg_moves_left=10.20`
- Level `009`: `win_rate=1.00`, `avg_moves_left=8.00`
- Level `010`: `win_rate=1.00`, `avg_moves_left=8.40`

## Content Notes

- Levels `002-010` were made winnable using only level JSON tuning.
- No changes were required in `ScoreSystem`, `GoalTracker`, or `core_match3` rules to clear the current regression.
- This baseline is intentionally generous; future difficulty increases should be done gradually and always re-validated through simulation.
