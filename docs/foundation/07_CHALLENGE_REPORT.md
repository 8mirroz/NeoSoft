# Neo Soft Frost — Challenge Audit Report

> **Review Date**: 2026-05-26  
> **Scope**: All foundation & core scripts under `res://docs/foundation/` and `res://scripts/`  
> **Reviewer**: AI Challenger  
> **Total Findings**: 3 Real Issues (1 Critical - Solved, 2 High)  

---

## 🎯 Review Methodology

This review uses a 3-dimensional analysis framework to ensure high-fidelity evaluation:

1. **System Design** - Architectural integrity, boundary clarity, consistency
2. **Runtime Simulation** - Temporal correctness, state synchronization, boundary conditions
3. **Engineering Implementation** - Testability, maintainability, performance, security

Each issue is backed by **direct evidence from code execution or compilation errors** rather than abstract predictions.

---

## 📊 Statistics

| Severity | Count | % |
|----------|-------|---|
| **Critical** | 1 | 33.3% |
| **High** | 2 | 66.7% |
| **Medium** | 0 | 0.0% |
| **Low** | 0 | 0.0% |
| **Total** | **3** | **100%** |

| Dimension | Count |
|-----------|-------|
| System Design | 1 |
| Runtime Sim | 1 |
| Engineering | 1 |

---

# Part 1: System Design Issues

## 🟠 High Level

### S1. Visual Drift and Shape Discrepancy (8 Gems vs 6 Gems)

