# Deliverable Specifications (v4.6)

> 本文件是 `trae-harness-advisor` Skill 的 Step 6 文件生成规格。
> 术语与架构以 `../resources/harness-engineering-on-trae-work.md` 第零部分为权威。
> 核心理念：Advisor 只生成**脚手架与指导思想**（角色 Skill、stage-orchestrator playbook、旧名兼容 shim、结构骨架、RULE.md、空 board），**不生成任何业务内容**。三件套由 Orchestrator 运行时产出。

## 目录

1. [配置变量映射](#配置变量映射)
2. [目录结构](#目录结构)
3. [1. Planner Role Skill](#1-planner-role-skill)
4. [2. Generator Role Skill](#2-generator-role-skill)
5. [3. Evaluator Role Skill](#3-evaluator-role-skill)
6. [4. stage-orchestrator Playbook Skill](#4-stage-orchestrator-playbook-skill)
7. [5. RULE.md（项目规范）](#5-rulemd项目规范)
8. [6. 钩子规则文本](#6-钩子规则文本)
9. [7. 三件套骨架模板](#7-三件套骨架模板)
10. [8. stage-contract 骨架](#8-stage-contract-骨架)
11. [9. state-board.json（v2 空表）](#9-state-boardjson-v2-空表)
12. [10. 可选 Agent 配置](#10-可选-agent-配置)
13. [11. 可选：多模式编排包](#11-可选多模式编排包generate_patterns默认-false)
14. [11b. 可选：Stage Dispatcher](#11b-可选stage-dispatchergenerate_stage_dispatcher默认-false)
15. [11c. 可选：MCP bridge 脚手架](#11c-可选mcp-bridge-脚手架mcp_access_modeevaluator_shell_bridge)
16. [12. 生成后验证](#12-生成后验证)

---

## 配置变量映射

问题编号与 `SKILL.md` 工作流 Step 1-4 的问答严格对应。`skill_dir`、`agent_dir` 不在问答中询问，使用默认值：

| 问题 | 变量名 | 默认值 |
|------|--------|--------|
| Q1: task_type | `{task_type}` | `"development"` |
| Q2: tech_stack | `{tech_stack}` | 用户输入 |
| Q3: project_scale | `{project_scale}` | `"medium"` |
| Q4: harness_dir | `{harness_dir}` | `"harness/"` |
| Q5: generate_agents | `{generate_agents}` | `false` |
| Q6: max_adversarial_rounds | `{max_rounds}` | `3` |
| Q7: eval_strictness | `{eval_strictness}` | `"standard"` |
| Q8: force_contract | `{force_contract}` | `true`（Orchestrator 标注关键 Contract 点；false 则跳过） |
| Q9: tdd_mode | `{tdd_mode}` | `"standard"` |
| Q10: verification_mode | `{verification_mode}` | `"full"` |
| Q11: use_calibration | `{use_calibration}` | `false` |
| Q12: custom_acceptance_rules | `{custom_rules}` | `"none"` |
| （不询问）skill_dir | `{skill_dir}` | `".trae/skills/"` |
| （不询问）agent_dir | `{agent_dir}` | `".trae/agents/"` |
| （不询问）generate_patterns | `{generate_patterns}` | `false`（开启则额外生成多模式编排包：3 角色+4 playbook，见第 11 节） |
| Q13: mcp_access_mode | `{mcp_access_mode}` | `"orchestrator_delegated"`；可选 `"evaluator_shell_bridge"`（实验，需 AP19 真机验证） |

> 注：`task_type` 决定 Milestone 的默认 `kind`（development→development，verification→verification，hybrid→由 Planner 按 Milestone 区分）。Stage 目录路径固定在 `{harness_dir}` 下，不再单独询问 spec/eval/contract 目录。state-board.json 为核心产物，始终生成。**Contract 已简化为 Orchestrator 一次标注关键点（见 stage-orchestrator），不再有多轮协商，故无 `max_contract_rounds`。**

### 评分严格度映射

| 严格度 | 通过阈值 | 单项最低分 |
|--------|----------|-----------|
| `relaxed` | 总分 >= 14/20 | 无单项 < 3 |
| `standard` | 总分 >= 16/20 | 无单项 < 4 |
| `strict` | 总分 >= 18/20 | 无单项 < 4 |

### TDD 模式映射

| 模式 | 行为描述 |
|------|---------|
| `relaxed` | 先实现，Stage 结束前补齐测试 |
| `standard` | 先写测试 → 确认失败 → 实现 → 全部通过 |
| `strict` | red-green-refactor 循环，覆盖率 >= 80% |

### 验证模式映射（Evaluator 业务质量验收）

| 模式 | 包含步骤 | 谁执行 |
|------|---------|--------|
| `quick` | 自动化测试 + 代码审查 | Evaluator 子代理（RunCommand 跑测试） |
| `automated` | 代码审查 + 自动化测试 + Lint | Evaluator 子代理 |
| `full` | automated + **浏览器测试 + 截图** | 浏览器步骤由 **Orchestrator 代行 MCP**（子代理无 MCP），证据写 `browser-check.md`，Evaluator 读取纳入评分 |

> ⚠ 真机实测：SubAgent **不继承 MCP**。`full` 的浏览器验证必须由有 MCP 的 Orchestrator 代行（AP11 已验证链路可行）；**实际浏览器交互还需预装 chromium**，且**安装命令须把 playwright 版本 pin 到 MCP 内置版本**（否则装错浏览器修订目录 → binary-not-found，排障见方法论附录 D）：`npx -y playwright@<MCP版本> install --with-deps chromium`，配置入口 https://docs.trae.cn/work_set-up-the-remote-environment 。若无 MCP 或无浏览器二进制，降级为 `automated`。

---

## 目录结构

先创建目标目录（如果不存在）：

```
{skill_dir}                       # 默认 .trae/skills/（静态/git）
├── planner-role/SKILL.md
├── generator-role/SKILL.md       # 内嵌 Agent 工具集 + 路径白名单
├── evaluator-role/SKILL.md       # 业务质量四维评分（不含裁决）
├── decision-role/SKILL.md        # 独立中立裁决者
├── stage-orchestrator/SKILL.md   # 运行时拉起 playbook
└── stage-executor/SKILL.md       # 旧名兼容 shim
RULE.md                           # 项目根目录（钩子规则加载）
{harness_dir}                     # 默认 harness/（持久真值 + 消息总线）
├── templates/
│   ├── spec.skeleton.md
│   ├── tasks.skeleton.md
│   ├── checklist.skeleton.md
│   └── stage-contract.skeleton.md
└── state-board.json              # v2 空表
（可选）{harness_dir}stage-dispatcher.md   # 外部机械派发器（generate_stage_dispatcher=true）
（可选）{harness_dir}mcp-bridge/           # Evaluator shell-bridged MCP 脚手架（mcp_access_mode=evaluator_shell_bridge）
├── install.sh
└── check.sh
（可选）config/mcporter.json               # MCP server/runtime + wrapper 白名单配置源
（可选）{agent_dir}               # 默认 .trae/agents/（仅 generate_agents=true）
├── generator.md  evaluator.md  decision.md
.trae/specs/ → 加入 .gitignore（原生临时 scratch，不生成、不依赖）
```

运行时由 Planner / Orchestrator 创建（**不在 Advisor 输出范围**）：
- `{harness_dir}milestones/{milestone}/milestone-plan.md`（Planner 产出）
- `.trae/specs/` 下当前 Stage 的 `spec.md / tasks.md / checklist.md`（Orchestrator 运行 `/spec` 产出；临时脚手架，不复制到 `{harness_dir}`）
- `{harness_dir}milestones/{milestone}/stages/{stage}/{contract,gen,eval,decision,browser-check}.md`（持久交付物/证据）

注意：
- Advisor **不生成任何业务内容**（不写 milestone-plan、不写三件套），只生成骨架与角色规范。
- `.trae/rules/` 不存在——项目规范用 RULE.md + 钩子规则。
- Agent 配置文件可选——当前云端不支持 `.trae/agents/`，角色行为已内嵌 Skill。

---

## 1. Planner Role Skill

**文件路径**: `{skill_dir}planner-role/SKILL.md`

**生成规则**: 基于 `../resources/...` 第 4.2 节 Planner Skill 模板。根据 `{task_type}` 调整描述：
- `development` → 强调"需求分析、Milestone→Stage 分解"
- `verification` → 强调"验收范围定义、验证 Stage 拆分"
- `hybrid` → 两者，并要求 Planner 为每个 Milestone 标注 `kind`

**核心内容（必须保留）**:
- 职责：用户需求 → 一个 Milestone（标注 `kind`）+ 战略分解为若干 Stage（含 `depends_on`、`contract_mode`）
- **每个 Stage 标 `contract_mode`**：`planned`（默认，验收标准规划期已明确/联调，Orchestrator 直接写 contract.md）或 `codraft`（验收标准需先有草稿才能定，早期/探索性开发，走"Generator 草稿→Evaluator 敲定标准"共识子阶段）
- 行为准则（只描述做什么/为什么、机械可检查验收标准、依赖标注、确定性语言、量化指标、Stage 粒度适中）
- **输出 `milestone-plan.md` + 初始化 `state-board.json`；不生成三件套**

---

## 2. Generator Role Skill

**文件路径**: `{skill_dir}generator-role/SKILL.md`

**生成规则**: 基于 `templates/generator-skill-template.md`。根据 `{tdd_mode}` 调整 TDD 描述（见映射表）。

**跳过条件**: `{task_type}` 为 `"verification"` 时跳过。

**核心内容（必须保留）**:
- 职责：按 Stage 实现功能，不评价自己代码
- 工具集（Read/Write/Edit/Glob/Grep/Bash）+ 路径白名单（可改 `src/`、`tests/`；禁改 `{harness_dir}`、`{skill_dir}`、`RULE.md`）
- 行为准则；实现总结写入 `{harness_dir}milestones/{milestone}/stages/{stage}/gen.md`
- 若 `{force_contract}=true`：Generator 实现前先读取 Orchestrator 标注的 `contract.md` 关键点（目标/验收要点/边界）

---

## 3. Evaluator Role Skill

**文件路径**: `{skill_dir}evaluator-role/SKILL.md`

**生成规则**: 基于 `templates/evaluator-skill-template.md`。根据 `{eval_strictness}` 调整阈值、`{verification_mode}` 调整验证步骤。

**核心内容（必须保留）**:
- 定位：**业务质量**对抗验收（"怀疑者"），在 task 内部作为 `[EVALUATOR]` 步骤运行；**与 checklist 完成性 gate 不同维度**（见第零部分 0.2）
- 四维评分（功能性、工艺质量、完整性、用户体验）+ 判定阈值
- 工具集 + 路径白名单（只读全部；只写 `.../eval.md`）。**子代理无 MCP**：用 RunCommand 跑测试/Lint；`verification_mode=full` 的浏览器证据由 Orchestrator 代行写入 `browser-check.md`，Evaluator Read 后纳入评分
- 评估报告写入 `.../eval.md`
- **不含裁决**：裁决已抽出为独立 `decision-role`（见下节 3.5）
- 若 `{use_calibration}=true`：追加 2-3 个 few-shot 评分案例
- 若 `{custom_rules}!="none"`：追加一条特殊验收规则

---

## 3.5 Decision Role Skill（独立裁决者）

**文件路径**: `{skill_dir}decision-role/SKILL.md`

**生成规则**: 基于 `templates/decision-skill-template.md`。Decision 自 v4.2 起从 evaluator-role 抽出为**独立角色**，作为**独立 SubAgent** 派发，与 G/E 上下文隔离以保证中立盲审。

**核心内容（必须保留）**:
- 定位：独立、只读、中立第三方；**不写代码、不评分**，只裁决
- 工具集：Read（gen/eval/contract/board；必要时读 Orchestrator 提供的当前 `.trae/specs` 上下文）+ Write（仅 decision.md）
- 输入：`gen.md`+`eval.md`+`contract.md`+ 当前 rounds
- 输出：`decision.md`（JSON：verdict pass/retry/escalate + reasoning + retry_focus/escalation_reason）
- 裁决规则：pass / retry（rounds < `{max_rounds}`，必给 retry_focus）/ escalate（rounds 达上限或根本分歧）
- **交接约定**：Decision 只裁决、不执行 retry；retry 的后续（改 tasks.md + 重派 Generator）由 Orchestrator 承担；Decision 不能自我循环

---

## 4. stage-orchestrator Playbook Skill

**文件路径**: `{skill_dir}stage-orchestrator/SKILL.md`

**生成规则**: 基于 `templates/stage-orchestrator-skill-template.md`。这是 **L2 的单一运行时入口**，触发短语如"执行 Stage / 开始阶段 / run stage"。同时生成 `{skill_dir}stage-executor/SKILL.md` 作为旧名兼容 shim，只指向 `@stage-orchestrator`。

**核心内容（必须保留，确定性过程）**:
1. 读 `{harness_dir}state-board.json` → 定位当前 Stage，校验 `depends_on` 全部 `passed`
2. 读 `{harness_dir}milestones/{milestone}/milestone-plan.md` → 取该 Stage 定义
3. 运行 `/spec`，按 `{harness_dir}templates/*.skeleton.md` 产出三件套（spec/tasks/checklist）——**留在原生 `.trae/specs/` 即可，本对话内供 G/E/D 读取，不复制到 harness/、不进 git**。只把**交付物** contract/gen/eval/decision 写入总线 `{harness_dir}milestones/{milestone}/stages/{stage}/`（验收标准放 contract.md）
4. **自检门**：spec 章节齐全？tasks 与 checklist 1:1 映射？否 → 停止并报告
5. **确定 contract.md（按 Stage 的 `contract_mode`）**：`planned`→Orchestrator 据 milestone-plan 要点+既定契约直接写；`codraft`→先跑共识子阶段（@generator-role 出草稿+提议标准 → @evaluator-role 敲定标准 → 写 contract.md）再对抗
6. 派发**三个独立 SubAgent**：`[GENERATOR]`(generator-role) → `[EVALUATOR]`(evaluator-role) → `[DECISION]`(decision-role，独立盲审)。Orchestrator 只串联、不兼任任何角色
7. 据 `decision.md` 的 verdict：pass→checklist gate；**retry→Orchestrator 改 tasks.md 追加返工任务 + 带 retry_focus 重派 Generator（rounds+1）**；escalate→暂停回写 board
8. 回写 `state-board.json`：`status / rounds / last_decision / artifacts`（最小更新）

> 强调：三件套内容由 Orchestrator 运行时推理，骨架只给章节契约。不要预生成业务内容。Orchestrator 不得自己兼任 Generator/Evaluator/Decision。

---

## 5. RULE.md（项目规范）

**文件路径**: `RULE.md`（项目根目录）

**设计说明**: TRAE Work 不支持 `.trae/rules/`。在「设置 > 规则」建一条云端钩子规则让每个 Task 启动读 `RULE.md`；`RULE.md` 顶部指向 `stage-orchestrator` playbook。

**生成规则**: 基于 `templates/project-rules-template.md`，按 `{tech_stack}`、`{project_scale}` 定制：
- **常用命令**: 按 `{tech_stack}` 推断（React→`npm run dev`/`npm test`；Python→`pytest`；Go→`go test ./...` 等）
- **关键目录结构**: `{harness_dir}`（持久总线）、`.trae/specs/`（临时 scratch，gitignore）
- **编码约定**: 按 `{tech_stack}` 推断
- **全局禁止修改**: `{harness_dir}`、`{skill_dir}`、`RULE.md`、`node_modules/`、`.git/`、`.env`
- **入口指引**: "执行某个 Stage 时，加载 stage-orchestrator playbook 并遵循其确定性流程；stage-executor 仅为旧名兼容入口"
- 若 `{custom_rules}!="none"`：追加到"编码约定"

---

## 6. 钩子规则文本

**不生成文件**，直接在对话输出供用户复制到「设置 > 规则」：

```
在开始执行任何任务之前，必须先读取当前项目根目录的 RULE.md 文件，将其内容作为当前项目的编码规范、约束条件和行为准则。如果 RULE.md 不存在，则跳过此步骤。
```

---

## 7. 三件套骨架模板

> 这些是**结构骨架**（只有章节契约，无业务内容），供 Orchestrator 运行时填充。内容见 `../resources/...` 第 4.1 节。

| 文件 | 路径 | 定位 |
|------|------|------|
| spec 骨架 | `{harness_dir}templates/spec.skeleton.md` | Stage 规格（目标/范围/验收标准/依赖/非功能） |
| tasks 骨架 | `{harness_dir}templates/tasks.skeleton.md` | 对抗编排（[GENERATOR]/[EVALUATOR]/[DECISION] 顺序步骤） |
| checklist 骨架 | `{harness_dir}templates/checklist.skeleton.md` | **底层机制**：tasklist 完成性 gate（≠ Evaluator 质量评分） |

**生成规则**: 直接落地 `templates/{spec,tasks,checklist}.skeleton.md` 的内容；`{tdd_mode}`、`{eval_strictness}` 作为占位提示写入 tasks 骨架。

---

## 8. stage-contract 骨架

**文件路径**: `{harness_dir}templates/stage-contract.skeleton.md`

**生成规则**: 基于 `templates/stage-contract.skeleton.md`（含本轮目标、验收要点、边界、依赖、风险）。顶部注明"由 **Orchestrator** 在起 Stage 时标注关键点，复制填充为 `stages/{stage}/contract.md`；非 Generator↔Evaluator 多轮协商"。
- 若 `{force_contract}=false`：追加注释"当前为跳过模式，Generator 直接按 spec 实现，无需 Contract 标注"。

---

## 9. state-board.json（v2 空表）

**文件路径**: `{harness_dir}state-board.json`（核心产物，始终生成）

**内容**: v2 空表，作为唯一跨 session 状态机真值：

```json
{
  "version": "2.0",
  "created_at": "{当前 ISO 时间戳}",
  "milestones": []
}
```

**Schema 约定**（写入文档说明，供 Planner/Orchestrator 遵循）：

```jsonc
{
  "version": "2.0",
  "milestones": [{
    "id": "string",
    "kind": "development | verification",
    "status": "planning | in_progress | done",
    "stages": [{
      "id": "string",
      "title": "string",
      "depends_on": ["stage_id"],
      "status": "planned | spec_ready | in_progress | passed | failed | escalated",
      "rounds": 0,
      "last_decision": "pass | retry | escalate | null",
      "artifacts": { "contract": "", "gen": "", "eval": "", "decision": "", "browser_check": "" }
    }]
  }]
}
```

- `milestone-plan.md` = 定义（静态只读）；`state-board.json` = 状态机（动态唯一真值）。两者不重复：plan 描述"是什么"，board 记录"到哪一步"。
- **artifacts schema**：
  - adversarial / loop：`contract/gen/eval/decision/browser_check`
  - classify：`classify` + `routes.{label}.*`
  - fanout：`parts` + `synthesis`
  - generate-filter：`candidates` + `selection`
  - tournament：`brackets` + `winner`
  - 三件套 `spec/tasks/checklist` 不进入 artifacts。
- **写协议（最小更新）**：无引擎锁；每次只对当前 Stage 那一条记录做最小字段更新，不整体重写、不动其它 Stage → 不相交小改动，git 合并不冲突。
- **并发语义**：Stage 并发 = 人类开多个独立云端对话，非自动调度；`depends_on` 是人工投递前的代码冲突规避依据（确认依赖已 passed 且无源文件交集），非自动门控。

---

## 10. 可选 Agent 配置

**生成条件**: 仅当 `{generate_agents}=true`。当前云端不支持 `.trae/agents/`，角色行为已内嵌 Skill；此为未来兼容保留。

| 文件 | 模板 | 要点 |
|------|------|------|
| `{agent_dir}generator.md` | `templates/generator-agent-template.md` | 读当前 Stage 三件套上下文 + contract.md；可改 src/、tests/；只写 gen.md |
| `{agent_dir}evaluator.md` | `templates/evaluator-agent-template.md` | 子代理无 MCP；只读全部、只写 eval.md；浏览器证据读取 `browser-check.md` |
| `{agent_dir}decision.md` | `templates/decision-agent-template.md` | 独立裁决者；读 gen/eval/contract/board；只写 decision.md；不强依赖 harness 下 spec.md |

跳过：`{task_type}="verification"` 时跳过 generator.md。

---

## 11. 可选：多模式编排包（`generate_patterns`，默认 false）

当 `{generate_patterns}=true` 时额外生成（让 Stage 可用 adversarial 之外的 5 种编排模式，见 resources 3.10）：

**3 个轻量角色 Skill**：
| 文件 | 模板 | 用途 |
|------|------|------|
| `{skill_dir}classifier-role/SKILL.md` | `templates/classifier-skill-template.md` | 分类/路由（classify 模式） |
| `{skill_dir}synthesizer-role/SKILL.md` | `templates/synthesizer-skill-template.md` | 归并汇总（fanout 模式） |
| `{skill_dir}selector-role/SKILL.md` | `templates/selector-skill-template.md` | 选优/两两比较（generate-filter / tournament） |

**4 个 pattern playbook Skill**：
| 文件 | 模板 | 模式 |
|------|------|------|
| `{skill_dir}pattern-classify/SKILL.md` | `templates/pattern-classify-template.md` | Classify-and-act |
| `{skill_dir}pattern-fanout/SKILL.md` | `templates/pattern-fanout-template.md` | Fan-out-and-synthesize |
| `{skill_dir}pattern-generate-filter/SKILL.md` | `templates/pattern-generate-filter-template.md` | Generate-and-filter |
| `{skill_dir}pattern-tournament/SKILL.md` | `templates/pattern-tournament-template.md` | Tournament |

> adversarial 与 loop 已由 stage-orchestrator 内置（loop=retry 泛化），无需额外文件。Planner 在 milestone-plan 给每个 Stage 标 `pattern`；stage-orchestrator 据此路由（见 resources 3.10）。未开启多模式包时，所有 Stage 走默认 adversarial。

---

## 11b. 可选：Stage Dispatcher（`generate_stage_dispatcher`，默认 false）

当 `{generate_stage_dispatcher}=true` 时额外生成 **1 个文件**——运行在 TRAE Work 之外的**机械执行派发器**，对应「三档自动化」的 B 档（人类 Supervisor/Lead + Codex-CUA Dispatcher + TRAE Work）。

| 文件 | 模板 | 位置说明 |
|------|------|------|
| `{harness_dir}stage-dispatcher.md` | `templates/stage-dispatcher-template.md` | **不放进 `{skill_dir}`**（那是 TRAE Work 内部技能目录）。它是总线里的一份外部派发说明，供人照做 / 喂给 Codex-CUA 当机械执行指令 / 给父 agent 当编排脚本 |

**生成方式**: 从模板复制，替换 `{harness_dir}`/`{max_adversarial_rounds}` 等占位符即可。

**它解决什么**: 把原「人节点」拆成三段：Supervisor/Lead 发起 Planner 规划对话并确认 milestone-plan；Stage Dispatcher 只接管**执行阶段机械派发**——读 board 找 ready Stage → 在 TRAE Work 开执行对话派发 `@stage-orchestrator` → 等完成 → 读 decision.md → pass 推进 / escalate/[BLOCKED] 上抛 Supervisor；Supervisor/Lead 处理 review、授权、纠偏、最终仲裁。收益随模式不同：fanout/tournament/generate-filter 最大（机器分批替代人分批），adversarial/loop 有限。

**三档自动化**（谁扮演 Dispatcher）：A=人（人兼 Lead + Dispatcher + Supervisor）｜B=Codex-CUA（机器搬运，人只处理规划确认/review/仲裁/授权）｜C=强 LLM 父 agent 走 TRAE API（最干净，依赖平台暴露 API）。

**护栏**（模板内已内置，务必保留）：只搬运不判断、规划确认/review/escalate/BLOCKED/授权/最终仲裁一律上抛 Supervisor、状态以总线文本为准（不靠屏幕解析业务状态）、动作幂等+有界重试、事件驱动禁忌忙轮询、最小 UI 面、不改业务真值、全程写 `stage-dispatcher-log.md`。**CUA 特有风险**（集成面决定可靠性、成本、ToS/反滥用）须如实告知用户由其权衡。

> 与多模式包正交：`generate_stage_dispatcher` 可单独开，也可与 `generate_patterns` 同开（后者收益最大）。未开启时默认 A 档（人当 Dispatcher）。

---

## 11c. 可选：MCP bridge 脚手架（`mcp_access_mode=evaluator_shell_bridge`）

当 `{mcp_access_mode}="evaluator_shell_bridge"` 时额外生成 **3 个实验脚手架文件**，用于 AP19 真机验证：让 Evaluator SubAgent 通过白名单 shell 命令间接调用 MCP 能力，并把查证证据留在 `eval.md`。

| 文件 | 模板 | 用途 |
|------|------|------|
| `{harness_dir}mcp-bridge/install.sh` | `templates/mcp-bridge-install-template.sh` | TRAE Work 远程环境 install 阶段调用；安装/准备 bridge wrapper 并运行自检 |
| `{harness_dir}mcp-bridge/check.sh` | `templates/mcp-bridge-check-template.sh` | 输出 `--json` 能力探测结果，供 Stage Orchestrator 写入 contract |
| `config/mcporter.json` | `templates/mcporter-config-template.json` | MCP server、install 命令、daemon keepAlive、wrapper allowlist 与翻译样例的 runtime 配置源 |
| `{skill_dir}mcporter-bridge/SKILL.md` | `templates/mcporter-bridge-skill-template.md` | 项目内 focused Skill：教 Evaluator 把 MCP/browser 意图翻译成 contract 白名单 shell 命令 |

**远程环境配置要求**：TRAE Work 云端运行环境的 `runtime_config.install` 必须包含 `cd /workspace && bash {harness_dir}mcp-bridge/install.sh`（或仓库实际 clone 目录）；若需要下载 npm/pypi/github 依赖，`network_policy.common_dependencies` 必须允许对应源。install 脚本长度限制为 10KB，因此具体逻辑放入仓库脚本，远程配置只调用脚本。

**MCP 来源模型**：
- MCP server 注册、安装命令、daemon keepAlive、wrapper 白名单与翻译样例由本项目 `config/mcporter.json` 自维护；不要依赖 TRAE UI 已注册 MCP 自动透传给 SubAgent。
- `install.sh` 读取 `config/mcporter.json`，执行各 server 的 `install` 命令，按 `bridgeWrappers.*.allowedTools` 生成 wrapper，并启动 `mcporter daemon`。
- discovery 结果只写入 `{harness_dir}mcp-bridge/discovery/` 供 Orchestrator/人读取，不自动扩权给 Evaluator。
- Evaluator 真正可调用的能力必须落成 `{harness_dir}mcp-bridge/bin/mcp-browser` 这类 wrapper，并同时出现在 `config/mcporter.json` 与 `contract.md` 白名单里。

**运行契约**：
- Stage Orchestrator 只运行 `check.sh --json` 并读取 `config/mcporter.json`，不得把未知 MCP 能力临时发明给 Evaluator。
- Stage Orchestrator 必须把 `config/mcporter.json` 的 `bridgeWrappers.*.allowedTools` / `translationExamples` 誊写成 contract 中的 `mcp_bridge_capabilities` / `mcp_to_shell_translation`，让 Evaluator 明确知道“想用 MCP 时改用哪条 RunCommand”。
- `check.sh --json` 中的 `discovery` 字段只表示 MCPorter 是否能看到某些 server/tool，不等价于 SubAgent 可用；只有 `commands.* == available` 才代表 wrapper 可供 Evaluator 使用。
- Evaluator 只能调用 contract 中 `mcp_bridge_capabilities` 声明的白名单命令；遇到浏览器/MCP 意图时必须按 `mcp_to_shell_translation` 改写成 shell，而不是寻找 `mcp__*` 工具。
- bridge 证据必须写入 `eval.md`；`browser-check.md` 仅用于默认 `orchestrator_delegated` 或 fallback。
- bridge 不可用时输出 `[BLOCKED: MCP bridge unavailable]`，或按 contract 明确 fallback 到 `orchestrator_delegated`。
- 本模式必须通过 AP19 真机验证后才能视为稳定能力；本地静态检查不能代表 AP19 通过。

---

## 12. 生成后验证

生成所有文件后执行：

1. **目录检查**: `{skill_dir}` 5 个核心角色/playbook 目录（planner/generator/evaluator/decision/stage-orchestrator）和 1 个旧名 shim（stage-executor）、`{harness_dir}templates/`、`{harness_dir}state-board.json` 均已创建；若 `generate_patterns=true` 另有 7 个多模式 Skill 目录；若 `generate_stage_dispatcher=true` 另有 `{harness_dir}stage-dispatcher.md`；若 `mcp_access_mode=evaluator_shell_bridge` 另有 `{harness_dir}mcp-bridge/`、`{skill_dir}mcporter-bridge/` 与 `config/mcporter.json`。
2. **文件计数**: 核心 **12 个文件**（5 个权威 Skill + 1 个 stage-executor 兼容 shim + RULE.md + 4 个骨架 + state-board.json），外加 1 段钩子规则文本；可选 +3 个 Agent 配置、+7 个多模式 Skill、+1 个 Stage Dispatcher 文件、+3 个 MCP bridge 脚手架文件、+1 个 MCPorter bridge 翻译 Skill、+1 个 mcporter config。`task_type=verification` 时 generator-role 跳过 → 核心 11 个文件。
3. **引用检查**: 路径使用 `{harness_dir}`、`{skill_dir}` 实际值；无 `feature`/`sprint`/`tasks-pattern` 等遗留词。
4. **职责检查**: 确认未生成任何业务内容（无 milestone-plan、无三件套实例）。

验证完成后，输出 Step 7 的完成摘要。
