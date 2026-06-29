# Trae Harness Advisor

> Harness Engineering 在 TRAE Work 上的最佳实践——Planner-Generator-Evaluator-Decision 四角色多智能体对抗架构，三层推理流程

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
│   │   └── harness-engineering-on-trae-work.md        # 方法论与架构完整文档（v3.1）
│   └── templates/                                     # 可复用模板（10 个文件）
│       ├── spec-template.md                           # SPEC 空模板（Planner 生成框架，主Agent 填充）
│       ├── planner-skill-template.md                  # Planner 角色 Skill 模板
│       ├── generator-skill-template.md                # Generator 角色 Skill 模板（含 Agent 工具集和路径白名单）
│       ├── generator-agent-template.md                # Generator Agent 配置模板（可选，未来兼容）
│       ├── evaluator-skill-template.md                # Evaluator 角色 Skill 模板（含 Decision 角色定义）
│       ├── evaluator-agent-template.md                # Evaluator Agent 配置模板（可选，未来兼容）
│       ├── decision-agent-template.md                 # Decision Agent 配置模板（可选，未来兼容）
│       ├── project-rules-template.md                  # RULE.md 模板（项目根目录，钩子规则加载）
│       ├── sprint-contract-template.md                # Sprint Contract 模板
│       └── eval-report-template.md                    # 评估报告模板
├── conversation-context-and-design-decisions.md       # 会话上下文与设计决策记录
├── archive/                                           # 过程档案
│   ├── harness-engineering-on-trae-work-plan.md       # v1.0 编写计划
│   └── supplement-and-alignment-plan.md               # v2.0 补充对齐计划
└── docs/                                              # 外部文档
    └── harness-engineering-on-trae-work/              # HTML 报告（人类可读）
```

## Skill 是什么

`trae-harness-advisor` 是一个 TRAE Work 平台上的 Harness Engineering 专家技能。它通过结构化问题引导用户理清项目上下文和定制需求，然后一键生成完整的 PGE+D（Planner-Generator-Evaluator-Decision）四角色多智能体对抗架构配置。

**核心设计思想**：在 TRAE Work 免费版的能力范围内，通过组合 SPEC + Skills + RULE.md 钩子规则等原生能力，"拼装"出一个模拟 Claude Code 内置 Orchestrator 的编排系统。方法论效果可以追齐 Claude Code 的 Harness 编排——角色分离、上下文隔离、对抗验证——但调度仍需人类触发（半自动）。

**三层推理流程**（v3.0 核心）：

| 层级 | 角色 | 职责 | 输出 |
|------|------|------|------|
| 第一层 | **专家 Skill** | 初始化 Harness 基础设施，根据技术栈定制规范 | Skills + RULE.md + tasks-pattern.md + sprint-N.md 模板 + 钩子规则文本 |
| 第二层 | **Planner** | 理解业务需求，拆分 Sprint 大方向，生成空模板 | sprint-plan.md（全局规划）+ spec.md（空模板） |
| 第三层 | **主Agent** | 运行时推理填充 spec.md → 生成 tasks.md → 调度 SubAgent | 填充后的 spec.md + tasks.md |
| 执行层 | **Generator/Evaluator/Decision** | 对抗循环执行 | 代码 + 评估报告 + 裁决 |

**v3.1 TRAE Work 兼容性修正**：

| 配置项 | 云端支持？ | 处理方式 |
|--------|-----------|---------|
| `.trae/skills/` | 是，自动按需加载 | 保留，唯一云端自动加载通道 |
| `.trae/rules/` | 否 | 删除，改为 RULE.md + 钩子规则 |
| `.trae/agents/` | 否（当前） | 保留为可选，角色行为内嵌到 Skill 中 |

**生成的文件**（核心 6 个文件 + 1 段钩子规则文本 + 可选 3 个）：

- 3 个角色 Skill（Planner、Generator、Evaluator）— Generator 含 Agent 工具集和路径白名单，Evaluator 含 Decision 角色定义
- RULE.md（项目根目录，TRAE Work 云端通过钩子规则加载）
- 钩子规则文本（用户复制到「设置 > 规则」的一次性配置）
- 编排模式参考（tasks-pattern.md）
- Sprint Contract 模板
- 可选全局任务看板
- 可选 3 个 Agent 配置文件（供未来兼容）

**目录解耦**：业务文档（spec、contracts）默认放在项目根目录（`harness-specs/`、`harness-contracts/`），不绑定 `.trae/`。所有路径支持用户自定义配置。

**与 Claude Code 的差异**：见主文档 1.4 节和 3.9 节。简言之：Claude Code 是"全自动挡汽车"，我们是在"手动挡汽车"上安装了"辅助驾驶系统"。

## 安装 Skill

将 `trae-harness-advisor/` 目录打包为 `.zip`，在 TRAE IDE 中通过 **设置 → 技能与命令 → 创建 → 导入外部技能** 上传即可。

或者直接复制到项目的 `.trae/skills/trae-harness-advisor/` 目录下。

## 给后续 Agent 的指引

如果你是一个被要求继续优化此 Skill 的 Agent，请按以下顺序阅读：

1. **`trae-harness-advisor/resources/harness-engineering-on-trae-work.md`** — Harness Engineering 在 TRAE Work 上的完整方法论（v3.1，含 Claude Code 对标分析、三层推理流程、TRAE Work 兼容性）
2. **`conversation-context-and-design-decisions.md`** — 本项目起源、关键决策及理由（含三层推理、目录解耦、RULE.md 钩子方案等决策）
3. **`trae-harness-advisor/SKILL.zh.md`** — Skill 的工作流程（7 步，含三层推理 I/O 契约）
4. **`trae-harness-advisor/references/deliverable-specs.md`** — 文件生成详细规格（核心 6 个文件 + 钩子规则文本 + 可选 3 个交付物）
5. **`trae-harness-advisor/templates/`** — 10 个模板文件

**关键架构要点**（请勿回退）：
- 三层推理流程：专家(基础设施) → Planner(全局规划+空模板) → 主Agent(推理填充spec→生成tasks) → SubAgent(执行)
- 四角色架构：Planner + Generator + Evaluator + Decision
- `.trae/rules/` 已删除，改为 RULE.md + 钩子规则方案
- `.trae/agents/` 保留为可选生成，Agent 角色行为已内嵌到 Skill 中
- 业务文档默认不绑定 `.trae/`（`harness-specs/`、`harness-contracts/`），所有路径可配置

## 方法论来源

本项目基于以下业界 Harness Engineering 实践的调研和整合：

| 来源 | 核心贡献 |
|------|---------|
| Mitchell Hashimoto | 6 阶段 AI 采用框架，阶段 5 = "工程化 Harness" |
| OpenAI | 0 人类代码行、100 万行生成代码、Context Engineering + Architectural Constraints |
| Anthropic | Pattern A（Initializer + Coding Agent）和 Pattern B（Planner-Generator-Evaluator） |
| Martin Fowler | Feedforward vs Feedback、Computational vs Inferential |
| LangChain | Agent = Model + Harness |
| Claude Code | `.claude/agents/` 静态 Harness、Dynamic Workflows（6 种编排模式）、内置 Orchestrator |