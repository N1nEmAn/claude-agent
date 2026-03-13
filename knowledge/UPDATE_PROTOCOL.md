# Claude Code 知识库更新协议

## 更新触发时机

1. **版本变更时**：每次使用前检查 `claude --version`，与 `../state/version.txt` 对比，版本变了立即触发更新
2. **定期更新**：距 `../state/last_updated.txt` 超过 7 天时触发
3. **手动触发**：涛哥要求时

## 数据源（信任度从高到低）

### 来源 1：CLI 本机输出（真相来源，反映实际安装版本）

```bash
claude --version                    # 当前版本
claude --help                       # CLI 参数
```

### 来源 2：GitHub 源码和文档

```
https://github.com/anthropics/claude-code
https://docs.anthropic.com/en/docs/claude-code
```

### 来源 3：官方文档站

```
https://docs.anthropic.com/en/docs/claude-code/overview
https://docs.anthropic.com/en/docs/claude-code/cli-usage
https://docs.anthropic.com/en/docs/claude-code/settings
https://docs.anthropic.com/en/docs/claude-code/hooks
https://docs.anthropic.com/en/docs/claude-code/mcp
https://docs.anthropic.com/en/docs/claude-code/memory
```

### 来源 4：社区（实验性功能线索，需验证）

- GitHub Issues/Discussions: `https://github.com/anthropics/claude-code/issues`

## 更新流程

1. 跑 CLI 获取本机实际状态（version + help）
2. 抓取 GitHub releases，提取最近变更
3. （可选）浏览官方文档站，补充 CLI 未覆盖的内容
4. 对比新旧数据，分析变化
5. 更新 `features.md`：新增标 [NEW]，废弃标 [DEPRECATED]
6. 更新 `config_schema.md`：同步字段变更
7. 更新 `capabilities.md`：检查本机能力变化
8. 更新 `changelog.md`：记录本次变更摘要
9. 如有推荐的配置变更 → 报告涛哥确认后应用
10. 更新 `../state/version.txt` 和 `../state/last_updated.txt`

## 校验规则

- 所有写入 features.md 的功能必须能在 CLI help 或官方文档中找到佐证
- 社区来源信息必须标注 [UNVERIFIED]，在官方文档中验证后才能去掉标记
- settings.json 修改建议必须通过实测验证合法性
