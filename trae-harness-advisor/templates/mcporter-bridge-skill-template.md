---
name: mcporter-bridge
description: Evaluator SubAgent 使用 MCPorter/shell bridge 的专用翻译 Skill。仅在 mcp_access_mode=evaluator_shell_bridge 且 contract 声明白名单命令时使用。
---

# MCPorter Bridge Skill

## 目的
当你是 Evaluator SubAgent，且需要使用浏览器/MCP 能力时，不能直接寻找或编造 `mcp__*` 工具。你必须把 MCP 意图翻译成 `contract.md` 允许的 shell 命令，并用 RunCommand 执行。

这个 Skill 只负责“翻译和约束”，不授予 MCP 权限。真实 MCP 能力来自远程环境 install 阶段安装的 MCPorter/bridge wrapper。

## 必读输入
1. 当前 Stage 的 `contract.md`
2. `contract.md` 中的 `mcp_bridge_capabilities`
3. `contract.md` 中的 `mcp_to_shell_translation`
4. 需要时读取 `{harness_dir}mcp-bridge/manifest.json` 作为只读参考；不得绕过 contract 扩权

## 翻译规则
- 想导航页面：使用 contract 指定的 `mcp-browser navigate {url}`
- 想获取快照：使用 contract 指定的 `mcp-browser snapshot --output {path}`
- 想截图：使用 contract 指定的 `mcp-browser screenshot --output {path}`
- 想读取页面文本：使用 contract 指定的 `mcp-browser text`
- contract 没有声明的动作：输出 `[BLOCKED: MCP bridge command not allowed]`
- bridge 自检或命令不可用：输出 `[BLOCKED: MCP bridge unavailable]`

## 禁止事项
- 不得直接调用、猜测或要求 `mcp__Playwright__*` 等 MCP tool。
- 不得运行 contract 白名单以外的 bridge 命令。
- 不得用 bridge 修改生产状态、提交表单、删除数据或执行不可逆操作，除非 contract 明确授权且 Stage 验收需要。
- 不得把 Orchestrator 代行的 `browser-check.md` 当作本模式下的主要证据。

## 证据落盘
每次调用 shell bridge 后，在 `eval.md` 写清：
- 原始 MCP 意图
- 实际执行的 shell 命令
- 关键输出摘要
- 截图、snapshot、trace 或日志路径
- PASS / FAIL / BLOCKED 结论
