# 3line Foundation

This folder is the source-of-truth layer for project decisions.

## Canonical Inputs

| Source | Role | When to use |
| --- | --- | --- |
| `res://p1.md` | Visual and art-direction standards | UI style, gem readability, lighting, animation timings |
| `res://p2.md` | Product and gameplay scope | MVP scope, systems, roadmap, risks, economy |
| `res://libra.md` | External references and legal/licensing notes | Engine/tooling choices, CI/CD references, licensing constraints |
| NotebookLM `Deushare` (`b6565e2f-488c-4fa4-b67d-cd066594e6b6`) | Primary strategic guide | Builds, mechanics, monetization, retention, and product-level tradeoffs |

## Governance Rule

Any new decision on builds, mechanics, balance, monetization, retention, or core difficulty must reference:
- a specific `p2.md` section, or
- a specific NotebookLM source item.

For complex system design, NotebookLM is the default first source.  
If no external backing exists, mark it as `Local assumption` in the decision log.

## Documents

- `architecture.md`: system boundaries and phase map (A-F).
- `engine-strategy.md`: engine decision and re-evaluation triggers.
- `engineering-rules.md`: production rules, quality gates, risk controls.
- `godot-mobile-cicd.md`: CI/CD lanes and mobile export/deploy architecture.
- `codex-godot-mcp.md`: Codex MCP integration for Godot editor/runtime workflows.
- `controller-first-match3-core.md`: engine-decoupled core loop blueprint.
- `runtime-language-strategy.md`: GDScript vs C# platform strategy.
- `resource-catalog.md`: prioritized resource intake for this project.
- `master-blueprint-rules.md`: operational rules extracted from NotebookLM synthesis.
- `skills-catalog.md`: reusable workflows for ongoing development cycles.
- `skill-policy.md`: mandatory Superpowers workflow for feature delivery.
- `decision-log.md`: ongoing decision ledger with source references.
- `mvp-mapping.md`: MVP feature ownership by module and phase.
- `visual-acceptance.md`: measurable visual gates derived from `p1.md`.
- `mvp-checklist.md`: current MVP closure checklist tied to repo truth.
- `balance-baseline.md`: accepted simulation baseline for shipped levels.
- `export-readiness.md`: current local and CI export verification status.
- `soft-launch-release-checklist.md`: release checklist for soft-launch candidate review.

## Research Quick Start

```bash
./scripts/notebooklm_safe.sh use b6565e2f-488c-4fa4-b67d-cd066594e6b6 --json
./scripts/notebooklm_safe.sh summary
./scripts/notebooklm_safe.sh source list
./scripts/research_preflight.sh
./scripts/resource_sync.sh verify --engine godot
```
