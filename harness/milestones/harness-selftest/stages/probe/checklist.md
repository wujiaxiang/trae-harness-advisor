# harness-selftest / Stage probe — 完成性 Checklist

> 定位 = 底层机制（TraeWork 原生完成性 gate）：机械检查该 Stage 的 tasklist 是否执行完成。
> 注意：这**不是**业务质量评分（质量由我们编排、在 task 内部运行的 Evaluator 的 eval.md 负责，见 0.2）。

- [x] tasks.md 中所有 [ORCHESTRATOR]/[GENERATOR]/[EVALUATOR]/[DECISION] 步骤均已完成
- [x] `stages/probe/` 下存在 7 个产物：spec.md / tasks.md / checklist.md / contract.md / gen.md / eval.md / decision.md
- [x] gen.md 逐行包含 `VERIFY[AP2]:`、`VERIFY[AP4]:`、`VERIFY[AP5]:`、`VERIFY[AP6]:` 四行
- [x] eval.md 逐行包含 `VERIFY[AP2]:`、`VERIFY[AP3]:`、`VERIFY[AP7]:`、`VERIFY[AP6]:` 四行
- [x] decision.md 列出 AP1–AP9 共 9 行 `VERIFY[AP<n>]:` 证据与总体 verdict
- [x] ap9-a.md 与 ap9-b.md 同时存在且各含 `started_at=` 时间戳
- [x] Orchestrator 在对话中报告了 `VERIFY[AP1]` 与 `VERIFY[AP8]` 与 `VERIFY[AP9]`
- [x] state-board.json 的 probe 记录已最小更新（status / rounds / last_decision / artifacts），其它字段未动
- [x] 无遗留 TODO / 未实现的接口（AP4 FAIL 是平台 MCP 能力缺失，非未实现接口）
- [x] 未修改任何全局禁止路径（src/、RULE.md、.trae/skills/、harness/templates/ 等）
