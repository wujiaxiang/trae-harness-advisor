---
name: operator-playbook
description: >
  Operator（操作员）——本框架里**唯一运行在 TRAE Work 之外**的角色。
  由「人」或「Codex/CUA 计算机使用代理」或「强 LLM 父 agent（若 TRAE 暴露 API）」扮演，
  负责纯机械的跨 Stage 调度：读 board → 在 TRAE Work 开对话派发 Stage → 等完成 → 读 decision → 推进或上抛。
  **只搬运、不判断**：一切需要判断的点（是否接受 escalate、纠偏方向、给授权）都停下来交给监督者。
  仅在「三档自动化」的 B 档（人 + Codex-CUA + TRAE Work）需要生成本文件。
---

# Operator 操作员 · 外部调度 Playbook

> 这不是 TRAE Work 内部的 SubAgent 技能，**不放进 `{skill_dir}`**。它是一份放在总线里的外部驱动说明（`{harness_dir}operator-playbook.md`），供**人照着做**、或**喂给 Codex/CUA 当指令**、或**给父 agent 当编排脚本**。

## 它在拓扑里的位置

我们把原来的「人节点」拆成两半，Operator 只接管其中**机械**的一半：

| 子职责 | 性质 | 谁干 |
|---|---|---|
| **操作员工作**：开新对话、贴固定提示模板、点「云端运行」、等完成、读 `decision.md`/`state-board.json` 推进下一个 Stage | 机械、可脚本化、重复 | ✅ Operator（人 / Codex-CUA / 父agent） |
| **监督者工作**：是否接受 escalate、纠偏方向、给 API Key/授权、跨 Milestone 取舍 | 判断、不可外包 | ⛔ 监督者（人 / 强 LLM 父 agent） |

Stage **内部**的对抗（Generator→Evaluator→Decision、有界 retry）由 TRAE Work 内的 Orchestrator 全自动完成，Operator **不介入内环**——它只在 Stage 之间搬运。

## 三档自动化（扮演者矩阵）

| 档 | 扮演 Operator 者 | 效果 | 代价 / 前提 |
|---|---|---|---|
| **A** | 人 | 现状：人兼操作员+监督者 | 每个 Stage 手动开对话；适合低频、重决策 |
| **B** | **Codex / CUA** | **变相全自动**：机器搬运，人只监督/纠偏 | 需监督预算；受 CUA 可靠性、成本、平台 ToS 约束（见下「护栏」「风险」） |
| **C** | 强 LLM 父 agent（走 TRAE API，若可用） | 最干净：API 编排，无屏幕驱动 | **依赖 TRAE 暴露 API/Web 控制台**，当前多为平台限制 |

无论哪一档，**监督者交接点（下文）不变**——差别只在「谁点鼠标」，不在「谁拍板」。

## 行为准则（护栏——把自己当一个会犯错的执行器来管）

1. **只搬运，不判断**。遇到以下任一情况**立即停止并上抛监督者**，绝不自行放行：
   - `decision.md` 判定为 `escalate`；
   - 任一角色写出 `[BLOCKED]`（缺 Key/授权/外部依赖/需求歧义）；
   - 达到 `max_adversarial_rounds` 仍未 `pass`；
   - 需要提供密钥、授权、或任何业务取舍。
2. **状态以总线文本为准**。判断 Stage 是否完成、是否 pass、下一个派发谁，**一律读 `{harness_dir}state-board.json` 与 `decision.md` 文本**，**绝不靠屏幕像素/截图解析业务状态**（截图驱动脆弱且会误判）。
3. **动作幂等 + 有界重试**。每个 UI 动作（开对话/贴提示/点运行/取回路径）失败时重试 ≤ 2 次；仍失败→上抛监督者。重复派发同一 Stage 不得造成重复副作用（先查 board 该 Stage 状态再决定是否派发）。
4. **事件驱动优先，禁止忙轮询**。board 无变化时不空转、不反复截图；用「运行完成」信号或合理间隔轮询，降低成本与被平台判定异常的风险。
5. **最小 UI 面**。CUA/人只做**不可省的 UI 动作**——在 TRAE Work 里触发一次云端运行 + 贴入 stage-executor 调用提示 + 取回产物路径；其余状态交换全部走 git / `{harness_dir}` 总线文本。UI 接触面越小，越可靠。
6. **不改业务真值**。`spec/tasks/checklist/gen/eval/decision` 与 `state-board.json` 的业务字段由 TRAE Work 内角色回写；Operator **只读它们 + 触发运行 + 记调度日志**，不改写业务内容。
7. **全程留痕**。每次派发/推进/上抛都追加到 `{harness_dir}operator-log.md`（时间戳、Stage id、动作、结果、下一步），供监督者审计与断点续跑。

