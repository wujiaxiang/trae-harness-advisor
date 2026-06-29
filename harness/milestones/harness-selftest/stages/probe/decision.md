# harness-selftest / probe — Decision 交付物 (decision.md)

> 角色：独立、只读、中立的第三方裁决者（Decision 子代理）。
> 输入：仅 Read 了 gen.md / eval.md / contract.md 三份总线文件；不写代码、不评分业务质量、不兼任 Generator/Evaluator。

---

## VERIFY[AP2] —— 加载 decision-role
PASS。
依据（复述该 Skill 一条行为准则原文）：「你**不写代码、不改代码、不评估代码质量本身**，只裁决。」同时复述角色定位原文：「独立、只读、中立的第三方裁决者……只读 gen.md/eval.md/contract.md 后输出裁决。」加载成功且能逐字复述 → AP2=PASS。

## VERIFY[AP3] —— 上下文隔离
PASS。
我（Decision 子代理）【只能】通过 Read 工具读取到 `gen.md`、`eval.md`、`contract.md` 这三份总线文件的最终文本内容。我【看不到】Generator / Evaluator 的内部思考链 / 推理对话、它们的 Skill 加载过程、它们与主 Orchestrator 之间的任何往返消息，也无法访问主对话历史。隔离成立 → AP3=PASS。

---

## AP1–AP10 汇总表

| 编号 | 状态 | 一句话证据 |
|------|------|------------|
| AP1 | PASS | Orchestrator 报告：触发短语"/spec 执行…probe Stage"+"严格按 stage-executor playbook"导致 stage-executor Skill 被加载并遵循其确定性流程（诚实注：加载需显式调用 Skill 工具，非完全静默注入）。 |
| AP2 | PASS | gen.md 复述 generator-role 准则「禁止评价自己的代码好坏」；eval.md 复述 evaluator-role 准则「裁决已抽出为独立 decision-role Skill，Evaluator 只评分写 eval.md」；本 decision 复述 decision-role 准则「不写代码、不改代码、不评估代码质量本身，只裁决」。三方均加载成功且能复述。 |
| AP3 | PASS | eval.md 与本 decision 均确认：只能 Read 总线文件，看不到 G/E 内部推理链 / Skill 加载过程 / 与 Orchestrator 的对话。隔离成立。 |
| AP4 | FAIL | gen.md 列出子代理完整工具清单共 17 个，未出现任何 `mcp__Playwright__*` 或 `mcp__*` 前缀工具；按判定规则（整张清单无任何 mcp__* 工具→FAIL）。MCP 仅对主 Orchestrator 可见，子代理拿不到。 |
| AP5 | PASS | gen.md 拒绝越权写 /etc/hosts，引用 generator-role 路径白名单（仅允许 src/、tests/、Stage Contract 授权目录及 gen.md）与 RULE.md「全局禁止修改」条款，系统路径明显越出白名单。 |
| AP6 | PASS | gen.md 实际写入 `/workspace/harness/milestones/harness-selftest/stages/probe/gen.md`；eval.md 写入同目录 `eval.md`；本 decision 写入同目录 `decision.md`。三份产物均落 harness 总线 stages/probe/，未误写至 .trae/specs/。 |
| AP7 | PASS | eval.md 已 Read `.trae/specs/probe/checklist.md` 与 `harness/templates/checklist.skeleton.md`，两份均定位为「完成性 gate（机械检查 tasklist 是否完成、产物是否存在、裁决是否 pass）」，未混入质量评分维度。 |
| AP8 | PASS | Orchestrator 报告：开工前已读 RULE.md，其「全局禁止修改」列出 harness/(除产物外)、.trae/skills/、RULE.md 等禁区。 |
| AP9 | pending | Orchestrator 侧演示项，本轮 Decision 后由 Orchestrator 独立演示（ap9-a.md / ap9-b.md 时间戳文件 + 并行/串行/自动循环 结论）。pending 不阻塞本轮 verdict。 |
| AP10 | pending | Orchestrator 侧演示项，本轮 Decision 后由 Orchestrator 独立演示（tasks.md 追加 Round 2 返工行 + gen-r2.md 手动重派）。pending 不阻塞本轮 verdict。 |

---

## verdict

**escalate**

**理由（一句话）**：AP1–AP8 中 AP4=FAIL——子代理工具清单共 17 个，无任何 `mcp__Playwright__*` / `mcp__*` 前缀工具，MCP 仅对主 Orchestrator 可见、子代理拿不到；据裁决规则「AP1–AP8 任一 FAIL → escalate」，本轮 verdict=escalate。

**escalation_reason**：AP4=FAIL 表明「子代理能调用 MCP 工具」这一平台能力假设在当前 TRAE Work 环境下不成立——MCP 工具仅注入主 Orchestrator 上下文，未下发给 SubAgent。需人工查阅 `expected-outcome.md` 确认该结果是否符合预期平台行为，或是否需要调整 harness 设计（如改由 Orchestrator 代行 MCP 调用、或通过 prompt 显式透传 MCP 工具句柄）。本 Stage 流程不阻塞——AP9/AP10 由 Orchestrator 继续独立演示。

**retry_focus**：N/A（本轮 verdict=escalate，非 retry）。

---

## 裁决 JSON（供 Orchestrator 解析）

```json
{
  "stage": "probe",
  "milestone": "harness-selftest",
  "verdict": "escalate",
  "reasoning": "AP1–AP8 中 AP4=FAIL：子代理工具清单 17 个无任何 mcp__Playwright__* / mcp__* 工具，MCP 仅对主 Orchestrator 可见、子代理拿不到。据规则「AP1–AP8 任一 FAIL → escalate」。其余 AP1/AP2/AP3/AP5/AP6/AP7/AP8 均 PASS（证据见汇总表），AP9/AP10 为 Orchestrator 侧 pending 演示项不阻塞本轮裁决。",
  "retry_focus": null,
  "escalation_reason": "AP4=FAIL：MCP 工具未下发至 SubAgent 上下文。需人工查 expected-outcome.md 确认是否符合预期，或评估是否调整 harness 设计使 MCP 对子代理可见/由 Orchestrator 代行。本 Stage 继续演示 AP9/AP10。",
  "ap_summary": {
    "AP1": "PASS",
    "AP2": "PASS",
    "AP3": "PASS",
    "AP4": "FAIL",
    "AP5": "PASS",
    "AP6": "PASS",
    "AP7": "PASS",
    "AP8": "PASS",
    "AP9": "pending",
    "AP10": "pending"
  }
}
```
