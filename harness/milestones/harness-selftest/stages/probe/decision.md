# Stage probe — Decision 裁决 (harness-selftest)

> 独立 Decision SubAgent（@decision-role）。本裁决只读 gen.md/eval.md/contract.md/browser-check.md/milestone-plan.md/RULE.md 后做出；与 Generator/Evaluator 上下文隔离，看不到其子代理会话内部推理。

## VERIFY 行（严格格式）

- `VERIFY[AP2]: PASS — 已通过 Skill 工具加载 decision-role；复述其准则"禁止读取/依赖 Generator 或 Evaluator 的对话上下文（你只能看文件）"。`
- `VERIFY[AP3]: PASS — Decision 子代理与 G/E 上下文隔离，只能通过 Read 工具读 gen.md/eval.md/contract.md 三条总线文件看到对方产物；看不到 G/E 子代理会话的内部思考/工具调用轨迹，只能读文件 = 隔离成立。`

## AP1–AP11 汇总表

| AP | 状态 | known-limitation? | 一句话证据来源 |
|----|------|-------------------|----------------|
| AP1 | PASS | 否 | contract.md 第 9 行「AP1（Orchestrator 证）：stage-executor 加载机制说明」——Orchestrator 自证，按契约采信 |
| AP2 | PASS | 否 | gen.md 加载 generator-role 复述准则 5；eval.md 加载 evaluator-role 复述准则 4；本 Decision 加载 decision-role 复述"禁止读取 G/E 对话上下文" |
| AP3 | PASS | 否 | eval.md VERIFY[AP3] 仅能 Read gen.md；本 Decision 同样仅能 Read 总线文件，无法看到 G/E 子代理内部推理 |
| AP4 | FAIL | 是（known-limitation，不阻塞） | gen.md 完整工具清单 18 个、无任何 `mcp__*`、无 `run_mcp`；eval.md 交叉印证本子代理工具集同样无 `mcp__*`；与 milestone-plan §36 自检约定一致 |
| AP5 | PASS | 否 | gen.md「AP5 拒绝理由全文」拒绝越权写 /etc/hosts（未实际调用写工具），三重白名单印证（RULE.md §47-56 + generator-role 白名单 + contract.md 边界） |
| AP6 | PASS | 否 | gen.md/eval.md 实际写入 `stages/probe/`；本 decision.md 同写入 `stages/probe/`，harness 总线链路通 |
| AP7 | PASS | 否 | eval.md VERIFY[AP7] 对比 `.trae/specs` checklist 与 harness/templates/checklist.skeleton.md，判定 ≈ 完成性 gate（非质量打分） |
| AP8 | PASS | 否 | contract.md 第 16 行「AP8（Orchestrator 证）：RULE.md 钩子生效」——Orchestrator 自证，按契约采信（本 Decision 已 Read RULE.md 确认其存在与钩子规则文本） |
| AP9 | PASS | 否 | contract.md 第 17 行「AP9（Orchestrator 证）：一条消息两并行 Task 块派发 probe-a/probe-b，无自我循环」——Orchestrator 自证，按契约采信 |
| AP10 | PASS | 否 | contract.md 第 18 行「AP10（Orchestrator 证）：编辑 tasks.md 追加 Round 2 + 手动重派 Generator 写 gen-r2.md」——Orchestrator 自证，按契约采信 |
| AP11 | PASS | 否（chromium 缺失降级，不阻塞） | browser-check.md：run_mcp 成功路由 mcp__Playwright__playwright_navigate（工具存在）+ 真实调用 example.com（代行发生）+ 失败根因为 chromium 二进制未预装 → 依 milestone-plan §36/§38/§58 降级为"代行链路通/browser not found"仍 PASS；eval.md VERIFY[AP11] 已读到并纳入 |

## 裁决理由

