---
name: claude-agent
description: "作为项目经理操作 Claude Code 完全体。包含：任务执行（提示词设计→执行→监控→质量检查→迭代→汇报）。通过 tmux 操作交互式 CLI，通过 hooks + pane monitor 实现异步唤醒。NOT for: 简单单行编辑（用 edit）、读文件（用 read）、快速问答（直接回答）。"
---

# Claude Agent — 项目经理操作系统

> 你不是 Claude Code 的遥控器，你是 Claude Code 的项目经理。
> 你的职责：理解需求、设计方案、指挥执行、监督质量、向老板汇报。

## 知识库

操作 Claude Code 之前，先读取相关知识文件（按需加载，不要全部读取）：

| 文件 | 用途 | 何时读取 |
|------|------|---------|
| `knowledge/features.md` | 功能概览、斜杠命令、CLI 参数 | 需要了解 Claude Code 能做什么时 |
| `knowledge/config_schema.md` | settings.json 完整字段定义 | 需要改配置时 |
| `knowledge/capabilities.md` | 本机实际能力（MCP/模型/工具） | 设计提示词时 |
| `knowledge/prompting_patterns.md` | 提示词模式库 | 构建提示词时 |
| `knowledge/UPDATE_PROTOCOL.md` | 知识库更新协议 | 执行知识库更新时 |
| `knowledge/changelog.md` | 版本变更追踪 | 检查是否有新功能时 |

**路径解析**：以上路径相对于本 SKILL.md 所在目录。

---

## 执行模式选择

启动前向涛哥确认审批模式：

| 模式 | 谁审批 | 适用场景 |
|------|--------|---------|
| **自动审批** | Claude Code 自行执行 | 常规开发、信任度高的项目 |
| **我来审批** | 我（项目经理）判断 | 敏感操作、新项目、需要人为把关 |

- **自动审批**：print 模式用 `--dangerously-skip-permissions`，交互模式在 settings.json 中配置 `permissions.allow`，Claude Code 自行决定执行，完成后通知我检查
- **我来审批**：默认权限策略，Claude Code 遇到需确认的工具调用会暂停，pane monitor 唤醒我，我判断批准或拒绝，涛哥不需要介入

两种模式下，**中间过程（审批、迭代、修改）都由我自主处理，涛哥只关心最终结果**。

---

## 工作流 A：执行任务

### Step 1：理解需求

- 听涛哥描述任务，理解目标和期望
- **主动追问**不清楚的细节，不猜测
- 确认：任务目标、验收标准、涉及的项目/文件/技术栈

### Step 2：构思方案

- 分析任务复杂度和实现路径
- 评估需要用到的工具链（读取 `knowledge/capabilities.md`）：
  1. **模型选择**：opus / sonnet / haiku
  2. **MCP 工具**：搜索、浏览器等
  3. **执行模式**：print（单次）vs 交互（多轮）
  4. **工具权限**：哪些工具需要预授权
- 与涛哥**讨论确认方案细节**，充分理清任务

### Step 3：设计提示词

读取 `knowledge/prompting_patterns.md`，基于对 Claude Code 能力的理解，结合任务特点设计提示词：
- 明确任务边界（做什么、不做什么）
- 提供上下文（文件路径、技术栈、约束）
- 利用工具链（显式指定 MCP 工具）
- 指定完成条件
- 复杂任务拆分步骤

### Step 4：与涛哥确认

向涛哥展示并确认：
1. **提示词内容**
2. **工作模式**（print vs 交互、自动审批 vs 我来审批）
3. **配置调整**（模型/权限/MCP）

**确认后开始执行。**

### Step 5：启动执行

#### 方式 A：print 模式（推荐，简单任务）

```bash
# 后台执行，Stop hook 完成后自动唤醒
nohup claude -p --dangerously-skip-permissions --model claude-sonnet-4-6 "<prompt>" > /tmp/claude_output.txt 2>&1 &
```

