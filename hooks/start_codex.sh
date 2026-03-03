#!/bin/bash
# Codex 一键启动器
# 用法: ./start_codex.sh <session-name> <workdir> [agent-name] [--full-auto]
#
# 自动完成：
# 1. 创建 tmux session
# 2. 启动 Codex TUI
# 3. 启动 pane monitor
# 4. session 结束时自动清理 monitor

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="${1:?Usage: $0 <session-name> <workdir> [agent-name] [--full-auto]}"
WORKDIR="${2:?Usage: $0 <session-name> <workdir> [agent-name] [--full-auto]}"
THIRD_ARG="${3:-}"
FOURTH_ARG="${4:-}"
FULL_AUTO=""

# 路由参数：
# - agent 优先顺序：第三参数 > CODEX_AGENT_NAME > OPENCLAW_AGENT_ID > main
# - channel/chat_id 可由环境变量覆盖
if [ "$THIRD_ARG" = "--full-auto" ]; then
    FULL_AUTO="--full-auto"
    AGENT_NAME="${CODEX_AGENT_NAME:-${OPENCLAW_AGENT_ID:-main}}"
elif [ -n "$THIRD_ARG" ]; then
    AGENT_NAME="$THIRD_ARG"
else
    AGENT_NAME="${CODEX_AGENT_NAME:-${OPENCLAW_AGENT_ID:-main}}"
fi

if [ "$FOURTH_ARG" = "--full-auto" ]; then
    FULL_AUTO="--full-auto"
fi

CHANNEL="${CODEX_AGENT_CHANNEL:-telegram}"
CHAT_ID="${CODEX_AGENT_CHAT_ID:-${OPENCLAW_TELEGRAM_CHAT_ID:-YOUR_CHAT_ID}}"

# 检查 tmux
if ! command -v tmux &>/dev/null; then
    echo "❌ tmux not found"
    exit 1
fi

# 检查 codex
if ! command -v codex &>/dev/null; then
    echo "❌ codex not found"
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

# 构建 codex 命令
CODEX_CMD="codex --no-alt-screen"
if [ "$FULL_AUTO" = "--full-auto" ]; then
    CODEX_CMD="codex --no-alt-screen --full-auto"
fi

# 1. 创建 tmux session + 启动 Codex
if ! tmux new-session -d -s "$SESSION" -c "$WORKDIR"; then
    echo "❌ Failed to create tmux session: $SESSION"
    exit 1
fi

# 注入路由环境变量，确保 codex notify hook 能按调用方回调
tmux set-environment -t "$SESSION" CODEX_AGENT_NAME "$AGENT_NAME"
tmux set-environment -t "$SESSION" CODEX_AGENT_CHANNEL "$CHANNEL"
tmux set-environment -t "$SESSION" CODEX_AGENT_CHAT_ID "$CHAT_ID"

if ! tmux send-keys -t "$SESSION" "$CODEX_CMD" Enter; then
    echo "❌ Failed to send command to tmux session: $SESSION"
    tmux kill-session -t "$SESSION" 2>/dev/null || true
    exit 1
fi

# 等待 Codex 启动（检查进程是否存在）
sleep 2
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "❌ tmux session died immediately, Codex may have failed to start"
    exit 1
fi

# 2. 启动 pane monitor（所有模式都启动，full-auto 偶尔也会弹审批）
MONITOR_PID_FILE="/tmp/codex_monitor_${SESSION}.pid"
nohup env \
    CODEX_AGENT_NAME="$AGENT_NAME" \
    CODEX_AGENT_CHANNEL="$CHANNEL" \
    CODEX_AGENT_CHAT_ID="$CHAT_ID" \
    bash "$SKILL_DIR/hooks/pane_monitor.sh" "$SESSION" > /dev/null 2>&1 &
echo $! > "$MONITOR_PID_FILE"

echo "✅ Codex started"
echo "   session:  $SESSION"
echo "   workdir:  $WORKDIR"
echo "   mode:     ${FULL_AUTO:-default-approval}"
echo "   agent:    $AGENT_NAME"
echo "   channel:  $CHANNEL"
echo "   chat_id:  $CHAT_ID"
echo "   monitor:  PID $(cat "$MONITOR_PID_FILE")"
echo ""
echo "📎 tmux attach -t $SESSION    # 直接查看"
echo "🔪 ./stop_codex.sh $SESSION   # 一键清理"
