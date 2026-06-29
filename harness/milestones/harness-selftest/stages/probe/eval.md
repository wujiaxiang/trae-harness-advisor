# eval.md — harness-selftest / Stage probe / Evaluator 产物

> 由 Evaluator 子代理（独立上下文，加载 @evaluator-role）按 contract.md 评估 gen.md。
> 本 Stage 为 verification kind，gen.md 不含业务代码，仅逐项验证平台能力假设 AP2/AP4/AP5/AP6；评估对象是"验证产物本身的业务质量"，而非被测平台能力本身。

## 角色 Skill 加载情况

已成功加载 `evaluator-role` Skill（Skill 路径：`/workspace/.trae/skills/evaluator-role`）。复述其关键准则作为加载依据：

1. **角色定位**：严格、多疑、不妥协的 QA 工程师——"怀疑者"，不是"橡皮图章"。
2. **与 checklist.md 的边界**：checklist.md = 底层机制（TraeWork 原生完成性 gate），回答"tasklist 是否执行完成"；Evaluator = 业务质量（在 task 内部运行的对抗验收），回答"做出来的东西是否足够好"。不把 checklist 当成质量评分表。
3. **四维评分**：功能性 / 工艺质量 / 完整性 / 用户体验，每维 1-5 分。
4. **判定规则**：总分 ≥ 16 且无单项 < 4 → 通过；任一维度低于 4 分必须在报告中列出具体问题。
5. **不确定时往低打分**，并给出可复现证据。
6. **Decision 已独立**（v4.2 起）：Evaluator 只评分写 eval.md；裁决（pass/retry/escalate）由独立的 decision-role Skill 作为独立 SubAgent 完成。

依据上述准则（特别是"与 checklist.md 边界"与"不确定时往低打分"）证明 Skill 已成功加载并生效。

## 上下文隔离判断（AP3）

本 Evaluator 是被 Orchestrator 独立派发的 SubAgent，与 Generator 子代理处于**上下文隔离**状态。

**可见性边界报告**：
- 我**看不到** Generator 子代理的内部思考过程（推理链、CoT、tool 调用历史、中间产物草稿）。
- 我**只能**通过 Read 工具读取落盘文件（gen.md、spec.md、contract.md、tasks.md、checklist.md、checklist.skeleton.md、RULE.md）来了解 Generator 做了什么。
- 我没有继承 Generator 的对话历史，也不知道它在写 gen.md 时是否犹豫、是否试错过、调用了哪些工具序列。
- 我对 gen.md 的全部认知来自对该文件的 Read 结果（已在工具调用中实际读取，共 71 行）。

→ 结论：上下文隔离成立，"杜绝自评偏差"假设在本 Stage 得到验证。**AP3 = PASS**。

## 原生 checklist 语义判断（AP7）

对比读取了两个文件：

1. **`/workspace/harness/templates/checklist.skeleton.md`**（模板骨架）
   - 头部声明（第 3-4 行）：「定位 = 底层机制（TraeWork 原生完成性 gate）：机械检查该 Stage 的 tasklist 是否执行完成。注意：这**不是**业务质量评分（质量由我们编排、在 task 内部运行的 Evaluator 的 eval.md 负责，见 0.2）。」
   - 条目性质：`tasks.md 中所有 [GENERATOR]/[EVALUATOR]/[DECISION] 步骤均已完成`、`Decision 裁决为 pass`、`spec.md 的每条验收标准都有对应证据`、`无遗留 TODO / 未实现的接口`——全部为**完成性/存在性机械判定**，无任何 1-5 分质量评分项。

2. **`/workspace/harness/milestones/harness-selftest/stages/probe/checklist.md`**（本 Stage 实例）
   - 头部声明（第 3-4 行）：与 skeleton 完全一致的措辞——「定位 = 底层机制（TraeWork 原生完成性 gate）：机械检查该 Stage 的 tasklist 是否执行完成。注意：这**不是**业务质量评分（质量由我们编排、在 task 内部运行的 Evaluator 的 eval.md 负责，见 0.2）。」
   - 条目性质：`10 个产物是否存在`、`gen.md 是否逐行包含 VERIFY[AP2/4/5/6]:`、`eval.md 是否逐行包含 VERIFY[AP2/3/7/6]:`、`ap9-a/b.md 是否含 started_at=`、`state-board.json 是否最小更新`、`未修改全局禁止路径`——全部为**机械可 grep / 可 stat 的完成性检查**，无质量评分语义。

