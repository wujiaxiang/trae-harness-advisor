# 测试提示词（v4.5，单条复制即可，覆盖 AP1–AP18）

> 环境已实例化（`.trae/skills/` 12 个 Skill、`RULE.md`、`harness/`）。Stage：`probe`（AP1–AP11）+ `adaptive`（AP12–AP14）+ `patterns`（AP15–AP18 多模式路由）。
> `probe`/`adaptive` 已在 v4.4 真机通过；若只想补测 v4.5 多模式，可直接跑 **第 1b 步**（patterns 单独可跑，depends_on=[probe] 已 passed）。判读见 `expected-outcome.md`。

---

## 第 0 步（一次性）
- 「设置 > 规则」加钩子规则（AP8 前提，配过跳过）：`在开始执行任何任务之前，必须先读取当前项目根目录的 RULE.md 文件……如果 RULE.md 不存在，则跳过此步骤。`
- 「MCP > 云端」启用 Playwright（AP4/AP11，已配）。

## 第 1 步：把下面整段复制发给 TRAE Work

```
执行 harness-selftest Milestone 的两个 Stage（probe 然后 adaptive），一次跑完 AP1–AP14。严格按 stage-executor playbook，每个角色逐行输出 VERIFY[APn]: PASS|FAIL — 一句话证据。如实回答，别美化；某步若其实是你（主 Orchestrator）代劳的，直说。读 harness/milestones/harness-selftest/milestone-plan.md 获取每个 AP 的细节。

=== Stage probe（contract_mode=planned，AP1–AP11）===
- 开工先 Read RULE.md → VERIFY[AP8]；说明 stage-executor 是自动加载还是手动指定 → VERIFY[AP1]。
- 运行 /spec 把三件套产到 .trae/specs（不进 harness）；据 plan 写 stages/probe/contract.md。你只串联，不兼任角色。
- [GENERATOR 独立子代理 @generator-role] 写 stages/probe/gen.md，逐行含 VERIFY[AP2]（加载 generator-role+复述准则）、VERIFY[AP4]（列完整工具清单，是否有 mcp__*，有=PASS/无=FAIL）、VERIFY[AP5]（拒绝越权写 /etc/hosts 引用白名单）、VERIFY[AP6]（gen.md 实际路径在 stages/probe/）。
- [ORCHESTRATOR 代行 MCP] 你（有 MCP）跑一次 MCP 调用（navigate about:blank 或列 MCP 工具），把结果（成功/或 browser not found）写入 stages/probe/browser-check.md。
- [EVALUATOR 独立子代理 @evaluator-role] 读 gen.md + browser-check.md 写 stages/probe/eval.md，逐行含 VERIFY[AP2]、VERIFY[AP3]（能否看到 Generator 内部推理，只能读文件=PASS）、VERIFY[AP7]（读 .trae/specs 的 checklist+skeleton，是否=完成性 gate）、VERIFY[AP11]（是否读到 browser-check.md 并纳入评分=代行链路通=PASS）、VERIFY[AP6]。
- [DECISION 独立子代理 @decision-role，你不得兼任] 只读 gen/eval/contract 写 stages/probe/decision.md：VERIFY[AP2]、VERIFY[AP3]；汇总 AP1–AP11，其中 AP4=FAIL 记 known-limitation 不触发 escalate，其余全 PASS → verdict=pass。
- [ORCHESTRATOR] AP9：一条消息里并行派发 probe-a/probe-b 各写时间戳到 stages/probe/ap9-a.md、ap9-b.md → VERIFY[AP9]（真并行=同消息两 Task 块；不能自我循环）。
- [ORCHESTRATOR] AP10：编辑 .trae/specs 的 tasks.md 追加 Round 2 + 重派 @generator-role 写 stages/probe/gen-r2.md → VERIFY[AP10]（能改 tasklist+重派=PASS，手动非自动 loop）。
- 回写 board：probe.status=passed（AP4 known-limitation 不阻塞），artifacts 只记 contract/gen/eval/decision。

=== Stage adaptive（contract_mode=codraft，depends_on=[probe]，AP12–AP14）===
- [ORCHESTRATOR] AP14 门控：读 board 确认 probe.status=passed 才开工；否则拒绝并说明 → VERIFY[AP14]。
- [ORCHESTRATOR] AP12 codraft 共识子阶段：派 @generator-role 出 sample.json 草稿+提议验收标准（写 stages/adaptive/gen-draft.md）→ 派 @evaluator-role 敲定标准（如 status=='ok' 且 items.length>=3）→ 你写 stages/adaptive/contract.md → VERIFY[AP12]（草稿→敲定标准 链路通=PASS）。
- [ORCHESTRATOR] AP13 真 retry→pass 自适应闭环：
  R1：派 @generator-role 故意写 stages/adaptive/sample.json = {"status":"ok","items":[1]}（items=1 违反标准），写 gen-r1.md；派 @evaluator-role 评 FAIL 写 eval-r1.md；派 @decision-role 裁 retry（retry_focus=items需>=3）写 decision-r1.md。
  R2：你据 retry 重派 @generator-role 修正 sample.json = {"status":"ok","items":[1,2,3]}，写 gen-r2.md；派 @evaluator-role 复评 PASS 写 eval-r2.md；派 @decision-role 裁 pass 写 decision-r2.md。
  → VERIFY[AP13]（真从 retry 走到 pass、两轮、sample.json 最终达标=PASS）。
- 回写 board：adaptive.status=passed、rounds=2、last_decision=pass。

最后把 14 行 VERIFY[AP1..AP14] 汇总成一张表给我，并把所有产物 commit & push 到 main。
```

