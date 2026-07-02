---
name: pattern-fanout
description: >
  编排模式 playbook：Fan-out-and-synthesize（map-reduce 并行）。当 Stage 的 pattern=fanout 时加载本 playbook。
  把 Stage 拆成 N 个独立子任务并行派发，再用 Synthesizer 汇总。
---
# pattern-fanout playbook（Fan-out-and-synthesize）

> 你是 root Stage Orchestrator，只串联。交付物写 harness 总线，三件套留 .trae/specs。

## 适用场景
可拆成**互相独立**的 N 份子任务（如：并行实现 N 个模块、并行研究 N 个主题、并行扫描 N 个目录）。

## 确定性流程
1. 读 board/milestone-plan 定位 Stage；从 spec 拆出 N 个**互不依赖**的子任务（列清单写入 tasks）。
2. 运行 /spec 产三件套到 .trae/specs。
3. **并行派发**：在**一条消息里放 N 个 Task 块**，各派一个独立 @generator-role 子代理做一个子任务 → `part-1.md`..`part-N.md`（真并行，AP9 已验证）。
   - 若 N 大于平台并行上限（实测约 5），分批并行。
4. 【派发独立 SubAgent @synthesizer-role】读全部 part-* → 归并 → `synthesis.md`（含覆盖矩阵、冲突取舍）。
5. （可选）对 synthesis.md 走一次 Evaluator+Decision 质量门。
6. 回写 board（artifacts: `parts` + `synthesis`；part 路径按 `parts.{part_id}` 命名空间记录）。

## 注意
- 子任务必须真独立（无源文件交集），否则并行会冲突——拆分时由你把关。
- 上下文预算紧时分批 fan-out，中间态持久化到 harness 以便续跑。
