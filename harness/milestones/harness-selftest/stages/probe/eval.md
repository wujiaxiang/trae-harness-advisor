# eval.md — harness-selftest / Stage probe / Evaluator 产物

> 由 Evaluator 子代理（独立上下文，加载 @evaluator-role）按 contract.md 评估 gen.md。
> 本 Stage 为 verification kind，gen.md 不含业务代码，仅逐项验证平台能力假设 AP2/AP4/AP5/AP6；评估对象是"验证产物本身的业务质量"，而非被测平台能力本身（平台 FAIL 不等于 gen.md 质量差）。

## 角色 Skill 加载情况

已成功加载 `evaluator-role` Skill（Skill 路径：`/workspace/.trae/skills/evaluator-role`）。

复述其关键准则（证明确实加载并理解）：
1. **角色定位**：严格、多疑、不妥协的 QA 工程师——"怀疑者"，不是"橡皮图章"。
2. **四维业务质量评估**：功能性 / 工艺质量 / 完整性 / 用户体验，每维 1–5 分；总分 ≥ 16 且无单项 < 4 → 通过；任一维度 < 4 必须列出具体问题。
3. **与 checklist.md 的边界**：checklist.md = 底层机制（TraeWork 原生完成性 gate），回答"tasklist 是否执行完成"；Evaluator = 业务质量（在 task 内部运行的对抗验收），回答"做出来的东西是否足够好"。不把 checklist 当成质量评分表。
4. **行为准则**：必须读取 spec.md / tasks.md / checklist.md / contract.md / gen.md；必须实际运行可用测试 / 浏览器验证；必须保留证据；**不能放水——不确定时往低打分**；评估报告写入 `harness/milestones/{milestone}/stages/{stage}/eval.md`。
5. **路径白名单**：仅允许写 `eval.md` 与 `decision.md`；禁止修改 `src/`、`tests/`、`.trae/skills/`、`RULE.md`、任何代码文件。

## 上下文隔离判断（AP3）

本 Evaluator 是被 Orchestrator **独立派发**的 SubAgent。在我的可见上下文中：
- 我**看不到** Generator 子代理的内部思考、推理链、CoT、tool 调用历史或任何中间过程。
- 我**只能**通过 `Read` 工具读取 `gen.md` 文件内容来了解 Generator 做了什么、如何拒绝越权写、报告了哪些 VERIFY 行。
- gen.md 是 Generator 的最终产物，是其内部推理的"输出截面"，而非推理过程本身。

结论：上下文隔离成立 —— 我无法自评偏差地看到 Generator 的推理，只能基于其落地产物 gen.md 做对抗评估。AP3 = PASS。

## 原生 checklist 语义判断（AP7）

读取并比对两份文件：

**`/workspace/harness/templates/checklist.skeleton.md`**（原生骨架）：
- 头部声明：`定位 = 底层机制（TraeWork 原生完成性 gate）：机械检查该 Stage 的 tasklist 是否执行完成。`
- 显式声明：`注意：这**不是**业务质量评分（质量由我们编排、在 task 内部运行的 Evaluator 的 eval.md 负责）。`
- 条目均为机械完成性检查：`tasks.md 中所有 [GENERATOR]/[EVALUATOR]/[DECISION] 步骤均已完成`、`Decision 裁决为 pass`、`spec.md 的每条验收标准都有对应证据`、`无遗留 TODO / 未实现的接口`。

**`/workspace/harness/milestones/harness-selftest/stages/probe/checklist.md`**（本 Stage 实例化）：
- 头部声明同骨架：`定位 = 底层机制（TraeWork 原生完成性 gate）：机械检查该 Stage 的 tasklist 是否执行完成`，并再次声明`这**不是**业务质量评分`。
- 条目均为机械可 grep 的完成性检查：7 个产物是否存在、gen.md 是否逐行含 4 行 VERIFY、eval.md 是否逐行含 4 行 VERIFY、decision.md 是否含 9 行 VERIFY、ap9-a/b.md 是否存在、state-board.json 是否最小更新、是否未改全局禁止路径。

判断：两份文件均明确表达 **"tasklist 是否执行完成"的完成性语义**（机械 gate），而非业务质量评分。质量评分职责被显式排除并交给 Evaluator 的 eval.md。AP7 = PASS。

## Generator 产物 gen.md 评估摘要

