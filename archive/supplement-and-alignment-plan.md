# 文档补充与对齐计划

> **目标**：补充理论文档（追齐 Claude Code Workflow 讨论），修复所有不一致，确保 Skill 实现与文档和新思想完全对齐

---

## 1. 当前状态分析

### 1.1 已发现的严重不一致（Explore Agent 分析结果）

| # | 问题 | 严重度 |
|---|------|--------|
| 1 | Planner 输出物矛盾：主文档说输出 spec.md+tasks.md+checklist.md，模板说只输出 spec.md | 严重 |
| 2 | 三角色 vs 四角色架构矛盾：主文档无 Decision 角色，但模板和 Skill 已包含 | 严重 |
| 3 | spec-template.md 文件名与内容不匹配（实际是 tasks.md 格式） | 严重 |
| 4 | README 交付物描述严重过时（缺 Decision Agent、tasks-pattern.md 等） | 严重 |
| 5 | 主文档第4.2节 Skills 模板内容过时（未反映 Planner 职责收窄） | 中等 |
| 6 | 主文档第4.5节 SubAgent 模板只列了 2 个（缺 Decision） | 中等 |
| 7 | 主文档 tasks.md 模板过时（未反映"运行时动态生成"） | 中等 |
| 8 | 文件结构约定不一致（contracts vs eval 目录） | 中等 |
| 9 | 主文档第5.2节 Planner 输出描述与实际不符 | 中等 |
| 10 | 主文档完全未提及 Claude Code 对标分析 | 缺失 |

### 1.2 缺失的理论内容

| 缺失内容 | 应补充位置 |
|---------|-----------|
| Claude Code `.claude/agents/` 静态 Harness 对标 | 主文档第一部分或新增章节 |
| Claude Code Dynamic Workflows 对标 | 主文档第一部分或新增章节 |
| 我们的四角色流程图（G→E→D 循环） | 主文档第三部分 |
| 半自动 vs 全自动的差异分析 | 主文档新增章节 |
| Planner 战略分解 vs 云端 Agent 战术编排的职责边界 | 主文档第三部分 |
| Orchestrator 对比（Claude Code 内置 vs 我们拼出来的） | 主文档新增章节 |

---

## 2. 变更计划

### 2.1 主文档 `harness-engineering-on-trae-work.md` 补充

#### 变更 1：新增"1.4 Claude Code 对标分析"章节

**位置**：第一部分末尾，1.3 之后

**内容**：
- Claude Code `.claude/agents/` 静态 Harness 机制介绍
- Planner/Generator/Evaluator 的 `.claude/agents/` 实现（引用 Qiita 文章）
- Dynamic Workflows 介绍（6 种编排模式）
- 三列对比表：Claude Code `.claude/agents/` vs Claude Code Dynamic Workflows vs TRAE Work（我们的实现）
- 核心差异：全自动 vs 半自动（自动调度 vs 人工触发 SPEC）

#### 变更 2：重写"3.2 三角色 PGE 架构"为"3.2 四角色 PGE 架构"

**内容**：
- 更新为四角色：Planner、Generator、Evaluator、Decision
- 新增 Decision 角色定义：中立裁决者（历史口径曾称 Orchestrator 代理；当前口径为独立 Decision + root Stage Orchestrator）
- 新增四角色流程图（ASCII art）
- 明确 Planner 只输出 spec.md + 更新全局任务表
- 明确 tasks.md 由云端 Agent 运行时动态生成

#### 变更 3：新增"3.7 与 Claude Code 的对比"章节

**内容**：
- Claude Code 内置 Orchestrator vs 我们"拼出来"的 Orchestrator（SPEC + Skills + Rules + SubAgent）
- 编排效果对比表（方法论效果可以追齐，自动化程度追不齐）
- 类比：Claude Code 是"内置发动机"，我们是用"零件组装了一台发动机"

#### 变更 4：更新"4.1 SPEC 模板"章节

**内容**：
- 移除 tasks.md 和 checklist.md 的预生成内容
- 新增 tasks-pattern.md 的说明：编排模式参考，云端 Agent 运行时动态生成 tasks.md
- 更新 roles 引用：增加 Decision 角色

#### 变更 5：更新"4.2 Skills 模板"章节

**内容**：
- Planner Skill 模板更新：职责收窄标注，不输出 tasks.md/checklist.md
- 新增 Planner 与云端 Agent 的契约说明

#### 变更 6：更新"4.5 SubAgent 配置模板"章节

**内容**：
- 新增 Decision SubAgent 配置模板
- 角色说明：中立裁决者，不写代码不评估代码，只做 pass/retry/escalate

#### 变更 7：更新"5.2 Sprint 1"示例

