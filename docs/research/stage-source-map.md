# Stage Source Map (NotebookLM Deushare)

This file converts NotebookLM source inventory into phase-aligned implementation evidence for 3line.

## Method

- Input: `docs/research/_generated/latest-sources.json` (82 sources in this snapshot).
- Scoring: keyword-based relevance per phase A-F with mobile-scope penalties.
- Use this map for planning and decision-log citations before implementation.

## Snapshot Summary

Summary:
These technical sources examine the **mathematical frameworks** and 
**psychological mechanics** that drive modern game design. Researchers explore 
**automated playtesting** in matching tile games by using **procedural 
personas** and **Monte Carlo Tree Search** to simulate diverse human playstyles,
ranging from high-scoring strategies to move-minimizing behaviors. Parallel 
discussions analyze the **manipulative design** of mobile games, highlighting 
how **dopamine loops**, social triggers, and visual cues are engineered to 
foster habit formation and encourage **in-game spending**. Psychological studies
further note the impact of these trends on **early childhood development**, 
specifically how digital socialization replaces traditional interpersonal 
interaction. Finally, the text provides practical methodologies for **game 
balancing**, detailing how designers project **combat curves** and progression 
scales to maintain player motivation. Collectively, the sources illustrate how 
**data-driven modeling** and behavioral psychology are utilized to optimize both
the **user experience** and the commercial viability of digital entertainment.

## Phase A — Pre-production

Usefulness counts: high=9, medium=14, low=58

Top high-value sources:
- [ab6a6583-bd54-4613-969d-804b0348302e] Architectural Paradigms, Automation Frameworks, and Integration Blueprints in Modern Game Development (SourceType.MARKDOWN; score=6; topics=architecture, ci_cd)
- [288e4620-53cb-45a6-ac3f-cad07dd64fa7] godot-ci · Actions · GitHub Marketplace (SourceType.WEB_PAGE; score=5; topics=ci_cd, tooling)
- [1e94ae18-1e9c-43c9-ac4e-4b05b0a456c4] game-ci/unity-builder: Build Unity projects for different platforms - GitHub (SourceType.WEB_PAGE; score=5; topics=ci_cd, tooling, ux_ui)
- [237d9ee0-aebc-4ec7-a3cb-ea67f87a274e] abarichello/godot-ci: Docker image to export Godot Engine ... - GitHub (SourceType.WEB_PAGE; score=5; topics=ci_cd, content_pipeline, tooling)
- [d8a30cda-ba54-4ded-af8f-d5bb88dbe282] Releases · abarichello/godot-ci - GitHub (SourceType.WEB_PAGE; score=5; topics=ci_cd, tooling)
- [ae4be4b8-fccd-46ef-a46a-64b743ceb0f6] Orchestration plugin for game-ci (AWS, Kubernetes, Docker, and more) allowing "distributed workloads" (e.g build, test) and advanced workflows for large projects - GitHub (SourceType.WEB_PAGE; score=5; topics=ci_cd, goals_progression, tooling, ux_ui)
- [ee6953dd-b0cc-4a52-8363-e1271125d564] I created a CI/CD system (automated builds) for Unity using GitHub Actions. - Reddit (SourceType.WEB_PAGE; score=5; topics=ci_cd, tooling, ux_ui)
- [55858c9a-f485-4f72-bb8f-1999dff54cc3] Godot CI to Publish From Github to Itch.io - Survive the Island by MurphysDad, Scrapy Ninja, 00Her0, immortalicecream (SourceType.WEB_PAGE; score=5; topics=ci_cd, tooling)

Noise/defer for this project scope:
- [d2979807-d898-406d-a9a5-4ae6f367de5f] Access Microsoft Game Development Kit (GDK) development ... (platform mismatch for mobile-first match-3 scope)
- [68005e1b-c263-473e-b566-27e83bc01eab] Building the Sentry Unreal Engine SDK with GitHub Actions (platform mismatch for mobile-first match-3 scope)
- [42f0a099-a512-48cf-b17a-d9b9e36191b9] C SDK - Epic Online Services - Epic Games (platform mismatch for mobile-first match-3 scope)
- [940411c8-af8a-429e-a4d5-ec8d2b0eee28] DEVBOX10/microsoft-GDK: Microsoft Public GDK - GitHub (platform mismatch for mobile-first match-3 scope)
- [ef60512c-0d08-4d6b-b557-ba829710be74] EOS SDK and Game Engines Introduction | Epic Online Services Developer (platform mismatch for mobile-first match-3 scope)

## Phase B — Prototype Core Loop

Usefulness counts: high=1, medium=7, low=73

Top high-value sources:
- [e27f8572-e6fb-4bd2-b027-396057b58482] Procedural Content Generation of Puzzle Games using Conditional Generative Adversarial Networks - arXiv (SourceType.PDF; score=5; topics=algorithms, content_pipeline, match3_core)

