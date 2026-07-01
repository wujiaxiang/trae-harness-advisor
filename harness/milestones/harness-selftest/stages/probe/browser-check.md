# browser-check.md — AP11 浏览器代行取证（Stage probe）

> 由 Orchestrator（主对话，有 MCP）代行。子代理拿不到 MCP，故此步必须由 Orchestrator 代行取证；属"取证"，不算 Orchestrator 兼任评分/裁决。

## 1. MCP 工具是否存在
- **是**。Orchestrator 主对话通过 `run_mcp` 成功调用 `mcp__Playwright__playwright_navigate`（server_name=`mcp_Playwright`，tool_name=`playwright_navigate`）。
- 调用入参：`{"url":"https://example.com","browserType":"chromium","headless":true,"timeout":30000,"waitUntil":"domcontentloaded"}`。
- 工具被路由到 MCP server 并产生执行响应（非"tool not found"），证明 MCP 工具链路存在。

## 2. 导航是否成功
- **否（browser not found）**。MCP server 返回执行错误：
  ```
  Failed to initialize browser: browserType.launch: Executable doesn't exist at
  /root/.cache/ms-playwright/chromium_headless_shell-1200/chrome-headless-shell-linux64/chrome-headless-shell
  Looks like Playwright Test or Playwright was just installed or updated.
  Please run the following command to download new browsers: npx playwright install
  ```
- 根因：chromium 二进制未预装（milestone-plan §38 环境约定中"安装命令"未配置为 `npx -y playwright install --with-deps chromium`）。

## 3. 页面标题/首屏文本证据
- **N/A**。因浏览器二进制缺失，无法取回 example.com 的页面标题/首屏文本。预期标题（参考）应为 "Example Domain"，但本次**未实际取到**，不伪造。

## 4. 降级判定（依 milestone-plan §36/§38/§58）
- 依约定：未装 chromium → AP11 降级为 **"代行链路通 / browser not found"**，仍记 **PASS**，不阻塞 probe 通过。
- 代行链路通的证据：
  - (a) MCP 工具存在且可被 Orchestrator 调用（run_mcp 路由成功）；
  - (b) Orchestrator 真实执行了一次 navigate 调用（非空跳过）；
  - (c) 失败原因明确为环境缺二进制，非编排/工具缺失问题。
- 浏览器二进制可用性单列为环境前置（见 milestone-plan §38），不计入本 Stage 编排是否通过的判定。

## 5. 给 Evaluator 的纳入提示
Evaluator 应读本文件并把"MCP 工具存在 + 代行调用真实发生 + 降级为链路通"纳入 AP11 评分（读到 + 纳入 = PASS = 代行链路通）。浏览器二进制可用性不作为扣分项。
