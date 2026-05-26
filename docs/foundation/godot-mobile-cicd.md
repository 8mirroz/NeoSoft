# Godot Mobile CI/CD Architecture

## Scope

Automate export and artifact delivery for Android/Web now, keep iOS lane prepared.

## Required Tooling

- `abarichello/godot-ci` for containerized export flows.
- `firebelley/godot-export` as action-based export alternative.
- `manleydev/butler-publish-itchio-action` for QA/demo delivery to itch.io.

## Pipeline Lanes

### Lane 1: Pull Request Validation (fast)
- Trigger: PR and push to feature branches.
- Checks:
  - project layout sanity (`project.godot` exists),
  - docs/rules consistency,
  - optional headless script checks (when gameplay scripts exist).

### Lane 2: Snapshot Export (manual or nightly)
- Trigger: `workflow_dispatch` and optional nightly schedule.
- Output:
  - Android debug build artifact,
  - Web build artifact for QA.

### Lane 3: Release Export + Distribution
- Trigger: tag `v*`.
- Output:
  - signed Android release artifact (AAB/APK),
  - optional Web release package.
- Optional deploy:
  - push build to itch.io channel with Butler action.

## Secrets and Config

- Android signing values must be stored in CI secrets.
- Itch.io deploy requires Butler API key and project/channel identifiers.
- Export presets must be committed (`export_presets.cfg`).

## Failure Gates

- Missing export preset -> fail pipeline.
- Missing signing secrets on release lane -> fail pipeline.
- Artifact upload/deploy failure -> block release completion.

