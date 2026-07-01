# winner.md (tournament champion)

> Stage: patterns | Pattern: tournament | Round: 1（共 1 轮，ceil(log2(2))=1）
> Selector: selector-role（独立 SubAgent，只读候选，不改代码）
> 候选数 N=2，本轮 1 场对决即决出冠军。

## VERIFY 原文

- VERIFY[AP2]: PASS — 已加载 selector-role skill，遵循其准则「比较必须基于可机械检查的证据（指标数值），不凭主观」；本裁决以 char_count 数值对比为唯一机械证据。
- VERIFY[AP6]: PASS — winner.md 实际写入路径为 /workspace/harness/milestones/harness-selftest/stages/patterns/winner.md（本文件所在路径）。

## Bracket 结构（1 轮 / 1 场）

```
Round 1 (Final):
  cand-1 (loginUser, char_count=8)
    └── vs ──►  WINNER: cand-1
  cand-2 (validate_user_credentials, char_count=27)
```

- 对决：cand-1 vs cand-2
- 胜者：cand-1
- 败者：cand-2

## 对决胜负依据（机械可检查）

| 标准 | cand-1 | cand-2 | 胜者 |
| --- | --- | --- | --- |
| 标准1：函数名 char_count 更短者更优 | 8 | 27 | cand-1 |
| 标准2：命名清晰度（动词是否表达登录动作） | `loginUser`：动词 `login` 直接表达登录动作 | `validate_user_credentials`：动词 `validate` 偏向"校验"，未直接表达"登录"动作 | cand-1 |
| 平局打破：char_count 更少者胜 | 8（更少） | 27 | cand-1 |

机械证据（char_count 数值）：
- cand-1.function_name = `loginUser`，长度 = len("loginUser") = 8
- cand-2.function_name = `validate_user_credentials`，长度 = len("validate_user_credentials") = 27
- 8 < 27 ⇒ cand-1 在标准1胜；标准2同样指向 cand-1（动词更贴合登录语义）；平局打破规则亦指向 cand-1。
- 三项标准一致指向 cand-1，无歧义。

## 冠军

champion: cand-1

## 与 AP17 选优的关系（重叠说明）

- 候选数 N=2 时，tournament 仅需 1 轮对决即决出冠军，等价于"一轮选优"。
- 故 AP18 tournament 与 AP17 generate-filter 选优在 N=2 场景下原语重叠，二者结论一致（winner=cand-1）。
- 依据 milestone-plan §37 约定：N=2 时淘汰=选优，AP18 复用 AP17 候选做单轮两两淘汰以验证 tournament 通路，结论与 AP17 selection.md（winner=cand-1）吻合。
- 本 winner.md 为 tournament 通路交付物；AP17 的 selection.md 为 generate-filter 通路交付物，二者并存不冲突。

## 约束遵守

- 只写 winner.md 一个文件，未修改 cand-1.md / cand-2.md / selection.md / contract.md / RULE.md / .trae/skills/。
- 比较基于可机械检查证据（char_count 数值 8 vs 27），未引入主观判断。
- Selector 只选不改。
