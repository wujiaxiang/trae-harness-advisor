# {Milestone Name} / Stage {id} — 任务

> Orchestrator 据 spec.md 填充。每个 Stage 的对抗为顺序模拟（非自动循环），最多 3 轮返工，超限 escalate。

- [ ] [GENERATOR] 提出 Stage Contract 草案 → contract.md
- [ ] [EVALUATOR] 审查 Contract，批准或要求修改
- [ ] [GENERATOR] 按 Contract 实现（TDD: {tdd_mode}）
- [ ] [GENERATOR] 实现总结 → gen.md
- [ ] [EVALUATOR] 质量评估（严格度: {eval_strictness}）→ eval.md
- [ ] [DECISION] 裁决（pass/retry/escalate，rounds≤3）→ decision.md
