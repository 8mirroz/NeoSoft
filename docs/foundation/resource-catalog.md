# Resource Catalog (Godot Mobile Match-3)

## Priority P1 (Integrate first)

- `abarichello/godot-ci` — baseline export automation.
- `firebelley/godot-export` — action-based export pipeline.
- `Template (Four Games)` — controller-first style reference (manual asset-store retrieval).
- `M3Engine architectural concepts` — logic/view decoupling and state machine core.
- `MCTS playtesting reference` — headless simulation strategy for difficulty tuning.

## Priority P2 (After baseline CI is stable)

- `manleydev/butler-publish-itchio-action` — automated QA/demo deployment.
- `Survivors Starter Kit` and `Cogito` — architecture patterns for systems and UI flows (selective extraction, no full copy).

## Optional / Future

- EOS, Steamworks, GDK references for future social/platform rollout (not MVP blockers).

## Operations

Machine-readable manifest:
- `res://config/resource_manifest.tsv`

Sync/verify script:
- `./scripts/resource_sync.sh list --engine godot`
- `./scripts/resource_sync.sh verify --engine godot`
- `./scripts/resource_sync.sh clone --engine godot --target ./external`
- `./scripts/resource_sync.sh verify --engine godot --include-private` (for private/org-gated repos)
