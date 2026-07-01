# Stage adaptive — Generator 草稿 (AP12 codraft 共识子阶段)

> 角色：Generator（已加载 `generator-role` skill）。
> 阶段：Stage `adaptive`，contract_mode=codraft。本文件为共识子阶段的草稿 + 提议验收标准，**不敲定最终标准、不裁决**（那是 Evaluator/Decision 的事）。

## 1. 草稿内容与设计理由

### 1.1 最小真实交付物
milestone-plan §77 约定本 Stage 的最小真实交付物是 `sample.json`，预期形如 `{"status":"ok","items":[...]}`，验收标准方向 = 含 `status="ok"` 且 `items` 数组长度 ≥ 3。

### 1.2 草稿选择
- `status` 取 `"ok"`：直接对齐 milestone-plan §77 的方向，且是字符串字面量，机械可比较。
- `items` 取 `[1,2,3]`：长度恰好 = 3，刚好满足“≥ 3”的下限，是最小合规样本；元素用数字而非对象，避免引入任何无关结构，把“是否达标”这件事压到最朴素的 `length` 检查上。
- 不附带额外字段（如 `meta`、`version`）：codraft 草稿阶段先不扩张契约面，把验收焦点收敛到 `status` + `items.length` 两条上。

### 1.3 草稿 sample.json 全文
```json
{"status":"ok","items":[1,2,3]}
```

## 2. 提议的验收标准（机械可检查）

以下标准全部可在脚本里用确定性逻辑判定，无需人工主观判断：

1. **C1 合法 JSON**：`sample.json` 能被 `JSON.parse` 成功解析（无语法错误）。
2. **C2 status 字段**：解析结果为对象，且 `obj.status === "ok"`（严格相等，区分大小写）。
3. **C3 items 是数组**：`Array.isArray(obj.items) === true`。
4. **C4 items 长度**：`obj.items.length >= 3`。

判定规则：C1 ∧ C2 ∧ C3 ∧ C4 全部为真 → PASS；任一为假 → FAIL。

## 3. 提议的验证方式

用 Node.js 一次性脚本解析并断言（不依赖任何外部库，仅用内置 `JSON` + `assert`），命令如下：

```bash
node -e "const fs=require('fs');const s=fs.readFileSync('harness/milestones/harness-selftest/stages/adaptive/sample.json','utf8');const o=JSON.parse(s);const assert=require('assert');assert.strictEqual(o.status,'ok');assert.ok(Array.isArray(o.items),'items 不是数组');assert.ok(o.items.length>=3,'items 长度 < 3');console.log('PASS');"
```

预期输出：`PASS`。若任一断言失败，进程非 0 退出并打印 `AssertionError`，可直接被 Evaluator 当作 FAIL 证据。

> 备注：本子阶段只产出合规草稿。AP13 R1 会**故意**把 `sample.json` 覆盖为违规样本（`{"status":"ok","items":[1]}`，length=1）以跑通 retry→pass 闭环；本步不预先做该覆盖。

## 4. VERIFY

- `VERIFY[AP2]: PASS — 已加载 generator-role skill；复述其准则“禁止评价自己的代码好坏 / 禁止修改 SPEC、Checklist 或验收标准”，本文件仅出草稿+提议标准，未敲定最终标准，未越界。`
- `VERIFY[AP6]: PASS — 两个交付物已实际写入：sample.json → /workspace/harness/milestones/harness-selftest/stages/adaptive/sample.json；gen-draft.md → /workspace/harness/milestones/harness-selftest/stages/adaptive/gen-draft.md。`
