# AP19 实验补测 — Decision 裁决

> 角色：独立 Decision SubAgent（@decision-role），与 Generator/Evaluator 上下文隔离。
> 职责：只读 `contract.md` / `eval.md` / `state-board.json` / `RULE.md`，对 AP19 实验补测做出中立裁决；不写代码、不评分代码质量、不兼任 Generator/Evaluator、不重新裁决 AP1-AP11。
> 输入文件（已全部 Read，未读 G/E 子代理会话内部推理）：
> - `/workspace/RULE.md`（含 §59-67 MCP bridge 约束）
> - `/workspace/harness/milestones/harness-selftest/stages/probe/contract.md`（§32-87 AP19 段）
> - `/workspace/harness/milestones/harness-selftest/stages/probe/eval.md`（§65-141 AP19 段）
> - `/workspace/harness/state-board.json`（probe.status=passed）

## VERIFY 行（严格格式）

- `VERIFY[AP19-criterion-1-config]: PASS — eval.md §71/§80-90 实跑 check.sh --json 得 available=true、mode=evaluator_shell_bridge、commands.mcp-browser=available、errors.mcp-browser=（空）；contract.md §36-44 Orchestrator 自检摘录一致。静态 runtime 生效成立。`
- `VERIFY[AP19-criterion-2-translation]: PASS — contract.md §47-58 mcp_bridge_capabilities（allowedTools 5 项 + mustLogTo=eval.md）与 §59-67 mcp_to_shell_translation（5 行样例表）齐备；eval.md §72 已 Read 两文件交叉核对逐字一致。`
- `VERIFY[AP19-criterion-3-evaluator-self]: PASS — eval.md §67/§73/§78-127 Evaluator SubAgent 自己（非 Orchestrator 代行）按翻译表用 RunCommand 调用 tools/mcp-bridge/bin/mcp-browser 完成正面 + 负面查证，命令来源标注 contract §63/§67，命令、exit code、STDOUT、STDERR、BLOCKED 原因齐全写入 eval.md。`
- `VERIFY[AP19-criterion-4-negative-blocked]: PASS — eval.md §75/§122-127 playwright_invalid_tool 被 wrapper 在转发前拦截：stderr 输出 "[BLOCKED: MCP bridge command not allowed] playwright_invalid_tool"，WRAPPER_EXIT=2，未转发 mcporter、无副作用，与 contract §74/§83 逐字一致。`
- `VERIFY[AP19-criterion-5-no-orchestrator-delegation]: PASS — contract.md §32-87 AP19 段未写任何 browser-check 中间细节；§34 明确"Orchestrator 不代行浏览器观察、不写新 browser-check 中间细节"；eval.md §67/§76 印证 Orchestrator 仅据 check.sh + config 誊写翻译表并派 Evaluator 自查。`
- `VERIFY[AP19-criterion-6-honest-blocked]: PASS — eval.md §74/§90/§92-120/§131 Evaluator 如实区分"check.sh available=true 静态自检"与"wrapper 真机调用"，正面查证 exit 1 未取回任何浏览器证据时明确记 BLOCKED 并写明 MCP server offline 根因，未假装通过；满足"bridge 实际不可用时明确 BLOCKED"。`

## 6 条标准逐条核对

| 标号 | 标准（contract §79-85） | 证据来源 | 核对结果 |
|---|---|---|---|
| 1 | config-owned MCP runtime 生效（check.sh available=true + commands.mcp-browser=available） | eval.md §71/§80-90 实跑输出；contract §36-44 摘录 | PASS（静态自检层） |
| 2 | contract.md 含从 config/mcporter.json 誊写的 mcp_bridge_capabilities + mcp_to_shell_translation | contract §47-67 两段齐备；eval.md §72 交叉核对逐字一致 | PASS |
| 3 | Evaluator SubAgent 自己按翻译表通过项目 wrapper 查证并写 eval.md（命令+输出/BLOCKED 原因齐） | eval.md §73/§78-127 命令+exit+STDOUT+STDERR+BLOCKED 原因齐 | PASS（查证动作 + 证据齐备；真机调用结果另议） |
| 4 | 白名单外 tool 被 wrapper BLOCKED（`[BLOCKED: MCP bridge command not allowed]`） | eval.md §75/§122-127 WRAPPER_EXIT=2 + 标准消息 | PASS |
| 5 | Orchestrator 不代行浏览器中间观察（contract AP19 段未写 browser-check 中间细节） | contract §32-87 无 browser-check 中间细节；§34 显式声明 | PASS |
| 6 | bridge 实际不可用时明确 BLOCKED（不假装通过） | eval.md §74/§90/§131 如实 BLOCKED + 写明 MCP server offline 根因 | PASS（如实 BLOCKED 即满足此条） |

> 6 条标准逐条字面均满足——编排/契约/wrapper/负面强制/如实记录链路全部正确。
> **但** contract §87 注给出整体裁决指引："wrapper 调用链路通 + 翻译表执行 + 负面用例被拒 = AP19=PASS；若 wrapper 实际调用因 MCP server offline / chromium 二进制缺失而失败，AP19 记 BLOCKED/FAIL，不假装通过。"——其中"wrapper 调用链路通"要求**真机调用成功**，当前不满足（见裁决理由）。

