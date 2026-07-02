# AP19 Evaluator 自查报告（shell bridge）

## 环境
- bridge: available（`bash harness/mcp-bridge/check.sh --json` → `available:true`, `mode:evaluator_shell_bridge`, `commands.mcp-browser:available`, discovery: mcporter 0.12.3 — 1 server `playwright` 23 tools healthy）
- wrapper: `harness/mcp-bridge/bin/mcp-browser`（通用薄壳，纯 bash，ALLOWED 5 项：playwright.browser_navigate / browser_snapshot / browser_take_screenshot / browser_click / browser_evaluate）
- 配置源: `config/mcporter.json`（声明 playwright server，daemon keepAlive）
- daemon: `mcporter daemon` running（playwright server connected，23 tools）
- Evaluator 仅用 RunCommand（cwd=/workspace, blocking=true）调 wrapper；未调用任何 `mcp__*` / Playwright MCP 工具。

## 查证记录

### 查证 1: navigate
- 命令: `harness/mcp-bridge/bin/mcp-browser playwright.browser_navigate url:https://example.com`
- exit: 0
- 关键输出（content[0].text 摘要）:
  ```
  ### Ran Playwright code
  await page.goto('https://example.com');
  ### Page
  - Page URL: https://example.com/
  - Page Title: Example Domain
  ### Snapshot
  - [Snapshot](.playwright-mcp/page-2026-07-02T16-23-34-045Z.yml)
  ```
- 结论: PASS — 真机导航返回 "Page Title: Example Domain"，非静态检查。

### 查证 2: snapshot
- 命令: `harness/mcp-bridge/bin/mcp-browser playwright.browser_snapshot`
- exit: 0
- 关键输出（content[0].text 摘要）:
  ```
  ### Page
  - Page URL: https://example.com/
  - Page Title: Example Domain
  ### Snapshot
  ```yaml
  - generic [ref=f2e2]:
    - heading "Example Domain" [level=1] [ref=f2e3]
    - paragraph [ref=f2e4]: This domain is for use in documentation examples without needing permission. Avoid use in operations.
    - paragraph [ref=f2e5]:
      - link "Learn more" [ref=f2e6] [cursor=pointer]:
        - /url: https://iana.org/domains/example
  ```
  ```
- 结论: PASS — 返回真实页面 a11y 快照结构。

### 查证 3: evaluate (document.title)

#### 3a. 按 contract 翻译表字面命令（`expression:document.title`）
- 命令: `harness/mcp-bridge/bin/mcp-browser playwright.browser_evaluate expression:document.title`
- exit: 1
- 关键输出（content[0].text，isError:true）:
  ```
  ### Error
  Invalid arguments for tool "browser_evaluate":
  ✖ Invalid input: expected string, received undefined
    → at function
  ```
- 同样以 `expression=document.title` / `--raw-strings` / `--args '{"expression":"document.title"}'` 均同样失败（exit:1）。
- 根因: `playwright.browser_evaluate` 的真实必填参数为 `function`（箭头函数 `() => { /* code */ }`），并非 `expression`。contract.md `mcp_to_shell_translation` 表第 5 行的 `expression:document.title` 写法与 MCP server schema 不符。
- 结论（字面命令）: FAIL — contract 翻译表条目错误，按字面执行不通过。

#### 3b. 按真实 schema 改写后重测（`function=() => document.title`）
- 命令: `harness/mcp-bridge/bin/mcp-browser playwright.browser_evaluate 'function=() => document.title'`
- exit: 0
- 关键输出（content[0].text 摘要）:
  ```
  ### Result
  "Example Domain"
  ### Ran Playwright code
  await page.evaluate('() => document.title');
  ```
- 结论（改写命令）: PASS — bridge 机制本身可正常执行 JS 取标题，返回 "Example Domain"。

#### 3 综合结论: PARTIAL — bridge 能力 PASS；contract 翻译表 evaluate 行有缺陷需修复。

### 查证 4: 白名单外调用（负面）
- 命令: `harness/mcp-bridge/bin/mcp-browser playwright.invalid_tool; echo "EXIT=$?"`
- exit: 2（输出末行 `EXIT=2` 确认；外层 echo 自身 exit=0 已分离）
- stderr: `[BLOCKED: MCP bridge command not allowed] playwright.invalid_tool`
- 结论: PASS — wrapper 白名单正确拦截非授权 tool，exit=2。

## Evaluator 结论
AP19 = PASS（带契约缺陷备注）— bridge 机制端到端真机可用：navigate 返回真实 "Example Domain"、snapshot 返回真实 DOM、evaluate（用正确 schema）返回 "Example Domain"、invalid_tool 被 BLOCKED exit=2，开闭原则与白名单生效。**但 contract.md `mcp_to_shell_translation` 表 evaluate 行写法有误**：声明的 `expression:document.title` 按 schema 实际应为 `function=() => document.title`；按契约字面命令查证 3a 失败（exit=1）。建议修复契约翻译表，AP19 本身（shell bridge 可用性）通过。

## 真机证据
- 真实导航 example.com 返回 "Page Title: Example Domain"（非静态检查，page.goto 真实执行）。
- 真实 snapshot 返回页面 a11y YAML（含 heading "Example Domain"、link "Learn more" → https://iana.org/domains/example）。
- 真实 evaluate（`function=() => document.title`）返回 `"Example Domain"`。
- 白名单外调用 `playwright.invalid_tool` 被正确 BLOCKED（stderr 输出拦截信息，exit=2）。

## 已知缺陷（供 Decision SubAgent 裁决）
- contract.md `mcp_to_shell_translation` 第 5 行 evaluate 翻译条目错误：`expression:document.title` → 应为 `function=() => document.title`（参数名 `expression` 不存在，真实必填参数为 `function`，需箭头函数体）。按字面执行 exit=1，不阻塞 bridge 本体判定，但应修复契约以避免后续 SubAgent 误用。
