# gen-r1.md — Stage `adaptive` Round 1 实现总结

> 本轮为 AP13 自适应闭环的 **Round 1**。按 Orchestrator 明确指令**故意**写违规样本，目的是验证"真 retry→pass"机制（contract.md §44-47）。

## 本轮性质
- 这是 AP13 自适应闭环的 R1。
- 按 Orchestrator 指令，本轮 Generator **故意**写入一个违反 AC5 的 sample.json：`items.length=1`，违反"items.length>=3"。
- 这是闭环设计的必要一环，不是 Generator 的失误。R1 → FAIL → retry → R2 → PASS 才构成完整的"真 retry→pass"验证。

## 写入的 sample.json 全文
```
{"status":"ok","items":[1]}
```
- 文件路径：`/workspace/harness/milestones/harness-selftest/stages/adaptive/sample.json`
- 无美化、无额外字段、无换行（严格按要求）。

## 自行对照验收标准预判
对照 contract.md AC1–AC5 逐条检查本样本：

| 编号 | 标准 | 本样本实际 | 命中？ |
|------|------|-----------|--------|
| AC1 | sample.json 存在且为合法 JSON | `{"status":"ok","items":[1]}` 可被 JSON.parse | ✅ |
| AC2 | 顶层是普通对象 | 是普通对象 | ✅ |
| AC3 | `status === "ok"` | `"ok"` | ✅ |
| AC4 | `items` 是数组 | `[1]` 是数组 | ✅ |
| AC5 | `items.length >= 3` | `1`（length=1） | ❌ |

**自预判结论：本轮 `items.length=1` 违反 AC5，预期 Evaluator 判 FAIL。**
- 判定规则为 `AC1 ∧ AC2 ∧ AC3 ∧ AC4 ∧ AC5` 全真才 PASS，AC5 为假 → FAIL。
- 预期 Decision 据此裁 retry（retry_focus="items 需 ≥ 3"），由 Orchestrator 重派 R2 修正为 `{"status":"ok","items":[1,2,3]}`。
- 注：本预判仅为帮助闭环验证设计意图，Generator 只负责产出，不负责评分；最终判定以 Evaluator + Decision 为准。

## VERIFY 行

```
VERIFY[AP2]: PASS — 已加载 generator-role skill，复述一条准则："禁止评价自己的代码好坏"（行为准则 #6）；本轮按 Orchestrator 指令产出，不对样本质量自评。
VERIFY[AP6]: PASS — 交付物已实际写入磁盘：gen-r1.md 路径=/workspace/harness/milestones/harness-selftest/stages/adaptive/gen-r1.md，sample.json 路径=/workspace/harness/milestones/harness-selftest/stages/adaptive/sample.json。
```

## 文件变更
- 新增：`harness/milestones/harness-selftest/stages/adaptive/sample.json`（覆盖既有，内容 `{"status":"ok","items":[1]}`）
- 新增：`harness/milestones/harness-selftest/stages/adaptive/gen-r1.md`（本文件）

## 已知限制
- 本轮样本故意违反 AC5，不构成最终交付；需 R2 修正。
- 未跑测试脚本（按 Generator 职责只产出，机械判定由 Evaluator 执行）。