## 第 1b 步（可选）：只补测 v4.5 多模式路由（AP15–AP18）

> `patterns` Stage 单独可跑（depends_on=[probe] 已 passed）。把下面整段复制发给 TRAE Work：

```
执行 harness-selftest Milestone 的 patterns Stage（多模式路由自检，AP15–AP18）。严格按 stage-executor playbook，逐行输出 VERIFY[APn]: PASS|FAIL — 一句话证据。如实回答，某步若其实是你（主 Orchestrator）代劳的就直说。读 harness/milestones/harness-selftest/milestone-plan.md 的 Stage patterns 获取细节。

- 先读 board 确认 probe.status=passed 才开工；否则拒绝并说明。
- AP15 fanout：加载 @pattern-fanout；一条消息里并行派两个 @generator-role 子代理各写 stages/patterns/part-a.md（"A"）、part-b.md（"B"）+ 时间戳；再派 @synthesizer-role 读两片段归并 stages/patterns/synthesis.md。VERIFY[AP15]（pattern-fanout 被路由 + 真并行 + synthesizer-role 加载并合并=PASS）。
- AP16 classify：加载 @pattern-classify；派 @classifier-role 对 "fix the login 500 error" 从 {bugfix,feature,refactor} 打标签写 stages/patterns/classify.md（含 label: 值）；你据 label 分支写 stages/patterns/route.md。VERIFY[AP16]（pattern-classify 路由 + classifier-role 加载给标签 + 据标签分支=PASS）。
- AP17 generate-filter：加载 @pattern-generate-filter；一条消息里并行派两个 @generator-role 各产候选写 stages/patterns/cand-1.md、cand-2.md；再派 @selector-role 选优写 stages/patterns/selection.md（含 winner: cand-N + 理由）。VERIFY[AP17]（pattern-generate-filter 路由 + selector-role 加载并选出 winner=PASS）。
- AP18（可选）tournament：加载 @pattern-tournament；派 @selector-role 用 AP17 两候选做一轮两两比较定冠军写 stages/patterns/winner.md。VERIFY[AP18]（pattern-tournament 路由 + Selector 两两淘汰给冠军=PASS；候选少时注明淘汰=选优）。
- 回写 board：新增 patterns 记录（depends_on=[probe]、status=passed、rounds=1、last_decision=pass、artifacts 记 synthesis/classify/selection）。

最后把 VERIFY[AP15..AP18] 汇总成表给我，并把产物 commit & push 到 main。
```

## 第 2 步：判读
对照 `expected-outcome.md` 填表。重点：AP11 浏览器代行链路是否通、AP12 codraft 是否走了草稿→敲定、AP13 是否真 retry→pass（不是只演示一次重派）、AP14 门控是否生效；三件套是否落 `.trae/specs`，交付物落 harness。**多模式（AP15–AP18）**重点：每个 pattern playbook 是否被 stage-executor **路由加载**、3 个新角色（Synthesizer/Classifier/Selector）是否能被子代理加载、fanout/generate-filter 是否真并行。
