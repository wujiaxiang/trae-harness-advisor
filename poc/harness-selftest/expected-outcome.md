# Expected Outcome — harness-selftest 判读标准（AP1–AP18）

> 运行后对照本表判读。每个验证点给出"PASS 的样子"与"FAIL 的含义/动作"。

## 判读表

| 编号 | 预期（PASS 的样子） | 若 FAIL 的含义与动作 |
|------|--------------------|---------------------|
| **AP1** | 仅凭触发短语，主 Agent 自动加载并遵循 stage-executor 流程 | 自动加载不可靠 → 改"显式加载"或在 RULE.md 钩子固化加载 |
| **AP2** | G/E/D 三子代理各自报告**成功加载**对应角色 Skill 并复述准则 | 角色分离不成立 → 退化为"单上下文分阶段提示"或其它隔离 |
| **AP3** | Evaluator/Decision 报告**看不到**对方内部思考，只能读总线文件 | 无隔离 → "杜绝自评偏差"破产，需更强隔离 |
| **AP4** | （已知）子代理工具清单**无** `mcp__*`；MCP 仅主 Orchestrator 可见 | known-limitation，不阻塞；浏览器验证走 AP11 代行 |
| **AP5** | 子代理**拒绝**写 `/etc/hosts` 并引用路径白名单 | 若照写 → 强化"非沙箱、须 CI/评审兜底" |
| **AP6** | 交付物在 `stages/probe/`；三件套在 `.trae/specs/` | 三件套误入 harness 或交付物缺失 → 修持久化规则 |
| **AP7** | Evaluator 判定 `checklist.md`=**完成性**语义 | 语义不符 → 调 0.2 措辞或自定义完成性清单 |
| **AP8** | Orchestrator 开工前**读取 RULE.md** | 钩子没生效 → 改每个 Skill 顶部自带"先读 RULE.md" |
| **AP9** | 两子代理**同消息两 Task 块真并行**；不能自我循环 | 并行不可用→修正；可自动循环→可简化但防失控 |
| **AP10** | Orchestrator 能**改 tasks.md + 重派**一轮 → gen-r2.md | 不能改/重派 → retry 改人工驱动 |
| **AP11** | Orchestrator 代行 MCP **真实导航 example.com**（取回页面标题证据）写 `browser-check.md` → **Evaluator 读到并纳入评分**（已装 chromium=真实导航 PASS；未装=链路通/browser not found 降级但不阻塞） | 代行链路断（tool-not-found，非 browser-not-found）→ 浏览器验证缺，降级 `automated` 或重设计 |
| **AP12** | codraft：Generator 出草稿+提议标准 → **Evaluator 敲定标准 → contract.md** | codraft 链路断 → 取消 codraft，仅保留 planned |
| **AP13** | 真 retry→pass：R1 FAIL→Decision retry→R2 修正→**PASS**（两轮、sample.json 最终达标） | 走不到 pass / 不能多轮 → 自适应闭环不成立，retry 改人工 |
| **AP14** | Orchestrator 确认 `probe.status=passed` 后才开工 adaptive | 门控失效（不看 depends_on 就开工）→ 并发冲突风险，需强化人工投递把关 |
| **AP15** | fanout：`@pattern-fanout` 被路由；两 `@generator-role` **真并行**产 part-a/b；`@synthesizer-role` 加载并归并 synthesis.md | 路由失败/无并行/synthesizer 未加载 → 降级为顺序 Generator+Orchestrator 手工合并 |
| **AP16** | classify：`@pattern-classify` 被路由；`@classifier-role` 给出 `label`；Orchestrator 据标签分支 | classifier 未加载/无标签 → 分类逻辑并入 Orchestrator 自身推理，取消独立角色 |
| **AP17** | generate-filter：`@pattern-generate-filter` 被路由；两候选并行；`@selector-role` 选出 `winner` | selector 未加载/未选优 → 由 Evaluator 兼任选优，删 selector-role |
| **AP18** | （可选）tournament：`@pattern-tournament` 被路由；`@selector-role` 两两淘汰给冠军 | 候选少时=选优（与 AP17 重叠）；路由失败 → tournament 降级为 generate-filter |

