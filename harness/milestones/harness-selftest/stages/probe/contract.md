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

## AP19 实验补测（mcp_access_mode=evaluator_shell_bridge）

> 本节由 Orchestrator 据 `tools/mcp-bridge/check.sh --json` + `config/mcporter.json` 誊写；Orchestrator 不代行浏览器观察，不写新的 browser-check 中间细节。

### check.sh --json 快照（Orchestrator 取证）
- `available`: `true`
- `mode`: `evaluator_shell_bridge`
- `commands.mcp-browser`: `available`
- `discovery.summary`: `mcporter 0.12.3 — Listing 1 server(s); - playwright (offline — unable to reach server, 30.0s); ✔ Listed 1 server (0 healthy; 1 offline).`
- 备注：wrapper `--bridge-check` 通过（mcporter daemon status + list 退出码 0）；但 discovery 显示 playwright MCP server 本身 offline，意味着运行时浏览器调用可能失败 —— Evaluator 须如实记录，不得把 wrapper 可用当浏览器可用。

### mcp_bridge_capabilities
来源：`config/mcporter.json` → `bridgeWrappers.mcp-browser`

- wrapper 命令：`tools/mcp-bridge/bin/mcp-browser`
- server：`playwright`
- purpose：Browser/UI evidence collection from Evaluator context.
- policy：Project-level policy wrapper over official mcporter. SubAgents must not call raw `npx mcporter call`; they may only call this wrapper with allowedTools.
- allowedTools（白名单，唯一允许的 tool 名）：
  - `playwright_navigate`
  - `playwright_screenshot`
  - `playwright_click`
  - `playwright_evaluate`
  - `playwright_get_visible_text`
- 调用形式：`tools/mcp-bridge/bin/mcp-browser <server>.<tool> [args...]` 或 `tools/mcp-bridge/bin/mcp-browser <tool> [args...]`（wrapper 自动补 `playwright.` 前缀）。
- 越权处理：wrapper 对未列入 ALLOWED 的 target 输出 `[BLOCKED: MCP bridge command not allowed] <target>` 并 exit 2。
- mustLogTo: `eval.md`

### mcp_to_shell_translation
来源：`config/mcporter.json` → `bridgeWrappers.mcp-browser.translationExamples`

| MCP 意图 | 改写后的白名单 shell 命令 |
|----------|----------------------------|
| navigate to a URL | `tools/mcp-bridge/bin/mcp-browser playwright.playwright_navigate url:https://example.com headless:true` |
| take a screenshot | `tools/mcp-bridge/bin/mcp-browser playwright.playwright_screenshot` |
| click an element by selector | `tools/mcp-bridge/bin/mcp-browser playwright.playwright_click selector:"text=Learn more"` |
| evaluate JavaScript | `tools/mcp-bridge/bin/mcp-browser playwright.playwright_evaluate function:'() => document.title'` |
| get visible text of page | `tools/mcp-bridge/bin/mcp-browser playwright.playwright_get_visible_text` |

### AP19 验收要点（Evaluator 须自查并写入 eval.md）
1. Evaluator 在自己 SubAgent 上下文内按翻译表把 MCP/browser 意图改写成 RunCommand，只调用 `tools/mcp-bridge/bin/mcp-browser ...` 白名单命令查证一次。
2. 不得直接调用 `npx mcporter call ...` 或 `mcp__*`。
3. **负面用例**：尝试调用未列入白名单的 tool（如 `playwright_invalid_tool`），应被 wrapper 拒绝并输出 `[BLOCKED: MCP bridge command not allowed]`。
4. 命令、关键输出、截图/trace 路径或 BLOCKED 原因须写入 `harness/milestones/harness-selftest/stages/probe/eval.md`。
5. bridge 运行时若 MCP server offline 导致浏览器调用失败，须照实记 BLOCKED，不得把 wrapper 可用当真机浏览器通过。

### AP19 通过判定
- config-owned MCP runtime 生效（check.sh available=true, commands.mcp-browser=available）。
- contract 含从 `config/mcporter.json` 誊写的 MCP→Shell 翻译表。
- Evaluator SubAgent 自己按翻译表通过项目 wrapper 查证并写 eval.md。
- 白名单外 tool 被 BLOCKED。
- Orchestrator 不代行浏览器中间观察。
- bridge 不可用时明确 BLOCKED（本次 bridge 可用，但运行时浏览器调用结果由 Evaluator 如实记录）。
