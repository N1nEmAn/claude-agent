# Claude Code settings.json 完整配置参考

> 最后更新: 2026-03-13

## 配置文件位置

| 作用域 | 路径 | 说明 |
|--------|------|------|
| 用户级 | `~/.claude/settings.json` | 全局设置 |
| 项目级 | `.claude/settings.json` | 项目覆盖 |

## 权限配置

```json
{
  "permissions": {
    "allow": [
      "Bash(npm *)",
      "Bash(git *)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo *)"
    ]
  }
}
```

### 权限匹配语法

- `"Read"` — 允许/拒绝所有 Read 调用
- `"Bash(npm *)"` — 允许以 `npm` 开头的 Bash 命令
- `"Bash(git *)"` — 允许以 `git` 开头的 Bash 命令
- 支持 glob 模式匹配

## Hooks 配置

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/pre-hook.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/post-hook.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/notify-hook.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 /path/to/on_complete.py"
          }
        ]
      }
    ]
  }
}
```

### Hook 事件说明

| 事件 | matcher 匹配目标 | stdin 输入 | 可修改行为 |
|------|-----------------|-----------|-----------|
| `PreToolUse` | 工具名 (Bash/Read/Write 等) | 工具调用详情 JSON | 是（可阻止调用） |
| `PostToolUse` | 工具名 | 工具调用结果 JSON | 否 |
| `Notification` | 通知类型 | 通知内容 JSON | 否 |
| `Stop` | 停止原因 | 会话信息 JSON | 否 |

### Hook 脚本协议

- 通过 **stdin** 接收 JSON 输入
- 通过 **stdout** 输出 JSON 响应（仅 PreToolUse 有效）
- 非零退出码表示 hook 失败
- PreToolUse hook 输出 `{"decision": "deny", "reason": "..."}` 可阻止工具调用

## MCP Servers 配置

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@package/name@latest"],
      "env": {
        "API_KEY": "your-key"
      }
    },
    "local-server": {
      "command": "node",
      "args": ["/path/to/server.js"]
    }
  }
}
```

## 完整示例

```json
{
  "permissions": {
    "allow": [
      "Bash(npm *)",
      "Bash(git *)",
      "Read",
      "Glob",
      "Grep"
    ],
    "deny": []
  },
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.openclaw/workspace/skills/claude-agent/hooks/on_complete.py"
          }
        ]
      }
    ]
  },
  "mcpServers": {}
}
```

## 项目级配置

项目级配置位于 `.claude/settings.json`，结构与用户级相同。项目级配置会与用户级合并，项目级优先。

## CLAUDE.md 项目指令

Claude Code 启动时自动读取项目目录的 `CLAUDE.md` 文件，用于提供项目特定的指令和上下文。

查找顺序：
1. 当前目录的 `CLAUDE.md`
2. 当前目录的 `.claude/CLAUDE.md`
3. 父目录递归查找（到 git root）
4. `~/.claude/CLAUDE.md`（用户级）
