# Architecture Overview — Genesis v1

Этот документ описывает декомпозицию системы на независимые модули, их зоны ответственности и физическую структуру кодовой базы игры **Neo Soft Frost**.

---

## 1. Декомпозиция системы (Separation of Concerns)

В соответствии с правилом `RULE-005` (Архитектурные запреты), игра разделена на 4 изолированных слоя, взаимодействие между которыми происходит исключительно через асинхронные события шины `EventBus`.

```mermaid
graph TD
    subgraph DataLayer [Data Layer]
        UserData[res://scripts/level_runtime/user_data.gd]
        LevelLoader[res://scripts/level_runtime/level_loader.gd]
        JSONLevels[res://data/levels/*.json]
    end

    subgraph CoreMatch3 [Core Match-3 Engine]
        BoardModel[res://scripts/core_match3/board_model.gd]
        BoardController[res://scripts/core_match3/board_controller.gd]
        MatchSystem[res://scripts/core_match3/match_system.gd]
    end

    subgraph LevelRuntime [Level Runtime Orchestrator]
        LevelSession[res://scripts/level_runtime/level_session.gd]
        GoalTracker[res://scripts/level_runtime/goal_tracker.gd]
        MoveCounter[res://scripts/level_runtime/move_counter.gd]
    end

    subgraph Presentation [Presentation / UI Layer]
        Gameplay[res://scenes/gameplay/gameplay.gd]
        BoardView[res://scripts/presentation/board_view.gd]
        GemView[res://scripts/presentation/gem_view.gd]
        MainMenu[res://scenes/menus/main_menu.gd]
    end

    EventBus[res://scripts/event_bus.gd]

    %% Interactions
    LevelSession -->|Инициализирует| BoardController
    LevelSession -->|Подключает к| EventBus
    BoardController -->|Мутирует| BoardModel
    BoardController -->|Считывает| MatchSystem
    
    Gameplay -->|Считывает жесты| BoardView
    BoardView -->|Процедурно рисует| GemView
    
    EventBus -.->|События ввода / кликов| LevelSession
    EventBus -.->|События анимаций / эффектов| BoardView
    EventBus -.->|Обновление HUD| Gameplay
```

### 1.1 Модули и Зоны ответственности

| Идентификатор | Модуль | Классы / Файлы | Зона ответственности | Зависимости |
|---|---|---|---|---|
| **MOD-CORE** | Core Match-3 | `board_model.gd`, `board_controller.gd`, `match_system.gd`, `swap_system.gd` | Чистая логика игрового поля. Никакого визуального состояния или таймеров. Быстрый расчет ходов и обрушений. | Нет (Изолирован) |
| **MOD-RUN** | Level Runtime | `level_session.gd`, `goal_tracker.gd`, `move_counter.gd`, `score_system.gd` | Оркестрация матча: подсчет очков, лимит ходов, отслеживание целей, ведение снимков истории для отмены хода (Undo). | MOD-CORE, MOD-DATA |
| **MOD-DATA** | Data Layer | `user_data.gd`, `level_loader.gd`, `scoring.json`, `levels/*.json` | Персистентность: локальные сохранения, настройки качества, профиль пользователя, загрузка уровней. | Нет |
| **MOD-UI** | Presentation | `gameplay.gd`, `board_view.gd`, `gem_view.gd`, `main_menu.gd`, `sound_manager.gd` | Отрисовка UI, векторная процедурная визуализация игрового поля и фишек, воспроизведение звуков, анимация свайпов и падений, захват ввода. | MOD-DATA (только чтение) |

---

## 2. Физическая структура проекта (ASCII Tree)

```text
/Users/user/3-line/
├── config/
│   ├── resource_manifest.tsv     # Манифест внешних ресурсов
│   └── soft_launch_config.json   # Конфигурация Soft Launch (профили качества)
├── data/
│   ├── balance/
│   │   ├── research_backlog.json # Накопленный научный бэклог (Phases A-F)
│   │   └── scoring.json          # Константы начисления очков
│   └── levels/
│       ├── level_001.json        # Базовый обучающий уровень
│       └── ...                   # Уровни 002-010
├── docs/
│   ├── foundation/
│   │   ├── 07_CHALLENGE_REPORT.md # Отчет Challenger-а с фиксацией багов
│   │   ├── architecture.md       # Описание общей архитектуры
│   │   ├── master-blueprint-rules.md # 7 операционных правил разработки
│   │   └── mvp-mapping.md        # Маппинг фич на модули и NotebookLM источники
│   └── research/
│       └── stage-source-map.md   # Карта научных источников NotebookLM
├── genesis/
│   └── v1/                       # Текущая архитектурная ветка MVP v1
│       ├── 00_MANIFEST.md        # Манифест версии
│       ├── concept_model.json    # Модель понятий
│       ├── 01_PRD.md             # Продуктовые требования
│       ├── 02_ARCHITECTURE_OVERVIEW.md # Этот документ
│       ├── 03_ADR/               # Решения по архитектуре (ADR)
│       │   ├── ADR_001_TECH_STACK.md
│       │   ├── ADR_002_INPUT_BLOCKING.md
│       │   ├── ADR_003_8_GEM_SUPPORT.md
│       │   └── ADR_004_CSAT_FEEDBACK.md
│       ├── 06_CHANGELOG.md       # Журнал изменений версии
│       └── 07_INSTALLED_SKILLS.md # Установленные плагины
├── scenes/
│   ├── boot/
│   │   └── boot.tscn             # Сцена первой загрузки и E2E тестов
│   ├── gameplay/
│   │   ├── gameplay.gd           # Контроллер игрового HUD и наложения меню
│   │   └── gameplay_soft_frost.tscn # Игровая сцена в премиальном стиле
│   └── menus/
│       ├── main_menu.tscn        # Главное меню с параллаксом
│       └── level_select.tscn     # Карта выбора 10 уровней
└── scripts/
    ├── core_match3/              # MOD-CORE:GDScript логика
    ├── level_runtime/            # MOD-RUN & MOD-DATA GDScript логика
    ├── presentation/             # MOD-UI:Векторная графика и звук
    └── validation/               # QA-Гейты: MCTS симуляции и тесты читаемости
```
