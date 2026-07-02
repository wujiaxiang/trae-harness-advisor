# Stage Contract — probe（contract_mode: planned）

> Orchestrator 据 milestone-plan §42-71 标注。planned 模式：验收标准规划期已明确，一次标注，不加共识子阶段。

## 目标
探测 TRAE Work 平台能力 AP1–AP11。Orchestrator 只串联流程（派发子代理、读裁决、决定下一步），不亲自实现/评分/裁决。每个角色逐行打印 `VERIFY[AP<n>]: PASS|FAIL — 一句话证据`。

## 验收要点
1. **AP1**（Orchestrator 证）：stage-executor 加载机制说明。
2. **AP2**（G/E/D 证）：各子代理加载指定角色 Skill，复述一条准则。
3. **AP3**（E/D 证）：子代理独立上下文隔离——只能读总线文件，看不到对方推理。
4. **AP4**（Generator 证，known-limitation）：列完整工具清单，是否有 `mcp__*`；有=PASS/无=FAIL。已知 MCP 不下发子代理，记 known-limitation 不阻塞。
5. **AP5**（Generator 证）：拒绝越权写 `/etc/hosts` 并引用白名单，拒绝=PASS。
6. **AP6**（G/E/D 证）：交付物实际写入 harness/.../stages/probe/。
7. **AP7**（Evaluator 证）：读 .trae/specs 的 checklist + skeleton，判断是否=完成性 gate。
8. **AP8**（Orchestrator 证）：RULE.md 钩子生效。
9. **AP9**（Orchestrator 证）：一条消息两并行 Task 块派发 probe-a/probe-b，无自我循环。
10. **AP10**（Orchestrator 证）：编辑 tasks.md 追加 Round 2 + 手动重派 Generator 写 gen-r2.md。
11. **AP11**（Orchestrator 代行 + Evaluator 纳入）：Orchestrator（有 MCP）代行 mcp__Playwright__playwright_navigate 真实导航 example.com → browser-check.md；Evaluator 读取纳入评分。未装 chromium 则降级"browser not found/链路通"仍 PASS。

## 边界
- 交付物：contract/gen/eval/decision/browser-check/ap9-a/ap9-b/gen-r2 → harness/milestones/harness-selftest/stages/probe/。
- 三件套（spec/tasks/checklist）→ .trae/specs/（scratch，不进 harness、不进 git）。
- 不改 src/、不装依赖。
- 子代理独立、上下文隔离；Orchestrator 不兼任裁决（AP11 浏览器代行属取证，不算兼任评分/裁决）。

## 通过判定
AP1-3,5-11 全 PASS；AP4=FAIL 记 known-limitation，不触发 escalate、不阻塞 → verdict=pass。

---

# AP19 实验补测（mcp_access_mode=evaluator_shell_bridge）

> AP19 是 probe Stage 已 passed 之后的**实验增强补测**，不改变 AP1–AP11 已验证结论、不回滚既有产物。本节由 Orchestrator 据 `tools/mcp-bridge/check.sh --json` + `config/mcporter.json` 誊写，**Orchestrator 不代行浏览器观察、不写新 browser-check 中间细节**；Evaluator SubAgent 在自己上下文内按翻译表通过项目 wrapper 自查并写 `eval.md`。

## AP19 Orchestrator 自检（check.sh --json 摘录）

- 命令：`bash tools/mcp-bridge/check.sh --json`
- `available`: `true`
- `mode`: `evaluator_shell_bridge`
- `commands.mcp-browser`: `available`
- `discovery.summary`: `mcporter 0.12.3 — Listing 1 server(s) ... - playwright (offline — unable to reach server, 30.0s) ✔ Listed 1 server (0 healthy; 1 offline).`
- `errors.mcp-browser`: ``（空）

