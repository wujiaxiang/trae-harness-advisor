# 会话上下文与设计决策记录

> **版本**: v4.5  
> **日期**: 2026-07-02  
> **变更**: v2.0 决策 6/7；v3.x 三层推理与 RULE.md 钩子；v4.0 Milestone/Stage/Task 重构、Stage 级三件套、stage-executor、两类验收、state-board v2；v4.1 决策 13；v4.2 决策 14（Decision 独立、retry 闭环、三件套只留 .trae/specs）；v4.3 决策 15（验收标准来源澄清 + 可选 codraft 共识子阶段）；v4.4 决策 16（动态编排=图灵完备、子代理工具实测、方案1 MCP 代行）；v4.5 决策 17（多模式编排框架——6 种编排模式全做：新增 Classifier/Synthesizer/Selector 3 角色 + 4 pattern playbook + Stage 层 pattern 字段 + generate_patterns 开关）
> **目标读者**: LLM/Agent——读完后能理解本项目的来龙去脉、关键决策及其理由，从而在现有基础上继续迭代优化  
> **关联文档**: `trae-harness-advisor/resources/harness-engineering-on-trae-work.md`（方法论与架构主文档）  
> **过程档案**: `archive/harness-engineering-on-trae-work-plan.md`（v1.0 编写计划）、`archive/supplement-and-alignment-plan.md`（v2.0 补充对齐计划）
> **核心概念定义**: 以 `trae-harness-advisor/resources/harness-engineering-on-trae-work.md` 第零部分为准；后续实现必须遵循 Milestone / Stage / Task 术语与两类验收分工。

---

## 目录

