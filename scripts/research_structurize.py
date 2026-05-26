#!/usr/bin/env python3
"""Build stage-aligned research artifacts from NotebookLM source exports.

Inputs:
- docs/research/_generated/latest-sources.json
- docs/research/_generated/latest-summary.txt (optional)

Outputs:
- docs/research/_generated/stage-source-matrix.json
- docs/research/stage-source-map.md
- data/balance/research_backlog.json
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Set, Tuple

ROOT = Path(__file__).resolve().parent.parent
SOURCES_PATH = ROOT / "docs/research/_generated/latest-sources.json"
SUMMARY_PATH = ROOT / "docs/research/_generated/latest-summary.txt"
MATRIX_JSON_PATH = ROOT / "docs/research/_generated/stage-source-matrix.json"
MAP_MD_PATH = ROOT / "docs/research/stage-source-map.md"
BACKLOG_JSON_PATH = ROOT / "data/balance/research_backlog.json"

STAGE_ORDER = ["A", "B", "C", "D", "E", "F"]
STAGE_NAMES = {
    "A": "Pre-production",
    "B": "Prototype Core Loop",
    "C": "Visual Integration",
    "D": "MVP Production",
    "E": "Balance and Playtest",
    "F": "Soft Launch Prep",
}

STAGE_TOPIC_WEIGHTS: Dict[str, Dict[str, int]] = {
    "A": {"architecture": 3, "ci_cd": 3, "tooling": 2, "mobile_platform": 1},
    "B": {"match3_core": 3, "algorithms": 2, "core_gameplay": 3},
    "C": {"ux_ui": 3, "animation_vfx": 3, "onboarding": 2},
    "D": {"level_design": 3, "goals_progression": 2, "content_pipeline": 2, "core_gameplay": 1},
    "E": {"balance_analytics": 3, "playtesting_ai": 3, "math_model": 2},
    "F": {"retention": 3, "monetization": 2, "ethics_risk": 3, "telemetry": 2},
}

TOPIC_KEYWORDS: Dict[str, Set[str]] = {
    "architecture": {
        "architecture", "framework", "pattern", "blueprint", "entity", "state machine", "fsm", "starterkit",
    },
    "ci_cd": {
        "ci/cd", "github actions", "gameci", "godot-ci", "build", "pipeline", "automation", "docker",
    },
    "tooling": {"godot", "unity", "template", "sdk", "repository", "plugin"},
    "mobile_platform": {"mobile", "android", "ios", "touch", "app"},
    "match3_core": {"match-3", "match 3", "matching tile", "3 в ряд", "puzzle"},
    "algorithms": {"algorithm", "pathfinding", "np-complete", "procedural", "generator", "mcts", "monte carlo"},
    "core_gameplay": {"gameplay", "gravity", "combo", "cascade", "booster", "mechanic"},
    "ux_ui": {"ux", "ui", "interface", "readability", "usability", "progression", "visual"},
    "animation_vfx": {"animation", "motion", "effect", "vfx", "particle", "shader"},
    "onboarding": {"onboarding", "tutorial", "first session", "new player"},
    "level_design": {"level", "quest", "goal", "moves", "difficulty", "campaign"},
    "goals_progression": {"progress", "trophy", "road", "reward", "stars", "win", "lose"},
    "content_pipeline": {"asset", "content", "pipeline", "import", "export", "pack"},
    "balance_analytics": {"balance", "analytics", "telemetry", "loss rate", "retention", "attempt"},
    "playtesting_ai": {"playtesting", "mcts", "monte carlo", "bot", "agent", "simulation"},
    "math_model": {"math", "mathematical", "model", "probability", "distribution"},
    "retention": {"retention", "engagement", "hook", "session", "d1", "d7", "funnel"},
    "monetization": {"monetization", "purchase", "iap", "f2p", "season pass", "store", "donat", "донат"},
    "ethics_risk": {"dark pattern", "lootbox", "gacha", "manipulative", "addiction", "microloan", "psychology"},
    "telemetry": {"analytics", "metric", "kpi", "cohort", "ab test"},
}

LOW_VALUE_KEYWORDS = {
    "steamworks", "unreal", "nintendo switch", "gdk", "epic online services", "eos sdk", "pc samples",
}

HIGH_CONFIDENCE_TYPES = {
    "SourceType.PDF", "SourceType.MARKDOWN", "SourceType.WEB_PAGE", "SourceType.YOUTUBE_VIDEO",
}


@dataclass
class Source:
    index: int
    source_id: str
    title: str
    source_type: str
    url: str


def normalize(text: str | None) -> str:
    if text is None:
        return ""
    return re.sub(r"\s+", " ", text.lower()).strip()


def detect_topics(title: str, url: str) -> Set[str]:
    hay = f"{normalize(title)} {normalize(url)}"
    topics: Set[str] = set()
    for topic, keywords in TOPIC_KEYWORDS.items():
        if any(kw in hay for kw in keywords):
            topics.add(topic)
    return topics


def is_low_value(title: str, url: str) -> bool:
    hay = f"{normalize(title)} {normalize(url)}"
    return any(token in hay for token in LOW_VALUE_KEYWORDS)


def relevance_score(stage: str, topics: Set[str], low_value: bool) -> int:
    weights = STAGE_TOPIC_WEIGHTS[stage]
    score = sum(weights.get(topic, 0) for topic in topics)
    if low_value:
        score -= 3
    return score


def usefulness_label(score: int) -> str:
    if score >= 5:
        return "high"
    if score >= 2:
        return "medium"
    return "low"


def load_sources() -> Tuple[Dict[str, object], List[Source]]:
    payload = json.loads(SOURCES_PATH.read_text(encoding="utf-8"))
    raw_sources = payload.get("sources", [])
    sources: List[Source] = []
    for item in raw_sources:
        source_type = item.get("type", "")
        if source_type not in HIGH_CONFIDENCE_TYPES:
            continue
        sources.append(
            Source(
                index=item.get("index", 0),
                source_id=item.get("id", ""),
                title=item.get("title", ""),
                source_type=source_type,
                url=item.get("url", ""),
            )
        )
    return payload, sources


def build_matrix(sources: List[Source]) -> Dict[str, object]:
    stage_matrix: Dict[str, Dict[str, object]] = {}

    for stage in STAGE_ORDER:
        ranked = []
        dropped = []
        for source in sources:
            topics = detect_topics(source.title, source.url)
            low_value = is_low_value(source.title, source.url)
            score = relevance_score(stage, topics, low_value)
            if low_value:
                dropped.append(
                    {
                        "id": source.source_id,
                        "title": source.title,
                        "reason": "platform mismatch for mobile-first match-3 scope",
                    }
                )
            ranked.append(
                {
                    "id": source.source_id,
                    "index": source.index,
                    "title": source.title,
                    "type": source.source_type,
                    "url": source.url,
                    "topics": sorted(topics),
                    "score": score,
                    "usefulness": usefulness_label(score),
                }
            )

        ranked.sort(key=lambda x: (x["score"], x["index"]), reverse=True)

        top_high = [r for r in ranked if r["usefulness"] == "high"][:12]
        top_medium = [r for r in ranked if r["usefulness"] == "medium"][:10]

        stage_matrix[stage] = {
            "stage_name": STAGE_NAMES[stage],
            "high_value_count": len([r for r in ranked if r["usefulness"] == "high"]),
            "medium_value_count": len([r for r in ranked if r["usefulness"] == "medium"]),
            "low_value_count": len([r for r in ranked if r["usefulness"] == "low"]),
            "top_high_value_sources": top_high,
            "top_medium_value_sources": top_medium,
            "noise_or_defer_sources": dropped[:12],
        }

    return {
        "method": "keyword-based stage relevance scoring with mobile-scope penalties",
        "stages": stage_matrix,
    }


def build_backlog(matrix: Dict[str, object]) -> Dict[str, object]:
    stage_to_modules = {
        "A": ["core_match3", "build_pipeline", "data_layer"],
        "B": ["core_match3", "level_runtime"],
        "C": ["presentation_layer"],
        "D": ["data_layer", "level_runtime", "presentation_layer"],
        "E": ["data_layer", "core_match3", "level_runtime"],
        "F": ["meta_layer", "data_layer", "presentation_layer"],
    }

    tasks = []
    for stage in STAGE_ORDER:
        stage_data = matrix["stages"][stage]
        top_sources = stage_data["top_high_value_sources"][:4]
        if not top_sources:
            top_sources = stage_data["top_medium_value_sources"][:4]
        tasks.append(
            {
                "stage_id": stage,
                "stage_name": stage_data["stage_name"],
                "owner_modules": stage_to_modules[stage],
                "task": f"Convert top research inputs into implementation checklist for phase {stage}",
                "acceptance": [
                    "Mapped decisions added to docs/foundation/decision-log.md",
                    "Module-level TODO items created in corresponding script folder",
                    "Validation checks linked to phase gate",
                ],
                "evidence_sources": [
                    {"id": s["id"], "title": s["title"]} for s in top_sources
                ],
            }
        )

    ethics_constraints = [
        "Do not implement hidden monetization pressure loops or fake discount anchors.",
        "If random rewards are used, expose probabilities and avoid paywall-only progression.",
        "Prioritize retention through fair progression and readable UX, not coercive timers.",
    ]

    return {
        "project": "3line",
        "generated_from": "docs/research/_generated/latest-sources.json",
        "tasks": tasks,
        "ethics_constraints": ethics_constraints,
    }


def write_markdown(matrix: Dict[str, object], summary_text: str) -> None:
    lines: List[str] = []
    lines.append("# Stage Source Map (NotebookLM Deushare)")
    lines.append("")
    lines.append("This file converts NotebookLM source inventory into phase-aligned implementation evidence for 3line.")
    lines.append("")
    lines.append("## Method")
    lines.append("")
    lines.append("- Input: `docs/research/_generated/latest-sources.json` (82 sources in this snapshot).")
    lines.append("- Scoring: keyword-based relevance per phase A-F with mobile-scope penalties.")
    lines.append("- Use this map for planning and decision-log citations before implementation.")
    lines.append("")
    lines.append("## Snapshot Summary")
    lines.append("")
    lines.append(summary_text.strip() or "No summary available.")
    lines.append("")

    for stage in STAGE_ORDER:
        stage_data = matrix["stages"][stage]
        lines.append(f"## Phase {stage} — {stage_data['stage_name']}")
        lines.append("")
        lines.append(
            f"Usefulness counts: high={stage_data['high_value_count']}, "
            f"medium={stage_data['medium_value_count']}, low={stage_data['low_value_count']}"
        )
        lines.append("")
        top_srcs = stage_data["top_high_value_sources"][:8]
        if not top_srcs:
            lines.append("Top medium-value sources (fallback):")
            for src in stage_data["top_medium_value_sources"][:8]:
                lines.append(
                    f"- [{src['id']}] {src['title']} ({src['type']}; score={src['score']}; topics={', '.join(src['topics']) or 'none'})"
                )
        else:
            lines.append("Top high-value sources:")
            for src in top_srcs:
                lines.append(
                    f"- [{src['id']}] {src['title']} ({src['type']}; score={src['score']}; topics={', '.join(src['topics']) or 'none'})"
                )
        lines.append("")
        lines.append("Noise/defer for this project scope:")
        for src in stage_data["noise_or_defer_sources"][:5]:
            lines.append(f"- [{src['id']}] {src['title']} ({src['reason']})")
        lines.append("")

    lines.append("## Implementation Policy")
    lines.append("")
    lines.append("- For each feature decision, cite at least one source ID from relevant phase block above.")
    lines.append("- Use `noise/defer` list to avoid spending implementation time on non-mobile/non-MVP vectors.")
    lines.append("- Rebuild this file after every research refresh.")
    lines.append("")

    MAP_MD_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    if not SOURCES_PATH.exists():
        raise SystemExit(f"missing input: {SOURCES_PATH}")

    _, sources = load_sources()
    summary_text = SUMMARY_PATH.read_text(encoding="utf-8") if SUMMARY_PATH.exists() else ""

    matrix = build_matrix(sources)
    backlog = build_backlog(matrix)

    MATRIX_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    MATRIX_JSON_PATH.write_text(json.dumps(matrix, ensure_ascii=False, indent=2), encoding="utf-8")

    BACKLOG_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    BACKLOG_JSON_PATH.write_text(json.dumps(backlog, ensure_ascii=False, indent=2), encoding="utf-8")

    write_markdown(matrix, summary_text)

    print(f"generated: {MATRIX_JSON_PATH}")
    print(f"generated: {MAP_MD_PATH}")
    print(f"generated: {BACKLOG_JSON_PATH}")


if __name__ == "__main__":
    main()
