# Harness Engineering 方法论参考

> 本文是 `trae-harness-advisor` Skill 的方法论参考文件（v4.0）。
> 完整文档见 `../resources/harness-engineering-on-trae-work.md`，术语权威定义见其"第零部分"。

## 目录

1. [核心概念（Milestone/Stage/Task）](#核心概念)
2. [核心定义](#核心定义)
3. [五层分层体系](#五层分层体系)
4. [PGE+D 四角色 + 执行分层](#pged-四角色--执行分层)
5. [两类验收的分工](#两类验收的分工)
6. [Stage Contract 协议](#stage-contract-协议)
7. [上下文隔离方案](#上下文隔离方案)
8. [TRAE Work 能力映射](#trae-work-能力映射)
9. [与 Claude Code 的对比](#与-claude-code-的对比)

## 核心概念

三级层次（严格定义，禁用 feature/sprint）：

| 层 | 名称 | 定义 | 载体 |
|----|------|------|------|
| 顶 | **Milestone** | 一次 Planner 对话覆盖的完整研发/验收过程（`kind: development \| verification`） | `harness/milestones/{milestone}/` + board |
| 中 | **Stage** | Milestone 下可独立验收的增量，可声明 `depends_on`、可并发 | milestone-plan 一项 + 一次 `/spec` |
| 底 | **Task** | Stage 内 `tasks.md` 的一个执行步骤（Trae 原生） | `tasks.md` 勾选项 |

- 持久真值与消息总线统一在 **`harness/`**；`.trae/specs/` 仅原生临时 scratch（销毁、gitignore、不依赖）。

## 核心定义

**Agent = Model + Harness**（LangChain, 2026）。凡不是模型本身的部分，就是 Harness。

**四大核心问题**：模型无法自我评估（pathological optimist）、上下文腐化（Context Rot）、缺乏持久状态、单一 Prompt 触顶。

## 五层分层体系

```
L4: Steering Layer     — 人类反馈、Harness 自我迭代、质量监控
L3: Verification Layer — Linter、Test、LLM-as-Judge、Browser Validation
L2: Orchestration Layer — SubAgent 调度、上下文重置、Compaction
L1: Execution Layer    — Filesystem、Bash、Sandbox、Browser、MCP
L0: Context Layer      — Rules、Skills、AGENTS.md、知识库
```

## PGE+D 四角色 + 执行分层

| 层级/角色 | 职责 | 输出 | 实现方式 |
|-----------|------|------|----------|
| **Advisor Skill** | 一次性初始化基础设施 | 角色 Skill + stage-executor + 骨架模板 + RULE.md + 空 board | 问答→生成 |
| **Planner** | Milestone→Stage 战略分解 | `milestone-plan.md` + 初始化 board | Milestone 规划对话 |
| **Orchestrator** | 每 Stage 运行时产三件套 + 派发 | spec/tasks/checklist（持久化 harness/）+ 回写 board | stage-executor playbook |
| **Generator** | 按 Stage 实现，TDD | 代码、测试、git commit、`gen.md` | SubAgent + Skill |
| **Evaluator** | 业务质量四维评分（task 内部） | `eval.md` | SubAgent + Skill + Playwright MCP |
| **Decision** | 中立裁决（Orchestrator 代理） | `decision.md`（pass/retry/escalate） | SubAgent（只读） |

**核心洞察**：
- 模型无法自我批判。Generator 和 Evaluator 必须运行在独立 SubAgent 中，拥有独立上下文。
- Decision 是裁决代理——TRAE Work 没有内置 Orchestrator，Decision 通过"只读 gen.md + eval.md → 输出裁决"模拟其决策功能。
- 三件套由 Orchestrator 运行时按骨架产出（不预生成），future-proof 于 Agent 能力迭代。

## 两类验收的分工

**不同维度，严禁混淆**：

| 验收 | 定位 | 回答 | 载体 |
|------|------|------|------|
| **Checklist** | 底层机制：Trae 原生完成性 gate | tasklist 是否执行完成 | `checklist.md` |
| **Evaluator** | 业务质量：我们编排、在 task 内部运行的对抗验收 | 业务质量是否过关（四维） | `eval.md` |

Checklist = 平台底层"做没做完"；Evaluator = 我们编排的偏业务"做得好不好"（即 tasks.md 的 `[EVALUATOR]` 步骤）。

## Stage Contract 协议

端到端 10 步（步骤 1 为 Planner 规划、2 为 Orchestrator 起 Stage、10 为完成性 gate；步骤 3-9 是单 Stage 的**顺序模拟对抗**，最多 3 轮返工，超限 escalate）：
1. Planner 输出 `milestone-plan.md`（Milestone + Stage 定义）
2. Orchestrator 经 stage-executor 起当前 Stage，按骨架产三件套 → 持久化 harness/
3. Generator 提出 Stage Contract 草案 → contract.md
4. Evaluator 审查 Contract（最多 3 轮协商）
5. 双方达成一致
6. Generator 按 Contract 实现（TDD）
7. Generator 自检 + git commit + 实现总结 → gen.md
8. Evaluator 业务质量四维评分 → eval.md
9. Decision 读取 gen.md + eval.md → 裁决（pass/retry/escalate，rounds≤3）
10. Checklist 完成性 gate 通过 → Orchestrator 回写 board

> 调研：TRAE Work 的 Task 下 SubAgent 只能**顺序执行**，无真实控制流循环；对抗为同一 Stage 对话内顺序模拟。

## 上下文隔离方案

三层隔离：
- L1 角色级 — Planner/Generator/Evaluator/Decision 各自独立 SubAgent
- L2 任务级 — 每个 Stage 独立 Generator 实例
- L3 路径级 — 路径白名单限制文件访问范围（提示词级，非沙箱强制）

共享状态：`harness/` 是 SubAgent 之间唯一的持久通信总线。

## TRAE Work 能力映射

| Harness 层 | TRAE Work 能力 |
|-----------|---------------|
| L0: Context | RULE.md（钩子加载）、Skills |
| L1: Execution | 文件系统、Bash、Sandbox、MCP |
| L2: Orchestration | `/spec` 工作流、SubAgent 调度、stage-executor、Decision 裁决 |
| L3: Verification | MCP（Playwright、Linter） |
| L4: Steering | 人类审查 Stage `/spec` 暂停确认、escalate 升级裁决 |

## 与 Claude Code 的对比

| 维度 | Claude Code | TRAE Work（我们的实现） |
|------|-------------|----------------------|
| Orchestrator | 内置，全自动路由和调度 | 拼装式：RULE.md 钩子 + Skills + stage-executor + SubAgent + Decision + 人类 |
| 自动化程度 | 全自动 | 半自动（人类逐 Stage 触发 /spec，之后顺序模拟对抗） |
| 角色定义 | `.claude/agents/` 下 Markdown | `.trae/skills/` 下 Skills（+ 可选 `.trae/agents/`） |
| 上下文隔离 | 内置，每角色独立上下文 | SubAgent 独立上下文（手动配置） |
| 费用 | 付费 | 免费（TRAE Work 免费版） |

**方法论效果可以追齐，自动化程度无法追齐。**
