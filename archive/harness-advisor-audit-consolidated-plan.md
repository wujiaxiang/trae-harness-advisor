# Trae Harness Advisor 四轮审计与收敛归档

> 日期：2026-07-02  
> 范围：`trae-harness-advisor` 设计文档、生成规格、模板、实例化 `.trae/skills/`、`harness/` 自检环境、PoC 文档和历史决策。

## 背景

项目从 v4.0 到 v4.6 经过多轮概念演进后，README、方法论文档、deliverable specs、模板和自检实例之间出现了口径残留。审计目标是从三个批判视角统一设计：

1. **内部逻辑不一致**：特别是 `.trae/specs/` 与 `harness/` 边界、角色读写权限、Decision/Evaluator 边界、board artifacts schema。
2. **名称概念过多**：`stage-executor`、Operator、pattern playbook、role Skill、SubAgent 等概念需要更准确命名。
3. **逻辑漏洞或不足**：classify 嵌套 pattern、SubAgent 能力边界、外部调度与人类仲裁边界、独立 best-practices 文件双源漂移。

## 第一轮：核心架构口径修复

### 发现

- 多处仍把 SPEC 三件套写入或读取自 `harness/`，但权威口径应是 `.trae/specs/` 当前对话 scratch。
- `stage-executor` 实际承担 root 控制流职责，应叫 **Stage Orchestrator**。
- Evaluator/Decision 写权限和输入边界混淆，Evaluator 曾被描述为可写 `decision.md`。
- `classify -> pattern:*` 的路由与嵌套执行能力未定义。

### 决策

- `.trae/specs/spec.md|tasks.md|checklist.md` 仅作当前 Stage 对话内过程脚手架，不入 `harness/`，不进 board artifacts。
- `harness/` 只持久化 `milestone-plan.md`、`contract.md`、`gen.md`、`eval.md`、`decision.md`、`browser-check.md`、`state-board.json`、模板和可选外部文件。
- 新增 canonical `stage-orchestrator`，`stage-executor` 降级为旧名兼容 shim。
- Pattern playbook 是 root Stage Orchestrator 的子流程库，不是 SubAgent；`pattern:*` 路由必须由 root inline 展开。
- Classifier 只分类，不路由；真正路由者是 Stage Orchestrator。

### 结果

- 新增 `stage-orchestrator` 模板与实例。
- 修正 Planner / Generator / Evaluator / Decision / Classifier 等角色边界。
- 增加 Pattern Composition Contract 和 nested artifacts 规则。
- README、RULE、SKILL、deliverable specs、resources、PoC 同步到 Stage Orchestrator 口径。

## 第二轮：外围产物与 schema 收口

### 发现

- 可选 `.trae/agents/` 模板仍保留旧架构。
- Operator playbook 仍引用旧入口，并把三件套暗示成持久真值。
- `tasks.skeleton.md` 仍写旧的“顺序模拟”和硬编码轮次。
- `state-board.json` artifacts schema 与 pattern 产物不匹配。
- 文件计数、README、SKILL 输出清单与实际新增 shim 后不一致。
- 方法论文档内联旧模板，产生双源漂移。

### 决策

- optional Agent templates 与 Skill 模板保持同一角色边界。
- Operator 仅能读 `harness/` 持久真值；`.trae/specs/` 不作为跨 session 真值。
- board artifacts schema 统一：
  - adversarial/loop：`contract/gen/eval/decision/browser_check`
  - classify：`classify + routes`
  - fanout：`parts + synthesis`
  - generate-filter：`candidates + selection`
  - tournament：`candidates + brackets + winner`
- 文件计数改为“13 个核心文件：12 权威 + 1 shim”（后续第四轮因删除 best-practices 再降为 12）。

### 结果

- 更新 Agent templates、Operator playbook、tasks skeleton、pattern playbooks、selector、board 示例。
- 方法论文档中的旧模板压缩为“以 templates 为生成源头”或直接修正关键旧路径。
- PoC 增加 Agent 模板、Operator 入口、board artifacts schema 审计断言。

## 第三轮：外部调度角色拆分

### 发现

`Operator` 概念仍然混淆三类责任：

1. 规划阶段的组长/负责人：发起 Planner 对话、确认 `milestone-plan.md`。
2. 执行阶段的机械搬运者：搬运 Stage 上下文、开执行对话、贴 `@stage-orchestrator`。
3. 过程 review 和最终仲裁者：处理 escalate/BLOCKED、授权、业务取舍和最终验收。

真正可由外部 Agent 替代的只有第 2 类机械搬运。

### 决策

- 人类判断角色命名为 **Supervisor / Lead**。
- 外部机械派发角色命名为 **External Stage Dispatcher / Stage Dispatcher**。
- Stage Dispatcher 只负责执行阶段派发：
  - 读 board 找 ready Stage
  - 打开 TRAE Work 执行对话
  - 调用 `@stage-orchestrator`
  - 等完成并读 `decision.md`
  - pass 推进，escalate/BLOCKED/授权/最终验收上抛 Supervisor
