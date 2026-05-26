# Project Structure Guide — Neo Soft Frost

> **Specification Version**: `genesis/v5.1`  
> **Status**: ACTIVE & FROZEN (Architecture Control Plan)

Этот документ фиксирует официальную физическую структуру директорий проекта **Neo Soft Frost** для Godot 4.x. Любые отклонения от данной структуры считаются архитектурным дрейфом (design drift) и не допускаются к сборке.

---

## 🌳 Физическое дерево каталогов (Project Tree)

```text
res://
├── .agent/                              # Конфигурации и правила AI-ассистентов
│   ├── rules/
│   │   └── agents.md                    # Инструкция навигации агента
│   └── workflows/                       # Системные workflows (genesis, blueprint и др.)
│
├── data/                                # Конфигурационные файлы баланса и параметров
│   ├── ui/
│   │   ├── theme_tokens.json            # Токены оформления (цвета, motion, audio)
│   │   └── shader_quality_profiles.json # Профили производительности шейдеров
│   ├── economy/
│   │   └── reward_profiles.json         # Профили наград и стоимости товаров
│   ├── feedback/
│   │   └── combo_feedback_profiles.json # Конфигурация лестницы каскадов (x1-x5+)
│   ├── cascade_rules.json               # Правила Controlled Cascade Engine
│   ├── shape_rules.json                 # Правила распознавания фигур
│   └── level_balance_profiles.json      # Профили сложности уровней для MCTS
│
├── docs/                                # Архитектурная и регламентная документация
│   ├── architecture/
│   │   ├── project_structure.md         # [THIS FILE] Структура каталогов
│   │   └── layer_boundaries.md          # Границы системных слоев и ответственности
│   ├── governance/
│   │   └── dependency_rules.md          # Правила запрета неявных зависимостей
│   └── contracts/
│       ├── gameplay_contracts.md        # Спецификация типизированных контрактов
│       └── event_signal_map.md          # Карта глобальной шины событий EventBus
│
├── shaders/                             # Шейдеры визуализации и эффектов
│   ├── frost_glass.gdshader             # Frosted glass blur shader
│   ├── gradient_text.gdshader           # Текст с радужным градиентом
│   └── iridescent_border.gdshader       # Анимированная стеклянная рамка
│
├── scripts/                             # Логика приложения (без сцен)
│   ├── contracts/                       # Жестко типизированные DTO/контракты событий
│   │   ├── board_snapshot.gd
│   │   ├── match_event.gd
│   │   ├── cascade_step.gd
│   │   └── telemetry_event.gd
│   ├── system/
│   │   └── game_event_bus.gd            # Централизованная глобальная шина событий
│   ├── core_match3/                     # Логика ядра (Deterministic Core & Probability)
│   │   ├── cell_state.gd
│   │   ├── board_logic.gd
│   │   ├── shape_detector.gd
│   │   ├── shape_classifier.gd
│   │   ├── special_sphere_factory.gd
│   │   ├── special_combo_resolver.gd
│   │   ├── controlled_cascade_engine.gd
│   │   ├── cascade_governor.gd
│   │   ├── balance_governor.gd
│   │   └── drop_rng_controller.gd
│   ├── ui/                              # Логика пользовательского интерфейса
│   │   └── ThemeTokens.gd               # Автозагрузка (Autoload) дизайн-токенов
│   ├── feedback/                        # Логика сочной обратной связи
│   │   ├── feedback_director.gd         # Координатор VFX/SFX каскадов
│   │   ├── audio_feedback_router.gd     # Роутер звуковых эффектов
│   │   └── camera_feedback_router.gd    # Управление тряской камеры
│   └── telemetry/                       # Сбор метрик и симуляция
│       └── balance_telemetry_layer.gd   # Сборщик данных для баланса
│
├── scenes/                              # Сцены Godot (.tscn + привязанные скрипты .gd)
│   ├── boot/
│   │   └── loading_screen.tscn          # Экран загрузки
│   ├── menus/
│   │   ├── main_menu.tscn               # Главное меню
│   │   ├── world_map.tscn               # Карта мира
│   │   ├── level_preview.tscn           # Превью уровня
│   │   ├── daily_rewards.tscn           # Ежедневные награды
│   │   └── shop.tscn                    # Магазин
│   ├── gameplay/
│   │   ├── gameplay.tscn                # Игровой HUD и рамка доски
│   │   ├── pause_menu.tscn              # Пауза
│   │   ├── level_complete.tscn          # Успех
│   │   └── out_of_moves.tscn            # Поражение
│   └── ui/
│       ├── components/                  # Атомарные переиспользуемые UI компоненты
│       │   ├── pill_button.tscn
│       │   ├── glass_card.tscn
│       │   └── resource_pill.tscn
│       └── particles/                   # Системы частиц обратной связи
│           ├── floating_bubbles.tscn
│           └── sparkle_dust.tscn
│
└── tests/                               # Набор автоматических тестов GUT
    ├── core_match3/                     # Юнит-тесты компонентов ядра
    │   ├── test_board_logic.gd
    │   ├── test_input_buffer_controller.gd
    │   └── test_shape_detector.gd
    └── e2e/
        └── test_ccpe_e2e.gd             # Сценарный симулятор игровых сессий (MCTS)
```

---

## ⚠️ Регламент изменений (Change Governance)

1. **Создание новых папок**: Требует обязательного согласования с владельцем архитектуры и внесения изменений в данный документ.
2. **Создание файлов логики**: Все файлы геймплейной логики без графики должны быть помещены строго в подкаталоги `scripts/`.
3. **Создание сцен**: Все визуальные компоненты, контейнеры, окна и элементы управления помещаются строго в `scenes/`.
