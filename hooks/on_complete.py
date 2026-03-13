#!/usr/bin/env python3
"""
Claude Code Stop hook — Claude Code 完成 turn 时：
1. 给用户发通知（Telegram/Discord 等）
2. 唤醒 OpenClaw agent（去检查输出）

配置：~/.claude/settings.json 中添加：
  {
    "hooks": {
      "Stop": [{
        "matcher": "",
        "hooks": [{
          "type": "command",
          "command": "python3 /path/to/on_complete.py"
        }]
      }]
    }
  }

环境变量：
  CLAUDE_AGENT_CHAT_ID   — Chat ID (Telegram/Discord/WhatsApp etc.)
  CLAUDE_AGENT_NAME      — OpenClaw agent 名称（默认 main）
  CLAUDE_AGENT_CHANNEL   — 通知通道（默认 telegram）
"""

import json
import os
import subprocess
import sys
from datetime import datetime

LOG_FILE = "/tmp/claude_notify_log.txt"

# 从环境变量读取，兼容 CLAUDE_AGENT_* 和 CODEX_AGENT_*（方便从 codex-agent 迁移）
CHAT_ID = os.environ.get("CLAUDE_AGENT_CHAT_ID",
          os.environ.get("CODEX_AGENT_CHAT_ID", "YOUR_CHAT_ID"))
CHANNEL = os.environ.get("CLAUDE_AGENT_CHANNEL",
          os.environ.get("CODEX_AGENT_CHANNEL", "telegram"))
AGENT_NAME = os.environ.get("CLAUDE_AGENT_NAME",
             os.environ.get("CODEX_AGENT_NAME", "main"))
ACCOUNT = os.environ.get("CLAUDE_AGENT_ACCOUNT",
          os.environ.get("CODEX_AGENT_ACCOUNT", ""))


def log(msg: str):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}\n")
    except Exception:
        pass  # 日志写入失败不应影响主流程


def notify_user(msg: str) -> bool:
    """发送通知，返回是否成功"""
    try:
        cmd = [
            "openclaw", "message", "send",
            "--channel", CHANNEL,
            "--target", CHAT_ID,
            "--message", msg,
        ]
        if ACCOUNT:
            cmd.extend(["--account", ACCOUNT])
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            _, stderr = proc.communicate(timeout=10)
            if proc.returncode != 0:
                log(f"notify failed (exit {proc.returncode}): {stderr.decode()[:200]}")
                return False
        except subprocess.TimeoutExpired:
            log("notify timeout (10s), process still running")
        log("notify sent")
        return True
    except Exception as e:
        log(f"notify error: {e}")
        return False


def wake_agent(msg: str) -> bool:
    """唤醒 OpenClaw agent，返回是否成功启动进程"""
    try:
        cmd = [
            "openclaw", "agent",
            "--agent", AGENT_NAME,
            "--message", msg,
            "--deliver",
            "--channel", CHANNEL,
            "--timeout", "120",
        ]
        if ACCOUNT:
            cmd.extend(["--account", ACCOUNT])
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        log(f"agent wake fired (pid {proc.pid})")
        return True
    except Exception as e:
        log(f"agent wake error: {e}")
        return False


def extract_summary(notification: dict) -> str:
    """从 hook payload 中提取摘要信息"""
    # 记录完整 payload 用于调试（仅首次或调试时有用）
    log(f"Payload keys: {list(notification.keys())}")

    # 尝试多种可能的字段名
    for key in ("last_assistant_message", "last_message", "message", "summary",
                "transcript_summary", "result"):
        val = notification.get(key)
        if val and isinstance(val, str) and val not in ("end_turn", "unknown"):
            return str(val)[:1000]

    # 尝试从 transcript 数组中取最后一条
    transcript = notification.get("transcript", [])
    if isinstance(transcript, list) and transcript:
        last = transcript[-1]
        if isinstance(last, dict):
            for k in ("content", "text", "message"):
                if k in last:
                    return str(last[k])[:1000]
            return str(last)[:1000]
        return str(last)[:1000]

    return "Turn Complete!"


def main() -> int:
    # Claude Code hooks 通过 stdin 传入 JSON
    try:
        raw = sys.stdin.read()
    except Exception:
        raw = ""

    if not raw.strip():
        log("Empty stdin, skipping")
        return 0

    try:
        notification = json.loads(raw)
    except json.JSONDecodeError as e:
        log(f"JSON parse error: {e}")
        return 1

    session_id = notification.get("session_id", "unknown")
    hook_event = notification.get("hook_event_name", "Stop")
    cwd = notification.get("cwd", os.getcwd())
    summary = extract_summary(notification)

    log(f"Claude Code {hook_event}: session={session_id}, cwd={cwd}")
    log(f"Summary: {summary[:200]}")

    # ⚠️ 注意：summary 可能包含代码片段、路径、密钥等敏感信息
    # 发送到 Telegram 前用户应评估风险（私人仓库/私聊通常可接受）
    msg = (
        f"🔔 Claude Code 任务回复\n"
        f"📁 {cwd}\n"
        f"💬 {summary}"
    )

    # 1. 给用户发通知
    tg_ok = notify_user(msg)

    # 2. 唤醒 agent（fire-and-forget）
    agent_msg = (
        f"[Claude Hook] 任务完成，请检查输出并汇报。\n"
        f"cwd: {cwd}\n"
        f"session: {session_id}\n"
        f"summary: {summary}"
    )
    agent_ok = wake_agent(agent_msg)

    if not tg_ok and not agent_ok:
        log("⚠️ Both notify and agent wake failed!")

    return 0


if __name__ == "__main__":
    sys.exit(main())
