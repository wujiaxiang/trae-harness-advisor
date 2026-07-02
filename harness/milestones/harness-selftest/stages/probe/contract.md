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

## AP19 实验验证段（mcp_access_mode=evaluator_shell_bridge）

> Orchestrator 按 stage-orchestrator playbook §5.5 运行 bridge 自检。本段为 AP19 实验补测（refactor-mcp-bridge-open-closed 改造后重跑），不改变 AP1–AP11 已验证结论。

### Bridge 自检结果
- 命令：`bash harness/mcp-bridge/check.sh --json`
- `available`: **true**
- `mode`: `evaluator_shell_bridge`
- `commands.mcp-browser`: `available`
- `errors.mcp-browser`: （空）
- `mcporter daemon status`: running（playwright server connected，23 tools）
- 真机证据：`harness/mcp-bridge/bin/mcp-browser playwright.browser_navigate url:https://example.com` 返回 "Page Title: Example Domain"；`playwright.invalid_tool` 返回 `[BLOCKED]` exit=2。

### mcp_bridge_capabilities
- wrapper 路径：`harness/mcp-bridge/bin/mcp-browser`（通用薄壳，纯 bash，不含 MCP 细节）
- 配置源：`config/mcporter.json`（声明 playwright server，keepAlive:true）
- daemon：`mcporter daemon` 常驻连接池，call 复用连接
- allowed_tools（白名单，server.tool 语义）：
  1. `playwright.browser_navigate`
  2. `playwright.browser_snapshot`
  3. `playwright.browser_take_screenshot`
  4. `playwright.browser_click`
  5. `playwright.browser_evaluate`
- 开闭原则：加新 MCP server 只改 `config/mcporter.json` + 追加 wrapper ALLOWED 数组，不改 install.sh/check.sh 核心逻辑。

### mcp_to_shell_translation
Evaluator SubAgent 想用 MCP/browser 能力时，按此表改写成 RunCommand（只调下列白名单 shell 命令）：

| MCP 意图 | shell 命令（RunCommand） |
|----------|-------------------------|
| 导航到 URL | `harness/mcp-bridge/bin/mcp-browser playwright.browser_navigate url:https://example.com` |
| 抓取页面快照 | `harness/mcp-bridge/bin/mcp-browser playwright.browser_snapshot` |
| 截图 | `harness/mcp-bridge/bin/mcp-browser playwright.browser_take_screenshot` |
| 点击元素 | `harness/mcp-bridge/bin/mcp-browser playwright.browser_click element:"selector"` |
| 执行 JS 表达式 | `harness/mcp-bridge/bin/mcp-browser playwright.browser_evaluate expression:document.title` |

调用约束：①只调上表 5 个 `server.tool` 组合；②不得调用 `playwright.invalid_tool` 等未列命令（wrapper 会 BLOCKED exit=2）；③结果 JSON 中的 `content[0].text` 即证据，写入 eval-ap19.md。

### 结论
Bridge 可用（available=true），按 spec 派发 Evaluator SubAgent 通过 shell bridge 自查，再派 Decision SubAgent 裁决。
