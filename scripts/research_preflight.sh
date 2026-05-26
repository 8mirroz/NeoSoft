#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAFE_NOTEBOOKLM="$ROOT_DIR/scripts/notebooklm_safe.sh"
NOTEBOOK_ID="${1:-b6565e2f-488c-4fa4-b67d-cd066594e6b6}"
OUT_DIR="$ROOT_DIR/docs/research/_generated"

if [[ ! -x "$SAFE_NOTEBOOKLM" ]]; then
  echo "error: missing executable wrapper: $SAFE_NOTEBOOKLM" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

SUMMARY_OUT="$OUT_DIR/latest-summary.txt"
SOURCES_OUT="$OUT_DIR/latest-sources.txt"
SOURCES_JSON_OUT="$OUT_DIR/latest-sources.json"
USE_OUT="$(mktemp)"
trap 'rm -f "$USE_OUT"' EXIT

echo "[1/6] notebooklm doctor"
"$SAFE_NOTEBOOKLM" doctor

echo "[2/6] notebooklm use $NOTEBOOK_ID"
"$SAFE_NOTEBOOKLM" use "$NOTEBOOK_ID" --json > "$USE_OUT"
cat "$USE_OUT"

echo "[3/6] notebooklm summary -> $SUMMARY_OUT"
"$SAFE_NOTEBOOKLM" summary > "$SUMMARY_OUT"

echo "[4/6] notebooklm source list -> $SOURCES_OUT"
"$SAFE_NOTEBOOKLM" source list > "$SOURCES_OUT"

echo "[5/6] notebooklm source list --json -> $SOURCES_JSON_OUT"
"$SAFE_NOTEBOOKLM" source list --json > "$SOURCES_JSON_OUT"

echo "[6/6] build stage/source map + research backlog"
"$ROOT_DIR/scripts/research_structurize.py"

echo
echo "Research preflight completed."
echo "Generated files:"
echo "- $SUMMARY_OUT"
echo "- $SOURCES_OUT"
echo "- $SOURCES_JSON_OUT"
echo "- $OUT_DIR/stage-source-matrix.json"
echo "- $ROOT_DIR/docs/research/stage-source-map.md"
echo "- $ROOT_DIR/data/balance/research_backlog.json"
