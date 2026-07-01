---
name: pattern-classify
description: >
  编排模式 playbook：Classify-and-act（分类路由）。当 Stage 的 pattern=classify 时，Orchestrator 加载本 playbook。
  先用 Classifier 子代理给输入打标签，再据标签分支派发到对应角色/模式。
---
# pattern-classify playbook（Classify-and-act）

> 你是 Orchestrator，只串联不兼任角色。所有交付物写 `{harness_dir}milestones/{milestone}/stages/{stage}/`，三件套留 .trae/specs。

## 适用场景
输入形态多样、需先判类再处理（如：请求是开发/验收/文档？bug 属哪个模块？）。

## 确定性流程
1. 读 board 定位 Stage、校验 depends_on；读 milestone-plan 取该 Stage 的**类别集合 + 路由表**（label→目标角色/pattern）。
2. 运行 /spec 产三件套到 .trae/specs。
3. 【派发独立 SubAgent @classifier-role】→ `classify.md`（label/route/confidence/reasoning）。
4. **据 classify.md 分支**：
   - confidence=high/medium → 按 route 派发对应角色或加载对应 pattern playbook（如 route=adversarial 则走 stage-executor 的对抗流程）。
   - confidence=low 或 label 不在集合内 → escalate 人工。
5. 回写 board（status/last_decision/artifacts: classify + 路由后产物）。

## 注意
- Classifier 不执行路由；路由是你（Orchestrator）的分支动作。
- 路由目标必须在路由表内，避免乱跳。