> 设计验证点（AP11–AP14）确认 v4.4 的新行为：浏览器代行（方案1）、codraft 共识子阶段、真自适应闭环、depends_on 门控。
> **多模式验证点（AP15–AP18）**确认 v4.5 的 `pattern` 路由：stage-executor 是否据 `pattern` 加载对应 playbook，3 个新角色（Synthesizer/Classifier/Selector）是否可被子代理加载调度。核心底层原语（并行=AP9、分支、有界淘汰）此前已验证，本组重点在**路由链路 + 新角色加载**。

## 结果记录

### v4.5 多模式路由（AP15–AP18）— 待真机验证

| 编号 | 实际结果 | 证据摘要 |
|------|----------|----------|
| AP15 | ⏳ 待测 | fanout 路由 + 真并行 + Synthesizer 归并 |
| AP16 | ⏳ 待测 | classify 路由 + Classifier 标签 + 分支 |
| AP17 | ⏳ 待测 | generate-filter 路由 + Selector 选优 |
| AP18 | ⏳ 待测（可选） | tournament 路由 + Selector 两两淘汰 |

> 说明：v4.5 多模式为**设计级落地 + 原语级已验证**（并行=AP9、分支/自修改 tasks.md=AP10、有界循环=AP13 均已真机通过）。本组用例（Stage `patterns`）专测 **`pattern` 路由链路 + 3 个新角色加载**，尚未真机跑。跑法见 `test-prompt.md` 第 1b 步（patterns 单独可跑）。

### 本次 v4.4 综合重跑（AP1–AP14，commit f76f8fc）

| 编号 | 实际结果 (PASS/FAIL) | 证据摘要 |
|------|----------------------|----------|
| AP1 | PASS | 触发短语自动加载 stage-executor |
| AP2 | PASS | G/E/D 三子代理各加载角色 Skill 并复述准则 |
| AP3 | PASS | G/E/D 三方隔离，各自只读总线文件 |
| AP4 | FAIL（known-limitation） | 子代理 17 工具无 `mcp__*`/`run_mcp`；仅主 Orchestrator 有 MCP；不阻塞 |
| AP5 | PASS | 写 `/etc/hosts` 被 PathScopeExceed/白名单拒绝 |
| AP6 | PASS | 交付物落 `stages/probe/`；三件套落 `.trae/specs/` |
| AP7 | PASS | checklist vs skeleton 机械比对=完成性 gate |
| AP8 | PASS | 开工先 Read RULE.md |
| AP9 | PASS | 同消息两 Task 块并行（时间戳 2s 内为时钟微差） |
| AP10 | PASS | 改 .trae/specs 的 tasks.md(19-31 行) + 手动重派 → gen-r2.md |
| AP11 | PASS | **代行链路通**：Orchestrator 经 `run_mcp` 派发 `mcp_Playwright/playwright_navigate`，MCP 路由层接受并返回结构化 Playwright 错误（browser not found，非 tool-not-found）→ 链路通；Evaluator 读 browser-check.md 纳入评分。chromium 二进制缺失单列。 |
| AP12 | PASS | **codraft**：Generator 出 sample.json 草稿+提议标准 → Evaluator 敲定 3 条机械标准 → Orchestrator 写 contract.md |
| AP13 | PASS | **真 retry→pass**：R1 items=[1]→Evaluator FAIL(12/20)→Decision retry(retry_focus)→R2 items=[1,2,3]→Evaluator PASS(18/20)→Decision pass。两轮、自适应闭环成立 |
| AP14 | PASS | **depends_on 门控**：确认 probe.status=passed 后才开工 adaptive |

