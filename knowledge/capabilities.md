# Claude Code 本机能力清单

> 最后更新: 2026-03-13

## 基本信息

- **版本**: 待检测（`claude --version`）
- **默认模型**: claude-sonnet-4-6
- **可用模型**: opus / sonnet / haiku
- **配置文件**: `~/.claude/settings.json`

## 内置工具

| 工具 | 说明 | 权限模式 |
|------|------|---------|
| `Bash` | 执行 shell 命令 | 需审批（可配置 allow） |
| `Read` | 读取文件 | 需审批（可配置 allow） |
| `Write` | 写入/创建文件 | 需审批 |
| `Edit` | 编辑文件（精确替换） | 需审批 |
| `Glob` | 文件名模式搜索 | 需审批（可配置 allow） |
| `Grep` | 文件内容搜索 | 需审批（可配置 allow） |
| `WebFetch` | 获取网页内容 | 需审批 |
| `WebSearch` | 网页搜索 | 需审批 |
| `Agent` | 启动子 agent | 需审批 |
| `NotebookEdit` | 编辑 Jupyter notebook | 需审批 |

## 已安装 MCP Servers

> 通过 `~/.claude/settings.json` 的 `mcpServers` 配置。
> 需要检查本机实际配置。

（首次使用时运行 `cat ~/.claude/settings.json` 检查）

## Hooks 系统

| 事件 | 说明 | 我们的用途 |
|------|------|----------|
| `Stop` | Claude Code 完成响应 | on_complete.py → 通知 + 唤醒 |
| `Notification` | Claude Code 发送通知 | 可选备用通知通道 |
| `PreToolUse` | 工具调用前 | 可用于审批控制 |
| `PostToolUse` | 工具调用后 | 可用于日志记录 |

## 模型选择策略

| 任务类型 | 推荐模型 |
|---------|---------|
| 简单修改/格式化 | haiku（最快） |
| 常规开发 | sonnet（平衡） |
| 复杂架构/超难 bug | opus（最强） |

交互模式切换：`/model sonnet` `/model opus` `/model haiku`
print 模式指定：`--model claude-opus-4-6`

## 提示词增强策略

### MCP 工具调用
Claude Code 会根据 prompt 自动调用已配置的 MCP 工具，也可显式提示：
```
使用 XXX MCP 搜索 "关键词" 的最新信息
```

### 子 Agent
Claude Code 支持通过 Agent 工具启动子 agent 并行处理任务。

### 上下文管理

| 场景 | 操作 |
|------|------|
| 上下文快满 | `/compact` 压缩历史 |
| 查看费用 | `/cost` |
| 查看诊断 | `/doctor` |

## 执行模式对比

| 模式 | 命令 | 适用场景 |
|------|------|---------|
| 交互模式 | `claude` | 多轮对话、复杂任务 |
| Print 模式 | `claude -p "prompt"` | 单次执行、脚本集成 |
| 继续对话 | `claude -c` | 恢复上次对话 |
| 恢复会话 | `claude --resume <id>` | 恢复指定会话 |
