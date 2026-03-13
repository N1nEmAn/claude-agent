#!/bin/bash
# Claude Code TUI pane 监控器
# 用法: ./pane_monitor.sh <tmux-session-name>
# 后台运行，检测权限提示和任务完成，发送通知
#
# 配置：通过环境变量或修改下方默认值
#   CLAUDE_AGENT_CHAT_ID   — Chat ID (Telegram/Discord/WhatsApp etc.)
#   CLAUDE_AGENT_NAME      — OpenClaw agent 名称（默认 main）
#   CLAUDE_AGENT_CHANNEL   — 通知通道（默认 telegram）

set -uo pipefail

SESSION="${1:?Usage: $0 <tmux-session-name>}"
# 兼容 CLAUDE_AGENT_* 和 CODEX_AGENT_*（方便从 codex-agent 迁移）
CHAT_ID="${CLAUDE_AGENT_CHAT_ID:-${CODEX_AGENT_CHAT_ID:-YOUR_CHAT_ID}}"
AGENT_NAME="${CLAUDE_AGENT_NAME:-${CODEX_AGENT_NAME:-main}}"
CHANNEL="${CLAUDE_AGENT_CHANNEL:-${CODEX_AGENT_CHANNEL:-telegram}}"
ACCOUNT="${CLAUDE_AGENT_ACCOUNT:-${CODEX_AGENT_ACCOUNT:-}}"
CHECK_INTERVAL=5  # 秒
LAST_STATE=""
NOTIFIED_APPROVAL=""
CAPTURE_LINES=30  # 抓取行数（增大以减少漏报）

LOG_FILE="/tmp/claude_monitor_${SESSION}.log"

log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"; }

# 清理函数：退出时删除 PID 文件
cleanup() {
    local pid_file="/tmp/claude_monitor_${SESSION}.pid"
    rm -f "$pid_file"
    log "Monitor exiting, cleaned up PID file"
}
trap cleanup EXIT

log "Monitor started for session: $SESSION"

while true; do
    # 检查 session 是否存在
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        log "Session $SESSION gone, exiting"
        exit 0
    fi

    OUTPUT=$(tmux capture-pane -t "$SESSION" -p -S -"$CAPTURE_LINES" 2>/dev/null)

    # 检测 Claude Code 权限提示（工具审批）
    if echo "$OUTPUT" | grep -qE "Allow|allow this|approve|permission|Do you want to proceed|Allow once|Allow always"; then
        # 提取待审批的工具调用
        TOOL=$(echo "$OUTPUT" | grep -oE "Allow (Bash|Read|Write|Edit|Glob|Grep|WebFetch|WebSearch|Agent|NotebookEdit)" | tail -1 | sed 's/Allow //')
        CMD=$(echo "$OUTPUT" | grep -A2 "Allow" | grep -v "Allow" | head -1 | sed 's/^[[:space:]]*//')
        STATE="approval:${TOOL:-unknown}:${CMD:-unknown}"

        if [ "$STATE" != "$NOTIFIED_APPROVAL" ]; then
            NOTIFIED_APPROVAL="$STATE"
            MSG="⏸️ Claude Code 等待审批
📋 工具: ${TOOL:-unknown}
📝 命令: ${CMD:-unknown}
🔧 session: $SESSION"
            # 构建 account 参数
            ACCOUNT_ARG=""
            if [ -n "$ACCOUNT" ]; then
                ACCOUNT_ARG="--account $ACCOUNT"
            fi
            # 1. 通知用户
            if ! openclaw message send --channel "$CHANNEL" $ACCOUNT_ARG --target "$CHAT_ID" --message "$MSG" --silent 2>>"$LOG_FILE"; then
                log "⚠️ Notify failed for approval"
            fi
            # 2. 唤醒 agent（后台执行，不阻塞 monitor 循环）
            AGENT_MSG="[Claude Monitor] 审批等待，请处理。
session: $SESSION
tool: ${TOOL:-unknown}
command: ${CMD:-unknown}
请在 tmux 中输入 y + Enter 批准，或 n + Enter 拒绝。"
            openclaw agent --agent "$AGENT_NAME" --message "$AGENT_MSG" --deliver --channel "$CHANNEL" $ACCOUNT_ARG --timeout 120 2>>"$LOG_FILE" &
            WAKE_PID=$!
            log "Agent wake fired (pid $WAKE_PID)"
            log "Approval detected: ${TOOL:-unknown} - ${CMD:-unknown}"
        fi

    # 检测回到空闲（等待用户输入，> 提示符出现）
    elif echo "$OUTPUT" | grep -qE "^>" | grep -v "grep"; then
        if [ "$LAST_STATE" = "working" ]; then
            LAST_STATE="idle"
            NOTIFIED_APPROVAL=""
            # Stop hook 已经处理 turn complete，这里不重复通知
            log "Back to idle"
        fi

    # 检测正在工作
    elif echo "$OUTPUT" | grep -qE "Thinking|Creating|Editing|Running|Reading|Searching|Writing"; then
        LAST_STATE="working"
    fi

    sleep "$CHECK_INTERVAL"
done
