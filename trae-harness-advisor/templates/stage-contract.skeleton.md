# Stage {id} Contract — {Milestone Name}

> 由 Orchestrator 在起 Stage 时标注关键点（一次标注，非 Generator↔Evaluator 多轮协商）。
> Generator 据此实现，Evaluator 据此验收。
> 若 force_contract=false：跳过本标注，Generator 直接按 spec.md 实现，并在 gen.md 说明验证依据。

## 本轮目标
{一句话描述}

## 验收要点（可机械检查）
> 原则 A：每条尽量能用「一个可运行命令 + ✅/❌ 输出」判定；判不了就继续拆或先写验证脚本。
1. {条件 1}（验证命令：{完整可运行命令，内嵌 ✅/❌ 判断}；期望输出：{具体值}）
2. {条件 2}
3. {条件 3}

## 边界（原则 B：不写出来的范围就是自由发挥空间）
- 包含：{范围内}
- 不包含 / 不要改：{范围外具体文件/模块，避免越权与级联修改}

## 失败速查表（联调/易错 Stage 建议填）
| 看到的报错 | 最可能原因 | 做这个（不要做这个） |
|-----------|-----------|--------------------|
| {报错1} | {原因} | {操作}；**{禁止事项}** |

## MCP Bridge 能力（可选，仅 mcp_access_mode=evaluator_shell_bridge）
- mode: orchestrator_delegated | evaluator_shell_bridge
- check_result: {harness_dir}mcp-bridge/check.sh --json 的摘要
- allowed_commands:
  - {命令名}: {用途、参数边界、输出/截图/trace 路径约定}
- mcp_to_shell_translation:
  - 当你想导航 URL 时，改用：`{harness_dir}mcp-bridge/bin/mcp-browser playwright.browser_navigate url:{url}`
  - 当你想获取快照时，改用：`{harness_dir}mcp-bridge/bin/mcp-browser playwright.browser_snapshot`
  - 当你想截图时，改用：`{harness_dir}mcp-bridge/bin/mcp-browser playwright.browser_take_screenshot`
  - 当你想点击元素时，改用：`{harness_dir}mcp-bridge/bin/mcp-browser playwright.browser_click element:"{label}" ref:{snapshot_ref}`
  - 当你想执行 JS 时，改用：`{harness_dir}mcp-bridge/bin/mcp-browser playwright.browser_evaluate 'function=() => document.title'`；注意参数名是 `function`，不是 `expression`
- fallback: bridge 不可用时 fallback 到 orchestrator_delegated，或输出 `[BLOCKED: MCP bridge unavailable]`

## 验收项 6 段式要求
每个验收项尽量包含：
1. 前置检查命令：服务是否在线 / 环境变量是否已设（带 ✅/❌）。
2. 执行命令：完整可运行，无 `...` 省略，内嵌 ✅/❌ 判断，不能只打印原始数据。
3. 期望输出：具体字段 + 合理值范围，不写"类似这样"。
4. 失败速查表：具体到操作 + 禁止事项。
5. 修改位置：如需改码，精确到文件/函数级，并写"只改这个，不要改其他"。
6. 通过标准：全部满足才算完成，每条含可观测数值/状态。

## 停止条件（原则 C：明确写，Generator 不会自己决定停）
遇到以下情况输出 `[BLOCKED: 原因]` 停下等人工/Orchestrator：
- {本 Stage 特有的必停项，如 HTTP 401/403、某字段缺失需人工确认}
- 同一问题改 >3 次仍失败 / 需改 >2~3 个文件 / 全量测试新增失败 / 需要人工提供 API Key、账号或业务决策

## 依赖
- {依赖的 Stage 或外部条件}

## 预估风险
- {潜在风险点}
