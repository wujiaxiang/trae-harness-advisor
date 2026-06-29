# Deliverable Specifications (v4.2)

> 本文件是 `trae-harness-advisor` Skill 的 Step 6 文件生成规格。
> 术语与架构以 `../resources/harness-engineering-on-trae-work.md` 第零部分为权威。
> 核心理念：Advisor 只生成**脚手架与指导思想**（角色 Skill、stage-executor playbook、结构骨架、RULE.md、空 board），**不生成任何业务内容**。三件套由 Orchestrator 运行时产出。

## 目录

1. [配置变量映射](#配置变量映射)
2. [目录结构](#目录结构)
3. [1. Planner Role Skill](#1-planner-role-skill)
4. [2. Generator Role Skill](#2-generator-role-skill)
5. [3. Evaluator Role Skill](#3-evaluator-role-skill)
6. [4. stage-executor Playbook Skill](#4-stage-executor-playbook-skill)
7. [5. RULE.md（项目规范）](#5-rulemd项目规范)
8. [6. 钩子规则文本](#6-钩子规则文本)
9. [7. 三件套骨架模板](#7-三件套骨架模板)
10. [8. stage-contract 骨架](#8-stage-contract-骨架)
11. [9. state-board.json（v2 空表）](#9-state-boardjson-v2-空表)
12. [10. 可选 Agent 配置](#10-可选-agent-配置)
13. [11. 生成后验证](#11-生成后验证)

---

## 配置变量映射

问题编号与 `SKILL.md` 工作流 Step 1-4 的 12 个问题严格对应。`skill_dir`、`agent_dir` 不在问答中询问，使用默认值：

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

> 注：`task_type` 决定 Milestone 的默认 `kind`（development→development，verification→verification，hybrid→由 Planner 按 Milestone 区分）。Stage 目录路径固定在 `{harness_dir}` 下，不再单独询问 spec/eval/contract 目录。state-board.json 为核心产物，始终生成。**Contract 已简化为 Orchestrator 一次标注关键点（见 stage-executor），不再有多轮协商，故无 `max_contract_rounds`。**

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

| 模式 | 包含步骤 |
|------|---------|
| `quick` | 自动化测试 + 代码审查 |
| `automated` | 代码审查 + 自动化测试 + Lint |
| `full` | 代码审查 + 自动化测试 + Lint + 浏览器测试 + 截图 |

---

## 目录结构

先创建目标目录（如果不存在）：

```
{skill_dir}                       # 默认 .trae/skills/（静态/git）
├── planner-role/SKILL.md
├── generator-role/SKILL.md       # 内嵌 Agent 工具集 + 路径白名单
├── evaluator-role/SKILL.md       # 业务质量四维评分（不含裁决）
├── decision-role/SKILL.md        # 独立中立裁决者
└── stage-executor/SKILL.md       # 运行时拉起 playbook
RULE.md                           # 项目根目录（钩子规则加载）
{harness_dir}                     # 默认 harness/（持久真值 + 消息总线）
├── templates/
│   ├── spec.skeleton.md
│   ├── tasks.skeleton.md
│   ├── checklist.skeleton.md
│   └── stage-contract.skeleton.md
└── state-board.json              # v2 空表
（可选）{agent_dir}               # 默认 .trae/agents/（仅 generate_agents=true）
├── generator.md  evaluator.md  decision.md
.trae/specs/ → 加入 .gitignore（原生临时 scratch，不生成、不依赖）
```

运行时由 Orchestrator 创建（**不在 Advisor 输出范围**）：
- `{harness_dir}milestones/{milestone}/milestone-plan.md`（Planner 产出）
- `{harness_dir}milestones/{milestone}/stages/{stage}/{spec,tasks,checklist,contract,gen,eval,decision}.md`

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
- 职责：用户需求 → 一个 Milestone（标注 `kind`）+ 战略分解为若干 Stage（含 `depends_on`）
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
- 工具集 + 路径白名单（只读全部；只写 `.../eval.md`）
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
- 工具集：Read（gen/eval/contract/spec/board）+ Write（仅 decision.md）
- 输入：`gen.md`+`eval.md`+`contract.md`+ 当前 rounds
- 输出：`decision.md`（JSON：verdict pass/retry/escalate + reasoning + retry_focus/escalation_reason）
- 裁决规则：pass / retry（rounds < `{max_rounds}`，必给 retry_focus）/ escalate（rounds 达上限或根本分歧）
- **交接约定**：Decision 只裁决、不执行 retry；retry 的后续（改 tasks.md + 重派 Generator）由 Orchestrator 承担；Decision 不能自我循环

---

## 4. stage-executor Playbook Skill

**文件路径**: `{skill_dir}stage-executor/SKILL.md`

**生成规则**: 基于 `templates/stage-executor-skill-template.md`。这是 **L2 的单一运行时入口**，触发短语如"执行 Stage / 开始阶段 / run stage"。

**核心内容（必须保留，确定性过程）**:
1. 读 `{harness_dir}state-board.json` → 定位当前 Stage，校验 `depends_on` 全部 `passed`
2. 读 `{harness_dir}milestones/{milestone}/milestone-plan.md` → 取该 Stage 定义
3. 运行 `/spec`，按 `{harness_dir}templates/*.skeleton.md` 产出三件套；`.trae/specs/` 产物可弃。tasklist 显式要求 subagent 把交付物**写入总线** `{harness_dir}milestones/{milestone}/stages/{stage}/`（不依赖 `/spec` 路径）
4. **自检门**：spec 章节齐全？tasks 与 checklist 1:1 映射？否 → 停止并报告
5. 派发**三个独立 SubAgent**：`[GENERATOR]`(generator-role) → `[EVALUATOR]`(evaluator-role) → `[DECISION]`(decision-role，独立盲审)。Orchestrator 只串联、不兼任任何角色
6. 据 `decision.md` 的 verdict：pass→checklist gate；**retry→Orchestrator 改 tasks.md 追加返工任务 + 带 retry_focus 重派 Generator（rounds+1）**；escalate→暂停回写 board
7. 回写 `state-board.json`：`status / rounds / last_decision / artifacts`（最小更新）

> 强调：三件套内容由 Orchestrator 运行时推理，骨架只给章节契约。不要预生成业务内容。Orchestrator 不得自己兼任 Generator/Evaluator/Decision。

---

## 5. RULE.md（项目规范）

**文件路径**: `RULE.md`（项目根目录）

**设计说明**: TRAE Work 不支持 `.trae/rules/`。在「设置 > 规则」建一条云端钩子规则让每个 Task 启动读 `RULE.md`；`RULE.md` 顶部指向 `stage-executor` playbook。

**生成规则**: 基于 `templates/project-rules-template.md`，按 `{tech_stack}`、`{project_scale}` 定制：
- **常用命令**: 按 `{tech_stack}` 推断（React→`npm run dev`/`npm test`；Python→`pytest`；Go→`go test ./...` 等）
- **关键目录结构**: `{harness_dir}`（持久总线）、`.trae/specs/`（临时 scratch，gitignore）
- **编码约定**: 按 `{tech_stack}` 推断
- **全局禁止修改**: `{harness_dir}`、`{skill_dir}`、`RULE.md`、`node_modules/`、`.git/`、`.env`
- **入口指引**: "执行某个 Stage 时，加载 stage-executor playbook 并遵循其确定性流程"
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
      "artifacts": { "spec": "", "tasks": "", "checklist": "", "contract": "", "eval": "" }
    }]
  }]
}
```

- `milestone-plan.md` = 定义（静态只读）；`state-board.json` = 状态机（动态唯一真值）。两者不重复：plan 描述"是什么"，board 记录"到哪一步"。
- **写协议（最小更新）**：无引擎锁；每次只对当前 Stage 那一条记录做最小字段更新，不整体重写、不动其它 Stage → 不相交小改动，git 合并不冲突。
- **并发语义**：Stage 并发 = 人类开多个独立云端对话，非自动调度；`depends_on` 是人工投递前的代码冲突规避依据（确认依赖已 passed 且无源文件交集），非自动门控。

---

## 10. 可选 Agent 配置

**生成条件**: 仅当 `{generate_agents}=true`。当前云端不支持 `.trae/agents/`，角色行为已内嵌 Skill；此为未来兼容保留。

| 文件 | 模板 | 要点 |
|------|------|------|
| `{agent_dir}generator.md` | `templates/generator-agent-template.md` | 工具集 + 路径白名单（可改 src/、tests/；禁改 {harness_dir}） |
| `{agent_dir}evaluator.md` | `templates/evaluator-agent-template.md` | 只读全部、只写 eval.md；`{verification_mode}` 调工具集 |
| `{agent_dir}decision.md` | `templates/decision-agent-template.md` | 仅 Read；裁决阈值映射 `{eval_strictness}`；escalate 条件含 `{max_rounds}` |

跳过：`{task_type}="verification"` 时跳过 generator.md。

---

## 11. 生成后验证

生成所有文件后执行：

1. **目录检查**: `{skill_dir}` 5 个角色/playbook 目录（planner/generator/evaluator/decision/stage-executor）、`{harness_dir}templates/`、`{harness_dir}state-board.json` 均已创建。
2. **文件计数**: 核心 **11 个文件**（5 个 Skill：planner/generator/evaluator/decision/stage-executor + RULE.md + 4 个骨架：spec/tasks/checklist/stage-contract + state-board.json），外加 1 段钩子规则文本（非文件）；可选 +3 个 Agent 配置。`task_type=verification` 时 generator-role 跳过 → 核心 10 个文件。
3. **引用检查**: 生成文件中的路径使用 `{harness_dir}`、`{skill_dir}` 实际值；无 `feature`/`sprint`/`tasks-pattern` 等遗留词。
4. **职责检查**: 确认未生成任何业务内容（无 milestone-plan、无三件套实例）。

验证完成后，输出 Step 7 的完成摘要。
