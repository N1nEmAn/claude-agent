# Claude Agent — Let OpenClaw Operate Claude Code for You

**English** | [中文](README.md)

> Lie in bed, say one sentence, and OpenClaw launches Claude Code, writes prompts, handles approvals, checks quality, and reports results. You can jump in anytime via terminal.

**This is an [OpenClaw](https://github.com/openclaw/openclaw) Skill.** It requires OpenClaw as the AI agent runtime, leveraging OpenClaw's agent wake, message delivery, and cron capabilities to drive the entire workflow.

## What Is It?

In one sentence: **OpenClaw operates Claude Code CLI on your behalf.**

Claude Code is Anthropic's terminal programming tool — powerful but requires you to sit at your computer, write prompts, watch output, approve tool calls, and check results. This skill lets OpenClaw do all that for you.

It's built on two things: **tmux + hooks**.

- **tmux**: Claude Code runs in a tmux session. OpenClaw reads output and sends commands through tmux — exactly like a human at the terminal
- **hooks**: When Claude Code finishes a task or waits for approval, it automatically notifies the user (Telegram) and wakes OpenClaw to handle it

You can `tmux attach` anytime to see what Claude Code is doing, or even take over.

## How It Works

```
1. User sends task (Telegram / terminal / any channel)
     ↓
2. OpenClaw understands requirements, asks clarifying questions
     ↓
3. OpenClaw designs prompt, selects execution mode, confirms with user
     ↓
4. OpenClaw launches Claude Code in tmux
     ↓
5. Claude Code works, OpenClaw is woken by hooks:
   ├── Task complete → OpenClaw checks output quality
   │   ├── Satisfied → Telegram notify user with results
   │   └── Not satisfied → Tell Claude Code to continue
   ├── Waiting for approval → OpenClaw decides approve/reject
   └── Direction issue → Immediately check with user
     ↓
6. User receives final result
   (Can tmux attach at any point)
```

## Two Approval Modes

| Mode | Who Approves | Use Case |
|------|-------------|----------|
| **Auto** (`--dangerously-skip-permissions`) | Claude Code decides | Routine dev, trusted projects |
| **OpenClaw Approval** (default) | OpenClaw decides | Sensitive operations |

## File Structure

```
claude-agent/
├── SKILL.md                    # OpenClaw workflow instructions
├── hooks/
│   ├── on_complete.py          # Stop hook → Telegram + agent wake
│   ├── pane_monitor.sh         # Approval detection → Telegram + agent wake
│   ├── start_claude.sh         # One-click start
│   └── stop_claude.sh          # One-click cleanup
├── knowledge/                  # Claude Code knowledge base (6 files)
├── workflows/                  # Task and update workflows
├── references/                 # CLI reference
└── state/                      # Version and update tracking
```

## Quick Start

See **[INSTALL.md](INSTALL.md)** for detailed setup steps.

After setup, just tell OpenClaw in Telegram:

> "Use Claude Code to implement XX feature in /path/to/project"

## Prerequisites

- [OpenClaw](https://github.com/openclaw/openclaw) installed and running
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (`claude --version`)
- tmux installed
- Telegram configured as OpenClaw message channel

## Acknowledgments

This project is based on [codex-agent](https://github.com/dztabel-happy/codex-agent), originally created by [@dztabel-happy](https://github.com/dztabel-happy). codex-agent implemented the complete workflow for operating OpenAI Codex CLI via OpenClaw — including the tmux + hook dual-channel notification architecture, knowledge base maintenance system, and project-manager-style multi-step task execution.

claude-agent inherits the core architectural design of codex-agent, migrating the target CLI from OpenAI Codex to Anthropic Claude Code, adapting to Claude Code's hooks system, permission model, and settings.json configuration format.

Thanks to the original author for the excellent work.
