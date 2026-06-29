# Stage adaptive Contract — harness-selftest

> 由 Orchestrator 在 codraft 共识子阶段后据 Evaluator 敲定的标准写入（contract_mode=codraft）。
> Generator 据此实现，Evaluator 据此验收。

## 本轮目标
用一个最小真实交付物 `sample.json` 跑通"真 retry→pass 自适应闭环"：R1 故意 FAIL → Decision retry → R2 修正 PASS。

## 验收要点（可机械检查；来自 Evaluator eval-draft.md）
1. `sample.json` 必须是合法 JSON（可被 `jq .` 或 `python -c "import json; json.load(open('sample.json'))"` 解析）。
2. `sample.json.status == "ok"`（机械字符串比较）。
3. `len(sample.json.items) >= 3`（数组长度机械检查）。

**PASS 条件** = 1 AND 2 AND 3 全部满足。
**FAIL 条件** = 任一不满足。

## R1 / R2 计划
- **R1（故意 FAIL 演示 retry 闭环）**：sample.json = `{"status":"ok","items":[1]}`（标准 #3 不满足 len=1<3）→ Evaluator FAIL → Decision retry，retry_focus="items 需 ≥ 3"。
- **R2（修正 PASS）**：sample.json = `{"status":"ok","items":[1,2,3]}`（全部满足）→ Evaluator PASS → Decision pass。

## 边界
- 包含：`harness/.../stages/adaptive/` 下所有交付物（gen-draft/eval-draft/contract/gen-r1/eval-r1/decision-r1/gen-r2/eval-r2/decision-r2/sample.json）。
- 不包含：src/、tests/、依赖安装；不动 milestone-plan.md、RULE.md、.trae/skills/。
- AP13 必须真两轮：R1 真的 FAIL、R2 真的 PASS，由 Orchestrator 手动重派（非自动 loop）。

## 依赖
- depends_on=[probe]（已 passed，AP14 门控通过）。

## 预估风险
- Generator 可能在 R1 不愿意故意写错的版本：通过强约束 prompt 兜底（明确告诉它这是演示 retry 闭环）。
- R2 必须由 Orchestrator 重派带 retry_focus，不能让子代理自我循环。
