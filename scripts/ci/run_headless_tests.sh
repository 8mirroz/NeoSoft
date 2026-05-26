#!/bin/bash
# /Users/user/3-line/scripts/ci/run_headless_tests.sh

## CI Headless Test Runner.
## Запускает все тесты GUT в безголовом режиме и возвращает exit code.
set -u

echo "==============================================="
echo "🎮 Starting Headless GUT Test Suite..."
echo "==============================================="

# Проверяем наличие установленного Godot в системе
if ! command -v godot &> /dev/null
then
    echo "❌ Error: 'godot' command line utility not found in PATH."
    echo "Fallback: Trying default macOS application path..."
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
else
    GODOT_BIN="godot"
fi

if [ ! -f "$GODOT_BIN" ] && [ "$GODOT_BIN" != "godot" ]; then
    echo "❌ Error: Godot binary not found at $GODOT_BIN"
    exit 1
fi

# Создаем папку под логи, если её нет
mkdir -p artifacts/testing

GUT_ENTRYPOINT="addons/gut/gut_cmdln.gd"
if [ ! -f "$GUT_ENTRYPOINT" ]; then
    echo "❌ Error: GUT entrypoint not found: $GUT_ENTRYPOINT"
    exit 1
fi

# Запускаем тесты GUT в headless режиме
echo "🚀 Running tests..."
$GODOT_BIN --headless --path . -s "$GUT_ENTRYPOINT" -gdir=res://tests -ginclude_subdirs > artifacts/testing/last_test_run.log 2>&1
TEST_RESULT=$?

# Выводим логи в консоль
cat artifacts/testing/last_test_run.log

# Защита от ложноположительного успеха:
# иногда Godot завершает процесс кодом 0, даже если скрипт не загрузился.
if grep -Eq "(Failed loading resource|Failed to load script|Can't load script|SCRIPT ERROR:|Parse Error:|Parse error|Compile Error:|Compilation failed|ERROR: Failed to load)" artifacts/testing/last_test_run.log; then
    echo "==============================================="
    echo "❌ Error: Runtime/compile/script loading errors detected in logs."
    echo "Check full logs in 'artifacts/testing/last_test_run.log'"
    echo "==============================================="
    exit 1
fi

if [ $TEST_RESULT -eq 0 ]; then
    echo "==============================================="
    echo "✅ Success: All tests passed!"
    echo "==============================================="
    exit 0
else
    echo "==============================================="
    echo "❌ Error: One or more tests failed!"
    echo "Check full logs in 'artifacts/testing/last_test_run.log'"
    echo "==============================================="
    exit $TEST_RESULT
fi
