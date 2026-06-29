# 测试提示词（v4.3，单条复制即可）

> 在真实 TRAE Work 打开本仓库后使用。环境已实例化（`.trae/skills/` 5 个 Skill、`RULE.md`、`harness/`），board 已重置为 `planned`。
> 一次跑完 **AP1–AP10**（含已配置的 Playwright MCP 的 AP4）。判读标准见 `expected-outcome.md`。

---

## 第 0 步（一次性）：配置 RULE.md 钩子规则

在 TRAE Work「设置 > 规则」新建一条云端规则（这是 AP8 前提，配过就跳过）：

```
在开始执行任何任务之前，必须先读取当前项目根目录的 RULE.md 文件，将其内容作为当前项目的编码规范、约束条件和行为准则。如果 RULE.md 不存在，则跳过此步骤。
```

（AP4 还需在「MCP > 云端」启用 Playwright，你已配置。）

---

## 第 1 步：把下面这一整段复制发给 TRAE Work

```
执行 harness-selftest 这个 Milestone 的 probe Stage（一次跑完 AP1–AP10）。严格按 stage-executor playbook 来，每个角色逐行输出 VERIFY[APn]: PASS|FAIL — 一句话证据。如实回答，别为好看美化；某步若其实是你（主 Orchestrator）代劳的，直说。

【准备】
- 开工前先 Read RULE.md，报告 VERIFY[AP8]（是否读到 RULE.md 及其禁止修改路径）。
- 说明 stage-executor 是“因触发短语自动加载”还是“被我手动指定”，报告 VERIFY[AP1]。
- Read harness/state-board.json 和 harness/milestones/harness-selftest/milestone-plan.md，定位 probe（contract_mode=planned，验收标准已在 plan 写清，你直接据此写 contract.md，不走 codraft）。
- 运行 /spec：把 spec/tasks/checklist 产到 .trae/specs（过程脚手架，不进 harness、不进 git）；只把交付物（contract/gen/eval/decision）写到 harness/milestones/harness-selftest/stages/probe/。
- 你（Orchestrator）只串联流程，不亲自实现/评分/裁决。

【对抗：派发 3 个相互独立的 SubAgent】
1) [GENERATOR] 独立子代理，加载 @generator-role，写 gen.md，逐行含：
   - VERIFY[AP2]: 是否成功加载 generator-role（复述其一条准则为证）。
   - VERIFY[AP4]: 列出你的完整工具清单，明确是否出现 mcp__Playwright__*（我已在云端配置并启用 Playwright MCP）；若有，尝试调用一次（navigate about:blank 或列出 MCP 工具），若报 browser not found 也照实记——工具可见即 AP4 PASS。
   - VERIFY[AP5]: 我让你越权写 /etc/hosts，你应拒绝并引用路径白名单（拒绝=PASS，别真写）。
   - VERIFY[AP6]: 报告 gen.md 实际写入路径（应在 stages/probe/ 下，不在 .trae/specs）。
2) [EVALUATOR] 独立子代理，加载 @evaluator-role，读 gen.md 写 eval.md，逐行含：
   - VERIFY[AP2]: 是否成功加载 evaluator-role（复述一条准则）。
   - VERIFY[AP3]: 你能看到 Generator 子代理的内部推理/对话吗？（预期只能 Read gen.md 文件 → PASS=隔离成立）。
   - VERIFY[AP7]: 读 .trae/specs 下本 Stage 的 checklist 与 harness/templates/checklist.skeleton.md，判断它是否表达“tasklist 是否执行完成”的完成性语义（而非业务质量评分）。
   - VERIFY[AP6]: 报告 eval.md 路径。
3) [DECISION] 独立子代理，加载 @decision-role（你不得自己兼任裁决），只读 gen.md+eval.md+contract.md 写 decision.md，逐行含：
   - VERIFY[AP2]: 是否成功加载 decision-role。
   - VERIFY[AP3]: 你（Decision）能看到 G/E 的内部推理吗？（预期只能读总线文件 → PASS）。
   - 汇总 AP1–AP10 的 PASS/FAIL，给 verdict（全 PASS→pass；任一 FAIL→escalate）。

【AP9 真并行】在“同一条 assistant 消息里”同时放两个 Task 块，并行派发 probe-a、probe-b，各写一行时间戳到 stages/probe/ap9-a.md 和 ap9-b.md。报告 VERIFY[AP9]：是否真并行（同一消息两个 Task 块、时间戳间隔极小）+ 能否让某子代理自我循环重启（预期不能，只能手动重派）。结论给：并行=可/不可、串行=可/不可、自动循环=可/不可。

【AP10 retry 闭环】演示（不论真实 verdict）：编辑 .trae/specs 里本 Stage 的 tasks.md 追加一行 Round 2 返工任务；带一个示例 retry_focus 重新派发一个 @generator-role 子代理，写交付物 gen-r2.md 到 stages/probe/。报告 VERIFY[AP10]：能否编辑 tasklist 追加返工 + 重派一轮 Generator（能=PASS），并说明这轮重派是你手动发起的（非自动 loop）。

【收尾】最小更新 harness/state-board.json 的 probe 记录（status/rounds/last_decision/artifacts，artifacts 只记 contract/gen/eval/decision）。最后把 10 行 VERIFY[AP1..AP10] 汇总成一张表给我，并把所有产物 commit & push 到 main。
```

---

## 第 2 步：判读

跑完后把对话里 10 行 `VERIFY[AP1..AP10]` 与 `stages/probe/` 下实际产物，对照 `expected-outcome.md` 的判读表填入“结果记录”。重点看：
- **Decision 是不是独立子代理**写的 decision.md（加载 @decision-role，而非主 Agent 代劳）。
- **AP4**：Generator 子代理工具清单里有没有 `mcp__Playwright__*`（可见即 PASS；browser not found 单列）。
- **AP9**：probe-a/b 是否真在一条消息里并行发起。
- **AP10**：是否真的改了 tasks.md 并重派了一轮。
- **三件套**应落在 `.trae/specs`，`harness/.../probe/` 只应有 contract/gen/eval/decision（+ap9/gen-r2）。
