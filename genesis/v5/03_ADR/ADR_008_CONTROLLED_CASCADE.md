# ADR 008: Controlled Cascade Engine

**Status**: Accepted
**Date**: 2026-05-26
**Context**: v5 CCPE

## Контекст

В v4 каскады были полностью детерминистичными — сферы падали честно, без управления. Это правильно для честности, но не даёт premium feel. Конкурентные паттерны (Candy Crush, Royal Match, Gardenscapes) используют управляемые каскады для усиления ощущения "живого поля".

## Решение

Ввести три режима выпадения (Natural, Assisted, Cinematic) под контролем CascadeGovernor и BalanceGovernor.

### Архитектурные компоненты

```text
ControlledCascadeEngine → решает, какой режим drop использовать
DropRngController       → управляет RNG для drop (seed, вероятности)
CascadeGovernor         → max cascade depth, принудительная стабилизация
BalanceGovernor         → anti-fake rules, cooldown, cap per level
```

### Правила Assisted Drop

```text
1. Допускается ТОЛЬКО после player_created_shape
2. Cooldown: 3 turns minimum
3. Max per level: 4
4. Блокируется если win_probability > threshold
5. Каждый assisted drop логируется в telemetry с debug_reason
```

### Правила Cinematic Drop

```text
1. Max 1 per level
2. Допускается при: fever_active, final_move_drama, tutorial_showcase
3. Визуально отличается slow-mo (0.2–0.4 sec)
4. Никогда не завершает уровень автоматически
```

## Альтернативы

1. **Полностью честный drop** — не даёт premium feel
2. **Неограниченный assisted drop** — ощущение фейка, "игра играет сама"
3. **Серверный контроль drop** — out of scope, требует сетевой инфраструктуры

## Trade-offs

| Критерий | Controlled | Fully Random | Unlimited Assist |
|---|---|---|---|
| Premium Feel | ✅ Высокий | ❌ Низкий | ✅ Высокий |
| Player Trust | ✅ Сохраняется | ✅ Макс | ❌ Теряется |
| Complexity | ⚠️ Средняя | ✅ Низкая | ⚠️ Средняя |
| Balance Risk | ⚠️ Управляемый | ✅ Нулевой | ❌ Высокий |

## Последствия

- Все assisted/cinematic drops имеют debug_reason
- BalanceGovernor может блокировать любой нечестный drop
- Telemetry отслеживает assisted_drop_usage_rate
