# ADR 003: Архитектура навигации главного меню (Top Bar + Quick Actions + Bottom Nav)

*   **Статус**: Утверждено
*   **Дата**: 2026-05-26
*   **Контекст**: Текущее меню v2 содержит только 2 кнопки (Play, Settings) и progress summary. Референс требует полноценной навигационной структуры с тремя зонами: верхняя панель валют, средняя зона контента, нижняя панель навигации.

---

## Решение

### Вертикальная структура экрана (720x1280)

```text
┌──────────────────────────────────────────┐
│  Top Bar (h=60): [Coins][Stars]  [Inbox] │  y: 0-60
├──────────────────────────────────────────┤
│  Title "Neo Soft Frost" (h=100)          │  y: 60-160
├──────────────────────────────────────────┤
│                                          │
│      Central Orb Display (h=350)         │  y: 160-510
│      [Arch + Orb + Pedestal]             │
│                                          │
├──────────────────────────────────────────┤
│  Play Button (h=75)                      │  y: 510-585
├──────────────────────────────────────────┤
│  Quick Actions 4x1 (h=130)              │  y: 600-730
│  [Levels][Events][Shop][Settings]        │
├──────────────────────────────────────────┤
│                                          │
│  (spacer)                                │  y: 730-1180
│                                          │
├──────────────────────────────────────────┤
│  Bottom Nav (h=100)                      │  y: 1180-1280
│  [Home][Rankings][Collection][Friends]   │
│              [Inbox]                     │
└──────────────────────────────────────────┘
```

### Реализация в Godot

Все компоненты реализуются в одном скрипте `main_menu.gd` через процедурную отрисовку `_draw()` и динамически создаваемые `Button`/`Label` ноды. Это позволяет:
- Полный контроль позиционирования
- Единый рендер-цикл для фона, декораций и UI
- Адаптивность через коэффициенты от `size`

### Ноды в TSCN

```text
MainMenu (Control)
├── Background (ColorRect) ← базовый gradient fill
├── BackgroundParticles (CPUParticles2D) ← мерцающие частицы
├── BackgroundGems (Control) ← floating gems (depth < 0.7)
├── TopBar (HBoxContainer) ← [CoinPill, StarPill, Spacer, InboxBtn]
├── TitleLabel (Label) ← "Neo Soft Frost"
├── OrbContainer (Control) ← центральная сфера (custom _draw)
├── PlayButton (Button) ← главная кнопка Play
├── QuickActions (HBoxContainer) ← [Levels, Events, Shop, Settings]
├── ForegroundGems (Control) ← floating gems (depth >= 0.7)
├── BottomNav (HBoxContainer) ← [Home, Rankings, Collection, Friends, Inbox]
├── SettingsOverlay (ColorRect) ← модальное окно настроек
└── FadeLayer (ColorRect) ← переход между сценами
```

---

## Последствия

- Чёткая вертикальная декомпозиция UI на 5 зон
- Все навигационные компоненты — заглушки с toast-уведомлениями (кроме Play, Levels, Settings)
- Масштабируемая архитектура для подключения реальных экранов в будущих версиях
