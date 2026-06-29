# Harness Engineering 方法论参考

> 本文是 `trae-harness-advisor` Skill 的方法论参考文件。
> 完整文档见 `../resources/harness-engineering-on-trae-work.md`。

## 目录

1. [核心定义](#核心定义)
2. [五层分层体系](#五层分层体系)
3. [PGE+D 四角色架构](#pged-四角色架构)
4. [Sprint Contract 协议](#sprint-contract-协议)
5. [上下文隔离方案](#上下文隔离方案)
6. [TRAE Work 能力映射](#trae-work-能力映射)
7. [与 Claude Code 的对比](#与-claude-code-的对比)

## 核心定义

**Agent = Model + Harness**（LangChain, 2026）。凡不是模型本身的部分，就是 Harness。

Harness Engineering 关注构建让 AI 在其中可靠工作的环境，而非仅仅告诉 AI 做什么。

**四大核心问题**：
- 模型无法自我评估（pathological optimist）
- 上下文腐化（Context Rot）
- 缺乏持久状态
- 单一 Prompt 已触及天花板

## 五层分层体系

```
L4: Steering Layer     — 人类反馈、Harness 自我迭代、质量监控
L3: Verification Layer — Linter、Test、LLM-as-Judge、Browser Validation
L2: Orchestration Layer — SubAgent 调度、上下文重置、Compaction
L1: Execution Layer    — Filesystem、Bash、Sandbox、Browser、MCP
L0: Context Layer      — Rules、Skills、AGENTS.md、知识库
```

## PGE+D 四角色架构

| 角色 | 职责 | 输出 | 实现方式 |
|------|------|------|----------|
| **Planner** | 需求 → 产品规格 + Sprint 级战略分解 | spec.md（仅 Sprint 分解，不输出 tasks.md） | SPEC 工作流暂停阶段 |
| **Generator** | 按 Sprint 实现功能，TDD 驱动 | 代码、测试、git commit、实现总结 | SubAgent + Skill |
| **Evaluator** | 验证 Generator 输出，四维评分 | 评估报告、截图、修复建议 | SubAgent + Skill + Playwright MCP |
| **Decision** | 中立裁决（Orchestrator 代理） | pass / retry / escalate 裁决 | SubAgent（只读） |

**核心洞察**：
- 模型无法自我批判。Generator 和 Evaluator 必须运行在独立 SubAgent 中，拥有独立上下文
- Decision 是 Orchestrator 代理——TRAE Work 没有内置 Orchestrator，Decision 通过"只读两份报告 → 输出裁决"的方式模拟 Orchestrator 的决策功能
- Planner 只做战略分解，tasks.md 由云端 Agent 运行时动态生成（读取 spec.md + tasks-pattern.md）

## Sprint Contract 协议

端到端 10 步流程（步骤 1-2 为 Planner/编排准备，步骤 10 为全局收尾；步骤 3-9 是单 Sprint 的对抗循环，对应 tasks-pattern.md 中压缩后的"6 个可执行步骤"：Contract 草案→Contract 审查→实现→总结→评估→Decision 裁决，其中 Decision 裁决即第 9 步）：
1. Planner 输出 spec.md（Sprint 级战略分解）
2. 云端 Agent 读取 spec.md + tasks-pattern.md，动态生成 tasks.md
3. Generator 提出 Sprint Contract 草案
4. Evaluator 审查 Contract（最多 3 轮协商）
5. 双方达成一致
6. Generator 按 Contract 实现（TDD）
7. Generator 自检 + git commit + 实现总结
8. Evaluator 运行测试 + 浏览器验证 + 评估报告
9. Decision 读取两份报告 → 裁决（pass/retry/escalate）
10. 全部 Sprint 完成后最终验收

## 上下文隔离方案

三层隔离：
- L1: 角色级 — Planner/Generator/Evaluator/Decision 各自独立 SubAgent
- L2: 任务级 — 每个 Sprint 独立 Generator 实例
- L3: 路径级 — 路径白名单限制文件访问范围

共享状态：文件系统是 SubAgent 之间唯一的通信总线。

## TRAE Work 能力映射

| Harness 层 | TRAE Work 能力 |
|-----------|---------------|
| L0: Context | Rules、Skills |
| L1: Execution | 文件系统、Bash、Sandbox、MCP |
| L2: Orchestration | SPEC 工作流、SubAgent 调度、Decision 裁决 |
| L3: Verification | MCP（Playwright、Linter） |
| L4: Steering | 人类审查 SPEC 暂停确认、escalate 升级裁决 |

## 与 Claude Code 的对比

| 维度 | Claude Code | TRAE Work（我们的实现） |
|------|-------------|----------------------|
| Orchestrator | 内置，全自动路由和调度 | 拼装式：SPEC + Skills + Rules + Tasks + SubAgent + Decision + 人类 |
| 自动化程度 | 全自动 | 半自动（人类触发 SPEC，之后自动执行对抗循环） |
| 角色定义 | `.claude/agents/` 下 Markdown 文件 | `.trae/agents/` 下 Markdown 文件 + Skills |
| 上下文隔离 | 内置，每个角色独立上下文 | SubAgent 独立上下文（手动配置） |
| 编排修改 | 静态文件 + 运行时 JS 脚本 | 全部 Markdown 文件，可直接编辑 |
| 费用 | 付费 | 免费（TRAE Work 免费版） |

**方法论效果可以追齐，自动化程度无法追齐。**