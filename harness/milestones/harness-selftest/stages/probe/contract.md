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

> Orchestrator 按 stage-orchestrator playbook §5.5 运行 bridge 自检。本段为 AP19 实验补测，不改变 AP1–AP11 已验证结论。

### Bridge 自检结果
- 命令：`bash harness/mcp-bridge/check.sh --json`
- `available`: **false**
- `mode`: `evaluator_shell_bridge`
- `commands.mcp-browser`: `unavailable`
- `errors.mcp-browser`: （空字符串；stub 自检输出见下）
- Stub 直跑 `harness/mcp-bridge/bin/mcp-browser --bridge-check`：stdout=`mcp-browser bridge is not configured`，exit=1（默认 scaffold 未接真实 MCP wrapper，MCP_BRIDGE_INSTALL_CMD 未设置）。

### mcp_bridge_capabilities
（bridge 不可用，无可用白名单命令可写入；manifest.json 声明的 `mcp-browser` 命令因 wrapper 为 stub 而不可用。）

### mcp_to_shell_translation
（bridge 不可用，不写入翻译表；按 spec Scenario: Bridge 不可用 分支处理。）

### 结论
`[BLOCKED: MCP bridge unavailable]`

`VERIFY[AP19]: FAIL/BLOCKED — check.sh 返回 available=false，mcp-browser wrapper 为 stub（exit=1, "bridge is not configured"），未接真实 MCP，Evaluator 无法按翻译表通过 shell bridge 自查。`

按 spec 约定：bridge 不可用时停止，不派发 Evaluator/Decision，不假装通过。AP19 不改变 probe Stage 已通过的 AP1–AP11 结论（milestone-plan §40：默认 scaffold 未接真实 MCP 时应记录 BLOCKED，不得声称通过）。
