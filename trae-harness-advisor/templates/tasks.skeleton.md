# {Milestone Name} / Stage {id} — 任务

> Stage Orchestrator 据当前 Stage 三件套上下文填充。每个 Stage 的对抗为 LLM 驱动的有界动态编排，最多 {max_adversarial_rounds} 轮返工，超限 escalate。

- [ ] [STAGE_ORCHESTRATOR] 标注关键 Contract 点 → contract.md（目标/验收要点/边界）
- [ ] [GENERATOR] 按 contract.md 实现（TDD: {tdd_mode}）
- [ ] [GENERATOR] 实现总结 → gen.md
- [ ] [EVALUATOR] 质量评估（严格度: {eval_strictness}）→ eval.md
- [ ] [DECISION] 裁决（pass/retry/escalate，rounds≤{max_adversarial_rounds}）→ decision.md
