# Harness Engineering 方法论参考

> 本文是 `trae-harness-advisor` Skill 的方法论参考文件（v4.6）。
> 完整文档见 `../resources/harness-engineering-on-trae-work.md`，术语权威定义见其"第零部分"。

## 目录

1. [核心概念（Milestone/Stage/Task）](#核心概念)
2. [核心定义](#核心定义)
3. [五层分层体系](#五层分层体系)
4. [PGE+D 四角色 + 执行分层](#pged-四角色--执行分层)
5. [两类验收的分工](#两类验收的分工)
6. [Stage Contract 协议](#stage-contract-协议)
7. [六种编排模式](#六种编排模式v45)
8. [上下文隔离方案](#上下文隔离方案)
9. [TRAE Work 能力映射](#trae-work-能力映射)
10. [与 Claude Code 的对比（含三档自动化）](#与-claude-code-的对比)

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
| **Advisor Skill** | 一次性初始化基础设施 | 角色 Skill + stage-orchestrator + 旧名 shim + 骨架模板 + RULE.md + 空 board | 问答→生成 |
| **Planner** | Milestone→Stage 战略分解 | `milestone-plan.md` + 初始化 board | Milestone 规划对话 |
| **Stage Orchestrator** | 每 Stage 运行时产三件套（留 .trae/specs）+ 派发 | 交付物 contract/gen/eval/decision 写 harness/ + 回写 board | stage-orchestrator playbook |
| **Generator** | 按 Stage 实现，TDD | 代码、测试、`gen.md` | SubAgent + Skill |
| **Evaluator** | 业务质量四维评分（task 内部） | `eval.md` | SubAgent + Skill；浏览器证据读 root Orchestrator 的 browser-check.md |
| **Decision** | 独立中立裁决 | `decision.md`（pass/retry/escalate） | SubAgent（只读） |

**核心洞察**：
- 模型无法自我批判。Generator 和 Evaluator 必须运行在独立 SubAgent 中，拥有独立上下文。
- Decision 是独立裁决者，通过只读 contract.md + gen.md + eval.md + board rounds 输出 pass/retry/escalate。
- 三件套由 Orchestrator 运行时按骨架产出（不预生成），future-proof 于 Agent 能力迭代。

## 两类验收的分工

**不同维度，严禁混淆**：

| 验收 | 定位 | 回答 | 载体 |
|------|------|------|------|
| **Checklist** | 底层机制：Trae 原生完成性 gate | tasklist 是否执行完成 | `checklist.md` |
| **Evaluator** | 业务质量：我们编排、在 task 内部运行的对抗验收 | 业务质量是否过关（四维） | `eval.md` |

Checklist = 平台底层"做没做完"；Evaluator = 我们编排的偏业务"做得好不好"（即 tasks.md 的 `[EVALUATOR]` 步骤）。

## Stage Contract 协议

端到端 8 步（步骤 1 为 Planner 规划、2 为 Orchestrator 起 Stage、8 为完成性 gate；步骤 3-7 是单 Stage 的**LLM 驱动动态编排**，最多 3 轮返工，超限 escalate）：
1. Planner 输出 `milestone-plan.md`（Milestone + Stage 定义）
2. Orchestrator 经 stage-executor 起当前 Stage，按骨架产三件套（留 .trae/specs，过程脚手架），只把交付物 contract/gen/eval/decision 写入 harness/ 总线
3. 定 contract.md（按 Stage 的 `contract_mode`）：**planned**=Orchestrator 据 plan 要点+契约直接写；**codraft**=Generator 草稿+提议标准→Evaluator 敲定→写 contract.md（再对抗）
4. Generator 按 contract.md 实现（TDD）
5. Generator 自检 + git commit + 实现总结 → gen.md
6. Evaluator 业务质量四维评分 → eval.md
7. Decision 读取 gen.md + eval.md → 裁决（pass/retry/escalate，rounds≤3）
8. Checklist 完成性 gate 通过 → Orchestrator 回写 board

> 调研（v4.4 真机纠正）：TRAE Work 的 Orchestrator（主 agent）真机验证具备**顺序/分支/有界循环/跳出/自修改 tasks.md/持久状态**——即**图灵完备的动态编排底座**；叠加子代理 Shell(RunCommand) 可实现真正自适应的 PGE。Stage 内 G→E→D 因数据依赖串行，多轮返工由 Orchestrator 在同一对话内驱动有界循环（≤3 轮），并非"无 loop 靠手动重派"。唯一无法追齐的是平台级"跨 Stage 自动调度"（半自动，见文末对比）。

## 六种编排模式（v4.5）

同一套原语（顺序/分支/并行派发/有界循环/自修改 tasks.md/持久 board）可组合出 Claude Code Dynamic Workflows 的 6 种模式，Stage 层用 `pattern` 字段路由（Planner 标注，默认 `adversarial`）：

| pattern | 何时用 | 内置/需生成 |
|---|---|---|
| **adversarial**（PGE，默认） | 做一件事并保质量 | stage-executor 内置 |
| **loop** | 反复精炼到达标（=retry 泛化） | stage-executor 内置 |
| **classify** | 先判类再路由 | `generate_patterns=true` |
| **fanout** | N 个独立子任务并行再合并 | `generate_patterns=true` |
| **generate-filter** | 多候选优中选优 | `generate_patterns=true` |
| **tournament** | 候选多、两两淘汰更稳 | `generate_patterns=true` |

多模式包额外生成 3 个轻量角色（Classifier/Synthesizer/Selector）+ 4 个 pattern playbook；6 种模式已真机端到端验证（AP1–AP18）。AP19 已验证 Evaluator 可通过项目 shell bridge 在 SubAgent 上下文内受控调用 MCP wrapper。

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
| 自动化程度 | 全自动 | 半自动（人类逐 Stage 触发 /spec，Stage 内 LLM 驱动动态编排）；可选三档提升 |
| 角色定义 | `.claude/agents/` 下 Markdown | `.trae/skills/` 下 Skills（+ 可选 `.trae/agents/`） |
| 上下文隔离 | 内置，每角色独立上下文 | SubAgent 独立上下文（手动配置） |
| 费用 | 付费 | 免费（TRAE Work 免费版） |

**方法论效果可以追齐，自动化程度默认半自动，可按需提升。**

### 三档自动化（v4.6.1）：谁当 Stage Dispatcher

把原"人节点"拆成 **Supervisor/Lead**（规划确认、review、escalate/BLOCKED、授权、最终仲裁——判断、不可外包）+ **Stage Dispatcher**（搬运 Stage 上下文、开执行对话、贴 `@stage-orchestrator`、读 decision 推进——机械、可外包）。据此三档自选：

| 档 | Stage Dispatcher | 效果 | 前提 |
|---|---|---|---|
| **A** | 人 | 现状：人兼 Lead + Dispatcher + Supervisor | 低频、重决策 |
| **B** | Codex/CUA | 机器替代执行派发，人只处理判断 | 受 CUA 可靠性/成本/平台 ToS 约束 |
| **C** | 强 LLM 父 agent 走 TRAE API | 最干净，API 编排 | 依赖平台暴露 API |

B 档收益随模式不同（fanout/tournament/generate-filter 最大——机器分批替代人分批）。逻辑固化为可选文件 **Stage Dispatcher**（`{harness_dir}stage-dispatcher.md`，`generate_stage_dispatcher=true`），**不放进 `.trae/skills/`**。无论哪档，规划确认、review、escalate/纠偏/授权/最终仲裁永远归 Supervisor/Lead。详见主文档 §1.4.5。
