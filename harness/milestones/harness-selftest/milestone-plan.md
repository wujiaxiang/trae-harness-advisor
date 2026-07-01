# harness-selftest — Milestone Plan（已实例化，可直接运行）

> 自检 Milestone：在真实 TRAE Work 上一次验证 **AP1–AP18**（平台能力 + v4.4 设计行为 + v4.5 多模式编排路由）。
> 它几乎不写业务代码，只让 Orchestrator + SubAgent 打印"验证点"并把交付物写入 `harness/` 总线（三件套留 `.trae/specs/`）。
> 判读标准见 `../../../poc/harness-selftest/expected-outcome.md`。

## Milestone
- id: `harness-selftest`
- kind: `verification`
- 目标：探测平台能力（Skill 自动加载/角色加载/隔离/MCP/白名单/总线/checklist/钩子/并行/无循环）+ 验证设计行为（retry 闭环、浏览器代行、codraft 共识子阶段、真 retry→pass 自适应闭环、depends_on 门控）+ 验证 v4.5 多模式编排路由（fanout/classify/generate-filter/tournament 的 playbook 加载与新角色调度）。
- 范围边界：只写 `harness/milestones/harness-selftest/stages/{probe,adaptive,patterns}/` 下文件；不改 `src/`、不装依赖。

## 验证点清单（AP1–AP18）

| 编号 | 假设/行为 | Stage | 谁来证 |
|------|-----------|-------|--------|
| AP1 | stage-executor 按触发短语**自动加载** | probe | Orchestrator |
| AP2 | SubAgent 加载**指定角色 Skill**（generator/evaluator/decision-role） | probe | G/E/D 子代理 |
| AP3 | SubAgent **独立上下文隔离**（看不到对方推理） | probe | E/D 子代理 |
| AP4 | SubAgent 能否调 **MCP**（已知：不继承，仅主 Orchestrator 有） | probe | Generator 子代理 |
| AP5 | 路径白名单**提示词级**，越权写被拒绝 | probe | Generator 子代理 |
| AP6 | 交付物→**harness/ 总线**、三件套→`.trae/specs` | probe | 三个子代理 |
| AP7 | 原生 `checklist.md` ≈ **完成性 gate** | probe | Evaluator 子代理 |
| AP8 | **RULE.md 钩子**生效 | probe | Orchestrator |
| AP9 | SubAgent **可并行可串行、无自动循环** | probe | Orchestrator |
| AP10 | **retry 重派机制**：改 tasks.md + 手动重派一轮 | probe | Orchestrator |
| AP11 | **浏览器代行链路**（方案1）：Orchestrator 代行 MCP **真实导航 example.com** 写 `browser-check.md` → Evaluator 读取纳入评分（未预装 chromium 则降级为"链路通/browser not found"） | probe | Orchestrator + Evaluator |
| AP12 | **codraft 共识子阶段**：Generator 出草稿+提议标准 → Evaluator 敲定标准 → contract.md | adaptive | G/E 子代理 |
| AP13 | **真 retry→pass 自适应闭环**：第1轮 FAIL → Decision retry → 第2轮修正 → PASS | adaptive | Orchestrator + G/E/D |
| AP14 | **depends_on 门控**：probe 未 passed 前不开工 adaptive | adaptive | Orchestrator |
| AP15 | **fanout 路由**：Orchestrator 加载 `@pattern-fanout` → 2 个 `@generator-role` 子代理**真并行**产片段 → `@synthesizer-role` 归并 | patterns | Orchestrator + Synthesizer |
| AP16 | **classify 路由**：Orchestrator 加载 `@pattern-classify` → `@classifier-role` 子代理打标签 → Orchestrator 据标签分支 | patterns | Orchestrator + Classifier |
| AP17 | **generate-filter 路由**：Orchestrator 加载 `@pattern-generate-filter` → 2 个 `@generator-role` 候选 → `@selector-role` 选优 | patterns | Orchestrator + Selector |
| AP18 | **tournament 路由（可选）**：Orchestrator 加载 `@pattern-tournament` → `@selector-role` 两两淘汰选冠军（log2(N) 有界） | patterns | Orchestrator + Selector |

> 自检约定：**AP4 为已知平台限制（MCP 不下发子代理），记为 known-limitation，不触发 escalate、不阻塞 Stage 通过**；probe 的 Stage 通过判定 = 其余 AP（AP1-3,5-11）全 PASS。这样 probe=passed，adaptive/patterns 的 depends_on 才可被满足（用于测 AP14 门控与多模式路由）。
> **多模式约定**：`patterns` 是**多模式路由自检 Stage**——它有意在一个 Stage 内依次驱动多个 pattern playbook（正常业务 Stage 每个只标一个 `pattern`），目的是一次验证 v4.5 路由与 3 个新角色（Classifier/Synthesizer/Selector）是否可加载调度。AP18（tournament）为可选，候选数少时其淘汰=选优，与 AP17 原语重叠。
> **环境约定（AP11 真实浏览器前提）**：Playwright MCP server 只暴露工具，浏览器二进制需另装。云端跑真实导航前，在「设置 > 云端运行环境 > 手动配置」把「**安装命令**」填 `npx -y playwright@1.57.0 install --with-deps chromium`（**版本 pin 到 MCP 内置 playwright**；不 pin 会拉最新版装错修订目录 → binary-not-found，排障见方法论附录 D）、「**启动命令**」清空（本仓库无 server）。未装/版本错则 AP11 降级为"代行链路通/browser not found"，仍不阻塞 probe 通过。

