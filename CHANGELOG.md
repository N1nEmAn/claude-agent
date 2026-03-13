# Changelog

## [2.0.0] - 2026-03-13

### Changed (Breaking)
- **CLI Migration**: From OpenAI Codex CLI to Anthropic Claude Code CLI
- **Config Format**: From `~/.codex/config.toml` (TOML) to `~/.claude/settings.json` (JSON)
- **Hook Mechanism**: From Codex notify hook (argv JSON) to Claude Code Stop hook (stdin JSON)
- **Models**: From GPT series to Claude series (opus / sonnet / haiku)
- **Permissions**: From sandbox + approval policy to permissions.allow/deny
- **Non-interactive Mode**: From `codex exec` to `claude -p`
- **Auto-approve**: From `--full-auto` to `--dangerously-skip-permissions`

### Added
- `hooks/start_claude.sh` — One-click launcher for Claude Code
- `hooks/stop_claude.sh` — One-click cleanup for Claude Code
- `references/claude-code-reference.md` — Claude Code CLI reference

### Removed
- `hooks/start_codex.sh` — Replaced by start_claude.sh
- `hooks/stop_codex.sh` — Replaced by stop_claude.sh
- `references/codex-cli-reference.md` — Replaced by claude-code-reference.md

### Rewritten
- `SKILL.md` — Complete rewrite for Claude Code workflow
- `hooks/on_complete.py` — Adapted for stdin JSON input
- `hooks/pane_monitor.sh` — Adapted for Claude Code permission prompts
- `knowledge/*` — All 6 files rewritten for Claude Code
- `workflows/*` — Adapted for Claude Code
- `README.md`, `README_EN.md`, `INSTALL.md` — Complete rewrite

## [0.2.0] - 2026-02-26

### Fixed
- `start_codex.sh`: Added `set -euo pipefail` and return code checks
- `pane_monitor.sh`: Fixed syntax error causing wake failure detection issue
- `on_complete.py`: Changed to DEVNULL for fire-and-forget agent wake

### Added
- `INSTALL.md`: Complete 7-step installation guide
- `README_EN.md`: Full English README
- Environment variable support: `CODEX_AGENT_CHAT_ID` and `CODEX_AGENT_NAME`

## [0.1.0] - 2026-02-25

### Added
- Initial release as codex-agent
- SKILL.md: 8-step workflow engine for OpenClaw to operate Codex CLI
- Dual-channel notification: notify hook + tmux pane monitor
- One-click start/stop scripts
- Knowledge base: 6 files
- Two approval modes: auto and OpenClaw-managed
