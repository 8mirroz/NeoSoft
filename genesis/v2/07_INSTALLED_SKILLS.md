# Установленные навыки и плагины — Genesis v2

Этот документ фиксирует плагины, навыки (skills) и операционные правила разработки, установленные и активные в текущем воркспейсе игры **Neo Soft Frost** для версии 2.0 (Premium UX/UI & Combo System).

---

## 1. Активные навыки (Active Skills)

В соответствии с результатами сканирования и анализа требований релиза v2, в воркспейсе активированы следующие специализированные расширения Antigravity:

### Разработка и Рендеринг (Core Development)
- **modern-web-guidance** ([modern-web-guidance/SKILL.md](file:///Users/user/.gemini/config/plugins/modern-web-guidance-plugin/skills/modern-web-guidance/SKILL.md)):
  Управление современными стандартами визуального отображения, адаптивной разметки под Web, сжатием текстур и качеством производительности на мобильных экранах (профили качества `web_default` vs `android_safe`).
- **chrome-devtools** ([chrome-devtools/SKILL.md](file:///file:///Users/user/.gemini/config/plugins/chrome-devtools-plugin/skills/chrome-devtools/SKILL.md)):
  Используется для удаленного профилирования Web-сборок, разметки кадров (LCP) и верификации плавности отрисовки векторной графики в браузере при 60 FPS.
- **godot-mobile-match3** ([godot-mobile-match3/SKILL.md](file:///Users/user/3-line/.agent/skills/active/godot-mobile-match3.md)):
  Управление автоматизацией мобильных сборок (godot-ci, butler), паттернами Controller-First для развязки Core Loop и презентации, а также MCTS headless валидацией.

### Архитектура и Управление (Management & Architecture)
- **design-system-guidance** ([design-system-guidance/SKILL.md](file:///Users/user/.gemini/config/plugins/custom-design-system/skills/design-system-guidance/SKILL.md)):
  Обязательный навык ведения глобальной дизайн-системы пользователя, обеспечивающий единообразие палитр и визуальных контуров между элементами доски и HUD.
- **google-antigravity-sdk** ([google-antigravity-sdk/SKILL.md](file:///Users/user/.gemini/config/plugins/google-antigravity-sdk/skills/google-antigravity-sdk/SKILL.md)):
  Используется для тонкой настройки многоагентных E2E тестов и MCTS балансировочных скриптов симуляции.

---

## 2. Операционные правила разработки (Active Rules)

Проект подчиняется **7 операционным правилам разработки**, зафиксированным в [master-blueprint-rules.md](file:///Users/user/3-line/docs/foundation/master-blueprint-rules.md):
1.  **RULE-001: Source-of-Truth Hierarchy**:
    Машиночитаемые файлы и директория `genesis/v2/` имеют безусловный приоритет над кодом и нарративными доками.
2.  **RULE-002: Research-First**:
    Все геймдизайнерские решения по балансу, удержанию и монетизации должны быть подкреплены фактами из базы знаний `Deushare` и записаны в `decision-log.md`.
3.  **RULE-003: Визуальные гейты**:
    Жесткие диапазоны длительности анимаций (Select: 0.18-0.35s, Swap: 0.22-0.35s) и лимиты читаемости фишек на мелких экранах. Добавлена регламентация для Cascade Sequencer (взрыв: 0.38s, пауза перед падением: 0.25s, refill: 0.34s, пауза перед повторным поиском: 0.15s).
4.  **RULE-004: Лицензионная чистота**:
    Исключение GPL-кода в продакшн-компонентах. Вся атрибуция CC-BY складывается в Credits.
5.  **RULE-005: Архитектурные запреты**:
    Шина событий `EventBus` как единственный мост связи между логическим ядром и UI. Запрет прямой зависимости логики от графики. Накопление событий хода в `VisualEventQueue` внутри `BoardView`.
6.  **RULE-006: VFX Quality Gates**:
    Запрет пересветов на светлом фоне, плавность SPRING-анимаций (Squash & Stretch). Для `CPUParticles2D` лимит частиц равен 20 на взрыв сферы в режиме `web_default` и 10 в режиме `android_safe`.
7.  **RULE-007: Этичная монетизация**:
    Полный отказ от манипулятивных техник (скрытые вероятности, фейковые цены, paywall) в пользу Rewarded Ads и косметики.
