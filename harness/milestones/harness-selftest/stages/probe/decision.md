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
