# Claude Agent 安装与配置指南

> 完整的手把手配置流程。也可以把本文件内容发给 OpenClaw，让它自动帮你配置。

## 前提条件

- [OpenClaw](https://github.com/openclaw/openclaw) 已安装并运行（`openclaw gateway status` 显示 running）
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 已安装（`claude --version`）
- tmux 已安装（`tmux -V`）
- Telegram 已配置为 OpenClaw 消息通道

## 第一步：安装 Skill

将 claude-agent 放到 OpenClaw 的 skills 目录：

```bash
# 方式 1：git clone
cd ~/.openclaw/workspace/skills/
git clone <repo-url> claude-agent

# 方式 2：手动复制（如果你已经下载了）
cp -r /path/to/claude-agent ~/.openclaw/workspace/skills/claude-agent
```

验证 skill 被识别：
```bash
ls ~/.openclaw/workspace/skills/claude-agent/SKILL.md
# 应该存在
```

## 第二步：配置 Claude Code Stop hook

编辑 Claude Code 用户配置 `~/.claude/settings.json`，添加 hooks 和环境变量：

```json
{
  "env": {
    "CLAUDE_AGENT_CHAT_ID": "你的Chat_ID",
    "CLAUDE_AGENT_CHANNEL": "telegram",
    "CLAUDE_AGENT_ACCOUNT": "main",
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

其中：
- `<SKILL_PATH>` 替换为实际路径，例如：`/home/你的用户名/.openclaw/workspace/skills/claude-agent`
- `CLAUDE_AGENT_CHAT_ID` 替换为你的 Telegram Chat ID
- `CLAUDE_AGENT_ACCOUNT` 替换为你的 OpenClaw Telegram 账号名（在 `openclaw.json` 的 `channels.telegram.accounts` 中查看）

> **注意**：`env` 中的变量会被 Claude Code 注入到 hook 进程的环境中，这是确保 hook 能正确发送通知的关键。也兼容 `CODEX_AGENT_*` 前缀（从 codex-agent 迁移时无需改名）。

## 第三步：配置通知目标

**推荐**：在第二步的 `~/.claude/settings.json` 的 `env` 中已经配置好了，无需额外操作。

如果你需要在 tmux 的 pane_monitor（非 hook 的监控脚本）中也使用正确的通知目标，可以额外在 shell 环境中设置：

```bash
# 在 ~/.zshrc 或 ~/.bashrc 中添加（可选，pane_monitor 用）
export CLAUDE_AGENT_CHAT_ID="你的Chat_ID"
export CLAUDE_AGENT_CHANNEL="telegram"
export CLAUDE_AGENT_ACCOUNT="main"        # OpenClaw 通道账号名
export CLAUDE_AGENT_NAME="main"           # OpenClaw agent 名称
```

获取 Chat ID 的方法：给你的 OpenClaw bot 发一条消息，然后查看 OpenClaw 日志中的 chat_id。

## 第四步：配置 OpenClaw session 重置

OpenClaw 默认每天凌晨 4 点自动重置 session，会导致长任务完成后 hook 唤醒 OpenClaw 时上下文全丢。

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

这相当于设置 100 年后才重置。你仍然可以随时用 `/new` 手动重置。

然后重启 gateway：
```bash
openclaw gateway restart
```

## 第五步：设置脚本权限

```bash
cd ~/.openclaw/workspace/skills/claude-agent/hooks/
chmod +x on_complete.py pane_monitor.sh start_claude.sh stop_claude.sh
```

## 第六步：验证安装

依次运行以下命令，确保每一步都成功：

```bash
# 1. Claude Code 可用
claude --version

# 2. tmux 可用
tmux -V

# 3. Telegram 通知可发送（替换 YOUR_CHAT_ID）
openclaw message send --channel telegram --target YOUR_CHAT_ID --message "claude-agent 通知测试"

# 4. OpenClaw agent 可唤醒
openclaw agent --agent main --message "claude-agent 唤醒测试" --deliver --channel telegram --timeout 10

# 5. Claude Code hook 可触发（在任意 git 目录下）
cd /tmp && mkdir -p claude-test && cd claude-test && git init
claude -p "say hello"
# 你应该在 Telegram 上收到通知
```

## 第七步：使用

安装完成后，直接在 Telegram 里对 OpenClaw 说：

> "用 Claude Code 帮我在 /path/to/project 实现 XX 功能"

OpenClaw 会：
1. 理解你的需求
2. 设计提示词
3. 在 tmux 里启动 Claude Code
4. 中间过程自动处理
5. 完成后 Telegram 通知你

你随时可以 `tmux attach -t <session>` 接入查看。

---

## 一键自动配置（发给 OpenClaw）

如果你不想手动配置，把下面这段话发给 OpenClaw，它会自动帮你完成配置：

```
请帮我安装和配置 claude-agent skill。步骤：
1. 将 claude-agent skill 安装到 ~/.openclaw/workspace/skills/claude-agent/
2. 在 ~/.claude/settings.json 中添加 Stop hook，指向 hooks/on_complete.py
3. 设置环境变量 CLAUDE_AGENT_CHAT_ID 为我的 Telegram Chat ID
4. 配置 OpenClaw session 不自动重置（idle + 52560000 分钟）
5. 设置脚本执行权限
6. 运行验证测试确认所有组件正常
安装指南在 skills/claude-agent/INSTALL.md
```

## 故障排查

| 症状 | 检查 |
|------|------|
| Claude Code 完成后没收到通知 | 检查 `~/.claude/settings.json` 的 hooks.Stop 配置是否正确 |
| 收到通知但 OpenClaw 没反应 | 检查 `openclaw agent --agent main` 是否可用 |
| pane monitor 没检测到审批 | 查看 `/tmp/claude_monitor_<session>.log` |
| start_claude.sh 报错 | 检查 tmux 和 claude 是否安装，workdir 是否存在 |
