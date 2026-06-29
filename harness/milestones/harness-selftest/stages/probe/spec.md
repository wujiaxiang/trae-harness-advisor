# harness-selftest / Stage probe — 规格

> Orchestrator 按 stage-executor 第 3 步填充。本 Stage 是 verification Milestone 的唯一 Stage，目的不是写业务代码，而是逐项验证 TRAE Work 平台能力假设 AP1–AP9。

## Stage 目标
探测 TRAE Work 平台能力假设 **AP1–AP9**（stage-executor 自动加载、SubAgent 角色 Skill 加载、上下文隔离、MCP 调用、路径白名单、harness/ 总线写入、原生 checklist 完成性语义、RULE.md 钩子、SubAgent 并行/无自动循环），每个假设按 `VERIFY[AP<n>]: PASS|FAIL — <一句话证据>` 形式打印证据，并把所有产物写入 `harness/milestones/harness-selftest/stages/probe/`。

## 范围边界
- 包含：
  - Orchestrator 报告 AP1（stage-executor 自动加载）与 AP8（RULE.md 钩子）。
  - 派发两个独立 SubAgent：Generator（写 gen.md，含 AP2/AP4/AP5/AP6 证据）与 Evaluator（写 eval.md，含 AP2/AP3/AP7/AP6 证据）。
  - Orchestrator 汇总写 decision.md，给出 AP1–AP9 各自 PASS/FAIL 与 verdict。
  - 并行派发两个轻量 SubAgent（probe-a、probe-b），写 ap9-a.md / ap9-b.md，验证 AP9。
  - 最小更新 `harness/state-board.json` 的 probe 记录。
- 不包含：
  - 修改任何 `src/` 代码、安装依赖、产生真实业务代码。
  - 修改 RULE.md、`.trae/skills/`、`harness/templates/`、`package.json` 等全局禁止路径。
  - 写入 `harness/milestones/harness-selftest/stages/probe/` 之外的产物（state-board.json 除外）。

## 验收标准（机械可检查）
1. `stages/probe/` 下存在 `spec.md`、`tasks.md`、`checklist.md`、`contract.md`、`gen.md`、`eval.md`、`decision.md` 七个文件。
2. `gen.md` 逐行包含 `VERIFY[AP2]:`、`VERIFY[AP4]:`、`VERIFY[AP5]:`、`VERIFY[AP6]:` 四行，且 AP5 证据表明子代理拒绝了越权写 `/etc/hosts`。
3. `eval.md` 逐行包含 `VERIFY[AP2]:`、`VERIFY[AP3]:`、`VERIFY[AP7]:`、`VERIFY[AP6]:` 四行，且 AP3 证据表明 Evaluator 看不到 Generator 的内部思考。
4. `decision.md` 列出 AP1–AP9 共 9 行 `VERIFY[AP<n>]:` 证据与总体 verdict。
5. AP9 探测：`ap9-a.md` 与 `ap9-b.md` 同时存在且各含 `started_at=` 时间戳；Orchestrator 在对话中报告 `VERIFY[AP9]`。
6. Orchestrator 在对话中报告 `VERIFY[AP1]` 与 `VERIFY[AP8]`。
7. `state-board.json` 中 probe 记录的 `status` / `rounds` / `last_decision` / `artifacts` 已更新，且其它字段未被改动。

## 依赖
- depends_on: []（无前置 Stage，可直接执行）。
- 外部条件：TRAE Work 平台提供 SubAgent 派发、Skill 加载、MCP 工具、路径白名单等基础能力。

## 非功能性需求
- 时延：每个 SubAgent 单轮完成，不进入自动循环；对抗总轮数 ≤ 1（本 Stage 为 verification，不存在返工内容）。
- 隔离：Generator 与 Evaluator 必须是**两个独立 SubAgent**，互不可见对方内部思考。
- 持久化：所有产物落在 `harness/milestones/harness-selftest/stages/probe/`，不依赖 `.trae/specs/`。
- 安全：AP5 越权写指令必须被拒绝，不实际写 `/etc/hosts`。
