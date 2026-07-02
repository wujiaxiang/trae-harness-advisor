# Harness Self-Test（平台能力 PoC 自检集）

> 目的：在**真实 TRAE Work** 上一次验证本设计依赖的平台能力 + v4.4 设计行为 + v4.5 多模式路由 + AP19 Evaluator shell-bridged MCP 实验，避免"纸面设计、真机跑不通"。
> 环境**已在本仓库实例化**（无需先跑 advisor）：`.trae/skills/` 13 个 Skill（含 stage-executor 旧名 shim）、根目录 `RULE.md`、`harness/`（templates + state-board + 自检 Milestone 三个 Stage）都已就绪。

## 它验证什么（AP1–AP19，三个 Stage + 一个实验项）

**Stage probe（平台能力 AP1–AP11）**

| 编号 | 假设 |
|------|------|
| AP1 | stage-orchestrator 触发短语**自动加载**（stage-executor 旧名兼容） |
| AP2 | SubAgent 加载**指定角色 Skill**（generator/evaluator/decision-role） |
| AP3 | SubAgent **独立上下文隔离** |
| AP4 | SubAgent 调 **MCP**（已知=不继承，仅主 Orchestrator 有；known-limitation） |
| AP5 | 路径白名单**提示词级**，越权写被拒 |
| AP6 | 交付物→**harness/**、三件套→`.trae/specs` |
| AP7 | 原生 `checklist.md` ≈ **完成性 gate** |
| AP8 | **RULE.md 钩子**生效 |
| AP9 | SubAgent **可并行可串行、无自动循环** |
| AP10 | **retry 重派机制**（改 tasks.md + 重派） |
| AP11 | **浏览器代行链路**（方案1：Orchestrator 代行 MCP 真实导航 example.com→browser-check.md→Evaluator 读；未装 chromium 则降级为链路通） |

**Stage adaptive（设计行为 AP12–AP14）**

| 编号 | 行为 |
|------|------|
| AP12 | **codraft 共识子阶段**（Generator 草稿→Evaluator 敲定标准） |
| AP13 | **真 retry→pass 自适应闭环**（R1 FAIL→retry→R2 PASS） |
| AP14 | **depends_on 门控**（probe 未 passed 不开工 adaptive） |

**Stage patterns（v4.5 多模式路由 AP15–AP18，✅ 真机已验证 commit c9a5e84）**

| 编号 | 行为 |
|------|------|
| AP15 | **fanout 路由**（@pattern-fanout→2 Generator 真并行→@synthesizer-role 归并） |
| AP16 | **classify 路由**（@pattern-classify→@classifier-role 打标签→root Orchestrator 分支；SubAgent 不递归启动 Orchestrator） |
| AP17 | **generate-filter 路由**（@pattern-generate-filter→2 候选→@selector-role 选优） |
| AP18 | **tournament 路由（可选）**（@pattern-tournament→@selector-role 两两淘汰选冠军） |

**AP19（实验：Evaluator shell-bridged MCP，需单独真机验证）**

| 编号 | 验证点 |
|------|--------|
| AP19 | `mcp_access_mode=evaluator_shell_bridge`：远程环境 install 初始化 `harness/mcp-bridge/`；Orchestrator 只写 bridge 能力和 MCP→Shell 翻译表到 contract；Evaluator SubAgent 按翻译表通过白名单 shell bridge 自查并写 `eval.md` |

```
.trae/skills/{planner-role,generator-role,evaluator-role,decision-role,stage-orchestrator}/SKILL.md # 5 核心
.trae/skills/stage-executor/SKILL.md                                                              # 旧名兼容 shim
.trae/skills/{classifier-role,synthesizer-role,selector-role}/SKILL.md                            # 3 多模式角色
.trae/skills/pattern-{classify,fanout,generate-filter,tournament}/SKILL.md                        # 4 pattern playbook
RULE.md                                                                              # 钩子目标
harness/
├── templates/{spec,tasks,checklist,stage-contract}.skeleton.md
├── state-board.json                         # probe(passed) + adaptive(passed) + patterns(planned, depends_on=[probe])
└── milestones/harness-selftest/
    ├── milestone-plan.md                    # ★ 自检计划（AP1–AP19）
    ├── stages/probe/                        # AP1–AP11 交付物落点（contract/gen/eval/decision/browser-check）
    ├── stages/adaptive/                     # AP12–AP14 交付物落点（codraft + retry→pass + sample.json）
    └── stages/patterns/                     # AP15–AP18 交付物落点（part-*/synthesis/classify/route/cand-*/selection/winner）
```

## 如何运行（AP1–AP19）

见 **`test-prompt.md`**：
1. 一次性配置 RULE.md 云端钩子规则（AP8 前提）+ 启用 Playwright MCP（AP4/AP11，你已配）+ **在「云端运行环境 > 手动配置」把「安装命令」填 `npx -y playwright@1.57.0 install --with-deps chromium`（版本 pin 到 MCP 内置 playwright，见 test-prompt 第 0 步 / 方法论附录 D）、「启动命令」清空**（AP11 真实导航前提；不配则降级为"链路通"）。
2. **复制 `test-prompt.md` 第 1 步那一整段**发给 TRAE Work——一次跑完 probe + adaptive、AP1–AP14。
3. **补测 v4.5 多模式**：`probe`/`adaptive` 已在 v4.4 通过，直接复制 **第 1b 步**那段跑 `patterns` Stage（AP15–AP18，单独可跑）。
4. **补测 AP19**：云端运行环境 install 需追加 `cd /workspace && bash harness/mcp-bridge/install.sh`（或仓库实际 clone 目录），并配置真实 MCP bridge wrapper；复制 **第 1c 步**那段跑 Evaluator shell bridge 验证。默认 scaffold 未接真实 bridge 时应 BLOCKED，不算通过。
4. 跑完让它把 `VERIFY[APn]` 汇总成表并 push 到 main。

## 如何判读

对照 `expected-outcome.md`：v4.4 的 AP1–AP14 见"综合重跑"表（13/14 PASS，AP11 已升级为真实导航成功）；v4.5 的 AP15–AP18 见"多模式路由"表（**✅ 真机 4/4 PASS，commit c9a5e84**）。多模式已确认：每个 `@pattern-*` playbook 被 Stage Orchestrator **路由加载**、3 个新角色（Synthesizer/Classifier/Selector）可被子代理加载、fanout/generate-filter 真并行、canonical 文件名与 Write 白名单对齐无违规。
