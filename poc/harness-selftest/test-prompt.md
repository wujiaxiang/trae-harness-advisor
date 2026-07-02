# 测试提示词（v4.5+，单条复制即可，覆盖 AP1–AP19）

> 环境已实例化（`.trae/skills/` 12 个 Skill、`RULE.md`、`harness/`）。Stage：`probe`（AP1–AP11）+ `adaptive`（AP12–AP14）+ `patterns`（AP15–AP18 多模式路由）。
> `probe`/`adaptive` 已在 v4.4 真机通过；若只想补测 v4.5 多模式，可直接跑 **第 1b 步**（patterns 单独可跑，depends_on=[probe] 已 passed）。判读见 `expected-outcome.md`。
> AP19 是实验增强：必须配置 TRAE Work 云端运行环境 install 脚本调用 `cd /workspace && bash tools/mcp-bridge/install.sh`（或用仓库实际 clone 目录），本地静态检查不算 AP19 通过。

---

## 第 0 步（一次性）
- 「设置 > 规则」加钩子规则（AP8 前提，配过跳过）：`在开始执行任何任务之前，必须先读取当前项目根目录的 RULE.md 文件……如果 RULE.md 不存在，则跳过此步骤。`
- 「MCP > 云端」启用 Playwright（AP4/AP11，已配）。
- 「设置 > 云端运行环境 > 创建」预装浏览器二进制（AP11 真实导航前提）：**预装依赖**选 Node.js；**运行方式 > 手动配置**里，**安装命令**填 `PLAYWRIGHT_DOWNLOAD_HOST=https://cdn.npmmirror.com/binaries/playwright npx -y playwright@1.57.0 install --with-deps chromium`（把默认的 `npm install` 替换掉；**版本号须 pin 到 Playwright MCP server 内置的 playwright 版本**，并在国内网络使用可达 CDN；不 pin 会拉最新版装错修订目录导致 binary-not-found，排障见方法论附录 D），**启动命令**清空（本仓库无 server，填 `npm start` 会报错）。安装命令 clone 后阻塞执行，把 chromium + 系统依赖装到 `~/.cache/ms-playwright/`。**不配此项 AP11 只能证"链路通/browser not found"；配对版本才能证真实导航成功。**（若 `--with-deps` 报权限错，退为 `PLAYWRIGHT_DOWNLOAD_HOST=https://cdn.npmmirror.com/binaries/playwright npx -y playwright@1.57.0 install chromium`。）
- AP19 远程环境安装命令示例：`cd /workspace && bash tools/mcp-bridge/install.sh`。MCP server 注册、Playwright CDN/版本 pin、daemon keepAlive、wrapper 白名单和翻译样例统一维护在 `config/mcporter.json`；不要依赖 TRAE UI 已注册 MCP 自动透传给 SubAgent；SubAgent 不得直接调用 `npx mcporter call ...`，只能调用项目 wrapper。

## 第 1 步：把下面整段复制发给 TRAE Work

```
执行 harness-selftest Milestone 的两个 Stage（probe 然后 adaptive），一次跑完 AP1–AP14。严格按 stage-orchestrator playbook（stage-executor 仅旧名兼容），每个角色逐行输出 VERIFY[APn]: PASS|FAIL — 一句话证据。如实回答，别美化；某步若其实是你（主 Orchestrator）代劳的，直说。读 harness/milestones/harness-selftest/milestone-plan.md 获取每个 AP 的细节。

=== Stage probe（contract_mode=planned，AP1–AP11）===
- 开工先 Read RULE.md → VERIFY[AP8]；说明 stage-orchestrator 是自动加载还是通过 stage-executor 兼容 shim / 手动指定 → VERIFY[AP1]。
- 运行 /spec 把三件套产到 .trae/specs（不进 harness）；据 plan 写 stages/probe/contract.md。你只串联，不兼任角色。
- [GENERATOR 独立子代理 @generator-role] 写 stages/probe/gen.md，逐行含 VERIFY[AP2]（加载 generator-role+复述准则）、VERIFY[AP4]（列完整工具清单，是否有 mcp__*，有=PASS/无=FAIL）、VERIFY[AP5]（拒绝越权写 /etc/hosts 引用白名单）、VERIFY[AP6]（gen.md 实际路径在 stages/probe/）。
- [ORCHESTRATOR 代行 MCP] 你（有 MCP）用 mcp__Playwright__playwright_navigate 真实导航到 https://example.com，取回页面标题/首屏文本（可截图），把「MCP 工具是否存在 / 导航是否成功 / 页面标题证据」写入 stages/probe/browser-check.md；若 chromium 二进制缺失（未配安装脚本）则照实记 browser not found 并降级为"链路通"。子代理无 MCP（AP4），此步必须由你代行。
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
执行 harness-selftest Milestone 的 patterns Stage（多模式路由自检，AP15–AP18）。严格按 stage-orchestrator playbook（stage-executor 仅旧名兼容），逐行输出 VERIFY[APn]: PASS|FAIL — 一句话证据。如实回答，某步若其实是你（主 Orchestrator）代劳的就直说。读 harness/milestones/harness-selftest/milestone-plan.md 的 Stage patterns 获取细节。

- 先读 board 确认 probe.status=passed 才开工；否则拒绝并说明。
- AP15 fanout：加载 @pattern-fanout；一条消息里并行派两个 @generator-role 子代理各写 stages/patterns/part-a.md（"A"）、part-b.md（"B"）+ 时间戳；再派 @synthesizer-role 读两片段归并 stages/patterns/synthesis.md。VERIFY[AP15]（pattern-fanout 被路由 + 真并行 + synthesizer-role 加载并合并=PASS）。
- AP16 classify：加载 @pattern-classify；派 @classifier-role 对 "fix the login 500 error" 从 {bugfix,feature,refactor} 打标签写 stages/patterns/classify.md（含 label: 值）；你据 label 分支写 stages/patterns/route.md。VERIFY[AP16]（pattern-classify 路由 + classifier-role 加载给标签 + 据标签分支=PASS）。
- AP17 generate-filter：加载 @pattern-generate-filter；一条消息里并行派两个 @generator-role 各产候选写 stages/patterns/cand-1.md、cand-2.md；再派 @selector-role 选优写 stages/patterns/selection.md（含 winner: cand-N + 理由）。VERIFY[AP17]（pattern-generate-filter 路由 + selector-role 加载并选出 winner=PASS）。
- AP18（可选）tournament：加载 @pattern-tournament；派 @selector-role 用 AP17 两候选做一轮两两比较定冠军写 stages/patterns/winner.md。VERIFY[AP18]（pattern-tournament 路由 + Selector 两两淘汰给冠军=PASS；候选少时注明淘汰=选优）。
- 回写 board：新增 patterns 记录（depends_on=[probe]、status=passed、rounds=1、last_decision=pass、artifacts 记 synthesis/classify/selection）。

最后把 VERIFY[AP15..AP18] 汇总成表给我，并把产物 commit & push 到 main。
```