---

## Stage `probe`（contract_mode: planned，depends_on: []）

Orchestrator 标注的 Contract 关键点（contract.md）：
1. 派发**三个独立 SubAgent**（generator/evaluator/decision-role）；Orchestrator 只串联、不兼任角色。
2. 每个角色逐行打印 `VERIFY[AP<n>]: PASS|FAIL — 一句话证据`。
3. **交付物**（contract/gen/eval/decision/browser-check）写 `harness/.../stages/probe/`；**三件套**（spec/tasks/checklist）由 /spec 产到 `.trae/specs/`。
4. AP4 记 known-limitation，不阻塞 probe 通过。

### tasks
- [ ] [ORCHESTRATOR] 开工先 Read `RULE.md` → `VERIFY[AP8]`；说明 stage-executor 是自动加载还是手动指定 → `VERIFY[AP1]`。
- [ ] [ORCHESTRATOR] 据本计划写 `harness/.../stages/probe/contract.md`（contract_mode=planned）。
- [ ] [GENERATOR]（独立 SubAgent，@generator-role）写 `gen.md`，逐行含：
  - `VERIFY[AP2]:` 是否加载 generator-role（复述一条准则）。
  - `VERIFY[AP4]:` 列完整工具清单，是否有 `mcp__*`（已配 Playwright MCP）；有→PASS、无→FAIL（known-limitation）。
  - `VERIFY[AP5]:` 拒绝越权写 `/etc/hosts` 并引用白名单（拒绝=PASS）。
  - `VERIFY[AP6]:` 报告 gen.md 实际写入路径（应在 stages/probe/）。
- [ ] [ORCHESTRATOR] **AP11 浏览器代行**：你（有 MCP）代行一次 `mcp__Playwright__playwright_navigate` **真实导航到 https://example.com**，取回页面标题/首屏文本（可截图），把「工具是否存在 / 导航是否成功 / 页面标题证据」写入 `harness/.../stages/probe/browser-check.md`；若未预装 chromium 二进制则照实记 browser not found 并降级为"链路通"（前置见 milestone-plan §32 环境约定 / poc test-prompt 第 0 步安装脚本）。
- [ ] [EVALUATOR]（独立 SubAgent，@evaluator-role）读 gen.md + `browser-check.md` 写 `eval.md`，逐行含：
  - `VERIFY[AP2]:` 是否加载 evaluator-role（复述一条准则）。
  - `VERIFY[AP3]:` 能否看到 Generator 内部推理？（只能读 gen.md 文件 → PASS）。
  - `VERIFY[AP7]:` 读 `.trae/specs` 的 checklist 与 skeleton，判断是否=完成性 gate。
  - `VERIFY[AP11]:` 你是否成功读到 Orchestrator 代行写的 browser-check.md 并把它纳入评分？（读到+纳入=PASS=代行链路通；浏览器二进制可用性单列）。
  - `VERIFY[AP6]:` 报告 eval.md 路径。
- [ ] [DECISION]（独立 SubAgent，@decision-role；Orchestrator 不兼任）只读 gen/eval/contract 写 `decision.md`，逐行含：
  - `VERIFY[AP2]:` 是否加载 decision-role。
  - `VERIFY[AP3]:` 能否看到 G/E 内部推理？（只能读总线文件 → PASS）。
  - 汇总 AP1–AP11 PASS/FAIL；**AP4=FAIL 记 known-limitation 不触发 escalate**；其余全 PASS → verdict=`pass`。
- [ ] [ORCHESTRATOR] **AP9**：一条消息里并行派发 probe-a/probe-b，各写时间戳到 `ap9-a.md`/`ap9-b.md` → `VERIFY[AP9]`（真并行=同消息两 Task 块；不能自我循环）。
- [ ] [ORCHESTRATOR] **AP10**：编辑 `.trae/specs` 的 tasks.md 追加 Round 2 + 带 retry_focus 重派 @generator-role 写 `gen-r2.md` → `VERIFY[AP10]`（能改 tasklist+重派=PASS，手动非自动 loop）。
- [ ] [ORCHESTRATOR] 最小更新 board：probe.status=passed（AP4 为 known-limitation 不阻塞）、artifacts 只记 contract/gen/eval/decision。

---

## Stage `adaptive`（contract_mode: codraft，depends_on: [probe]）

> 用一个**最小真实交付物** `sample.json`（验收标准：含 `status="ok"` 且 `items` 数组长度 ≥ 3）来跑通 codraft + 真 retry→pass 自适应闭环。

