#!/usr/bin/env bash
set -euo pipefail

NOTEBOOKLM_BIN="${NOTEBOOKLM_BIN:-$HOME/.local/bin/notebooklm}"
NOTEBOOKLM_PROFILE="${NOTEBOOKLM_PROFILE:-default}"

if [[ ! -x "$NOTEBOOKLM_BIN" ]]; then
  echo "error: notebooklm binary not found or not executable: $NOTEBOOKLM_BIN" >&2
  exit 1
fi

env \
  -u HTTPS_PROXY \
  -u HTTP_PROXY \
  -u ALL_PROXY \
  -u https_proxy \
  -u http_proxy \
  -u all_proxy \
  "$NOTEBOOKLM_BIN" --profile "$NOTEBOOKLM_PROFILE" "$@"

