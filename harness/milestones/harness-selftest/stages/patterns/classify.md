# classify.md — Stage `patterns`（AP16 classify 路由）

> 由 `@classifier-role` 子代理生成。模式 = classify-and-act（路由）。
> 输入串：`"fix the login 500 error"`；类别集合：`{bugfix, feature, refactor}`。
> 路由表（milestone-plan §104 AP16 提供）：bugfix→修复流程；feature→功能开发；refactor→重构流程。

## VERIFY

- VERIFY[AP2]: PASS — 已加载 `classifier-role` skill；复述其准则「你是一个分类器子代理（独立 SubAgent）。读取 spec/输入，判断它属于哪一类、应路由到哪个处理路径，输出结构化标签。不写代码、不评分。」
- VERIFY[AP6]: PASS — classify.md 实际写入路径 = `/workspace/harness/milestones/harness-selftest/stages/patterns/classify.md`（位于 harness/ 总线，符合白名单 `harness/milestones/{milestone}/stages/{stage}/classify.md`）。

## 分类结果

```json
{
  "label": "bugfix",
  "route": "修复流程",
  "confidence": "high",
  "reasoning": "输入串 \"fix the login 500 error\" 含动词 \"fix\"（修复），并明确出现 \"500 error\"（HTTP 500 服务器内部错误），二者均直接指向对既有登录接口的故障修复，既非新增功能（无 feature/add 类语汇）也非重构（无 refactor/restructure 类语汇）。依据输入中的具体证据 \"fix\" + \"500 error\"，归入 bugfix；路由表映射 bugfix→修复流程。"
}
```

## 备注
- 仅在给定类别集合 `{bugfix, feature, refactor}` 内选择（满足 classifier-role 行为规则 1）。
- 引用输入中具体证据做判断，未臆测（满足行为规则 2）。
- 路由目标「修复流程」为 milestone-plan 路由表中存在的目标（满足行为规则 3）。
- 本文件不执行路由（由 Orchestrator 据 classify.md 分支派发）；不写代码、不评分。
