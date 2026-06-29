# Harness Self-Test（平台能力 PoC 自检集）

> 目的：在**真实 TRAE Work** 上验证 v4.0/v4.1 设计所依赖的几条平台能力假设，避免"纸面设计、真机跑不通"。
> 这是一个**自包含、最小**的 Milestone，喂给 TRAE Work 执行即可；执行后按 `expected-outcome.md` 判读是否符合预期。

## 它验证什么（5 个假设点）

| 编号 | 假设 | 为什么重要 |
|------|------|-----------|
| **AP1** | SubAgent 能加载指定角色 Skill（`@generator-role` / `@evaluator-role`） | 角色分离 + 上下文隔离的地基；否则退化成"自己评自己" |
| **AP2** | SubAgent 能调用 MCP（如 Playwright/任意已装 MCP） | Evaluator 的浏览器/外部验证能力 |
| **AP3** | 路径白名单为提示词级——SubAgent 收到越权写指令时**会拒绝并说明** | 验证"白名单是 best-effort"这一诚实结论是否成立 |
| **AP4** | 交付物能写入 `harness/` 总线（**不依赖** `.trae/specs/`） | "harness/ 是唯一消息总线"的地基 |
| **AP5** | 原生 `checklist.md` 语义≈"tasklist 完成性 gate" | 两类验收分工（checklist vs Evaluator）的地基 |

## 如何运行

前置：已对本仓库执行过 `trae-harness-advisor` 生成基础设施（至少有 `.trae/skills/{generator-role,evaluator-role,stage-executor}/` 与 `harness/`），并配置了 RULE.md 钩子规则。
若尚未生成，可先只做本自检：把本目录的 `selftest-milestone-plan.md` 作为 `milestone-plan.md`，手动触发 stage-executor 执行其中的 Stage。

1. 在 TRAE Work 打开本项目。
2. 让 Orchestrator 读取 `poc/harness-selftest/selftest-milestone-plan.md`，按 stage-executor playbook 执行 **Stage `probe`**。
3. 要求每个被派发的 SubAgent **按规定格式打印验证点**（`VERIFY[...]: PASS|FAIL — 证据`）。
4. 执行完成后，对照 `expected-outcome.md` 判读。

## 如何判读

- 所有 `VERIFY[AP1..AP5]` 行都出现，且与 `expected-outcome.md` 的预期一致 → 该假设**成立**。
- 任一为 FAIL 或缺失 → 在 `expected-outcome.md` 的"结果记录"里登记，并据此回到主文档把对应设计标注/调整（例如 AP1 FAIL 则角色分离方案需改）。

## 产物落点（应出现在这里，证明 AP4）

```
harness/milestones/harness-selftest/stages/probe/
├── gen.md        # Generator 子代理写入（含 VERIFY[AP1/AP2/AP3/AP4]）
├── eval.md       # Evaluator 子代理写入（含 VERIFY[AP1/AP5]）
└── decision.md   # 裁决（汇总 5 个验证点的 PASS/FAIL）
```
若这些文件出现在 `harness/...` 而非仅 `.trae/specs/` → AP4 PASS。