**内容**：
- Planner 输出改为只输出 spec.md
- 增加云端 Agent 动态生成 tasks.md 的步骤
- 增加 Decision 裁决步骤

#### 变更 8：更新"附录 C 配置速查表"

**内容**：
- 增加 Decision SubAgent 配置文件
- 更新 tasks.md 条目为 tasks-pattern.md

### 2.2 模板文件修复

#### 变更 9：重写 `spec-template.md`

**问题**：当前内容实际是 tasks.md 格式，标题为"任务分解"
**修复**：重写为 spec.md 格式，标题为"{Feature Name} — 产品规格说明"，包含产品概述、技术栈、Sprint 分解（战略级）、非功能性需求、开放问题

#### 变更 10：更新 `README.md`

**修复内容**：
- 更新项目结构图（增加 Decision、tasks-pattern.md）
- 更新"Skill 是什么"章节（四角色架构）
- 更新模板数量（9 → 10）
- 更新给后续 Agent 的指引（增加 Decision 角色说明）

### 2.3 上下文文档补充

#### 变更 11：更新 `conversation-context-and-design-decisions.md`

**新增内容**：
- 新增"发现 3：Claude Code Workflow 对标"章节
- 记录 2026-06-29 的 Claude Code 调研结论
- 记录 Decision 角色的引入决策
- 记录 Planner 职责收窄决策
- 新增"决策 6：引入 Decision 角色作为中立裁决者"
- 新增"决策 7：Planner 职责收窄为战略分解"
- 更新外部参考资源（增加 Claude Code 相关链接）

### 2.4 Skill 文件对齐检查

#### 变更 12：验证 `SKILL.md` 和 `SKILL.zh.md`

**检查项**：
- I/O 合同是否反映四角色架构 ✓（已更新）
- Step 生成顺序是否包含 Decision ✓（已更新）
- Step 7 完成摘要是否反映新流程 ✓（已更新）
- 确认不需要进一步修改

#### 变更 13：验证 `deliverable-specs.md`

**检查项**：
- 交付物数量是否为 10 个 ✓（已更新）
- 是否包含 Decision SubAgent 生成规则 ✓（已更新）
- tasks-pattern.md 说明是否清晰 ✓（已更新）
- 确认不需要进一步修改

#### 变更 14：验证 `harness-methodology.md`

**检查项**：
- 是否反映四角色架构 → 需要更新
- 更新为四角色 + 新增 Decision 角色说明
- 更新 Sprint Contract 协议（增加 Decision 裁决步骤）

---

## 3. 变更文件清单

| 序号 | 文件 | 变更类型 | 变更内容 |
|------|------|---------|---------|
| 1 | `resources/harness-engineering-on-trae-work.md` | 补充 | 新增 1.4 Claude Code 对标、重写 3.2 为四角色、新增 3.7 对比章节、更新 4.1/4.2/4.5/5.2/附录C |
| 2 | `templates/spec-template.md` | 重写 | 改为 spec.md 格式（产品规格说明），非 tasks.md 格式 |
| 3 | `../README.md` | 更新 | 更新项目结构、交付物描述、模板数量 |
| 4 | `../conversation-context-and-design-decisions.md` | 补充 | 新增 Claude Code 对标发现、Decision 引入决策、Planner 收窄决策 |
| 5 | `references/harness-methodology.md` | 更新 | 更新为四角色架构，增加 Decision 说明 |
| 6 | `references/deliverable-specs.md` | 验证 | 确认已对齐，无需修改 |
| 7 | `SKILL.md` | 验证 | 确认已对齐，无需修改 |
| 8 | `SKILL.zh.md` | 验证 | 确认已对齐，无需修改 |

---

## 4. 假设与决策

1. **四角色架构是最终形态**：Planner + Generator + Evaluator + Decision，不再回退到三角色
2. **Planner 只输出 spec.md**：tasks.md 由云端 Agent 运行时生成，这是已确认的设计决策
3. **文档风格保持一致**：主文档使用中文，结构化章节，ASCII art 流程图，表格对比
4. **Skill 文件（SKILL.md/SKILL.zh.md/deliverable-specs.md）已与最新设计对齐**，本次只需验证确认，不需要修改

---

## 5. 验证步骤

1. 主文档中所有 Planner 输出描述一致（只输出 spec.md + 全局任务表）
2. 主文档中所有角色引用为四个（Planner/Generator/Evaluator/Decision）
3. spec-template.md 标题为"产品规格说明"而非"任务分解"
4. README.md 项目结构图与实际文件一致
5. harness-methodology.md 包含四角色说明
6. 所有文档中对 Claude Code 的引用一致
7. 无残余的"三角色""tasks.md 预生成""checklist.md"引用