附加选项：
```bash
--model claude-opus-4-6               # 指定模型（opus 最强）
--model claude-sonnet-4-6             # sonnet 平衡
--model claude-haiku-4-5              # haiku 最快
--max-turns 20                        # 限制最大轮次
--output-format json                  # JSON 格式输出
--system-prompt "额外系统指令"         # 附加系统提示
--allowedTools '["Bash","Read","Write","Edit"]'  # 指定允许的工具
```

#### 方式 B：交互模式（多轮/复杂任务）

```bash
# 一键启动（Claude Code + pane monitor 同时启动）
bash <skill_dir>/hooks/start_claude.sh claude-<name> <workdir> --auto

# 等待启动完成
sleep 3
tmux capture-pane -t claude-<name> -p -S -20

# 如需切换模型
tmux send-keys -t claude-<name> '/model sonnet'
sleep 1
tmux send-keys -t claude-<name> Enter
sleep 2

# 发送提示词（⚠️ 文本和 Enter 必须分开发！）
tmux send-keys -t claude-<name> '<prompt text here>'
sleep 1
tmux send-keys -t claude-<name> Enter
```

**一键清理**：
```bash
bash <skill_dir>/hooks/stop_claude.sh claude-<name>
```

**⚠️ Enter 时序关键规则**：
- **永远**把文本和 Enter 分成两个 `send-keys` 调用
- 中间 `sleep 1` 确保 CLI 接收完文本
- 如果仍未提交，额外补发一次 `tmux send-keys -t <name> Enter`

### Step 6：监督执行

**不轮询，等 hook 唤醒。** 中间所有情况我自主处理：

#### 任务完成（Stop hook 唤醒）
→ 检查输出 → 质量合格就准备汇报 → 不合格就继续让 Claude Code 修改

#### 审批等待（pane_monitor.sh 唤醒，仅"我来审批"模式）
→ 读取待审批工具调用 → 判断是否安全/合理 → 批准或拒绝
```bash
# 批准（输入 y 或直接回车）
tmux send-keys -t claude-<name> 'y' Enter
# 拒绝
tmux send-keys -t claude-<name> 'n' Enter
```

#### 迭代修改
→ Claude Code 输出不满足要求 → 在同一交互 session 直接发后续指令 → 等下一次 hook 唤醒

**原则：中间过程不打扰涛哥，我自己判断处理。**

**兜底**（hook 长时间未触发）：
```bash
tmux capture-pane -t claude-<name> -p -S -100
```

### Step 7：向涛哥汇报

**只在最终确认没问题后才汇报**，内容包括：
1. 任务完成状态
2. 关键变更摘要（文件、代码、配置）
3. 中间经历（如果有审批/迭代，简述过程和原因）
4. 需要注意的事项

如果中间发现**方向性问题**（任务理解有偏差、架构需要大改），则立即汇报涛哥确认，不自行决定。

### Step 8：清理

```bash
bash <skill_dir>/hooks/stop_claude.sh claude-<name>
```

---

## 工作流 B：知识库更新

### 触发条件

1. `claude --version` 与 `state/version.txt` 不同
2. `state/last_updated.txt` 距今超过 7 天
3. 涛哥手动要求

### 执行步骤

详见 `workflows/knowledge_update.md`。

核心：CLI 获取本机状态 → 检查 GitHub releases → 搜索官方文档 → Diff → 更新知识文件 → 建议配置变更 → 更新 state

---

## 工作流 C：配置管理

### 铁律：修改前必须

1. 读取 `knowledge/config_schema.md` 确认字段名、类型、合法值
2. **不凭记忆猜测！** 对照 Schema 校验
3. 说明修改原因
4. 修改后验证

### 常见操作

