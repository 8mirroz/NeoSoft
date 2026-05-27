# System Design — Motion & Animation System

## Neo Soft Frost — Production Animation Architecture for Godot 4.x

> **System ID**: `motion-animation-system`
> **Related Requirements**: [REQ-CCPE-509] Cascade Reward Psychology, [REQ-UI-601]–[REQ-UI-610]
> **Depends on**: [ui-ux-design-system](file:///Users/user/3-line/genesis/v5/04_SYSTEM_DESIGN/ui-ux-design-system.md)
> **ADR**: [ADR-010](file:///Users/user/3-line/genesis/v5/03_ADR/ADR_010_UI_UX_SYSTEM.md)

---

## 1. Overview

Этот документ определяет **полную motion-архитектуру** Neo Soft Frost — от навигационных переходов до VFX разрушения, от микровзаимодействий до каскадных физик. Все тайминги основаны на исследованиях человеческого восприятия и production-паттернах premium casual games.

### Принципы

```text
1. МГНОВЕННОСТЬ    — отклик < 50ms, базовые анимации 200–500ms
2. ФИЗИЧНОСТЬ      — squash & stretch, bounce, гравитация, вес
3. ЭСКАЛАЦИЯ       — каскад-лестница VFX x1→x5+ с нарастающей интенсивностью
4. БЮДЖЕТНОСТЬ     — particle budget, performance tiers, ambient pause
5. ЧИТАЕМОСТЬ      — анимация помогает, а не мешает gameplay
6. ACCESSIBILITY   — prefers-reduced-motion, fallback на мгновенные переходы
```

---

## 2. Тайминги — Physiological Thresholds

### 2.1 Пороги восприятия

| Порог | Время | Восприятие | Правило |
|---|---|---|---|
| Мгновенное | < 100ms | Действие не замечено как анимация | Используй для state changes без motion |
| Тактильный отклик | < 50ms | Идеальный haptic feedback | Tap → visual change gap |
| Идеальный баланс | 200–500ms | Плавно + понятно + не раздражает | **Все UI-анимации в этом окне** |
| Верхний предел | ≤ 1000ms | Ещё воспринимается как плавное | Только для complex transitions |
| Раздражение | > 1000ms | Кажется зависанием | **Запрещено для базового UI** |

### 2.2 Master Timing Table

| Категория | Элемент | Duration | Offset/Stagger | Easing |
|---|---|---|---|---|
| **Мгновенный отклик** | Tap → visual change | ≤ 50ms | — | instant |
| **Кнопки** | Press scale (0.97) | 120ms | — | ease_out |
| **Кнопки** | Release restore | 80ms | — | ease_out_back |
| **Кнопки** | Color/shadow shift | 150ms | — | ease_out |
| **Иконки** | Tap reaction | 180ms | — | ease_out |
| **Тумблеры** | Toggle slide | 220ms | — | ease_in_out |
| **Карточки** | Appear (opacity+y) | 260ms | 40ms stagger | spring |
| **Навигация** | Horizontal swipe | 300ms | — | ease_out_cubic |
| **Навигация** | Fade transition | 300ms | — | ease_in_out |
| **Модалы** | Slide up + scrim | 320ms | — | ease_out_back |
| **Модалы** | Dismiss | 200ms | — | ease_in |
| **Match clear** | Sphere dissolve | 350–420ms | — | ease_out |
| **Cascade fall** | Per-sphere drop | 280ms | 50ms stagger | bounce |
| **Reward fly** | Resource → counter | 500–700ms | — | ease_in_out_back |
| **Stars fill** | Per-star bounce | 350ms | 100ms stagger | bounce |
| **Score counter** | Roll up numbers | 600ms | — | ease_out |
| **Level complete** | Full sequence | 800–1200ms | — | composed |
| **Confetti burst** | Particle explosion | 900ms | — | ease_out |
| **Launch screen** | Full splash | ≤ 2000ms | — | composed |
| **Ambient** | Bubble float cycle | 4000–9000ms | random | linear |

### 2.3 Правило 6 секунд

```text
Если загрузка > 6 секунд:
  1. Разбить на 3–4 последовательные фазы
  2. Каждая фаза имеет собственную анимацию (1.5–2с каждая)
  3. Прогресс-бар заполняется ступенчато (не линейно)
  4. Фазы: logo → tip → progress → "Tap to Start"

Субъективно: серия коротких анимаций < одна длинная
```

---

## 3. Easing Presets — Godot Implementation

### 3.1 Easing Library

```gdscript
# easing_presets.gd — AUTOLOAD
class_name EasingPresets
extends Node

## ═══════════════════════════════════════════
## STANDARD EASINGS
## ═══════════════════════════════════════════

## Мягкий выход — кнопки, появление элементов
static func ease_out() -> Tween:
    return null  # placeholder, use inline

const EASE_OUT_TRANS = Tween.TRANS_QUAD
const EASE_OUT_EASE = Tween.EASE_OUT

## Плавный вход-выход — навигация, fade
const EASE_IN_OUT_TRANS = Tween.TRANS_SINE
const EASE_IN_OUT_EASE = Tween.EASE_IN_OUT

## Быстрый вход — dismiss modal
const EASE_IN_TRANS = Tween.TRANS_QUAD
const EASE_IN_EASE = Tween.EASE_IN

## ═══════════════════════════════════════════
## PHYSICS EASINGS
## ═══════════════════════════════════════════

## Bounce — каскадное падение, stars, squash
const BOUNCE_TRANS = Tween.TRANS_BOUNCE
const BOUNCE_EASE = Tween.EASE_OUT

## Spring/Back — modal appear, button release, pop-in
const SPRING_TRANS = Tween.TRANS_BACK
const SPRING_EASE = Tween.EASE_OUT

## Elastic — reward emphasis, fever activation
const ELASTIC_TRANS = Tween.TRANS_ELASTIC
const ELASTIC_EASE = Tween.EASE_OUT

## ═══════════════════════════════════════════
## CUBIC BEZIER (custom curves for special cases)
## ═══════════════════════════════════════════

## iOS-style smooth — navigation transitions
## Equivalent: cubic-bezier(0.16, 1, 0.3, 1)
static func smooth_curve() -> Curve:
    var c = Curve.new()
    c.add_point(Vector2(0.0, 0.0))
    c.add_point(Vector2(0.16, 0.6))
    c.add_point(Vector2(0.3, 1.0))
    c.add_point(Vector2(1.0, 1.0))
    return c

## Anticipation curve — замедление перед действием
## Легкий откат назад (anticipation), затем быстрый бросок вперёд
static func anticipation_curve() -> Curve:
    var c = Curve.new()
    c.add_point(Vector2(0.0, 0.0))
    c.add_point(Vector2(0.15, -0.08))  # slight pullback
    c.add_point(Vector2(0.4, 0.6))
    c.add_point(Vector2(0.7, 1.05))    # overshoot
    c.add_point(Vector2(1.0, 1.0))
    return c
```

---

## 4. Категория 1 — Навигационные и системные анимации

### 4.1 Launch / Splash Screen

```text
Тайминг: ≤ 2000ms total
Фазы:
  0ms     — Logo fade in (opacity 0→1, scale 0.95→1.0)       [300ms, ease_out]
  300ms   — Tagline slide up (y+20→0, opacity 0→1)           [250ms, ease_out]
  600ms   — Orb scale in + rotation start                     [400ms, spring]
  1000ms  — Progress bar appear                               [200ms, ease_out]
  1400ms  — "Tap to Start" pulse begin                        [loop, 1500ms]

Правило: Если ресурсы загрузились раньше 2с → всё равно показать минимум 1.2с
         Если загрузка > 6с → разбить на фазы (tip rotation + progress steps)
```

```gdscript
# loading_screen.gd
func _play_launch_sequence() -> void:
    var tween = create_tween()
    tween.set_parallel(false)

    # Phase 1: Logo
    tween.tween_property(logo, "modulate:a", 1.0, 0.3) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(logo, "scale", Vector2.ONE, 0.3) \
        .from(Vector2(0.95, 0.95)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    # Phase 2: Tagline
    tween.tween_property(tagline, "modulate:a", 1.0, 0.25) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(tagline, "position:y", tagline.position.y, 0.25) \
        .from(tagline.position.y + 20)

    # Phase 3: Orb
    tween.tween_property(orb, "scale", Vector2.ONE, 0.4) \
        .from(Vector2(0.6, 0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    # Phase 4: Progress bar
    tween.tween_property(progress_bar, "modulate:a", 1.0, 0.2)

    await tween.finished
    _start_tap_pulse()
```

### 4.2 Screen Transitions

| Тип перехода | Жест/Действие | Анимация | Duration | Godot Implementation |
|---|---|---|---|---|
| **Forward** | Tap "Play", "Next" | Slide left | 300ms | `position.x: 0 → -width` + next `width → 0` |
| **Back** | Tap "←", swipe right | Slide right | 300ms | `position.x: 0 → width` + prev `-width → 0` |
| **Modal up** | Tap action (Pause, etc.) | Slide from bottom + scrim | 320ms | `position.y: height → 0` + scrim `alpha: 0 → 0.62` |
| **Modal dismiss** | Tap Close, tap scrim | Slide down + scrim fade | 200ms | `position.y: 0 → height` + scrim `alpha: 0.62 → 0` |
| **Fade** | Scene change (fallback) | Cross-fade | 300ms | `modulate.a` overlay |
| **Scale up** | Popup, reward | Scale from center | 280ms | `scale: 0.85 → 1.0` + `modulate.a: 0 → 1` |

```gdscript
# transition_manager.gd
func slide_forward(current: Control, next: Control, duration: float = 0.3) -> void:
    next.position.x = get_viewport().get_visible_rect().size.x
    next.visible = true
    var tween = create_tween().set_parallel(true)
    tween.tween_property(current, "position:x", -current.size.x, duration) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(next, "position:x", 0.0, duration) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    await tween.finished
    current.visible = false

func modal_up(modal: Control, scrim: ColorRect, duration: float = 0.32) -> void:
    modal.position.y = get_viewport().get_visible_rect().size.y
    scrim.modulate.a = 0.0
    modal.visible = true
    scrim.visible = true
    var tween = create_tween().set_parallel(true)
    tween.tween_property(modal, "position:y", modal.get_meta("target_y", 0.0), duration) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(scrim, "modulate:a", 0.62, duration * 0.7) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    await tween.finished
```

### 4.3 Loading Indicators

```text
Загрузка < 2с:   FrostProgressBar linear fill + sparkle marker
Загрузка 2–6с:   FrostProgressBar + rotating tip text (3 tips, 2с каждый)
Загрузка > 6с:   Split into phases:
  Phase A (0–2s):  Logo + brand animation
  Phase B (2–4s):  Tip #1 + progress 0→40%
  Phase C (4–6s):  Tip #2 + progress 40→80%
  Phase D (6+s):   Tip #3 + progress 80→100% + "Ready!"
```

```gdscript
# Stepped progress for long loads
func _animate_progress_phased(total_steps: int = 4) -> void:
    var step_duration = 1.5
    for i in range(total_steps):
        var target = float(i + 1) / total_steps
        var tween = create_tween()
        tween.tween_property(progress_bar, "value", target, step_duration) \
            .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        if i < tips.size():
            _show_tip(tips[i])
        await tween.finished
```

### 4.4 Error State Animations

```text
Тайминг: 400ms entrance, gentle bounce

Анимация:
  1. Sad orb icon wobble (rotation -5°→+5°→0°, 3 cycles) [600ms]
  2. Error text slide in from bottom                       [300ms, ease_out]
  3. Action button pulse glow                              [loop, 1500ms]

Правило: Никогда не shake весь экран. Только иконка покачивается.
         Обязательно показать кнопку выхода из ошибки.
```

---

## 5. Категория 2 — Микровзаимодействия и обратная связь

### 5.1 Button Animations

```gdscript
# micro_animator.gd
class_name MicroAnimator

## Press — мгновенная тактильная обратная связь
static func button_press(btn: Control) -> void:
    var tween = btn.create_tween()
    tween.tween_property(btn, "scale", Vector2(0.97, 0.97), 0.12) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Release — пружинный возврат
static func button_release(btn: Control) -> void:
    var tween = btn.create_tween()
    tween.tween_property(btn, "scale", Vector2.ONE, 0.08) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## CTA pulse glow — привлечение внимания к главной кнопке
static func cta_pulse(btn: Control, glow_node: Control) -> void:
    var tween = btn.create_tween().set_loops()
    tween.tween_property(glow_node, "modulate:a", 0.8, 0.75) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(glow_node, "modulate:a", 0.3, 0.75) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Disabled tap — subtle shake (accessibility: also shows tooltip)
static func disabled_shake(btn: Control) -> void:
    var orig_x = btn.position.x
    var tween = btn.create_tween()
    tween.tween_property(btn, "position:x", orig_x + 4, 0.05)
    tween.tween_property(btn, "position:x", orig_x - 4, 0.05)
    tween.tween_property(btn, "position:x", orig_x + 2, 0.05)
    tween.tween_property(btn, "position:x", orig_x, 0.05)
```

### 5.2 Icon Animations

```text
Nav icon tap:
  1. Scale down 0.85 [80ms, ease_out]
  2. Scale up 1.1 [100ms, spring]
  3. Settle to 1.0 [120ms, ease_out]
  Total: 300ms

Loading icon → progress:
  1. Spinner rotation (continuous, 800ms/revolution)
  2. On progress data: morph spinner → arc fill
  3. Arc fills 0→100% following actual progress
  4. On complete: checkmark pop (scale 0→1.1→1.0, 250ms, spring)
```

```gdscript
## Icon tap reaction — bounce sequence
static func icon_tap(icon: Control) -> void:
    var tween = icon.create_tween()
    tween.tween_property(icon, "scale", Vector2(0.85, 0.85), 0.08) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(icon, "scale", Vector2(1.1, 1.1), 0.1) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(icon, "scale", Vector2.ONE, 0.12) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
```

### 5.3 Success State Animations

```text
Level Complete sequence (800–1200ms total):
  0ms     — Screen overlay fade in                          [200ms]
  100ms   — "Level Complete" text scale in (0.8→1.0)        [300ms, spring]
  300ms   — Star 1 bounce fill                              [350ms, bounce]
  400ms   — Star 2 bounce fill (100ms stagger)              [350ms, bounce]
  500ms   — Star 3 bounce fill (100ms stagger)              [350ms, bounce]
  500ms   — Confetti particle burst                         [900ms, ease_out]
  600ms   — Score counter roll up                           [600ms, ease_out]
  800ms   — "NEW BEST!" badge slide in (if applicable)      [250ms, spring]
  1000ms  — Reward icons pop in                             [300ms, spring]
  1200ms  — Buttons appear                                  [250ms, ease_out]
```

```gdscript
func _play_level_complete() -> void:
    var tween = create_tween()

    # Title pop
    tween.tween_property(title, "scale", Vector2.ONE, 0.3) \
        .from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    # Stars — staggered bounce
    for i in range(3):
        tween.tween_interval(0.1)  # 100ms stagger
        tween.tween_callback(star_rating.fill_star.bind(i))
        # fill_star internally plays 350ms bounce animation

    # Confetti (fire-and-forget particle)
    tween.parallel().tween_callback(confetti_particles.emit_burst)

    # Score roll-up
    tween.tween_method(_roll_score, 0, final_score, 0.6) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    # NEW BEST badge
    if is_new_best:
        tween.tween_property(best_badge, "scale", Vector2.ONE, 0.25) \
            .from(Vector2(0.5, 0.5)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.parallel().tween_property(best_badge, "modulate:a", 1.0, 0.15)

    # Rewards pop
    tween.tween_property(rewards_panel, "scale", Vector2.ONE, 0.3) \
        .from(Vector2(0.9, 0.9)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(rewards_panel, "modulate:a", 1.0, 0.2)

    # Buttons
    tween.tween_property(buttons_container, "modulate:a", 1.0, 0.25)
```

### 5.4 Toggle Switch Animation

```gdscript
## Toggle — плавное переключение с feedback
static func toggle_switch(knob: Control, track: Control, is_on: bool, duration: float = 0.22) -> void:
    var target_x = track.size.x - knob.size.x - 4 if is_on else 4.0
    var target_color = ThemeTokens.ACCENT_CYAN if is_on else ThemeTokens.PRIMARY_300

    var tween = knob.create_tween().set_parallel(true)
    tween.tween_property(knob, "position:x", target_x, duration) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(track, "modulate", target_color, duration) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

---

## 6. Категория 3 — Игровые эффекты (Геймплей и физика)

### 6.1 Idle-анимации (Поле в покое)

```text
Когда игрок не двигается > 3 секунд:

Сферы:
  - Subtle breathing: scale 1.0→1.02→1.0 [2000ms, sine loop]
  - Gentle bob: position.y ±2px [3000ms, sine loop, random phase offset]
  - Internal refraction shimmer [shader, continuous]

Блокеры:
  - Ice: frost sparkle particles [every 4000ms]
  - Chain: slight rattle [rotation ±1°, 1500ms, ease_in_out loop]

Ambient:
  - Floating bubbles: 4000–9000ms per cycle, random path
  - Diamond crystals: gentle rotation ±5° [6000ms, sine loop]
  - Sparkle dust: random spawn, 0.5–1.0s lifetime

Правило: ВСЕ idle-анимации ОСТАНАВЛИВАЮТСЯ когда:
  - Pipeline state != IDLE
  - Модальное окно открыто
  - Combo Window активно (focus on gameplay)
```

```gdscript
# sphere_idle_animator.gd
func _start_idle(gem_view: Node2D, delay: float = 0.0) -> void:
    await get_tree().create_timer(delay).timeout

    # Breathing
    var breath = gem_view.create_tween().set_loops()
    breath.tween_property(gem_view, "scale", Vector2(1.02, 1.02), 1.0) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    breath.tween_property(gem_view, "scale", Vector2.ONE, 1.0) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    # Bob (random phase)
    var bob = gem_view.create_tween().set_loops()
    var base_y = gem_view.position.y
    bob.tween_property(gem_view, "position:y", base_y - 2, 1.5) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    bob.tween_property(gem_view, "position:y", base_y + 2, 1.5) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    _idle_tweens[gem_view] = [breath, bob]

func _stop_all_idle() -> void:
    for tweens in _idle_tweens.values():
        for t in tweens:
            t.kill()
    _idle_tweens.clear()
```

### 6.2 Каскадное падение (Cascade Falls)

```text
Паттерн: Сферы падают НЕ одновременно, а по очереди (снизу вверх).

Timing per sphere:
  - Fall distance: переменная (зависит от пустых клеток)
  - Fall duration: 180–280ms (зависит от расстояния)
  - Stagger between columns: 50ms (1–2 кадра при 60fps)
  - Landing bounce: squash 30ms → stretch 50ms → settle 80ms

Easing: ease_in для падения (ускорение вниз = гравитация)
        bounce для приземления

Порядок:
  1. Нижние ряды падают первыми
  2. Верхние ряды — с задержкой stagger
  3. Новые сферы (spawn сверху) — последними
```

```gdscript
# cascade_animator.gd
func animate_fall(gem_view: Node2D, from_y: float, to_y: float, column_index: int) -> void:
    var distance = abs(to_y - from_y)
    var fall_duration = remap(distance, 0, 400, 0.18, 0.28)
    var stagger_delay = column_index * 0.05

    gem_view.position.y = from_y
    await get_tree().create_timer(stagger_delay).timeout

    var tween = gem_view.create_tween()

    # Fall with gravity easing
    tween.tween_property(gem_view, "position:y", to_y, fall_duration) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

    # Landing: squash & stretch
    tween.tween_property(gem_view, "scale", Vector2(1.15, 0.85), 0.03)  # squash
    tween.tween_property(gem_view, "scale", Vector2(0.92, 1.08), 0.05)  # stretch
    tween.tween_property(gem_view, "scale", Vector2(1.03, 0.97), 0.04)  # mini squash
    tween.tween_property(gem_view, "scale", Vector2.ONE, 0.08) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)            # settle

    await tween.finished
    animation_completed.emit(gem_view)
```

### 6.3 Squash & Stretch (Деформация)

```text
Правила деформации:
  - Площадь ВСЕГДА сохраняется: если X сжимается, Y растягивается
  - squash_factor + stretch_factor ≈ 2.0 (conservation of volume)
  - Максимальная деформация: 20% от оригинального размера
  - Применяется к: сферам при падении, swap, match, bounce

Таблица деформаций:
  Landing impact:  squash(1.15, 0.85) → stretch(0.92, 1.08) → settle(1.0, 1.0)
  Swap motion:     stretch in direction(1.12, 0.90) → settle(1.0, 1.0)
  Match dissolve:  uniform shrink(0.0, 0.0) with rotation ±15°
  Spawn pop-in:    stretch(0.7, 1.3) → squash(1.1, 0.9) → settle(1.0, 1.0)
```

### 6.4 Anticipation (Предварительная подготовка)

```text
Применяется к:
  - Beam activation: луч "заряжается" 200ms (пульсация + glow ramp)
  - Blast explosion: сфера "набухает" scale 1.0→1.15 [150ms] перед взрывом
  - Homing launch: покачивание 100ms перед "полётом"
  - Prism activation: радужная волна проходит по сфере [300ms]
  - Special combo: обе сферы пульсируют синхронно [200ms]
  - Fever activation: экран мигает золотом [150ms] перед сменой режима

Правило: anticipation_duration ≈ 30–50% от основной анимации
         Никогда не делать anticipation > 500ms (раздражает)
```

```gdscript
## Anticipation pulse before special activation
static func anticipation_pulse(node: Node2D, power: float = 1.15, duration: float = 0.2) -> void:
    var tween = node.create_tween()
    # Slight scale up (inhale)
    tween.tween_property(node, "scale", Vector2(power, power), duration * 0.6) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    # Glow ramp
    tween.parallel().tween_property(node, "modulate", Color(1.3, 1.3, 1.3, 1.0), duration * 0.6)
    # Hold briefly
    tween.tween_interval(duration * 0.4)
```

### 6.5 Fake 3D (Перспектива в 2D)

```text
Техники:
  1. Кнопка "вдавливание": при нажатии shadow_offset уменьшается + slight scale down
     → создаёт иллюзию утопления в поверхность

  2. Popup "из экрана": элемент появляется с scale 0.6→1.0 + shadow нарастает
     → создаёт иллюзию вылетания "в камеру"

  3. Parallax layers: фон двигается медленнее переднего плана при scroll
     → World Map: clouds (0.3x), path (1.0x), UI (fixed)

  4. Drop shadow depth: чем выше элемент "парит", тем больше shadow offset + blur
     → surface/1: shadow_offset 6px, surface/3: shadow_offset 14px
```

```gdscript
## Button press depth effect
static func button_depth_press(btn: Control, shadow: StyleBoxFlat) -> void:
    var tween = btn.create_tween().set_parallel(true)
    tween.tween_property(btn, "scale", Vector2(0.97, 0.97), 0.12)
    # Shadow shrinks = button "sinks"
    tween.tween_method(func(v): shadow.shadow_offset = Vector2(0, v), 6.0, 2.0, 0.12)
    tween.tween_method(func(v): shadow.shadow_size = v, 18, 6, 0.12)

static func button_depth_release(btn: Control, shadow: StyleBoxFlat) -> void:
    var tween = btn.create_tween().set_parallel(true)
    tween.tween_property(btn, "scale", Vector2.ONE, 0.08) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_method(func(v): shadow.shadow_offset = Vector2(0, v), 2.0, 6.0, 0.08)
    tween.tween_method(func(v): shadow.shadow_size = v, 6, 18, 0.08)
```

---

## 7. Категория 4 — VFX разрушения и наград

### 7.1 Match / Explosion Effects

```text
Каскад-лестница VFX (из REQ-CCPE-509):

x1 "Nice":
  - Small flash: white circle expand 0→cell_size [200ms, ease_out], fade out
  - Particles: 4 small sparkles
  - Screen effect: none

x2 "Combo":
  - Ripple wave: circular distortion shader [300ms]
  - Particles: 8 sparkles + color trails
  - Screen effect: none

x3 "Chain Reaction":
  - Board pulse: entire board scale 1.0→1.01→1.0 [150ms]
  - Particles: 12 sparkles + energy lines between matched cells
  - Screen effect: subtle vignette flash [200ms]

x4 "Cascade Surge":
  - Energy lines: glowing lines from match origin to board edges [400ms]
  - Particles: 16 sparkles + shockwave ring
  - Screen effect: slight camera shake (offset ±3px, 200ms)

x5+ "Fever Spark":
  - Mini fever aura: golden shimmer around board [500ms]
  - Particles: 24 sparkles + star burst + golden trails
  - Screen effect: golden vignette + camera shake (±5px, 300ms)
  - Title popup: animated floating text with glow
```

### 7.2 Reward Flight (Trail Animation)

```text
Тайминг: 500–700ms
Trajectory: Bezier curve from source → UI counter (top bar)

Phases:
  1. Spawn: pop from match origin (scale 0→1.2→1.0) [150ms]
  2. Flight: follow bezier path with trail particles [300–400ms]
  3. Absorption: scale 1.0→0.5 at counter + counter pulse [100ms]
  4. Counter update: number increment with golden flash [immediate]

Trail particles:
  - 6-8 small glowing dots
  - Lifetime: 200ms
  - Fade: alpha 1.0→0.0
  - Color: ACCENT_GOLD for coins, ACCENT_CYAN for stars
```

```gdscript
# reward_flight.gd
func fly_reward(icon: Node2D, from: Vector2, to: Vector2, duration: float = 0.6) -> void:
    icon.position = from
    icon.scale = Vector2.ZERO

    # Pop in
    var tween = icon.create_tween()
    tween.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.1) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(icon, "scale", Vector2.ONE, 0.05)

    # Bezier flight
    var mid_point = Vector2(
        lerp(from.x, to.x, 0.5),
        min(from.y, to.y) - 80  # arc above both points
    )
    var flight_tween = icon.create_tween()
    flight_tween.tween_method(
        func(t: float):
            icon.position = _quadratic_bezier(from, mid_point, to, t),
        0.0, 1.0, duration * 0.65
    ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

    # Trail particles
    flight_tween.parallel().tween_callback(_emit_trail_particle.bind(icon)).set_loops()

    await flight_tween.finished

    # Absorption
    var absorb = icon.create_tween()
    absorb.tween_property(icon, "scale", Vector2(0.3, 0.3), 0.1)
    absorb.parallel().tween_property(icon, "modulate:a", 0.0, 0.1)
    await absorb.finished
    icon.queue_free()

static func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
    var q0 = p0.lerp(p1, t)
    var q1 = p1.lerp(p2, t)
    return q0.lerp(q1, t)
```

### 7.3 Win Celebration Effects

```text
Confetti burst:
  - 60-100 particles
  - Colors: ACCENT_GOLD, ACCENT_PINK, ACCENT_CYAN, SUCCESS
  - Shapes: rectangles (confetti strips) + circles (dots)
  - Gravity: slight downward pull
  - Lifetime: 2000–3000ms
  - Spread: 360° from screen center
  - Initial velocity: 400–800px/s

Golden rain (Fever win):
  - 30 gold particles falling from top
  - Shimmer rotation
  - Lifetime: 1500ms
  - Used only for 3-star or Fever-active wins
```

---

## 8. Категория 5 — Анимации прогрессии

### 8.1 World Map Path Animation

```text
При разблокировке нового уровня:
  1. Текущий node пульсирует [300ms, glow up]
  2. Путь от текущего к следующему node "рисуется" (stroke animation) [600ms]
  3. Новый node "зажигается" (scale 0→1.0, opacity 0→1, glow) [400ms, spring]
  4. Camera pan к новому node [500ms, ease_in_out]
  5. "You are here" tooltip появляется [200ms, fade_in + slide_up]

Total: ~2000ms
```

```gdscript
func _animate_level_unlock(from_node: Control, to_node: Control, path_line: Line2D) -> void:
    var tween = create_tween()

    # Current node pulse
    tween.tween_property(from_node, "modulate", Color(1.3, 1.3, 1.3), 0.3)
    tween.tween_property(from_node, "modulate", Color.WHITE, 0.15)

    # Path draw (animate end point ratio of Line2D)
    tween.tween_method(
        func(t): path_line.points[-1] = path_line.get_point_position(0).lerp(to_node.position, t),
        0.0, 1.0, 0.6
    ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

    # New node appear
    to_node.scale = Vector2.ZERO
    to_node.modulate.a = 0.0
    tween.tween_property(to_node, "scale", Vector2.ONE, 0.4) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(to_node, "modulate:a", 1.0, 0.3)

    # Camera pan
    tween.tween_property(camera, "position", to_node.position, 0.5) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    # Tooltip
    tween.tween_property(tooltip, "modulate:a", 1.0, 0.2)
    tween.parallel().tween_property(tooltip, "position:y", tooltip.position.y - 10, 0.2)
```

### 8.2 Star/Score Evolution

```text
При увеличении рейтинга или прокачке:
  1. Old value → flash [100ms]
  2. Counter roll (old → new) [400ms, ease_out]
  3. New value glow pulse [300ms]
  4. If milestone reached: burst particles + badge popup [500ms]
```

---

## 9. Performance Budget

### 9.1 Particle Budget per Screen

| Screen | Max Particle Systems | Max Active Particles | Notes |
|---|---|---|---|
| Loading | 3 | 60 | bubbles + sparkles + diamonds |
| Main Menu | 4 | 80 | bubbles + sparkles + orb shimmer + crystals |
| World Map | 3 | 40 | clouds + sparkles + path glow |
| Level Preview | 2 | 30 | sparkles + booster glow |
| Gameplay (idle) | 2 | 20 | subtle sparkles + ambient |
| Gameplay (match) | 6 | 120 | **peak budget** — match VFX |
| Gameplay (cascade x5+) | 8 | 180 | **absolute max** — fever spark |
| Pause | 0 | 0 | all ambient PAUSED |
| Level Complete | 4 | 100 | confetti + sparkles + reward trails |
| Out of Moves | 1 | 10 | sad sparkle only |
| Daily Rewards | 3 | 50 | orb shimmer + sparkles + reward glow |
| Shop | 2 | 30 | featured card glow + sparkles |

### 9.2 Performance Tier Overrides

```gdscript
# Performance tier multipliers for particle counts
const TIER_MULTIPLIERS = {
    "high": 1.0,    # Full particles
    "mid": 0.6,     # 60% particles
    "safe": 0.3     # 30% particles, no blur, no camera shake
}

# Items disabled on android_safe:
# - Blur shaders (solid fallback)
# - Camera shake
# - Reward trail particles (instant counter update)
# - Idle sphere breathing (static)
# - Confetti > 30 particles
```

### 9.3 Tween Budget

```text
Max active tweens per frame: 20
Max concurrent particle systems: 8
Camera shake cooldown: 3 seconds minimum between shakes
Sound polyphony: max 6 simultaneous sound effects

If frame drops below 50fps:
  → Reduce particle count by 50%
  → Skip idle animations
  → Simplify squash/stretch to instant scale
```

---

## 10. Reduced Motion — Accessibility

```gdscript
# All motion functions check this flag first
class_name MotionSettings

static var reduced_motion: bool = false

## Call this on settings change
static func set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    if enabled:
        # Kill all ambient tweens
        # Set all transitions to instant
        # Replace particle effects with static icons
        # Replace camera shake with screen flash
        # Replace confetti with simple color pulse

## Usage pattern in all animation functions:
static func animate_or_instant(node: Control, prop: String, val: Variant, dur: float) -> void:
    if MotionSettings.reduced_motion:
        node.set(prop, val)
    else:
        var tween = node.create_tween()
        tween.tween_property(node, prop, val, dur)
```

**Замена при reduced_motion:**

| Normal Animation | Reduced Motion Alternative |
|---|---|
| Particle confetti | Golden color pulse on background |
| Camera shake | Screen border flash (gold/cyan) |
| Squash & stretch | Instant position change |
| Idle breathing | Static (no motion) |
| Trail particles | Instant counter update |
| Cascade stagger | All spheres drop simultaneously |
| Modal slide | Instant appear/disappear |
| Button scale | Color change only |

---

## 11. Testing Checklist

```text
Timing verification:
  ☐ All tap→visual responses < 50ms
  ☐ All UI transitions 200–500ms
  ☐ No animation > 1000ms without clear progress indicator
  ☐ Launch sequence ≤ 2000ms
  ☐ Match clear ≤ 420ms

Physics feel:
  ☐ Squash/stretch preserves visual area
  ☐ Cascade falls from bottom to top with stagger
  ☐ Landing bounce feels physical
  ☐ Anticipation before special activation

Performance:
  ☐ 60fps maintained during cascades (high tier)
  ☐ 60fps maintained on all screens (safe tier)
  ☐ Particle budget respected per screen
  ☐ Tween count < 20 per frame

Accessibility:
  ☐ All animations have reduced_motion path
  ☐ No animation-only information (always icon/text backup)
  ☐ Camera shake has border flash alternative
  ☐ Confetti has color pulse alternative

Cascade ladder:
  ☐ x1→x2→x3→x4→x5 visually escalates
  ☐ VFX intensity matches cascade importance
  ☐ No VFX overlap that hides board state
  ☐ Title popups don't block input
```
