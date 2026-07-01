# route.md — AP16 classify 路由分支（Stage patterns）

> 由 Orchestrator 据 classify.md 的 label 分支派发。Classifier 不执行路由，路由是 Orchestrator 的分支动作（pattern-classify playbook §4）。

## 输入
- classify.md 路径：harness/milestones/harness-selftest/stages/patterns/classify.md
- label：`bugfix`
- route（Classifier 建议）：`修复流程`
- confidence：`high`

## 路由表（milestone-plan §104）
| label | 目标 |
|---|---|
| bugfix | 修复流程 |
| feature | 功能开发流程 |
| refactor | 重构流程 |

## 分支决定
- 据	label=`bugfix`（confidence=high，在路由表内）→ **路由到修复流程**。
- 输出：`路由到修复流程`（按 milestone-plan §104 约定：bugfix→打印"路由到修复流程"）。

## VERIFY
- `VERIFY[AP16]: PASS — pattern-classify 已路由（Skill 加载 pattern-classify + classifier-role）；classifier-role 加载并给出 label=bugfix（confidence=high，证据 "fix"+"500 error"）；Orchestrator 据 label 分支到"修复流程"并写 route.md。`

## 说明
- 本案为多模式路由自检，分支动作以写 route.md 记录"路由到修复流程"为完成标志，不实际派发后续修复实现（非本 Stage 范围）。
- Classifier confidence=high 且 label 在路由表内，未触发 escalate。