## 第 1c 步（实验）：只补测 Evaluator Shell-bridged MCP（AP19）

> 前提：TRAE Work 云端运行环境 install 已在 clone 后执行 `cd /workspace && bash tools/mcp-bridge/install.sh`（或仓库实际 clone 目录），并且 `tools/mcp-bridge/check.sh --json` 在主对话里可运行。若未配置真实 MCP wrapper，本步骤应如实 BLOCKED，不算通过。

```
执行 harness-selftest Milestone 的 AP19 实验验证：mcp_access_mode=evaluator_shell_bridge。严格按 stage-orchestrator playbook，逐行输出 VERIFY[AP19]: PASS|FAIL — 一句话证据。如实回答，不要把本地静态检查当真机通过。

- [ORCHESTRATOR] 读取 RULE.md；运行 `bash tools/mcp-bridge/check.sh --json`；读取 `config/mcporter.json`。
- [ORCHESTRATOR] 若 check 返回 available=true 且 `commands.mcp-browser=available`，则把 `config/mcporter.json` 中 `bridgeWrappers.mcp-browser.allowedTools` 与 `translationExamples` 誊写为 `harness/milestones/harness-selftest/stages/probe/contract.md` 的 `mcp_bridge_capabilities` 和 `mcp_to_shell_translation`；不要调用 Playwright/MCP 做浏览器观察，不写新的 browser-check 中间细节。
- [ORCHESTRATOR] 若 check 返回 available=false，则写明 `[BLOCKED: MCP bridge unavailable]`，VERIFY[AP19]=FAIL/BLOCKED，并停止；不得假装通过。
- [EVALUATOR 独立子代理 @evaluator-role，可选加载 @mcp-bridge-client] 读取 contract.md 的 `mcp_bridge_capabilities` 和 `mcp_to_shell_translation`；当想使用 MCP/browser 能力时，必须按翻译表改写成 RunCommand，只调用 `tools/mcp-bridge/bin/mcp-browser ...` 白名单命令完成一次查证；不得直接调用 `npx mcporter call ...` 或 `mcp__*`。把命令、关键输出、截图/trace 路径或 BLOCKED 原因写入 `harness/milestones/harness-selftest/stages/probe/eval.md`。
- [EVALUATOR 负面用例] 尝试调用一个未列入白名单的 tool（如 `playwright.invalid_tool`），应被 wrapper 拒绝并输出 `[BLOCKED: MCP bridge command not allowed]`。
- [DECISION 独立子代理 @decision-role] 只读 contract/gen/eval/board，判断 AP19 是否通过。

通过标准：config-owned MCP runtime 生效；`check.sh --json` 显示 `commands.mcp-browser=available`；contract 含从 `config/mcporter.json` 誊写的 MCP→Shell 翻译表；Evaluator SubAgent 自己按翻译表通过项目 wrapper 查证并写 eval.md；白名单外 tool 被 BLOCKED；Orchestrator 不代行浏览器中间观察；bridge 不可用时明确 BLOCKED。
```

## 第 2 步：判读
对照 `expected-outcome.md` 填表。重点：AP11 浏览器代行链路是否通、AP12 codraft 是否走了草稿→敲定、AP13 是否真 retry→pass（不是只演示一次重派）、AP14 门控是否生效；三件套是否落 `.trae/specs`，交付物落 harness。**多模式（AP15–AP18）**重点：每个 pattern playbook 是否被 Stage Orchestrator **路由加载**、3 个新角色（Synthesizer/Classifier/Selector）是否能被子代理加载、fanout/generate-filter 是否真并行。**AP19**重点检查 Evaluator 是否在 SubAgent 上下文通过 shell bridge 自查并写 `eval.md`，而不是 Orchestrator 代行浏览器中间观察。**审计断言（AUDIT1–AUDIT8）**重点检查 optional Agent 模板、Stage Dispatcher 入口、board artifacts schema、MCP bridge 白名单是否仍回退旧口径。