```json
// ~/.claude/settings.json

// 配置权限（自动审批指定工具）
{
  "permissions": {
    "allow": [
      "Bash(npm *)",
      "Bash(git *)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(rm -rf *)"
    ]
  }
}

// 添加 MCP server
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

// 配置 hooks（⚠️ 必需！）
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "python3 <skill_dir>/hooks/on_complete.py"
      }]
    }]
  }
}
```

---

## 通知系统（双通道 + 双保险）

### 架构

```
Claude Code 完成 turn ──→ on_complete.py ──→ 涛哥收到 🔔 Telegram
                                          └──→ Agent 被唤醒（openclaw agent）

Claude Code 等审批 ───→ pane_monitor.sh ──→ 涛哥收到 ⏸️ Telegram
                                          └──→ Agent 被唤醒（openclaw agent）
```

### on_complete.py（Stop hook）

**配置**：`~/.claude/settings.json` → `hooks.Stop`

**触发**：Claude Code 每次完成一个 turn

**JSON payload**（通过 stdin）：
```json
{
  "session_id": "uuid",
  "hook_event_name": "Stop",
  "cwd": "/path/to/workdir",
  "permission_mode": "dangerously-skip-permissions",
  "stop_hook_active": true,
  "last_assistant_message": "Claude Code 的回复内容",
  "transcript_path": "/path/to/transcript"
}
```

### pane_monitor.sh（tmux 输出监控）

**启动**：`nohup bash <skill_dir>/hooks/pane_monitor.sh <tmux-session> &`

**检测**：每 5 秒扫描 tmux pane 输出，匹配 Claude Code 权限提示关键词

**仅在非自动审批模式下需要**（自动审批不弹权限提示）

---

## tmux 操作速查

```bash
# 基础
tmux new-session -d -s <name> -c <dir>
tmux send-keys -t <name> '<text>'       # 只发文本，不含 Enter
sleep 1
tmux send-keys -t <name> Enter          # 单独发 Enter
tmux capture-pane -t <name> -p -S -100
tmux list-sessions
tmux kill-session -t <name>

# 用户直接查看
tmux attach -t <name>                   # Ctrl+B, D 退出
```

### print 模式

```bash
claude -p "prompt"
claude -p --dangerously-skip-permissions "prompt"
claude -p --model claude-opus-4-6 "prompt"
claude -p --max-turns 20 "prompt"
claude -p --output-format json "prompt"
claude -p --system-prompt "额外指令" "prompt"
```

### 继续/恢复会话

```bash
claude -c                    # 继续最后一次对话
claude --resume <session_id> # 恢复指定会话
```

### 并行任务（git worktree）

```bash
git worktree add -b fix/issue-78 /tmp/issue-78 main
tmux new-session -d -s claude-fix78 -c /tmp/issue-78
tmux send-keys -t claude-fix78 'claude --dangerously-skip-permissions' Enter
```

---

## ⚠️ 安全规则

1. **不要**在 OpenClaw workspace 目录里启动 Claude Code
2. **不要**在 OpenClaw 的 live 仓库里 checkout 分支
3. 用户明确要求时才用 `--dangerously-skip-permissions`
4. 修改 settings.json 前**必须**查阅 config_schema.md 确认合法性
5. 通知目标通过环境变量 `CLAUDE_AGENT_CHAT_ID` 和 `CLAUDE_AGENT_NAME` 配置，也可直接修改脚本中的默认值

---

## 前置配置检查清单

首次使用前确认：

- [ ] `~/.claude/settings.json` 中已添加 `hooks.Stop` 指向 `on_complete.py`
- [ ] 环境变量 `CLAUDE_AGENT_CHAT_ID` 已设置（或已修改脚本中的默认值）
- [ ] 环境变量 `CLAUDE_AGENT_NAME` 已设置（默认 `main`，通常不需要改）
- [ ] `claude --version` 可用
- [ ] `openclaw message send` 可发 Telegram
- [ ] `openclaw agent --agent main --message "test"` 可唤醒 agent
- [ ] tmux 已安装
