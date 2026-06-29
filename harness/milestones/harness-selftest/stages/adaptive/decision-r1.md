# Stage adaptive — Decision R1 裁决 (AP13)

```json
{
  "stage": "adaptive",
  "round": 1,
  "verdict": "retry",
  "reasoning": "eval-r1.md 判 FAIL（总分 12/20，验收要点 #3 不满足）：sample.json.items.length=1 < 3，违反 contract.md 验收要点 #3。Generator 在 gen-r1.md 中诚实声明这是 R1 故意 FAIL 演示 retry 闭环。rounds=0<3，retry 路径明确可修复（仅需把 items 改为长度>=3 的数组）。",
  "retry_focus": "items 需 >= 3：把 sample.json 改为 {\"status\":\"ok\",\"items\":[1,2,3]}",
  "escalation_reason": null,
  "known_limitations": []
}
```

## VERIFY
- `VERIFY[AP13-R1]: retry — eval-r1.md FAIL（items.length=1<3），retry_focus='items 需 >= 3'，rounds<3 允许 retry。`
