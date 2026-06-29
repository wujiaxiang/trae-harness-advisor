# Harness Engineering on TRAE Work：Planner-Generator-Evaluator 多智能体对抗架构最佳实践

> **版本**: v4.4  
> **日期**: 2026-06-29  
> **变更**: v4.4 基于 v4.3 真机重跑：①**重要发现——动态编排=图灵完备底座**：Orchestrator 真机验证具备顺序/分支/有界循环/跳出/自修改 tasks.md/持久状态，叠加子代理 Shell(RunCommand) → 可实现**真正自适应的 PGE 流程**（注脚：推理级控制、有界、确定性不可追齐）；"顺序模拟对抗"措辞升级为"LLM 驱动的动态编排"；②**子代理工具能力实测**：17 个工具含 Web+Shell，**唯缺 MCP**；③**AP4 决定性结论 + 方案1**：SubAgent 不继承 MCP → `verification_mode=full` 浏览器验证改由 **Orchestrator 代行 MCP**，证据写 `browser-check.md` 供 Evaluator 评分；④v4.3 全部改动（Decision 独立、retry 闭环 AP10、三件套→.trae/specs）真机验证成立  
> **v4.3**: 验收标准来源澄清 + per-Stage `contract_mode`（planned/codraft 可选共识子阶段）  
> **v4.2**: Decision 独立 SubAgent（decision-role）、Orchestrator 只串联不兼任角色、retry 闭环 AP10、三件套只留 .trae/specs 不入 harness、核心 Skill 5/文件 11  
> **v4.1**: ①外部引用逐条核实；②`.trae/specs/` 降为可弃、subagent 写 `harness/` 总线；③Contract 简化为 Orchestrator 一次标注；④board 最小更新写协议、并发=人工多对话；⑤约束强度=提示词级措辞；⑥新增 `poc/harness-selftest/` 自检集  
> **v4.0**: 概念重构——引入 **Milestone / Stage / Task** 三级层次（弃用 feature、sprint）；SPEC 三件套下沉 **Stage 层**由 Orchestrator 运行时创建；新增 **stage-executor playbook**；checklist（底层机制完成性 gate）与 Evaluator（业务质量对抗）分工去重；对抗改顺序模拟最多 3 轮超限 escalate；`state-board.json` v2；持久总线统一 `harness/`  
> **v3.1**: 基于 TRAE Work 平台能力调研，删除 `.trae/rules/`（云端不支持），改为 RULE.md + 钩子规则方案；Agent 配置保留为可选生成（未来兼容）  
> **v3.0**: 三层推理流程、目录解耦、Planner 只生成空模板（运行时填充）  
> **v2.0**: Claude Code 对标分析、四角色架构、Decision 角色、Planner 职责收窄  
> **目标读者**: LLM/Agent（读完后能理解并实现多智能体对抗工作流），同时兼容人类开发者阅读  
> **基于平台**: TRAE Work（截至 2026 年 6 月最新能力）  
> **关联文档**: 本项目的会话背景、设计决策和已知限制见 `../../conversation-context-and-design-decisions.md`  
> **配套 Skill**: `trae-harness-advisor` — 自动化 Harness 项目改造（见 `../` 即当前 Skill 目录）

---

## 目录

