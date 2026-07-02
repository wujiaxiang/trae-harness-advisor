---
name: stage-dispatcher
description: >
  External Stage Dispatcher（外部 Stage 派发器）——运行在 TRAE Work 之外的机械搬运角色。
  它只负责执行阶段的组员对话派发：读 board → 搬运 Stage 上下文 → 在 TRAE Work 开执行对话 →
  贴入 stage-orchestrator 调用提示 → 等完成 → 读 decision/board → pass 推进或异常上抛 Supervisor。
  它不发起规划组长对话，不做 review，不做仲裁。
---

# Stage Dispatcher 外部派发器

> 这不是 TRAE Work 内部 SubAgent 技能，**不放进 `.trae/skills/`**。它是一份放在总线里的外部派发说明（`harness/stage-dispatcher.md`），供**人照着做**、或**喂给 Codex/CUA 当机械执行指令**、或**给父 agent 当编排脚本**。

## 角色拆分：Lead / Dispatcher / Stage Orchestrator

| 角色 | 阶段 | 谁扮演 | 负责 | 不负责 |
|---|---|---|---|---|
| **Supervisor / Lead（监督者/组长）** | 规划 + 审阅 + 仲裁 | 人，或人授权的强父 agent | 发起 Planner 对话、确认 `milestone-plan.md`、处理 review/escalate/BLOCKED、给授权、最终取舍 | 不做重复 UI 搬运 |
| **External Stage Dispatcher（外部 Stage 派发器）** | 执行阶段跨 Stage 搬运 | 人 / Codex-CUA / 父 agent | 找 ready Stage、搬运上下文、开执行对话、贴 `stage-orchestrator` 提示、记录日志、异常上抛 | 不规划、不 review、不裁决、不改业务真值 |
| **Stage Orchestrator** | 单个 Stage 对话内部 | TRAE Work root agent + `.trae/skills/stage-orchestrator` | 运行 `/spec`、写 contract、派发 G/E/D、执行 retry/escalate、回写 board | 不跨 session 自动开新对话 |
| **Role SubAgents** | Stage 内叶子执行 | TRAE Work 子代理 | Generator/Evaluator/Decision 等叶子职责 | 不递归启动 Stage Orchestrator |

一句话：**Lead 发起“组长规划对话”并做判断；Dispatcher 只发起“组员团体执行对话”；Stage Orchestrator 管一个执行对话内部的对抗流程。**

## Dispatcher 的唯一职责

Dispatcher 只接管原来人手里最机械的一段：

1. 读 `harness/state-board.json` 和 `milestone-plan.md`，找出 `status=planned` 且依赖已通过的 Stage。
2. 为每个 ready Stage 打开一个 TRAE Work 云端执行对话。
3. 贴入固定提示：调用 `@stage-orchestrator`，指定 milestone / stage / pattern / board 路径。
4. 等待该执行对话完成。
5. 读取该 Stage 的 `decision.md` 和 board 状态：
   - `pass`：记录日志，继续派发后续 ready Stage；
   - `retry`：由 Stage Orchestrator 在同一执行对话内处理，Dispatcher 不插手；
   - `escalate` / `[BLOCKED]` / 超轮次 / 缺授权：停止该分支，上抛 Supervisor。
6. 追加 `harness/stage-dispatcher-log.md`。

## 必须上抛 Supervisor 的情况

Dispatcher 一律停下并把上下文交给 Supervisor：

- Planner/milestone-plan 尚未被人确认；
- `decision.md` 判定为 `escalate`；
- 任一角色写出 `[BLOCKED]`；
- 达到 `3` 仍未 pass；
- 需要 API Key、账号授权、密钥、付费确认；
- 需要业务取舍、需求变更、优先级调整；
- 需要人类 review 或最终验收判断。

上抛包必须包含：milestone、stage、当前 board 条目、`decision.md` 摘要、相关 `gen/eval/browser-check` 路径、dispatcher log 最近记录。

## 调度循环（伪码）

```text
precondition:
  Supervisor 已确认 milestone-plan.md，并允许进入执行阶段

loop:
  board = read harness/state-board.json
  ready = board 中 status=planned 且 depends_on 全部 passed 的 Stage

  if ready 为空:
     若仍有 Stage 被 escalate/BLOCKED 卡住 → 上抛 Supervisor 并停
     否则 → Milestone 执行完成；写 stage-dispatcher-log；等待 Supervisor review

  for stage in ready:
     在 TRAE Work 新开执行对话
     贴入 @stage-orchestrator 调用提示（milestone / stage / pattern / harness 路径）
     触发云端运行
     记录 stage-dispatcher-log

  等待这些执行对话完成（事件驱动优先，禁止忙轮询）

  for stage in 刚完成:
     d = read {stage 路径}/decision.md
     if d == pass:
        记录 log，继续
     if d == escalate or 出现 [BLOCKED] or 超轮次:
        上抛 Supervisor，停该分支
```

## 护栏

1. **只搬运，不判断**：Dispatcher 不能接受/否决 escalate，不能决定 retry 纠偏方向，不能做业务验收。
2. **只读持久总线**：跨 session 状态只读 `harness/`；`.trae/specs/` 是 Stage 对话内 scratch，不是 Dispatcher 真值来源。
3. **不改业务真值**：`contract/gen/eval/decision/browser-check/state-board` 的业务字段由 TRAE Work 内角色写；Dispatcher 只写 `stage-dispatcher-log.md`。
4. **动作幂等**：派发前先查 board，避免重复开同一 Stage 造成副作用。
5. **事件驱动优先**：不要靠截图忙轮询业务状态；以对话完成信号、git/文件变化和合理间隔为准。
6. **最小 UI 面**：只做开对话、贴固定提示、触发运行、读取产物路径这类不可省 UI 动作。

## 三档自动化

| 档 | Dispatcher 扮演者 | 适用 |
|---|---|---|
| **A** | 人 | 低频执行；人同时扮演 Lead + Dispatcher，但概念上仍要区分判断与搬运 |
| **B** | Codex / CUA | 机器替代机械搬运；人只当 Supervisor 处理 review/仲裁/授权 |
| **C** | 强父 agent + TRAE API | 最干净的 API 编排；依赖平台暴露稳定 API |

## 逐模式收益

| 模式 | Dispatcher 要做的搬运 | B 档收益 |
|---|---|---|
| adversarial / loop | 一个 Stage 一次执行对话；读 decision 推进下一个 | 中 |
| classify | 派发分类 Stage；root Stage Orchestrator inline 展开 route | 低 |
| fanout | 分批派发大 fanout，回收 namespaced artifacts 后触发汇总 | 高 |
| generate-filter | 分批派发 candidates，再触发 selector | 高 |
| tournament | 逐轮推进 brackets，回收 winner | 最高 |

## 输出

- `harness/stage-dispatcher-log.md`：唯一可写产物，追加式调度审计日志。
- 不产出业务文件，不改写 board 业务字段。
