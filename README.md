# Trae Harness Advisor

> Harness Engineering 在 TRAE Work 上的最佳实践——Advisor → Planner → Orchestrator → Generator/Evaluator/Decision 的 Milestone/Stage/Task 多智能体对抗架构（v4.2）

---

## 项目结构

```
.
├── README.md                                          # 本文件
├── trae-harness-advisor/                              # Skill 目录（可打包安装）
│   ├── SKILL.md                                       # Skill 主文件（英文版）
│   ├── SKILL.zh.md                                    # Skill 主文件（中文版）
│   ├── references/                                    # 渐进式披露参考
│   │   ├── harness-methodology.md                     # 方法论浓缩参考
│   │   └── deliverable-specs.md                       # 文件生成规格
│   ├── resources/                                     # Skill 运行时引用
│   │   └── harness-engineering-on-trae-work.md        # 方法论与架构完整文档（v4.2）
│   └── templates/                                     # 可复用模板（14 个文件）
│       ├── planner-skill-template.md                  # Planner 角色 Skill 模板
│       ├── generator-skill-template.md                # Generator 角色 Skill 模板（含路径白名单）
│       ├── evaluator-skill-template.md                # Evaluator 角色 Skill 模板（业务质量评分）
│       ├── decision-skill-template.md                 # Decision 独立裁决者 Skill 模板
│       ├── stage-executor-skill-template.md           # Orchestrator 运行时 playbook Skill 模板
│       ├── spec.skeleton.md                           # Stage 规格骨架
│       ├── tasks.skeleton.md                          # Stage 任务骨架（G/E/D 顺序步骤）
│       ├── checklist.skeleton.md                      # 完成性 gate 骨架
│       ├── stage-contract.skeleton.md                 # Stage Contract 骨架
│       ├── generator-agent-template.md                # Generator Agent 配置模板（可选，未来兼容）
│       ├── evaluator-agent-template.md                # Evaluator Agent 配置模板（可选，未来兼容）
│       ├── decision-agent-template.md                 # Decision Agent 配置模板（可选，未来兼容）
│       ├── project-rules-template.md                  # RULE.md 模板（项目根目录，钩子规则加载）
│       └── eval-report-template.md                    # 业务质量评估报告模板
├── conversation-context-and-design-decisions.md       # 会话上下文与设计决策记录
│
│   # ↓↓↓ 以下为「自检 PoC 实例化环境」——由模板实例化，供真机 TRAE Work 跑 harness-selftest ↓↓↓
├── .trae/skills/                                      # 已实例化的 5 个角色/playbook Skill（可被云端加载）
│   ├── planner-role/SKILL.md
│   ├── generator-role/SKILL.md
│   ├── evaluator-role/SKILL.md                        # 业务质量四维评分（不含裁决）
│   ├── decision-role/SKILL.md                         # 独立中立裁决者（独立 SubAgent）
│   └── stage-executor/SKILL.md                        # Orchestrator 运行时 playbook（只串联）
├── RULE.md                                            # 项目规范（钩子规则加载目标）
├── harness/                                           # 持久真值 + 消息总线
│   ├── templates/{spec,tasks,checklist,stage-contract}.skeleton.md
│   ├── state-board.json                               # 已 seed: harness-selftest/probe
│   └── milestones/harness-selftest/milestone-plan.md  # 可直接运行的自检计划（AP1–AP10）
├── poc/                                               # 平台能力自检 PoC（人类可读测试套件）
│   └── harness-selftest/
│       ├── README.md                                  # 如何运行与判读
│       ├── test-prompt.md                             # ★ 复制粘贴到 TRAE Work 的测试提示词
│       └── expected-outcome.md                        # AP1–AP10 判读表 + 结果记录
├── archive/                                           # 过程档案
│   ├── harness-engineering-on-trae-work-plan.md       # v1.0 编写计划
│   └── supplement-and-alignment-plan.md               # v2.0 补充对齐计划
└── docs/                                              # 外部文档
    └── harness-engineering-on-trae-work/              # HTML 报告（人类可读）
```

> 说明：`trae-harness-advisor/` 是**可打包安装的 Skill 本体**；而 `.trae/skills/`、`RULE.md`、`harness/` 是**为自检 PoC 实例化的运行环境**（相当于对本仓库跑了一遍 advisor 的产物），让你无需先生成即可直接在真机验证平台能力。

## Skill 是什么

`trae-harness-advisor` 是一个 TRAE Work 平台上的 Harness Engineering 专家技能。它通过结构化问题引导用户理清项目上下文和定制需求，然后一键生成完整的 PGE+D（Planner-Generator-Evaluator-Decision）多智能体对抗架构配置。

**核心设计思想**：在 TRAE Work 免费版的能力范围内，通过组合 SPEC + Skills + RULE.md 钩子规则 + harness/ 持久消息总线，拼装出一个模拟 Claude Code 内置 Orchestrator 的编排系统。方法论效果可以追齐 Claude Code 的 Harness 编排——角色分离、上下文隔离、对抗验证——但调度仍需人类触发（半自动）。

**v4.0 三级层次与角色分工**：

| 层级 | 角色 | 职责 | 输出 |
|------|------|------|------|
| L0 | **Advisor Skill** | 一次性初始化 Harness 基础设施 | 5 个 Skill + RULE.md + 4 个 skeleton + state-board.json + 钩子规则文本 |
| L1 | **Planner** | 将需求规划为 Milestone，并拆成可独立验收的 Stage | milestone-plan.md + 初始化 state-board.json |
| L2 | **Orchestrator** | 每个 Stage 加载 stage-executor，运行 /spec 产三件套（留 .trae/specs）并**串联**对抗（自己不兼任角色） | 交付物 contract/gen/eval/decision 写 harness/ + 据裁决决定下一步（retry 改 tasks.md+重派）+ 状态回写 |
| 执行层 | **Generator/Evaluator/Decision**（各为独立 SubAgent） | 顺序模拟对抗：实现、业务质量评分、**独立中立裁决** | gen.md + eval.md + decision.md |