## 调度循环（伪码）

```
loop:
  board = read {harness_dir}state-board.json
  ready = board 中 status=planned 且 depends_on 全部 passed 的 Stage
  if ready 为空:
     若仍有未完成 Stage 但被 escalate/BLOCKED 卡住 → 上抛监督者并停
     否则 → Milestone 完成，写 operator-log 收尾，退出
  for stage in ready:          # fanout/tournament 可一次派发多个
     在 TRAE Work 新开云端对话
     贴入：stage-executor 调用提示（指定 milestone / stage / pattern）
     触发云端运行；记 operator-log
  等待（事件驱动）这些 Stage 的对话结束
  for stage in 刚跑完:
     d = read {stage 路径}/decision.md
     if d == pass:            board 已由内环回写 passed；记 log，继续
     if d == escalate or 出现 [BLOCKED] or 超 max rounds:
                              上抛监督者（附 Stage id + decision 摘要 + log），停该分支
  回到 loop
```

## 监督者交接点（必停清单）

Operator **永远不做**下列任何一项，一律停下交监督者：
- 接受/否决 `escalate`；
- 决定 retry 的**纠偏方向**（改哪、怎么改）；
- 提供 API Key、账号授权、密钥、付费确认；
- 跨 Milestone / 需求层面的取舍与优先级；
- 判定「这个业务结果算不算达标」（这是 Evaluator/监督者的判断，不是搬运）。

## 逐模式操作要点（B 档收益差异）

Operator 的价值 = 该模式**需要重复开对话/推进的次数**：

| 模式 | Operator 要做的搬运 | B 档收益 |
|---|---|---|
| adversarial / loop | 跨 Stage 串联：一个 Stage 一次对话，读 decision 推进下一个 | 中 |
| classify | 派发 1 个分类 Stage，按结果派发后续 | 低 |
| **fanout** | **一次批量开 N 个并行对话**贴各 part 提示 → 回收 `part-*.md` → 派发 synthesizer 归并 | 高 |
| **generate-filter** | 批量派发候选生成（`cand-*.md`）→ 触发 selector 选优 | 高 |
| **tournament** | **逐轮推进 bracket**：开每轮对话、回收 `bracket-rN.md`、推进到下一轮，人只看最终 `winner.md` | 最高 |

> 关键：之前「超大 fan-out / tournament 受上下文预算需**人**分批」这条限制，B 档把它变成「**机器**分批」——这是 Operator 最值钱的地方。adversarial/loop 本就单窗口自动化，Operator 只省几次点击，收益有限；不必为它们启用 B 档。

## CUA 特有风险（如实告知监督者，由其权衡）

1. **集成面决定可靠性**：若 TRAE Work 只有桌面 IDE、无 API/Web 控制台 → CUA 只能截图驱动桌面（当前此类端到端成功率偏低、延迟以分钟计、随 UI 改版失效）；若有 Web 控制台 → 走浏览器原生远更可靠。**启用 B 档前先确认 TRAE 的可驱动面**。
2. **成本/延迟**：CUA 每步都是视觉+LLM 调用，忙轮询会烧钱——务必事件驱动、最小 UI 面。
3. **平台 ToS / 反滥用**：用机器人驱动**免费产品** UI 大规模取算力，可能违反服务条款或触发反滥用风控。这是监督者要显式承担的选择，Operator 不替其决定。

## 输出

- `{harness_dir}operator-log.md`（唯一产物）：追加式调度审计日志。
- 不产出任何业务文件，不改写 board 业务字段。
