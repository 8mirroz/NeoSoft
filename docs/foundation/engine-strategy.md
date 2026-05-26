# Engine Strategy (Mobile Match-3)

## Decision (2026-05-26)

- **Execution engine for this repository:** Godot 4.x.
- **Reason:** active project and assets already live in a Godot workspace; fastest route to MVP and playtest loops.
- **Secondary track:** Unity references stay in research catalog for possible scale-up migration after MVP gate.

## Decision Criteria

1. Time to first playable MVP.
2. Ability to keep logic decoupled from rendering/UI.
3. CI/CD readiness for mobile export.
4. Support for long-term meta systems (economy, retention, live-ops).
5. Team/tooling overhead in the current repository.

## Current Positioning

### Godot (Primary now)
- Best fit for immediate delivery in this repo.
- Keep architecture engine-agnostic at core model level.
- Use controller-first patterns and event-driven boundaries.

### Unity (Research lane)
- Strong ecosystem for advanced mobile meta/live-ops.
- Use as comparison baseline, not migration target right now.
- Re-evaluate after Phase D MVP metrics.

### Unreal (Reference only)
- Useful for GAS and architecture study.
- Not selected for this match-3 mobile build path.

## Re-evaluation Trigger

Re-open engine decision only if one of these happens:
- MVP in Godot misses performance/export stability targets.
- Required platform/service integration becomes a blocker.
- Team decides to invest in larger live-ops/mobile stack and accepts migration cost.

