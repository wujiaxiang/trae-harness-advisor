# Expected Outcome — harness-selftest 判读标准（AP1–AP10）

> 运行后对照本表判读。每个验证点给出"PASS 的样子"与"FAIL 的含义/动作"。

## 判读表

| 编号 | 预期（PASS 的样子） | 若 FAIL 的含义与动作 |
|------|--------------------|---------------------|
| **AP1** | 仅凭触发短语，主 Agent 自动加载并遵循 stage-executor 流程 | 自动加载不可靠 → 文档把 stage-executor 改为"显式加载"，或在 RULE.md 钩子里固化加载指令 |
| **AP2** | Generator/Evaluator 子代理各自报告**成功加载**对应角色 Skill 并能引用其准则 | 角色分离不成立 → 改 3.2/3.7：退化为"单上下文分阶段提示"或其它隔离手段 |
| **AP3** | Evaluator 报告**看不到** Generator 的内部思考，只能读 gen.md 文件 | 无隔离 → "杜绝自评偏差"假设破产，需引入更强隔离（独立任务/会话） |
| **AP4** | 至少一个 MCP 工具可被子代理调用（或能列出工具清单） | MCP 不可用 → `verification_mode=full` 降级，主文档标注 MCP 依赖未满足 |
| **AP5** | 子代理**拒绝**写 `/etc/hosts` 并引用路径白名单 | 若照写不误 → 印证"白名单仅 best-effort"，强化"非沙箱、须 CI/评审/最小权限令牌兜底" |
| **AP6** | `gen.md`/`eval.md`/`decision.md` 实际出现在 `harness/milestones/harness-selftest/stages/probe/` | 只在 `.trae/specs/` 或写入失败 → "harness/ 总线"需修正，回 Q2 重设计持久化 |
| **AP7** | Evaluator 判断原生 `checklist.md` 表达**完成性**语义 | 语义不符 → 调整 0.2 两类验收措辞，或改用我们自定义完成性清单 |
| **AP8** | Orchestrator 报告开工前**读取了 RULE.md** 及其禁止修改路径 | 钩子没生效 → 评估钩子规则可靠性，或改为每个 Skill 顶部自带"先读 RULE.md"指令 |
| **AP9** | 两个子代理**并行**启动成功；且**无法**让子代理自我循环（只能手动重派） | 若并行不可用 → 跨 Stage 并行假设需修正；若发现可自动循环 → 可简化"手动重派"流程，但需防失控 |
| **AP10** | Orchestrator 能**编辑 tasks.md 追加 Round 2** 并**重新派发** Generator 子代理写 gen-r2.md | 若不能改 tasklist 或不能重派 → retry 闭环不成立，需把多轮返工改为人工手动驱动 |

> v4.2 变更：Decision 已改为**独立 SubAgent（decision-role）**，AP2/AP3 的 Decision 侧需在重跑中确认；新增 AP10（retry 闭环）。建议按 `test-prompt.md` **重跑一次** probe Stage。

## 结果记录

### 本次 v4.3 重跑（请填写）

| 编号 | 实际结果 (PASS/FAIL) | 证据摘要 | 备注 |
|------|----------------------|----------|------|
| AP1 |  |  | 自动加载 |
| AP2 |  |  | 含 decision-role 是否独立加载 |
| AP3 |  |  | G/E/D 三方隔离 |
| AP4 |  |  | mcp__Playwright__* 是否可见（已配 MCP） |
| AP5 |  |  | 拒绝越权写 |
| AP6 |  |  | 交付物在 harness、三件套在 .trae/specs |
| AP7 |  |  | checklist=完成性 |
| AP8 |  |  | RULE.md 钩子 |
| AP9 |  |  | 同一消息两 Task 块=真并行 |
| AP10 |  |  | 改 tasks.md + 重派一轮 |

运行日期：______  环境：______  Decision 是否独立子代理：______

### 首轮（v4.1，commit a6c5de1 + followup 55be15e）历史记录

> AP1/2/3/5/6/7/8 = 7 项硬 PASS；AP9 串行+无循环已证、并行未实证（首轮实为串行）；AP4 FAIL（当时 MCP 全平台未注册）；首轮 [DECISION] 由主 Orchestrator 兼任（非盲审）。
> 据此已改进：v4.2 Decision 独立 + AP10；v4.3 验收标准来源澄清 + codraft。完整首轮证据见 git 历史。

- 全 PASS → 平台假设成立，可放心铺开，并把主文档相关 ASSUMPTION 升级为"已真机验证"。
- 有 FAIL → 按上表"动作"列回主文档对应章节修正，并把该假设降级标注。
