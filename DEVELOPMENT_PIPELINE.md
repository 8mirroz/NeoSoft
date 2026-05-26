# 3line Development Pipeline

This file is the entry point for future project planning and implementation.

## Primary Inputs

- Visual direction: `res://p1.md`
- Product/game systems: `res://p2.md`
- External references/licensing notes: `res://libra.md`
- Primary strategic research guide: NotebookLM `Deushare`
  - URL: https://notebooklm.google.com/notebook/b6565e2f-488c-4fa4-b67d-cd066594e6b6
  - ID: `b6565e2f-488c-4fa4-b67d-cd066594e6b6`

## Master Blueprint

- **Master blueprint (synthesized knowledge):** `docs/foundation/master-blueprint-rules.md` + `docs/foundation/skills-catalog.md`
- Derived from: 82 NotebookLM sources × 7 deep queries + p1/p2/libra analysis

## Execution Policy

- Architecture and rules: `res://docs/foundation/`
- Mandatory workflow: `res://docs/foundation/skill-policy.md`
- **Operational rules:** `res://docs/foundation/master-blueprint-rules.md` (7 rules)
- **Skills catalog:** `res://docs/foundation/skills-catalog.md` (8 skills)
- Decision trace log: `res://docs/foundation/decision-log.md`
- Research preflight: `./scripts/research_preflight.sh`
- Resource intake/verification: `./scripts/resource_sync.sh verify --engine godot`
- Codex + Godot MCP setup: `./scripts/setup_codex_godot_mcp.sh setup`
- CI/CD templates: `res://.github/workflows/`

## Knowledge Domains (from NotebookLM Deushare)

| # | Domain | Sources | Key Value |
|---|---|---|---|
| 1 | Match-3 Game Design | ~18 | Core mechanics, scoring, difficulty curves |
| 2 | Game Deconstruction | ~8 | Candy Crush, Royal Match, Gardenscapes params |
| 3 | Player Psychology | ~12 | Ethical retention vs dark patterns |
| 4 | UX/UI & Motion Design | ~10 | Timings, trends 2026, icon rules |
| 5 | VFX & Visual Effects | ~7 | Physics, anti-sandwich, particle tricks |
| 6 | Technical Architecture | ~15 | Model-View, CI/CD, SDK templates |
| 7 | Monetization | ~8 | F2P models, segmentation, pricing |
| 8 | Procedural Generation | ~4 | GAN, MCTS, auto-playtesting |

## MVP-First Rule

Ship MVP mechanics and quality gates first (from `p2.md`), then expand into full meta layer.

## Phase Map

```
A: Pre-production  → Architecture, CI/CD, data formats
B: Prototype       → Playable core loop (continuous gravity)
C: Visual Integration → p1.md style, gem readability tests
D: MVP Production  → 10 levels, boosters, UI, export
E: Balance & Playtest → Wave difficulty, MCTS bots, tuning
F: Soft Launch Prep → Analytics, retention, ethical monetization
```
