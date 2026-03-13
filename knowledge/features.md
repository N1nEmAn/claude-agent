# Claude Code 功能全览

> 最后更新: 2026-03-13

## CLI 参数

| 参数 | 说明 |
|------|------|
| `-p, --print` | 非交互模式（print mode），执行完输出结果后退出 |
| `-m, --model <MODEL>` | 指定模型（opus / sonnet / haiku 或完整 model ID） |
| `--dangerously-skip-permissions` | 跳过所有工具权限提示（仅 -p 模式） |
| `--allowedTools <JSON>` | 指定允许的工具列表（JSON 数组） |
| `--max-turns <N>` | 限制最大对话轮次（-p 模式） |
| `--output-format <FMT>` | 输出格式：`text`（默认）/ `json` / `stream-json` |
| `--system-prompt <TEXT>` | 附加系统提示 |
| `--append-system-prompt <TEXT>` | 追加到系统提示 |
| `-c, --continue` | 继续最后一次对话 |
| `--resume <SESSION_ID>` | 恢复指定会话 |
| `--verbose` | 详细输出 |

## 模型

| 模型 | Model ID | 特点 |
|------|----------|------|
| Opus 4.6 | `claude-opus-4-6` | 最强推理能力，复杂任务 |
| Sonnet 4.6 | `claude-sonnet-4-6` | 平衡速度与能力，日常开发 |
| Haiku 4.5 | `claude-haiku-4-5` | 最快速度，简单任务 |

模型切换（交互模式）：`/model sonnet` 或 `/model opus`

## 斜杠命令（交互模式）

| 命令 | 说明 |
|------|------|
| `/help` | 显示帮助信息 |
| `/model <model>` | 切换模型 |
| `/clear` | 清除对话历史 |
| `/compact` | 压缩上下文（防止 context 爆满） |
| `/cost` | 显示当前会话费用和 token 用量 |
| `/memory` | 管理 Claude Code 的记忆系统 |
| `/doctor` | 运行诊断检查 |
| `/quit` `/exit` | 退出 |

## 内置工具

Claude Code 提供以下内置工具：

| 工具 | 说明 |
|------|------|
| `Bash` | 执行 shell 命令 |
| `Read` | 读取文件内容 |
| `Write` | 写入/创建文件 |
| `Edit` | 编辑文件（精确替换） |
| `Glob` | 文件模式匹配搜索 |
| `Grep` | 文件内容搜索 |
| `WebFetch` | 获取网页内容 |
| `WebSearch` | 网页搜索 |
| `Agent` | 启动子 agent |
| `NotebookEdit` | 编辑 Jupyter notebook |

## 权限系统

Claude Code 使用基于工具的权限系统：

```json
{
  "permissions": {
    "allow": [
      "Bash(npm *)",
      "Bash(git *)",
      "Read",
      "Write",
      "Edit"
    ],
    "deny": [
      "Bash(rm -rf *)"
    ]
  }
}
```

权限模式：
- **默认**：每次工具调用都需要用户确认
- **Allow 列表**：匹配的工具自动批准
- **Deny 列表**：匹配的工具自动拒绝
- **`--dangerously-skip-permissions`**：跳过所有确认（仅 -p 模式）

## Hooks 系统

Claude Code 支持在特定事件时触发自定义脚本：

| 事件 | 说明 |
|------|------|
| `PreToolUse` | 工具调用前触发 |
| `PostToolUse` | 工具调用后触发 |
| `Notification` | 通知事件触发 |
| `Stop` | Claude Code 完成响应时触发 |

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "python3 /path/to/script.py"
      }]
    }]
  }
}
```

Hook 脚本通过 stdin 接收 JSON payload，可通过 stdout 输出 JSON 修改行为（仅 Pre hooks）。

## MCP 支持

Claude Code 支持 MCP (Model Context Protocol) 服务器：

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package@latest"],
      "env": {
        "API_KEY": "..."
      }
    }
  }
}
```

## CLAUDE.md

项目指令文件，相当于 Codex 的 AGENTS.md。Claude Code 启动时自动读取：
- `CLAUDE.md` — 项目根目录
- `.claude/settings.json` — 项目级配置

## 自定义斜杠命令（Skills）

在 `.claude/commands/` 目录下创建 Markdown 文件即可注册自定义命令：
```
.claude/commands/my-command.md
```
使用 `/my-command` 调用。文件内容作为 prompt 模板。
