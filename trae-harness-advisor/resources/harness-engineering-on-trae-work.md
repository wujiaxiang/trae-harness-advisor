# Harness Engineering on TRAE Work：Planner-Generator-Evaluator 多智能体对抗架构最佳实践

> **版本**: v3.1  
> **日期**: 2026-06-29  
> **变更**: v3.1 基于 TRAE Work 平台能力调研，删除 `.trae/rules/`（云端不支持），改为 RULE.md + 钩子规则方案；Agent 配置保留为可选生成（未来兼容）；Agent 角色行为内嵌到 Skill 中保证当前可用  
> **v3.0**: 新增三层推理流程、目录解耦（默认不绑定 .trae）、Planner 只生成空模板（主Agent 推理填充）  
> **v2.0**: 新增 1.4 Claude Code 对标分析、3.2 四角色架构、3.6 Decision 角色、3.9 与 Claude Code 对比、Planner 职责收窄、tasks.md 动态生成  
> **目标读者**: LLM/Agent（读完后能理解并实现 Planner-Generator-Evaluator 工作流），同时兼容人类开发者阅读  
> **基于平台**: TRAE Work（截至 2026 年 6 月最新能力）  
> **关联文档**: 本项目的会话背景、设计决策和已知限制见 `../../conversation-context-and-design-decisions.md`  
> **配套 Skill**: `trae-harness-advisor` — 自动化 Harness 项目改造（见 `../` 即当前 Skill 目录）

---

## 目录

