# Harness Self-Test（平台能力 PoC 自检集）

> 目的：在**真实 TRAE Work** 上验证本设计依赖的平台能力假设 **AP1–AP10**，避免"纸面设计、真机跑不通"。
> 环境**已在本仓库实例化**（无需先跑 advisor）：`.trae/skills/` 四个 Skill、根目录 `RULE.md`、`harness/`（templates + state-board + 自检 Milestone）都已就绪。

## 它验证什么（AP1–AP10）

| 编号 | 假设 | 为什么重要 |
|------|------|-----------|
| **AP1** | stage-executor Skill 能按触发短语**自动加载**（主 Agent 侧 auto-load） | "单一拉起入口"的前提 |
| **AP2** | 派发的 SubAgent 能加载**指定角色 Skill**（@generator-role / @evaluator-role） | 角色分离的地基 |
| **AP3** | SubAgent 拥有**独立上下文**（隔离，看不到对方推理） | "杜绝自评偏差"的地基 |
| **AP4** | SubAgent 能调用 **MCP**（如 Playwright） | Evaluator 浏览器/外部验证 |
| **AP5** | 路径白名单为**提示词级**——越权写会被拒绝 | 验证"best-effort 非沙箱"结论 |
| **AP6** | 交付物能写入 **harness/ 总线**（不依赖 `.trae/specs/`） | "harness/ 是唯一总线"的地基 |
| **AP7** | 原生 `checklist.md` ≈ **tasklist 完成性** gate | 两类验收分工的地基 |
| **AP8** | **RULE.md 钩子**生效（任务启动自动读 RULE.md） | 项目级规范自治的前提 |
| **AP9** | SubAgent **可并行可串行，但不能自动循环（loop）** | "顺序模拟对抗、手动重派、无自动循环"设计的依据 |

## 已构造的环境

```
.trae/skills/{planner-role,generator-role,evaluator-role,decision-role,stage-executor}/SKILL.md   # 5 个，可被云端加载
RULE.md                                                                              # 钩子目标
harness/
├── templates/{spec,tasks,checklist,stage-contract}.skeleton.md
├── state-board.json                         # 已 seed + 重置: harness-selftest / probe (planned)
└── milestones/harness-selftest/
    ├── milestone-plan.md                    # ★ 自检计划（AP1–AP10 的 VERIFY 指令 + contract_mode=planned）
    └── stages/probe/                        # 运行时交付物落点（contract/gen/eval/decision；三件套去 .trae/specs）
```

## 如何运行（v4.3，单条提示词）

见 **`test-prompt.md`**：
1. 一次性配置 RULE.md 云端钩子规则（AP8 前提）+ 启用 Playwright MCP（AP4，你已配）。
2. **复制 `test-prompt.md` 第 1 步那一整段**发给 TRAE Work——一次跑完 AP1–AP10（含 MCP、AP9 真并行、AP10 retry、Decision 独立）。
3. 跑完让它把 10 行 `VERIFY[APn]` 汇总成表并 push 到 main。

## 如何判读

对照 `expected-outcome.md` 的"本次 v4.3 重跑"表，把 10 行 VERIFY 结果与实际产物登记进去。重点确认 Decision 是独立子代理写的、AP4 的 `mcp__Playwright__*` 是否可见、三件套是否落 `.trae/specs`。任一 FAIL → 按主文档对应章节降级/调整。
