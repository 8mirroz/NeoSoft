# ADR 009: Balance Governor

**Status**: Accepted
**Date**: 2026-05-26
**Context**: v5 CCPE

## Контекст

Controlled Cascade Engine и расширенная экосистема спец-сфер (10 типов, 15 комбинаций) создают риск "игра играет сама". Нужен жёсткий governance layer, который предотвращает ощущение фейка и автопрохождения.

## Решение

Выделить BalanceGovernor как отдельную подсистему с правом блокировать любую нечестную операцию.

### Governance Parameters (JSON-driven)

```json
{
  "max_cascade_depth_default": 5,
  "max_cascade_depth_fever": 8,
  "lucky_drop_max_per_level": 2,
  "lucky_drop_min_turn_gap": 5,
  "lucky_drop_cannot_trigger_after_bad_random_move": true,
  "lucky_drop_prefer_after_skillful_shape": true,
  "assisted_drop_cooldown_turns": 3,
  "assisted_drop_max_per_level": 4,
  "assisted_drop_disabled_if_win_probability_too_high": true,
  "cinematic_drop_max_per_level": 1,
  "cinematic_drop_allowed_in_tutorial": true,
  "cinematic_drop_allowed_in_fever": true,
  "cinematic_drop_allowed_on_final_move": true,
  "anti_fake_rules": {
    "never_guarantee_paid_recovery": true,
    "never_force_loss_state": true,
    "never_hide_probability_shift_from_debug": true,
    "never_auto_complete_major_objective_without_player_chain": true
  }
}
```

### Anti-Auto-Win Rule

```text
Правило: Победа не должна выглядеть полностью автоматической.

Проверка:
  objective_completion_source == manual_or_player_triggered
  → если > 80% objective completion from cascade_or_assisted
  → BalanceGovernor уменьшает assisted probability на следующий ход
```

## Альтернативы

1. **Все лимиты hardcoded** — не гибко, нельзя тюнить без ребилда
2. **Без governance** — каскады и assisted drops ломают баланс
3. **Server-side governance** — out of scope

## Последствия

- Все balance параметры вынесены в `level_balance_profiles.json`
- Debug mode показывает reason для каждого governance решения
- Telemetry отслеживает все governance interventions
