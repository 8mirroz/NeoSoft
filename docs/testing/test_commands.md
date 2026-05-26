# Automated Testing Guide — Neo Soft Frost

> **Specification Version**: `genesis/v5.1`  
> **Status**: ACTIVE & FROZEN (Architecture Control Plan)

Этот документ содержит описание всех тестовых команд, конфигурации автоматического тест-раннера и регламент запуска юнит/интеграционных/E2E тестов в системе **Neo Soft Frost**.

---

## 1. Консольные скрипты тестирования (CI Test Runners)

Для упрощения автозапуска и интеграции с CI/CD в каталоге `scripts/ci/` развернуты два командных файла:

### 1.1 `run_all_tests.sh` (`res://scripts/ci/run_all_tests.sh`)
Запускает весь набор юнит-тестов ядра игры в безголовом (headless) режиме с выводом результатов GUT в консоль.
- **Команда для запуска**:
  ```bash
  ./scripts/ci/run_all_tests.sh
  ```

### 1.2 `run_headless_tests.sh` (`res://scripts/ci/run_headless_tests.sh`)
Консольный ранер, используемый сервером непрерывной интеграции (CI) для жесткой валидации фиксаций коммитов.
- **Команда для запуска**:
  ```bash
  ./scripts/ci/run_headless_tests.sh
  ```

---

## 2. Команды ручного запуска через терминал (Manual Commands)

Вы можете запускать тесты вручную, передавая расширенные параметры в командную строку Godot:

* **Запустить тесты конкретного класса**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/core_match3 -gselect=test_input_buffer_controller.gd
  ```

* **Запустить конкретный юнит-тест внутри класса**:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/core_match3 -gselect=test_input_buffer_controller.gd -gunit=test_queue_limit_and_multiple_enqueues
  ```

---

## 3. Регламент запуска тестов (QA Readiness Gate)

1. **Перед коммитом (Pre-commit hook)**: Разработчик обязан локально прогнать скрипт `./scripts/ci/run_all_tests.sh`. Коммит разрешен только при 100% прохождении тестов.
2. **CI-валидация**: При каждом Pull Request запускается `./scripts/ci/run_headless_tests.sh`. Любая ошибка компиляции или падение теста приводит к блокировке слияния ветки.
3. **Безголовый (Headless) режим**: Во время прогона тестов рендеринг графического интерфейса отключается через флаг `--headless`. Это исключает зависимость тестов от графической видеокарты хоста.
