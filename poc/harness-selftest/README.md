# Harness Self-Test（平台能力 PoC 自检集）

> 目的：在**真实 TRAE Work** 上一次验证本设计依赖的平台能力 + v4.4 全部设计行为 **AP1–AP14**，避免"纸面设计、真机跑不通"。
> 环境**已在本仓库实例化**（无需先跑 advisor）：`.trae/skills/` 5 个 Skill、根目录 `RULE.md`、`harness/`（templates + state-board + 自检 Milestone 两个 Stage）都已就绪。

## 它验证什么（AP1–AP14，两个 Stage）

**Stage probe（平台能力 AP1–AP11）**

| 编号 | 假设 |
|------|------|
| AP1 | stage-executor 触发短语**自动加载** |
| AP2 | SubAgent 加载**指定角色 Skill**（generator/evaluator/decision-role） |
| AP3 | SubAgent **独立上下文隔离** |
| AP4 | SubAgent 调 **MCP**（已知=不继承，仅主 Orchestrator 有；known-limitation） |
| AP5 | 路径白名单**提示词级**，越权写被拒 |
| AP6 | 交付物→**harness/**、三件套→`.trae/specs` |
| AP7 | 原生 `checklist.md` ≈ **完成性 gate** |
| AP8 | **RULE.md 钩子**生效 |
| AP9 | SubAgent **可并行可串行、无自动循环** |
| AP10 | **retry 重派机制**（改 tasks.md + 重派） |
| AP11 | **浏览器代行链路**（方案1：Orchestrator 代行 MCP→browser-check.md→Evaluator 读） |

**Stage adaptive（设计行为 AP12–AP14）**

| 编号 | 行为 |
|------|------|
| AP12 | **codraft 共识子阶段**（Generator 草稿→Evaluator 敲定标准） |
| AP13 | **真 retry→pass 自适应闭环**（R1 FAIL→retry→R2 PASS） |
| AP14 | **depends_on 门控**（probe 未 passed 不开工 adaptive） |

```
.trae/skills/{planner-role,generator-role,evaluator-role,decision-role,stage-executor}/SKILL.md   # 5 个，可被云端加载
RULE.md                                                                              # 钩子目标
harness/
├── templates/{spec,tasks,checklist,stage-contract}.skeleton.md
├── state-board.json                         # 已重置: probe(planned) + adaptive(planned, depends_on=[probe])
└── milestones/harness-selftest/
    ├── milestone-plan.md                    # ★ 自检计划（AP1–AP14；probe=planned, adaptive=codraft）
    ├── stages/probe/                        # AP1–AP11 交付物落点（contract/gen/eval/decision/browser-check）
    └── stages/adaptive/                     # AP12–AP14 交付物落点（codraft + retry→pass + sample.json）
```

## 如何运行（v4.4，单条提示词，AP1–AP14）

见 **`test-prompt.md`**：
1. 一次性配置 RULE.md 云端钩子规则（AP8 前提）+ 启用 Playwright MCP（AP4/AP11，你已配）。
2. **复制 `test-prompt.md` 第 1 步那一整段**发给 TRAE Work——一次跑完两个 Stage（probe + adaptive）、AP1–AP14。
3. 跑完让它把 14 行 `VERIFY[APn]` 汇总成表并 push 到 main。

## 如何判读

对照 `expected-outcome.md` 的"本次 v4.4 综合重跑"表，把 14 行 VERIFY 与产物登记进去。重点确认：AP11 浏览器代行链路通、AP12 codraft 走了草稿→敲定、AP13 真 retry→pass（非只演示一次重派）、AP14 门控生效；三件套落 `.trae/specs`、交付物落 harness。任一 FAIL → 按主文档对应章节降级/调整。
