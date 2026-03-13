# 知识库更新工作流

## 概述
定期或触发式更新 Claude Code 知识库，保持与最新版本同步。

## 触发条件

1. `claude --version` 输出与 `state/version.txt` 不同
2. `state/last_updated.txt` 距今超过 7 天
3. 涛哥手动要求

## 执行步骤

### Step 1: 收集本机数据

```bash
claude --version > /tmp/claude_version.txt
claude --help > /tmp/claude_help.txt
cat ~/.claude/settings.json
```

### Step 2: 拉取远程数据

```bash
# 创建缓存目录
mkdir -p /tmp/claude-knowledge-cache

# GitHub releases（如果有公开仓库）
# 官方文档
```

### Step 3: 浏览官方文档（如可访问）

优先访问：
- https://docs.anthropic.com/en/docs/claude-code/overview
- https://docs.anthropic.com/en/docs/claude-code/cli-usage
- https://docs.anthropic.com/en/docs/claude-code/settings
- https://docs.anthropic.com/en/docs/claude-code/hooks

### Step 4: Diff 分析

对比新旧数据：
- CLI 参数是否有新增/变更
- settings.json 字段是否有变化
- 斜杠命令是否有新增
- 是否有重要功能变更

### Step 5: 更新文件

按变更更新：
- `features.md` — 新增标 [NEW]，废弃标 [DEPRECATED]
- `config_schema.md` — 新字段/新类型
- `capabilities.md` — 本机能力变化
- `prompting_patterns.md` — 新功能带来的新用法
- `changelog.md` — 追加变更记录

### Step 6: 配置建议

如有新功能推荐启用：
1. 生成 settings.json 的具体修改建议
2. 说明变更理由
3. 报告涛哥确认后再应用

### Step 7: 更新状态

```bash
echo "<new_version>" > state/version.txt
echo "<today>" > state/last_updated.txt
```
