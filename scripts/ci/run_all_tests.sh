#!/usr/bin/env bash
# /Users/user/3-line/scripts/ci/run_all_tests.sh
set -euo pipefail

echo "=== RUNNING ALL GUT TESTS ==="

GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Error: Godot executable not found at $GODOT_BIN" >&2
  exit 1
fi

"$GODOT_BIN" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/core_match3

echo "=== ALL TESTS COMPLETED SUCCESSFULLY ==="
