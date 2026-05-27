# Installed Skills & Rules - Genesis v5

Этот документ фиксирует набор активных навыков (skills) и правил поведения (rules), настроенных в рабочей среде для разработки **Controlled Cascade Pleasure Engine (CCPE)** и **UI/UX System** в игре **Neo Soft Frost**.

---

## 1. Активные Навыки (Active Skills)

Для реализации Combo Fever Engine используются 3 основных технологических навыка:

### 1.1 Custom Skill: Godot Mobile Match-3 Development & CI/CD Automation
- **Путь**: [.agent/skills/active/godot-mobile-match3.md](file:///Users/user/3-line/.agent/skills/active/godot-mobile-match3.md)
- **Область применения**:
  - Архитектурный паттерн **Controller-First Design (Four Games)** для разделения логики `BoardController` и визуализации `BoardView`.
  - Математическое ядро Match-3 (сканирование, осыпание столбцов, генерация) без зависимости от сцен Godot.
  - Headless-симуляция MCTS (Monte Carlo Tree Search) для автобалансировки уровней сложности.
  - Интеграция мобильного CI/CD (GitHub Actions, butler-publish на itch.io).

### 1.2 Design System Guidance
- **Путь**: [custom-design-system/design-system-guidance](file:///Users/user/.gemini/config/plugins/custom-design-system/skills/design-system-guidance/SKILL.md)
- **Область применения**:
  - Использование глобальной дизайн-системы, токенов палитры и паттернов отрисовки (Liquid Opal Glass, процедурные градиенты главного меню и HUD).

### 1.3 Google Antigravity SDK
- **Путь**: [google-antigravity-sdk](file:///Users/user/.gemini/config/plugins/google-antigravity-sdk/skills/google-antigravity-sdk/SKILL.md)
- **Область применения**:
  - Проектирование, отладка и оркестрация мультиагентных систем.

---

## 2. Активные Правила (Installed Rules)

В каталоге правил рабочей среды развернуты следующие конфигурации:

### 2.1 Навигационный Гид Агента
- **Путь**: [.agent/rules/agents.md](file:///Users/user/3-line/.agent/rules/agents.md)
- **Назначение**:
  - Поддержание карты проекта.
  - Указание путей к активным архитектурным документам (PRD, ADR, System Design).
  - Справочник по структуре папок проекта.
