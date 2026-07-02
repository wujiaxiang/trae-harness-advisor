---
name: pattern-tournament
description: >
  编排模式 playbook：Tournament（两两淘汰赛）。当 Stage 的 pattern=tournament 时加载本 playbook。
  对 N 个候选做两两比较、逐轮淘汰，得出冠军。比单次打分更鲁棒。
---
# pattern-tournament playbook（Tournament）

> 你是 root Stage Orchestrator，只串联。交付物写 harness 总线，三件套留 .trae/specs。

## 适用场景
候选多、单次绝对打分不可靠，用**相对两两比较**更稳（如：从 4-8 个文案/设计/实现里选最佳）。

## 确定性流程
1. 读 board/milestone-plan 定位 Stage；确定候选数 N 与**两两比较标准**（写入 contract.md）。
2. 运行 /spec 产三件套到 .trae/specs。
3. **并行派发 N 个 @generator-role** 产候选 → `cand-1.md`..`cand-N.md`。
4. **Bracket 淘汰**（最多 ceil(log2(N)) 轮，有界）：
   - 每轮把存活候选两两配对，【派发 @selector-role】逐对比较出 winner → 写入 `brackets.round-{n}` 对应文件。
   - winners 进入下一轮，直到剩 1 个。
5. 输出 `winner.md`（冠军 + 每场对决依据）。
6. 回写 board（artifacts: `candidates` + `brackets` + `winner`；候选路径按 `candidates.{candidate_id}`，轮次按 `brackets.round-{n}` 命名空间记录）。

## 注意
- 轮数有界（log2(N)），防失控；每轮持久化 bracket，爆上下文也能续。
- 两两比较基于可机械检查证据；平局用明确打破规则（更少代码/更高覆盖率等）。
