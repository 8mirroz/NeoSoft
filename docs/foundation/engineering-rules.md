# 3line Engineering Rules

## 1. Scope and Quality Baseline

- Build MVP first; postpone full meta layer until MVP gate passes.
- Keep systems modular; avoid god-scripts with mixed responsibilities.
- Prefer data-driven tuning over hardcoded constants.

## 2. Licensing and Asset Policy

- Allowed by default for code/assets in core build: MIT, Apache-2.0, CC0.
- `GPL` dependencies are not allowed in the production code path.
- `CC-BY` assets require attribution entry before merge/use.
- Every imported asset must be recorded in `res://assets/licenses/credits.md`.

Required fields per asset:
- source URL
- asset/package name
- license
- author/publisher
- date added
- usage note

## 3. Architecture Guardrails

- `core_match3` and `level_runtime` cannot depend on concrete HUD/menu scenes.
- `presentation_layer` cannot mutate board state directly.
- Layer communication must use signals/events.
- Balance and level goals must load from data files (`res://data/...`).
- Match-3 core loop must preserve controller-first orchestration:
  - `MatchSystem`
  - `SheddingSystem`
  - `GenerationSystem`

## 4. NotebookLM Research Rule

NotebookLM `Deushare` is the primary guide for complex project design.

For decisions about builds, mechanics, difficulty, retention, monetization, and analytics:
- cite a NotebookLM source item, or
- cite a section in `p2.md`.

If neither is available, mark explicitly as `Local assumption`.

Use the safe wrapper to avoid proxy-related failures:

```bash
./scripts/notebooklm_safe.sh <command>
```

## 5. Verification Gates

### Spec consistency gate
- Each MVP feature from `p2.md` is mapped in `mvp-mapping.md`.
- Each key visual rule from `p1.md` has measurable checks in `visual-acceptance.md`.

### Research integrity gate
- Decision log contains source references for balance/retention/monetization.
- `research_preflight.sh` passes (`doctor`, `use`, `summary`, `source list`).

### Delivery readiness gate
- MVP includes Web and Android export path.
- `p2.md` section 39 risks have mitigation and test checks.
- CI templates exist and are configured for:
  - Godot export automation (`abarichello/godot-ci` or `firebelley/godot-export`)
  - optional itch QA deployment (`manleydev/butler-publish-itchio-action`)
