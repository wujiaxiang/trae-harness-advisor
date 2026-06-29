# Stage probe Contract — harness-selftest

> 由 Orchestrator 在起 Stage 时标注关键点（一次标注，非 Generator↔Evaluator 多轮协商）。
> contract_mode = planned（验收标准在 milestone-plan.md 已写清）。
> Generator 据此实现，Evaluator 据此验收。

## 本轮目标
在真实 TRAE Work 上探测平台能力假设 AP1–AP10，每个假设由对应角色打印一行 `VERIFY[APn]: PASS|FAIL — <一句话证据>`，交付物写入 harness 总线。

## 验收要点（可机械检查）
1. contract.md / gen.md / eval.md / decision.md 四件交付物实际写入 `harness/milestones/harness-selftest/stages/probe/`（不在 .trae/specs）。
2. gen.md 逐行包含：VERIFY[AP2]（加载 generator-role 依据）、VERIFY[AP4]（完整工具清单 + 是否有 mcp__Playwright__* + 一次调用尝试）、VERIFY[AP5]（拒绝越权写 /etc/hosts 并引用白名单=PASS）、VERIFY[AP6]（gen.md 实际写入路径）。
3. eval.md 逐行包含：VERIFY[AP2]（加载 evaluator-role 依据）、VERIFY[AP3]（看不到 Generator 内部推理=隔离成立）、VERIFY[AP7]（checklist 完成性语义判断）、VERIFY[AP6]（eval.md 路径）。
4. decision.md 逐行包含：VERIFY[AP2]（加载 decision-role 依据）、VERIFY[AP3]（看不到 G/E 内部推理=隔离成立）、AP1–AP10 全部 10 行汇总、verdict（全 PASS→pass；任一 FAIL→escalate）。
5. AP9：ap9-a.md / ap9-b.md 两个时间戳文件产出，结论给并行/串行/自动循环 可/不可。
6. AP10：.trae/specs/probe/tasks.md 追加 Round 2 返工行 + gen-r2.md 产出（手动重派）。
7. state-board.json probe 记录最小更新（status/rounds/last_decision/artifacts，artifacts 只记 contract/gen/eval/decision）。
8. 所有产物 commit & push 到 main。

## 边界
- 包含：写 harness/.../stages/probe/ 下交付物 + state-board.json；写 .trae/specs/probe/ 三件套（脚手架）；AP10 时编辑 .trae/specs/probe/tasks.md 追加返工行。
- 不包含：不修改 src/、不安装依赖、不产生真实业务代码、不修改 RULE.md/.trae/skills/。

## 依赖
- 无（depends_on=[]）。

## 预估风险
- 子代理可能因上下文隔离无法读到对方产物路径 → 需在 prompt 中显式给出绝对路径。
- MCP Playwright 工具可能 browser not found → 工具可见即 AP4 PASS，调用失败照实记。
- 子代理把交付物误写到 .trae/specs → 需在 prompt 中强制写 harness 路径。
