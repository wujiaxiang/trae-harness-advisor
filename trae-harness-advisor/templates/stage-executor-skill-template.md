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
- {harness_dir} 是唯一持久真值与消息总线。
- .trae/specs/ 仅是原生 /spec 临时 scratch，不得作为跨 session 依赖。
- SPEC 三件套必须持久化到 {harness_dir}milestones/{milestone}/stages/{stage}/。
- skeleton 文件只提供结构，不包含业务内容；业务内容由 Orchestrator 在当前 Stage 对话中推理填充。
- 对抗流程是顺序模拟，不是自动控制流循环；最多 {max_adversarial_rounds} 轮，超限 escalate。

## 确定性流程

### 1. 读取状态机并定位当前 Stage
1. 读取 `{harness_dir}state-board.json`。
2. 找到当前应执行的 Stage：优先使用用户指定；否则选择第一个 status 为 planned/spec_ready/in_progress 且依赖满足的 Stage。
3. 校验该 Stage 的 depends_on 全部为 passed；否则停止并报告未满足依赖。
4. 将该 Stage 状态置为 in_progress（如尚未置位）。

### 2. 读取 Milestone 静态定义
1. 读取 `{harness_dir}milestones/{milestone}/milestone-plan.md`。
2. 提取当前 Stage 的目标、范围、验收标准要点、depends_on、技术栈与非功能性需求。
3. 不把动态状态写回 milestone-plan.md；动态状态只写 state-board.json。

### 3. 运行 /spec 并持久化三件套
1. 读取 `{harness_dir}templates/spec.skeleton.md`、`tasks.skeleton.md`、`checklist.skeleton.md`。
2. 运行 `/spec`，按骨架生成当前 Stage 的 spec.md、tasks.md、checklist.md。
3. 将三件套持久化到 `{harness_dir}milestones/{milestone}/stages/{stage}/`。
4. 不依赖 `.trae/specs/` 中的副本；如平台生成了临时文件，仅将其视为 scratch。

### 4. 自检门
继续前必须同时满足：
- spec.md 包含 Stage 目标、范围边界、验收标准、依赖、非功能性需求五个部分。
- tasks.md 包含 [GENERATOR]、[EVALUATOR]、[DECISION] 顺序步骤。
- checklist.md 是完成性 gate，且与 tasks.md 的关键完成项 1:1 对应。
- 三件套没有残留未替换的关键占位符。

任一失败：停止执行，报告缺口，不派发子角色。

### 5. 顺序派发对抗步骤
按 tasks.md 顺序执行，最多 {max_adversarial_rounds} 轮：
1. [GENERATOR] 提出或更新 Stage Contract → `contract.md`。
2. [EVALUATOR] 审查 Contract，批准或要求修改。
3. [GENERATOR] 按 Contract 进行 TDD 实现 → `gen.md`。
4. [EVALUATOR] 进行四维业务质量评估 → `eval.md`。
5. [DECISION] 读取 gen.md + eval.md → `decision.md`，裁决 pass/retry/escalate。

若 verdict=retry 且 rounds 未达上限，带 retry_focus 重新派发 [GENERATOR]。若达到上限仍未通过，必须转 escalate 并暂停等待人类裁决。

### 6. 回写 state-board.json
根据 decision.md 回写 `{harness_dir}state-board.json`：
- status: spec_ready / in_progress / passed / failed / escalated
- rounds
- last_decision: pass | retry | escalate | null
- artifacts: spec/tasks/checklist/contract/gen/eval/decision 的实际路径

## 完成条件
- checklist.md 的完成性 gate 通过。
- decision.md verdict=pass。
- state-board.json 已回写当前 Stage 的最终状态和产物路径。
