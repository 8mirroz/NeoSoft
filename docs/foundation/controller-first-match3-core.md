# Controller-First Match-3 Core (Engine-Decoupled)

## Objective

Implement core loop logic independent from scene/view nodes, so gameplay is deterministic, testable, and suitable for headless simulation.

## Core Runtime States

- `IdleState`
- `InputState`
- `ResolveSwapState`
- `ResolveMatchState`
- `SheddingState` (gravity/fall)
- `GenerationState` (spawn/refill)
- `CascadeState`
- `WinLoseState`

State transitions are driven by logic events, not by animation callbacks.

## Mandatory Systems

- `MatchSystem`: detect lines/figures and special-piece creation candidates.
- `SheddingSystem`: resolve gravity and column collapse after removals.
- `GenerationSystem`: spawn new pieces and validate board continuity.

## Data Model Rules

- Piece entity is not hard-bound to visual cell nodes.
- Board occupancy is a logical map (`cell -> piece_id`) updated by systems.
- Visual layer consumes movement/removal/spawn events from logic layer.

## Contract Example (conceptual)

- Input: `SwapCommand(from_cell, to_cell)`
- Output events:
  - `SwapRejected`
  - `SwapAccepted`
  - `MatchesResolved`
  - `BoardCollapsed`
  - `PiecesGenerated`
  - `TurnFinished`

## Headless Simulation Path

- Provide deterministic random seed support.
- Expose a simulation entrypoint for batch level-play runs.
- Use simulation outputs for:
  - difficulty tuning,
  - dead-board detection,
  - move economy balancing.

## MCTS / Agent Research Integration

- Research baseline is tracked from NotebookLM and external MCTS references.
- Keep headless API stable so agent runners can evaluate thousands of episodes.