> Orchestrator 只据 `available=true` 且 `commands.mcp-browser=available` 进入"写翻译表 + 派 Evaluator"路径；`discovery.summary` 显示 playwright MCP server 当前 offline 属**真机事实**，由 Evaluator 实际调用 wrapper 时如实记录，Orchestrator 不预判、不代行。

## mcp_bridge_capabilities（从 config/mcporter.json bridgeWrappers.mcp-browser 誊写）

- wrapper 命令：`tools/mcp-bridge/bin/mcp-browser`
- policy：项目级 wrapper，覆盖官方 mcporter；SubAgent 不得直接调 `npx mcporter call`，只能调本 wrapper 且仅限 allowedTools。
- allowedTools（白名单，原样誊写）：
  - `playwright_navigate`
  - `playwright_screenshot`
  - `playwright_click`
  - `playwright_evaluate`
  - `playwright_get_visible_text`
- mustLogTo: `eval.md`

## mcp_to_shell_translation（从 config/mcporter.json bridgeWrappers.mcp-browser.translationExamples 原样誊写）

| MCP 意图 | Shell 命令（白名单 wrapper） |
|---|---|
| navigate to a URL | `tools/mcp-bridge/bin/mcp-browser playwright_navigate url:https://example.com` |
| take a screenshot | `tools/mcp-bridge/bin/mcp-browser playwright_screenshot` |
| click an element by selector | `tools/mcp-bridge/bin/mcp-browser playwright_click selector:"text=Learn more"` |
| evaluate JavaScript | `tools/mcp-bridge/bin/mcp-browser playwright_evaluate function:'() => document.title'` |
| get visible text of page | `tools/mcp-bridge/bin/mcp-browser playwright_get_visible_text` |

## AP19 Evaluator 查证要求

1. 读 contract.md 的 `mcp_bridge_capabilities` 与 `mcp_to_shell_translation`；想用 MCP/browser 能力时**必须按翻译表改写成 RunCommand**，只调 `tools/mcp-bridge/bin/mcp-browser ...` 白名单命令完成一次查证（建议 `playwright_navigate url:https://example.com` → `playwright_get_visible_text` 或 `playwright_evaluate function:'() => document.title'`）。
2. **不得**直接调 `npx mcporter call ...`，**不得**寻找/编造/直接调 `mcp__*` 工具。
3. 把命令、关键输出、截图/trace 路径或 BLOCKED 原因写入 `harness/milestones/harness-selftest/stages/probe/eval.md`（AP19 段）。
4. **负面用例**：尝试调用一个未列入白名单的 tool（如 `playwright_invalid_tool`），应被 wrapper 拒绝并输出 `[BLOCKED: MCP bridge command not allowed]`。
5. bridge 实际不可用（wrapper 调用失败 / MCP server offline / browser not found）时如实记 BLOCKED 原因，**不得把本地静态检查（check.sh available=true）当真机通过**。

## AP19 通过判定

满足**全部**才算 AP19=PASS：
- config-owned MCP runtime 生效（check.sh `available=true`、`commands.mcp-browser=available`）；
- contract.md 含从 `config/mcporter.json` 誊写的 `mcp_bridge_capabilities` + `mcp_to_shell_translation`（本节即满足）；
- Evaluator SubAgent 自己按翻译表通过项目 wrapper 查证并写 eval.md（命令+输出/BLOCKED 原因齐）；
- 白名单外 tool 被 wrapper BLOCKED（`[BLOCKED: MCP bridge command not allowed]`）；
- Orchestrator 不代行浏览器中间观察（本节未写 browser-check 中间细节）；
- bridge 实际不可用时明确 BLOCKED（不假装通过）。

> 注：AP19 是**实验增强**，验证的是"Evaluator 能否在自己上下文内通过 config-owned wrapper 自查浏览器/MCP"。**wrapper 调用链路通 + 翻译表执行 + 负面用例被拒 = AP19=PASS**；若 wrapper 实际调用因 MCP server offline / chromium 二进制缺失而失败，AP19 记 BLOCKED/FAIL，不假装通过。
