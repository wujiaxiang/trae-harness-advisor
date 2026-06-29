# Harness Engineering on TRAE Work 架构设计文档 — 编写计划

## 文档元信息

| 属性 | 内容 |
|------|------|
| 文档标题 | 《Harness Engineering on TRAE Work：Planner-Generator-Evaluator 多智能体对抗架构最佳实践》 |
| 目标读者 | LLM/Agent（读完后能理解并实现 PGE 工作流），同时兼容人类开发者阅读 |
| 输出格式 | Markdown（主文档，给 LLM 读）+ HTML（html-report 渲染，给人读） |
| 输出路径 | `resources/harness-engineering-on-trae-work.md`（当前位于 Skill 目录内） |
| 预计章节数 | 5 大部分，约 20-25 个子章 |

---

## 第一部分：Harness Engineering 方法论综述

### 1.1 什么是 Harness Engineering？

- 引用 LangChain 定义：Agent = Model + Harness
- 对比 Prompt Engineering 与 Harness Engineering 的本质区别
- 论述单一 Prompt 的瓶颈：模型无法自我评估、上下文腐化、缺乏持久状态

### 1.2 业界实践全景

#### 1.2.1 Mitchell Hashimoto 的 6 阶段 AI 采用框架
- 阶段 1-4：从聊天机器人到外包明确任务
- 阶段 5（Engineer the Harness）：每次智能体犯错，构建工具让它不再犯
- 阶段 6（Always Have an Agent Running）：持续运行的智能体团队
- 图表：6 阶段阶梯图

#### 1.2.2 OpenAI 的 Harness Engineering 实践
- 0 人类代码行，100 万生成代码，1500 PRs
- 三类 Harness：Context Engineering、Architectural Constraints、Garbage Collection
- 图表：三层 Harness 架构图

#### 1.2.3 Anthropic 的 Pattern A 与 Pattern B
- Pattern A：Initializer + Coding Agent，分 Feature 上下文重置
- Pattern B：Planner-Generator-Evaluator，GAN 对抗架构
- 核心洞察：模型无法自我批判（pathological optimist）
- 图表：Pattern A vs Pattern B 架构对比、GAN 类比图

#### 1.2.4 Martin Fowler 的 Harness 框架
- Feedforward (Guides) vs Feedback (Sensors)
- Computational vs Inferential 控制
- 三类 Harness：Maintainability、Architecture Fitness、Behaviour
- 质量左移（Keep Quality Left）理念
- 图表：2x2 控制矩阵、三类 Harness 分层图、Steering Loop

### 1.3 Harness Engineering 分层体系

- 五层模型：Context Layer → Execution Layer → Orchestration Layer → Verification Layer → Steering Layer
- 每层对应具体组件和解决的核心问题
- 图表：五层金字塔架构图、各层与业界实践的对应关系表

---

## 第二部分：TRAE Work 平台能力分析

### 2.1 平台能力全景

- `.trae/` 目录结构作为 Harness 配置的物理载体
- 作用域体系：Project > User > Local
- 图表：目录结构全景图、作用域优先级图

### 2.2 SPEC 工作流

- spec.md / tasks.md / checklist.md 三阶段文档
- AI 暂停确认机制 → Planner 角色映射
- 图表：SPEC 工作流时序图

### 2.3 Skills 体系

- 按需加载（Progressive Disclosure）解决 Context Rot
- Skills vs Rules 的本质区别
- 图表：Skills 按需加载流程图

### 2.4 Rules 体系

- project_rules / user_rules / path-based rules
- Rules 作为 Computational Feedforward 控制
- 图表：Rules 加载时序图

### 2.5 SubAgent 体系（核心能力）

- 独立上下文窗口 — 上下文隔离的基础
- 路径白名单隔离 — 三层路径管控
- 结果摘要回传机制
- 图表：SubAgent 上下文隔离架构图、路径白名单三层模型

### 2.6 平台能力与 Harness 分层体系映射

- 每个 TRAE Work 能力映射到 Harness 五层
- 识别能力缺口
- 图表：映射矩阵表

---

## 第三部分：TRAE Work 上的 Harness 架构设计

### 3.1 Planner 角色定义

- 职责：将需求扩展为完整产品规格说明
- 输出边界：只描述"做什么""为什么"，不描述"怎么做"
- 实现方式：SPEC 工作流 + Planner Skill
- 图表：Planner 输入输出数据流图

### 3.2 Generator 角色定义

- 职责：按 Sprint 实现功能，TDD 驱动
- 核心行为：分 Feature 工作、自检、Git 版本控制
- 实现方式：Generator SubAgent + Generator Skill
- 图表：Generator Sprint 工作流状态机

### 3.3 Evaluator 角色定义

- 职责：以"怀疑者"身份测试，四维评分（功能性/工艺质量/完整性/用户体验）
- 核心原则：必须与 Generator 结构分离
- 实现方式：Evaluator SubAgent + Evaluator Skill + Playwright MCP
- 图表：评分维度雷达图、评估报告模板

