# Claude Code CLI 完整命令参考

## 基本用法

```bash
claude [OPTIONS] [PROMPT]          # 交互模式
claude -p [OPTIONS] [PROMPT]       # Print 模式（非交互）
```

## 全局选项

| 选项 | 说明 |
|------|------|
| `-p, --print` | 非交互模式，输出结果后退出 |
| `-m, --model <MODEL>` | 指定模型（opus / sonnet / haiku 或完整 ID） |
| `--dangerously-skip-permissions` | 跳过所有权限提示（仅 -p 模式） |
| `--allowedTools <JSON>` | 允许的工具列表（JSON 数组格式） |
| `--max-turns <N>` | 最大对话轮次（-p 模式） |
| `--output-format <FMT>` | 输出格式：text / json / stream-json |
| `--system-prompt <TEXT>` | 附加系统提示 |
| `--append-system-prompt <TEXT>` | 追加系统提示 |
| `-c, --continue` | 继续最后一次对话 |
| `--resume <SESSION_ID>` | 恢复指定会话 |
| `--verbose` | 详细输出 |
| `--version` | 显示版本 |
| `--help` | 显示帮助 |

## 模型

| 简称 | 完整 Model ID | 特点 |
|------|--------------|------|
| `opus` | `claude-opus-4-6` | 最强推理，复杂任务 |
| `sonnet` | `claude-sonnet-4-6` | 平衡速度与能力 |
| `haiku` | `claude-haiku-4-5` | 最快速度，简单任务 |

## 交互模式斜杠命令

| 命令 | 说明 |
|------|------|
| `/help` | 显示帮助 |
| `/model <model>` | 切换模型 |
| `/clear` | 清除对话 |
| `/compact` | 压缩上下文 |
| `/cost` | 显示费用和 token 用量 |
| `/memory` | 管理记忆 |
| `/doctor` | 运行诊断 |
| `/quit` | 退出 |

## 配置文件

配置位置：`~/.claude/settings.json`

```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep"],
    "deny": ["Bash(rm -rf *)"]
  },
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "python3 /path/to/hook.py"
      }]
    }]
  },
  "mcpServers": {}
}
```

## 常用命令组合

```bash
# 标准自动执行
claude -p --dangerously-skip-permissions "任务描述"

# 指定模型
claude -p --model claude-opus-4-6 "任务描述"

# 限制轮次
claude -p --max-turns 20 "任务描述"

# JSON 输出
claude -p --output-format json "任务描述"

# 附加系统提示
claude -p --system-prompt "你是代码审查专家" "审查这段代码"

# 继续上次对话
claude -c

# 恢复指定会话
claude --resume <session_id>
```
