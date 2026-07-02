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

> 实验增强，不改变 AP1–AP11 已验证结论。Orchestrator 只写能力与翻译表；Evaluator SubAgent 在自己上下文内按翻译表把 MCP/browser 意图改写成白名单 shell 命令查证；Orchestrator 不代行浏览器中间观察，不写新 browser-check 中间细节。

### bridge 自检结果（harness/mcp-bridge/check.sh --json）

- `available`: `true`
- `mode`: `evaluator_shell_bridge`
- `config`: `/workspace/config/mcporter.json`
- `commands.mcp-browser`: `available`
- discovery: mcporter 0.12.3，1 server（playwright，23 tools，healthy）

### mcp_bridge_capabilities

Evaluator SubAgent 只能调用下列白名单 shell 命令（wrapper：`harness/mcp-bridge/bin/mcp-browser`）。不得直接调用 `mcp__Playwright__*` / `run_mcp` / 裸 `npx mcporter call`。

| 白名单 shell 命令 | 对应 MCP tool | 用途 |
|------|------|------|
| `harness/mcp-bridge/bin/mcp-browser playwright.browser_navigate url:{url}` | playwright.browser_navigate | 导航到 URL |
| `harness/mcp-bridge/bin/mcp-browser playwright.browser_snapshot` | playwright.browser_snapshot | 捕获浏览器快照 |
| `harness/mcp-bridge/bin/mcp-browser playwright.browser_take_screenshot` | playwright.browser_take_screenshot | 截图 |
| `harness/mcp-bridge/bin/mcp-browser playwright.browser_click element:"{label}" ref:{ref}` | playwright.browser_click | 点击快照中元素 |
| `harness/mcp-bridge/bin/mcp-browser playwright.browser_evaluate 'function=() => ...'` | playwright.browser_evaluate | 在页面执行 JS（参数名为 `function`，非 `expression`） |
| `harness/mcp-bridge/bin/mcp-browser --bridge-check` | — | bridge daemon 存活自检（非浏览器动作） |

- 未列入上表的 MCP 意图：Evaluator 输出 `[BLOCKED: MCP bridge command not allowed]`。
- bridge 自检失败或命令不可用：Evaluator 输出 `[BLOCKED: MCP bridge unavailable]`。
- 证据落盘：每次调用后写入 `eval.md`（原始 MCP 意图 / 实际 shell 命令 / 关键输出 / 截图或 trace 路径 / PASS|FAIL|BLOCKED 结论）。

### mcp_to_shell_translation

| MCP 意图 | 改写后的 shell 命令（RunCommand） |
|------|------|
| navigate to a URL | `bash harness/mcp-bridge/bin/mcp-browser playwright.browser_navigate url:https://example.com` |
| capture a browser snapshot | `bash harness/mcp-bridge/bin/mcp-browser playwright.browser_snapshot` |
| take a screenshot | `bash harness/mcp-bridge/bin/mcp-browser playwright.browser_take_screenshot` |
| click an element from a snapshot | `bash harness/mcp-bridge/bin/mcp-browser playwright.browser_click element:"Learn more" ref:f2e6` |
| evaluate JavaScript | `bash harness/mcp-bridge/bin/mcp-browser playwright.browser_evaluate 'function=() => document.title'` |

### AP19 通过判定

- contract 含 `mcp_bridge_capabilities` + `mcp_to_shell_translation`（本段已满足）。
- Evaluator SubAgent 自己按翻译表通过 shell bridge 查证一次并写 eval.md（命令、输出、PASS|FAIL|BLOCKED）。
- Decision SubAgent 独立裁决 AP19，写 `VERIFY[AP19]: PASS|FAIL|BLOCKED — 一句话证据`。
- Orchestrator 不代行浏览器中间观察，不写新 browser-check 中间细节。
- bridge 不可用则 `[BLOCKED: MCP bridge unavailable]`，VERIFY[AP19]=FAIL/BLOCKED，停止（本次 available=true，不适用）。