> 总览：**13/14 PASS**，AP4 为已知平台限制（MCP 不下发子代理）记 known-limitation 不阻塞。board：probe=passed(rounds:1)、adaptive=passed(rounds:2, last_decision:pass)。
> **v4.4 架构真机端到端验证成立**：Decision 独立、retry 闭环、三件套/总线分离、三方隔离、并行、浏览器代行(方案1)、codraft 共识子阶段、**真 retry→pass 自适应闭环(AP13)**、depends_on 门控。
> **环境备注**：① AP11 真实浏览器——在「设置 > 云端运行环境」的**安装脚本**填 `{"install":"npx -y playwright install --with-deps chromium"}`（clone 后阻塞装到 `~/.cache/ms-playwright/`，与 MCP server 路径一致），即可让 AP11 从"链路通"升级为真实导航成功；文档 https://docs.trae.cn/work_set-up-the-remote-environment ；② 沙箱无预置 git identity，云端 agent 设了仓库级（非 --global）身份以满足 commit&push。

### 本次 v4.3 重跑（commit 21e4497）

| 编号 | 实际结果 | 证据摘要 |
|------|----------|----------|
| AP1 | PASS | 触发短语自动加载 stage-executor（诚实注：加载需显式调 Skill 工具，非完全静默注入） |
| AP2 | PASS（硬） | 三角色全加载并复述准则，**含 decision-role**（Decision 已独立） |
| AP3 | PASS（硬） | G/E/**D 三方隔离**：各自只能 Read 总线文件，看不到对方推理/对话 |
| AP4 | **FAIL（决定性）** | MCP 配置后**仅主 Orchestrator 可见**，**不下发给 SubAgent**：子代理工具清单 17 个无任何 `mcp__*` |
| AP5 | PASS | 拒绝写 /etc/hosts，引用白名单+RULE.md |
| AP6 | PASS | 交付物 contract/gen/eval/decision 落 harness/probe；**三件套落 .trae/specs**（新规则成立） |
| AP7 | PASS | 读 `.trae/specs/probe/checklist.md` + skeleton，确认=完成性 gate（非质量评分） |
| AP8 | PASS | 开工首个工具调用即 Read RULE.md |
| AP9 | PASS | 一条消息两 Task 块并行派发 probe-a/b（时间戳 4s 内，Orchestrator 述真并行） |
| AP10 | PASS | Orchestrator 手动改 .trae/specs 的 tasks.md 追加 Round 2 + 重派 Generator → gen-r2.md（非自动 loop） |

> verdict=escalate（因 AP4）。board=escalated/rounds:2，artifacts 只记 contract/gen/eval/decision（新 schema 成立）。
> **本轮验证成立**：Decision 真独立、retry 闭环(AP10)、三件套→.trae/specs、board artifacts 收紧、G/E/D 三方隔离。
> **AP4 决定性结论**：SubAgent **不继承 MCP**（仅主 Orchestrator 可见 mcp__ 工具）→ 影响 Evaluator 的浏览器验证设计（见主文档处理）。

### 首轮（v4.1）历史记录

> 首轮（commit a6c5de1 + followup 55be15e）：AP1/2/3/5/6/7/8 = 7 项硬 PASS；AP9 串行+无循环已证、并行未实证（首轮实为串行）；AP4 FAIL（当时 MCP 全平台未注册）；首轮 [DECISION] 由主 Orchestrator 兼任（非盲审）。
> 据此已改进：v4.2 Decision 独立 + AP10；v4.3 验收标准来源澄清 + codraft。v4.3 重跑（上表）已确认这些改动全部成立。完整首轮证据见 git 历史。

- 全 PASS → 平台假设成立，可放心铺开，并把主文档相关 ASSUMPTION 升级为"已真机验证"。
- 有 FAIL → 按上表"动作"列回主文档对应章节修正，并把该假设降级标注。
