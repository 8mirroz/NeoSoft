# Протокол детерминированных реплеев (Replay Protocol) — Genesis v5.1

Для обеспечения 100% воспроизводимости игровых сессий, воспроизведения багов и тестирования сходимости уровней через MCTS вводится единый стандарт сериализации сессий в JSON.

Файлы реплеев сохраняются в каталоге `artifacts/replays/` и имеют расширение `.json`.

---

## 1. Схема JSON протокола

```json
{
  "protocol_version": "5.1",
  "level_id": "dreamy_skies_level_1",
  "difficulty_profile": "medium_tier_2",
  "initial_seed": 42,
  "board_dimensions": {
    "width": 8,
    "height": 8
  },
  "initial_board_snapshot": {
    "width": 8,
    "height": 8,
    "cells": [
      [{"color": "blue", "state": 0, "special_type": 0}, "..."],
      ["..."]
    ]
  },
  "player_moves": [
    {
      "turn_index": 0,
      "swipe_from": {"x": 2, "y": 3},
      "swipe_to": {"x": 3, "y": 3},
      "queued_inputs_during_turn": [
        {"swipe_from": {"x": 4, "y": 4}, "swipe_to": {"x": 5, "y": 4}, "delay_msec": 450}
      ],
      "expected_score_gained": 120,
      "expected_final_board_hash": "a4f89d3810c9e123"
    }
  ],
  "final_summary": {
    "total_score": 15400,
    "stars_earned": 3,
    "moves_remaining": 12,
    "result": "won"
  }
}
```

---

## 2. Алгоритм воспроизведения (Replay Invariants)

При инициализации `ReplayPlayer`:
1. Извлекается `initial_seed` и передается в `DropRngController`. Это замораживает генератор псевдослучайных чисел.
2. Поле доски заполняется строго в соответствии с `initial_board_snapshot` (а не случайной генерацией).
3. По шагам воспроизводится каждый ход из массива `player_moves`:
   * Имитируется вызов `swap_requested` через `InputBufferController`.
   * Если в массиве `queued_inputs_during_turn` есть буферизованные свайпы, они инжектируются в очередь ввода в строго указанные моменты времени (симуляция задержки ввода).
   * ResolvePipeline полностью рассчитывает ход, сдвиги гравитации и каскады под управлением Seeded RNG.
4. В конце каждого хода логический снапшот поля сверяется с `expected_final_board_hash`. Любое расхождение означает потерю детерминизма (desync), что немедленно прерывает тест и отправляет баг в лог.