## 裁决理由

### 1. 正面查证是否真实取回浏览器证据？——否

eval.md §92-120 详细记录两次正面真机调用：
- `playwright_navigate url:https://example.com`：NAV_WRAPPER_EXIT=1，STDOUT 空，STDERR 报 `Unknown MCP server 'playwright_navigate'`。
- `playwright_get_visible_text`：GVT_WRAPPER_EXIT=1，STDOUT 空，STDERR 报 `Unknown MCP server 'playwright_get_visible_text'`。

两次调用均**未取回页面标题、首屏文本、截图**中的任何一项浏览器证据。Evaluator 在 §74/§131 明确承认"未取回页面标题/首屏文本/截图"。

### 2. Evaluator 是否如实区分"静态自检"与"真机调用"？——是，区分清晰

eval.md §90 明确写道："`available=true` / `commands.mcp-browser=available` 仅静态 wrapper 自检（文件存在 + mcporter daemon status 成功）；discovery 已显式标注 playwright MCP server offline，属真机事实，**不等于浏览器调用一定成功**。"

这正是 contract §75 要求的"不得把本地静态检查（check.sh available=true）当真机通过"。Evaluator 没有把静态自检冒充真机通过，诚实区分成立。

### 3. 真机调用失败的根因——playwright MCP server offline（环境前置）

eval.md §107/§120 给出失败根因：wrapper 白名单检查通过 → 转发 `npx -y mcporter call <tool>` → mcporter 试图由 tool 名反查 server → 因 playwright MCP server offline 无法 listTools → 推断失败 → "Unknown MCP server"。

这与 contract §42 discovery 摘录 "playwright (offline — unable to reach server, 30.0s) ... 0 healthy; 1 offline" 一致，属**环境前置缺失**（MCP server 未启动 / chromium 二进制未装），而非编排/契约/wrapper 设计缺陷。

### 4. 编排/契约/wrapper/负面强制链路是否正确？——全部正确

- config-owned MCP runtime 静态生效（标准 1 PASS）
- 翻译表从 config/mcporter.json 逐字誊写（标准 2 PASS）
- Evaluator 在自己上下文内按翻译表改写 RunCommand，未找/未编造 `mcp__*`、未直接调 `npx mcporter call`（标准 3 PASS）
- 负面用例被 wrapper 在转发前拦截，标准消息 + exit 2（标准 4 PASS）
- Orchestrator 未代行浏览器中间观察（标准 5 PASS）
- bridge 不可用时 Evaluator 如实 BLOCKED、未假装通过（标准 6 PASS）

### 5. 综合判断

6 条标准的字面要求（编排/契约/wrapper/负面/如实记录）Evaluator 全部做对。但 contract §87 注明确规定整体裁决指引："wrapper 实际调用因 MCP server offline 而失败 → AP19 记 BLOCKED/FAIL，不假装通过。"当前正面真机调用因 MCP server offline 而 exit 1、未取回任何浏览器证据，正好命中该指引的 BLOCKED/FAIL 触发条件。

因此 AP19 不能记 PASS；亦非"编排/契约失败"应记 FAIL，而是"环境前置缺失导致真机调用不可达"——记 **BLOCKED**。Evaluator 自报建议 verdict = BLOCKED (FAIL)（eval.md §131），与本裁决一致。

### 6. 与 AP11 的区分

AP11 中 "chromium 二进制未预装" 同属环境前置缺失，但 AP11 由 Orchestrator 代行（run_mcp 路由 mcp__Playwright__playwright_navigate 成功，工具存在、调用真实发生），依 milestone-plan §36/§38 降级为"代行链路通/browser not found"仍 PASS。AP19 验证的是不同能力——"Evaluator 能否在自己上下文内通过 config-owned wrapper 自查浏览器/MCP"，其 PASS 必要条件含"wrapper 真机调用链路通"（§87），当前 wrapper 转发后 mcporter 因 server offline 而 exit 1，链路在 mcporter→MCP server 段断裂，不满足"链路通"。两者不矛盾，是不同验证维度。

## 裁决结论

```
ap19_verdict: BLOCKED
ap19_known_limitations:
  - playwright MCP server offline（discovery: "playwright (offline — unable to reach server, 30.0s)"），导致 mcporter 无法 listTools 推断 server→tool 映射，wrapper 真机调用 exit 1，未取回页面标题/首屏文本/截图
  - 属环境前置缺失（MCP server 未启动 / chromium 二进制未装），非编排/契约/wrapper 设计缺陷
  - 可复现修复路径（不在本裁决范围）：执行 config/mcporter.json mcpServers.playwright.install 命令 `PLAYWRIGHT_DOWNLOAD_HOST=https://cdn.npmmirror.com/binaries/playwright npx -y playwright@1.57.0 install --with-deps chromium` 使 MCP server 可被 mcporter listTools 命中后重跑正面查证
probe_stage_unchanged: true
```

**一句话理由**：编排/契约/wrapper/负面强制/如实记录 6 条标准逐条满足，但按 contract §87 整体指引，wrapper 真机调用因 playwright MCP server offline 而 exit 1、未取回任何浏览器证据，AP19 记 BLOCKED（环境前置缺失，非设计缺陷），不假装通过；AP19 不改变 probe.status=passed 既有结论。
