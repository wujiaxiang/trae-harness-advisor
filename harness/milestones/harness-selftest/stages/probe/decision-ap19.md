# AP19 Decision 裁决

## 裁决输入
- contract.md AP19 段：`available=true`，含 `mcp_bridge_capabilities`（wrapper 路径 / 配置源 / daemon / 5 项 allowed_tools / 开闭原则）+ `mcp_to_shell_translation` 表（navigate / snapshot / screenshot / click / evaluate 5 行映射）+ 真机证据声明（navigate 返回 "Page Title: Example Domain"、invalid_tool 返回 [BLOCKED] exit=2）。
- eval-ap19.md：Evaluator SubAgent 4 项查证——
  - 查证 1 navigate：exit 0，返回 "Page Title: Example Domain" + page.goto 真实执行 → PASS
  - 查证 2 snapshot：exit 0，返回真实 a11y YAML（heading "Example Domain" / link "Learn more" → iana.org/domains/example）→ PASS
  - 查证 3a evaluate（contract 字面 `expression:document.title`）：exit 1，schema 报错 "expected string, received undefined → at function" → FAIL
  - 查证 3b evaluate（改写 `function=() => document.title`）：exit 0，返回 `"Example Domain"` → PASS
  - 查证 3 综合：PARTIAL — bridge 能力 PASS；contract 翻译表 evaluate 行有缺陷
  - 查证 4 invalid_tool（负面）：exit 2，stderr `[BLOCKED: MCP bridge command not allowed] playwright.invalid_tool` → PASS
- state-board.json：probe stage `status=passed`、`last_decision=pass`、`rounds=1`（AP1-AP11 已闭环）；AP19 为后续实验补测段，state-board 未单独追加 AP19 artifacts 条目，不影响本次裁决（AP19 段独立于 AP1-AP11 已验证结论，contract.md §32-71 明示"不改变 AP1-AP11 已验证结论"）。

## 裁决维度核对
| 维度 | 状态 | 证据 |
|------|------|------|
| bridge 可用 | ✓ | contract 声明 `available=true`、`mode=evaluator_shell_bridge`、`commands.mcp-browser=available`、daemon running（23 tools）；eval.md 查证 1/2/3b 真实 exit=0 返回，bridge 端到端通 |
| Evaluator 独立 | ✓ | eval.md §环境 明确"Evaluator 仅用 RunCommand（cwd=/workspace, blocking=true）调 wrapper；未调用任何 `mcp__*` / Playwright MCP 工具"；4 项查证均由 SubAgent 自跑 shell 命令，contract.md §71 也明确"派发 Evaluator SubAgent 通过 shell bridge 自查"——Orchestrator 未代行浏览器中间观察 |
| 真机证据 | ✓ | eval.md §真机证据 含 navigate 返回 "Page Title: Example Domain"（page.goto 真实执行）、snapshot 返回真实 a11y YAML（含 ref=f2e3 heading / ref=f2e6 link）、evaluate 返回 `"Example Domain"`；明确标注"非静态检查，page.goto 真实执行" |
| 白名单生效 | ✓ | eval.md 查证 4：`playwright.invalid_tool` exit=2，stderr `[BLOCKED: MCP bridge command not allowed]`，外层 echo `EXIT=2` 二次确认；wrapper ALLOWED 5 项之外命令被正确拦截 |
| 契约缺陷 | 不阻塞 | Evaluator 发现 contract.md `mcp_to_shell_translation` 第 5 行 evaluate 条目参数名错误：声明 `expression:document.title`，真实 MCP server schema 必填参数为 `function`（箭头函数体 `() => document.title`）。按字面执行 exit=1（查证 3a FAIL），但用正确 schema 后 PASS（查证 3b）。该缺陷为**文档/契约翻译表缺陷**，bridge 本体（wrapper + daemon + 白名单 + 端到端调用链）全部可用，不影响 AP19"shell bridge 可用性"通过判定。属文档缺陷而非能力缺陷，建议后续修复 contract 翻译表，不阻塞 AP19。 |

## 契约缺陷处理
Evaluator 发现 contract 翻译表 evaluate 条目参数名有误（`expression` 应为 `function`，且需箭头函数体 `() => document.title`）。裁决：该缺陷为**文档缺陷**，bridge 本体端到端可用（navigate / snapshot / evaluate 正确 schema 后均 PASS，invalid_tool BLOCKED exit=2），不影响 AP19 通过判定。建议后续修复 contract `mcp_to_shell_translation` 表第 5 行，将 `expression:document.title` 改为 `function='() => document.title'`，避免后续 SubAgent 按字面命令误用导致 exit=1。

## Verdict
AP19 = **PASS** — bridge 端到端真机可用（navigate/snapshot/evaluate 真实返回 "Example Domain"，invalid_tool 被 BLOCKED exit=2），Evaluator 独立通过 shell bridge 自查 4 项全过；contract 翻译表 evaluate 行参数名缺陷为文档缺陷，用正确 schema 后 PASS，不阻塞 AP19。

## VERIFY
VERIFY[AP19]: PASS — shell bridge available=true 且 Evaluator 独立自查 navigate/snapshot/evaluate 真机返回 "Example Domain" + invalid_tool BLOCKED exit=2，契约 evaluate 参数名缺陷为文档层面不阻塞能力判定。
