# Stage Contract — adaptive（contract_mode: codraft）

> Orchestrator 据共识子阶段产物编写。codraft 模式：Generator 出草稿+提议标准 → Evaluator 敲定标准 → 本 contract.md。
> 共识子阶段产物：gen-draft.md（草稿 sample.json + 提议标准）、eval-draft.md（敲定的最终标准 + 验证脚本）。

## 目标
用最小真实交付物 `sample.json` 跑通 codraft 共识子阶段 + 真 retry→pass 自适应闭环（AP12/AP13），并验证 depends_on 门控（AP14）。

## 验收标准（机械可检查，由 Evaluator 在 eval-draft.md 敲定）
判定对象 = `harness/milestones/harness-selftest/stages/adaptive/sample.json`：

| 编号 | 标准 | 机械检查表达式 |
|------|------|----------------|
| AC1 | sample.json 存在且为合法 JSON | `JSON.parse(text)` 不抛异常 |
| AC2 | 顶层是普通对象 | `typeof o === "object" && o !== null && !Array.isArray(o)` |
| AC3 | `status` 严格等于字符串字面量 `"ok"`（大小写敏感） | `o.status === "ok"` |
| AC4 | `items` 是数组 | `Array.isArray(o.items)` |
| AC5 | `items` 长度 ≥ 3 | `o.items.length >= 3` |

判定规则：`AC1 ∧ AC2 ∧ AC3 ∧ AC4 ∧ AC5` 全真 → PASS；任一为假 → FAIL。

## 验证脚本（机械判定，供 Evaluator 各轮复用）
```bash
node -e "
const fs=require('fs');
const p='harness/milestones/harness-selftest/stages/adaptive/sample.json';
const s=fs.readFileSync(p,'utf8');
let o;
try { o=JSON.parse(s); } catch(e) { console.log('FAIL — JSON 解析失败:', e.message); process.exit(1); }
if (typeof o!=='object'||o===null||Array.isArray(o)) { console.log('FAIL — 顶层不是普通对象'); process.exit(1); }
if (o.status!=='ok') { console.log('FAIL — status!==\"ok\" (实际: '+JSON.stringify(o.status)+')'); process.exit(1); }
if (!Array.isArray(o.items)) { console.log('FAIL — items 不是数组'); process.exit(1); }
if (o.items.length<3) { console.log('FAIL — items.length<3 (实际: '+o.items.length+')'); process.exit(1); }
console.log('PASS — status==\"ok\" 且 items 是数组且 items.length='+o.items.length+'>=3');
"
```

## 边界
- 交付物：sample.json + gen-draft/eval-draft/gen-r1/eval-r1/decision-r1/gen-r2/eval-r2/decision-r2 → harness/milestones/harness-selftest/stages/adaptive/。
- 三件套留 .trae/specs/（scratch）。
- 不改 src/、不装依赖。
- 子代理独立、上下文隔离；Orchestrator 只串联，不兼任裁决。

## 闭环设计（AP13）
- R1：Generator 故意写 `{"status":"ok","items":[1]}`（items.length=1，违反 AC5）→ Evaluator 判 FAIL → Decision 裁 retry（retry_focus="items 需 ≥ 3"）。
- R2：Orchestrator 据 retry 重派 Generator 修正为 `{"status":"ok","items":[1,2,3]}` → Evaluator 复评 PASS → Decision 裁 pass。
- rounds=2，最终 sample.json 达标。

## 通过判定
AP12（codraft 链路通）+ AP13（真 retry→pass 两轮）+ AP14（depends_on 门控）全 PASS → verdict=pass。
