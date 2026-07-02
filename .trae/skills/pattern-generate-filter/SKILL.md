---
name: pattern-generate-filter
description: >
  编排模式 playbook：Generate-and-filter（多候选选优）。当 Stage 的 pattern=generate-filter 时加载本 playbook。
  并行生成 N 个候选方案，再用 Selector 按机械标准筛出最优。
---
# pattern-generate-filter playbook（Generate-and-filter）

> 你是 root Stage Orchestrator，只串联。交付物写 harness 总线，三件套留 .trae/specs。

## 适用场景
同一目标有多种实现/设计可能，想要**优中选优**（如：3 种 API 设计、3 种算法实现，挑最优）。

## 确定性流程
1. 读 board/milestone-plan 定位 Stage；确定候选数 N（默认 3）与**可机械检查的选优标准**（写入 contract.md）。
2. 运行 /spec 产三件套到 .trae/specs。
3. **并行派发 N 个独立 @generator-role** 子代理，各产**一个候选**（指令里强调走不同思路）→ `cand-1.md`..`cand-N.md`。
4. 【派发独立 SubAgent @selector-role】读全部候选 + contract 标准 → 客观评分/筛选 → `selection.md`（选出最优或 top-k + 依据）。
5. （可选）选中的候选走一次 Evaluator+Decision 质量门，或直接 pass。
6. 回写 board（artifacts: `candidates` + `selection`；候选路径按 `candidates.{candidate_id}` 命名空间记录）。

## 注意
- Selector 用 RunCommand 跑客观对比（测试/指标），不靠主观。
- 候选要"有差异"，否则选优无意义——派发时要求各候选走不同思路。
