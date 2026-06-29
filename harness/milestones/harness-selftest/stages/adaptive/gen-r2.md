# Stage adaptive — Generator R2 实现总结 (AP13)

## Round 2 (R2) — 据 retry_focus 修正
- R1 verdict=retry，retry_focus="items 需 >= 3"。
- 本 R2 把 sample.json 从 `{"status":"ok","items":[1]}` 修正为 `{"status":"ok","items":[1,2,3]}`。
- 现在满足 contract.md 全部 3 条验收标准（合法 JSON / status=="ok" / items.length=3>=3）。

## 实现内容
- 写入 sample.json = {"status":"ok","items":[1,2,3]}（覆盖 R1 的 [1]）。
- 本 R2 由 Orchestrator 据 decision-r1.md retry_focus 手动重派（非自动 loop）。

## 文件变更
- harness/milestones/harness-selftest/stages/adaptive/sample.json (覆盖 R1)
- harness/milestones/harness-selftest/stages/adaptive/gen-r2.md (新增)

## VERIFY
- `VERIFY[AP13-R2]: PASS — 据 retry_focus 修正 sample.json，items=[1,2,3] 长度=3>=3，满足 contract.md 验收要点 #3。`