- Stage Orchestrator 仍只负责单个 Stage 对话内部控制流。

### 结果

- 新增 Stage Dispatcher 外部派发说明。
- README、resources、deliverable specs、SKILL、PoC、历史决策同步为 Supervisor/Lead + Stage Dispatcher 口径。

## 第四轮：模板命名、兼容残留和 best-practices 去中心化

### 发现

- `stage-dispatcher-playbook-template.md` 仍带 `playbook`，容易和 Skill/pattern playbook 混淆。
- `operator-playbook` shim 和 `generate_operator` 兼容描述会继续让 Agent 读到旧概念。
- `llm-task-authoring-best-practices.md` 是独立参考文件，Planner/Generator/Evaluator/Contract 通过“详见某节”跳转，容易双源漂移。

### 决策

- Dispatcher 模板采用 `stage-dispatcher-template.md`，不叫 `skill-template`，也不叫 `playbook-template`。
- 生成物采用 `harness/stage-dispatcher.md`。
- 删除旧 Operator shim 和旧开关引用，不再保留可用兼容路径。
- 删除独立 `llm-task-authoring-best-practices.md`，将必要规则直接内联到使用处：
  - Planner：Stage 拆分原则、3000 行预算、串并行判据、一命令边界、显式排除、停止条件。
  - Generator：按需读文件、报错诊断步骤、7 个必停条件、状态报告格式。
  - Evaluator：“你看到什么就算通过”、可观测证据、避免空泛 200/跑通判断。
  - stage-contract skeleton：6 段式验收项、失败速查表、停止条件。

### 结果

- 新增/保留 canonical：
  - `trae-harness-advisor/templates/stage-dispatcher-template.md`
  - `harness/stage-dispatcher.md`
- 删除：
  - `trae-harness-advisor/templates/operator-playbook-template.md`
  - `harness/operator-playbook.md`
  - `trae-harness-advisor/references/llm-task-authoring-best-practices.md`
  - `harness/references/llm-task-authoring-best-practices.md`
- 核心文件数更新为 **12 个核心文件：11 个权威文件 + 1 个 stage-executor 兼容 shim**。

## 最终权威口径

### 路径与产物

| 产物 | 位置 | 生命周期 |
|---|---|---|
| `spec.md/tasks.md/checklist.md` | `.trae/specs/` | 当前 Stage 对话内 scratch，不进 `harness/` |
| `milestone-plan.md` | `harness/milestones/{milestone}/` | Milestone 静态定义 |
| `contract/gen/eval/decision/browser-check` | `harness/milestones/{milestone}/stages/{stage}/` | Stage 持久消息总线 |
| `state-board.json` | `harness/` | 动态状态机唯一真值 |
| `stage-dispatcher.md` | `harness/` | 可选外部机械派发说明，不在 `.trae/skills/` |

### 角色边界

| 角色 | 职责 | 不负责 |
|---|---|---|
| Advisor | 生成脚手架与指导思想 | 不写业务 milestone-plan 或三件套实例 |
| Planner | 拆 Milestone/Stage，初始化 board | 不执行 Stage，不生成三件套 |
| Stage Orchestrator | 单 Stage root 控制流，运行 `/spec`、路由 pattern、派发子代理、回写 board | 不写业务代码、不评分、不裁决 |
| Generator | 实现代码/测试，写 `gen.md` | 不评价自己，不改验收标准 |
| Evaluator | 业务质量评估，写 `eval.md` | 不写 `decision.md`，不裁决 |
| Decision | 独立中立裁决，写 `decision.md` | 不实现、不评分、不代理 Orchestrator |
| Supervisor / Lead | 人类规划确认、review、授权、仲裁 | 不做重复机械搬运 |
| Stage Dispatcher | 外部机械派发执行对话 | 不规划、不 review、不裁决 |

## 验证记录

最终完成后执行了以下检查：

- `rg` 扫描旧引用无命中：
  - `stage-dispatcher-playbook`
  - `stage-dispatcher-playbook-template`
  - `operator-playbook`
  - `operator-playbook-template`
  - `generate_operator`
  - `llm-task-authoring-best-practices`
  - 旧 13 文件计数
- `python3 -m json.tool harness/state-board.json`
- `git diff --check`

## 后续维护原则

1. 生成源头以 `trae-harness-advisor/templates/` 与 `references/deliverable-specs.md` 为准。
2. 方法论文档讲契约和决策，不再复制大段易过期模板。
3. 历史决策保留演进史，但旧概念必须标注 superseded。
4. 新增外部角色时，先判断它是人类判断角色、外部机械角色，还是 TRAE Work 内部 Skill，避免再次混用 Operator/Skill/playbook 等术语。
