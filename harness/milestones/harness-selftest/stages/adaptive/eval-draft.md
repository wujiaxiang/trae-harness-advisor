# Stage adaptive — Evaluator 草稿 review + 敲定验收标准 (AP12 codraft)

## Generator 草稿 review
- 草稿 sample.json = {"status":"ok","items":[1,2,3]}（合法 JSON）
- 提议的 3 条标准合理，但需收紧为可机械检查的判据

## 敲定的验收标准（mechanical,给 Orchestrator 写入 contract.md）
1. `sample.json` 必须是合法 JSON（可被 `jq .` 或 `python -c "import json; json.load(open('sample.json'))"` 解析）
2. `sample.json.status == "ok"`（机械字符串比较）
3. `len(sample.json.items) >= 3`（数组长度机械检查）

**PASS 条件** = 1 AND 2 AND 3 全部满足。
**FAIL 条件** = 任一不满足。

## 给 R1/R2 Evaluator 的判分依据
- R1: sample.json = {"status":"ok","items":[1]} → 标准 #3 不满足（len=1<3）→ FAIL
- R2: sample.json = {"status":"ok","items":[1,2,3]} → 全部满足 → PASS

## VERIFY
- `VERIFY[AP12]: PASS — reviewed gen-draft.md + sample.json；敲定 3 条机械可检查标准（合法 JSON / status=="ok" / items.length>=3）；链路通（Generator 草稿 → Evaluator 敲定 → Orchestrator 写 contract.md）。`
