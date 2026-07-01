# selection.md — Stage `patterns`（AP17 generate-filter 选优）

> Selector 角色（generate-and-filter）对 cand-1 / cand-2 做客观评分与选优。
> 比较基于可机械检查的证据（char_count 数值），不凭主观。

## VERIFY
- `VERIFY[AP2]: PASS — 已加载 selector-role skill，遵循其准则"比较必须基于可机械检查的证据（测试结果、是否满足标准、指标数值），不凭主观"。`
- `VERIFY[AP6]: PASS — selection.md 实际写入路径 /workspace/harness/milestones/harness-selftest/stages/patterns/selection.md。`

## 候选客观评分表

| 候选 | function_name | char_count | 命名清晰度（动词是否表达登录/校验动作） | 是否达标（AP17 候选产出 + 动词前缀） |
|------|---------------|-----------:|----------------------------------------|--------------------------------------|
| cand-1 | loginUser | 8 | 清晰：动词 login 直接表达登录动作，简洁 | 达标 |
| cand-2 | validate_user_credentials | 27 | 清晰：validate 表达校验动作，更明确"凭证校验"语义 | 达标 |

### 机械对比
- **标准1 char_count（更短更优）**：cand-1=8 < cand-2=27 → cand-1 胜（差值 19 字符，约 3.4× 更短）。
- **标准2 命名清晰度（动词是否表达登录动作）**：两者均以动词开头表达动作语义——cand-1 用 `login`（直接命中"登录"动作），cand-2 用 `validate`（强调"校验"动作）。本标准为定性"是否清晰"，二者均清晰，标准2 视为平局。
- **平局打破规则**：char_count 更少者胜 → cand-1。

## 选优结果

`winner: cand-1`

## 选择依据（基于 char_count 机械对比）
- cand-1 char_count=8，cand-2 char_count=27；按"char_count 更短者更优（更简洁）"的机械标准，cand-1 严格更优。
- 标准2（命名清晰度）两者均达标且均为平局，触发平局打破规则：char_count 更少者胜 → cand-1。
- 结论：cand-1（`loginUser`）以更短、更简洁的命名胜出；cand-2 在"校验语义明确性"上有侧重，但本 Stage 选优标准以简洁性（char_count）为客观主轴，故 winner=cand-1。

## 备注
- 仅做选优，不修改 cand-1/cand-2/contract.md/RULE.md/.trae/skills/。
- 选出的 cand-1 由 Orchestrator 推进到后续流程。
- 满足 contract.md AP17：selection.md 含 `winner: cand-1`。