0. [第零部分：核心概念定义](#第零部分核心概念定义)
1. [第一部分：Harness Engineering 方法论综述](#第一部分harness-engineering-方法论综述)
2. [第二部分：TRAE Work 平台能力分析](#第二部分trae-work-平台能力分析)
3. [第三部分：TRAE Work 上的 Harness 架构设计](#第三部分trae-work-上的-harness-架构设计)
4. [第四部分：实战指南](#第四部分实战指南)
5. [第五部分：从开发到验收的完整流程示例](#第五部分从开发到验收的完整流程示例)
6. [附录](#附录)

---

## 第零部分：核心概念定义

> 本节是全文术语的唯一权威定义。所有角色、Skill、模板必须严格遵循此处定义，不得自创同义词或混用。

### 0.1 三级工作层次

本方法论把一个研发/验收工作拆成严格的三级层次：

| 层 | 名称 | 定义 | 边界判据 | 物理载体 |
|----|------|------|----------|----------|
| 顶 | **Milestone（里程碑）** | 一次 Planner 对话所覆盖的**完整研发或验收过程**，通常对应一个交付里程碑 | 能独立成篇规划；标注 `kind: development \| verification` | `harness/milestones/{milestone}/` + `state-board.json` 一条 |
| 中 | **Stage（阶段）** | Milestone 下一个**可独立验收的增量**，允许声明依赖、可部分并发 | 有独立验收标准；一次云端对话内可完成 | `milestone-plan.md` 的一项 + 一次 `/spec` 执行实例 |
| 底 | **Task（任务）** | Stage 内 `tasks.md` 的一个**执行步骤**（TRAE Work SPEC 原生概念） | 单步可执行 | 持久化的 `tasks.md` 勾选项 |

**命名约定（强约束）**：
- 全文统一使用 **Milestone / Stage / Task**。**禁止**使用 `feature`、`sprint` 作为层级名（历史版本遗留概念）。
- Anthropic Pattern A 文献中的 “Feature 分解” ≈ 本设计的 **Stage 分解**；引用该文献时须注明此对应关系，避免与"里程碑/阶段"混淆。
- “Stage” 取"可独立验收的增量"之义，**不是**敏捷的时间盒 Stage；它允许并发，靠 `depends_on` 表达顺序，而非固定迭代周期。

### 0.2 两类"验收"的分工（关键区分）

本方法论存在两个**不同维度**、互不重叠的验收，**严禁混为一谈**：

| 验收 | 定位 | 谁产出 | 回答的问题 | 载体 |
|------|------|--------|-----------|------|
| **Checklist** | **底层机制**：TraeWork 原生完成性 gate | Orchestrator（SPEC 原生 `checklist.md`） | 该 Stage 的 **tasklist 是否执行完成**、原生验收项是否满足 | `checklist.md` |
| **Evaluator** | **业务质量**：我们自己编排、在 **task 内部**运行的对抗验收 | Evaluator SubAgent（四维评分） | 做出来的东西**业务质量是否过关**（功能性/工艺/完整性/体验） | `eval.md` |

Checklist 是**平台底层机制**的"做没做完"闸门；Evaluator 是**我们编排的、偏业务**的"做得好不好"对抗质量门，作为 `tasks.md` 的 `[EVALUATOR]` 步骤在 task 内部执行。

### 0.3 持久化与临时产物（消息总线）

- **`harness/` 是唯一的持久真值与跨 session 消息总线**（可 git 同步，不绑定 IDE 实现）。角色之间通过 `harness/` 下的文件传递状态。
- **SPEC 三件套（spec.md / tasks.md / checklist.md）= 过程脚手架，只放 `.trae/specs/`**：由原生 `/spec` 产出。它们在**同一个 Stage 对话内**有效，G/E/D 子代理在对话内可直接读取；对话结束即弃、**不进 git、不复制到 `harness/`**。丢了能靠 `milestone-plan.md` + 重跑 `/spec` 再生。
- **只有"交付物/证据"才持久化到 `harness/` 总线**：`contract.md`（验收要点）、`gen.md`（实现产出）、`eval.md`（质量评估）、`decision.md`（裁决）、`state-board.json`（状态）。
- **验收标准在 `contract.md`，不在 spec.md**——所以三件套不持久化不影响 Evaluator/Decision 验收（它们读 contract.md 拿验收要点）。

---


## 第一部分：Harness Engineering 方法论综述

### 1.1 什么是 Harness Engineering？

LangChain 在 2026 年 3 月的文章《The Anatomy of an Agent Harness》中给出了一个简洁的定义：**Agent = Model + Harness**。凡不是模型本身的部分，就是 Harness。

这个定义看似简单，却揭示了一个根本性的范式转变。传统的 Prompt Engineering 关注的是"告诉 AI 做什么"——通过精心设计的提示词引导模型的行为。Harness Engineering 则关注"构建一个让 AI 在其中可靠工作的环境"——通过工具、规则、护栏、反馈回路和编排机制，将模型的能力约束在一个可控的框架内。

为什么需要 Harness？因为单一 Prompt 已经触及天花板。随着任务复杂度上升，以下问题变得不可回避：

- **模型无法自我评估**：Anthropic 的研究指出，当前模型是"病态乐观主义者"（pathological optimist），会高估自己输出质量，无法有效进行自我批判
- **上下文腐化（Context Rot）**：随着对话轮次增加，模型性能持续下降，注意力分散，出现跨模块误修改
- **缺乏持久状态**：单个对话会话无法跨任务保持状态，无法实现持续学习和迭代改进

Harness Engineering 正是为解决这些问题而生的方法论。

### 1.2 业界实践全景

#### 1.2.1 Mitchell Hashimoto 的 6 阶段 AI 采用框架

Mitchell Hashimoto（Hashicorp 创始人）在 2026 年的文章《My AI Adoption Journey》中提出了一个从个人实践到工程化采纳的 6 阶段框架：

| 阶段 | 名称 | 核心行为 | 关键转变 |
|------|------|----------|----------|
| 1 | 旁观者 | 在聊天界面使用 AI | 从零到开始使用 |
| 2 | 助手 | AI 辅助完成小任务 | 开始信任 AI 的局部能力 |
| 3 | 协作者 | 将明确任务外包给 AI | 从"我来做"到"AI 来做" |
| 4 | 自主代理 | 将更大任务委托给 AI | 从单次任务到持续任务 |
| 5 | **工程化 Harness** | 构建工具让 AI 不再犯同样的错 | 从"修复 Bug"到"修复产生 Bug 的系统" |
| 6 | 常驻代理 | 始终有 AI 代理在后台运行 | 从按需调用到持续运行 |

阶段 5 是本指南的核心。Hashimoto 的核心理念是：**每次智能体犯错，不是手动修复 Bug，而是构建一个工具（Harness 组件）让它以后不再犯同样的错**。这是一种系统性的质量改进方法，而非头痛医头的修补。

#### 1.2.2 OpenAI 的 Harness Engineering 实践

OpenAI 在 2025 年进行了为期 5 个月的 Harness Engineering 实验：从一个空 Git 仓库出发，**零行人类编写的代码**，Codex 自主构建了 100 万行代码的产品，提交了约 1500 个 PR，达到平均 3.5 PR/工程师/天的吞吐量。

OpenAI 将 Harness 组件分为三类：

- **Context Engineering（上下文工程）**：知识库 + 动态上下文注入。确保 Agent 在每次执行时拥有完成任务所需的最小而完整的上下文
- **Architectural Constraints（架构约束）**：自定义 Linter + 结构测试。通过 Computational Feedback 在代码生成后立即检测架构违规
- **Garbage Collection（垃圾回收）**：周期性熵检测。识别并清理代码库中积累的技术债务、死代码和退化模式

OpenAI 的核心理念是："**当 Agent 遇到困难，将其视为信号——找出缺失了什么（工具、护栏、文档），并让 Codex 自己编写修复方案**"。这形成了一个自我改进的闭环：Agent 遇到问题 → 分析根因 → 构建 Harness 组件 → Agent 不再重复同样错误。

#### 1.2.3 Anthropic 的 Pattern A 与 Pattern B

Anthropic 在文章《Effective harnesses for long-running agents》中系统描述了两种 Harness 架构模式：

**Pattern A: Initializer + Coding Agent**

流程：需求 → Initializer 生成 Spec 和 Feature 分解 → Coding Agent 逐 Feature 实现 → 每个 Feature 完成后进行上下文重置 → 结构化交接。

这一模式的核心是**上下文重置**。Coding Agent 完成一个 Feature 后，上下文被清空，下一个 Feature 从干净状态开始。这种设计解决了早期模型（如 Sonnet 4.5）的"上下文焦虑"问题——模型在长上下文中会变得犹豫不决、过度保守。

**Pattern B: Planner-Generator-Evaluator（PGE）**

灵感来自 GAN（生成对抗网络）架构。三个角色各有独立职责：

- **Planner**：将模糊需求扩展为完整的产品规格说明，分解为可执行的 Stage
- **Generator**：按 Stage 实现功能，只负责构建，不负责评判
- **Evaluator**：以批判者身份验证 Generator 的输出，使用 Playwright 操作真实浏览器进行功能验证

核心洞察：**模型无法自我批判**。让同一个 Agent 既写代码又评估自己的代码，就像让考生给自己的试卷打分——天然偏袒。分离生成与评估是突破质量瓶颈的关键。

Anthropic 在两个场景中验证了 Pattern B 的效果：

| 场景 | Solo Agent 结果 | PGE Harness 结果 |
|------|----------------|------------------|
| 前端设计 | 单人 20 分钟 $9，产出半成品 | 5-15 轮迭代，产生创造性飞跃 |
| 全栈开发 | 单人 20 分钟 $9，产出半成品 | 6 小时 $200，产出功能完备的应用 |

#### 1.2.4 Martin Fowler 的 Harness 框架

Martin Fowler 在 2026 年 2 月的两篇文章中（《Harness Engineering for GenAI》和《Blending AI and Human Judgment》）提出了一个系统化的 Harness 分类法：

**控制维度**

| 维度 | 类型 | 特点 | 示例 |
|------|------|------|------|
| 方向 | Feedforward（前馈/引导） | 事前预防，在 AI 生成内容前注入约束 | Rules、Skills、编码规范、架构约束 |
| 方向 | Feedback（反馈/传感） | 事后纠正，在 AI 生成内容后检测问题 | Linter、测试、LLM-as-Judge、浏览器验证 |
| 实现方式 | Computational（确定性） | 快速、可靠、可自动执行 | 类型检查、Lint、单元测试 |
| 实现方式 | Inferential（推断性） | 慢速、但能处理语义层面 | LLM 代码审查、LLM 设计评审 |

**三类 Harness**

1. **Maintainability Harness（可维护性 Harness）**：代码质量、测试覆盖、文档完整性。主要通过 Computational Feedback 实现
2. **Architecture Fitness Harness（架构适配性 Harness）**：模块边界、依赖方向、接口契约。Computational + Inferential 混合
3. **Behaviour Harness（行为 Harness）**：功能正确性、用户体验、业务逻辑。以 Inferential Feedback 为主，最难以自动化

**质量左移（Keep Quality Left）**

Fowler 强调将质量检查尽可能前置到变更生命周期的早期阶段。检查越早，修复成本越低。理想状态是：Pre-commit（Linter）→ Pre-integration（单元测试）→ Post-integration（E2E 测试）→ Continuous Drift（架构漂移检测）。

**Steering Loop（引导循环）**

人类在 Harness 体系中的角色不是审查每一次代码变更，而是**当问题反复出现时，改进 Harness 本身**。这是一个元层次的反馈循环：观察 Agent 的失败模式 → 分析需要什么 Harness 组件 → 构建或改进该组件 → Agent 不再重复同样错误。

### 1.3 Harness Engineering 分层体系

将上述业界实践抽象为统一的五层模型：

```
┌─────────────────────────────────────────────────┐
│              L4: Steering Layer                  │
│  人类反馈、Harness 自我迭代、质量监控               │
│  (Fowler Steering Loop, Hashimoto Stage 5/6)     │
├─────────────────────────────────────────────────┤
│              L3: Verification Layer              │
│  Linter、Test、LLM-as-Judge、Browser Validation  │
│  (Anthropic Evaluator, Fowler Feedback,          │
│   OpenAI Garbage Collection)                     │
├─────────────────────────────────────────────────┤
│              L2: Orchestration Layer             │
│  SubAgent 调度、上下文重置、Ralph Loop、Compaction│
│  (Anthropic Patterns, Hashimoto Stage 4/5)       │
├─────────────────────────────────────────────────┤
│              L1: Execution Layer                 │
│  Filesystem、Bash、Sandbox、Browser、MCP Tools   │
│  (Platform-granted capabilities)                 │
├─────────────────────────────────────────────────┤
│              L0: Context Layer                   │
│  Rules、AGENTS.md、Skills、知识库、动态上下文注入  │
│  (OpenAI Context Engineering,                    │
│   Fowler Feedforward Guides)                     │
└─────────────────────────────────────────────────┘
```

| 层级 | 核心问题 | 关键组件 | 业界实践来源 |
|------|----------|----------|-------------|
| L0: Context | Agent 知道什么、遵守什么 | Rules、Skills、知识库 | OpenAI Context Engineering |
| L1: Execution | Agent 能做什么 | 文件系统、Shell、浏览器、MCP | 平台原生能力 |
| L2: Orchestration | 如何协调多个 Agent | SubAgent 调度、上下文重置 | Anthropic Pattern A/B |
| L3: Verification | 如何确保质量 | 测试、Lint、LLM-as-Judge | Fowler Feedback、OpenAI Garbage Collection |
| L4: Steering | 如何持续改进 | 人类反馈、Harness 迭代 | Fowler Steering Loop、Hashimoto Stage 5 |

### 1.4 Claude Code Workflow 对标分析

Claude Code 在 2026 年 6 月发布的 Dynamic Workflows 功能，将 Harness Engineering 的核心思想——多角色对抗、上下文隔离、编排自动化——内化为平台的基础能力。理解 Claude Code 的实现方式，有助于我们认清 TRAE Work 实现方案的定位：**我们不是在"重新发明"，而是在"有限条件下模拟"**。

#### 1.4.1 Claude Code 的静态 Harness：`.claude/agents/`

Claude Code 通过 `.claude/agents/` 目录支持**静态定义 Harness 角色**。每个角色是一个 Markdown 文件，定义了该角色的职责、工具集和行为规则。开发者可以定义 Planner、Generator、Evaluator 等角色，Claude Code 的内置 Orchestrator 会自动根据任务类型将请求路由到合适的角色。

```
.claude/
├── agents/
│   ├── planner.md      # 需求分析、任务分解
│   ├── generator.md     # 代码实现
│   └── evaluator.md     # 质量验证
```

这与我们在 TRAE Work 中设计的 `.trae/agents/` 目录结构高度相似——因为两者都源自 Anthropic 的 Pattern B 架构。差异在于调度方式：Claude Code 的 Orchestrator 是**内置的、自动的**，而 TRAE Work 需要**人类触发 SPEC 工作流**来启动编排。

#### 1.4.2 Claude Code 的 Dynamic Workflows

2026 年 6 月，Claude Code 进一步推出了 Dynamic Workflows——**运行时自生成的 JavaScript 编排脚本**。它提供了 6 种内置编排模式：

| 模式 | 描述 | 适用场景 |
|------|------|----------|
| Classify-and-act | 先分类输入，再路由到对应处理器 | 多类型任务分流 |
| Fan-out-and-synthesize | 并行派发到多个执行器，汇总结果 | 独立子任务并行处理 |
| Adversarial verification | Generator → Evaluator 对抗验证 | 质量要求高的场景 |
| Generate-and-filter | 生成多个候选方案，筛选最优 | 需要创意或多样性的场景 |
| Tournament | 多轮淘汰赛，选出最优方案 | 复杂决策场景 |
| Loop until done | 循环执行直到满足退出条件 | 需要迭代收敛的场景 |

其中 **Adversarial verification** 就是我们的 PGE 架构的核心模式。Claude Code 的实现方式是：Orchestrator 自动生成编排脚本，脚本中调用 Generator 和 Evaluator 作为子过程，循环直到通过或达到最大轮次。

#### 1.4.3 三列对比：Claude Code vs TRAE Work

| 维度 | Claude Code `.claude/agents/` | Claude Code Dynamic Workflows | TRAE Work（我们的实现） |
|------|------|------|------|
| **角色定义方式** | `.claude/agents/` 下 Markdown 文件 | 运行时 JS 脚本动态生成 | `.trae/agents/` 下 Markdown 文件 + Skills |
| **Orchestrator** | 内置，自动路由 | 内置，JS 脚本 + 自动调度 | 拼装式：SPEC + Skills + Rules + Tasks + SubAgent + 人类触发 |
| **自动化程度** | 全自动 | 全自动 | 半自动（人类触发 SPEC，之后自动执行 Task 循环） |
| **上下文隔离** | 每个角色独立上下文（内置） | 每个执行器独立上下文（内置） | SubAgent 独立上下文（手动配置） |
| **对抗循环** | 手动编排 | 内置 Adversarial verification 模式 | tasks.md 中 [GENERATOR]/[EVALUATOR]/[DECISION] 标记驱动 |
| **编排修改能力** | 静态文件，可修改 | 运行时动态生成，可自适应 | 预编排（spec.md 静态），tasks.md 由Orchestrator 动态生成 |
| **持久状态** | 内置跨会话状态 | 内置 | 文件系统（state-board.json、eval/） |
| **费用** | 付费（Claude Code 订阅） | 付费（Claude Code 订阅） | 免费（TRAE Work 免费版能力） |

#### 1.4.4 核心差异：全自动 vs 半自动

Claude Code 与我们的实现之间最本质的差异在于**调度权归属**：

- **Claude Code**：Orchestrator 是平台内置的"发动机"——用户提出需求后，Orchestrator 自动完成从角色路由、任务分解、对抗循环到最终交付的全过程。人类只需在起点输入需求，在终点接收结果。
- **TRAE Work（我们的实现）**：我们"拼装了一台发动机"——SPEC 工作流提供 Planner 界面，Skills 提供角色行为定义，Rules 提供护栏约束，SubAgent 提供上下文隔离，tasks.md 提供编排脚本。但**启动钥匙在人类手里**：每次 SPEC 工作流需要人类执行 `/spec` 命令来触发，Planner 阶段的 spec.md 需要人类确认。

**我们的定位**：在 TRAE Work 免费版的能力范围内，通过组合现有能力（SPEC + Skills + Rules + SubAgent），**模拟** Claude Code 的 Harness 编排效果。方法论效果可以追齐——同样的角色分离、对抗验证、上下文隔离——但自动化程度无法追齐，因为缺少一个内置的 Orchestrator 来自动触发和调度。

**类比**：Claude Code 是一台"自动挡汽车"——踩油门就走。我们是在"手动挡汽车"上安装了一套"辅助驾驶系统"——换挡仍需手动，但转向、加速、刹车都有辅助。

---

## 第二部分：TRAE Work 平台能力分析

### 2.1 平台能力全景

Harness 配置分布在两类载体：`.trae/`（IDE 静态配置 + 原生临时 scratch）与 `harness/`（我们自定义的持久真值与消息总线）。完整布局如下：

```
项目根目录/
├── .trae/
│   ├── skills/                 # 角色 Skill + stage-executor（L0，唯一云端自动加载通道，git 同步）
│   │   ├── planner-role/SKILL.md
│   │   ├── generator-role/SKILL.md
│   │   ├── evaluator-role/SKILL.md      # 业务质量四维评分（不含裁决）
│   │   ├── decision-role/SKILL.md       # 独立中立裁决者（v4.2 起独立）
│   │   └── stage-executor/SKILL.md      # 运行时拉起 playbook（Orchestrator 触发加载）
│   ├── agents/                 # SubAgent 配置（可选，当前云端不支持，保留供未来兼容）
│   └── specs/                  # ⚠ 原生 /spec 临时 scratch：执行完即销毁、gitignore、不做消息传递
├── RULE.md                     # 项目规范（L0，根目录，通过钩子规则加载，git 同步）
├── harness/                    # ★ 持久真值 + 跨 session 消息总线（git 可同步，不绑定 .trae）
│   ├── templates/              # 三件套 + Contract 的结构骨架（静态，只有章节契约，无内容）
│   │   ├── spec.skeleton.md
│   │   ├── tasks.skeleton.md
│   │   ├── checklist.skeleton.md
│   │   └── stage-contract.skeleton.md
│   ├── milestones/
│   │   └── {milestone}/
│   │       ├── milestone-plan.md        # Stage 定义（Planner 产出，静态只读真值）
│   │       └── stages/{stage}/
│   │           ├── contract.md          # 验收要点（Orchestrator 标注）
│   │           └── gen.md  eval.md  decision.md      # 交付物/证据（消息总线）
│   └── state-board.json        # 动态状态机真值（跨 session）
├── .trae/specs/{...}/          # ⚠ 原生 /spec 三件套 spec/tasks/checklist：过程脚手架，gitignore、对话结束即弃、不入 harness
```

**关键设计决策（v4.0）**：
- `.trae/skills/` 是 TRAE Work 云端唯一自动加载的配置通道；Agent 角色行为内嵌到 Skill 中，保证当前可用
- **`harness/` 是唯一持久真值与消息总线**；`.trae/specs/` 只是原生临时 scratch，必须把三件套持久化到 `harness/` 后再据此流转（详见 0.3）
- `.trae/rules/` 不存在——TRAE Work 不支持此目录，项目规范改为 `RULE.md` + 钩子规则方案
- 钩子规则：用户在 TRAE Work「设置 > 规则」中创建一条云端规则，让所有 Task 启动时自动读取 `RULE.md`；`RULE.md` 再指向 `stage-executor` playbook
- `.trae/specs/` 应加入 `.gitignore`

### 2.2 SPEC 工作流（Stage 层）

SPEC 工作流是 TRAE Work 的核心编排机制。每次 `/spec` 生成三件套：

- `spec.md`（大纲）：该 **Stage** 的目标、范围边界、验收标准
- `tasks.md`（任务列表）：可执行的 Task 分解，含依赖关系
- `checklist.md`（验收清单）：底层机制——可机械检查的 **tasklist 完成性**清单

**关键定位（v4.0）**：
- SPEC 三件套作用在 **Stage 层**——每个 Stage 一次 `/spec`，由 **Orchestrator（云端父 Agent）运行时创建**，而非 Planner 预生成。Advisor 只提供结构骨架（`harness/templates/*.skeleton.md`），内容由 Orchestrator 按当前上下文推理填充。
- **三件套都保留**：`checklist.md` 不被裁掉。它是**底层机制**——TraeWork 原生的完成性 gate，机械检查该 Stage 的 **tasklist 是否执行完成**；而 Evaluator 是**我们自己编排、在 task 内部运行的偏业务质量对抗验收**（见 0.2）。两者不同维度，互不替代。
- **三件套是过程脚手架，只放 `.trae/specs/`，不进总线**：`/spec` 在 `.trae/specs/` 产出 spec/tasks/checklist，仅在该 Stage 对话内供 G/E/D 读取，对话结束即弃。**只把"交付物"写入 `harness/` 总线**：contract.md（验收要点）+ gen.md + eval.md + decision.md（+ board）。我们不控制 `/spec` 输出路径，而是让角色把要留存的产物主动写到总线。

**关键机制：AI 暂停确认**。三件套首次生成后，AI 暂停，等待用户确认或编辑。确认后 Task 状态随执行进度更新。

**角色映射**：Planner 负责更上游的 Milestone→Stage 战略分解（产出 `milestone-plan.md`）；单个 Stage 的 `/spec` 暂停确认阶段由 **Orchestrator** 主导，用户在此审查该 Stage 的三件套。

### 2.3 Skills 体系

Skills 是 TRAE Work 的**按需加载（Progressive Disclosure）**机制。每个 Skill 包含 `name`、`description`（触发条件）和完整的指令内容。Agent 仅在匹配到触发条件时加载 Skill 内容，任务完成后释放上下文。

Skills 与 Rules 的本质区别：

| 特性 | Rules | Skills |
|------|-------|--------|
| 加载时机 | 会话开始时全量加载 | 按需触发，按需加载 |
| 上下文占用 | 始终占用 | 仅在需要时占用 |
| 适用场景 | 全局约束、编码规范、安全策略 | 特定任务 SOP、设计规范、测试流程 |
| Harness 角色 | Computational Feedforward | Inferential Feedforward Guide |

在 Harness 体系中，Skills 是封装角色行为的关键载体：Planner、Generator、Evaluator 各用独立 Skill 定义行为，外加一个 **stage-executor** playbook Skill 作为运行时拉起入口。

### 2.4 Rules 体系

> **v3.1 重要修正**：TRAE Work 云端**不支持** `.trae/rules/` 文件驱动的规则目录。规则体系是 UI 驱动的全局规则（在「设置 > 规则」中维护），与 IDE 的文件驱动体系不同。因此项目级规范改用 **`RULE.md`（项目根目录）+ 一条云端钩子规则**实现（详见 2.1 节和决策 10）。

在概念上，Rules 仍可分为两层职责：

- **全局规则**（「设置 > 规则」）：跨项目的个人偏好与通用约束；本方案仅用其中一条作为"钩子"——让每个 Task 启动时自动读取项目根目录的 `RULE.md`
- **项目规范 `RULE.md`**：全团队共享的编码规范、技术栈约束、安全策略、禁止修改路径；随 git 同步，由钩子规则加载

在 Harness 体系中，Rules 是 **Computational Feedforward 控制**的核心手段。规则在模型执行前注入约束，从源头防止越权操作。需要注意：这类约束是**提示词级（建议性）**的，依赖模型遵守，并非沙箱强制隔离。

规则编写原则：
- 控制在 200 行以内，避免上下文膨胀
- 使用确定性语言："必须"、"禁止"、"要求"，而非"可能"、"尽量"、"建议"
- 每行规则对应一个已知的失败案例

### 2.5 SubAgent 体系（核心能力）

SubAgent 是 TRAE Work 实现 Harness 架构的**基础设施**。其核心特性：

1. **独立上下文窗口**：每个 SubAgent 拥有独立的上下文，互不污染。主 Agent 上下文不会因 SubAgent 的执行而膨胀
2. **路径白名单隔离**：三层路径管控——
   - 第一层：全局禁止目录（`node_modules`、`.git`、`.env`）
   - 第二层：任务级白名单（每个 SubAgent 声明唯一可修改路径）
   - 第三层：文件级锁（关键文件标注 `// TRAE SOLO 全局锁文件`）
3. **结果摘要回传**：SubAgent 完成后，将关键结果摘要回传给主 Agent，细节留在子上下文
4. **并行执行**：可在单条消息中并行发起多个 SubAgent 调用

在 Harness 体系中，SubAgent 是**实现 Generator 和 Evaluator 角色分离**的前提——每个角色运行在独立的 SubAgent 中，拥有独立的上下文和工具集，天然杜绝自评偏差。

> **SubAgent 工具能力（真机实测，v4.3）**：`general_purpose_task` 子代理拥有 **17 个工具**：Skill；代码搜索（SearchCodebase/Glob/LS/Grep/Read）；**Web（WebSearch/WebFetch）**；**Shell（RunCommand/CheckCommandStatus/StopCommand）**；文件操作（DeleteFile/Edit/Write）；任务/调度（TodoWrite/Schedule）；OpenPreview。
> 含义：子代理**能跑任意 Shell 命令**（git/npm/docker/构建/测试）、**能联网查文档**、能读写文件——**唯一缺口是 MCP**（`mcp__*` 工具不下发给子代理，仅主 Orchestrator 可见，见 AP4）。所以 Evaluator 子代理仍能跑自动化测试/Lint（用 RunCommand），只是浏览器类 MCP 验证要由 Orchestrator 代行。

> **动态编排能力（真机验证 → 一个重要发现）**：本次自检验证了 Orchestrator 在运行时具备完整控制流：**顺序**（依次派发 G→E→D）、**分支**（读 decision.md 的 verdict 走 pass/retry/escalate）、**有界循环**（retry→改 tasks.md+手动重派）、**跳出**（escalate）、**自修改程序**（运行时改写自己的 tasks.md）、**持久状态**（board+harness 跨会话）。叠加子代理的 Shell（RunCommand 可跑任意程序），整体构成一个**图灵完备的执行底座**。
> 因此可以实现**真正自适应的 PGE 流程**——Orchestrator 据运行时证据动态重规划（加轮、改任务、分支、升级），而非跑预先写死的脚本。**但有三条工程注脚**：① 控制是**推理级（LLM 逐步决策）而非计算级（确定性引擎）**——图灵完备 ≠ 可靠，依赖 Orchestrator 忠实执行（提示词级）；② **有界**——循环跑在一次对话内，受上下文/轮次预算限制，靠 board+文件外置状态才能跨会话续；`max_rounds`/escalate 是刻意护栏，防图灵完备带来的跑飞；③ **效果可追齐 Claude Code 的自适应编排，确定性/可重放性追不齐**（我们是"LLM 当编排器"）。
> 措辞约定：全文"顺序模拟对抗"应理解为 **"LLM 驱动的动态编排 / 自适应对抗循环（图灵完备底座 + 推理级控制 + 护栏有界）"**，而非静态预编排脚本。

> **约束强度说明（重要）**：上面的"路径白名单隔离"以及全文出现的路径白名单、RULE.md 钩子规则、stage-executor playbook 的遵循、board 的读写规范，**都是提示词级（best-effort）约束，依赖模型遵守，并非沙箱/引擎强制**。模型仍可能不读 RULE.md、越界改文件、跳过自检门。它们能显著降低出错概率，但**不能当作硬隔离/安全边界**。真正的硬保护需配合外部手段（CI 校验、代码评审、最小权限令牌等）。

> **平台能力自检（已真机端到端验证，v4.4 综合重跑 AP1–AP14）**：`poc/harness-selftest/`（probe + adaptive 两个 Stage）在真实 TRAE Work 跑通，**13/14 PASS**：
> - **平台能力 PASS**：自动加载（AP1）；SubAgent 加载角色 Skill（AP2，含 decision-role）；G/E/D 三方隔离（AP3）；白名单拒绝越权（AP5）；交付物→harness、三件套→.trae/specs（AP6）；checklist=完成性 gate（AP7）；RULE.md 钩子（AP8）；真并行+无自动循环（AP9）；retry 重派（AP10）。
> - **设计行为 PASS（v4.4 全部验证成立）**：浏览器代行链路（AP11，方案1：Orchestrator 经 `run_mcp` 派发成功、Evaluator 读 browser-check.md 评分）；codraft 共识子阶段（AP12）；**真 retry→pass 自适应闭环（AP13：R1 FAIL→retry→R2 PASS）**；depends_on 门控（AP14）。
> - **唯一 FAIL（已知平台限制，非阻塞）**：**SubAgent 不继承 MCP**（AP4）——`mcp__*` 仅主 Orchestrator 可见，故浏览器/MCP 验证由 Orchestrator 代行（AP11 已验证此路径可行）。
> - **环境备注**：AP11 的实际浏览器交互需预装 chromium（`npx playwright install chromium`）或配置 TRAE Work 远程环境（https://docs.trae.cn/solo_set-up-the-remote-environment）——本次 MCP 代行链路通但 chromium 二进制缺失（返回 Playwright 运行期错误，非链路失败）。
> 详见 `poc/harness-selftest/expected-outcome.md`。结论：**v4.4 的"LLM 驱动的动态自适应 PGE 编排"在真机端到端成立**（AP13 是关键佐证）。

### 2.6 平台能力与 Harness 分层体系映射

| Harness 层 | TRAE Work 能力 | 映射说明 |
|-----------|---------------|----------|
| L0: Context | Rules、Skills、知识库 | Rules 提供 Computational Feedforward；Skills 提供 Inferential Feedforward Guide |
| L1: Execution | 文件系统、Bash、Sandbox、MCP | 平台原生能力，提供 Agent 执行的基础工具集 |
| L2: Orchestration | SPEC 工作流、SubAgent 调度 | SPEC 提供 Planner 界面；SubAgent 提供 Generator/Evaluator 角色分离 |
| L3: Verification | MCP（Playwright、Linter 等）、LLM-as-Judge | 通过 MCP 集成外部验证工具；通过 Skills 封装评估逻辑 |
| L4: Steering | 人类审查 SPEC 暂停确认阶段 | 人类在 Planner 阶段审查规格，在最终验收阶段审查结果 |

**能力缺口识别**：TRAE Work 目前缺少自动化的 Computational Feedback 持续执行机制（如 CI/CD 集成）。建议通过外部 CI/CD 流水线 + MCP 补充。

---

## 第三部分：TRAE Work 上的 Harness 架构设计

### 3.1 架构总览

```
                        ┌──────────────────────────┐
                        │     人类（Steering）       │
                        │  Stage /spec 暂停确认      │
                        │  最终验收 + escalate 裁决   │
                        └────────────┬─────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
┌───────▼────────┐      ┌────────────▼───────────┐    ┌───────────▼──────────┐
│ L0: Advisor    │      │ L1: Planner            │    │ L2: Orchestrator      │
│ Skill 一次性    │      │ Milestone 规划对话      │    │ 每个 Stage 一次云端对话 │
│ 初始化基础设施   │      │ 输出:                   │    │ 由 stage-executor 引导 │
│ 输出: 角色Skill+ │      │ - milestone-plan.md    │    │ 1 读 board 定位 Stage  │
│ stage-executor+ │      │   (Stage 定义+depends) │    │ 2 /spec 产三件套→harness│
│ 骨架模板+RULE.md+│      │ - 初始化 state-board   │    │ 3 自检门               │
│ 空 board        │      │                        │    │ 4 派发 G→E→D / 回写board│
└─────────────────┘      └────────────────────────┘    └──────────┬───────────┘
                                                                  │
                                              ┌───────────────────┼───────────────────┐
                                  ┌───────────▼──┐    ┌──────────▼──┐    ┌──────────▼──┐
                                  │  Generator   │    │  Evaluator   │    │  Decision   │
                                  │  SubAgent    │    │  SubAgent    │    │  SubAgent   │
                                  │  独立上下文   │    │  独立上下文   │    │  独立上下文  │
                                  │  写代码+测试  │    │  质量四维评分 │    │  中立裁决    │
                                  │  → gen.md    │    │  → eval.md   │    │  pass/retry │
                                  │              │    │              │    │  /escalate  │
                                  └──────────────┘    └─────────────┘    └─────────────┘
        所有持久产物落在 harness/milestones/{milestone}/stages/{stage}/（消息总线）
```

**关键变化（v4.0）**：
- 层级重命名为 **L0 Advisor → L1 Planner → L2 Orchestrator → 执行层（G/E/D）**，对齐 Milestone/Stage/Task 三级概念。
- **SPEC 三件套下沉到 Stage 层**：不再由 Planner 生成"feature 级空模板"，改由 Orchestrator 在每个 Stage 的 `/spec` 对话中按骨架模板运行时创建，并持久化到 `harness/`。
- **stage-executor playbook** 是 L2 的单一拉起入口（见 3.x），把"读 board + 读 plan + 用模板 + 自检 + 派发"收敛为一条确定性流程。
- 持久真值与消息总线统一在 `harness/`，`.trae/specs/` 仅作临时 scratch。

### 3.2 PGE+D 四角色与执行分层

本架构在 Anthropic 的 Pattern B（Planner-Generator-Evaluator）三角色基础上，新增 **Decision（裁决者）**，形成 PGE+D。Decision 充当 Orchestrator 的裁决代理——在 Generator 与 Evaluator 分歧时做中立裁决。

整个工作流分为四个执行层级，每层都有自主推理能力，上层产出约束下层行为：

#### 执行分层分工表

| 层级 | 角色 | 触发 | 输入 | 输出（交付物） | 自主推理能力 |
|------|------|------|------|----------------|-------------|
| L0 | **Advisor Skill** | 用户一次性调用 | 技术栈、目录偏好、TDD、严格度等 | 1. 角色 Skill（planner/generator/evaluator/decision-role）<br>2. **stage-executor** playbook Skill<br>3. RULE.md + 钩子规则文本<br>4. `harness/templates/*.skeleton.md`（三件套+Contract 骨架）<br>5. 空 `state-board.json`<br>6. 可选 Agent 配置 | 据技术栈定制编码规范、TDD 流程、评估维度 |
| L1 | **Planner** | Milestone 规划对话 | 用户需求 | 1. `milestone-plan.md`（Milestone 含 `kind` + Stage 定义含 `depends_on`）<br>2. 初始化 `state-board.json` | 理解需求，拆分 Stage，标注依赖与验收标准 |
| L2 | **Orchestrator** | 每个 Stage 一次云端对话（stage-executor 触发） | board + milestone-plan + 骨架模板 | 1. 三件套（spec/tasks/checklist）→ 持久化到 `harness/.../stages/{stage}/`<br>2. 派发 G/E/D<br>3. 回写 board 状态 | 据 Stage 定义与当前上下文推理填充三件套、编排对抗 |
| 执行层 | **Generator** | tasks.md 步骤 | spec + Stage Contract | 代码 + 测试 + `gen.md` | TDD 实现 |
| 执行层 | **Evaluator** | Generator 完成 | 代码 + Contract | `eval.md`（四维质量评分） | 怀疑者立场验证 |
| 执行层 | **Decision** | Evaluator 完成 | gen.md + eval.md + contract.md | `decision.md`（pass/retry/escalate） | 中立裁决（**独立 SubAgent**，加载 decision-role） |

**为什么三件套由 Orchestrator 运行时创建、而非预生成？** Planner 完成 Milestone 规划后，用户可能过几天才执行某个 Stage，期间上下文会变；且未来 Agent 能力会迭代。预生成的具体内容会过时、错配。因此 Advisor/Planner 只给**指导思想**（骨架模板 + Stage 定义），三件套的**具体内容**由 Orchestrator 在执行当下推理填充。

**实现方式说明**：TRAE Work 云端唯一自动加载的配置通道是 `.trae/skills/`。`.trae/agents/` 当前不支持，因此 G/E/D 的工具集、路径白名单、裁决规则各自**内嵌到对应的角色 Skill**（generator-role / evaluator-role / **decision-role**）中；Agent 配置文件保留为可选生成，供未来兼容。

**职责边界（强约束）**：
- **Advisor 只做基础设施初始化**：生成角色 Skill、stage-executor、骨架模板、RULE.md、空 board。**不碰任何业务内容**。
- **Planner 只做 Milestone→Stage 战略分解**：产出 `milestone-plan.md` + 初始化 board。**不生成三件套**。
- **Orchestrator 只串联流程**：读 board 定位 Stage → `/spec` 产三件套 → 持久化 `harness/` → 自检 → 派发 G/E/D 三个**独立**子代理 → 据裁决决定下一步（含 retry 时改 tasks.md + 重派）→ 回写 board。**自己不实现、不评分、不裁决**。
- **Decision 是独立中立裁决者**：作为**独立 SubAgent**（加载 decision-role，与 G/E 上下文隔离、盲审）只读 gen.md+eval.md+contract.md → 输出裁决。**Orchestrator 不得自己兼任裁决**（真机自检发现兼任会丧失中立性，v4.2 改为独立）。
- **`harness/` 是状态总线**：角色之间不直接通信，全部通过 `harness/` 下文件传递（无持久会话架构下的最优解）。
- **RULE.md 钩子规则**：在「设置 > 规则」建一条云端规则让每个 Task 启动读 `RULE.md`，`RULE.md` 再指向 stage-executor。一次性配置。

**Stage 内对抗流程（顺序模拟，非自动循环）**：

> 调研结论：TRAE Work 的 SubAgent **可并行、也可串行派发，但没有自动控制流循环（loop）**——子代理不能自我循环重启。因此 Stage 内的 G→E→D 因数据依赖天然串行，而多轮返工靠 Orchestrator **每轮手动重新派发**（非自动循环），最多 3 轮，超限即 escalate 人工介入。（跨独立 Stage 的并行另由人工多对话实现，见 3.7。）

```
[Stage 开始]
   │
   ▼
[ORCHESTRATOR] 标注关键 Contract 点 → contract.md（目标 / 验收要点 / 边界）
   │
   ▼
[GENERATOR] 按 contract.md 实现（TDD）
   │
   ▼
[GENERATOR] 实现总结 → harness/.../stages/{stage}/gen.md
   │
   ▼
[EVALUATOR] 质量评估 → harness/.../stages/{stage}/eval.md
   │
   ▼
[DECISION]  读取 gen.md + eval.md → decision.md
   │
   ├── pass     → 该 Stage 通过，回写 board=passed，进入下一可执行 Stage
   ├── retry    → Orchestrator 重新派发 [GENERATOR]，附带 retry_focus（rounds+1）
   │              （rounds 达到上限 3 仍未过 → 转 escalate）
   └── escalate → 暂停，回写 board=escalated，请求人类裁决
```

> **Contract 的两种来源（v4.3）**：验收标准的"根"在 Planner 的 `milestone-plan.md`（每个 Stage 带"验收标准要点"），Orchestrator 只是据此 + 既定契约**誊写/收敛**成 `contract.md`，不凭空发明。每个 Stage 在 plan 里标 `contract_mode`：
> - **planned（默认）**：验收标准规划期已明确（需求清晰 / 联调阶段，骨架与模块契约已定，如"下单接口调通、购买流程不报错、日志无 ERROR"）→ Orchestrator 直接写 contract.md，**一次标注、不加子阶段**。
> - **codraft（可选）**：验收标准需先有草稿才能定（早期/探索性开发，"开发写一版 → 测试 review → 再调标准"）→ 先跑 **Contract 共识子阶段**（Generator 出草稿+提议标准 → Evaluator 敲定 → 写 contract.md），再进入正式对抗。
> 若 `force_contract=false`，跳过 contract，Generator 直接按 spec 实现。

### 3.3 Planner 角色定义

**职责**：将用户需求扩展为一个 **Milestone**，并战略性地分解为若干 **Stage**。**Planner 只做战略级分解，不生成三件套、不写业务实现内容**。

**输出边界**：Planner 输出两样：
1. **`milestone-plan.md`**：Milestone 概述（含 `kind: development | verification`）+ 每个 Stage 的定义（目标、验收标准要点、`depends_on` 依赖、预估复杂度、**`contract_mode: planned | codraft`**）
2. **初始化 `state-board.json`**：把 Milestone 与各 Stage 以 `status: planned` 写入状态机

**不输出三件套**：spec/tasks/checklist 由 Orchestrator 在每个 Stage 的 `/spec` 对话中运行时创建。

**在 TRAE Work 中的实现**：
- 创建 `planner-role` Skill 定义 Planner 的行为规范
- Planner 输出存储为 `harness/milestones/{milestone}/milestone-plan.md`
- 初始化/更新 `harness/state-board.json`


**Planner 与Orchestrator 的契约**：

Planner 输出的 spec.md 模板必须包含结构框架让Orchestrator 填充：
**Planner 与 Orchestrator 的契约**：

`milestone-plan.md` 必须让 Orchestrator 能据此为单个 Stage 产出三件套：
- 每个 Stage 的目标、可机械检查的验收标准要点
- `depends_on` 依赖、预估复杂度
- 技术栈与架构约束、非功能性需求（量化指标）

Orchestrator 每次起一个 Stage：读 `milestone-plan.md` + board → 按骨架产三件套 → 标注 Contract 关键点 → 派发对抗。Planner 不干预 Orchestrator 的编排决策。

**Planner 的核心原则**：

1. 从用户需求中提取核心功能，而非技术实现细节
2. 将功能分解为独立、可验证的 Stage，每个 Stage 有明确的验收标准
3. 识别 Stage 之间的依赖关系，标注 `depends_on`
4. 验收标准必须是 Evaluator 可以机械检查的，而非主观判断

### 3.4 Generator 角色定义

**职责**：根据 Stage 的 spec 与 Orchestrator 标注的 Contract 关键点，以 Stage 为单位实现功能。只负责构建，不负责评判。

**核心行为**：

1. 读取该 Stage 的 spec.md、tasks.md 和 Orchestrator 标注的 contract.md
2. 严格遵循 TDD：先写测试，确认测试失败，再写实现
3. 每次代码改动后立即运行测试
4. 完成一个 Stage 后立即 git commit
5. 将实现总结写入 `harness/milestones/{milestone}/stages/{stage}/gen.md`

**在 TRAE Work 中的实现**：

- 创建 `generator` SubAgent（`.trae/agents/generator.md`）
- 创建 `generator-role` Skill（`.trae/skills/generator-role/SKILL.md`）
- 工具集：Read、Write、Edit、Glob、Grep、Bash（git、test、dev server）
- 路径白名单：仅允许修改 `src/`、`tests/` 和 `eval/` 目录

**Generator 的禁止行为**：

- 禁止评价自己的代码好坏
- 禁止修改 Spec 文档或验收标准
- 禁止跳过测试直接写实现
- 禁止跨 Stage 修改不属于当前 Stage 的文件

### 3.5 Evaluator 角色定义

**职责**：以"怀疑者"身份验证 Generator 的输出。严格要求，不妥协。

**四维评分标准（每个 1-5 分）**：

| 维度 | 评估内容 | 检查方式 |
|------|----------|----------|
| 功能性 | 功能是否按 spec 要求正确实现 | 浏览器测试、API 测试 |
| 工艺质量 | 代码结构、错误处理、边界条件 | 代码审查、Lint |
| 完整性 | 测试覆盖、文档、验收标准全部满足 | 测试覆盖率报告 |
| 用户体验 | 交互流畅、响应时间、错误提示 | 浏览器实际操作 |

**判定规则**：总分 >= 16 且无单项 < 4 → 通过。任一维度低于 4 分 → 必须在评估报告中列出具体问题。

**在 TRAE Work 中的实现**：

- 创建 `evaluator` SubAgent（`.trae/agents/evaluator.md`）
- 创建 `evaluator-role` Skill（`.trae/skills/evaluator-role/SKILL.md`）
- 工具集（真机实测，子代理无 MCP）：Read、Glob、Grep、**RunCommand（跑 test/lint/build）**、WebSearch/WebFetch；**浏览器验证由 Orchestrator 代行**（它有 MCP），证据写 `browser-check.md`，Evaluator 读取纳入评分
- 工作目录：只读模式，仅可写入 `eval.md`

**Evaluator 的核心原则**：

1. 必须用 RunCommand 实际运行测试/Lint；面向 UI 的 Stage 读 Orchestrator 代行写的 `browser-check.md`（截图/日志），不能仅凭代码审查判断
2. 浏览器证据由 Orchestrator 代行 MCP 产出并留证（子代理无 MCP）
3. 不能"放水"——不确定时往低打分
4. 评估报告必须包含：通过/失败状态、各维度分数、具体问题描述、修复建议

### 3.6 Decision 角色定义

**职责**：作为中立裁决者（Orchestrator 代理），在 Generator 和 Evaluator 产生分歧时做出裁决。Decision 不写代码，不评估代码，只做 pass/retry/escalate 三种决定。

**为什么需要 Decision？**

在三角色架构中，Generator 和 Evaluator 之间的分歧没有自动解决机制。Evaluator 给出 FAIL 后，Generator 需要修改，但如果没有第三方裁决，可能出现两种情况：
- Generator 过度修改（修改了不需要改的部分，引入新问题）
- Generator 和 Evaluator 陷入僵局（Evaluator 反复要求修改，Generator 反复提交）

Decision 通过"只读两份报告 → 输出裁决"的方式，模拟 Orchestrator 的决策功能，为对抗循环提供自动化闭环。

> **真机自检发现（待决策）**：在 `poc/harness-selftest` 这轮里，[DECISION] 步骤是由**主 Orchestrator 自己执行**的（读 gen.md/eval.md 后写 decision.md），而非独立隔离的 SubAgent；且主 Orchestrator 还能看到 Generator/Evaluator 各自的 Task 返回摘要。这意味着"中立裁决者"实际上**不是盲审第三方**——做裁决的 Agent 正是派发并旁观了双方的那个。
> **真机自检发现 → 已采纳（v4.2）**：在 `poc/harness-selftest` 首轮里，[DECISION] 曾由**主 Orchestrator 自己执行**且能看到双方 Task 返回摘要，"中立裁决者"沦为非盲审。据此**已决定：Decision 一律作为独立 SubAgent**（加载 `decision-role`，只 Read gen.md/eval.md/contract.md，无双方对话上下文），Orchestrator 只负责串联流程、读裁决、决定下一步（含 retry 时改 tasks.md + 重派），**不再兼任裁决**。代价是每轮多一次 SubAgent 派发，换取真正的中立盲审。

**在 TRAE Work 中的实现**：

- 创建 `decision` SubAgent（`.trae/agents/decision.md`）
- 工具集：仅 Read（只读，不写代码）
- 路径白名单：允许读取 `harness/`（Stage 目录下的 gen.md/eval.md/contract.md/spec.md）；允许写入仅 `harness/milestones/{milestone}/stages/{stage}/decision.md`
- 裁决逻辑：

```
读取 harness/milestones/{milestone}/stages/{stage}/gen.md（Generator 实现总结）
读取 harness/milestones/{milestone}/stages/{stage}/eval.md（Evaluator 评估报告）
      │
      ▼
对比两份报告 → 做出裁决
      │
      ├── pass: 两份报告无实质性分歧，Evaluator 评分通过 → 进入下一 Stage
      ├── retry: 存在可修复的问题，输出 retry_focus（聚焦修复建议）→ Generator 重试
      └── escalate: 无法裁决（如评分标准争议、需求理解分歧）→ 暂停，人类介入
```

**Decision 的行为规则**：

1. 保持中立：不偏向 Generator 或 Evaluator 任何一方
2. 引用证据：每个裁决决定必须引用两份报告中的具体内容作为依据
3. 矛盾优先：当两份报告存在矛盾时，必须明确指出矛盾点
4. 不确定时 escalate：当无法通过现有信息做出明确裁决时，标记为 escalate，不强行裁决
5. 不看意图只看产出：裁决基于实际产出（代码、测试结果、截图），不基于 Generator 的"意图描述"
6. 不质疑评分标准：尊重 Evaluator 的评分维度，但可以质疑评分与证据的一致性
7. 输出格式为 JSON：`{"decision": "pass|retry|escalate", "reason": "...", "retry_focus": ["..."]}`

### 3.7 上下文隔离方案

**三层隔离策略**：

| 层级 | 隔离方式 | 解决的问题 |
|------|----------|-----------|
| L1: 角色级 | Planner/Generator/Evaluator 各自使用独立 SubAgent | 防止 Generator 假设污染 Evaluator 判断 |
| L2: 任务级 | 每个 Stage 使用独立的 Generator 实例 | 防止 Context Rot，每个 Stage 从干净上下文开始 |
| L3: 路径级 | 路径白名单限制每个 SubAgent 的文件访问范围 | 防止越权修改，确保并行安全 |

**共享状态机制**：

文件系统（`harness/`）是 SubAgent 之间唯一的通信总线。所有状态通过该 Stage 目录下的文件传递：

- `harness/milestones/{milestone}/milestone-plan.md` — Planner 输出的 Stage 定义，Orchestrator 读取
- `.trae/specs/{...}/spec.md|tasks.md|checklist.md` — 当前 Stage 三件套（原生 /spec 产出，过程脚手架，仅本对话内可读，不入 harness）
- `harness/milestones/{milestone}/stages/{stage}/contract.md` — Orchestrator 标注的 Contract 关键点
- `harness/milestones/{milestone}/stages/{stage}/gen.md|eval.md|decision.md` — G/E/D 产物
- `harness/state-board.json` — 跨 session 状态机

**state-board.json 写协议（最小更新原则）**：

- 没有引擎级锁。为避免冲突，**每次只对"当前 Stage 那一条记录"做最小字段更新**（status / rounds / last_decision / artifacts），不整体重写、不触碰其它 Stage 的记录。
- 这样即使多个 Stage 在不同对话里推进，board 的写入也是**不相交的小改动 → git 合并不冲突**。
- **代码级冲突无法靠工具自动规避**：当多个 Stage 改到同一批源文件时，必须由**人工在投递 Stage 时依据 `depends_on` 把关**——只投递依赖已 `passed` 且与在途 Stage 无文件交集的 Stage。

**关于"并发"的真实语义**：

- TRAE Work 没有引擎级编排器。所谓"Stage 并发"= **人类开多个独立云端对话**分别推进，不是自动并行调度。
- 因此 `depends_on` 是**人工/Orchestrator 投递前的冲突规避依据**（"这个 Stage 现在能不能开工"），而非自动门控。投递权与冲突责任都在人。

**上下文重置策略**：

当 Generator 的上下文接近窗口上限时，主 Agent 触发 Compaction（上下文压缩）。如果 Compaction 后仍不足，则启动 Context Reset——完成当前 Stage 的 commit，然后启动新的 Generator SubAgent 实例处理下一个 Stage。

### 3.8 沟通协议设计

**Stage Contract 协议**

```
Orchestrator 起 Stage（/spec 三件套 → .trae/specs）
        │
        ▼
contract.md 来源？（看 Stage 的 contract_mode）
   ├─ planned（默认）→ Orchestrator 据 milestone-plan 要点+既定契约直接写 contract.md
   └─ codraft（可选）→ [GENERATOR] 出草稿+提议标准 → [EVALUATOR] 敲定标准 → 写 contract.md
        │
        ▼
Generator 按 contract.md 实现（TDD）
        │
        ▼
Generator 自检后提交 → gen.md
        │
        ▼
Evaluator 质量评估 → eval.md
        │
        ▼
Decision 裁决 → decision.md
        │
        ├── pass     → 进入下一可执行 Stage
        ├── retry    → Generator 修复（rounds+1，最多 3 轮）→ 重新评估
        └── escalate → 暂停，人类介入（rounds 超限或无法裁决）
```

**文件结构约定**：

```
.trae/skills/                    # 角色 Skill + playbook（静态/git）
├── planner-role/SKILL.md
├── generator-role/SKILL.md      # 含 Agent 工具集和路径白名单
├── evaluator-role/SKILL.md      # 业务质量四维评分（不含裁决）
├── decision-role/SKILL.md       # 独立中立裁决者
└── stage-executor/SKILL.md      # 运行时拉起 playbook
（可选）.trae/agents/            # 仅 generate_agents=true 时生成
├── generator.md  evaluator.md  decision.md
RULE.md                          # 项目根目录（钩子规则加载）
harness/                         # ★ 持久真值 + 消息总线
├── templates/                   # 三件套 + Contract 骨架（Advisor 预置）
│   ├── spec.skeleton.md  tasks.skeleton.md  checklist.skeleton.md
│   └── stage-contract.skeleton.md
├── milestones/{milestone}/
│   ├── milestone-plan.md        # Planner 输出：Milestone + Stage 定义
│   └── stages/{stage}/
│       ├── contract.md          # 验收要点（Orchestrator 标注）
│       └── gen.md  eval.md  decision.md      # 交付物/证据（G/E/D 产物）
└── state-board.json             # 状态机真值
.trae/specs/{...}/               # 原生 /spec 三件套 spec/tasks/checklist：过程脚手架，gitignore、对话结束即弃、不入 harness
```

### 3.9 与 Claude Code 的对比

在 1.4 节中，我们从 Harness 机制层面分析了 Claude Code 与 TRAE Work 的差异。这里从**架构设计决策**的角度，对比两者的编排实现路径。

#### 3.9.1 Orchestrator：内置 vs 拼装

| 方面 | Claude Code | TRAE Work（我们的实现） |
|------|-------------|----------------------|
| **Orchestrator 来源** | 平台内置，代码级实现 | 拼装式：SPEC + Skills + Rules + Tasks + SubAgent + 人类触发 |
| **任务路由** | 自动根据任务类型路由到对应角色 | 人类通过 `/spec` 命令触发，tasks.md 标记驱动角色切换 |
| **对抗循环** | 内置 Adversarial verification 模式，自动循环 | tasks.md 中 [GENERATOR]/[EVALUATOR]/[DECISION] 标记驱动，File System 作为状态总线 |
| **循环终止** | Orchestrator 自动判断 | Decision 角色模拟：pass → 下一 Stage，escalate → 人类介入 |
| **可修改性** | 静态文件 + 运行时 JS 脚本 | 全部为 Markdown 文件，可直接编辑 |

#### 3.9.2 编排效果：能否追齐？

**方法论效果可以追齐**。两者都实现了：
- 角色分离（Planner/Generator/Evaluator 各司其职）
- 独立上下文（每个角色运行在独立 SubAgent 中）
- 对抗验证（Generator 实现 → Evaluator 评分 → 循环迭代）
- 结构化输出（实现总结、评估报告、裁决记录）

**自动化程度无法追齐**。核心差距在于：
- Claude Code 的 Orchestrator 可以**自动发起**对抗循环，无需人工干预
- TRAE Work 需要人类**手动触发**每个 SPEC 工作流
- 但一旦 SPEC 启动，tasks.md 中的对抗循环是**自动执行**的（包括 Decision 裁决）

**关于"拼出来的 Orchestrator"**：

我们的 Orchestrator 不是单一组件，而是多个 TRAE Work 原生能力的组合：
- SPEC 工作流 → Planner 界面
- Skills → 角色行为定义
- Rules → 护栏约束
- SubAgent → 上下文隔离
- tasks.md → 编排脚本（PGE 循环定义）
- Decision → 裁决代理（循环终止判定）
- File System → 状态总线
- 人类 → 最终决策者（escalate 升级）

这不是"缺少 Orchestrator"，而是"用现有零件组装了一个 Orchestrator"。在免费版的能力边界内，这是最优解。

#### 3.9.3 设计哲学差异

| 哲学维度 | Claude Code | TRAE Work（我们的实现） |
|---------|-------------|----------------------|
| **编排理念** | 平台内置，用户无需关心编排细节 | 方法论驱动，用户理解编排原理后手动配置 |
| **抽象层级** | 高抽象（用户只需描述需求） | 中抽象（用户需要理解 PGE 架构和配置） |
| **灵活性** | 低（受限于平台提供的编排模式） | 高（所有编排文件可手动编辑和定制） |
| **学习曲线** | 低（开箱即用） | 中（需要理解 Harness Engineering 方法论） |
| **适用场景** | 快速开发、原型验证 | 需要精细控制流程的复杂项目 |

**我们的选择**：在 TRAE Work 免费版的能力范围内，选择"方法论驱动 + 手动配置"的路径。这不是妥协——对于需要精细控制 Harness 行为的团队，手动配置带来的灵活性本身就是一种优势。

---

## 第四部分：实战指南

### 4.1 三件套骨架与 stage-executor playbook

> **核心理念**：Advisor 只提供**结构骨架**（章节契约，无业务内容）；三件套（spec/tasks/checklist）的具体内容由 **Orchestrator 在每个 Stage 的 `/spec` 对话中运行时填充**，并持久化到 `harness/milestones/{milestone}/stages/{stage}/`。骨架放在 `harness/templates/*.skeleton.md`。

#### spec.skeleton.md（Stage 规格骨架）

```markdown
# {Milestone Name} / Stage {id} — 规格

> 骨架由 Advisor 预置。Orchestrator 运行时按当前 Stage 上下文填充各 {…} 占位符。

## Stage 目标
{Orchestrator 填充：本 Stage 要交付什么}

## 范围边界
{Orchestrator 填充：包含 / 不包含}

## 验收标准（机械可检查）
1. {Orchestrator 填充}
2. {Orchestrator 填充}

## 依赖
{Orchestrator 填充：依赖哪些已完成 Stage}

## 非功能性需求
{Orchestrator 填充：响应时间、并发、覆盖率等量化指标}
```

#### tasks.skeleton.md（任务分解骨架 = 对抗编排）

```markdown
# {Milestone Name} / Stage {id} — 任务

> Orchestrator 据 spec.md 填充。每个 Stage 的对抗为顺序模拟（非自动循环），最多 3 轮返工，超限 escalate。

- [ ] [ORCHESTRATOR] 标注关键 Contract 点 → contract.md（目标/验收要点/边界）
- [ ] [GENERATOR] 按 contract.md 实现（TDD: {tdd_mode}）
- [ ] [GENERATOR] 实现总结 → gen.md
- [ ] [EVALUATOR] 质量评估（严格度: {eval_strictness}）→ eval.md
- [ ] [DECISION] 裁决（pass/retry/escalate，rounds≤3）→ decision.md
```

#### checklist.skeleton.md（底层机制：tasklist 完成性 gate）

```markdown
# {Milestone Name} / Stage {id} — 完成性 Checklist

> 定位 = 底层机制（TraeWork 原生完成性 gate）：机械检查该 Stage 的 tasklist 是否执行完成。
> 注意：这**不是**业务质量评分（质量由我们编排、在 task 内部运行的 Evaluator 的 eval.md 负责，见 0.2）。

- [ ] tasks.md 中所有 [GENERATOR]/[EVALUATOR]/[DECISION] 步骤均已完成
- [ ] Decision 裁决为 pass
- [ ] spec.md 的每条验收标准都有对应证据
- [ ] 无遗留 TODO / 未实现的接口
```

#### stage-executor playbook（运行时拉起入口）

stage-executor 是 L2 的**单一确定性入口**（触发短语"执行 Stage"/"开始阶段"）。它把"读 board + 读 plan + 用骨架 + 自检 + 派发"收敛为一条流程，避免 Orchestrator 自己东拼西凑：

```
1. 读 harness/state-board.json → 定位当前 Stage，校验 depends_on 已 passed
2. 读 harness/milestones/{milestone}/milestone-plan.md → 取该 Stage 定义
3. 运行 /spec，按 harness/templates/*.skeleton.md 产出三件套
   → 持久化到 harness/milestones/{milestone}/stages/{stage}/（不依赖 .trae/specs）
4. 自检门：spec 章节齐全？tasks 与 checklist 1:1 映射？否 → 停止并报告
5. 顺序派发 [GENERATOR]→[EVALUATOR]→[DECISION]（最多 3 轮返工，超限 escalate）
6. 回写 state-board.json：status / rounds / last_decision / artifacts
```

**验收标准编写原则**：

验收标准必须是 Evaluator 可以机械检查的，不应包含主观判断。以下是对比示例：

| 坏的验收标准 | 好的验收标准 |
|------------|------------|
| 结账流程应该正常工作 | 点击"下单"后 3 秒内显示订单号，状态码 200 |
| UI 应该好看 | 所有按钮在 320px-1920px 宽度下可点击，对比度 >= 4.5:1 |
| 错误处理应该完善 | 输入无效邮箱时显示红色提示"请输入有效的邮箱地址"，表单不提交 |

### 4.2 Skills 模板

#### Planner Skill

文件路径：`.trae/skills/planner-role/SKILL.md`

```yaml
---
name: planner-role
description: >
  当需要把用户需求规划为一个 Milestone 并战略性分解为若干可独立验收的 Stage 时使用。
  定义 Planner 角色——需求分析、Milestone→Stage 分解、依赖标注。
  注意：Planner 只输出 milestone-plan.md + 初始化 state-board.json，不生成三件套。
---
# Planner 角色规范

## 职责
将用户需求扩展为一个 Milestone（标注 kind: development | verification），
并战略性分解为若干可独立验收、可声明依赖的 Stage（战略级分解）。
**不生成三件套**——spec/tasks/checklist 由 Orchestrator 在每个 Stage 的 /spec 对话运行时产出。

## 行为准则
1. 只描述"做什么"和"为什么"，不描述"怎么做"
2. 每个 Stage 必须有明确的、可机械检查的验收标准要点
3. 标注 Stage 间依赖 depends_on（无依赖者可并发）
4. 验收标准使用确定性语言，禁止"应该""尽量""可能"
5. 非功能性需求必须包含量化指标
6. Stage 粒度适中：每个 Stage 应能在一次云端对话内完成

## 输出格式
- 写入 harness/milestones/{milestone}/milestone-plan.md（Milestone 概述 + 各 Stage 定义）
- 初始化/更新 harness/state-board.json（Milestone.kind + 各 Stage status=planned + depends_on）
- 不生成 spec/tasks/checklist

## 与 Orchestrator 的契约
milestone-plan.md 必须让 Orchestrator 能据此为单个 Stage 产出三件套：
- 每个 Stage 的目标、验收标准要点、depends_on、contract_mode（planned/codraft）
- 技术栈和架构约束
- 非功能性需求（量化指标）
```

#### Generator Skill

文件路径：`.trae/skills/generator-role/SKILL.md`

```yaml
---
name: generator-role
description: >
  当需要实现代码功能、编写测试、修复 Bug 时使用。
  定义 Generator 角色——专注于构建和实现，不评估自己的代码质量。
---
# Generator 角色规范

## 职责
根据 Planner 的规格说明和 Evaluator 认可的 Stage Contract，按 Stage 实现功能。

## 行为准则
1. 必须先读取 harness/milestones/{milestone}/stages/{stage}/ 下的所有文档
2. 严格遵循 TDD：先写测试 → 确认测试失败 → 再写实现
3. 每次代码改动后立即运行测试，确认全部通过
4. 完成一个 Stage 后立即 git commit，commit message 格式: "feat({scope}): {描述}"
5. 将实现总结写入 harness/milestones/{milestone}/stages/{stage}/gen.md
6. 禁止评价自己的代码好坏
7. 禁止修改 SPEC 文档或验收标准
8. 禁止跳过测试直接写实现

## 实现总结格式
### Stage {N}: {Stage 名称}
- 实现内容: {简述做了什么}
- 文件变更: {列出新增/修改的文件}
- 测试结果: {测试通过数量/总数}
- 已知限制: {如有}
```

#### Evaluator Skill

文件路径：`.trae/skills/evaluator-role/SKILL.md`

```yaml
---
name: evaluator-role
description: >
  当需要验证代码质量、执行功能测试、评分时使用。
  定义 Evaluator 角色——严格、多疑、不妥协的 QA 工程师。
---
# Evaluator 角色规范

## 职责
以"怀疑者"身份验证 Generator 的输出。严格评分，不妥协。

## 评分维度（每个 1-5 分）
1. 功能性 — 功能是否按 spec 要求正确实现
2. 工艺质量 — 代码结构、错误处理、边界条件
3. 完整性 — 测试覆盖、文档、验收标准全部满足
4. 用户体验 — 交互流畅、响应时间、错误提示

## 判定规则
- 总分 >= 16 且无单项 < 4 → 通过
- 任一维度低于 4 分 → 必须在评估报告中列出具体问题

## 行为准则
1. 必须用 RunCommand 实际运行测试；面向 UI 的 Stage 读 Orchestrator 代行写的 browser-check.md（浏览器验证由 Orchestrator 代行 MCP），不能仅凭代码审查判断
2. 必须截图留证
3. 不能"放水"——不确定时往低打分
4. 评估报告必须写入 harness/milestones/{milestone}/stages/{stage}/eval.md
5. 评估报告必须包含：通过/失败状态、各维度分数、具体问题描述、修复建议
6. 如果失败，必须列出可操作的修复步骤

## 评估报告格式
### Stage {N}: {Stage 名称}
- 状态: PASS / FAIL
- 功能性: {1-5} — {评语}
- 工艺质量: {1-5} — {评语}
- 完整性: {1-5} — {评语}
- 用户体验: {1-5} — {评语}
- 总分: {N}/20
- 截图: {路径}
- 问题列表: {如有}
- 修复建议: {如有}
```

### 4.3 Rules 模板

> TRAE Work 云端不支持 `.trae/rules/` 目录。项目规范统一写入项目根目录的 `RULE.md`，由「设置 > 规则」中的一条云端钩子规则加载（见 2.1 / 2.4 节）。按路径生效的细分规则也合并进 `RULE.md` 的分节中。

#### 项目规范 RULE.md

文件路径：`RULE.md`（项目根目录）

```markdown
# 项目规则

## 常用命令
- 启动开发服务器: `npm run dev`
- 运行全部测试: `npm test`
- 运行单个测试文件: `npm test -- {file}`
- Lint 检查: `npm run lint`

## 关键目录结构
- src/ — 源代码
- tests/ — 测试文件
- harness/ — 持久真值与消息总线（milestone-plan、三件套、contract、gen/eval/decision、state-board.json）
- .trae/specs/ — 原生 /spec 临时 scratch（gitignore，不依赖）

## 编码约定
- 禁止使用 `any` 类型
- 所有函数必须有类型注解
- 组件文件使用 PascalCase
- 工具函数文件使用 camelCase
- 测试文件命名为 `{filename}.test.ts`

## 全局禁止修改
- node_modules/
- dist/
- build/
- .git/
- .env 文件
- package.json（除非 Stage Contract 明确授权）

## API 层约束（对应 src/api/**、src/services/**）
- 所有 API 路由必须有输入验证
- 所有 API 响应必须包含统一的错误格式
- 数据库查询必须使用参数化查询，禁止字符串拼接
- 每个 API 端点必须有对应的集成测试
- 禁止在路由处理函数中直接操作数据库（必须通过 Service 层）
- 禁止返回原始数据库错误给客户端
```

> 说明：旧版（v3.0 及之前）曾使用 `.trae/rules/project_rules.md` + `.trae/rules/{name}.md` 按路径生效的独立规则文件。v3.1 起这些内容统一合并进 `RULE.md`，按章节区分作用范围。

### 4.4 Stage Contract 流程

**完整生命周期（端到端 8 步）**：

| 步骤 | 角色 | 输入 | 输出 | 说明 |
|------|------|------|------|------|
| 1 | Planner | 用户需求 | milestone-plan.md（Milestone + Stage 定义） | Milestone 规划对话 |
| 2 | Orchestrator | milestone-plan + 骨架 | 三件套 spec/tasks/checklist → .trae/specs（脚手架） | stage-executor playbook，每 Stage 一次 /spec |
| 3 | Orchestrator（或 G+E） | milestone-plan 要点 / 草稿 | contract.md（验收要点） | **planned**：Orchestrator 直接写；**codraft**：Generator 草稿→Evaluator 敲定 |
| 4 | Generator | contract.md | 代码实现 + 测试 | TDD 驱动 |
| 5 | Generator | 代码 | 自检 + git commit | 实现总结 → gen.md |
| 6 | Evaluator | 代码 + contract.md | 业务质量评估 → eval.md | 四维评分（task 内部） |
| 7 | Decision | gen.md + eval.md | pass/retry/escalate → decision.md | 独立盲审（rounds≤3，超限 escalate） |
| 8 | Orchestrator | checklist.md | 完成性 gate 通过 → 回写 board | 底层机制完成性验收 |

**Stage Contract 文件模板**（planned 由 Orchestrator 标注；codraft 由 Generator 草稿+Evaluator 敲定）：

```markdown
# Stage {id} Contract — {Milestone Name}

> 由 Orchestrator 在起 Stage 时标注关键点；Generator 据此实现，Evaluator 据此验收。

## 本轮目标
{一句话描述}

## 验收要点（可机械检查）
1. {条件 1}
2. {条件 2}
3. {条件 3}

## 边界
- 包含：{范围内}
- 不包含：{范围外，避免越权}

## 依赖
- {依赖的 Stage 或外部条件}

## 预估风险
- {潜在风险点}
```

### 4.5 SubAgent 配置模板

#### Generator SubAgent

文件路径：`.trae/agents/generator.md`

```markdown
# Generator SubAgent

## 角色
你是一个专注于代码实现的 Generator。你负责按照 SPEC 文档和 Stage Contract 编写代码和测试，不负责评估自己的代码质量。

## 工具集
- Read: 读取 SPEC 文档、Contract、源代码
- Write: 创建新文件
- Edit: 修改现有文件
- Glob: 搜索文件
- Grep: 搜索代码内容
- Bash: 运行开发服务器、测试、git 操作

## 路径白名单
### 允许修改
- src/
- tests/
- eval/

### 禁止修改
- harness/
- harness/
- RULE.md
- .trae/skills/
- package.json（除非 Stage Contract 明确授权）
- .env 文件

## 行为规则
1. 读取 harness/milestones/{milestone}/stages/{stage}/ 下的所有文档
2. 读取 harness/milestones/{milestone}/stages/{stage}/contract.md 获取当前 Stage Contract
3. 严格遵循 TDD
4. 完成后写入 harness/milestones/{milestone}/stages/{stage}/gen.md
5. 禁止评价自己的代码质量
```

#### Evaluator SubAgent

文件路径：`.trae/agents/evaluator.md`

```markdown
# Evaluator SubAgent

## 角色
你是一个严格的 QA 工程师。你的职责是验证 Generator 的输出，找出所有问题。你是"怀疑者"，不是"橡皮图章"。

## 工具集
- Read: 读取代码、Contract、评估报告
- Glob: 搜索文件
- Grep: 搜索代码内容
- Bash: 运行测试、Lint
- 浏览器验证：由 Orchestrator 代行 MCP（子代理无 mcp__ 工具），证据写 browser-check.md

## 路径白名单
### 允许读取
- 全部项目文件

### 允许写入
- eval/（仅评估报告）

### 禁止修改
- src/
- tests/
- .trae/
- 任何代码文件

## 行为规则
1. 读取 harness/milestones/{milestone}/stages/{stage}/contract.md 获取验收标准
2. 读取 harness/milestones/{milestone}/stages/{stage}/gen.md 了解实现内容
3. 必须实际启动应用并通过浏览器测试
4. 按四维评分标准打分
5. 写入 harness/milestones/{milestone}/stages/{stage}/eval.md
6. 截图保存到 eval/screenshots/
7. 不能"放水"，不确定时往低打分
```

#### Decision SubAgent

文件路径：`.trae/agents/decision.md`

```markdown
# Decision SubAgent

## 角色
你是中立裁决者（Orchestrator 代理）。你的职责是对比 Generator 的实现总结和 Evaluator 的评估报告，做出 pass/retry/escalate 裁决。你不写代码，不评估代码，只做裁决。

## 工具集
- Read: 读取实现总结、评估报告、Contract 文件

## 路径白名单
### 允许读取
- eval/（实现总结和评估报告）
- harness/（Stage Contract）
- harness/（产品规格说明）

### 允许写入
- eval/（仅 xxx-decision-N.md 裁决文件）

### 禁止修改
- src/
- tests/
- .trae/
- 任何代码文件

## 裁决规则
- pass: 两份报告无实质性分歧，Evaluator 评分通过 → 进入下一 Stage
- retry: 存在可修复的问题 → 输出 retry_focus，Generator 聚焦修复
- escalate: 无法裁决（评分标准争议、需求理解分歧等）→ 暂停，人类介入

## 行为规则
1. 保持中立：不偏向 Generator 或 Evaluator 任何一方
2. 引用证据：每个裁决决定必须引用两份报告中的具体内容
3. 矛盾优先：当两份报告存在矛盾时，必须明确指出矛盾点
4. 不确定时 escalate：当无法通过现有信息做出明确裁决时，标记为 escalate
5. 不看意图只看产出：裁决基于实际产出（代码、测试结果、截图）
6. 不质疑评分标准：尊重 Evaluator 的评分维度，但可质疑评分与证据的一致性
7. 输出格式为 JSON：{"decision": "pass|retry|escalate", "reason": "...", "retry_focus": ["..."]}
```

---

## 第五部分：从开发到验收的完整流程示例

### 5.1 示例场景

**场景**：构建一个"任务管理看板"Web 应用（Todo Kanban）。

**用户需求**（1-4 句话，模拟 Pattern B 输入）：

> 我需要一个任务管理看板，可以创建任务、拖拽任务在不同列之间移动（待办、进行中、已完成）。任务需要有标题、描述、优先级标签。后端用 Python FastAPI，前端用 React，数据库用 SQLite。

**技术栈**：React（前端看板）+ FastAPI（后端 API）+ SQLite（数据库）

### 5.2 Phase 1: 规划（Planner 执行）

Planner 接收用户需求，输出 `spec.md`（Stage 级战略分解）。将需求拆分为 5 个 Stage：

| Stage | 名称 | 内容 | 预估复杂度 | 依赖 |
|--------|------|------|-----------|------|
| 1 | 项目脚手架 + 数据库 | FastAPI 项目结构、SQLite 表定义、数据库迁移 | 低 | 无 |
| 2 | 看板 CRUD API | 看板列的创建、读取、更新、删除 | 中 | Stage 1 |
| 3 | 任务卡片 CRUD API | 任务卡片的创建、读取、更新、删除、移动 | 中 | Stage 2 |
| 4 | React 前端看板 UI | 看板页面、列组件、卡片组件、状态管理 | 中 | Stage 3 |
| 5 | 拖拽交互 + 端到端 | 拖拽移动卡片、乐观更新、E2E 测试 | 高 | Stage 4 |

Planner 产出 milestone-plan.md（含 Stage 定义）后，人类确认。之后逐个 Stage：Orchestrator 经 stage-executor playbook 启动，按骨架产出三件套（spec/tasks/checklist）到 `.trae/specs/`（过程脚手架），tasks.md 含 [GENERATOR]/[EVALUATOR]/[DECISION] 顺序对抗步骤，交付物 contract/gen/eval/decision 写入 harness/ 总线。

### 5.3 Phase 2: 执行（Generator 执行 Stage 1-N）

以 Stage 1 为例，展示完整流程：

**Stage Contract 标注**：

Orchestrator 读取 Stage 1 的 `spec.md`，在 `contract.md` 标注关键点：目标=搭建用户表与数据库连接；验收要点=含 Alembic 迁移脚本、数据库连接错误处理、模型测试通过；边界=只动 `models.py`/`database.py`，不碰认证逻辑。Generator 据此开始编码。

**Generator 编码过程**：

1. 创建 FastAPI 项目结构（`main.py`、`models.py`、`database.py`）
2. 编写数据库模型测试（`test_models.py`）
3. 确认测试失败（表尚未创建）
4. 实现数据库模型（`models.py`）
5. 运行测试 → 全部通过
6. 编写数据库连接测试（`test_database.py`）
7. 确认测试失败
8. 实现数据库连接（`database.py`）
9. 运行全部测试 → 全部通过
10. 写入 `eval/kanban-gen-001.md`（实现总结）
11. `git add` + `git commit -m "feat(kanban): Stage 1 — 项目脚手架 + 数据库模型"`

### 5.4 Phase 3: 评估（Evaluator 执行验证）

Evaluator 启动应用，通过浏览器和 API 测试验证 Stage 1 的输出：

**评估报告**（`eval/kanban-eval-001.md`）：

```markdown
### Stage 1: 项目脚手架 + 数据库
- 状态: PASS
- 功能性: 5 — 数据库表创建正确，API 启动正常
- 工艺质量: 4 — 代码结构清晰，缺少数据库连接池配置
- 完整性: 5 — 测试覆盖全部模型和连接逻辑
- 用户体验: N/A（本 Stage 无 UI）
- 总分: 14/15（排除 N/A 维度）
- 截图: eval/screenshots/stage-1-api-health.png
- 问题列表: 无阻塞性问题
- 修复建议: 建议在 Stage 2 中增加数据库连接池配置
```

**模拟一次"失败"场景**（Stage 4）：

```markdown
### Stage 4: React 前端看板 UI
- 状态: FAIL
- 功能性: 3 — 卡片组件未显示优先级标签颜色
- 工艺质量: 3 — 状态管理未处理加载状态，白屏闪烁
- 完整性: 4 — 测试覆盖基本功能
- 用户体验: 3 — 卡片列表在移动端不响应
- 总分: 13/20
- 问题列表:
  1. 优先级标签仅显示文字，未按 spec 要求使用颜色区分
  2. 数据加载时无 Loading 状态，用户看到白屏
  3. 移动端（< 375px）卡片宽度溢出
- 修复建议:
  1. 在 Card 组件中根据 priority 属性渲染对应颜色的 Tag
  2. 在 useQuery 中增加 isLoading 状态，渲染 Loading 骨架屏
  3. 在 Card 样式中增加 max-width: 100% 和 overflow: hidden
```

Generator 收到失败报告后，逐一修复问题，重新提交。Evaluator 再次验证 → 通过。

在每一轮评估后，**Decision SubAgent** 读取 Generator 总结和 Evaluator 报告，做出裁决：
- 如果通过 → 进入下一 Stage
- 如果失败但问题明确 → Decision 指定 retry_focus，Generator 重试
- 如果存在分歧或无法裁决 → Decision 标记 escalate，暂停执行，人类介入裁决

Generator 收到失败报告后，逐一修复问题，重新提交。Evaluator 再次验证，Decision 裁决 → pass，进入下一 Stage。

### 5.5 Phase 4: 迭代与验收

全部 5 个 Stage 完成后，Evaluator 进行端到端验收：

- 从零启动应用
- 通过浏览器完成完整的用户流程：创建看板列 → 创建任务卡片 → 拖拽移动卡片 → 验证数据库状态
- 运行全套 E2E 测试
- 生成最终验收报告

**Harness 自我迭代**：从本次项目中识别出以下改进点，更新 Rules 和 Skills：

- 规则更新：在 `project_rules.md` 中增加"所有前端数据获取必须处理 Loading 和 Error 状态"
- Skill 更新：在 Generator Skill 中增加"编写 UI 组件时，必须同步编写移动端响应式样式"
- 工具更新：增加 Lint 规则，自动检测未处理优先级标签颜色的 Card 组件

### 5.6 完整流程回顾

| 阶段 | 角色 | 耗时占比 | 关键产出 |
|------|------|----------|----------|
| 规划 | Planner | 10% | spec.md（Stage 级战略分解） |
| 编排 | Orchestrator | 5% | tasks.md（动态生成，对抗循环步骤） |
| 执行 Stage 1-5 | Generator | 45% | 代码、测试、git 提交历史 |
| 评估 Stage 1-5 | Evaluator | 30% | 评估报告、截图、修复反馈 |
| 裁决 Stage 1-5 | Decision | 5% | pass/retry/escalate 裁决记录 |
| 最终验收 | Evaluator | 5% | 最终验收报告 |

**Solo Agent vs PGE Harness 对比**：

| 维度 | Solo Agent | PGE Harness |
|------|-----------|-------------|
| 代码质量 | 中等，存在自评偏差 | 高，对抗评估发现隐藏问题 |
| 功能完整性 | 约 70-80% | 约 95%+ |
| 可维护性 | 低，缺少标准化流程 | 高，标准化文档和评估流程 |
| 上下文效率 | 低，单上下文膨胀 | 高，独立上下文隔离 |
| 迭代能力 | 弱，难以持续改进 | 强，Harness 自我迭代 |

---

## 附录

### 附录 A：术语表

| 术语 | 英文 | 定义 |
|------|------|------|
| Harness | Harness | 围绕模型构建的工程化环境，包括工具、规则、护栏、反馈回路和编排机制 |
| 前馈控制 | Feedforward | 在 AI 生成内容前注入约束，事前预防 |
| 反馈控制 | Feedback | 在 AI 生成内容后检测问题，事后纠正 |
| 确定性控制 | Computational | 快速、可靠、可自动执行的控制（如 Lint、类型检查） |
| 推断性控制 | Inferential | 慢速但能处理语义层面的控制（如 LLM-as-Judge） |
| 上下文腐化 | Context Rot | 随着对话轮次增加，模型性能持续下降的现象 |
| 逐步披露 | Progressive Disclosure | 按需加载 Skill 内容，任务完成后释放上下文 |
| Stage Contract | Stage Contract | Generator 和 Evaluator 在 Stage 开始前达成的验收协议 |
| 引导循环 | Steering Loop | 人类观察 Agent 失败模式 → 改进 Harness 组件 → Agent 不再重复同样错误 |
| 质量左移 | Keep Quality Left | 将质量检查尽可能前置到变更生命周期早期阶段 |

### 附录 B：参考资源

> **来源核实说明（2026-06）**：以下链接经 HTTP 核实分组。"已核实"= 链接可访问且为权威来源；"未核实"= 状态码不确定（如反爬 403 或文档站 soft-200），引用其结论时请审慎。已删除若干经核实为失效/伪造的旧链接（404）。

**已核实（权威来源）**
- [LangChain — The Anatomy of an Agent Harness](https://blog.langchain.com/the-anatomy-of-an-agent-harness/) — Agent = Model + Harness 定义
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — 长时运行 Agent 的 Harness 编排（Pattern A/B 来源）
- [Martin Fowler / Birgitta Böckeler — Harness Engineering](https://martinfowler.com/articles/harness-engineering.html) — Feedforward/Feedback、Computational/Inferential、Keep Quality Left、Steering Loop
- [Mitchell Hashimoto — My AI Adoption Journey](https://mitchellh.com/writing/my-ai-adoption-journey) — 6 阶段 AI 采用框架
- [TRAE 官方文档 — SPEC 工作流](https://docs.trae.cn/solo/spec-and-plan)
- [TRAE 官方文档 — 配置远程环境（预装依赖/浏览器）](https://docs.trae.cn/solo_set-up-the-remote-environment)
- [TRAE 官方社区 — SubAgent 多线程](https://forum.trae.cn/t/topic/1189)
- [TRAE 官方社区 — SOLO 多任务并行零冲突](https://forum.trae.cn/t/topic/1139)
- [TRAE 官方社区 — Agent 概念速览](https://forum.trae.cn/t/topic/2702)

**未核实（状态不确定，谨慎引用）**
- OpenAI — Harness Engineering 实践（"零人类代码行 / 100 万行 / 1500 PR"等数据出处反爬，无法独立核实）：`https://openai.com/index/harness-engineering/`
- [Claude Code — Dynamic Workflows 文档](https://docs.anthropic.com/en/docs/claude-code/workflows)（文档站 soft-200，页面具体内容未独立核实）

> 已删除：原列表中 `martinfowler.com/articles/harness-engineering-genai/`、`.../blending-ai-human-judgment/`、`blog.langchain.dev/anatomy-of-an-agent-harness/`、`anthropic.com/engineering/harness-design-for-long-running-application-development`、`qiita.com/kzk_maeda/items/5c3a4e2f...` 均经核实为 404/失效，已用上方权威链接替代或移除。


### 附录 C：TRAE Work 配置速查表

| 配置文件 | 路径 | 作用 |
|----------|------|------|
| 项目规范 | `RULE.md`（项目根目录） | 全团队共享的编码规范、安全策略、禁止修改路径（由云端钩子规则加载） |
| 钩子规则 | 「设置 > 规则」中的一条云端规则 | 让每个 Task 启动时自动读取 `RULE.md`（一次性配置） |
| Planner Skill | `.trae/skills/planner-role/SKILL.md` | Planner 角色行为规范 |
| Generator Skill | `.trae/skills/generator-role/SKILL.md` | Generator 角色行为规范（内嵌 Agent 工具集与路径白名单） |
| Evaluator Skill | `.trae/skills/evaluator-role/SKILL.md` | Evaluator 角色行为规范（业务质量四维评分，不含裁决） |
| Decision Skill | `.trae/skills/decision-role/SKILL.md` | 独立中立裁决者（只读 gen/eval/contract → decision.md） |
| Generator Agent | `.trae/agents/generator.md` | Generator SubAgent 配置（可选，当前云端不支持，未来兼容） |
| Evaluator Agent | `.trae/agents/evaluator.md` | Evaluator SubAgent 配置（可选，当前云端不支持，未来兼容） |
| Decision Agent | `.trae/agents/decision.md` | Decision SubAgent 配置（可选，当前云端不支持，未来兼容） |
| SPEC 规格 | `harness/milestones/{milestone}/stages/{stage}/spec.md` | Planner 输出的产品规格（Stage 级分解） |
| stage-executor | `.trae/skills/stage-executor/SKILL.md` | 运行时拉起 playbook（Orchestrator 据此产三件套并派发 G/E/D） |
| Stage Contract | `harness/milestones/{milestone}/stages/{stage}/contract.md` | Stage N 的验收协议 |
| 评估报告 | `harness/milestones/{milestone}/stages/{stage}/eval.md` | Evaluator 对 Stage N 的评估 |
| 实现总结 | `harness/milestones/{milestone}/stages/{stage}/gen.md` | Generator 对 Stage N 的实现总结 |
| 裁决记录 | `harness/milestones/{milestone}/stages/{stage}/decision.md` | Decision 对 Stage N 的裁决（pass/retry/escalate） |
| 持久记忆 | `harness/milestones/{milestone}/memory.md` | 跨会话的持续学习记录 |