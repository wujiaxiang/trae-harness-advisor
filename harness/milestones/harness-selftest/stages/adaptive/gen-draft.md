# Stage adaptive — Generator 草稿 (AP12 codraft)

## 草稿交付物
- sample.json (草稿) = {"status":"ok","items":[1,2,3]}

## 提议验收标准（给 Evaluator 敲定）
1. sample.json 必须是合法 JSON
2. sample.json.status == "ok"
3. sample.json.items 是数组，且长度 >= 3

## VERIFY
- `VERIFY[AP12]: PASS — Generator 出草稿+提议验收标准，链路通；最终标准由 Evaluator 敲定。`
