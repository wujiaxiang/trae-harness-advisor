# 项目规则（RULE.md）

> 本文件位于项目根目录，通过 TRAE Work 云端钩子规则自动加载。
> 钩子规则文本：`在开始执行任何任务之前，必须先读取当前项目根目录的 RULE.md 文件，将其内容作为当前项目的编码规范、约束条件和行为准则。如果 RULE.md 不存在，则跳过此步骤。`
> 当执行某个 Stage 时，加载 stage-orchestrator playbook 并遵循其确定性流程；stage-executor 仅为旧名兼容入口。
> 约束强度：本文件的禁止修改路径、白名单等均为**提示词级约束**（依赖模型遵守，非沙箱强制）；请严格遵守，但团队应辅以 CI/评审等硬手段兜底。
> 用户需将此钩子规则复制到 TRAE Work「设置 > 规则」中（仅需操作一次）。

## 常用命令
按项目技术栈填写并保持最新：

### Node.js / Web
- 启动开发服务器: `npm run dev`
- 运行全部测试: `npm test`
- 运行单个测试文件: `npm test -- {file}`
- Lint 检查: `npm run lint`

### Python
- 运行全部测试: `pytest`
- 运行单个测试文件: `pytest {file}`
- 类型检查: `mypy .`
- 格式检查: `ruff check .`

### Go
- 运行全部测试: `go test ./...`
- 运行单个包测试: `go test ./path/to/pkg`
- 格式化检查: `gofmt -w {file}`

## 关键目录结构
- src/ — 源代码
- tests/ — 测试文件
- harness/ — 持久真值与消息总线（milestone-plan、contract、gen/eval/decision、browser-check、state-board.json）
- harness/templates/ — 三件套与 Stage Contract 的结构骨架，只含章节契约，无业务内容
- tools/mcp-bridge/ — 可选 MCP shell bridge runtime fixture；由 `trae-mcp-bridge-advisor` 维护，仅在 `mcp_access_mode=evaluator_shell_bridge` 时使用
- harness/milestones/{milestone}/stages/{stage}/ — Stage 级持久产物目录
- .trae/specs/ — 原生 /spec 临时 scratch（gitignored，不依赖，不做消息传递）
- .trae/skills/ — 角色 Skill 与 stage-orchestrator playbook（静态配置，git 同步）
- .trae/agents/ — 可选 Agent 配置（未来兼容）

## 编码约定
- 禁止使用不安全的动态执行或字符串拼接查询
- 所有公共函数必须有清晰输入输出类型或文档
- 组件文件使用 PascalCase
- 工具函数文件使用 camelCase
- 测试文件命名为 `{filename}.test.ts`、`test_{filename}.py` 或项目既有约定
- 新增逻辑必须包含对应测试或在 gen.md 中说明无法自动化测试的原因

## 全局禁止修改
- harness/（除 Orchestrator 回写状态、contract/browser-check 与 gen/eval/decision 产物外）
- .trae/skills/
- RULE.md
- node_modules/
- .git/
- .env 文件
- dist/
- build/
- package.json / lockfile（除非 Stage Contract 明确授权）

## MCP bridge 约束（仅 evaluator_shell_bridge）
- MCP server 注册、安装命令、wrapper 所属 server、白名单与翻译样例由本项目 `config/mcporter.json` 自维护；不要依赖 TRAE UI 已注册 MCP 自动透传给 SubAgent。
- 任意 MCP server 的安装与调用必须同源：`mcpServers.*.args/install`、`bridgeWrappers.*.server/allowedTools`、`translationExamples` 必须匹配同一个 server 的真实 `tools/list` schema。
- 需要下载大二进制或外部运行时的 MCP（如浏览器、数据库客户端、仿真器）必须在 `config/mcporter.json` 的 `install` 中维护版本 pin、CDN/镜像和系统依赖安装命令。
- Stage Orchestrator 只能运行 `tools/mcp-bridge/check.sh --json` 并读取 `config/mcporter.json`，不得自由扫描未知 MCP 能力或临时扩权。
- Evaluator 只能调用 `contract.md` 中 `mcp_bridge_capabilities` 声明的白名单 shell wrapper 命令。
- Evaluator 不得直接调用官方通用 `npx mcporter call ...`；MCPorter 只作为 wrapper 的底层 runtime。wrapper 转发目标必须是 Mcporter 要求的 `server.tool` 形式。
- Evaluator 遇到 MCP 意图时，必须按 `contract.md` 中 `mcp_to_shell_translation` 改写成 RunCommand；不得寻找、编造或直接调用 `mcp__*` 工具，也不得猜测方法名/参数名。
- bridge 证据必须写入 `eval.md`；默认/回退的 Orchestrator 代行证据才写 `browser-check.md`。
- bridge 不可用时输出 `[BLOCKED: MCP bridge unavailable]`，白名单外命令输出 `[BLOCKED: MCP bridge command not allowed]`，不得假装验证通过。

## API 层约束（对应 src/api/**、src/services/** 或项目等价目录）
- 所有 API 路由必须有输入验证
- 所有 API 响应必须包含统一的错误格式
- 数据库查询必须使用参数化查询，禁止字符串拼接
- 每个 API 端点必须有对应的集成测试或契约测试
- 禁止在路由处理函数中直接操作数据库（必须通过 Service/Repository 层）
- 禁止返回原始数据库错误给客户端
- 鉴权、限流、审计日志要求必须在 Stage Contract 中明确
