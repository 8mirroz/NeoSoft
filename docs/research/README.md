# Research Workspace

This directory stores research artifacts used for planning and balancing decisions.

- `_generated/latest-summary.txt`: last NotebookLM summary snapshot.
- `_generated/latest-sources.txt`: last NotebookLM source list snapshot.
- `_generated/latest-sources.json`: structured source inventory (id/title/type/url).
- `_generated/stage-source-matrix.json`: phase A-F usefulness matrix with high/medium/low relevance scoring.
- `stage-source-map.md`: human-readable phase map with top sources and scope noise filters.
- `res://data/balance/research_backlog.json`: execution backlog derived from the current research snapshot.

Regenerate with:

```bash
./scripts/research_preflight.sh
```

Optional direct rebuild (without re-fetching from NotebookLM):

```bash
./scripts/research_structurize.py
```
