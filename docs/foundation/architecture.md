# 3line Architecture Blueprint

## Target Runtime

- Engine: Godot 4.x (project currently configured for 4.5 mobile renderer).
- Primary release targets: Web and Android for MVP.
- Runtime language for MVP core: GDScript (`runtime-language-strategy.md`).

## System Boundaries

### `core_match3`
- Board model, swap validation, match finding/resolution, gravity, refill, cascades.
- No direct dependency on UI nodes.
- Controller-first orchestration with explicit systems:
  - `MatchSystem`
  - `SheddingSystem`
  - `GenerationSystem`

### `level_runtime`
- Goal tracking, move limits, score/stars, win/lose states, hint trigger timing.
- Consumes board events, updates level state.

### `presentation_layer`
- HUD, menus, game screen, VFX, audio, haptics, transitions.
- Reads state and reacts to domain events; does not own game rules.

### `meta_layer` (post-MVP)
- Map progression, daily reward, lives/energy, shop/currency loops.
- Explicitly deferred until MVP gate is passed.

### `data_layer`
- Level configs and balance files, isolated from gameplay code.
- No hardcoded tuning constants inside swap/match logic.

## Cross-Layer Contract

Use event/signal-driven communication only:
- `swap_requested`
- `swap_resolved`
- `match_resolved`
- `cascade_completed`
- `goals_updated`
- `level_finished`

Direct calls from `presentation_layer` into board internals are forbidden.

## Phase Map (A-F)

### Phase A: Pre-production
- Lock module boundaries, data formats, scene map, performance budgets, Definition of Done.
- Exit gate: architecture docs approved and folder skeleton in place.

### Phase B: Prototype
- Implement playable gameplay loop without final art quality.
- Exit gate: stable swap/match/fall/refill/cascade plus win/lose.

### Phase C: Visual Integration
- Apply p1 style rules, ensure readability at gameplay scale (64px/96px checks).
- Exit gate: visual clarity and UX contrast validated.

### Phase D: MVP Production
- Deliver 10 levels, goals/moves/score, base boosters, menu/pause/save, Web+Android export path.
- Exit gate: complete MVP checklist from `p2.md`.

### Phase E: Balance and Playtest
- Tune difficulty, hint quality, score pacing, performance.
- Exit gate: key risks from `p2.md` section 39 mitigated.

### Phase F: Soft Launch Prep
- Add analytics baseline, retention hooks, economy safeguards, release checklist.
- Exit gate: launch candidate passes QA and telemetry checks.

## Target Project Skeleton

```text
res://
  docs/
    foundation/
  scenes/
    boot/
    menus/
    gameplay/
  scripts/
    core_match3/
    level_runtime/
    presentation/
    meta_layer/
  data/
    levels/
    balance/
  assets/
    ui/
    fx/
    audio/
    licenses/
```
