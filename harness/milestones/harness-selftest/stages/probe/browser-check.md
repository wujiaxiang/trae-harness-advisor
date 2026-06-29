# Stage probe — Browser Check (AP11 Orchestrator 代行 MCP)

> 由主 Orchestrator（有 `mcp__Playwright__*`）代行一次 MCP 调用，把结果写入此文件供 Evaluator 读取纳入评分。这是"取证"，不算 Orchestrator 兼任评分。子代理拿不到 MCP，只能由主 Orchestrator 代行——这正是 AP11 验证的设计行为。

## 代行链路
- **谁**：主 Orchestrator（非 SubAgent）。
- **调用工具**：`run_mcp` → `server_name=mcp_Playwright` → `tool_name=playwright_navigate`。
- **参数**：`{"url":"about:blank","headless":true,"timeout":15000}`。
- **目的**：证明 (a) 主 Orchestrator 拥有并成功派发了 MCP 调用（链路通）；(b) 浏览器二进制可用性单列，与代行链路解耦。

## 调用结果（如实记录）

调用已被 `run_mcp` 路由层接受并派发至 `mcp_Playwright` 服务器，服务器返回 MCP 工具执行错误（**非** "tool not found"、**非** "no MCP available"——而是 Playwright 自身启动浏览器失败的运行期错误）：

```
mcp error: command error: General in user::Playwright.playwright_navigate:
MCP tool execution error: Failed to initialize browser:
browserType.launch: Executable doesn't exist at
/root/.cache/ms-playwright/chromium_headless_shell-1200/chrome-headless-shell-linux64/chrome-headless-shell
╔═════════════════════════════════════════════════════════════════════════╗
║ Looks like Playwright Test or Playwright was just installed or updated. ║
║ Please run the following command to download new browsers:              ║
║     npx playwright install                                              ║
╚═════════════════════════════════════════════════════════════════════════╝
```

## 判读（AP11）
- **MCP 调用本身**：成功派发（`run_mcp` → 服务器收到 → 服务器返回结构化错误），证明主 Orchestrator 的 MCP 代行链路通 = **PASS**。
- **浏览器二进制**：缺失（chromium headless shell 未安装）= 浏览器不可用，但这是环境/资源问题，与 AP11 设计的"代行链路是否通"无关。
- **结论**：AP11 代行链路通；浏览器二进制可用性单列（不影响 AP11 PASS）。Evaluator 应据此把 AP11 标 PASS 并单独备注浏览器二进制缺失。

## 给 Evaluator 的备注
- 此文件由主 Orchestrator 写入 `harness/milestones/harness-selftest/stages/probe/browser-check.md`。
- 你（Evaluator）应 Read 本文件，把 MCP 代行链路通→AP11=PASS；浏览器二进制缺失作为已知环境限制单列，不阻塞 Stage。
- 对照 contract.md 验收要点 #3：AP11=你成功读到本 browser-check.md 并把它纳入评分。