**Severity**: High  
**Document**: [board_view.gd](file:///Users/user/3-line/scripts/presentation/board_view.gd#L445) and [gem_view.gd](file:///Users/user/3-line/scripts/presentation/gem_view.gd#L14)

**Description**:
The design-system standard defines **8 unique gem types** (0 to 7), and [gem_view.gd](file:///Users/user/3-line/scripts/presentation/gem_view.gd) fully implements them with distinct geometric shapes and color palettes. 

However, in [board_view.gd](file:///Users/user/3-line/scripts/presentation/board_view.gd), both the shape rendering match block (line 445) and the palette picker (line 610) use `wrapi(piece_id, 0, 6)`. This operation compresses any piece with ID 6 (Amethyst Haze) or 7 (Rose Glow) into the 0–5 range, making them render identical to piece 0 (Pink Pearl) or piece 1 (Blue Flow).

**Source of Evidence**:
*   `gem_view.gd` defines 8 styles in `PALETTES`.
*   `board_view.gd` line 445:
    ```gdscript
    match wrapi(piece_id, 0, 6):
        0: _draw_star_dust(...)
        ...
    ```
*   `board_view.gd` line 610:
    ```gdscript
    func _get_palette(piece_id: int) -> Dictionary:
        match wrapi(piece_id, 0, 6):
            ...
    ```

**Impact**:
*   **Gameplay Core Broken**: Gems of type 6 and 7 will look identical to gems of type 0 and 1 on the board, but they **will not match/collapse** together because `BoardModel` treats them as different IDs. The player will see a row of 3 identical gems that refuses to match, breaking the Match-3 core.

**Recommendation**:
*   Expand `board_view.gd` to fully support all 8 gem types by mapping shapes and palettes up to `wrapi(piece_id, 0, 8)` and implement `_draw_octagon()` and `_draw_rose()` inside `board_view.gd` to achieve visual consistency with `gem_view.gd`.

---

# Part 2: Runtime Simulation Issues

## 🟠 High Level

### R1. Temporal Input Desynchronization (Missing Input Lock during VFX)

**Severity**: High  
**Document**: [gameplay.gd](file:///Users/user/3-line/scenes/gameplay/gameplay.gd#L208) and [board_view.gd](file:///Users/user/3-line/scripts/presentation/board_view.gd#L242)

**Description**:
`BoardController._resolve_turn` processes matches, collapses, and top refills **instantaneously and synchronously** in memory, settling the model state. It emits events (`board_collapsed`, `pieces_generated`) immediately. 

`BoardView` intercepts these events and plays slide/collapse animations over time (`MATCH_POP_DURATION = 0.38s`, `FALL_TRAIL_DURATION = 0.28s`, `SPAWN_REVEAL_DURATION = 0.34s`). 

However, during these active animations, [gameplay.gd](file:///Users/user/3-line/scenes/gameplay/gameplay.gd)'s `_on_board_cell_pressed` does NOT check if the board is animating. The player can tap or swipe moving tiles. These gestures resolve against the *settled* coordinates in the logic model rather than the *visual* positions on screen, causing action desynchronization.

**Source of Evidence**:
*   `board_controller.gd` line 108 `_resolve_turn()` settles the board in a synchronous `while` loop.
*   `gameplay.gd` line 208 `_on_board_cell_pressed` only guards against `session_finished` or `session_paused`.

**Impact**:
*   Clicking on an animating tile registers as clicking on whatever new gem has already taken its place in the logic board, leading to visual glitches, wrong selections, and perceived input lag/unresponsiveness.

**Recommendation**:
*   Introduce an `animating` state or check `board_visual._has_active_effects()` before emitting `EventBus.gem_tapped` inside `gameplay.gd`. Block cell pressed inputs when the visual presentation layer is actively rendering transitions.

---

# Part 3: Engineering Implementation Issues

## 🔴 Critical Level (Solved ✅)

### E1. GDScript Strict Inference Warning Treated as Compile Error

**Severity**: Critical (Resolved)  
**Document**: [board_view.gd](file:///Users/user/3-line/scripts/presentation/board_view.gd#L345)

**Description**:
With Godot's strict warning configuration (where warnings are treated as compilation errors), `board_view.gd` failed to compile because of static type inference (`:=`) on values retrieved from a dynamic Dictionary (which returns Variant type).
```gdscript
var offset := gem_offsets.get(cell, Vector2.ZERO) # Warn: inferred from Variant
```
This warning broke `board_view.gd` compilation, causing a cascade compilation failure in `gameplay.gd` (which references class `BoardView`), rendering the entire gameplay scene unrunnable.

**Source of Evidence**:
*   Godot Headless output during smoke test:
    ```text
    SCRIPT ERROR: Parse Error: The variable type is being inferred from a Variant value, so it will be typed as Variant. (Warning treated as error.)
              at: GDScript::reload (res://scripts/presentation/board_view.gd:345)
    SCRIPT ERROR: Trying to assign value of type 'Control' to a variable of type 'board_view.gd'.
              at: @implicit_ready (res://scenes/gameplay/gameplay.gd:8)
    ```

**Impact**:
*   **Total Runtime Failure**: The game crashed on startup when trying to load the gameplay scene, completely failing E2E smoke tests.

**Recommendation (Implemented)**:
*   Change the dynamic type inference to explicit static types:
    ```gdscript
    var offset: Vector2 = gem_offsets.get(cell, Vector2.ZERO)
    var scale_factor: Vector2 = gem_scales.get(cell, Vector2.ONE)
    var alpha: float = gem_alphas.get(cell, 1.0)
    ```
    This resolved the compile error and restored 100% test compliance.

---

# Summary & Recommendations

## 🎯 Core Findings

*   **Critical Issues**: Resolving the compile-time type warning in `board_view.gd` was crucial to restoring gameplay functionality.
*   **High Issues**: The temporal desynchronization (input while animating) and the 6-vs-8 gem visual count drift represent high risks for playability and consistency that must be prioritized before release.

---

## 📋 Action Checklist

### P0 - Immediate (Blocking)
1.  [x] **Fix board_view.gd Parse Errors**: Resolved by explicitly typing variant dictionary lookups.

### P1 - Near Term (Important)
1.  [ ] **Block Input during VFX**: Update `gameplay.gd`'s `_on_board_cell_pressed` to reject inputs while `board_visual._has_active_effects()` is true.
2.  [ ] **Support 8 Gems on Board**: Modify `board_view.gd` to support all 8 piece types instead of wrapping them to 6, maintaining visual symmetry with `gem_view.gd`.

---

## 🚦 Final Judgment

*   **[x] 🟡 Project can proceed, solve P1 next** (P0 is already solved, E2E Smoke test passes successfully!)

---

## 📚 Appendix

### A. Pre-Mortem Analysis

| Failure Scenario | Root Cause | Probability | Related Issues |
|------------------|------------|:-----------:|----------------|
| Playability Crash | Type warning treated as compilation error | 🔴 High (Fixed) | E1 |
| Glitchy Cascades | Clicking on moving tiles registers on settled state | 🟡 Medium | R1 |
| Match-3 Failures | Gems of type 6/7 look like 0/1 but do not collapse | 🔴 High | S1 |

### B. Assumption Validation Results

| Aspect | Current Design | Eval | Issue |
|--------|----------------|:----:|-------|
| Concurrency / User Input | Allows user taps during cascades | ❌ | R1 (Taps register on settled state) |
| Visual Symmetry | BoardView only supports 6 gems; UI has 8 | ❌ | S1 (Identical gems do not match) |
| Strict Typing | Uses variant type inference `:=` | ❌ (Fixed)| E1 (Crashes compilation) |