1. [第一部分：Harness Engineering 方法论综述](#第一部分harness-engineering-方法论综述)
2. [第二部分：TRAE Work 平台能力分析](#第二部分trae-work-平台能力分析)
3. [第三部分：TRAE Work 上的 Harness 架构设计](#第三部分trae-work-上的-harness-架构设计)
4. [第四部分：实战指南](#第四部分实战指南)
5. [第五部分：从开发到验收的完整流程示例](#第五部分从开发到验收的完整流程示例)
6. [附录](#附录)

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

Anthropic 在 2026 年 3 月的文章《Harness design for long-running application development》中系统描述了两种 Harness 架构模式：

**Pattern A: Initializer + Coding Agent**

流程：需求 → Initializer 生成 Spec 和 Feature 分解 → Coding Agent 逐 Feature 实现 → 每个 Feature 完成后进行上下文重置 → 结构化交接。

这一模式的核心是**上下文重置**。Coding Agent 完成一个 Feature 后，上下文被清空，下一个 Feature 从干净状态开始。这种设计解决了早期模型（如 Sonnet 4.5）的"上下文焦虑"问题——模型在长上下文中会变得犹豫不决、过度保守。

**Pattern B: Planner-Generator-Evaluator（PGE）**

灵感来自 GAN（生成对抗网络）架构。三个角色各有独立职责：

- **Planner**：将模糊需求扩展为完整的产品规格说明，分解为可执行的 Sprint
- **Generator**：按 Sprint 实现功能，只负责构建，不负责评判
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
| **编排修改能力** | 静态文件，可修改 | 运行时动态生成，可自适应 | 预编排（spec.md 静态），tasks.md 由云端 Agent 动态生成 |
| **持久状态** | 内置跨会话状态 | 内置 | 文件系统（global_task_board.json、eval/） |
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

TRAE Work 的 `.trae/` 目录结构是 Harness 配置的物理载体。其作用域体系如下：

```
项目根目录/
├── .trae/                      # 静态 Harness 配置（git 可同步）
│   ├── skills/                 # 技能（L0: Context Layer，唯一云端自动加载的通道）
│   │   └── {skill-name}/
│   │       └── SKILL.md
│   └── agents/                 # SubAgent 配置（可选，L2: Orchestration Layer，当前云端不支持，保留供未来兼容）
│       └── {agent-name}.md
├── RULE.md                     # 项目规范（L0: Context Layer，通过钩子规则加载）
├── harness-specs/              # 业务文档（可配置，默认不绑定 .trae）
│   └── {feature}/
│       ├── spec.md             # 空模板（Planner 生成）→ 主Agent 运行时填充
│       ├── sprint-plan.md      # 全局 Sprint 规划（Planner 生成）
│       └── tasks-pattern.md    # 编排模式参考（专家 Skill 预置）
├── harness-contracts/          # Sprint Contract（可配置）
│   └── {feature}/
│       └── sprint-N.md
├── eval/                       # 运行时输出（评估报告、实现总结、裁决记录）
└── global_taskboard.json       # 可选，跨 session 状态
```

**关键设计决策（v3.1）**：
- `.trae/skills/` 是 TRAE Work 云端唯一自动加载的配置通道，Agent 角色行为已内嵌到 Skill 中，保证当前可用
- `.trae/rules/` 已删除——TRAE Work 不支持此目录，改为 `RULE.md` + 钩子规则方案
- `.trae/agents/` 保留为可选生成——当前 TRAE Work 云端不支持，但未来可能支持，Agent 角色行为同时内嵌在 Skill 中
- 钩子规则：用户在 TRAE Work「设置 > 规则」中创建一条云端规则，让所有 Task 启动时自动读取 `RULE.md`

作用域优先级：**Project-level（`.trae/`，团队共享）> User-level（全局，个人偏好）> Local（仅本机）**。

### 2.2 SPEC 工作流

SPEC 工作流是 TRAE Work 的核心编排机制，生成三阶段文档组：

- `spec.md`（大纲）：产品概述、技术架构、范围边界
- `tasks.md`（任务列表）：可执行的任务分解，含依赖关系和验收标准
- `checklist.md`（验收清单）：可机械检查的通过/失败条件

在 Harness 体系中，我们简化了 SPEC 输出：Planner 只生成 spec.md，tasks.md 由云端 Agent 运行时动态生成。checklist.md 的验收功能被整合到 Evaluator 的四维评分标准中，不再作为独立文件。

**关键机制：AI 暂停确认**。文档首次生成后，AI 暂停执行，等待用户确认。用户可以直接编辑文档内容，或用自然语言告诉 AI 修改。确认后，任务列表和验收清单的状态随执行进度自动更新。

在 Harness 体系中，SPEC 工作流的暂停确认阶段自然映射为 **Planner 角色**——人类（或上游 Planner Agent）在此阶段与 AI 对齐需求、审查规格、确认任务拆分。

### 2.3 Skills 体系

Skills 是 TRAE Work 的**按需加载（Progressive Disclosure）**机制。每个 Skill 包含 `name`、`description`（触发条件）和完整的指令内容。Agent 仅在匹配到触发条件时加载 Skill 内容，任务完成后释放上下文。

Skills 与 Rules 的本质区别：

| 特性 | Rules | Skills |
|------|-------|--------|
| 加载时机 | 会话开始时全量加载 | 按需触发，按需加载 |
| 上下文占用 | 始终占用 | 仅在需要时占用 |
| 适用场景 | 全局约束、编码规范、安全策略 | 特定任务 SOP、设计规范、测试流程 |
| Harness 角色 | Computational Feedforward | Inferential Feedforward Guide |

在 Harness 体系中，Skills 是封装角色行为的关键载体。每个 Harness 角色（Planner、Generator、Evaluator）使用独立的 Skill 定义其行为规范。

### 2.4 Rules 体系

Rules 提供三层配置：

- **project_rules.md**（项目规则）：全团队共享的编码规范、技术栈约束、安全策略
- **user_rules.md**（个人规则）：个人偏好，如语言、代码风格、交互方式
- **path-based rules**（按路径生效）：仅对特定目录生效的规则，减少无关噪音

在 Harness 体系中，Rules 是 **Computational Feedforward 控制**的核心手段。规则在模型执行前注入约束，从源头防止越权操作。

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
                        │  SPEC 暂停确认 + 最终验收   │
                        │  疑难裁决（escalate 升级）  │
                        └────────────┬─────────────┘
                                     │
          ┌──────────────────────────┼──────────────────────────┐
          │                          │                          │
┌─────────▼─────────┐    ┌───────────▼──────────┐    ┌─────────▼─────────┐
│  第一层：专家 Skill │    │  第二层：Planner      │    │ 第三层：主Agent     │
│  初始化 Harness    │    │  = SPEC 工作流暂停    │    │  云端运行时         │
│  基础设施          │    │  输出:                │    │  读取模板+全局规划  │
│  输出: Skills +    │    │  - sprint-plan.md    │    │  → 填充 spec.md    │
│  Agents + Rules +  │    │  - spec.md（空模板）  │    │  → 生成 tasks.md   │
│  tasks-pattern.md  │    │  更新: global_board  │    │  → 调度 SubAgent   │
└────────────────────┘    └───────────────────────┘    └──────────┬──────────┘
                                                                  │
                                              ┌───────────────────┼───────────────────┐
                                              │                   │                   │
                                  ┌───────────▼──┐    ┌──────────▼──┐    ┌──────────▼──┐
                                  │  Generator   │    │  Evaluator   │    │  Decision   │
                                  │  SubAgent    │    │  SubAgent    │    │  SubAgent   │
                                  │  独立上下文   │    │  独立上下文   │    │  独立上下文  │
                                  │  写代码+测试  │    │  浏览器验证  │    │  中立裁决    │
                                  │  输出: eval/  │    │  输出: eval/ │    │  输出: pass/ │
                                  │  gen-N.md     │    │  eval-N.md   │    │  retry/esc  │
                                  └──────────────┘    └─────────────┘    └─────────────┘
```

**关键变化（v3.0 三层推理）**：
- **三层推理流程**：专家 Skill（基础设施）→ Planner（全局规划+模板）→ 主Agent（推理填充spec→生成tasks→调度SubAgent）
- Planner 只输出全局 Sprint 规划 + spec.md 空模板，不填充具体内容
- 主Agent 运行时读取模板 + 全局规划 → 推理填充 spec.md → 生成 tasks.md
- 所有业务文档目录（spec、contracts）默认不绑定 `.trae/`，支持用户自定义

### 3.2 四角色 PGE+D 架构与三层推理

本架构在 Anthropic 的 Pattern B（Planner-Generator-Evaluator）三角色基础上，新增 **Decision（裁决者）** 角色，形成四角色 PGE+D 架构。Decision 充当 Orchestrator 代理——在 Generator 和 Evaluator 产生分歧时做出中立裁决，实现对抗循环的自动化闭环。

**三层推理模型**是 v3.0 的核心设计：整个 Harness 工作流分为三个推理层级，每层都有自主推理能力，上层生成的规范约束下层行为。

#### 三层推理分工表

| 层级 | 角色 | 触发 | 输入 | 输出（交付物） | 自主推理能力 |
|------|------|------|------|----------------|-------------|
| 第一层 | **专家 Skill** | 用户调用 | 技术栈、目录偏好、TDD、严格度等 | 1. 角色 Skill（Planner/Generator/Evaluator）<br>2. Agent 配置（Generator/Evaluator/Decision）<br>3. 项目 Rules（根据技术栈定制）<br>4. tasks-pattern.md（编排模式参考）<br>5. sprint-N.md 模板<br>6. 可选：global_taskboard.json | 根据技术栈动态定制编码规范、TDD 流程、评估维度 |
| 第二层 | **Planner** | `/spec` | 用户业务需求 | 1. **全局 Sprint 文档**（sprint-plan.md）<br>2. **spec.md 模板**（空结构，只有框架） | 理解业务需求，拆分 Sprint 大方向，定制模板结构 |
| 第三层 | **主Agent** | 用户指定 Sprint | spec.md 模板 + 全局 Sprint 文档 + 用户指定 Sprint N | 1. **推理填充 spec.md**（具体内容）<br>2. **生成 tasks.md**（对抗循环编排）<br>3. 调度 SubAgent | 根据模板和全局规划，推理生成具体规格和编排 |
| 执行层 | **Generator** | tasks.md 步骤 | spec.md + Sprint Contract | 代码 + 测试 + 实现总结 | TDD 实现 |
| 执行层 | **Evaluator** | Generator 完成 | 代码 + Contract | 评估报告 + 四维评分 | 怀疑者立场验证 |
| 执行层 | **Decision** | Evaluator 完成 | 两份报告 | pass/retry/escalate 裁决 | 中立裁决 |

**为什么 Planner 只生成空模板？** Planner 知道业务全貌，但不知道具体 Sprint 执行的上下文。用户可能在 Planner 完成后，过几天才执行 Sprint 3，期间项目上下文可能变化。因此：
- Planner 生成全局 Sprint 文档（大方向规划）+ spec.md 模板（结构框架）
- 主Agent 在运行时，根据用户指定的 Sprint + 当前项目上下文，推理填充 spec.md
- 好处：spec.md 内容由运行时上下文决定，不需要 git 同步，也更灵活

**三层约束链**：

```
专家 Skill 生成的规范
    │
    ├── planner-role Skill ──→ 约束 Planner 的行为（如何拆分 Sprint、如何写模板）
    │
    ├── tasks-pattern.md ────→ 约束主Agent 的行为（如何生成 tasks.md、如何编排循环）
    │
    ├── generator-role Skill  ──→ 约束 Generator 的行为（TDD、代码规范、总结格式）
    ├── evaluator-role Skill  ──→ 约束 Evaluator 的行为（评分维度、验证方法）
    └── decision Agent 配置  ──→ 约束 Decision 的行为（裁决规则、输出格式）
```

四个角色各有独立职责，通过**文件系统作为通信总线**传递状态：

| 角色 | 职责 | 输入 | 输出 | 实现方式 | 推理层级 |
|------|------|------|------|----------|----------|
| **专家 Skill** | 初始化 Harness 基础设施 | 技术栈、目录偏好、配置参数 | Skills + RULE.md + tasks-pattern.md + sprint-N.md 模板 + 钩子规则文本 | 问答 → 生成 | 第一层 |
| **Planner** | 战略级需求分解 | 用户需求 | sprint-plan.md（全局规划）+ spec.md（空模板） | SPEC 工作流暂停阶段 | 第二层 |
| **主Agent** | 运行时推理填充 + 编排 | spec.md 模板 + 全局 Sprint 文档 | 填充后的 spec.md + tasks.md | 云端 Agent 运行时 | 第三层 |
| **Generator** | Sprint 级代码实现 | spec.md + Sprint Contract | 代码 + 测试 + 实现总结 | Skill 角色定义（当前）<br>Agent 配置文件（未来兼容） | 执行层 |
| **Evaluator** | 质量验证与评分 | Generator 输出 + Contract | 评估报告（四维评分） | Skill 角色定义（当前）<br>Agent 配置文件（未来兼容） | 执行层 |
| **Decision** | 中立裁决（Orchestrator 代理） | Generator 总结 + Evaluator 报告 | pass / retry / escalate | 嵌入在 Evaluator Skill 中（当前）<br>Agent 配置文件（未来兼容） | 执行层 |

**实现方式说明（v3.1）**：TRAE Work 云端唯一自动加载的配置通道是 `.trae/skills/`。`.trae/agents/` 当前不支持，因此 Agent 角色行为（工具集、路径白名单、Decision 裁决规则）已内嵌到对应 Skill 中。Agent 配置文件保留为可选生成，供未来 TRAE Work 支持时使用。

**职责边界（关键设计决策）**：

- **专家 Skill 只做基础设施初始化**：生成 Skills、Agents、Rules、tasks-pattern.md、sprint-N.md 模板。不生成 spec.md（因为不知道业务需求）。
- **Planner 只做战略分解 + 空模板**：输出 sprint-plan.md（全局 Sprint 规划）+ spec.md（空模板，只有结构框架）。不填充具体内容——由主Agent 运行时推理填充。
- **主Agent 是推理填充者**：用户指定 Sprint → 读取模板 + 全局规划 → 推理填充 spec.md → 生成 tasks.md → 调度 SubAgent。
- **Decision 是 Orchestrator 代理**：TRAE Work 没有内置 Orchestrator，Decision 角色通过"只读两份报告 → 输出裁决"的方式模拟 Orchestrator 的决策功能。正常情况（pass/retry）自动处理，罕见情况（escalate）升级给人类。
- **文件系统是状态总线**：所有角色之间不直接通信，通过 `{spec_dir}/`、`{eval_dir}/`、`{contract_dir}/` 目录下的文件传递状态。这是 TRAE Work 无持久会话架构下的最优解。
- **RULE.md 钩子规则**：TRAE Work 不支持 `.trae/rules/` 目录。替代方案是在「设置 > 规则」中创建一条云端钩子规则，让所有云端 Task 启动时自动读取项目根目录的 `RULE.md`。用户仅需操作一次。

**四角色对抗循环流程**：

```
[Sprint Start]
      │
      ▼
[GENERATOR] → 提出 Sprint Contract 草案
      │
      ▼
[EVALUATOR] → 审查 Contract（批准后才可编码）
      │
      ▼
[GENERATOR] → 按 Contract 实现（TDD）
      │
      ▼
[GENERATOR] → 实现总结 → eval/{feature}-gen-{N}.md
      │
      ▼
[EVALUATOR] → 评估验证 → eval/{feature}-eval-{N}.md
      │
      ▼
[DECISION]  → 读取两份报告 → 裁决
      │
      ├── pass     → 进入下一 Sprint
      ├── retry    → 回到 [GENERATOR]，附带 Decision 的 retry_focus
      └── escalate → 暂停，请求人类裁决
```

### 3.3 Planner 角色定义

**职责**：将 1-4 句话的用户需求扩展为完整的产品规格说明，分解为可执行的 Sprint。**Planner 只做战略级分解，生成空模板，不填充具体内容**。

**输出边界**：Planner 输出两个交付物：
1. **全局 Sprint 文档**（`sprint-plan.md`）：所有 Sprint 的大方向规划，每个 Sprint 的简要概述
2. **spec.md 模板**（空结构）：只有结构框架，所有内容为占位符，不填充具体业务细节

**不输出 tasks.md**：tasks.md 由主Agent 运行时根据 tasks-pattern.md 动态生成。

**在 TRAE Work 中的实现**：

- 使用 SPEC 工作流作为 Planner 的交互界面
- 创建 `planner` Skill 定义 Planner 的行为规范
- Planner 输出存储为 `{spec_dir}/sprint-plan.md` 和 `{spec_dir}/spec.md`
- 更新 `global_task_board.json` 记录当前 Feature 状态

**Planner 与主Agent 的契约**：

Planner 输出的 spec.md 模板必须包含结构框架让主Agent 填充：
- 产品概述占位符
- 技术栈占位符
- Sprint 分解占位符（每个 Sprint 的目标、验收标准、依赖关系）
- 非功能性需求占位符（量化指标）
- 开放问题占位符

主Agent 启动后读取 spec.md 模板 + sprint-plan.md（全局规划），按照 Harness 编排模式推理填充 spec.md → 生成 tasks.md。Planner 不干预主Agent 的编排决策。

**Planner 的核心原则**：

1. 从用户需求中提取核心功能，而非技术实现细节
2. 将功能分解为独立、可验证的 Sprint，每个 Sprint 有明确的验收标准
3. 识别 Sprint 之间的依赖关系，标注必须串行的强依赖
4. 验收标准必须是 Evaluator 可以机械检查的，而非主观判断

### 3.4 Generator 角色定义

**职责**：根据 Planner 的规格说明，以 Sprint 为单位实现功能。只负责构建，不负责评判。

**核心行为**：

1. 读取 Planner 输出的 spec.md 和 tasks.md
2. 对当前 Sprint 提出 Contract 草案（"本轮构建什么、如何验证成功"）
3. 与 Evaluator 协商 Contract 直到达成一致
4. 严格遵循 TDD：先写测试，确认测试失败，再写实现
5. 每次代码改动后立即运行测试
6. 完成一个 Sprint 后立即 git commit
7. 将实现总结写入 `eval/{feature}-gen-{sprint}.md`

**在 TRAE Work 中的实现**：

- 创建 `generator` SubAgent（`.trae/agents/generator.md`）
- 创建 `generator-role` Skill（`.trae/skills/generator-role/SKILL.md`）
- 工具集：Read、Write、Edit、Glob、Grep、Bash（git、test、dev server）
- 路径白名单：仅允许修改 `src/`、`tests/` 和 `eval/` 目录

**Generator 的禁止行为**：

- 禁止评价自己的代码好坏
- 禁止修改 Spec 文档或验收标准
- 禁止跳过测试直接写实现
- 禁止跨 Sprint 修改不属于当前 Sprint 的文件

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
- 工具集：Read、Glob、Grep、Bash（test、lint）、Playwright MCP（浏览器验证）
- 工作目录：只读模式，仅可写入 `eval/` 目录

**Evaluator 的核心原则**：

1. 必须实际启动应用并通过浏览器测试，不能仅凭代码审查判断
2. 必须截图留证
3. 不能"放水"——不确定时往低打分
4. 评估报告必须包含：通过/失败状态、各维度分数、具体问题描述、修复建议

### 3.6 Decision 角色定义

**职责**：作为中立裁决者（Orchestrator 代理），在 Generator 和 Evaluator 产生分歧时做出裁决。Decision 不写代码，不评估代码，只做 pass/retry/escalate 三种决定。

**为什么需要 Decision？**

在三角色架构中，Generator 和 Evaluator 之间的分歧没有自动解决机制。Evaluator 给出 FAIL 后，Generator 需要修改，但如果没有第三方裁决，可能出现两种情况：
- Generator 过度修改（修改了不需要改的部分，引入新问题）
- Generator 和 Evaluator 陷入僵局（Evaluator 反复要求修改，Generator 反复提交）

Decision 通过"只读两份报告 → 输出裁决"的方式，模拟 Orchestrator 的决策功能，为对抗循环提供自动化闭环。

**在 TRAE Work 中的实现**：

- 创建 `decision` SubAgent（`.trae/agents/decision.md`）
- 工具集：仅 Read（只读，不写代码）
- 路径白名单：允许读取 eval/、.trae/contracts/、.trae/specs/；允许写入仅 eval/xxx-decision-N.md
- 裁决逻辑：

```
读取 eval/{feature}-gen-{N}.md（Generator 实现总结）
读取 eval/{feature}-eval-{N}.md（Evaluator 评估报告）
      │
      ▼
对比两份报告 → 做出裁决
      │
      ├── pass: 两份报告无实质性分歧，Evaluator 评分通过 → 进入下一 Sprint
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
| L2: 任务级 | 每个 Sprint 使用独立的 Generator 实例 | 防止 Context Rot，每个 Sprint 从干净上下文开始 |
| L3: 路径级 | 路径白名单限制每个 SubAgent 的文件访问范围 | 防止越权修改，确保并行安全 |

**共享状态机制**：

文件系统是 SubAgent 之间唯一的通信总线。所有状态通过以下目录传递：

- `{spec_dir}/{feature}/` — Planner 输出的规格和模板，Generator 和 Evaluator 共同读取
- `{eval_dir}/` — Generator 写入实现总结，Evaluator 写入评估报告
- `{contract_dir}/` — Sprint Contract 协议文件

**上下文重置策略**：

当 Generator 的上下文接近窗口上限时，主 Agent 触发 Compaction（上下文压缩）。如果 Compaction 后仍不足，则启动 Context Reset——完成当前 Sprint 的 commit，然后启动新的 Generator SubAgent 实例处理下一个 Sprint。

### 3.8 沟通协议设计

**Sprint Contract 协议**

```
Planner 输出 spec.md
        │
        ▼
Generator 提出 Sprint Contract 草案
        │
        ▼
Evaluator 审查 Contract 草案  ──→  提出修改意见
        │                              │
        ▼                              │
双方达成一致  ◄─────────────────────────┘
        │
        ▼
Generator 按 Contract 实现
        │
        ▼
Generator 自检后提交
        │
        ▼
Evaluator 运行测试 + 浏览器验证
        │
        ├── Pass → 进入下一 Sprint
        │
        └── Fail → Generator 修复 → 重新提交 Evaluator
```

**文件结构约定**：

```
{skill_dir}                    # 默认 .trae/skills/
├── planner-role/SKILL.md
├── generator-role/SKILL.md    # 含 Agent 工具集和路径白名单
└── evaluator-role/SKILL.md    # 含 Decision 角色定义
（可选）{agent_dir}            # 默认 .trae/agents/（仅 generate_agents=true 时生成）
├── generator.md
├── evaluator.md
└── decision.md
RULE.md                        # 项目根目录（钩子规则加载）
{spec_dir}/{feature}/          # 默认 harness-specs/{feature}/
├── sprint-plan.md             # Planner 输出：全局 Sprint 规划
├── spec.md                    # Planner 输出：空模板 → 主Agent 运行时填充
└── tasks-pattern.md           # 专家 Skill 预置：编排模式参考
{contract_dir}/{feature}/      # 默认 harness-contracts/{feature}/
├── sprint-1.md                # Sprint 1 Contract
├── sprint-2.md
└── ...
{eval_dir}/                    # 默认 eval/
├── {feature}-gen-001.md       # Generator Sprint 1 实现总结
├── {feature}-eval-001.md      # Evaluator Sprint 1 评估报告
├── {feature}-decision-001.md  # Decision Sprint 1 裁决记录
├── {feature}-gen-002.md
└── {feature}-eval-002.md
```

### 3.9 与 Claude Code 的对比

在 1.4 节中，我们从 Harness 机制层面分析了 Claude Code 与 TRAE Work 的差异。这里从**架构设计决策**的角度，对比两者的编排实现路径。

#### 3.9.1 Orchestrator：内置 vs 拼装

| 方面 | Claude Code | TRAE Work（我们的实现） |
|------|-------------|----------------------|
| **Orchestrator 来源** | 平台内置，代码级实现 | 拼装式：SPEC + Skills + Rules + Tasks + SubAgent + 人类触发 |
| **任务路由** | 自动根据任务类型路由到对应角色 | 人类通过 `/spec` 命令触发，tasks.md 标记驱动角色切换 |
| **对抗循环** | 内置 Adversarial verification 模式，自动循环 | tasks.md 中 [GENERATOR]/[EVALUATOR]/[DECISION] 标记驱动，File System 作为状态总线 |
| **循环终止** | Orchestrator 自动判断 | Decision 角色模拟：pass → 下一 Sprint，escalate → 人类介入 |
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

### 4.1 SPEC 模板

#### spec.md 模板（由 Planner 生成空模板，主Agent 运行时填充）

**重要变更（v3.0）**：Planner 不再填充 spec.md 的具体内容。Planner 只生成空模板（结构框架），所有 "{...}" 占位符由主Agent 运行时推理填充。

```markdown
# {Feature Name} — 产品规格说明

> 本模板由 Planner 生成。主Agent 在运行时根据当前 Sprint 上下文推理填充此模板。

## 产品概述
{主Agent 填充：1-2 段描述产品目标}

## 技术栈
{主Agent 填充：根据项目实际情况}

## Sprint 分解
{主Agent 填充：从全局 Sprint 文档中提取当前 Sprint 的详细信息}

### Sprint N: {Sprint 名称}
- **目标**: {主Agent 填充}
- **验收标准**:
  1. {主Agent 填充}
  2. {主Agent 填充}
- **预估复杂度**: {主Agent 填充}
- **依赖**: {主Agent 填充}

## 非功能性需求
{主Agent 填充：响应时间、并发数、覆盖率等量化指标}

## 开放问题
{主Agent 填充：需要澄清的模糊点}
```

#### tasks-pattern.md（编排模式参考）

tasks-pattern.md 不是预生成的 tasks.md。它是**编排模式参考**——云端 Agent 启动时读取此文件，理解 Harness 编排模式，然后结合 spec.md 的 Sprint 分解**动态生成**实际的 tasks.md。

```markdown
# Harness 编排模式参考

> 云端 Agent 启动时读取此文件，理解对抗编排模式，动态生成 tasks.md。
> 不要直接使用此文件作为 tasks.md——它需要根据 spec.md 的实际 Sprint 填充。

## 四角色编排模式

每个 Sprint 遵循以下流程：

[Sprint Start]
      ↓
[GENERATOR] → 提出 Sprint Contract 草案
      ↓
[EVALUATOR] → 审查 Contract（批准后才可编码）
      ↓
[GENERATOR] → 按 Contract 实现（TDD）
      ↓
[GENERATOR] → 实现总结 → eval/{feature}-gen-{N}.md
      ↓
[EVALUATOR] → 评估验证 → eval/{feature}-eval-{N}.md
      ↓
[DECISION]  → 读取两份报告 → 裁决
      ↓
  pass     → 进入下一 Sprint
  retry    → 回到 [GENERATOR]，附带 Decision 的 retry_focus
  escalate → 暂停，请求人类裁决

## tasks.md 生成规则

云端 Agent 生成 tasks.md 时必须遵循以下规则：
1. 读取 spec.md 的 Sprint 分解，为每个 Sprint 生成一个循环块
2. 每个 Sprint 块包含 6 个步骤：GENERATOR(Contract) → EVALUATOR(Contract审查) → GENERATOR(实现) → GENERATOR(总结) → EVALUATOR(评估) → DECISION(裁决)
3. 每个步骤标注角色标记：[GENERATOR]、[EVALUATOR]、[DECISION]
4. 角色标记后注明：加载对应 Skill，使用 SubAgent 独立上下文
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
  当需要将用户需求转化为产品规格说明、分解任务、定义验收标准时使用。
  定义 Planner 角色——需求分析、Sprint 级战略分解、规格输出。
  注意：Planner 只输出 spec.md + 更新全局任务表，不输出 tasks.md 和 checklist.md。
---
# Planner 角色规范

## 职责
将 1-4 句话的用户需求扩展为完整的产品规格说明，分解为可独立执行的 Sprint（战略级分解）。
**不负责生成 tasks.md**——tasks.md 由云端 Agent 运行时根据 tasks-pattern.md 动态生成。

## 行为准则
1. 只描述"做什么"和"为什么"，不描述"怎么做"
2. 每个 Sprint 必须有明确的、可机械检查的验收标准
3. 识别 Sprint 之间的依赖关系，标注强依赖（必须串行）和弱依赖（可并行）
4. 验收标准使用确定性语言，禁止"应该""尽量""可能"
5. 非功能性需求必须包含量化指标（响应时间、并发数、覆盖率等）
6. Sprint 粒度适中：每个 Sprint 的工作量应该在 1-3 个 SubAgent 会话内完成

## 输出格式
- 输出到 .trae/specs/{feature}/spec.md
- 更新 global_task_board.json（如果存在）
- 不输出 tasks.md 和 checklist.md
- 必须包含"产品概述""技术栈""Sprint 分解""非功能性需求""开放问题"

## 与云端 Agent 的契约
spec.md 必须包含足够的信息让云端 Agent 生成 tasks.md：
- 每个 Sprint 的目标、验收标准、依赖关系
- 技术栈和架构约束
- 非功能性需求（量化指标）
云端 Agent 启动后读取 spec.md + tasks-pattern.md，按照 Harness 编排模式动态生成 tasks.md。
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
根据 Planner 的规格说明和 Evaluator 认可的 Sprint Contract，按 Sprint 实现功能。

## 行为准则
1. 必须先读取 .trae/specs/{feature}/ 下的所有文档
2. 严格遵循 TDD：先写测试 → 确认测试失败 → 再写实现
3. 每次代码改动后立即运行测试，确认全部通过
4. 完成一个 Sprint 后立即 git commit，commit message 格式: "feat({scope}): {描述}"
5. 将实现总结写入 eval/{feature}-gen-{sprint}.md
6. 禁止评价自己的代码好坏
7. 禁止修改 SPEC 文档或验收标准
8. 禁止跳过测试直接写实现

## 实现总结格式
### Sprint {N}: {Sprint 名称}
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
1. 必须实际启动应用并通过浏览器测试，不能仅凭代码审查判断
2. 必须截图留证
3. 不能"放水"——不确定时往低打分
4. 评估报告必须写入 eval/{feature}-eval-{sprint}.md
5. 评估报告必须包含：通过/失败状态、各维度分数、具体问题描述、修复建议
6. 如果失败，必须列出可操作的修复步骤

## 评估报告格式
### Sprint {N}: {Sprint 名称}
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

#### 项目级规则

文件路径：`.trae/rules/project_rules.md`

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
- eval/ — 评估报告（Generator 和 Evaluator 写入）
- .trae/specs/ — SPEC 文档
- .trae/contracts/ — Sprint Contract

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
- package.json（除非 Sprint Contract 明确授权）
```

#### 按路径生效的规则

文件路径：`.trae/rules/api.md`

```markdown
---
paths:
  - src/api/**
  - src/services/**
---
# API 层规则

## 强制约束
- 所有 API 路由必须有输入验证
- 所有 API 响应必须包含统一的错误格式
- 数据库查询必须使用参数化查询，禁止字符串拼接
- 每个 API 端点必须有对应的集成测试

## 禁止
- 禁止在路由处理函数中直接操作数据库（必须通过 Service 层）
- 禁止返回原始数据库错误给客户端
```

### 4.4 Sprint Contract 流程

**完整生命周期（9 步）**：

| 步骤 | 角色 | 输入 | 输出 | 说明 |
|------|------|------|------|------|
| 1 | Planner | 用户需求 | spec.md（Sprint 级战略分解） | SPEC 暂停确认阶段 |
| 2 | 云端 Agent | spec.md + tasks-pattern.md | tasks.md（对抗循环编排） | 动态生成任务列表 |
| 3 | Generator | spec.md, tasks.md | Sprint Contract 草案 | 提出本轮构建内容 |
| 4 | Evaluator | Contract 草案 | 审查意见 | 最多 3 轮迭代 |
| 5 | 双方 | 审查意见 | 达成一致的 Contract | 写入 .trae/contracts/ |
| 6 | Generator | Contract | 代码实现 + 测试 | TDD 驱动 |
| 7 | Generator | 代码 | 自检 + git commit | 实现总结写入 eval/ |
| 8 | Evaluator | 代码 + Contract | 评估报告 | 测试 + 浏览器验证 |
| 9 | Decision | 两份报告 | pass/retry/escalate | 裁决 → 下一 Sprint 或重试 |
| 10 | Evaluator | 全部 Sprint | 最终验收报告 | 端到端测试 |

**Sprint Contract 文件模板**：

```markdown
# Sprint {N} Contract — {Feature Name}

## 本轮目标
{一句话描述}

## 实现范围
### 新增文件
- {文件路径} — {用途}

### 修改文件
- {文件路径} — {修改内容}

## 验收标准
1. {可机械检查的条件 1}
2. {可机械检查的条件 2}
3. {可机械检查的条件 3}

## 依赖
- {依赖的 Sprint 或外部条件}

## 预估风险
- {潜在风险点}

---

## Evaluator 审查（由 Evaluator 填写）
- 审查状态: {同意 / 需修改}
- 修改意见: {如有}
```

### 4.5 SubAgent 配置模板

#### Generator SubAgent

文件路径：`.trae/agents/generator.md`

```markdown
# Generator SubAgent

## 角色
你是一个专注于代码实现的 Generator。你负责按照 SPEC 文档和 Sprint Contract 编写代码和测试，不负责评估自己的代码质量。

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
- .trae/specs/
- .trae/contracts/
- .trae/rules/
- .trae/skills/
- package.json（除非 Sprint Contract 明确授权）
- .env 文件

## 行为规则
1. 读取 .trae/specs/{feature}/ 下的所有文档
2. 读取 .trae/contracts/{feature}/sprint-{n}.md 获取当前 Sprint Contract
3. 严格遵循 TDD
4. 完成后写入 eval/{feature}-gen-{n}.md
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
- Playwright MCP: 浏览器功能验证

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
1. 读取 .trae/contracts/{feature}/sprint-{n}.md 获取验收标准
2. 读取 eval/{feature}-gen-{n}.md 了解实现内容
3. 必须实际启动应用并通过浏览器测试
4. 按四维评分标准打分
5. 写入 eval/{feature}-eval-{n}.md
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
- .trae/contracts/（Sprint Contract）
- .trae/specs/（产品规格说明）

### 允许写入
- eval/（仅 xxx-decision-N.md 裁决文件）

### 禁止修改
- src/
- tests/
- .trae/
- 任何代码文件

## 裁决规则
- pass: 两份报告无实质性分歧，Evaluator 评分通过 → 进入下一 Sprint
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

Planner 接收用户需求，输出 `spec.md`（Sprint 级战略分解）。将需求拆分为 5 个 Sprint：

| Sprint | 名称 | 内容 | 预估复杂度 | 依赖 |
|--------|------|------|-----------|------|
| 1 | 项目脚手架 + 数据库 | FastAPI 项目结构、SQLite 表定义、数据库迁移 | 低 | 无 |
| 2 | 看板 CRUD API | 看板列的创建、读取、更新、删除 | 中 | Sprint 1 |
| 3 | 任务卡片 CRUD API | 任务卡片的创建、读取、更新、删除、移动 | 中 | Sprint 2 |
| 4 | React 前端看板 UI | 看板页面、列组件、卡片组件、状态管理 | 中 | Sprint 3 |
| 5 | 拖拽交互 + 端到端 | 拖拽移动卡片、乐观更新、E2E 测试 | 高 | Sprint 4 |

Planner 输出 spec.md 后，人类确认。确认后，云端 Agent 启动，读取 spec.md + tasks-pattern.md，动态生成 tasks.md（包含 [GENERATOR]/[EVALUATOR]/[DECISION] 标记的对抗循环步骤）。

### 5.3 Phase 2: 执行（Generator 执行 Sprint 1-N）

以 Sprint 1 为例，展示完整流程：

**Sprint Contract 协商**：

Generator 读取 `spec.md` 和 `tasks.md`，提出 Sprint 1 的 Contract 草案。Evaluator 审查后提出修改意见：增加 Alembic 迁移脚本要求、增加数据库连接错误处理。双方达成一致后，Generator 开始编码。

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
11. `git add` + `git commit -m "feat(kanban): Sprint 1 — 项目脚手架 + 数据库模型"`

### 5.4 Phase 3: 评估（Evaluator 执行验证）

Evaluator 启动应用，通过浏览器和 API 测试验证 Sprint 1 的输出：

**评估报告**（`eval/kanban-eval-001.md`）：

```markdown
### Sprint 1: 项目脚手架 + 数据库
- 状态: PASS
- 功能性: 5 — 数据库表创建正确，API 启动正常
- 工艺质量: 4 — 代码结构清晰，缺少数据库连接池配置
- 完整性: 5 — 测试覆盖全部模型和连接逻辑
- 用户体验: N/A（本 Sprint 无 UI）
- 总分: 14/15（排除 N/A 维度）
- 截图: eval/screenshots/sprint-1-api-health.png
- 问题列表: 无阻塞性问题
- 修复建议: 建议在 Sprint 2 中增加数据库连接池配置
```

**模拟一次"失败"场景**（Sprint 4）：

```markdown
### Sprint 4: React 前端看板 UI
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
- 如果通过 → 进入下一 Sprint
- 如果失败但问题明确 → Decision 指定 retry_focus，Generator 重试
- 如果存在分歧或无法裁决 → Decision 标记 escalate，暂停执行，人类介入裁决

Generator 收到失败报告后，逐一修复问题，重新提交。Evaluator 再次验证，Decision 裁决 → pass，进入下一 Sprint。

### 5.5 Phase 4: 迭代与验收

全部 5 个 Sprint 完成后，Evaluator 进行端到端验收：

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
| 规划 | Planner | 10% | spec.md（Sprint 级战略分解） |
| 编排 | 云端 Agent | 5% | tasks.md（动态生成，对抗循环步骤） |
| 执行 Sprint 1-5 | Generator | 45% | 代码、测试、git 提交历史 |
| 评估 Sprint 1-5 | Evaluator | 30% | 评估报告、截图、修复反馈 |
| 裁决 Sprint 1-5 | Decision | 5% | pass/retry/escalate 裁决记录 |
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
| Sprint Contract | Sprint Contract | Generator 和 Evaluator 在 Sprint 开始前达成的验收协议 |
| 引导循环 | Steering Loop | 人类观察 Agent 失败模式 → 改进 Harness 组件 → Agent 不再重复同样错误 |
| 质量左移 | Keep Quality Left | 将质量检查尽可能前置到变更生命周期早期阶段 |

### 附录 B：参考资源

- [Mitchell Hashimoto — My AI Adoption Journey](https://mitchellh.com/writing/my-ai-adoption-journey)
- [OpenAI — Harness Engineering](https://openai.com/index/harness-engineering/)
- [Anthropic — Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-for-long-running-application-development)
- [Martin Fowler — Harness Engineering for GenAI](https://martinfowler.com/articles/harness-engineering-genai/)
- [Martin Fowler — Blending AI and Human Judgment](https://martinfowler.com/articles/blending-ai-human-judgment/)
- [LangChain — The Anatomy of an Agent Harness](https://blog.langchain.dev/anatomy-of-an-agent-harness/)
- [TRAE 官方文档 — SPEC 工作流](https://docs.trae.cn/solo/spec-and-plan)
- [TRAE 官方社区 — SubAgent 多线程打工](https://forum.trae.cn/t/topic/1189)
- [TRAE 官方社区 — SOLO 模式多任务并行零冲突](https://forum.trae.cn/t/topic/1139)
- [TRAE 官方社区 — Agent 概念速览](https://forum.trae.cn/t/topic/2702)
- [Claude Code — Dynamic Workflows 官方文档](https://docs.anthropic.com/en/docs/claude-code/workflows)
- [Qiita — Claude Code で Planner/Generator/Evaluator を .claude/agents/ で実装](https://qiita.com/kzk_maeda/items/5c3a4e2f8e1a7b9c0d6f)

### 附录 C：TRAE Work 配置速查表

| 配置文件 | 路径 | 作用 |
|----------|------|------|
| 项目规则 | `.trae/rules/project_rules.md` | 全团队共享的编码规范和安全策略 |
| 个人规则 | `.trae/rules/user_rules.md` | 个人偏好 |
| 路径规则 | `.trae/rules/{name}.md` | 对特定目录生效的规则 |
| Planner Skill | `.trae/skills/planner-role/SKILL.md` | Planner 角色行为规范 |
| Generator Skill | `.trae/skills/generator-role/SKILL.md` | Generator 角色行为规范 |
| Evaluator Skill | `.trae/skills/evaluator-role/SKILL.md` | Evaluator 角色行为规范 |
| Generator Agent | `.trae/agents/generator.md` | Generator SubAgent 配置 |
| Evaluator Agent | `.trae/agents/evaluator.md` | Evaluator SubAgent 配置 |
| Decision Agent | `.trae/agents/decision.md` | Decision SubAgent 配置（中立裁决者） |
| SPEC 规格 | `.trae/specs/{feature}/spec.md` | Planner 输出的产品规格（Sprint 级分解） |
| 编排模式 | `.trae/specs/{feature}/tasks-pattern.md` | 编排模式参考（云端 Agent 据此生成 tasks.md） |
| Sprint Contract | `.trae/contracts/{feature}/sprint-{n}.md` | Sprint N 的验收协议 |
| 评估报告 | `eval/{feature}-eval-{n}.md` | Evaluator 对 Sprint N 的评估 |
| 实现总结 | `eval/{feature}-gen-{n}.md` | Generator 对 Sprint N 的实现总结 |
| 裁决记录 | `eval/{feature}-decision-{n}.md` | Decision 对 Sprint N 的裁决（pass/retry/escalate） |
| 持久记忆 | `.trae/memory/{feature}.md` | 跨会话的持续学习记录 |