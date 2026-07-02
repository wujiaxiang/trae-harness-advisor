---
name: stage-executor
description: >
  兼容旧触发名。当用户说“执行 Stage”“开始阶段”“run stage”或要求推进当前 Stage 时使用。
  本 Skill 已更名为 stage-orchestrator；加载后必须立即转用 @stage-orchestrator。
---

# stage-executor compatibility shim

`stage-executor` 是历史名称，容易被误解为叶子执行器；当前权威名称是 **Stage Orchestrator**。

执行任何 Stage 时，请加载并遵循 `@stage-orchestrator`。本文件只保留旧触发短语兼容，不定义独立流程。
