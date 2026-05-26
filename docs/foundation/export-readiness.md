# Export Readiness

This document captures the current export truth for Phase D and Phase F.

## Confirmed Ready

- `export_presets.cfg` defines `Web` and `Android` presets.
- CI workflows exist in `.github/workflows/` for:
  - `build.yml`
  - `godot-export-firebelley.yml`
  - `itch-publish.yml`

## Local Verification Result

Web command:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/user/3-line --export-release Web /tmp/nsf-export-web/index.html
```

Observed blocker:

- Missing export templates under `~/Library/Application Support/Godot/export_templates/4.5.1.stable/`

Android command:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/user/3-line --export-release Android /tmp/nsf-export-android/neo_soft_frost.apk
```

Observed blockers:

- Missing Android export templates under `~/Library/Application Support/Godot/export_templates/4.5.1.stable/`
- Java SDK path is not configured in the Godot editor environment
- Android SDK path is not configured in the Godot editor environment
- `platform-tools`, `build-tools`, `adb`, and `apksigner` are not available through the configured Android SDK path

## Next Actions

- Install Godot `4.5.1` export templates locally.
- Configure Java SDK in Godot editor settings.
- Configure Android SDK in Godot editor settings.
- Re-run both local export commands.
- Keep CI export lanes as the canonical automated path.
