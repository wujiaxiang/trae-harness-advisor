# Stage Contract — patterns（多模式路由自检）

> Orchestrator 据 milestone-plan §97-107 标注。本 Stage 无对抗轮次（pattern 路由自检，每个 pattern 跑通骨架即可）；contract 标注 4 个 pattern 的验收要点。

## 目标
验证 v4.5 多模式编排路由（fanout/classify/generate-filter/tournament）与 3 个新角色（Classifier/Synthesizer/Selector）可加载调度。用极小"业务"输入跑通每个 pattern 的 playbook 骨架。

## 验收要点
1. **AP15 fanout**：加载 @pattern-fanout playbook；一条消息两并行 Task 块派 @generator-role 写 part-a.md("A")/part-b.md("B") + 时间戳；@synthesizer-role 读两片段归并 synthesis.md。
2. **AP16 classify**：加载 @pattern-classify playbook；@classifier-role 对 "fix the login 500 error" 从 {bugfix,feature,refactor} 打标签写 classify.md（含 `label: <值>`）；Orchestrator 据 label 分支写 route.md。
3. **AP17 generate-filter**：加载 @pattern-generate-filter playbook；一条消息两并行 Task 块派 @generator-role 写 cand-1.md/cand-2.md；@selector-role 按简单标准选优写 selection.md（含 `winner: cand-N`）。
4. **AP18 tournament（可选）**：加载 @pattern-tournament playbook；@selector-role 用 AP17 两候选两两淘汰写 winner.md（候选少时淘汰=选优）。

## 边界
- 交付物：part-a/part-b/synthesis/classify/route/cand-1/cand-2/selection/winner → harness/milestones/harness-selftest/stages/patterns/。
- 三件套留 .trae/specs/（scratch）。
- 不改 src/、不装依赖。
- 子代理独立、上下文隔离；Orchestrator 只串联，不兼任角色。

## 通过判定
AP15-18 全 PASS（AP18 可选，候选少时淘汰=选优仍记 PASS）→ patterns.status=passed、rounds=1、last_decision=pass。