Noise/defer for this project scope:
- [d2979807-d898-406d-a9a5-4ae6f367de5f] Access Microsoft Game Development Kit (GDK) development ... (platform mismatch for mobile-first match-3 scope)
- [68005e1b-c263-473e-b566-27e83bc01eab] Building the Sentry Unreal Engine SDK with GitHub Actions (platform mismatch for mobile-first match-3 scope)
- [42f0a099-a512-48cf-b17a-d9b9e36191b9] C SDK - Epic Online Services - Epic Games (platform mismatch for mobile-first match-3 scope)
- [940411c8-af8a-429e-a4d5-ec8d2b0eee28] DEVBOX10/microsoft-GDK: Microsoft Public GDK - GitHub (platform mismatch for mobile-first match-3 scope)
- [ef60512c-0d08-4d6b-b557-ba829710be74] EOS SDK and Game Engines Introduction | Epic Online Services Developer (platform mismatch for mobile-first match-3 scope)

## Phase C — Visual Integration

Usefulness counts: high=1, medium=12, low=68

Top high-value sources:
- [bbfb76b8-f87f-4ed7-a5c6-d3a0fe6b4a1f] The Impact of Motion Design on User Experience in Mobile Apps - MoldStud (SourceType.WEB_PAGE; score=6; topics=animation_vfx, mobile_platform, retention, ux_ui)

Noise/defer for this project scope:
- [d2979807-d898-406d-a9a5-4ae6f367de5f] Access Microsoft Game Development Kit (GDK) development ... (platform mismatch for mobile-first match-3 scope)
- [68005e1b-c263-473e-b566-27e83bc01eab] Building the Sentry Unreal Engine SDK with GitHub Actions (platform mismatch for mobile-first match-3 scope)
- [42f0a099-a512-48cf-b17a-d9b9e36191b9] C SDK - Epic Online Services - Epic Games (platform mismatch for mobile-first match-3 scope)
- [940411c8-af8a-429e-a4d5-ec8d2b0eee28] DEVBOX10/microsoft-GDK: Microsoft Public GDK - GitHub (platform mismatch for mobile-first match-3 scope)
- [ef60512c-0d08-4d6b-b557-ba829710be74] EOS SDK and Game Engines Introduction | Epic Online Services Developer (platform mismatch for mobile-first match-3 scope)

## Phase D — MVP Production

Usefulness counts: high=0, medium=9, low=72

Top medium-value sources (fallback):
- [36e4fd79-0199-4ece-bcb1-cb0e3689611b] TEST REPORT (SourceType.PDF; score=4; topics=content_pipeline, goals_progression)
- [63c93ab6-6fe1-4f36-adf5-9ad8d397ba8d] Frequently Asked Questions (FAQ) - GameCI (SourceType.WEB_PAGE; score=3; topics=ci_cd, level_design)
- [237d9ee0-aebc-4ec7-a3cb-ea67f87a274e] abarichello/godot-ci: Docker image to export Godot Engine ... - GitHub (SourceType.WEB_PAGE; score=2; topics=ci_cd, content_pipeline, tooling)
- [e27f8572-e6fb-4bd2-b027-396057b58482] Procedural Content Generation of Puzzle Games using Conditional Generative Adversarial Networks - arXiv (SourceType.PDF; score=2; topics=algorithms, content_pipeline, match3_core)
- [ae4be4b8-fccd-46ef-a46a-64b743ceb0f6] Orchestration plugin for game-ci (AWS, Kubernetes, Docker, and more) allowing "distributed workloads" (e.g build, test) and advanced workflows for large projects - GitHub (SourceType.WEB_PAGE; score=2; topics=ci_cd, goals_progression, tooling, ux_ui)
- [13a98938-bc9f-40a4-88ce-6c2fa14473c3] In-game transactions in Free-to-play games: Player motivation to purchase in-game content - Diva-Portal.org (SourceType.PDF; score=2; topics=content_pipeline, monetization)
- [569d1452-197e-41be-9b9e-21c390872380] From Zero to Hero: Visualizing Player Progression within UI/UX - GDC Vault (SourceType.PDF; score=2; topics=goals_progression, ux_ui)
- [1a21048a-fed9-48cc-9ab4-d4b69881ce5f] Dominikkasprzyk/UnityProjectBase: A comprehensive Unity starter template featuring essential packages, asset organization rules, and coding standards - perfect for new projects and prototypes. - GitHub (SourceType.WEB_PAGE; score=2; topics=content_pipeline, tooling)

