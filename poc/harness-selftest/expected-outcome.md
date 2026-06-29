# Expected Outcome — harness-selftest 判读标准（AP1–AP14）

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
| **AP11** | Orchestrator 代行 MCP 写 `browser-check.md` → **Evaluator 读到并纳入评分**（链路通=PASS，浏览器二进制可用性单列） | 代行链路断 → 浏览器验证缺，降级 `automated` 或重设计 |
| **AP12** | codraft：Generator 出草稿+提议标准 → **Evaluator 敲定标准 → contract.md** | codraft 链路断 → 取消 codraft，仅保留 planned |
| **AP13** | 真 retry→pass：R1 FAIL→Decision retry→R2 修正→**PASS**（两轮、sample.json 最终达标） | 走不到 pass / 不能多轮 → 自适应闭环不成立，retry 改人工 |
| **AP14** | Orchestrator 确认 `probe.status=passed` 后才开工 adaptive | 门控失效（不看 depends_on 就开工）→ 并发冲突风险，需强化人工投递把关 |

> 设计验证点（AP11–AP14）确认 v4.4 的新行为：浏览器代行（方案1）、codraft 共识子阶段、真自适应闭环、depends_on 门控。

## 结果记录

### 本次 v4.4 综合重跑（AP1–AP14，请填写）

| 编号 | 实际结果 (PASS/FAIL) | 证据摘要 |
|------|----------------------|----------|
| AP1 |  |  |
| AP2 |  |  |
| AP3 |  |  |
| AP4 |  | （已知=FAIL/known-limitation） |
| AP5 |  |  |
| AP6 |  |  |
| AP7 |  |  |
| AP8 |  |  |
| AP9 |  |  |
| AP10 |  |  |
| AP11 |  | 浏览器代行链路 |
| AP12 |  | codraft 共识子阶段 |
| AP13 |  | 真 retry→pass 自适应闭环 |
| AP14 |  | depends_on 门控 |

运行日期：______  环境：______

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