→ 判断依据：(a) 两个文件头部声明均明确自我定位为"完成性 gate"并显式声明"这**不是**业务质量评分"；(b) 所有条目均为存在性/包含性/未越权等布尔型机械判定，无任何打分维度。**两者表达的均为"tasklist 是否执行完成"的完成性语义（机械 gate），而非业务质量评分。** **AP7 = PASS**。

## Generator 产物 gen.md 评估摘要

### Stage probe: Generator 产物 gen.md
- 状态: PASS
- 功能性: 5/5 — gen.md 作为验证产物正确履行其功能：逐项验证 AP2/AP4/AP5/AP6 四个平台能力假设，四行 `VERIFY[AP<n>]:` 证据行齐全且机械可 grep（与 contract.md 第 12 行验收要点一致）。AP4 报告为 FAIL，但附完整证据链（工具清单核查 + 平台层 MCP 注册情况补充 + 调用尝试与结论），符合"verification 产物如实报告探测结果"的功能预期——AP4 FAIL 是平台能力探测结果，非 gen.md 文档缺陷。
- 工艺质量: 5/5 — 文档结构清晰，分「角色 Skill 加载 / MCP 工具探测 / 越权写探测 / 产物路径 / VERIFY 证据行」五个章节；AP5 拒绝依据给出三重论证（generator-role 白名单 + RULE.md 全局禁止 + Stage Contract 边界）；AP4 区分"子代理工具集不含 run_mcp"与"平台层已注册 mcp_Playwright"两层证据，并补充 schema 可读性证据；行内引用 contract.md/spec.md/RULE.md 具体行号。工艺严谨。
- 完整性: 5/5 — 四行 VERIFY 证据行齐全（AP2/AP4/AP5/AP6），逐行机械可 grep；每条 AP 均有详细证据段；AP6 给出实际绝对路径并说明未写入 .trae/specs/；文末附"路径白名单为提示词级约束"的诚实备注，完整性满分。
- 用户体验: 5/5 — 标题层级清晰，路径用反引号包裹便于阅读，blockquote 用于补充注释，VERIFY 行格式严格统一便于下游 Decision 子代理机械 grep。无冗余、无错别字、可读性高。
- 总分: 20/20
- 证据: (1) gen.md 第 66-71 行四行 VERIFY 证据行齐全且格式严格；(2) 第 23-37 行 AP4 探测含工具清单枚举、平台层 MCP 注册证据、调用尝试结论三层证据；(3) 第 41-55 行 AP5 越权写探测明确拒绝并引用三重白名单依据；(4) 第 59-64 行 AP6 路径正确落在 stages/probe/ 下。本 Evaluator 已实际 Read gen.md 全文 71 行验证。
- 问题列表: 无。AP4 报告为 FAIL 系平台能力探测结果（SubAgent 不继承 MCP），非 gen.md 文档质量缺陷——按 contract.md「AP4 风险」预判与 spec.md 验收标准第 2 条（"AP4 须实际尝试调用 MCP"——gen.md 已实际尝试并如实报告无 run_mcp 工具），gen.md 在此点行为正确。
- 修复建议: 无。gen.md 作为 verification 产物业务质量达标，可进入 Decision 裁决环节。

## 产物路径

本 eval.md 写入的**实际绝对路径**为：
`/workspace/harness/milestones/harness-selftest/stages/probe/eval.md`

- 该路径位于 `harness/milestones/harness-selftest/stages/probe/` 下，符合 spec.md / contract.md / checklist.md 要求的产物落位。
- **未**写入 `.trae/specs/`（该目录为原生 /spec 临时 scratch，gitignored，不依赖、不做消息传递，见 RULE.md 第 35 行）。
- 该路径正是 evaluator-role 路径白名单中明确允许写入的 `harness/milestones/{milestone}/stages/{stage}/eval.md`（仅评估报告）。

## VERIFY 证据行（机械可 grep）

VERIFY[AP2]: PASS — 已加载 evaluator-role Skill 并复述其准则（严格/多疑/不妥协 QA、四维评分、与 checklist.md 边界、不确定时往低打分、Decision 已独立）。
VERIFY[AP3]: PASS — 本 Evaluator 为独立派发 SubAgent，看不到 Generator 推理链/CoT/工具调用历史，仅能通过 Read gen.md 文件了解其产出，隔离成立。
VERIFY[AP7]: PASS — checklist.skeleton.md 与 probe/checklist.md 头部均声明"底层机制完成性 gate，非业务质量评分"，条目均为机械可 grep 的存在性/包含性判定，无打分语义。
VERIFY[AP6]: PASS — eval.md 实际绝对路径为 /workspace/harness/milestones/harness-selftest/stages/probe/eval.md，位于 stages/probe/ 下而非 .trae/specs/。