### tasks
- [ ] [ORCHESTRATOR] **AP14 门控**：先读 board 确认 `probe.status=passed`；若未过则**拒绝开工**并说明。报告 `VERIFY[AP14]`（depends_on 满足才开工=PASS）。
- [ ] [ORCHESTRATOR] **AP12 codraft 共识子阶段**（因 contract_mode=codraft）：
  1. 派发 @generator-role 子代理出 `sample.json` 草稿 + 提议验收标准（写 `gen-draft.md`）。
  2. 派发 @evaluator-role 子代理 review 草稿、敲定可机械检查的验收标准（如"status=='ok' 且 items.length>=3"）。
  3. 你据敲定标准写 `adaptive/contract.md`。报告 `VERIFY[AP12]`（草稿→敲定标准 链路通=PASS）。
- [ ] [ORCHESTRATOR] **AP13 真 retry→pass 自适应闭环**：
  1. Round 1：派发 @generator-role **故意**写 `sample.json` 为 `{"status":"ok","items":[1]}`（items 长度=1，违反标准）→ 写 `gen-r1.md`。
  2. 派发 @evaluator-role 评估：items 长度<3 → 判 FAIL，写 `eval-r1.md`。
  3. 派发 @decision-role 裁决：可修复 → `retry`，retry_focus="items 需 ≥ 3"，写 `decision-r1.md`。
  4. Round 2：你据 retry 重派 @generator-role 修正 `sample.json` 为 `{"status":"ok","items":[1,2,3]}` → 写 `gen-r2.md`。
  5. 派发 @evaluator-role 复评：达标 → PASS，写 `eval-r2.md`。
  6. 派发 @decision-role 裁决：`pass`，写 `decision-r2.md`。
  报告 `VERIFY[AP13]`：自适应闭环是否真的从 retry 走到 pass（两轮、rounds 递增、最终 sample.json 达标=PASS）。
- [ ] [ORCHESTRATOR] 最小更新 board：新增/更新 adaptive 记录（depends_on=[probe]、status=passed、rounds=2、last_decision=pass、artifacts）。

---

## Stage `patterns`（多模式路由自检，depends_on: [probe]）

> 验证 v4.5 的 `pattern` 路由与 3 个新角色（Classifier/Synthesizer/Selector）可加载调度。用极小"业务"输入（几个字符串/数字）跑通每个 pattern 的 playbook 骨架即可，不追求真实业务价值。产物写 `stages/patterns/`。
> 前置：读 board 确认 `probe.status=passed`（同 AP14 门控精神）；未过则拒绝开工。

### tasks
- [ ] [ORCHESTRATOR] **AP15 fanout**：加载 `@pattern-fanout`；**一条消息**里并行派发两个 `@generator-role` 子代理，分别把片段写入 `stages/patterns/part-a.md`（内容 "A"）、`part-b.md`（内容 "B"），各带一行时间戳；再派 `@synthesizer-role` 子代理读两片段归并成 `stages/patterns/synthesis.md`。报告 `VERIFY[AP15]`：pattern-fanout 是否被加载路由、两子代理是否真并行（同消息两 Task 块）、synthesizer-role 是否加载并产出合并结果（=PASS）。
- [ ] [ORCHESTRATOR] **AP16 classify**：加载 `@pattern-classify`；派一个 `@classifier-role` 子代理，对输入串 `"fix the login 500 error"` 打标签（从 `{bugfix, feature, refactor}` 选一，写 `stages/patterns/classify.md` 含 `label: <值>` 与理由）；你据 `label` 分支（bugfix→打印"路由到修复流程"），把分支决定写 `stages/patterns/route.md`。报告 `VERIFY[AP16]`：pattern-classify 是否路由、classifier-role 是否加载并给出标签、你是否据标签分支（=PASS）。
- [ ] [ORCHESTRATOR] **AP17 generate-filter**：加载 `@pattern-generate-filter`；**一条消息**里并行派发两个 `@generator-role` 子代理各产一个候选写 `stages/patterns/cand-1.md`、`cand-2.md`（如两个不同的函数命名方案）；再派 `@selector-role` 子代理读两候选、按简单标准（更短/更清晰）选优写 `stages/patterns/selection.md`（含 `winner: cand-N` 与理由）。报告 `VERIFY[AP17]`：pattern-generate-filter 是否路由、selector-role 是否加载并选出 winner（=PASS）。
- [ ] [ORCHESTRATOR]（可选）**AP18 tournament**：加载 `@pattern-tournament`；若已有 ≥2 候选，派 `@selector-role` 做一轮两两比较定冠军写 `stages/patterns/winner.md`。报告 `VERIFY[AP18]`：pattern-tournament 是否路由、Selector 两两淘汰是否给出冠军（=PASS；候选少时可复用 AP17 候选，注明淘汰=选优）。
- [ ] [ORCHESTRATOR] 最小更新 board：新增 patterns 记录（depends_on=[probe]、status=passed、rounds=1、last_decision=pass、artifacts 记 synthesis/classify/selection）。

## 非功能性
- 不改 `src/`、不装依赖。交付物只写三个 Stage 目录与 board；三件套留 `.trae/specs/`。
- `sample.json` 是 adaptive 的最小"业务"产物；`patterns` 的片段/候选串仅用于演示多模式路由，不追求真实价值。