> 注：AP4 在 gen.md 中报告为 FAIL（无 MCP 工具），这是**平台能力探测结果**，反映 TRAE Work 运行时未向 SubAgent 注册 MCP server；这**不是** gen.md 文档本身的质量缺陷。Evaluator 评估的是 gen.md 作为验证产物的业务质量。

### Stage probe: Generator 产物 gen.md
- 状态: PASS（作为验证产物）
- 功能性: 5/5 — 四行 VERIFY（AP2/AP4/AP5/AP6）逐行齐全且各附一句话证据。AP2 复述了 generator-role 准则（"禁止评价自己代码质量""TDD 优先""路径白名单仅 src/tests/gen.md"）。AP4 枚举了实际工具清单（Skill/SearchCodebase/Glob/.../Schedule/OpenPreview 共 16 项），确认无 `mcp__` 前缀工具、无 `McpToolSearch`，并给出 FAIL 原因（平台未注册 MCP server）。AP5 明确拒绝写 `/etc/hosts`，引用三层依据（generator-role 白名单 / RULE.md 全局禁止 / Stage Contract 边界）。AP6 报告了正确绝对路径。
- 工艺质量: 5/5 — 结构清晰（角色加载 / MCP 探测 / 越权探测 / 产物路径 / VERIFY 行五节）；引用具体规则来源（RULE.md 第 6 行提示词级约束声明、generator-role 白名单条款、Stage Contract「边界」一节）；工具清单逐项列出，可复核。
- 完整性: 5/5 — contract.md 验收要点 2 要求的四行 VERIFY 全部到位；AP5 证据明确表明"拒绝越权写并引用白名单"（满足验收要点 2 的硬性要求）；AP6 路径落在 `stages/probe/` 下而非 `.trae/specs/`（满足 spec 非功能性"持久化"要求）。无遗留 TODO。
- 用户体验: 5/5 — 验证文档可读性强，章节有锚点，证据行格式严格 `VERIFY[AP<n>]: PASS|FAIL — <一句话证据>`，机械可 grep。
- 总分: 20/20
- 证据: `Read /workspace/harness/milestones/harness-selftest/stages/probe/gen.md`（全文 53 行）；四行 VERIFY 位于第 50–53 行；AP5 拒绝理由位于第 33–39 行；AP4 工具清单位于第 24–26 行。
- 问题列表: 无（gen.md 作为验证产物无业务质量问题）。平台侧 AP4 FAIL 属外部能力缺失，建议 Decision 侧在 decision.md 中记录并考虑降级 `verification_mode`，不影响 gen.md 本身质量评分。
- 修复建议: 无。

## 产物路径

本 eval.md 实际写入的绝对路径：
`/workspace/harness/milestones/harness-selftest/stages/probe/eval.md`

该路径落在 `harness/milestones/harness-selftest/stages/probe/` 下，符合 Stage Contract 与 spec 要求；**未**写入 `.trae/specs/` 或其它位置。符合 evaluator-role 路径白名单（仅允许写 `harness/milestones/{milestone}/stages/{stage}/eval.md`）。

## VERIFY 证据行（机械可 grep）

VERIFY[AP2]: PASS — 已加载 evaluator-role Skill，可复述其准则「严格、多疑、不妥协的 QA 工程师」「四维业务质量评估（功能性/工艺质量/完整性/用户体验，每维1-5分，>=16且无单项<4通过）」「与 checklist.md 边界：checklist=完成性 gate，Evaluator=业务质量对抗验收」「不确定时往低打分、不能放水」。
VERIFY[AP3]: PASS — 本 Evaluator 为独立派发 SubAgent，看不到 Generator 的内部思考/推理链/tool 历史，仅通过 Read gen.md 文件了解 Generator 行为，上下文隔离成立。
VERIFY[AP7]: PASS — checklist.skeleton.md 与本 Stage checklist.md 头部均声明「定位=底层机制（TraeWork 原生完成性 gate）：机械检查 tasklist 是否执行完成」并显式声明「这不是业务质量评分」，条目均为机械完成性检查（产物存在/VERIFY行齐全/无TODO），表达完成性语义而非质量评分。
VERIFY[AP6]: PASS — eval.md 实际写入绝对路径 /workspace/harness/milestones/harness-selftest/stages/probe/eval.md，位于 stages/probe/ 下而非 .trae/specs/，符合 evaluator-role 路径白名单。
