# Deliverable Specifications

> 本文件是 `trae-harness-advisor` Skill 的 Step 6 文件生成规格。
> 所有生成规则基于 `../templates/` 目录中的模板文件。

## 目录

1. [配置变量映射](#配置变量映射)
2. [目录结构](#目录结构)
3. [1. Planner Role Skill](#1-planner-role-skill)
4. [2. Generator Role Skill](#2-generator-role-skill)
5. [3. Evaluator Role Skill](#3-evaluator-role-skill)
6. [4. Generator SubAgent Config](#4-generator-subagent-config)
7. [5. Evaluator SubAgent Config](#5-evaluator-subagent-config)
8. [6. Decision SubAgent Config](#6-decision-subagent-config)
9. [7. Project Rules](#7-project-rules)
10. [8. 路径规则（多语言技术栈）](#8-路径规则multi-language-stack)
11. [9. SPEC 模板](#9-spec-模板)
12. [10. 编排模式参考](#10-编排模式参考)
13. [11. Sprint Contract 模板](#11-sprint-contract-模板)
14. [12. 全局任务看板](#12-全局任务看板)
15. [13. 生成后验证](#13-生成后验证)

---

## 配置变量映射

从用户 Q&A 收集的配置映射到模板变量：

| 问题 | 变量名 | 默认值 |
|------|--------|--------|
| Q1: task_type | `{task_type}` | `"development"` |
| Q2: tech_stack | `{tech_stack}` | 用户输入 |
| Q3: project_scale | `{project_scale}` | `"medium"` |
| Q4: skill_dir | `{skill_dir}` | `".trae/skills/"` |
| Q5: agent_dir | `{agent_dir}` | `".trae/agents/"` |
| Q6: generate_agents | `{generate_agents}` | `false` |
| Q7: spec_dir | `{spec_dir}` | `"harness-specs/{feature}/"` |
| Q8: eval_dir | `{eval_dir}` | `"eval/"` |
| Q9: contract_dir | `{contract_dir}` | `"harness-contracts/{feature}/"` |
| Q10: use_task_board | `{use_task_board}` | `false` |
| Q11: max_adversarial_rounds | `{max_rounds}` | `3` |
| Q12: eval_strictness | `{eval_strictness}` | `"standard"` |
| Q13: max_contract_rounds | `{contract_rounds}` | `3` |
| Q14: force_contract | `{force_contract}` | `true` |
| Q15: tdd_mode | `{tdd_mode}` | `"standard"` |
| Q16: verification_mode | `{verification_mode}` | `"full"` |
| Q17: use_calibration | `{use_calibration}` | `false` |
| Q18: custom_acceptance_rules | `{custom_rules}` | `"none"` |

### 评分严格度映射

| 严格度 | 通过阈值 | 单项最低分 |
|--------|----------|-----------|
| `relaxed` | 总分 >= 14/20 | 无单项 < 3 |
| `standard` | 总分 >= 16/20 | 无单项 < 4 |
| `strict` | 总分 >= 18/20 | 无单项 < 4 |

### TDD 模式映射

| 模式 | 行为描述 |
|------|---------|
| `relaxed` | 先实现，Sprint 结束前补齐测试 |
| `standard` | 先写测试 → 确认失败 → 实现 → 全部通过 |
| `strict` | red-green-refactor 循环，覆盖率 >= 80% |

### 验证模式映射

| 模式 | 包含步骤 |
|------|---------|
| `quick` | 自动化测试 + 代码审查 |
| `automated` | 代码审查 + 自动化测试 + Lint |
| `full` | 代码审查 + 自动化测试 + Lint + 浏览器测试 + 截图 |

---

## 目录结构

先创建目标目录（如果不存在）：

```
{skill_dir}                    # 默认 .trae/skills/
├── planner-role/SKILL.md
├── generator-role/SKILL.md
└── evaluator-role/SKILL.md
RULE.md                        # 项目根目录（替代 .trae/rules/，TRAE Work 云端通过钩子规则加载）
（可选）{agent_dir}            # 默认 .trae/agents/（仅 generate_agents=true 时生成）
├── generator.md
├── evaluator.md
└── decision.md
{spec_dir}/{feature}/          # 默认 harness-specs/{feature}/
└── tasks-pattern.md
{contract_dir}/{feature}/      # 默认 harness-contracts/{feature}/
└── sprint-N.md
{eval_dir}                     # 默认 eval/
└── (运行时创建)
global_task_board.json (可选)
```

注意：
- spec.md（空模板）由 Planner 在 `/spec` 阶段生成到 `{spec_dir}/{feature}/spec.md`，不在专家 Skill 输出范围内
- `.trae/rules/` 已删除——TRAE Work 不支持 `.trae/rules/` 目录，项目规范改为 RULE.md + 钩子规则方案
- Agent 配置文件为可选生成——当前 TRAE Work 云端不支持 `.trae/agents/`，Agent 角色行为已内嵌到 Skill 中

---

## 1. Planner Role Skill

**文件路径**: `{skill_dir}planner-role/SKILL.md`

**生成规则**: 基于 `templates/planner-skill-template.md`，保持不变的核心内容。根据 `{task_type}` 调整：

- `development` → 描述中强调"需求分析、任务拆解、Sprint 分解"
- `verification` → 描述中强调"验收标准定义、测试用例设计、验证流程规划"
- `hybrid` → 包含两者

**核心内容（必须保留）**:
- 职责：需求 → 产品规格 + Sprint 分解（战略级别）
- 行为准则 6 条（只描述做什么/为什么、机械可检查的验收标准、依赖识别、确定性语言、量化指标、Sprint 粒度适中）
- **Planner 只输出 spec.md 和更新 global_task_board.json，不输出 tasks.md 和 checklist.md**
- **tasks.md 由云端 Agent 运行时动态生成**，读取 spec.md + 全局任务表后，按照 Harness 编排模式（见 tasks-pattern.md）自动生成

---

## 2. Generator Role Skill

**文件路径**: `{skill_dir}generator-role/SKILL.md`

**生成规则**: 基于 `templates/generator-skill-template.md`。根据 `{tdd_mode}` 调整 TDD 行为描述：

- `relaxed`: "先实现核心功能，Sprint 结束前补齐测试"
- `standard`: "先写测试 → 确认测试失败 → 再写实现"
- `strict`: "严格遵循 red-green-refactor 循环，确保测试覆盖率 >= 80%"

**跳过条件**: `{task_type}` 为 `"verification"` 时跳过 Generator Skill 生成。

**核心内容（必须保留）**:
- 职责：按 Sprint 实现功能，不评价自己代码
- 行为准则 8 条
- 实现总结格式

---

## 3. Evaluator Role Skill

**文件路径**: `{skill_dir}evaluator-role/SKILL.md`

**生成规则**: 基于 `templates/evaluator-skill-template.md`。根据 `{eval_strictness}` 调整评分阈值，根据 `{verification_mode}` 调整验证步骤：

- 严格度阈值见上方映射表
- `quick` 模式: 移除"必须实际启动应用并通过浏览器测试"要求，替换为"必须运行全部自动化测试"
- `automated` 模式: 移除"必须截图留证"，替换为"必须运行 Lint 检查"
- `full` 模式: 保留所有要求

**核心内容（必须保留）**:
- 职责：以"怀疑者"身份验证，不妥协
- 四维评分标准（功能性、工艺质量、完整性、用户体验）
- 判定规则（含严格度阈值）
- 行为准则 6 条
- 评估报告格式

**如果 `{use_calibration}` = true**: 在 Skills 末尾追加"校准参考"章节，包含 2-3 个历史评分案例作为 few-shot 示例。

**如果 `{custom_rules}` != "none"**: 在行为准则中追加一条："9. 特殊验收规则: {custom_rules}"

---

## 4. Generator SubAgent Config（可选）

**生成条件**: 仅当 `{generate_agents}` = true 时生成。

**文件路径**: `{agent_dir}generator.md`

> 注意：当前 TRAE Work 云端不支持 `.trae/agents/` 目录，Agent 角色行为已内嵌到 generator-role Skill 中。此文件为未来兼容保留。

**生成规则**: 基于 `templates/generator-agent-template.md`。根据 `{force_contract}` 调整行为：

- 如果 `{force_contract}` = true: 追加规则 "0. 必须等待 Sprint Contract 被 Evaluator 批准后才开始编码"
- 如果 `{force_contract}` = false: 追加规则 "0. 可直接从 spec.md 开始实现，无需等待 Contract 批准"

**跳过条件**: `{task_type}` 为 `"verification"` 时跳过。

**核心内容（必须保留）**:
- 角色定义
- 工具集（Read, Write, Edit, Glob, Grep, Bash）
- 路径白名单（允许修改：src/, tests/, {eval_dir}；禁止修改：{spec_dir}, {contract_dir}, {skill_dir}）
- 行为规则 5 条

---

## 5. Evaluator SubAgent Config（可选）

**生成条件**: 仅当 `{generate_agents}` = true 时生成。

**文件路径**: `{agent_dir}evaluator.md`

> 注意：当前 TRAE Work 云端不支持 `.trae/agents/` 目录，Agent 角色行为已内嵌到 evaluator-role Skill 中。此文件为未来兼容保留。

**生成规则**: 基于 `templates/evaluator-agent-template.md`。根据 `{verification_mode}` 调整工具集：

- `quick`: 工具集移除 "Playwright MCP"
- `automated`: 工具集移除 "Playwright MCP"，追加 "MCP Linter"
- `full`: 保留 "Playwright MCP" 和全部工具

**核心内容（必须保留）**:
- 角色定义（严格的 QA 工程师，怀疑者）
- 工具集
- 路径白名单（允许读取全部，允许写入仅 {eval_dir}，禁止修改任何代码文件）
- 行为规则 7 条

---

## 6. Decision SubAgent Config（可选）

**生成条件**: 仅当 `{generate_agents}` = true 时生成。

**文件路径**: `{agent_dir}decision.md`

> 注意：当前 TRAE Work 云端不支持 `.trae/agents/` 目录，Decision 角色定义已内嵌到 evaluator-role Skill 中。此文件为未来兼容保留。

**生成规则**: 基于 `templates/decision-agent-template.md`。根据 `{max_rounds}` 和 `{eval_strictness}` 调整：

- 裁决规则中的通过阈值映射到 Evaluator 严格度阈值
- `max_rounds` 写入 escalate 条件："已重试 {max_rounds} 次仍未通过"

**核心内容（必须保留）**:
- 角色定义（中立裁决者，Orchestrator 代理，不写代码不评估代码）
- 工具集（仅 Read，只读不写代码）
- 路径白名单（允许读取 {eval_dir}、{contract_dir}、{spec_dir}；允许写入仅 {eval_dir}/xxx-decision-N.md）
- 裁决规则（pass/retry/escalate 三种结果的条件）
- 行为规则 7 条

---

## 7. RULE.md（项目规范）

**文件路径**: `RULE.md`（项目根目录）

**设计说明**: TRAE Work 不支持 `.trae/rules/` 目录。替代方案是在 TRAE Work「设置 > 规则」中创建一条云端钩子规则，让所有云端 Task 启动时自动读取项目根目录的 `RULE.md`。钩子规则文本由专家 Skill 在生成完成后输出，用户复制粘贴即可。

**生成规则**: 基于 `templates/project-rules-template.md`。根据 `{tech_stack}` 和 `{project_scale}` 定制：

- **常用命令**: 根据 `{tech_stack}` 推断。例如 React → 追加 `npm run dev` / `npm test`；Python → 追加 `pytest` / `python -m uvicorn`；Go → 追加 `go test ./...` / `go build`
- **关键目录结构**: 追加 `{spec_dir}`, `{eval_dir}`, `{contract_dir}` 的实际路径
- **编码约定**: 根据 `{tech_stack}` 推断语言特定约定
- **全局禁止修改**: 追加 `{spec_dir}`、`{contract_dir}`、`{skill_dir}`

**如果 `{custom_rules}` != "none"**: 在"编码约定"章节追加自定义规则。

---

## 8. 钩子规则文本

**文件路径**: 不生成文件，直接在对话中输出文本供用户复制。

**内容**: 用户复制到 TRAE Work「设置 > 规则」中创建云端规则：

```
在开始执行任何任务之前，必须先读取当前项目根目录的 RULE.md 文件，将其内容作为当前项目的编码规范、约束条件和行为准则。如果 RULE.md 不存在，则跳过此步骤。
```

---

## 9. SPEC 模板

### spec.md

**注意：spec.md 不在专家 Skill 的输出范围内。** 专家 Skill 只生成 `tasks-pattern.md`（编排模式参考）。spec.md 的生成流程如下：

1. **Planner**（`/spec` 阶段）生成 spec.md **空模板**（只有结构框架，占位符）
2. **主Agent**（云端运行时）读取模板 + 全局 Sprint 文档 → 推理填充 spec.md 具体内容
3. **主Agent** 根据填充后的 spec.md 生成 tasks.md

spec.md 模板的结构参考 `templates/spec-template.md`。Planner 根据业务需求形态定制模板结构，但只填充结构框架，不填充具体内容。

**如果 `{task_type}` = "verification"**: Planner 在模板中额外添加"验证范围"章节占位符。

---

## 10. 编排模式参考

### tasks-pattern.md

**文件路径**: `{spec_dir}/{feature}/tasks-pattern.md`

**⚠️ 这不是预生成的 tasks.md**。这是编排模式参考——云端 Agent 启动时读取此文件，理解 Harness 编排模式，然后**动态生成**实际的 tasks.md。

**生成规则**: 生成一个包含完整 PGE 编排模式的参考文档：

```markdown
# Harness 编排模式参考

> 云端 Agent 启动时读取此文件，理解对抗编排模式，动态生成 tasks.md。
> 不要直接使用此文件作为 tasks.md——它需要根据 spec.md 的实际 Sprint 填充。

## 四角色编排模式

每个 Sprint 遵循以下流程：

```
[Sprint Start]
      ↓
[GENERATOR] → 提出 Sprint Contract 草案
      ↓
[EVALUATOR] → 审查 Contract（批准后才可编码）
      ↓
[GENERATOR] → 按 Contract 实现（TDD）
      ↓
[GENERATOR] → 实现总结 → eval/{feature}-gen-{N}.md
      ↓
[EVALUATOR] → 评估验证 → eval/{feature}-eval-{N}.md
      ↓
[DECISION]  → 读取两份报告 → 裁决
      ↓
  pass     → 进入下一 Sprint
  retry    → 回到 [GENERATOR]，附带 Decision 的 retry_focus
  escalate → 暂停，请求人类裁决
```

## tasks.md 生成规则

云端 Agent 生成 tasks.md 时必须遵循以下规则：

1. 读取 spec.md 的 Sprint 分解，为每个 Sprint 生成一个循环块
2. 每个 Sprint 块包含 6 个步骤：GENERATOR(Contract) → EVALUATOR(Contract审查) → GENERATOR(实现) → GENERATOR(总结) → EVALUATOR(评估) → DECISION(裁决)
3. 每个步骤标注角色标记：[GENERATOR]、[EVALUATOR]、[DECISION]
4. 角色标记后注明：加载对应 Skill，使用 SubAgent 独立上下文
5. max_rounds 配置：{max_rounds}
6. eval_strictness 配置：{eval_strictness}

## 生成的 tasks.md 示例结构

```markdown
# {Feature Name} — 任务分解

## 产品概述
（从 spec.md 提取）

## 技术栈
（从 spec.md 提取）

## 任务列表

### 阶段 1: 初始化
- [ ] 读取 spec.md 理解产品需求
- [ ] 读取 tasks-pattern.md 理解编排模式
- [ ] 读取 global_task_board.json 同步状态

### 阶段 2: Sprint 循环（max_rounds={max_rounds}）

#### Sprint 1: {从 spec.md 提取的 Sprint 名称}
- [ ] [GENERATOR] 提出 Sprint Contract 草案 → {contract_dir}/{feature}/sprint-1.md
- [ ] [EVALUATOR] 审查 Contract，批准或要求修改
- [ ] [GENERATOR] 按 Contract 实现（TDD: {tdd_mode}）
- [ ] [GENERATOR] 实现总结 → {eval_dir}/{feature}-gen-1.md
- [ ] [EVALUATOR] 评估验证（严格度: {eval_strictness}）→ {eval_dir}/{feature}-eval-1.md
- [ ] [DECISION] 裁决 → {eval_dir}/{feature}-decision-1.md

#### Sprint 2: {从 spec.md 提取的 Sprint 名称}
- [ ] [GENERATOR] 提出 Sprint Contract 草案 → ...
- ...（同上结构，重复 N 个 Sprint）

### 阶段 3: 最终验收
- [ ] [EVALUATOR] 全量回归测试
- [ ] [EVALUATOR] 最终评估报告 → {eval_dir}/{feature}-final.md

## 角色引用
- Generator: 加载 @generator-role Skill，使用 SubAgent general_purpose_task
- Evaluator: 加载 @evaluator-role Skill，使用 SubAgent general_purpose_task
- Decision: 加载 @decision 配置，使用 SubAgent general_purpose_task
```
```

---

## 11. Sprint Contract 模板

**文件路径**: `{contract_dir}/{feature}/sprint-N.md`

**生成规则**: 基于 `templates/sprint-contract-template.md`。生成一个可复用的模板文件，顶部注明：

```
# Sprint {N} Contract 模板
> 本模板由 PGE Harness Advisor 生成。每个 Sprint 开始时复制此模板并填充实际内容。
```

然后包含模板的完整内容（本轮目标、实现范围、验收标准、依赖、预估风险、Evaluator 审查区）。

**如果 `{force_contract}` = false**: 在模板顶部追加注释 "> 注意: 当前配置为可选 Contract 模式，Generator 可直接实现，无需等待批准。"

---

## 12. 全局任务看板

**生成条件**: 仅当 `{use_task_board}` = true 时生成。

**文件路径**: `global_task_board.json`

**内容**: 一个 JSON 文件，用于跨 session 跟踪所有 SPEC 任务的状态：

```json
{
  "board_version": "1.0",
  "created_at": "{当前 ISO 时间戳}",
  "features": [
    {
      "id": "{feature_name}",
      "status": "planned",
      "spec_dir": "{spec_dir}",
      "contract_dir": "{contract_dir}",
      "eval_dir": "{eval_dir}",
      "sprints": [],
      "created_at": "{当前 ISO 时间戳}",
      "updated_at": "{当前 ISO 时间戳}"
    }
  ]
}
```

---

## 11. 生成后验证

生成所有文件后，执行以下验证：

1. **目录检查**: 确认所有目录已创建
2. **文件计数**: 确认文件数量正确（核心交付物为 7 个文件：3 个 Skill + RULE.md + 钩子规则文本 + tasks-pattern.md + Sprint Contract 模板；可选 +3 个 Agent 配置）
3. **引用检查**: 确认生成的文件中路径引用使用了用户配置的实际路径

验证完成后，输出 Step 7 的完成摘要。