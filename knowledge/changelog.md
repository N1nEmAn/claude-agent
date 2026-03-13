# Claude Code 版本变更追踪

## 2026-03-13 — 知识库 v1 完成（从 codex-agent 移植）

### 本次完成

- [x] 从 codex-agent 移植为 claude-agent
- [x] 知识库 6 文件建成（features/config_schema/capabilities/prompting_patterns/UPDATE_PROTOCOL/changelog）
- [x] SKILL.md 重写为 Claude Code 完整工作流（print + 交互双模式）
- [x] on_complete.py 适配 Claude Code hooks（stdin JSON）
- [x] pane_monitor.sh 适配 Claude Code 权限提示检测
- [x] start_claude.sh / stop_claude.sh 一键管理脚本
- [x] Enter 时序规则保留（文本和 Enter 分两次 send-keys，中间 sleep 1s）

### Claude Code vs Codex 关键差异

| 维度 | Codex | Claude Code |
|------|-------|------------|
| CLI 命令 | `codex` | `claude` |
| 非交互模式 | `codex exec` | `claude -p` |
| 自动审批 | `--full-auto` | `--dangerously-skip-permissions` |
| 配置文件 | `~/.codex/config.toml`（TOML） | `~/.claude/settings.json`（JSON） |
| 项目指令 | `AGENTS.md` | `CLAUDE.md` |
| Hook 机制 | `notify` config（argv JSON） | `hooks.Stop`（stdin JSON） |
| 模型 | gpt-5.2 | opus / sonnet / haiku |
| Feature Flags | 30+ flags | 无（功能内置） |
| TUI 标志 | `--no-alt-screen` | 不需要 |
| 权限系统 | 沙盒 + 审批策略 | permissions.allow/deny |

### 待补充

- [ ] 测试 pane_monitor.sh 与 Claude Code TUI 的权限提示匹配准确性

### Claude Code Stop Hook 实测 Payload

```json
{
  "session_id": "uuid",
  "transcript_path": "/path/to/transcript",
  "cwd": "/path/to/workdir",
  "permission_mode": "dangerously-skip-permissions",
  "hook_event_name": "Stop",
  "stop_hook_active": true,
  "last_assistant_message": "Claude Code 的回复内容"
}
```

关键发现：
- 字段名是 `last_assistant_message`（下划线），不是 `last-assistant-message`（连字符，Codex 用法）
- `hook_event_name` 替代了 Codex 的 `type` 字段
- 没有 `stop_reason` 字段，有 `stop_hook_active` 布尔值
- `permission_mode` 字段标识当前权限模式
- Hook 通过 **stdin** 接收 JSON（Codex 通过 argv）
