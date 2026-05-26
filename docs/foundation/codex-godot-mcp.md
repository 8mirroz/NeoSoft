# Codex + Godot MCP Setup

This project uses Godot MCP so Codex can launch the editor, run the project, and read runtime/debug output through MCP tools.

## Prerequisites

- Godot installed locally (tested with `4.5.1`)
- Node.js `>= 18`
- Codex installed locally (with `~/.codex/config.toml`)

## One-command setup

From project root:

```bash
./scripts/setup_codex_godot_mcp.sh setup
```

What it does:

- Installs `@coding-solo/godot-mcp` globally
- Adds `mcp_servers.godot` to Codex config (`~/.codex/config.toml`) if missing
- Sets `GODOT_PATH` automatically (defaults to `/Applications/Godot.app/Contents/MacOS/Godot` on macOS)
- Validates binary + config presence

## Validation only

```bash
./scripts/setup_codex_godot_mcp.sh check
```

## Config block used by Codex

```toml
[mcp_servers.godot]
command = "npx"
args = ["-y", "@coding-solo/godot-mcp"]

[mcp_servers.godot.env]
GODOT_PATH = "/Applications/Godot.app/Contents/MacOS/Godot"
DEBUG = "false"
```

## Notes

- Restart Codex after setup so the MCP server list is reloaded.
- If Godot is installed in a non-standard path, export `GODOT_PATH` before running setup:

```bash
GODOT_PATH=/custom/path/to/Godot ./scripts/setup_codex_godot_mcp.sh setup
```
