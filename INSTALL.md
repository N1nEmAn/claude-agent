# Claude Agent 安装与配置指南

> 完整的手把手配置流程。也可以把本文件内容发给 OpenClaw，让它自动帮你配置。

## 前提条件

- [OpenClaw](https://github.com/openclaw/openclaw) 已安装并运行（`openclaw gateway status`）
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 已安装（`claude --version`）
- tmux 已安装（`tmux -V`）
- 至少一个消息通道已配置（Telegram / Discord / QQ 等）

## 第一步：安装 Skill

将 claude-agent 克隆到 OpenClaw 的 workspace skills 目录：

```bash
# 查看你的 workspace 路径（openclaw.json 中 agents.defaults.workspace）
WORKSPACE=$(python3 -c "import json; print(json.load(open('$HOME/.openclaw/openclaw.json')).get('agents',{}).get('defaults',{}).get('workspace','$HOME/.openclaw/workspace'))")

# 克隆到 skills 目录
mkdir -p "$WORKSPACE/skills"
cd "$WORKSPACE/skills"
git clone https://github.com/N1nEmAn/claude-agent.git

# 设置脚本权限
chmod +x claude-agent/hooks/*.sh claude-agent/hooks/*.py
```

验证 skill 被识别：
```bash
openclaw gateway restart
openclaw skills 2>&1 | grep claude-agent
# 应显示 ✓ ready │ claude-agent
```

## 第二步：配置 Claude Code hooks 和环境变量

编辑 `~/.claude/settings.json`（如果文件不存在则创建），**合并**以下内容到现有配置中：

```json
{
  "env": {
    "CLAUDE_AGENT_CHAT_ID": "你的Chat_ID",
    "CLAUDE_AGENT_CHANNEL": "telegram",
    "CLAUDE_AGENT_ACCOUNT": "你的OpenClaw通道账号名",
    "CLAUDE_AGENT_NAME": "main"
  },
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 <SKILL_PATH>/hooks/on_complete.py"
          }
        ]
      }
    ]
  }
}
```

替换说明：
- `<SKILL_PATH>`：替换为实际安装路径，例如 `/home/用户名/clawd/skills/claude-agent`
- `CLAUDE_AGENT_CHAT_ID`：你的 Telegram Chat ID（给 bot 发消息后查看 OpenClaw 日志）
- `CLAUDE_AGENT_ACCOUNT`：OpenClaw 中配置的通道账号名（在 `~/.openclaw/openclaw.json` 的 `channels.telegram.accounts` 中查看）
- `CLAUDE_AGENT_NAME`：OpenClaw agent 名称，通常是 `main`

> **注意**：`env` 中的变量会被 Claude Code 注入到 hook 进程环境中，这是 hook 能正确发送通知的关键。也兼容 `CODEX_AGENT_*` 前缀（从 codex-agent 迁移时无需改名）。

## 第三步：配置 pane_monitor 环境变量（可选）

pane_monitor 在 tmux 中独立运行，不通过 Claude Code hooks 触发，所以需要单独配置环境变量：

```bash
# 在 ~/.zshrc 或 ~/.bashrc 中添加
export CLAUDE_AGENT_CHAT_ID="你的Chat_ID"
export CLAUDE_AGENT_CHANNEL="telegram"
export CLAUDE_AGENT_ACCOUNT="你的OpenClaw通道账号名"
export CLAUDE_AGENT_NAME="main"
```

然后 `source ~/.zshrc`。

> 如果你只用自动审批模式（`--auto`），pane_monitor 基本不会触发通知，可以跳过这步。

## 第四步：配置 OpenClaw session 重置（推荐）

OpenClaw 默认定期自动重置 session，长任务完成后 hook 唤醒 OpenClaw 时上下文可能已丢失。

编辑 `~/.openclaw/openclaw.json`，添加或修改：

```json
{
  "session": {
    "reset": {
      "mode": "idle",
      "idleMinutes": 52560000
    }
  }
}
```

然后重启 gateway：
```bash
openclaw gateway restart
```

## 第五步：验证安装

```bash
# 1. Claude Code 可用
claude --version

# 2. tmux 可用
tmux -V

# 3. Skill 已识别
openclaw skills 2>&1 | grep claude-agent

# 4. 通知可发送（替换参数）
openclaw message send --channel telegram --account 你的账号名 --target 你的Chat_ID --message "claude-agent 通知测试"

# 5. Claude Code hook 可触发
claude -p "say hello"
# 你应该收到通知
```

## 使用

安装完成后，在 Telegram 里对 OpenClaw 说：

> "用 Claude Code 帮我在 /path/to/project 实现 XX 功能"

OpenClaw 会自动匹配 `claude-agent` skill，然后：
1. 理解你的需求
2. 设计提示词
3. 在 tmux 里启动 Claude Code
4. 中间过程自动处理
5. 完成后通知你

你随时可以 `tmux attach -t <session>` 接入查看。

---

## 一键自动配置（发给 OpenClaw）

把下面这段话发给 OpenClaw，它会自动帮你完成配置：

```
请帮我安装和配置 claude-agent skill。
先读 INSTALL.md（路径：skills/claude-agent/INSTALL.md），然后按步骤完成配置。
```

## 故障排查

| 症状 | 检查 |
|------|------|
| `openclaw skills` 没有 claude-agent | 确认 SKILL.md 在 `$WORKSPACE/skills/claude-agent/` 目录下，重启 gateway |
| Claude Code 完成后没收到通知 | 检查 `~/.claude/settings.json` 的 hooks.Stop 和 env 配置 |
| 通知发送失败 | 检查 `CLAUDE_AGENT_ACCOUNT` 是否与 openclaw.json 中的账号名一致 |
| 收到通知但 OpenClaw 没反应 | 检查 `openclaw agent --agent main` 是否可用 |
| pane monitor 没检测到审批 | 查看 `/tmp/claude_monitor_<session>.log` |
| start_claude.sh 报错 | 检查 tmux 和 claude 是否安装，workdir 是否存在 |
| Claude Code 报嵌套错误 | start_claude.sh 已自动处理（unset CLAUDECODE） |
