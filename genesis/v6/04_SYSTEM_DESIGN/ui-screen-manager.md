# System Design — UI Screen Manager

Детальный технический дизайн **UI Screen Manager** (менеджер экранов и навигации) для Neo Soft Frost.

> **System ID**: `ui-screen-manager`  
> **Related Requirements**: [REQ-UI-601]–[REQ-UI-610], [REQ-UI-613]  
> **Target Version**: `genesis/v6`

---

## 1. Overview

### Цель
Обеспечить единую точку навигации, управление переходами (transitions), ведение истории перемещений (backward stack) и гибкое переключение профилей качества отображения (HIGH/MID/SAFE) на всех 10 экранах игры.

---

## 2. Goals & Non-Goals

### Goals
- **Детерминированный роутинг**: Все переходы осуществляются по строгим текстовым идентификаторам (ROUTES registry), исключая жестко зашитые пути к файлам в вызывающих контроллерах.
- **Сохранение состояния**: Поддержка передачи payloads (словарей данных) между сценами при навигации.
- **История переходов**: Надежный стек возврата назад (back stack) с автоматическим определением "World" или "Collection" в зависимости от контекста экрана.
- **Notch Safe-Area**: Адаптивное смещение верхней плашки `TopCurrencyBar` на мобильных устройствах с вырезами экрана (Safe-Area).

### Non-Goals
- Динамическое скачивание сцен с удаленного сервера (Asset Bundles) — все сцены включены в сборку локально.
- Поддержка многооконного режима (Multi-window) в Godot.

---

## 3. Architecture & Routing Flow

```mermaid
graph TD
    subgraph CallerNodes["UI Caller Components"]
        Btn[PillButton / TabItem]
        Screen[Screen Controller]
    end

    subgraph ManagerCore["UIScreenManager Core (Autoload)"]
        Routes[ROUTES Registry]
        History[History Stack]
        Quality[Quality Profile Manager]
        Trans[Transition Overlay Layer]
    end

    subgraph TargetScenes["10 Production Screens"]
        S1[Loading Screen]
        S2[Main Menu]
        S3[World Map]
        S4[Level Preview]
        S5[Gameplay HUD]
        S6[Pause Menu]
        S7[Level Complete]
        S8[Out of Moves]
        S9[Daily Rewards]
        S10[Shop]
    end

    Btn -->|navigate(screen_id, payload)| ManagerCore
    Screen -->|back()| ManagerCore

    ManagerCore -->|lookup path| Routes
    ManagerCore -->|push history| History
    ManagerCore -->|configure shader profile| Quality
    ManagerCore -->|fade in/out| Trans
    
    Trans -->|change scene| TargetScenes
```

### Реестр маршрутов (ROUTES Registry)
```gdscript
const ROUTES: Dictionary = {
	&"loading": "res://scenes/boot/loading_screen.tscn",
	&"main_menu": "res://scenes/menus/main_menu.tscn",
	&"world_map": "res://scenes/menus/world_map.tscn",
	&"level_select": "res://scenes/menus/world_map.tscn",
	&"level_preview": "res://scenes/menus/level_preview.tscn",
	&"gameplay": "res://scenes/gameplay/gameplay.tscn",
	&"daily_rewards": "res://scenes/menus/daily_rewards.tscn",
	&"shop": "res://scenes/menus/shop.tscn",
	&"rankings": "res://scenes/menus/rankings.tscn",
	&"collection": "res://scenes/menus/collection.tscn",
	&"friends": "res://scenes/menus/friends.tscn",
	&"inbox": "res://scenes/menus/inbox.tscn",
}
```

---

## 4. Interface Design

### 4.1 Навигация вперед (`navigate`)
```gdscript
func navigate(screen_id: StringName, screen_payload: Dictionary = {}, transition: StringName = &"fade") -> void
```
- **screen_id**: Идентификатор из ROUTES.
- **screen_payload**: Дополнительные параметры (например, номер уровня `{"level_id": 5}`).
- **transition**: Тип перехода (`fade`, `none`, `slide`).

### 4.2 Навигация назад (`back`)
```gdscript
func back() -> void
```
Возвращает на предыдущий экран из `_history` стека. Если стек пуст — осуществляет безопасный возврат в `main_menu`.

---

## 5. Technology Stack & Quality Presets

Для предотвращения падения производительности на слабых мобильных устройствах, менеджер управляет тремя глобальными профилями качества:

| Profile | Blur Shader | Particles Count | FPS Target |
|---|---|---|---|
| **HIGH** | Enabled (18px, full scale) | Max 40 active | 60+ |
| **MID** | Enabled (12px, 0.5x scale) | Max 20 active | 60+ |
| **SAFE** | Disabled (flat tint) | Max 10 active | 55+ |

При активации SAFE-профиля все размытия морозного стекла плавно отключаются и заменяются на сплошную полупрозрачную текстуру `GLASS_BG_STRONG`.

---

## 6. Trade-offs & Alternatives

### Выбор: Централизованный Autoload vs Локальные переходы `get_tree().change_scene()`

| Подход | Pros | Cons |
|---|---|---|
| **Локальные переходы** | Не требует синглтона, просто в написании для мелких проектов | Нет истории переходов (back stack), невозможно сделать красивый сквозной transition, дублирование путей к сценам |
| **Autoload Screen Manager (Наш выбор)** | Единая точка входа, централизованный контроль качества, поддержка истории и сквозных анимаций, notch safe-area | Требует наличия глобального синглтона в автозагрузке |

---

## 7. Performance & Security

- **Notch Safe-Area Adaptation**: Менеджер экранов считывает `DisplayServer.get_display_safe_area()` и динамически добавляет отступ (top margin) для `TopCurrencyBar` на notched телефонах.
- **Thread Safety**: Если пользователь совершает повторные клики во время активного перехода, `_navigating` флаг блокирует двойной запуск сцен, предотвращая утечки памяти.

---

## 8. Testing Strategy

- **Automated Validation**:
  - `scripts/validation/validate_ui_routes.gd` программно эмулирует переходы по всему графу ROUTES и проверяет отсутствие зависших нод или отсутствующих путей.
- **Manual Verification**:
  - Проверка корректности работы кнопки «Назад» на каждом экране.
  - Проверка Safe-Area отступов в симуляторах Godot под экраны iPhone/Samsung с челками.