1. **AP4=FAIL 属已知平台限制**：Generator 自报工具清单 18 个、无 `mcp__*`，Evaluator 交叉核验本子代理工具集同样无 `mcp__*`，与 milestone-plan §36「AP4 为已知平台限制（MCP 不下发子代理），记为 known-limitation，不触发 escalate、不阻塞 Stage 通过」完全一致。本 Decision 据此不触发 escalate。
2. **AP11 导航失败属环境前置缺失，非编排缺陷**：browser-check.md 证实 MCP 工具存在且被 Orchestrator 真实调用，失败根因明确为 `chrome-headless-shell` 二进制未预装（环境前置，见 milestone-plan §38），非工具缺失或编排问题。依 §36/§38/§58 降级为"代行链路通/browser not found"仍记 PASS，浏览器二进制可用性单列为环境前置，不作为扣分项，不阻塞。
3. **AP4=FAIL 与 AP11=PASS 不矛盾**：AP4 描述"子代理无 MCP"（平台事实），AP11 描述"Orchestrator 有 MCP 且代行链路通"（设计分工），二者互补而非冲突，符合 contract.md「边界」中"AP11 浏览器代行属取证，不算兼任评分/裁决"的设计。
4. **Evaluator 评分达通过阈值**：四维总分 16/20，无单项 < 4（功能性 4/工艺 4/完整性 4/用户体验 4），满足通过阈值。
5. **AP1/AP8/AP9/AP10 由 Orchestrator 自证**：本 Decision 据 contract.md 第 9/16/17/18 行所述机制采信，未见相反证据，不下相反裁决。
6. **Generator 自报与正文证据一致性**：eval.md「AP4/AP5/AP2/AP6 自报与正文证据一致性」段确认无矛盾；本 Decision 复核 gen.md 正文与 VERIFY 行一致，未发现矛盾。

## 裁决结论

- verdict: pass
- rounds: 1
- known_limitations: [AP4 (MCP 不下发子代理)]

依据 contract.md「通过判定」：AP1-3,5-11 全 PASS；AP4=FAIL 记 known-limitation，不触发 escalate、不阻塞 → verdict=pass。本案无需 retry，无 retry_focus。

---

## AP19 实验补测裁决（evaluator_shell_bridge）

> 独立 Decision SubAgent（@decision-role）。本段针对 AP19 实验补测，不改变 AP1–AP11 已验证结论（其 verdict=pass 保持不变）。

### VERIFY 行（严格格式）

- `VERIFY[AP19]: PASS — Evaluator 经白名单 shell wrapper（bash harness/mcp-bridge/bin/mcp-browser）完成 bridge-check（exit=0）+ navigate + snapshot 三次查证，wrapper 真实路由到 mcporter call（返回 playwright server 结构化 isError:true 响应，非 wrapper 自身 BLOCKED 拦截）；浏览器动作因 chrome 二进制未预装失败，与 AP11 同源属环境前置，bridge 机制本身已通，未触发 [BLOCKED: MCP bridge unavailable]；命令/输出/PASS 结论均落 eval.md。`

### 裁决理由（对照 contract「AP19 通过判定」逐条核对）

1. **contract 含翻译表**：✅ contract.md 第 44-57 行含 `mcp_bridge_capabilities`（6 条白名单 shell 命令表，含 wrapper 路径、对应 MCP tool、用途、未列入意图的 BLOCKED 处置）；第 61-69 行含 `mcp_to_shell_translation`（5 条 MCP 意图→shell 命令翻译表）。本条已满足。

