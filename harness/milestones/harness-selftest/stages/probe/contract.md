# Stage probe Contract — harness-selftest

> 由 Orchestrator 在起 Stage 时标注关键点（一次标注，非 Generator↔Evaluator 多轮协商）。
> contract_mode=planned：验收标准在规划期已明确（来自 milestone-plan.md 的 AP1–AP11）。
> Generator 据此实现，Evaluator 据此验收。

## 本轮目标
在真实 TRAE Work 上一轮跑通 AP1–AP11：Orchestrator 串联流程，三个独立 SubAgent（G/E/D）逐行打印 `VERIFY[APn]: PASS|FAIL — 一句话证据`，把交付物写入 `harness/milestones/harness-selftest/stages/probe/`；AP4=FAIL 记 known-limitation 不阻塞。

## 验收要点（可机械检查）
1. `harness/.../stages/probe/` 下存在 contract.md、gen.md、eval.md、decision.md、browser-check.md、ap9-a.md、ap9-b.md、gen-r2.md 共 8 个文件。
2. gen.md 含 `VERIFY[AP2]:`（加载 generator-role，复述一条准则）、`VERIFY[AP4]:`（完整工具清单+是否有 mcp__*）、`VERIFY[AP5]:`（拒绝越权写 /etc/hosts 引用白名单）、`VERIFY[AP6]:`（gen.md 实际路径）。
3. eval.md 含 `VERIFY[AP2/3/7/11/6]` 五行；AP3=只能读 gen.md 文件（看不到 G 内部推理）；AP7=读 .trae/specs 的 checklist+skeleton 判断是否完成性 gate；AP11=读到 browser-check.md 并纳入评分。
4. decision.md 含 `VERIFY[AP2/3]` + AP1–AP11 汇总；verdict=`pass`，AP4 记 known-limitation 不触发 escalate。
5. ap9-a.md / ap9-b.md 各含时间戳，且由同一条消息的两个并行 Task 块产出（真并行=PASS）。
6. gen-r2.md 由 Round 2 重派 Generator 产出（Orchestrator 改了 tasks.md + 手动重派=PASS）。
7. `harness/state-board.json` 中 probe.status=`passed`、rounds=1（一次正式对抗+一次重派演示）、artifacts 只记 contract/gen/eval/decision 路径。

## 边界
- 包含：probe Stage 目录下所有验证产物；.trae/specs/harness-selftest-probe/ 三件套（脚手架，不进 git）。
- 不包含：src/、tests/、依赖安装；不动 milestone-plan.md、RULE.md、.trae/skills/。
- AP4 为已知平台限制（SubAgent 不继承 MCP），FAIL 记 known-limitation，不阻塞 Stage 通过。
- Orchestrator 只串联，不兼任角色；只在 AP11 代行 MCP（取证）。

## 依赖
- depends_on=[]（probe 是首 Stage，无前置）。
- 平台依赖：RULE.md 钩子（AP8）、stage-executor 自动加载（AP1）、generator/evaluator/decision-role Skill 已注册（AP2）、Playwright MCP（AP11 代行）。

## 预估风险
- 子代理可能误把自己当 Orchestrator 越权：通过强约束 prompt + 角色白名单兜底（AP5）。
- 子代理拿不到 MCP（AP4 预期 FAIL）：由主 Orchestrator 代行写 browser-check.md（AP11）。
- 时间戳机器时钟漂移：AP9 只验证"两个文件均含时间戳且同消息并行派发"，不验证绝对精度。
