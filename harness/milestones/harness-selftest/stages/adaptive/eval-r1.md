# Stage adaptive — Evaluator R1 评估报告 (AP13)

## 状态
- 状态: FAIL

## 机械检查结果（对照 contract.md 验收要点）
1. 合法 JSON: PASS — sample.json = {"status":"ok","items":[1]} 可被解析。
2. status == "ok": PASS — status="ok"。
3. items.length >= 3: FAIL — items=[1]，len=1 < 3。

## 四维评分（1-5）
- 功能性: 2 — 故意违反标准 #3（items.length=1<3），这是 R1 的预期失败（演示 retry 闭环）。
- 工艺质量: 4 — JSON 格式合法、Generator 在 gen-r1.md 中诚实声明"故意 FAIL"。
- 完整性: 2 — 验收要点 #3 不满足。
- 用户体验: 4 — JSON 可读、gen-r1.md 说明清晰。
- 总分: 12/20

## 证据
- `python3 -c "import json; d=json.load(open('/workspace/harness/milestones/harness-selftest/stages/adaptive/sample.json')); print('status=',d['status'],'len=',len(d['items']))"` → status= ok len= 1
- contract.md 验收要点 #3: `len(sample.json.items) >= 3` — 当前 len=1，FAIL。

## 问题列表
1. items.length=1 < 3，违反 contract.md 验收要点 #3。
2. 需要 R2 修正为 items.length>=3。

## 修复建议
- R2 应把 sample.json 改为 `{"status":"ok","items":[1,2,3]}`（items 长度=3>=3）。

## VERIFY
- `VERIFY[AP13-R1]: FAIL — sample.json.items.length=1 < 3，违反 contract.md 验收要点 #3；R2 需修正。`
