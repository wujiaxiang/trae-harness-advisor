---
name: stage-orchestrator
description: >
  当用户说“执行 Stage”“开始阶段”“run stage”或要求推进当前 Stage 时使用。
  这是 Stage Orchestrator 的运行时 playbook：读取 state-board.json 和 milestone-plan.md，按骨架运行 /spec（三件套留在 .trae/specs 即可），只把交付物 contract/gen/eval/decision/browser-check 写入 harness/ 总线，顺序派发 Generator/Evaluator/Decision，并回写状态。
---

# Stage Orchestrator playbook

## 定位
你是 Stage Orchestrator 的确定性执行手册。你不预设业务内容；你根据当前 Stage 上下文在运行时推理内容，并使用 {harness_dir}templates/*.skeleton.md 作为结构骨架。

## 强约束
- {harness_dir} 是唯一持久真值与消息总线。
- .trae/specs/ 放原生 /spec 三件套（spec/tasks/checklist），是过程脚手架：本对话内可读，不进 harness、不进 git、对话结束即弃。
- subagent 执行 tasklist 时，必须把交付物（contract/gen/eval/decision/browser-check）主动写入 {harness_dir}milestones/{milestone}/stages/{stage}/。
- skeleton 文件只提供结构，不包含业务内容；业务内容由 Stage Orchestrator 在当前 Stage 对话中推理填充。
- 对抗流程是 LLM 驱动的有界动态编排；最多 {max_adversarial_rounds} 轮，超限 escalate。
- 只有 root Stage Orchestrator 拥有控制流、MCP 代行、pattern 路由和 board 回写职责；任何 SubAgent 都不得递归启动本 playbook。
- MCP 访问默认采用 `orchestrator_delegated`；若项目显式配置 `mcp_access_mode=evaluator_shell_bridge`，你只运行 bridge 自检并把白名单能力写入 contract，不读取浏览器中间状态。

## 确定性流程

### 1. 读取状态机并定位当前 Stage
1. 读取 `{harness_dir}state-board.json`。
2. 找到当前应执行的 Stage：优先使用用户指定；否则选择第一个 status 为 planned/spec_ready/in_progress 且依赖满足的 Stage。
3. 校验该 Stage 的 depends_on 全部为 passed；否则停止并报告未满足依赖。
4. 将该 Stage 状态置为 in_progress（如尚未置位）。

### 2. 读取 Milestone 静态定义
1. 读取 `{harness_dir}milestones/{milestone}/milestone-plan.md`。
2. 提取当前 Stage 的目标、范围、验收标准要点、depends_on、技术栈、非功能性需求、**`pattern`**、**`contract_mode`**。
3. 不把动态状态写回 milestone-plan.md；动态状态只写 state-board.json。

### 2.5 按 pattern 路由编排模式
读 Stage 的 `pattern`（默认 `adversarial`）。**adversarial 用本 playbook 下面的步骤 3-7**；其它模式**加载对应 pattern playbook 并由当前 root Stage Orchestrator inline 执行**：
- `adversarial` → 本 playbook（Generate→Evaluate→Decide，见步骤 3-7）。
- `loop` → 本 playbook，但把"对抗"退化为"Generator 迭代精炼 + 每轮一个客观检查（Evaluator 或 RunCommand），达标或满 {max_adversarial_rounds} 轮即止"（即 retry 闭环的泛化）。
- `classify` → 加载 `@pattern-classify`（Classifier 打标签 → 你按 route_table 分支路由）。
- `fanout` → 加载 `@pattern-fanout`（并行 N 子任务 → Synthesizer 汇总）。
- `generate-filter` → 加载 `@pattern-generate-filter`（并行 N 候选 → Selector 选优）。
- `tournament` → 加载 `@pattern-tournament`（N 候选两两淘汰 → 冠军）。

无论哪种模式：你只串联、交付物写 harness 总线、三件套留 .trae/specs、最小更新 board、超界/不确定 escalate。pattern playbook 是你的子流程库，不是 SubAgent；SubAgent 只能承担 generator/evaluator/decision/classifier/synthesizer/selector 等叶子角色。

### 3. 运行 /spec 产出三件套（脚手架，留在 .trae/specs），交付物写总线
1. 读取 `{harness_dir}templates/spec.skeleton.md`、`tasks.skeleton.md`、`checklist.skeleton.md`。
2. 运行 `/spec`，按骨架生成当前 Stage 的 spec.md、tasks.md、checklist.md——这三件套是**过程脚手架，放原生 `.trae/specs/`** 即可，G/E/D 子代理在**本对话内**可直接读取，或由你在派发 prompt 中内联摘要。
3. **三件套不必复制/持久化到 `{harness_dir}`、不进 git**；对话结束即弃，丢了能靠 milestone-plan + 重跑 /spec 再生。
4. 只把**交付物/证据**写入总线 `{harness_dir}milestones/{milestone}/stages/{stage}/`：`contract.md`、`gen.md`、`eval.md`、`decision.md`、`browser-check.md`。验收标准放 contract.md，子代理据此验收（不依赖持久化的 spec）。

### 4. 自检门
继续前必须同时满足：
- spec.md 包含 Stage 目标、范围边界、验收标准、依赖、非功能性需求五个部分。
- tasks.md 包含 [GENERATOR]、[EVALUATOR]、[DECISION] 顺序步骤，或当前 pattern 所需的等价叶子角色步骤。
- checklist.md 是完成性 gate，且与 tasks.md 的关键完成项 1:1 对应。
- 三件套没有残留未替换的关键占位符。

任一失败：停止执行，报告缺口，不派发子角色。

### 5. 确定 contract.md（按 Stage 的 contract_mode）
你（Stage Orchestrator）只负责**串联流程**：派发子代理、读裁决、决定下一步；**不亲自实现、不评分、不裁决**。
先看该 Stage 在 milestone-plan.md 里的 `contract_mode`：

- **planned（默认）**：验收标准在规划期已明确（需求清晰 / 联调阶段，骨架与模块契约已定）。你直接据 milestone-plan 的"验收标准要点" + 既定契约，写 `contract.md`（目标/验收要点/边界，一次标注）。**不加共识子阶段**。
- **codraft（可选）**：验收标准需先有草稿才能定（早期/探索性开发）。先跑 **Contract 共识子阶段**：
  1. 【派发独立 SubAgent，加载 @generator-role】出一版**草稿/接口骨架** + 提议验收标准 → `gen-draft.md`。
  2. 【派发独立 SubAgent，加载 @evaluator-role】以测试视角 review 草稿 + 敲定可机械检查的验收标准 → 由你写入 `contract.md`。
  3. 共识达成后再进入下面的正式对抗轮。
- 若 force_contract=false：跳过 contract，Generator 直接按当前 Stage 三件套上下文实现。

### 5.5 MCP 访问模式（verification_mode=full 时）
读取项目/Stage 的 `mcp_access_mode`（默认 `orchestrator_delegated`）：

- **orchestrator_delegated（默认）**：若该 Stage 需要浏览器/MCP 查证，由你代行 MCP，把截图/日志/结论写入 `browser-check.md`，Evaluator 读取该文件纳入评分。
- **evaluator_shell_bridge（实验增强，需 AP19 真机验证）**：运行 `{harness_dir}mcp-bridge/check.sh --json`，读取 `{harness_dir}mcp-bridge/manifest.json`，把可用白名单命令和 MCP→Shell 翻译表写入 `contract.md` 的 `mcp_bridge_capabilities` / `mcp_to_shell_translation`。bridge 可用时不要代行浏览器观察；Evaluator 在自己的 SubAgent 上下文内按翻译表把 MCP/browser 意图改写成 RunCommand，并把证据写入 `eval.md`。bridge 不可用时，按 contract 策略 fallback 到 `orchestrator_delegated`，或暂停并要求 `[BLOCKED: MCP bridge unavailable]`。

禁止自由扫描未知 MCP。只能信任 `manifest.json` + `check.sh --json` 的确定性结果。

### 6. 顺序派发对抗步骤
按 tasks.md 顺序执行，最多 {max_adversarial_rounds} 轮：
1. 【派发独立 SubAgent，加载 @generator-role】[GENERATOR] 按 contract.md 进行 TDD 实现 → `gen.md`。
2. **（仅 verification_mode=full 且该 Stage 需浏览器验证）**按 `mcp_access_mode` 处理：
   - `orchestrator_delegated`：由**你（Stage Orchestrator）代行 MCP 浏览器验证**，把截图/日志/结论写入 `browser-check.md`。这属"取证"，不算你兼任评分。
   - `evaluator_shell_bridge`：你不做浏览器观察，只把 `mcp_bridge_capabilities` 和 `mcp_to_shell_translation` 写入 contract；Evaluator 自己按翻译表把 MCP/browser 意图改写成白名单 shell 命令查证，证据写入 `eval.md`。
3. 【派发独立 SubAgent，加载 @evaluator-role】[EVALUATOR] 进行四维业务质量评估（用 RunCommand 跑测试/Lint；按 contract 读取 `browser-check.md` 或使用 MCP bridge 自查）→ `eval.md`。
4. 【派发**独立** SubAgent，加载 @decision-role】[DECISION] 只读 gen.md+eval.md+contract.md → `decision.md`，裁决 pass/retry/escalate。
   - Decision 必须是独立子代理（与 G/E 隔离、看不到双方对话），保证中立盲审；**你（Stage Orchestrator）不得自己兼任裁决**。

**根据 decision.md 的 verdict 决定下一步（这是你的核心编排职责）**：
- `pass` → 进入 checklist 完成性 gate，回写 board=passed。
- `retry`（且 rounds < {max_adversarial_rounds}）→ 你**有权修改 tasks.md**：在其中追加一轮返工任务（标注 round N+1 与 Decision 给的 `retry_focus`），然后**重新派发 [GENERATOR]**（带 retry_focus），rounds+1，再走 E→D。
- `escalate`（或 rounds 达上限仍未过）→ 暂停，回写 board=escalated，请求人类裁决。
- 你**不能**让任何子代理自我循环；多轮返工只能由你**手动重新派发**（无自动 loop）。

### 7. 回写 state-board.json
根据 decision.md 回写 `{harness_dir}state-board.json`（**最小更新原则**：只改当前 Stage 那一条记录的字段，不整体重写、不动其它 Stage，确保 git 合并不冲突）：
- status: spec_ready / in_progress / passed / failed / escalated
- rounds
- last_decision: pass | retry | escalate | null
- artifacts: contract/gen/eval/decision/browser_check 的实际路径（三件套留在 .trae/specs，不记入持久 artifacts）

> 并发说明：Stage 并发 = 人类开多个独立对话推进，非自动调度。投递某 Stage 前须确认其 `depends_on` 全部 passed，且与在途 Stage 无源文件交集（代码冲突由人工把关）。

## 完成条件
- checklist.md 的完成性 gate 通过。
- decision.md verdict=pass。
- state-board.json 已回写当前 Stage 的最终状态和产物路径。