1. [项目起源](#项目起源)
2. [关键发现与纠正](#关键发现与纠正)
3. [设计决策记录](#设计决策记录)
4. [外部参考资源](#外部参考资源)
5. [已知限制与待解决问题](#已知限制与待解决问题)
6. [未来迭代方向](#未来迭代方向)

---

## 项目起源

### 初始问题

用户的核心诉求：**在 TRAE Work 免费版的能力范围内，实现 Harness Engineering 方法论中的 Planner-Generator-Evaluator（PGE）多智能体对抗架构**。

探索过程分为以下阶段：

### 阶段 1：TRAE Work 能否被外部编排？

**问题**: TRAE Work 是否支持无头模式（headless mode）或 CLI 方式，让上游智能体把任务派发过来执行？

**结论**: **不支持**。TRAE Work 是一个终端执行单元，任务必须由人类手动触发（通过 `/spec` 命令等），无法通过外部 API 或 CLI 进行编排。这意味着 TRAE Work 不能像 GitHub Actions 或 Jenkins 那样被编程化调度。

**影响**: 排除了"TRAE CLI + Docker 容器 + 外部编排脚本"的方案。所有编排逻辑必须在 TRAE Work 内部通过 SPEC 工作流、Skills、Rules 和 SubAgent 实现。

### 阶段 2：方法论调研

调研了以下业界 Harness Engineering 实践（详见主文档第一部分）：

| 来源 | 核心贡献 | 关键引用 |
|------|---------|---------|
| Mitchell Hashimoto | 6 阶段 AI 采用框架，阶段 5 = "工程化 Harness" | 《My AI Adoption Journey》 |
| OpenAI | 零人类代码行、100 万行生成代码、1500 个 PR | Context Engineering + Architectural Constraints + Garbage Collection |
| Anthropic | Pattern A（Initializer + Coding Agent）和 Pattern B（Planner-Generator-Evaluator） | 《Effective harnesses for long-running agents》 |
| Martin Fowler | Feedforward vs Feedback、Computational vs Inferential、3 种 Harness 类型 | 两篇 Harness Engineering 文章 |
| LangChain | Agent = Model + Harness | 《The Anatomy of an Agent Harness》 |
| Birgitta Böckeler | Keep Quality Left 理念 | Martin Fowler 博客分析 |

### 阶段 3：TRAE Work 能力映射

将 Harness Engineering 五层模型映射到 TRAE Work 平台能力：

| Harness 层 | 用途 | TRAE Work 实现 |
|-----------|------|---------------|
| L0: Context | 上下文注入 | Rules、Skills、AGENTS.md |
| L1: Execution | 代码执行 | 文件系统、Bash、Sandbox、MCP |
| L2: Orchestration | 任务编排 | SPEC 工作流、SubAgent 调度 |
| L3: Verification | 质量验证 | MCP（Playwright、Linter）、自动化测试 |
| L4: Steering | 人类反馈 | 人类审查 SPEC 暂停确认 |

### 阶段 4：选型结论

最终方案：**TRAE Work + Skills（角色定义）+ Rules（护栏约束）+ SPEC 工作流（Planner 角色）+ SubAgent（Generator/Evaluator 独立上下文）**

### 阶段 5：文档迭代（v1.0 → v2.0）

本项目经历了两次主要文档迭代：

- **v1.0**（2026-06-28）：初始架构设计，编写计划见 `archive/harness-engineering-on-trae-work-plan.md`。产出三角色 PGE 架构、5 部分主文档、9 个模板文件、HTML 报告
- **v2.0**（2026-06-29）：基于 Claude Code Workflow 调研进行补充对齐，变更计划见 `archive/supplement-and-alignment-plan.md`。新增 1.4 Claude Code 对标分析、3.2 四角色架构（加入 Decision）、3.9 与 Claude Code 对比、Planner 职责收窄、tasks.md 动态生成
- 2026-06-29: 本文档 `conversation-context-and-design-decisions.md` 按时间线串联所有决策和背景，过程文档已归档到 `archive/` 目录，供后续 Agent 了解迭代决策过程。

---

## 关键发现与纠正

### 发现 1：SubAgent 能力（重要纠正）

**初始错误判断**: 在对话早期，我断言 TRAE Work 的 tasks.md 执行时不能使用 SubAgent，认为 Generator 和 Evaluator 必须在同一上下文中运行。

**用户纠正**: 用户分享了实际 TRAE Work Agent 的回复，证明 TRAE Work **确实有 Task 工具**，可以 spawn `general_purpose_task` 和 `search` 两种 SubAgent，每个 SubAgent 拥有独立上下文窗口，最多支持 5 个并行执行。

**验证**: 通过查阅 TRAE 官方论坛（topic/1139），确认了 SubAgent 在 SOLO 模式下的调度能力。

**影响**: 这个发现是架构设计的转折点——它使得 Generator 和 Evaluator 可以运行在独立 SubAgent 中，真正实现了 Anthropic Pattern B 的"上下文隔离"要求。如果没有这个能力，Generator 和 Evaluator 共用上下文会导致 Context Rot 和"自己评自己"的 bias。

### 发现 2：SPEC 工作流的 Planner 角色

TRAE Work 的 SPEC 工作流有三个关键文件：
- `spec.md`：产品规格说明，由 AI 在暂停阶段生成，用户确认后固化
- `tasks.md`：任务分解，AI 按步骤执行，可在任务间暂停
- `checklist.md`：AI 暂停确认的检查清单

**关键设计决策**: 将 Planner 角色映射到 SPEC 工作流的"暂停确认阶段"——Planner 生成 spec.md 后，用户审查确认，然后云端 Agent 根据 tasks-pattern.md 动态生成 tasks.md，其中的 Generator/Evaluator/Decision 标记引导后续 SubAgent 调度。

### 发现 3：Claude Code Workflow 对标（2026-06-29）

在 2026 年 6 月 29 日的调研中，发现 Claude Code 已通过两种机制将 Harness Engineering 内化为平台基础能力：

**Claude Code 的静态 Harness（`.claude/agents/`）**：
- 通过 `.claude/agents/` 目录下的 Markdown 文件静态定义角色（Planner、Generator、Evaluator）
- 内置 Orchestrator 自动根据任务类型路由到对应角色
- 这与我们的 `.trae/agents/` 设计高度相似——因为两者都源自 Anthropic 的 Pattern B

**Claude Code 的 Dynamic Workflows**：
- 2026 年 6 月发布，运行时自生成 JavaScript 编排脚本
- 提供 6 种内置编排模式：Classify-and-act、Fan-out-and-synthesize、Adversarial verification、Generate-and-filter、Tournament、Loop until done
- Adversarial verification 就是 PGE 架构的核心模式

**关键洞察**：
- Claude Code 的 Orchestrator 是**内置的、全自动的**——用户只需描述需求，Orchestrator 自动完成从角色路由到对抗循环的全过程
- TRAE Work 没有内置 Orchestrator，但我们通过组合 SPEC + Skills + Rules + SubAgent + Decision **拼装了一个 Orchestrator**
- 方法论效果可以追齐（角色分离、上下文隔离、对抗验证），但自动化程度无法追齐（需要人类手动触发 SPEC）
- 类比：Claude Code 是"自动挡汽车"，我们是在"手动挡汽车"上安装了"辅助驾驶系统"

**影响**：这个发现影响了两大设计决策——引入 Decision 角色作为 Orchestrator 代理（决策 6），以及收窄 Planner 职责到战略分解（决策 7）。

---

## 设计决策记录

> 本节按决策发生的时间顺序编号（决策 1→17）。**决策 1–7 为早期（v1.0–v3.0 前）方案，部分术语（Sprint / Feature / tasks-pattern.md / global_task_board.json / `.trae/contracts`）已在决策 11（v4.0 三级模型）后被取代**，保留原文仅作演进背景；当前术语一律以主文档第零部分为准。

---

### 决策 1：为什么不用 TRAE CLI + Docker？

**方案**: 在 Docker 容器中运行 TRAE CLI，接收外部指令，完成后销毁容器。

**否决理由**: 
- TRAE Work 免费版不提供 CLI 的远程调度 API
- 需要额外搭建编排层（消息队列、状态管理）
- 增加了运维复杂度和成本
- 与 TRAE Work 的云端执行模型不兼容

---

### 决策 2：为什么选择 SPEC 工作流作为 Planner 角色？

**理由**:
- SPEC 是 TRAE Work 原生支持的规划机制，无需额外开发
- 暂停确认阶段天然提供了"人类审查 Planner 输出"的 Steering 机制
- spec.md 固化后，后续 tasks.md 步骤可以引用固定的规格文档，避免需求漂移

---

### 决策 3：为什么 Generator 和 Evaluator 必须用独立 SubAgent？

**理由**:
- 模型是"病态乐观主义者"（pathological optimist），无法有效自我批判——同一上下文中的 Generator 评估自己的代码会给出虚高分数
- 上下文腐化（Context Rot）——长对话中模型性能下降，注意力分散
- 路径白名单隔离——Generator SubAgent 只能修改 src/ 和 tests/，Evaluator SubAgent 只能写入 eval/，防止误修改

---

### 决策 4：Sprint Contract 的定位

Sprint Contract 是 Generator 和 Evaluator 之间的"对抗协议"：
- Generator 提出"我打算实现什么、怎么实现、验收标准是什么"
- Evaluator 审查"这个计划是否合理、验收标准是否可测"
- 双方达成一致后，Generator 按 Contract 实现，Evaluator 按 Contract 验收
- 这解决了"需求和实现不一致"的经典问题——在代码写之前就对齐预期

---

### 决策 5：全局任务看板（global_task_board.json）

**目的**: 解决 TRAE Work 会话之间缺乏持久状态的问题。每个 SPEC session 独立运行，全局任务看板提供跨 session 的任务状态追踪。

**设计**: 简单 JSON 文件，记录每个 Feature 的 SPEC 路径、Sprint 状态、评估结果。Generator 和 Evaluator 的 SubAgent 可以通过文件系统读写这个看板。

---

### 决策 6：引入 Decision 角色作为中立裁决者（2026-06-29）

**背景**: 在三角色架构中，Generator 和 Evaluator 之间的分歧没有自动解决机制。Evaluator 给出 FAIL 后，Generator 需要修改，但如果没有第三方裁决，可能出现 Generator 过度修改（引入新问题）或双方陷入僵局（反复拉扯）。

**决策**: 在三角色基础上新增第四角色——Decision（裁决者），充当 Orchestrator 代理。

**Decision 的设计约束**:
- 只读不写：只能读取 Generator 总结和 Evaluator 报告，不能修改任何代码
- 三种裁决：pass（通过，进入下一 Sprint）、retry（重试，附带聚焦建议）、escalate（升级，人类介入）
- 中立性：不偏向任何一方，引用证据做裁决
- 不确定时 escalate：不强行裁决，承认不确定性

**Decision 是 Orchestrator 代理，不是 Orchestrator**：TRAE Work 没有内置 Orchestrator，Decision 通过"只读两份报告 → 输出裁决"的方式模拟 Orchestrator 的决策功能。正常情况（pass/retry）自动处理，罕见情况（escalate）升级给人类。

---

### 决策 7：Planner 职责收窄为战略分解（2026-06-29）

**背景**: 在 v1.0 设计中，Planner 输出 spec.md + tasks.md + checklist.md 三个文件。但在实际设计中，我们发现 tasks.md 的生成属于**战术编排**——它需要根据具体的 Harness 编排模式（对抗循环、角色切换、SubAgent 调度）来生成，这是编排引擎的职责，不是 Planner 的职责。

**决策**: Planner 只输出 spec.md（Sprint 级战略分解），不输出 tasks.md 和 checklist.md。

**tasks.md 的生成方式**:
- 项目中预置 tasks-pattern.md（编排模式参考），定义了对抗循环的六步流程
- 云端 Agent 启动时，读取 spec.md（Sprint 分解）+ tasks-pattern.md（编排模式），**动态生成** tasks.md
- 这确保了：Planner 聚焦战略，编排引擎（云端 Agent）聚焦战术，职责边界清晰

**Planner 与云端 Agent 的契约**:
- spec.md 必须包含足够的信息让云端 Agent 生成 tasks.md
- 每个 Sprint 的目标、验收标准、依赖关系
- 技术栈和架构约束
- 非功能性需求（量化指标）

---

### 决策 8：三层推理流程重构（v3.0）

**日期**：2026-06-29

**背景**：用户指出当前架构存在三个问题：
1. `.trae/` 目录写死，业务文档（spec、contracts）不应该绑定 IDE 私有目录
2. Planner 直接生成具体 spec.md 内容，但 Planner 不知道运行时上下文
3. 角色之间推理能力不清晰——专家 Skill、Planner、主Agent、SubAgent 的推理边界模糊

**决策**：重构为三层推理流程 + 目录解耦

**三层推理模型**：
- **第一层（专家 Skill）**：初始化 Harness 基础设施，根据技术栈定制规范。输出 Skills + Agents + Rules + tasks-pattern.md + sprint-N.md 模板。不生成 spec.md（因为不知道业务需求）。
- **第二层（Planner）**：理解业务需求，拆分 Sprint 大方向。输出 sprint-plan.md（全局 Sprint 规划）+ spec.md 空模板（只有结构框架，不填充具体内容）。因为 Planner 知道业务全貌，但不知道具体 Sprint 执行时的上下文。
- **第三层（主Agent）**：用户指定 Sprint → 读取 spec.md 模板 + 全局 Sprint 文档 → 推理填充 spec.md → 生成 tasks.md → 调度 SubAgent 执行对抗循环。
- **执行层（Generator/Evaluator/Decision）**：按规范执行对抗循环。

**核心理由**：
- Planner 完成后，用户可能过几天才执行 Sprint 3，期间项目上下文可能变化，spec.md 由主Agent 运行时填充更灵活
- 不需要 git 同步 spec.md 内容（因为被主Agent 运行时填充）
- 每层都有自主推理能力，上层规范约束下层

**三层约束链**：
```
专家 Skill 生成的规范
    ├── planner-role Skill → 约束 Planner 的行为
    ├── tasks-pattern.md → 约束主Agent 的行为
    ├── generator-role Skill → 约束 Generator 的行为
    ├── evaluator-role Skill → 约束 Evaluator 的行为
    └── decision Agent 配置 → 约束 Decision 的行为
```

---

### 决策 9：目录解耦——默认不绑定 `.trae/`

**日期**：2026-06-29

**背景**：之前的架构中所有输出路径都写死在 `.trae/` 目录下（`.trae/specs/`、`.trae/contracts/`）。但 `.trae/` 是 IDE 私有目录，业务文档不应该放在这里同步到 git。

**决策**：实现目录配置化，所有路径支持用户自定义，默认不绑定 `.trae/`

**新增配置变量**：
- `skill_dir`：默认 `.trae/skills/`（静态配置，git 可同步）
- `agent_dir`：默认 `.trae/agents/`（静态配置，git 可同步）
- `rules_dir`：默认 `.trae/rules/`（静态配置，git 可同步）
- `spec_dir`：默认 `harness-specs/{feature}/`（业务文档，不绑定 `.trae`）
- `contract_dir`：默认 `harness-contracts/{feature}/`（业务文档，不绑定 `.trae`）
- `eval_dir`：默认 `eval/`（运行时输出，保持）

**设计原则**：
- `.trae/` 只放静态 Harness 配置（Skills、Agents、Rules）——这些是配置，git 可同步
- `harness-specs/` 和 `harness-contracts/` 放业务文档——用户可选择是否 git 同步
- `eval/` 放运行时输出——用户通常 `.gitignore`
- 不破坏向后兼容：用户仍可指定 `spec_dir: .trae/specs/{feature}/` 恢复旧行为

**文件变更**：所有模板和文档中的路径引用全面更新为变量形式，删除硬编码的 `.trae/specs/`、`.trae/contracts/` 路径

---

### 决策 10：TRAE Work 兼容性修正——RULE.md 钩子方案 + Agent 可选保留（v3.1，2026-06-29）

**背景**：在 v3.0 完成后，调研发现 TRAE Work 云端对 `.trae/` 目录的支持存在严重限制：
- `.trae/rules/`：**完全不支持**——TRAE Work 规则体系是 UI 驱动的全局规则，与 IDE 的文件驱动体系完全不同
- `.trae/agents/`：**当前不支持**——Agent 定义只能通过 UI 创建，但未来可能支持
- `.trae/skills/`：**唯一云端自动加载的通道**——AI 自动按需匹配加载

**决策**：

**1. RULE.md 钩子方案**：删除 `.trae/rules/`，改为项目根目录 `RULE.md` + 钩子规则。用户在 TRAE Work「设置 > 规则」中创建一条云端规则：

```
在开始执行任何任务之前，必须先读取当前项目根目录的 RULE.md 文件，将其内容作为当前项目的编码规范、约束条件和行为准则。如果 RULE.md 不存在，则跳过此步骤。
```

这是一次性操作。之后所有云端 Task 启动时自动加载各项目的 `RULE.md`，实现项目级规范自治。

**2. Agent 角色行为内嵌到 Skill**：将 Generator 的工具集和路径白名单合并到 `generator-role/SKILL.md`，将 Evaluator 的工具集、路径白名单和 Decision 裁决者角色定义合并到 `evaluator-role/SKILL.md`。这样在当前 TRAE Work 不支持 `.trae/agents/` 的情况下，角色行为通过 Skill 自动加载，保证云端可用。

**3. Agent 配置文件保留为可选**：`agent_dir` 变量保留，默认 `.trae/agents/`，新增 `generate_agents` 布尔变量（默认 `false`）。专家 Skill 在问答中询问用户是否生成 Agent 配置文件。生成后 `deliverable-specs.md` 中 Agent 配置章节标注为"可选生成"。这样未来 TRAE Work 支持 `.trae/agents/` 时可直接使用。

**影响**：
- `rules_dir` 变量删除，`project_rules.md` 改为 `RULE.md`
- 交付物：核心 6 个文件（3 个 Skill + RULE.md + tasks-pattern.md + sprint-N.md）+ 1 段钩子规则文本（非文件）+ 可选 3 个 Agent 配置
- Generator 和 Evaluator Skill 内容大幅扩展（合并了 Agent 工具集和 Decision 角色）
- 主文档版本号：v3.0 → v3.1


### 决策 11：概念重构（Milestone/Stage/Task）v4.0

**日期**：2026-06-29

**背景**：v3.x 中“业务层级、执行批次、原生任务”的边界仍然容易混淆，历史术语还会让 Planner、云端父 Agent、SubAgent 的职责发生重叠。用户要求把层级定义锁定为可长期维护的三层模型，并消除旧命名造成的歧义。

**决策**：统一采用严格三级层次：
- **Milestone**：一次 Planner 对话覆盖的完整研发或验收过程，标注 `kind: development | verification`，物理载体为 `harness/milestones/{milestone}/` 与 `state-board.json` 中的一条记录。
- **Stage**：Milestone 下一个可独立验收的增量，允许声明 `depends_on`，可部分并发，通常对应一次云端对话与一次 `/spec` 实例。
- **Task**：Stage 内 `tasks.md` 的一个 TRAE Work 原生执行步骤。

**理由**：该定义把“规划范围”“可验收增量”“平台执行步骤”拆开，避免把战略规划、运行时编排和底层 tasklist 混为一谈。Anthropic Pattern A 中的功能分解在本设计中对应 Stage 分解，后续引用时必须显式说明。

**影响**：后续文档、模板和 Skill 的正向表达均以主文档第零部分为唯一术语来源。历史决策记录保留原话，仅作为演进背景。

---

### 决策 12：SPEC 三件套下沉 Stage 层 + stage-executor + 两类验收分工 + 顺序模拟对抗 + state-board v2

**日期**：2026-06-29

**背景**：用户进一步澄清：Advisor 和 Planner 都不应预先生成业务内容；SPEC 三件套需要由执行当下的 Orchestrator 根据最新上下文推理生成。同时，TRAE Work 的 SubAgent 能力支持顺序执行，但不等价于真实自动控制流循环；旧状态文件也混合了定义与运行状态。

**决策**：
1. **SPEC 三件套下沉到 Stage 层**：`spec.md`、`tasks.md`、`checklist.md` 由 Orchestrator 在每个 Stage 的 `/spec` 对话中运行时创建，并持久化到 `harness/milestones/{milestone}/stages/{stage}/`。Advisor 只提供 `harness/templates/*.skeleton.md` 的结构骨架。
2. **新增 stage-executor playbook**：作为 Orchestrator 的单一拉起入口，确定性执行“读 board → 读 plan → 运行 /spec → 自检 → 顺序派发 G/E/D → 回写 board”。RULE.md 钩子只负责指向该 playbook。
3. **两类验收分工**：`checklist.md` 是底层机制，回答 tasklist 是否完成；Evaluator 是业务质量评估，作为 tasks.md 内的 `[EVALUATOR]` 步骤输出四维评分 `eval.md`。两者不互相替代。
4. **顺序模拟对抗**：同一 Stage 对话内按 Generator → Evaluator → Decision 顺序执行，最多 3 轮返工；超过上限或出现根本分歧时 escalate 给人类。
5. **state-board.json v2**：`milestone-plan.md` 只保存静态定义，`state-board.json` 是动态状态机唯一真值，记录 Stage 状态、轮次、最后裁决和产物路径。

**理由**：运行时生成三件套可以利用最新代码与上下文；stage-executor 降低手动拼装输入的脆弱性；两类验收拆分避免重复或错位；顺序模拟对抗符合 TRAE Work 当前能力边界；状态定义分离使跨 session 恢复更可靠。

**影响**：持久真值与消息总线统一落在 `harness/`；`.trae/specs/` 仅作为原生临时 scratch，不再承担持久消息传递。

---

### 决策 13：v4.1 健壮性与诚实性收尾

**日期**：2026-06-29

**背景**：v4.0 概念重构完成后，复盘出一批"待讨论项"（未验证平台假设、约束强度措辞、状态并发、复杂度、引用可信度）。本决策据用户反馈逐条落地。

**内容**：
1. **外部引用核实**：逐条 HTTP 核实参考来源。删除伪造链接（如 Qiita 哈希 URL 404）、修正失效链接（Anthropic/Fowler/LangChain），状态不确定者标"未核实"，加来源免责。
2. **`.trae/specs/` 降级为完全可弃**：不再依赖 `/spec` 产物路径；改为 tasklist 步骤让 subagent 主动把交付物写入 `harness/` 总线。
3. **Contract 简化**：废除 Generator↔Evaluator 多轮协商，改为 **Orchestrator 起 Stage 时一次标注关键 Contract 点**（目标/验收要点/边界）。删除 `max_contract_rounds`，问答从 13 题降为 12 题。
4. **board 写协议**：最小更新原则（每次只改当前 Stage 那条记录）→ git 合并不冲突；代码级冲突由人工依据 `depends_on` 在投递 Stage 时把关。明确"并发=人工多对话，非自动调度"。
5. **约束强度诚实化**：路径白名单、RULE.md 钩子、playbook、board 全部标注为"提示词级、best-effort、非沙箱强制"，需 CI/评审兜底。
6. **PoC 自检集 + 实例化环境**：新增 `poc/harness-selftest/`（测试套件）并在仓库**实例化** `.trae/skills/`+`RULE.md`+`harness/` 运行环境，喂给真机 TRAE Work 验证 AP1–AP9（Skill 自动加载、SubAgent 加载角色 Skill、上下文隔离、MCP、路径白名单、harness 总线写入、原生 checklist 语义、RULE.md 钩子、SubAgent 可并行可串行但无自动循环）。

**影响**：方法论主张更稳健、措辞更诚实；平台假设从"纸面"转为"可真机验证"。

---

### 决策 14：真机自检结果 + Decision 独立 + retry 闭环（v4.2）

**日期**：2026-06-29

**背景**：`poc/harness-selftest` 在真实 TRAE Work 云端跑通一轮（commit a6c5de1 + followup 55be15e）。结果：AP1/2/3/5/6/7/8 硬验证 PASS（自动加载、子代理加载角色 Skill、子代理间隔离、白名单拒绝越权、harness 总线、checklist 完成性、RULE.md 钩子）；AP9 串行+无自动循环已证、真并行待补；AP4 MCP 全平台未注册（连主 Agent 都无 mcp__ 工具）。followup 还诚实暴露：首轮 **[DECISION] 由主 Orchestrator 自己执行**且能看到双方摘要，非盲审。

**决策（用户拍板）**：
1. **Decision 独立**：把 Decision 从 evaluator-role 抽出为独立 `decision-role` Skill，作为**独立 SubAgent** 派发（与 G/E 上下文隔离，中立盲审）。**Orchestrator 只串联流程，不兼任任何角色**。核心 Skill 4→5、核心文件 10→11、模板 13→14。
2. **retry 闭环（新增 AP10）**：明确 Orchestrator 收到 `retry` 后可**编辑 tasks.md 追加返工任务 + 带 retry_focus 重新派发 Generator**（rounds+1），多轮返工靠手动重派（无自动 loop）。新增自检点 AP10 验证此能力。
3. **MCP**：AP4 FAIL 是平台未配置；用户可在 TRAE Work「MCP > 云端 > 创建」添加 MCP server（如 Playwright）后，按 `followup-prompt.md` 补证 SubAgent 是否继承 mcp__ 工具。
4. **三件套持久化收紧**：spec/tasks/checklist 是过程脚手架，只留 `.trae/specs/`（对话内可读、不入 harness、不进 git）；只有交付物 contract/gen/eval/decision + state-board 持久化到 `harness/`。验收标准在 contract.md，故三件套不持久化不影响 Evaluator/Decision 验收。board 的 `artifacts` 只记 contract/gen/eval/decision。

**影响**：中立裁决从"名义"变"真盲审"；retry 闭环明确为人工驱动的有限重派；建议按更新后的 `test-prompt.md` 重跑一次以确认 Decision 独立 + AP10 + AP9 真并行。

---

### 决策 15：验收标准来源澄清 + 可选 codraft 共识子阶段（v4.3）

**日期**：2026-06-29

**背景**：用户质疑"验收标准真的能让 Orchestrator(串联者)定吗?"——Orchestrator 没看代码，早期开发阶段的验收标准往往要"开发先写一版、测试 review 后再调"才能定清楚；而联调阶段(骨架与模块契约已定)验收标准又天然明确。

**决策**：
1. **澄清来源**：验收标准的"根"在 Planner 的 `milestone-plan.md`（每个 Stage 带"验收标准要点"），Orchestrator 只是据此 + 既定契约**誊写/收敛**成 contract.md，**不凭空发明**。联调/需求明确的 Stage 由此即可。
2. **新增 per-Stage `contract_mode`**（Planner 在 milestone-plan 标，默认 `planned`）：
   - `planned`：验收标准规划期已明确 → Orchestrator 直接写 contract.md，不加子阶段。
   - `codraft`（可选）：验收标准需先有草稿才能定（早期/探索性）→ 插入 **Contract 共识子阶段**：Generator 出草稿+提议标准 → Evaluator(测试视角)敲定标准写入 contract.md → 再进入正式 G→E→D 对抗。
3. 这把 v4.1 砍掉的"协商"以**可选、且基于真实草稿**的形式请回来，正好对应"开发写一版、测试 review 后调标准"。

**影响**：覆盖了"验收标准自顶向下(预定)"与"自底向上(涌现)"两类来源；联调走 planned、早期开发可选 codraft。改动 planner-role / stage-executor / 文档 / 自检计划。

---

### 决策 16：v4.3 真机重跑结论——动态编排=图灵完备 + 方案1（MCP 代行）（v4.4）

**日期**：2026-06-29

**背景**：v4.3 重跑（commit 21e4497）验证了 Decision 独立、retry 闭环、三件套→.trae/specs 全部成立；AP4 给出决定性结论：**即便配置 Playwright MCP，`mcp__*` 工具也只对主 Orchestrator 可见、不下发给 SubAgent**。同时用户提出一个重要洞察：Orchestrator 能运行时改 tasks.md，是否意味着图灵完备、可模拟真 PGE？

**结论与决策**：
1. **重要发现：动态编排 = 图灵完备执行底座（LLM 驱动）**。真机验证 Orchestrator 具备顺序/分支(读 verdict)/有界循环(retry 重派)/跳出(escalate)/**自修改 tasks.md**/持久状态(board+harness)，叠加子代理 **Shell(RunCommand)** 可跑任意程序 → 整体图灵完备。故**真正自适应的 PGE 流程可行**（据运行时证据动态重规划），不再只是静态脚本。注脚：控制是**推理级非计算级**（图灵完备≠可靠）、**有界**（受上下文/轮次，靠 board 外置状态、max_rounds/escalate 护栏）、**效果可追齐 Claude Code、确定性追不齐**。措辞："顺序模拟对抗" → "LLM 驱动的动态编排"。
2. **子代理工具能力实测**：17 个工具含 Web(WebSearch/WebFetch)+Shell(RunCommand 等)+文件操作，**唯缺 MCP**。
3. **方案1（采纳）**：`verification_mode=full` 的浏览器/MCP 验证改由**主 Orchestrator 代行**（它有 MCP），把截图/日志写入 `browser-check.md`，Evaluator 子代理 Read 后纳入四维评分；Evaluator 自身用 RunCommand 跑测试/Lint。无 MCP/浏览器环境则降级 `automated`。

**影响**：方法论从"静态模拟"升级为"动态自适应编排"的定位；解决了 AP4 带来的浏览器验证缺口；改动 evaluator-role / stage-executor / verification_mode 映射 / 文档。

**真机确认（commit f76f8fc）**：v4.4 综合自检（AP1–AP14，probe+adaptive 两 Stage）**13/14 PASS**——浏览器代行(AP11)、codraft(AP12)、**真 retry→pass 自适应闭环(AP13)**、depends_on 门控(AP14) 全部端到端验证成立；唯一 FAIL 为 AP4(MCP 不下发子代理) known-limitation 不阻塞。浏览器二进制需 `npx playwright install chromium` 或配置远程环境（docs.trae.cn/solo_set-up-the-remote-environment）。**至此"LLM 驱动的动态自适应 PGE 编排"在真机端到端成立。**

---

### 决策 17：多模式编排框架——6 种编排模式全做（v4.5）

**日期**：2026-07-02

**背景**：v4.4 确立 Orchestrator 图灵完备底座后，用户提出更大胆的想法——Claude Code 的 Dynamic Workflows 内置 6 种编排模式（Classify-and-act / Fan-out-and-synthesize / Adversarial / Generate-and-filter / Tournament / Loop until done），而本框架此前只落地了最经典的 **adversarial（PGE）**。能否把其余几种也在国产免费平台上模拟？原则不变：执行机只负责"频繁对抗/比较的内环"，跨 pattern/Stage 由人工调度，或父 Agent 上下文预算够时自动一次跑完。

**结论与决策（全上：6 种模式全做）**：
1. **无需新平台能力，只需新 playbook**：6 种模式都能用 v4.4 已验证的同一套原语（顺序/分支/并行派发/有界循环/自修改 tasks.md/持久 board）+ 独立 SubAgent + harness 总线组合出来。**6 种模式现均已真机端到端验证**：adversarial/loop=AP1–AP14（loop=retry 泛化=AP13）；classify/fanout/generate-filter/tournament=AP15–AP18（commit c9a5e84）。
2. **新增 3 个轻量角色**：Classifier（打标签）、Synthesizer（并行结果汇总）、Selector（候选选优/两两淘汰），复用既有 Generator/Evaluator/Decision。
3. **新增 4 个 pattern playbook**：pattern-classify / pattern-fanout / pattern-generate-filter / pattern-tournament。
4. **Stage 层新增 `pattern` 字段**（Planner 在 milestone-plan 标，默认 `adversarial`）：`stage-executor` step 2.5 据此路由到对应 playbook；模式可嵌套（如 classify→fanout，fanout 每个子任务内部走 adversarial）。
5. **新增 `generate_patterns` 生成开关**（Advisor 侧，默认 `false`）：开启则额外生成多模式包（3 角色+4 playbook 共 7 个 Skill）；未开启时所有 Stage 走默认 adversarial，交付物不变。

**交付（commit d19d398，已推 main）**：新增 3 角色模板 + 4 pattern playbook 模板（templates 增至 21 个）；实例化 7 个新 Skill 到 `.trae/skills/`（自检环境增至 12 个）；更新 stage-executor（pattern 路由）、planner-role（pattern 字段+6 模式判据）、resources §3.10、deliverable-specs §11/§12、SKILL.md/SKILL.zh.md（generate_patterns 参数）、README。

**约束与注脚**：多模式已从"设计级落地 + 原语级已验证"升级为 **6 种模式端到端真机验证成立**（AP15–AP18 于 commit c9a5e84 通过：pattern 路由链路 + Classifier/Synthesizer/Selector 三新角色子代理加载 + fanout/generate-filter 真并行 + canonical 文件名与 Write 白名单对齐）。所有 playbook 仍是提示词级 best-effort，需 CI/评审/最小权限令牌兜底。

---

## 外部参考资源

> **来源核实说明（v4.1，2026-06）**：以下链接经 HTTP 核实。失效/伪造链接（404）已修正为权威地址或标注；状态不确定者标"未核实"。详见 `trae-harness-advisor/resources/...` 附录 B。

### 方法论来源（已核实）

1. **LangChain - The Anatomy of an Agent Harness**
   URL: https://blog.langchain.com/the-anatomy-of-an-agent-harness/
   核心贡献: Agent = Model + Harness 的定义，Harness 组件分类
   （原 `blog.langchain.dev/...` 为 404，已修正）

2. **Martin Fowler / Birgitta Böckeler - Harness Engineering**
   URL: https://martinfowler.com/articles/harness-engineering.html
   核心贡献: Feedforward vs Feedback、Computational vs Inferential、Keep Quality Left、Steering Loop
   （原"备忘录 memo/..."与"分析 harness-engineering-analysis/"均为 404；实为 Böckeler 单篇文章，已合并）

3. **Mitchell Hashimoto - My AI Adoption Journey**
   URL: https://mitchellh.com/writing/my-ai-adoption-journey
   核心贡献: 6 阶段 AI 采用框架，阶段 5 = 工程化 Harness

4. **Anthropic - Effective harnesses for long-running agents**
   URL: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
   核心贡献: Pattern A（Initializer + Coding Agent）和 Pattern B（Planner-Generator-Evaluator）
   （原 `harness-design-for-long-running-application-development` 为 404，已修正）

### 方法论来源（未核实，谨慎引用）

5. **OpenAI - Harness Engineering 实践**
   URL: https://openai.com/index/harness-engineering/ （反爬 403，无法独立核实）
   核心贡献（待核实）: 0 人类代码行、100 万行生成代码、Context Engineering + Architectural Constraints + Garbage Collection

6. **Claude Code — Dynamic Workflows 文档**
   URL: https://docs.anthropic.com/en/docs/claude-code/workflows （文档站 soft-200，内容未独立核实）
   核心贡献（待核实）: 内置编排模式、运行时编排

### TRAE Work 参考（已核实）

7. **TRAE 官方文档 - SPEC 工作流**
   URL: https://docs.trae.cn/solo/spec-and-plan

8. **TRAE 官方社区 - SubAgent / SOLO 并行调度**
   URL: https://forum.trae.cn/t/topic/1189 ，https://forum.trae.cn/t/topic/1139 ，https://forum.trae.cn/t/topic/2702
   核心贡献: SubAgent 调度能力、SOLO 多任务并行零冲突、Agent 概念

> 已删除：`qiita.com/kzk_maeda/items/5c3a4e2f...`（404，伪造链接）。

---

## 已知限制与待解决问题

### 当前限制

1. **人类在回路中**: Planner 阶段需要人类确认 spec.md，无法完全自动化。这是 TRAE Work 的设计特性，也是 Harness L4 Steering 层的体现。

2. **SubAgent 并行度**: 最多 5 个并行 SubAgent。对于大型项目，可能需要分批调度。

3. **无持久会话**: 每个 SPEC session 结束后上下文丢失，依赖文件系统（global_task_board.json、eval/ 目录）传递状态。

4. **无外部触发**: 无法通过 Webhook 或 API 触发 SPEC 工作流，必须手动执行 `/spec` 命令。

### 平台假设验证状态（已真机端到端验证，v4.4 综合自检 13/14 PASS）

通过 `poc/harness-selftest/`（probe + adaptive 两 Stage，commit f76f8fc）已验证：

1. ✅ SubAgent 加载自定义角色 Skill（generator/evaluator/decision-role）— AP2
2. ✅ SubAgent 上下文隔离（三方）— AP3；✅ 自动加载 — AP1；✅ RULE.md 钩子 — AP8
3. ✅ 路径白名单提示词级、拒绝越权 — AP5
4. ✅ 交付物→harness、三件套→.trae/specs、原生 checklist=完成性 — AP6/AP7
5. ✅ 真并行+无自动循环 — AP9；✅ retry 重派 — AP10；✅ 真 retry→pass 自适应闭环 — AP13
6. ✅ 浏览器代行链路（方案1）— AP11；✅ codraft — AP12；✅ depends_on 门控 — AP14
7. ❌ **SubAgent 不继承 MCP — AP4（已知平台限制，不阻塞；浏览器验证由 Orchestrator 代行）**

**仍待处理/操作项**：
- AP11 实际浏览器交互需预装 chromium（`npx playwright install chromium`）或配置 TRAE 远程环境（docs.trae.cn/solo_set-up-the-remote-environment）。
- 长 session 中 Orchestrator 上下文窗口管理：靠 board+harness 外置状态分 Stage 续跑；超长流程建议人工分批投递（暂未纳入 PoC）。
- 小项目 Lite 预设（跳过部分角色）为可选优化，尚未实现。

---

## 未来迭代方向

### 短期（当前能力范围内）

1. **Skill 校准数据积累**: 收集 Evaluator 的评分案例，构建 few-shot 校准库，提高评分一致性
2. **模板库扩展**: 针对不同技术栈（React、Python、Go、Rust）生成定制化模板
3. **验收场景深化**: 完善 Verification 模式的模板和流程（大规模代码验收）

### 中期（依赖平台能力演进）

1. **自动化 Planner 触发**: 如果 TRAE Work 支持 Webhook/API 触发，可以实现 Git Push → 自动启动 SPEC 工作流
2. **多 Milestone/Stage 并行编排**: 利用 SubAgent 并行能力，同时推进多个依赖已满足的 Stage
3. **Harness 组件自迭代**: 参考 OpenAI 的"Agent 遇到困难 → 分析根因 → 构建 Harness 组件"闭环

### 长期（方法论层面）

1. **跨项目 Harness 复用**: 将 Harness 配置（Skills、Rules、Templates）抽象为可跨项目安装的包
2. **质量趋势分析**: 基于 eval/ 目录的历史评估报告，分析项目质量变化趋势
3. **自适应严格度**: 根据项目阶段和 Sprint 类型，动态调整 Evaluator 的评分严格度