Noise/defer for this project scope:
- [d2979807-d898-406d-a9a5-4ae6f367de5f] Access Microsoft Game Development Kit (GDK) development ... (platform mismatch for mobile-first match-3 scope)
- [68005e1b-c263-473e-b566-27e83bc01eab] Building the Sentry Unreal Engine SDK with GitHub Actions (platform mismatch for mobile-first match-3 scope)
- [42f0a099-a512-48cf-b17a-d9b9e36191b9] C SDK - Epic Online Services - Epic Games (platform mismatch for mobile-first match-3 scope)
- [940411c8-af8a-429e-a4d5-ec8d2b0eee28] DEVBOX10/microsoft-GDK: Microsoft Public GDK - GitHub (platform mismatch for mobile-first match-3 scope)
- [ef60512c-0d08-4d6b-b557-ba829710be74] EOS SDK and Game Engines Introduction | Epic Online Services Developer (platform mismatch for mobile-first match-3 scope)

## Phase E — Balance and Playtest

Usefulness counts: high=0, medium=1, low=80

Top medium-value sources (fallback):
- [03b9112d-7407-46a1-b78f-428d7aa986e2] Automated Playtesting of Matching Tile Games - arXiv (SourceType.PDF; score=3; topics=match3_core, playtesting_ai)

Noise/defer for this project scope:
- [d2979807-d898-406d-a9a5-4ae6f367de5f] Access Microsoft Game Development Kit (GDK) development ... (platform mismatch for mobile-first match-3 scope)
- [68005e1b-c263-473e-b566-27e83bc01eab] Building the Sentry Unreal Engine SDK with GitHub Actions (platform mismatch for mobile-first match-3 scope)
- [42f0a099-a512-48cf-b17a-d9b9e36191b9] C SDK - Epic Online Services - Epic Games (platform mismatch for mobile-first match-3 scope)
- [940411c8-af8a-429e-a4d5-ec8d2b0eee28] DEVBOX10/microsoft-GDK: Microsoft Public GDK - GitHub (platform mismatch for mobile-first match-3 scope)
- [ef60512c-0d08-4d6b-b557-ba829710be74] EOS SDK and Game Engines Introduction | Epic Online Services Developer (platform mismatch for mobile-first match-3 scope)

## Phase F — Soft Launch Prep

Usefulness counts: high=0, medium=6, low=75

Top medium-value sources (fallback):
- [bbfb76b8-f87f-4ed7-a5c6-d3a0fe6b4a1f] The Impact of Motion Design on User Experience in Mobile Apps - MoldStud (SourceType.WEB_PAGE; score=3; topics=animation_vfx, mobile_platform, retention, ux_ui)
- [0c118f46-3455-4b76-acda-feb7f6617823] Section 3. Psychology (SourceType.PDF; score=3; topics=ethics_risk)
- [d9a3ab01-7ff6-481e-bb0f-28120d4a2f7b] Perceived Values and Dark Patterns: Investigating Their Influence on Player Continuance Intention to Play Genshin Impact among Indonesian Gamer - Success Culture Press (SourceType.PDF; score=3; topics=architecture, ethics_risk)
- [c84bd8bc-e661-4eef-9a39-6894788adbeb] Психология «Доната»: контур проблемного исследования Текст научной статьи по специальности «Психологические науки» - КиберЛенинка (SourceType.WEB_PAGE; score=2; topics=monetization)
- [13a98938-bc9f-40a4-88ce-6c2fa14473c3] In-game transactions in Free-to-play games: Player motivation to purchase in-game content - Diva-Portal.org (SourceType.PDF; score=2; topics=content_pipeline, monetization)
- [bb43a60a-4b88-4c51-87dc-479046d564e7] #starterkit - Godot Asset Store (SourceType.WEB_PAGE; score=2; topics=architecture, content_pipeline, monetization, tooling)

Noise/defer for this project scope:
- [d2979807-d898-406d-a9a5-4ae6f367de5f] Access Microsoft Game Development Kit (GDK) development ... (platform mismatch for mobile-first match-3 scope)
- [68005e1b-c263-473e-b566-27e83bc01eab] Building the Sentry Unreal Engine SDK with GitHub Actions (platform mismatch for mobile-first match-3 scope)
- [42f0a099-a512-48cf-b17a-d9b9e36191b9] C SDK - Epic Online Services - Epic Games (platform mismatch for mobile-first match-3 scope)
- [940411c8-af8a-429e-a4d5-ec8d2b0eee28] DEVBOX10/microsoft-GDK: Microsoft Public GDK - GitHub (platform mismatch for mobile-first match-3 scope)
- [ef60512c-0d08-4d6b-b557-ba829710be74] EOS SDK and Game Engines Introduction | Epic Online Services Developer (platform mismatch for mobile-first match-3 scope)

## Implementation Policy

- For each feature decision, cite at least one source ID from relevant phase block above.
- Use `noise/defer` list to avoid spending implementation time on non-mobile/non-MVP vectors.
- Rebuild this file after every research refresh.
