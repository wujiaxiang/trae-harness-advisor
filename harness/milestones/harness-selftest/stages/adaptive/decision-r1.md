# decision-r1.md — Stage `adaptive` Round 1 裁决（AP13 R1）

> Decision 角色（已加载 `decision-role` skill），作为独立 SubAgent 运行，与 Generator / Evaluator 上下文隔离。
> 本轮为 AP13 自适应闭环的 **Round 1 裁决**。仅基于总线文件 contract.md / gen-r1.md / eval-r1.md 做中立裁决，不写代码、不评估代码质量、不兼任 G/E。

## 输入文件（只读，均来自 harness/milestones/harness-selftest/stages/adaptive/）
- contract.md（验收标准 AC1–AC5 + 验证脚本）
- gen-r1.md（Generator R1 实现总结，sample.json = `{"status":"ok","items":[1]}`）
- eval-r1.md（Evaluator R1 实跑脚本判定 FAIL，AC5 为假，items.length=1<3）

> 注：state-board.json 当前不存在于 harness/ 目录；rounds 据任务上下文与 contract.md §47 闭环设计取值为 1，上限为 3（decision-role skill 裁决规则：rounds < 3 可 retry）。

## VERIFY 行

```
VERIFY[AP2]: PASS — 已加载 decision-role skill，复述一条准则："中立——不偏向任何一方"（行为规则 #1）；本轮只读 contract/gen-r1/eval-r1 三份总线文件，不采信 G/E 对话上下文，不评估代码质量本身。
VERIFY[AP3]: PASS — 仅能读取总线产物文件（contract.md/gen-r1.md/eval-r1.md），看不到 Generator/Evaluator 的内部对话推理；上下文隔离成立，故独立裁决前提满足。
```

## 裁决结论

```
verdict: retry
rounds: 1
retry_focus: items 需 ≥ 3（当前 length=1，需补足至 3，建议改为 [1,2,3]）
```

## 裁决理由

1. **机械判定 FAIL（来自 eval-r1.md 实跑证据）**
   - eval-r1.md §34-39 记录验证脚本实跑 stdout = `FAIL — items.length<3 (实际: 1)`，node 进程 exit code = 1。
   - eval-r1.md §47-53 逐条判定表显示：AC1–AC4 均 ✅ PASS，唯独 AC5（`o.items.length >= 3`）❌ FAIL（实际 `items.length === 1`，`1 >= 3` 为假）。
   - contract.md §20 判定规则：`AC1 ∧ AC2 ∧ AC3 ∧ AC4 ∧ AC5` 全真才 PASS；AC5 为假 → 整体 FAIL。
   - gen-r1.md §12-13 自报 sample.json 全文 = `{"status":"ok","items":[1]}`，与 eval-r1.md 判定对象一致，证据自洽无矛盾。

2. **属"可修复"范畴，存在明确修复路径**
   - 唯一失败项为 AC5 的数量约束，结构性问题（AC1–AC4）均已通过。
   - 修复动作极小且机械：将 `items` 数组由 `[1]` 补足至 ≥3 个元素即可，contract.md §46 与 eval-r1.md §70/85 均给出明确建议值 `{"status":"ok","items":[1,2,3]}`。
   - 无需 spec/contract 层 trade-off，无需人类介入判定验收标准本身。

3. **未超 rounds 上限，retry 合规**
   - 当前 rounds = 1，decision-role skill 裁决规则规定 retry 条件为 `rounds < 3`；1 < 3 满足。
   - contract.md §44-47 闭环设计明确预期 R1 → FAIL → retry → R2 → PASS，本轮 retry 即为该闭环的既定第二步。

4. **不判 escalate 的理由**
   - 不存在"rounds >= 3 仍未过"（当前仅 R1）。
   - 不存在 G/E 对验收标准的根本分歧：gen-r1.md §28 自预判 FAIL、eval-r1.md §56 判 FAIL，双方对 AC5 失败的认定一致。
   - 不存在 spec/contract 本身的问题：AC5 表达式清晰、验证脚本可复跑、证据自洽。

5. **不判 pass 的理由**
   - eval-r1.md verdict 建议 = `fail`，验证脚本 exit code = 1，AC5 客观为假，未达 contract.md §20 通过条件。

## retry_focus（重申，供 Orchestrator 重派 R2 Generator）

`items 需 ≥ 3（当前 length=1，需补足至 3，建议改为 [1,2,3]）`

可操作修复步骤：
- 将 `sample.json` 由 `{"status":"ok","items":[1]}` 改为 `{"status":"ok","items":[1,2,3]}`（或任意 ≥3 元素数组）。
- 保持 `status === "ok"`、顶层为普通对象、`items` 为数组（AC1–AC4 已通过，勿回归）。
- 修正后重跑 contract.md §22-36 验证脚本，预期 stdout `PASS — status=="ok" 且 items 是数组且 items.length=3>=3`、exit code=0。

## 与 Orchestrator 的交接

- 本裁决为 `retry`；后续动作由 Orchestrator 承担：读 verdict=retry → 带 retry_focus 重派 Generator（rounds+1=2）。
- Decision 不自我循环、不重派他人。R2 完成后由 Evaluator 复评、Decision 再裁一次。

## 文件变更
- 新增：`harness/milestones/harness-selftest/stages/adaptive/decision-r1.md`（本文件，唯一写入）
- 未修改：contract.md / gen-r1.md / eval-r1.md / sample.json / milestone-plan.md / RULE.md / .trae/skills/（遵守 Decision 写入白名单与全局禁止修改清单）