**TRAE Work 能力映射**：

| 配置项 | 云端支持？ | 处理方式 |
|--------|-----------|--------------|
| `.trae/skills/` | 是，自动按需加载 | 角色 Skill + stage-executor 的唯一云端自动加载通道 |
| `.trae/rules/` | 否 | 不使用；改为 RULE.md + 钩子规则 |
| `.trae/agents/` | 否（当前） | 保留为可选，角色行为内嵌到 Skill 中 |
| `.trae/specs/` | 原生临时区 | 仅作 /spec scratch，gitignored，不作为消息总线 |
| `harness/` | 普通项目目录 | 持久真值与跨 session 消息总线 |

**生成的文件**（11 个核心文件 + 1 段钩子规则文本；可选 3 个 Agent 配置）：

- 5 个 Skill：Planner、Generator、Evaluator（业务质量评分）、**Decision（独立裁决者）**、stage-executor
- RULE.md（项目根目录，TRAE Work 云端通过钩子规则加载）
- 4 个结构骨架：spec.skeleton.md、tasks.skeleton.md、checklist.skeleton.md、stage-contract.skeleton.md
- state-board.json v2（动态状态机唯一真值）
- 钩子规则文本（用户复制到「设置 > 规则」的一次性配置）
- 可选 3 个 Agent 配置文件（供未来兼容）

**关键架构要点**：

- 严格三级层次：Milestone > Stage > Task。
- SPEC 三件套在 Stage 层由 Orchestrator 运行时创建于 `.trae/specs/`（过程脚手架，不入 harness/git）；只有交付物 contract/gen/eval/decision + board 持久化到 `harness/`。
- `harness/` 是唯一持久真值与消息总线；`.trae/specs/` 是原生三件套 scratch（对话结束即弃）。
- 验收标准放 `contract.md`（不在 spec.md），故三件套不持久化不影响验收。
- 两类验收分工：checklist.md 是底层完成性 gate；Evaluator 是业务质量四维评估。
- 对抗流程为顺序模拟，最多 3 轮返工，超限 escalate 给人类。
- Contract 简化为 Orchestrator 起 Stage 时一次标注关键点（非多轮协商）。
- milestone-plan.md 是静态定义；state-board.json v2 是动态状态机唯一真值（最小更新，git 合并友好）。
- 并发 = 人类开多个独立对话推进；depends_on 是人工投递前的冲突规避依据，非自动调度。
- 约束强度：路径白名单/RULE.md 钩子/playbook 均为提示词级（best-effort），非沙箱强制，需 CI/评审兜底。

**与 Claude Code 的差异**：见主文档 1.4 节和 3.x 节。简言之：Claude Code 是“全自动挡汽车”，我们是在“手动挡汽车”上安装了“辅助驾驶系统”。

## 安装 Skill

将 `trae-harness-advisor/` 目录打包为 `.zip`，在 TRAE IDE 中通过 **设置 → 技能与命令 → 创建 → 导入外部技能** 上传即可。

或者直接复制到项目的 `.trae/skills/trae-harness-advisor/` 目录下。

## 给后续 Agent 的指引

如果你是一个被要求继续优化此 Skill 的 Agent，请按以下顺序阅读：

1. **`trae-harness-advisor/resources/harness-engineering-on-trae-work.md`** — Harness Engineering 在 TRAE Work 上的完整方法论（v4.2；先读第零部分核心概念定义，再读 4.1 stage-executor 与三件套骨架）
2. **`conversation-context-and-design-decisions.md`** — 本项目起源、关键决策及理由（含 v4.0/v4.1/v4.2 概念重构记录）
3. **`trae-harness-advisor/SKILL.zh.md`** — Skill 的工作流程与 I/O 契约
4. **`trae-harness-advisor/references/deliverable-specs.md`** — 文件生成详细规格（11 个核心文件 + 钩子规则文本 + 可选 Agent 配置）
5. **`trae-harness-advisor/templates/`** — 14 个模板文件，尤其是 stage-executor、decision-role 与四个 skeleton
6. **`poc/harness-selftest/`** — 平台能力自检套件 + 已实例化的 `.trae/skills`/`RULE.md`/`harness/` 环境，真机验证 AP1–AP10 假设

**请勿回退**：
- 不要恢复旧层级命名；统一使用 Milestone / Stage / Task。
- 不要让 Planner 生成 Stage 三件套；它们必须由 Orchestrator 运行时创建。
- 不要把 checklist.md 与 Evaluator 混为一谈。
- 不要依赖 `.trae/specs/` 做持久状态或消息传递。

## 方法论来源

本项目基于以下业界 Harness Engineering 实践的调研和整合：

| 来源 | 核心贡献 |
|------|---------|
| Mitchell Hashimoto | 6 阶段 AI 采用框架，阶段 5 = “工程化 Harness” |
| OpenAI | 0 人类代码行、100 万行生成代码、Context Engineering + Architectural Constraints |
| Anthropic | Pattern A（Initializer + Coding Agent）和 Pattern B（Planner-Generator-Evaluator） |
| Martin Fowler | Feedforward vs Feedback、Computational vs Inferential |
| LangChain | Agent = Model + Harness |
| Claude Code | `.claude/agents/` 静态 Harness、Dynamic Workflows（6 种编排模式）、内置 Orchestrator |
