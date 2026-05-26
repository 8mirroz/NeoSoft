#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-setup}"
CONFIG_FILE="${CODEX_CONFIG_FILE:-$HOME/.codex/config.toml}"
MCP_PACKAGE="@coding-solo/godot-mcp"

usage() {
  cat <<'USAGE'
Usage:
  setup_codex_godot_mcp.sh [setup|check]

Modes:
  setup  Install Godot MCP and register it in Codex config (default)
  check  Validate current setup without changing files
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
}

find_godot_bin() {
  if [[ -n "${GODOT_PATH:-}" && -x "${GODOT_PATH}" ]]; then
    echo "$GODOT_PATH"
    return 0
  fi

  local candidates=(
    "/Applications/Godot.app/Contents/MacOS/Godot"
    "$(command -v godot4 2>/dev/null || true)"
    "$(command -v godot 2>/dev/null || true)"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

ensure_config_exists() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "error: Codex config not found at $CONFIG_FILE" >&2
    echo "Install/open Codex first so it creates config.toml." >&2
    exit 1
  fi
}

install_package() {
  echo "[1/3] Installing $MCP_PACKAGE globally"
  npm install -g "$MCP_PACKAGE"
}

append_config_block() {
  local godot_bin="$1"

  if rg -q '^\[mcp_servers\.godot\]' "$CONFIG_FILE"; then
    echo "[2/3] Codex MCP server 'godot' already exists in $CONFIG_FILE"
    return 0
  fi

  local backup_file="$CONFIG_FILE.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$CONFIG_FILE" "$backup_file"
  echo "[2/3] Backed up Codex config to $backup_file"

  cat >> "$CONFIG_FILE" <<EOF_CFG

[mcp_servers.godot]
command = "npx"
args = ["-y", "@coding-solo/godot-mcp"]

[mcp_servers.godot.env]
GODOT_PATH = "$godot_bin"
DEBUG = "false"
EOF_CFG

  echo "[2/3] Added MCP server 'godot' to $CONFIG_FILE"
}

run_checks() {
  local godot_bin="$1"

  echo "[3/3] Validating setup"
  require_cmd node
  require_cmd npm

  if ! command -v godot-mcp >/dev/null 2>&1; then
    echo "error: godot-mcp binary not found in PATH" >&2
    exit 1
  fi

  if [[ ! -x "$godot_bin" ]]; then
    echo "error: Godot executable not found: $godot_bin" >&2
    exit 1
  fi

  if ! rg -q '^\[mcp_servers\.godot\]' "$CONFIG_FILE"; then
    echo "error: mcp_servers.godot block not found in $CONFIG_FILE" >&2
    exit 1
  fi

  echo "OK: godot-mcp binary: $(command -v godot-mcp)"
  echo "OK: godot executable: $godot_bin"
  echo "OK: config contains [mcp_servers.godot]"
}

main() {
  case "$MODE" in
    setup|check)
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown mode '$MODE'" >&2
      usage
      exit 1
      ;;
  esac

  require_cmd rg
  require_cmd node
  require_cmd npm

  local godot_bin
  godot_bin="$(find_godot_bin || true)"
  if [[ -z "$godot_bin" ]]; then
    echo "error: Godot executable not found. Set GODOT_PATH and retry." >&2
    exit 1
  fi

  ensure_config_exists

  if [[ "$MODE" == "setup" ]]; then
    install_package
    append_config_block "$godot_bin"
  fi

  run_checks "$godot_bin"

  echo
  echo "Setup complete. Restart Codex to load the new MCP server list."
}

main "$@"
