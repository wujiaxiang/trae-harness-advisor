---
name: stage-executor
description: >
  当用户说“执行 Stage”“开始阶段”“run stage”或要求推进当前 Stage 时使用。
  这是 Orchestrator 的运行时 playbook：读取 state-board.json 和 milestone-plan.md，按骨架运行 /spec，持久化三件套，顺序派发 Generator/Evaluator/Decision，并回写状态。
---

# stage-executor playbook

## 定位
你是 Orchestrator 的确定性执行手册。你不预设业务内容；你根据当前 Stage 上下文在运行时推理内容，并使用 harness/templates/*.skeleton.md 作为结构骨架。

## 强约束
- harness/ 是唯一持久真值与消息总线。
- .trae/specs/ 完全可弃：原生 /spec 临时 scratch，不读取、不依赖、不传消息。
- subagent 执行 tasklist 时，必须把我们关心的交付物主动写入 harness/milestones/{milestone}/stages/{stage}/。
- skeleton 文件只提供结构，不包含业务内容；业务内容由 Orchestrator 在当前 Stage 对话中推理填充。
- 对抗流程是顺序模拟，不是自动控制流循环；最多 3 轮，超限 escalate。

## 确定性流程

### 1. 读取状态机并定位当前 Stage
1. 读取 `harness/state-board.json`。
2. 找到当前应执行的 Stage：优先使用用户指定；否则选择第一个 status 为 planned/spec_ready/in_progress 且依赖满足的 Stage。
3. 校验该 Stage 的 depends_on 全部为 passed；否则停止并报告未满足依赖。
4. 将该 Stage 状态置为 in_progress（如尚未置位）。

### 2. 读取 Milestone 静态定义
1. 读取 `harness/milestones/{milestone}/milestone-plan.md`。
2. 提取当前 Stage 的目标、范围、验收标准要点、depends_on、技术栈与非功能性需求。
3. 不把动态状态写回 milestone-plan.md；动态状态只写 state-board.json。

### 3. 运行 /spec 并把交付物写入总线
1. 读取 `harness/templates/spec.skeleton.md`、`tasks.skeleton.md`、`checklist.skeleton.md`。
2. 运行 `/spec`，按骨架生成当前 Stage 的 spec.md、tasks.md、checklist.md。
3. `.trae/specs/` 下的原生产物**完全可弃**：不读取、不依赖其路径。
4. 在 tasks.md 中显式约定：每个 subagent 执行时，把"我们关心的交付物"**主动写入** `harness/milestones/{milestone}/stages/{stage}/`（spec/checklist 关键信息 + contract.md/gen.md/eval.md/decision.md）。总线 = harness/，不是 .trae/specs/。

### 4. 自检门
继续前必须同时满足：
- spec.md 包含 Stage 目标、范围边界、验收标准、依赖、非功能性需求五个部分。
- tasks.md 包含 [GENERATOR]、[EVALUATOR]、[DECISION] 顺序步骤。
- checklist.md 是完成性 gate，且与 tasks.md 的关键完成项 1:1 对应。
- 三件套没有残留未替换的关键占位符。

任一失败：停止执行，报告缺口，不派发子角色。

### 5. 标注 Contract 并顺序派发对抗步骤
先由你（Orchestrator）标注关键 Contract 点 → `contract.md`（目标/验收要点/边界，一次标注，非多轮协商；若 force_contract=false 则跳过，Generator 直接按 spec 实现）。
你（Orchestrator）只负责**串联流程**：派发子代理、读裁决、决定下一步；**不亲自实现、不评分、不裁决**。
然后按 tasks.md 顺序执行，最多 3 轮：
1. 【派发独立 SubAgent，加载 @generator-role】[GENERATOR] 按 contract.md 进行 TDD 实现 → `gen.md`。
2. 【派发独立 SubAgent，加载 @evaluator-role】[EVALUATOR] 进行四维业务质量评估 → `eval.md`。
3. 【派发**独立** SubAgent，加载 @decision-role】[DECISION] 只读 gen.md+eval.md+contract.md → `decision.md`，裁决 pass/retry/escalate。
   - Decision 必须是独立子代理（与 G/E 隔离、看不到双方对话），保证中立盲审；**你（Orchestrator）不得自己兼任裁决**。

**根据 decision.md 的 verdict 决定下一步（这是你的核心编排职责）**：
- `pass` → 进入 checklist 完成性 gate，回写 board=passed。
- `retry`（且 rounds < 3）→ 你**有权修改 tasks.md**：在其中追加一轮返工任务（标注 round N+1 与 Decision 给的 `retry_focus`），然后**重新派发 [GENERATOR]**（带 retry_focus），rounds+1，再走 E→D。
- `escalate`（或 rounds 达上限仍未过）→ 暂停，回写 board=escalated，请求人类裁决。
- 你**不能**让任何子代理自我循环；多轮返工只能由你**手动重新派发**（无自动 loop）。

### 6. 回写 state-board.json
根据 decision.md 回写 `harness/state-board.json`（**最小更新原则**：只改当前 Stage 那一条记录的字段，不整体重写、不动其它 Stage，确保 git 合并不冲突）：
- status: spec_ready / in_progress / passed / failed / escalated
- rounds
- last_decision: pass | retry | escalate | null
- artifacts: spec/tasks/checklist/contract/gen/eval/decision 的实际路径

> 并发说明：Stage 并发 = 人类开多个独立对话推进，非自动调度。投递某 Stage 前须确认其 `depends_on` 全部 passed，且与在途 Stage 无源文件交集（代码冲突由人工把关）。

## 完成条件
- checklist.md 的完成性 gate 通过。
- decision.md verdict=pass。
- state-board.json 已回写当前 Stage 的最终状态和产物路径。
