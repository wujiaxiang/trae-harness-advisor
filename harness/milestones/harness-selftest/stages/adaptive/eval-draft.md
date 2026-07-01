# Stage adaptive — Evaluator 草稿 (AP12 codraft 共识子阶段)

> 角色：Evaluator（已加载 `evaluator-role` skill）。
> 阶段：Stage `adaptive`，contract_mode=codraft。本文件 review Generator 草稿并**敲定**最终可机械检查的验收标准（将写入 contract.md）。本步只产出 eval-draft.md，不裁决（那是 Decision 的事），不出新草稿。

## 1. 输入回放（只读）
- Generator 草稿：`/workspace/harness/milestones/harness-selftest/stages/adaptive/gen-draft.md`
- sample.json 草稿：`/workspace/harness/milestones/harness-selftest/stages/adaptive/sample.json`
- 草稿全文：`{"status":"ok","items":[1,2,3]}`
- Generator 提议标准：C1 合法 JSON / C2 `obj.status === "ok"` / C3 `Array.isArray(obj.items)` / C4 `obj.items.length >= 3`
- milestone-plan §77 方向：`status="ok"` 且 `items` 数组长度 ≥ 3
- milestone-plan §86：AP13 R1 会**故意**把 sample.json 覆盖为 `{"status":"ok","items":[1]}`（length=1）跑 retry→pass 闭环 —— 意味着敲定的标准必须能确定性判出该违规样本为 FAIL。

## 2. 对 Generator 提议标准的 review
- 提议 4 条标准方向正确，与 milestone-plan §77 完全对齐，且全部机械可检查（无主观判断）。
- **补强一处**：C2 直接写 `obj.status === "ok"` 隐含假设了 `obj` 是对象。若 sample.json 退化成 `"ok"`（字符串）、`[1,2,3]`（数组）或 `null`，`obj.status` 为 `undefined`，C2 仍能判 FAIL，但错误信息会含糊。补一条 AC2「顶层是普通对象」让失败定位更清晰，且不改变判定结论（仍是 `obj.status === "ok"` 在对象前提下成立）。
- 其余 C3/C4 直接采纳，无需改动。

## 3. 敲定的最终验收标准（机械可检查，写入 contract.md）

> 判定对象：`harness/milestones/harness-selftest/stages/adaptive/sample.json` 文件内容。

| 编号 | 标准 | 机械检查表达式 |
|------|------|----------------|
| AC1 | sample.json 存在且为合法 JSON | `JSON.parse(text)` 不抛异常 |
| AC2 | 顶层是普通对象 | `typeof o === "object" && o !== null && !Array.isArray(o)` |
| AC3 | `status` 严格等于字符串字面量 `"ok"`（大小写敏感） | `o.status === "ok"` |
| AC4 | `items` 是数组 | `Array.isArray(o.items)` |
| AC5 | `items` 长度 ≥ 3（整数比较） | `o.items.length >= 3` |

**判定规则**：`AC1 ∧ AC2 ∧ AC3 ∧ AC4 ∧ AC5` 全真 → **PASS**；任一为假 → **FAIL**（脚本以退出码 1 退出并打印首条失败原因）。

**敲定理由**：
1. 与 milestone-plan §77 方向 `status="ok"` 且 `items` 数组长度 ≥ 3 完全一致，不扩张契约面。
2. 全部为确定性表达式（`===`、`Array.isArray`、`length >= N`），可在 node/python 中一行判定，无人工主观空间。
3. AC2 是对 Generator C2 的边界补强——不改变 PASS/FAIL 结论，只让 `null`/数组/字符串等退化样本的失败定位更明确。
4. 对 AP13 R1 故意注入的违规样本 `{"status":"ok","items":[1]}`，AC5 会确定性判 FAIL（length=1 < 3）→ 触发 retry；R2 修正回 `[1,2,3]` 后 AC5 真 → PASS，闭环可被本标准机械驱动。
5. 不约束 `items` 元素类型（数字/对象/字符串均可）—— milestone-plan §77 只约束长度，约束元素类型属于越界扩张。

