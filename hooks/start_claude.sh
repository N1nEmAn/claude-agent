#!/bin/bash
# Claude Code 一键启动器
# 用法: ./start_claude.sh <session-name> <workdir> [--auto]
#
# 自动完成：
# 1. 创建 tmux session
# 2. 启动 Claude Code
# 3. 启动 pane monitor
# 4. session 结束时自动清理 monitor

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="${1:?Usage: $0 <session-name> <workdir> [--auto]}"
WORKDIR="${2:?Usage: $0 <session-name> <workdir> [--auto]}"
AUTO_MODE="${3:-}"

# 检查 tmux
if ! command -v tmux &>/dev/null; then
    echo "❌ tmux not found"
    exit 1
fi

# 检查 claude
if ! command -v claude &>/dev/null; then
    echo "❌ claude not found (Claude Code CLI)"
    exit 1
fi

# 检查 workdir
if [ ! -d "$WORKDIR" ]; then
    echo "❌ Directory not found: $WORKDIR"
    exit 1
fi

# 杀掉同名旧 session
tmux kill-session -t "$SESSION" 2>/dev/null || true
pkill -f "pane_monitor.sh $SESSION" 2>/dev/null || true

# 构建 claude 命令（unset CLAUDECODE 防止嵌套检测）
CLAUDE_CMD="unset CLAUDECODE; claude"
if [ "$AUTO_MODE" = "--auto" ]; then
    CLAUDE_CMD="unset CLAUDECODE; claude --dangerously-skip-permissions"
fi

# 1. 创建 tmux session + 启动 Claude Code
if ! tmux new-session -d -s "$SESSION" -c "$WORKDIR"; then
    echo "❌ Failed to create tmux session: $SESSION"
    exit 1
fi

if ! tmux send-keys -t "$SESSION" "$CLAUDE_CMD" Enter; then
    echo "❌ Failed to send command to tmux session: $SESSION"
    tmux kill-session -t "$SESSION" 2>/dev/null || true
    exit 1
fi

# 等待 Claude Code 启动
sleep 2
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "❌ tmux session died immediately, Claude Code may have failed to start"
    exit 1
fi

# 2. 启动 pane monitor（所有模式都启动）
MONITOR_PID_FILE="/tmp/claude_monitor_${SESSION}.pid"
nohup bash "$SKILL_DIR/hooks/pane_monitor.sh" "$SESSION" > /dev/null 2>&1 &
echo $! > "$MONITOR_PID_FILE"

echo "✅ Claude Code started"
echo "   session:  $SESSION"
echo "   workdir:  $WORKDIR"
echo "   mode:     ${AUTO_MODE:-default-approval}"
echo "   monitor:  PID $(cat "$MONITOR_PID_FILE")"
echo ""
echo "📎 tmux attach -t $SESSION    # 直接查看"
echo "🔪 ./stop_claude.sh $SESSION  # 一键清理"
