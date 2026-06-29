# Stage adaptive — Generator R1 实现总结 (AP13)

## Round 1 (R1) — 故意 FAIL 演示 retry 闭环
- 故意写违反验收标准的 sample.json 以触发 Decision retry。
- 标准 #3 要求 items.length>=3，本轮故意写 items=[1]（长度=1）。

## 实现内容
- 写入 sample.json = {"status":"ok","items":[1]}（status="ok" PASS 标准 #2，items.length=1 FAIL 标准 #3）。
- 本 R1 不修复——留给 R2 据 retry_focus 修正。

## 文件变更
- harness/milestones/harness-selftest/stages/adaptive/sample.json (覆盖草稿)
- harness/milestones/harness-selftest/stages/adaptive/gen-r1.md (新增)

## VERIFY
- `VERIFY[AP13-R1]: PASS — R1 故意写违反标准的 sample.json (items.length=1<3)，由 Decision 裁 retry 后由 Orchestrator 手动重派 R2 修正。`
