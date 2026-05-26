# Antigravity Agent Configuration and Navigation Guide

## 📍 Current Status
- **Latest Arch Version**: `genesis/v5`
- **Active Task List**: `Pending` (Wait for /blueprint)
- **Last Updated**: `2026-05-26`

---

## 🌳 Project Structure

> **Note**: Maintained by `/genesis`.

```text
/Users/user/3-line/
├── genesis/v5/          # Arch Docs (Active)
│   ├── 00_MANIFEST.md
│   ├── concept_model.json
│   ├── 01_PRD.md
│   ├── 02_ARCHITECTURE_OVERVIEW.md
│   ├── 03_ADR/
│   │   ├── ADR_001_TECH_STACK.md
│   │   ├── ADR_002_RESOLVER_PIPELINE.md
│   │   ├── ADR_003_INPUT_BUFFER_CONTROLLER.md
│   │   ├── ADR_004_MATCH_SHAPE_DETECTOR.md
│   │   ├── ADR_005_TARGET_PRIORITY_SYSTEM.md
│   │   ├── ADR_006_FEEDBACK_ORCHESTRATOR.md
│   │   ├── ADR_007_TELEMETRY_BALANCE_SYSTEM.md
│   │   ├── ADR_008_CONTROLLED_CASCADE.md
│   │   ├── ADR_009_BALANCE_GOVERNOR.md
│   │   └── ADR_010_UI_UX_SYSTEM.md
│   ├── 04_SYSTEM_DESIGN/
│   │   ├── combo_fever_engine.md
│   │   ├── ui_ux_system.md
│   │   └── ui-ux-design-system.md     ★ Design System v1.0
│   ├── 06_CHANGELOG.md
│   └── 07_INSTALLED_SKILLS.md
├── genesis/v4/          # Arch Docs (Previous)
├── scenes/              # Game Scenes
│   ├── boot/
│   ├── gameplay/
│   │   ├── gameplay.gd
│   │   ├── gameplay.tscn
│   │   └── board_visual.gd
│   └── menus/
├── scripts/             # GDScript Sources
│   ├── core_match3/     # Логика и математика Match-3
│   ├── level_runtime/   # Рантайм игровых сессий
│   ├── presentation/    # Про процедурный визуал
│   └── validation/      # Headless тесты и MCTS
└── ui1/
    └── screens 01/      # Reference UI mockups (10 PNG screens)
```

---

## 🧭 Navigation Guide

- **Arch Overview**: [02_ARCHITECTURE_OVERVIEW.md](file:///Users/user/3-line/genesis/v5/02_ARCHITECTURE_OVERVIEW.md)
- **PRD**: [01_PRD.md](file:///Users/user/3-line/genesis/v5/01_PRD.md)
- **ADR**: See [genesis/v5/03_ADR/](file:///Users/user/3-line/genesis/v5/03_ADR/)
- **Detailed Design**: [combo_fever_engine.md](file:///Users/user/3-line/genesis/v5/04_SYSTEM_DESIGN/combo_fever_engine.md)
- **UI/UX Design System**: [ui-ux-design-system.md](file:///Users/user/3-line/genesis/v5/04_SYSTEM_DESIGN/ui-ux-design-system.md) ★
- **UI/UX Screens**: [ui_ux_system.md](file:///Users/user/3-line/genesis/v5/04_SYSTEM_DESIGN/ui_ux_system.md)
- **Task List**: Pending (run /blueprint)

---

## 🎯 Active Skills

> **Note**: Maintained by `/skill-install`.

### Core Development (3)
- [modern-web-guidance](file:///Users/user/.gemini/config/plugins/modern-web-guidance-plugin/skills/modern-web-guidance/SKILL.md)
- [chrome-devtools](file:///Users/user/.gemini/config/plugins/chrome-devtools-plugin/skills/chrome-devtools/SKILL.md)
- [godot-mobile-match3](file:///Users/user/3-line/.agent/skills/active/godot-mobile-match3.md)

### Management & Architecture (2)
- [design-system-guidance](file:///Users/user/.gemini/config/plugins/custom-design-system/skills/design-system-guidance/SKILL.md)
- [google-antigravity-sdk](file:///Users/user/.gemini/config/plugins/google-antigravity-sdk/skills/google-antigravity-sdk/SKILL.md)

**Total Skills**: 5  
**Last Updated**: `2026-05-26`