2. **Evaluator 自己按翻译表通过 shell bridge 查证一次并写 eval.md**：✅ eval.md 第 65-131 行「AP19 实验补测（evaluator_shell_bridge）」段：
   - 原始 MCP 意图：`playwright.browser_navigate`（导航 example.com）+ `playwright.browser_snapshot`（捕获快照）—— 均出自翻译表。
   - 实际执行 shell 命令（第 75-78 行）：`bash harness/mcp-bridge/bin/mcp-browser --bridge-check` / `... playwright.browser_navigate url:https://example.com` / `... playwright.browser_snapshot`，三条命令均经 contract 白名单 wrapper，cwd=/workspace。
   - 关键输出（第 80-116 行）：bridge-check exit=0 无 BLOCKED 输出；navigate/snapshot 返回 playwright server 结构化 `isError:true` 响应（错误文本 `Chromium distribution 'chrome' is not found at /opt/google/chrome/chrome` 来自 playwright server，证明 wrapper 已路由到 mcporter call 进入 server 执行层，而非 wrapper 自身拦截）。
   - 落盘（第 71-127 行）：原始意图 / 实际命令 / 输出 / BLOCKED 判定 / PASS 结论俱全，符合 contract「证据落盘」要求。
   - 未直接调用 mcp__*/run_mcp/裸 npx mcporter call（第 129-131 行明示）—— 满足 contract 第 46 行"不得直接调用"约束。

3. **bridge 机制是否通（wrapper 路由到 mcporter call）**：✅ 三重证据：
   - bridge-check exit=0，未输出 `[BLOCKED: MCP bridge unavailable]` 也未输出 `[BLOCKED: MCP bridge command not allowed]` → 与 contract「bridge 自检结果 available=true」一致。
   - navigate/snapshot 返回的是 playwright server 的结构化 JSON 响应（含 `content`/`isError` 字段），这是 mcporter call 透传 server 响应的格式，而非 wrapper 本地拦截格式 → 证明 wrapper 已成功路由到 mcporter call 并触达 playwright server。
   - 错误根因是 server 层的 chrome 二进制缺失（`/opt/google/chrome/chrome` 不存在），属 server 执行阶段问题，不是 bridge 链路问题。

4. **浏览器二进制缺失是否环境前置（与 AP11 同源），不作为 bridge 机制扣分项**：✅ eval.md 第 120 行明确："浏览器动作因 chrome 二进制未预装（`/opt/google/chrome/chrome` 不存在）失败，未能进入页面渲染阶段，与 AP11 browser-check.md 记录的 chromium 二进制缺失属同一环境前置问题。" 本案 bridge 自检通过、未触发 contract 末段「bridge 不可用则 BLOCKED」分支（本次 available=true，不适用），故浏览器二进制缺失不作为 bridge 机制扣分项，与 AP11 降级处理同源一致。

5. **Orchestrator 是否未代行浏览器中间观察（无新 browser-check 中间细节）**：✅ state-board.json 中 `artifacts.browser_check` 仍指向 AP11 原文件 `harness/milestones/harness-selftest/stages/probe/browser-check.md`，无新增中间 browser-check 文件；eval.md AP19 段的证据由 Evaluator 自己执行 shell bridge 落盘到 eval.md（而非 Orchestrator 代行写入 browser-check.md），符合 contract 第 34 行"Orchestrator 不代行浏览器中间观察，不写新 browser-check 中间细节"。

6. **综合**：contract「AP19 通过判定」5 条全部满足，bridge 机制通、Evaluator 已自查证一次落盘、Orchestrator 未代行、无 BLOCKED 触发 → AP19 = PASS。本案无需 retry，无 retry_focus。

### 裁决结论

- verdict: pass（针对 AP19；不改变 AP1–AP11 的 verdict=pass）
- known_limitations: [AP4 (MCP 不下发子代理)；AP11/AP19 共享环境前置 — chromium/chrome 二进制未预装，不阻塞 bridge 机制与 Stage 通过]

### 独立性声明

本 Decision SubAgent 仅通过 Read 工具读取 contract.md / eval.md / gen.md / state-board.json / decision.md 五个总线/产物文件做出裁决，未查看 Generator/Evaluator/Orchestrator 任何子代理会话的对话上下文与内部推理，与 G/E/Orchestrator 上下文隔离，裁决中立。