### 3.4 上下文隔离方案

- 三层隔离：角色级 → 任务级 → 路径级
- 共享状态：文件系统作为通信总线
- 上下文重置策略：Compaction + Context Reset
- 图表：三层隔离架构全景图、上下文生命周期图

### 3.5 沟通协议设计

- 基于文件系统的异步通信
- Sprint Contract 协议：Propose → Review → Agree/Revise → Build → Evaluate
- 文件结构约定：specs/、contracts/、memory/ 目录
- 图表：Sprint Contract 协商序列图、协议状态机

---

## 第四部分：实战指南

### 4.1 tasks.md 模板

- 完整模板结构：产品概述、技术栈、Sprint 分解、验收标准、非功能性需求
- 验收标准编写原则：必须可机械检查
- 图表：模板结构图、好/坏验收标准对比表

### 4.2 Skills 模板

- 三大核心 Skill 完整示例：Planner / Generator / Evaluator
- Skill 迭代优化指南
- 图表：三个 Skill 的关系图

### 4.3 Rules 模板

- 项目级规则、按路径规则、个人规则
- 规则编写 Checklist
- 图表：Rules 文件结构模板图

### 4.4 Sprint Contract 流程

- 完整生命周期：9 步流程从 Planner 输出到最终验收
- 每步输入/输出/负责角色
- 图表：三泳道泳道图

### 4.5 SubAgent 配置模板

- 三个核心 SubAgent 的完整配置
- 路径白名单配置示例
- 模型选择策略
- 图表：配置对比表、权限矩阵图

---

## 第五部分：从开发到验收的完整流程示例

### 5.1 示例场景
- 任务管理看板 Web 应用（Todo Kanban）
- 技术栈：React + FastAPI + SQLite
- 图表：应用架构概览图

### 5.2 Phase 1: 规划
- Planner 输出完整 spec.md
- 拆分为 5 个 Sprint
- 图表：Sprint 依赖图

### 5.3 Phase 2: 执行
- Sprint 1 详细示例：Contract 协商 → 编码 → 自检 → 提交
- Git 提交历史展示
- 图表：Sprint 1 时序图

### 5.4 Phase 3: 评估
- Evaluator 运行测试 + 浏览器验证
- 评估报告完整示例
- 模拟一次"失败→修复"循环
- 图表：评估流程活动图、Pass/Fail 决策树

### 5.5 Phase 4: 迭代与验收
- 全部 Sprint 完成后的端到端验收
- Harness 自我迭代：从问题中更新 Rules/Skills
- 图表：端到端验收流程图

### 5.6 完整流程回顾
- 时间线、Token 消耗、成本估算
- Solo Agent vs PGE Harness 对比
- 图表：完整时间线图、对比雷达图

---

## 附录

- **附录 A**：术语表（Harness、Feedforward、Feedback、Sprint Contract、Context Rot 等）
- **附录 B**：参考资源链接
- **附录 C**：TRAE Work 配置速查表

---

## 输出格式

| 格式 | 路径 | 用途 |
|------|------|------|
| Markdown | `resources/harness-engineering-on-trae-work.md` | 主文档，给 LLM/Agent 阅读 |
| HTML | `docs/harness-engineering-on-trae-work/harness-engineering-on-trae-work.html` | 给人阅读，支持目录导航、图表渲染、代码高亮 |
| 模板文件 | `templates/` | 独立模板，供复制使用 |

---

## 写作规范

1. **LLM 可读性优先**：清晰 Markdown 结构、明确标题层级、一致 YAML Frontmatter
2. **代码示例完整**：所有模板均为可直接复制使用的完整内容，无占位符
3. **中文为主，英文术语保留**：核心概念首次出现时标注英文原文
4. **引用标注**：所有外部来源论点标注来源链接
5. **图表使用 Mermaid**：流程图、时序图、架构图使用 Mermaid 语法
6. **确定性用语**：使用"必须""禁止""要求"，避免"可能""尽量""建议"

---

## 实施步骤

1. 创建目录结构（Skill 根目录 + `resources/` + `templates/` + `docs/`）
2. 按章节顺序编写 Markdown 主文档（第一部分 → 第五部分 → 附录）
3. 使用 html-report skill 生成 HTML 版本
4. 质量审查：链接有效性、代码语法、图表一致性、术语一致性

---

## 潜在挑战与应对

| 挑战 | 应对 |
|------|------|
| 内容量大，单文件过长 | 模板独立到 `templates/` 目录 |
| Mermaid 图在 HTML 中渲染兼容性 | 使用 html-report 确认支持的格式 |
| 平台能力持续迭代 | 文档注明版本信息，引导查阅最新文档 |
| Evaluator 调校缺乏量化标准 | 提供 Few-shot 示例评分表 |