## 4. 验证脚本（可重复执行，用于 AP13 各轮次机械判定）

### 4.1 Node.js 版（推荐，单行可贴）
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

### 4.2 Python 版（备选，无 node 时用）
```bash
python3 -c "
import json,sys
p='harness/milestones/harness-selftest/stages/adaptive/sample.json'
with open(p,'r',encoding='utf-8') as f: s=f.read()
try: o=json.loads(s)
except Exception as e: print('FAIL — JSON 解析失败:', e); sys.exit(1)
if not isinstance(o,dict): print('FAIL — 顶层不是普通对象'); sys.exit(1)
if o.get('status')!='ok': print(f'FAIL — status!==\"ok\" (实际: {o.get(\"status\")!r})'); sys.exit(1)
if not isinstance(o.get('items'),list): print('FAIL — items 不是数组'); sys.exit(1)
if len(o['items'])<3: print(f'FAIL — items.length<3 (实际: {len(o[\"items\"])})'); sys.exit(1)
print(f'PASS — status==\"ok\" 且 items 是数组且 items.length={len(o[\"items\"])}>=3')
"
```

**判定契约**：脚本打印 `PASS ...` 且退出码 0 → 本轮 PASS；打印 `FAIL — ...` 且退出码 1 → 本轮 FAIL（首条失败原因即为 retry_focus 候选）。

## 5. 实测证据（已在本子阶段真跑，可复现）

| 用例 | sample 内容 | 脚本输出 | 退出码 | 结论 |
|------|-------------|----------|--------|------|
| 当前草稿（合规） | `{"status":"ok","items":[1,2,3]}` | `PASS — status=="ok" 且 items 是数组且 items.length=3>=3` | 0 | PASS |
| AP13 R1 待注入（违规） | `{"status":"ok","items":[1]}` | `FAIL — items.length<3 (实际: 1)` | 1 | FAIL（命中 AC5） |
| 当前草稿（Python 版） | `{"status":"ok","items":[1,2,3]}` | `PASS — status=="ok" 且 items 是数组且 items.length=3>=3` | 0 | PASS |

> 两条关键路径都已实测：合规样本两条脚本都 PASS；AP13 R1 计划注入的违规样本被 AC5 确定性判 FAIL。闭环可被本标准机械驱动。

## 6. 对草稿 sample.json 的 review 结论

**合规（PASS）**。

- AC1 ✓：`{"status":"ok","items":[1,2,3]}` 可被 `JSON.parse` 成功解析。
- AC2 ✓：顶层是普通对象。
- AC3 ✓：`status === "ok"`（字符串字面量、严格相等）。
- AC4 ✓：`items` 是数组 `[1,2,3]`。
- AC5 ✓：`items.length === 3 >= 3`（恰好命中下限，是最小合规样本）。

草稿是最小合规样本（长度恰为 3、元素用数字、无额外字段），与 Generator "把验收焦点收敛到 status + items.length 两条" 的设计意图一致，不引入无关结构。**建议 Orchestrator 据本敲定标准写 contract.md，进入 AP13 真 retry→pass 闭环**。

## 7. VERIFY

- `VERIFY[AP2]: PASS — 已加载 evaluator-role skill；复述其准则“你是怀疑者，不是橡皮图章 / 不确定时往低打分 / 必须保留证据”，本文件对草稿逐条核对 AC1–AC5 并实测两脚本三用例，未放水、未越界出草稿或裁决。`
- `VERIFY[AP6]: PASS — eval-draft.md 实际写入路径 /workspace/harness/milestones/harness-selftest/stages/adaptive/eval-draft.md（位于 harness/ 总线 stages/adaptive/ 下，符合 RULE.md 关键目录结构约定）。`
