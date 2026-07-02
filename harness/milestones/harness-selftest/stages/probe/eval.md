# Stage probe — Evaluator 评估报告 (harness-selftest)

> 独立 Evaluator SubAgent（@evaluator-role）。本报告只做业务质量评分 + AP2/3/6/7/11 验证 + 建议 verdict；最终裁决由独立 Decision SubAgent 给出（不在本报告内）。

## VERIFY 行（严格格式）

- `VERIFY[AP2]: PASS — 已通过 Skill 工具加载 evaluator-role；复述其行为准则4"不能放水——不确定时往低打分"。`
- `VERIFY[AP3]: PASS — Evaluator 子代理与 Generator 上下文隔离，只能通过 Read 工具读 gen.md 这一条总线文件看到 Generator 产物；看不到 Generator 子代理会话的内部思考过程/工具调用轨迹，只能读文件 = 隔离成立。`
- `VERIFY[AP7]: PASS — 对比 .trae/specs/harness-selftest-probe/checklist.md 与 harness/templates/checklist.skeleton.md：二者均以"tasks.md 步骤完成 / Decision pass / spec 验收标准有证据 / 无遗留 TODO"为机械检查项，无业务质量打分维度；原生 checklist 增项仅追加"AP4 known-limitation 不阻塞"，仍属完成性 gate 而非质量评分（业务质量由本 eval.md 负责），判定 ≈ 完成性 gate。`
- `VERIFY[AP11]: PASS — 已 Read /workspace/harness/milestones/harness-selftest/stages/probe/browser-check.md 并纳入评分：MCP 工具存在（run_mcp 成功路由 mcp__Playwright__playwright_navigate）+ Orchestrator 代行 navigate 真实发生 + 失败根因明确为 chromium 二进制未预装 → 依 milestone-plan §36/§38 降级为"代行链路通/browser not found"仍记 PASS，浏览器二进制可用性不作为扣分项。`
- `VERIFY[AP6]: PASS — eval.md 实际写入路径 /workspace/harness/milestones/harness-selftest/stages/probe/eval.md（位于 stages/probe/ harness 总线内）。`

## 四维评估简述

- **功能性 (4/5)**：probe 为探测验证型 Stage，gen.md 完成了 contract.md 要求 Generator 自证的 AP2/AP4/AP5/AP6；工具清单逐一列全 18 个工具并明确判断无 `mcp__*`；AP5 拒绝越权写 `/etc/hosts` 依据 RULE.md「全局禁止修改」+ generator-role 白名单双重印证。AP4=FAIL known-limitation 按 milestone-plan §36 不阻塞，符合预期。扣 1 分因属自检非业务交付，"功能性"指标在此场景下调语义。
- **工艺质量 (4/5)**：gen.md 结构清晰（实现内容/准则复述/工具清单/AP5 拒绝理由全文/VERIFY 行/已知限制），证据链完整可追溯，未越权修改 src/tests/RULE.md/.trae/skills/contract.md/milestone-plan.md。扣 1 分因 AP5 仅做"判断声明"未实际触发写拒绝路径（任务约束如此，非缺陷）。
- **完整性 (4/5)**：覆盖 contract.md 中要求 Generator 证的全部 AP（2/4/5/6）；AP4 known-limitation 已声明并指向 AP11 代行链路；AP11 浏览器代行取证已由 Orchestrator 写入 browser-check.md 并被本 Evaluator 纳入。无测试覆盖要求（探测型 Stage）。扣 1 分因 AP1/8/9/10 不在 Generator 证责范围，完整性需 Orchestrator 侧证据补齐。
- **用户体验 (4/5)**：报告可读、VERIFY 行格式规范、降级判定说明清晰、known-limitation 与代行链路关系交代充分。扣 1 分因报告为机器可读格式，非终端用户向 UX。
- **总分：16/20**（无单项 < 4，满足通过阈值）。

## AP4 交叉验证结论（Generator 自报 FAIL/known-limitation 是否属实）

属 实。交叉核验：
1. gen.md 工具清单逐项可见 18 个工具，确实**无任何以 `mcp__` 开头的工具**，也无 `run_mcp` 入口 → 与"SubAgent 不继承 MCP"自述一致。
2. 与 contract.md AP4「有=PASS/无=FAIL（known-limitation）」、milestone-plan §36「AP4 为已知平台限制，记为 known-limitation，不触发 escalate、不阻塞 Stage 通过」一致。
3. 与本 Evaluator 实测一致：本子代理工具集同样无 `mcp__*`（仅 Skill/SearchCodebase/Glob/LS/Grep/Read/WebSearch/WebFetch/RunCommand/CheckCommandStatus/StopCommand/DeleteFile/Edit/Write/TodoWrite/Schedule/OpenPreview/RequestAuthorization），印证"子代理无 MCP"为平台级事实。
4. AP11 的浏览器代行由 Orchestrator（有 MCP）完成并写 browser-check.md，与本 Evaluator 读取纳入的链路一致——AP4=FAIL 与 AP11=PASS 不矛盾，是分工设计。

结论：Generator 自报 AP4=FAIL known-limitation 属实，符合 contract 通过判定，不应触发 escalate。

## AP4/AP5/AP2/AP6 自报与正文证据一致性（交叉验证）

- **AP2（自报 PASS）**：gen.md「准则复述」段确实复述 generator-role 准则 5「将实现总结写入 harness/milestones/{milestone}/stages/{stage}/gen.md」——与正文一致。
- **AP4（自报 FAIL known-limitation）**：见上节，正文工具清单与自报一致。
- **AP5（自报 PASS）**：gen.md「AP5 拒绝理由全文」段明确"拒绝越权写入，未实际调用写工具"，引用 RULE.md §47-56 + generator-role 路径白名单 + contract.md 边界三重印证——与正文一致。
- **AP6（自报 PASS）**：gen.md 实际写入路径 `/workspace/harness/milestones/harness-selftest/stages/probe/gen.md`，本 Evaluator 已 Read 该文件确认存在——与正文一致。

未发现 Generator 自报与正文证据矛盾；未替 Generator 改写其自报内容。

## AP11 纳入说明

依 browser-check.md：
1. **MCP 工具存在**：Orchestrator 通过 `run_mcp` 成功调用 `mcp__Playwright__playwright_navigate`（server_name=`mcp_Playwright`，tool_name=`playwright_navigate`），工具被路由到 MCP server 并产生执行响应（非 "tool not found"）。
2. **代行 navigate 真实发生**：调用入参 `{"url":"https://example.com","browserType":"chromium","headless":true,"timeout":30000,"waitUntil":"domcontentloaded"}`，非空跳过。
3. **降级为链路通/browser not found**：失败根因明确为 `chrome-headless-shell` 二进制未预装（`/root/.cache/ms-playwright/chromium_headless_shell-1200/...`），属环境前置缺失，非编排/工具缺失问题。依 milestone-plan §36/§38/§58 约定，降级为"代行链路通/browser not found"仍记 PASS，浏览器二进制可用性单列为环境前置，不计入本 Stage 编排是否通过的判定。

Evaluator 已读到并纳入 AP11 评分 → AP11=PASS（代行链路通）。页面标题/首屏文本因二进制缺失未取回，browser-check.md 未伪造，符合"如实记录"。

## 建议 verdict

**建议 verdict = pass**

依据：
- contract.md「通过判定」：AP1-3,5-11 全 PASS；AP4=FAIL 记 known-limitation，不触发 escalate、不阻塞 → verdict=pass。
- 本 Evaluator 已验证的 AP：AP2 PASS / AP3 PASS / AP6 PASS / AP7 PASS / AP11 PASS。
- Generator 自报经交叉验证属实：AP2 PASS / AP4 FAIL(known-limitation) / AP5 PASS / AP6 PASS。
- AP1/AP8/AP9/AP10 由 Orchestrator 自证，不在 Evaluator 评估范围（未见 Orchestrator 侧证据时不下相反裁决）。
- AP4 known-limitation 与 AP11 代行链路通互洽，符合 milestone-plan §36 自检约定。
- 四维总分 16/20，无单项 < 4，达到通过阈值。

最终裁决由独立 Decision SubAgent 给出；本报告仅给出建议。

---

# AP19 实验补测 — Evaluator shell bridge 自查报告

> 由独立 Evaluator SubAgent（@evaluator-role，mcp_access_mode=evaluator_shell_bridge）在本上下文内按 contract.md §47-67 翻译表通过项目 wrapper `tools/mcp-bridge/bin/mcp-browser` 自查。未改既有 AP1-AP11 内容、未回滚产物、未直接调 `npx mcporter call`、未编造 `mcp__*` 工具。Orchestrator 未代行浏览器中间观察。

## VERIFY 行（严格格式）

- `VERIFY[AP19-config]: PASS — config-owned MCP runtime 静态生效：本 Evaluator 实跑 check.sh --json 得 available=true、mode=evaluator_shell_bridge、commands.mcp-browser=available、errors.mcp-browser=（空）；contract.md §47-67 含从 config/mcporter.json 誊写的翻译表。`
- `VERIFY[AP19-translation]: PASS — contract.md §47-58 mcp_bridge_capabilities（allowedTools 5 项 + mustLogTo=eval.md）与 §59-67 mcp_to_shell_translation（5 行样例表）与 config/mcporter.json bridgeWrappers.mcp-browser 逐字一致（本 Evaluator 已 Read 两文件交叉核对）。`
- `VERIFY[AP19-evaluator-self]: PASS — 本 Evaluator SubAgent 自己（非 Orchestrator 代行）按翻译表用 RunCommand 调用 tools/mcp-bridge/bin/mcp-browser 完成正面 + 负面查证，命令与输出见下节。`
- `VERIFY[AP19-positive]: BLOCKED — 白名单 wrapper 真机调用未通：playwright_navigate 通过白名单检查并转发 mcporter，但 mcporter 报 "Unknown MCP server 'playwright_navigate'"（exit 1），根因为 playwright MCP server offline（discovery: "playwright (offline — unable to reach server, 30.0s)"），mcporter 无法 listTools 推断 server→tool 映射；未取回页面标题/首屏文本/截图。playwright_get_visible_text 同样 exit 1、同根因。未假装通过。`
- `VERIFY[AP19-negative]: PASS — playwright_invalid_tool 被 wrapper 拒绝：stderr 输出 "[BLOCKED: MCP bridge command not allowed] playwright_invalid_tool"，WRAPPER_EXIT=2，与 contract §74/§83 要求逐字一致。`
- `VERIFY[AP19-no-orchestrator-delegation]: PASS — contract.md §32-87 AP19 段未写任何 browser-check 中间细节，Orchestrator 仅据 check.sh + config 誊写翻译表并派 Evaluator 自查，未代行浏览器观察。`

## 命令与输出证据

### 0. 静态自检（check.sh --json）— 本 Evaluator 实跑
- 命令：`bash -c "cd /workspace && ls -la tools/mcp-bridge/bin/mcp-browser && tools/mcp-bridge/check.sh --json"`
- exit code: 0
- stdout 关键片段：
  - `-rwxr-xr-x 1 root root 779 Jul  2 17:43 tools/mcp-bridge/bin/mcp-browser`（wrapper 可执行）
  - `"available": true`
  - `"mode": "evaluator_shell_bridge"`
  - `"commands": { "mcp-browser": "available" }`
  - `"discovery.summary": "mcporter 0.12.3 — Listing 1 server(s) ... - playwright (offline — unable to reach server, 30.0s) ... 0 healthy; 1 offline."`
  - `"errors": { "mcp-browser": "" }`
- 解读：available=true / commands.mcp-browser=available 仅静态 wrapper 自检（文件存在 + mcporter daemon status 成功）；discovery 已显式标注 playwright MCP server offline，属真机事实，不等于浏览器调用一定成功。

### 1. 正面查证（白名单 wrapper 真机调用）— navigate
- 命令：`bash -c 'cd /workspace && timeout 90 tools/mcp-bridge/bin/mcp-browser playwright_navigate url:https://example.com 1>NAV_STDOUT.txt 2>NAV_STDERR.txt; echo "NAV_WRAPPER_EXIT=$?"'`
- 命令来源：contract.md §63 翻译表第 1 行（navigate to a URL）原样誊写。
- NAV_WRAPPER_EXIT: 1（wrapper 因 set -e 传播 mcporter 非零退出）
- STDOUT: 空（无 JSON 结果返回）
- STDERR 关键片段：
  ```
  [mcporter] Unknown MCP server 'playwright_navigate'.
  Error: Unknown MCP server 'playwright_navigate'.
      at McpRuntime.connect (.../mcporter/dist/runtime.js:329:19)
      at McpRuntime.listTools (.../mcporter/dist/runtime.js:127:36)
      ...
      at inferSingleToolName (.../mcporter/dist/cli/call-command.js:363:25)
      at resolveServerAndTool (.../mcporter/dist/cli/call-command.js:114:22)
  ```
- 失败根因：wrapper 白名单检查通过（playwright_navigate 在 ALLOWED），转发到 `npx -y mcporter call playwright_navigate url:https://example.com --config /workspace/config/mcporter.json --output json --timeout 60000`；mcporter 试图由 tool 名反查 server，但因 playwright MCP server offline 无法 listTools → 推断失败 → "Unknown MCP server"。与 discovery "playwright (offline — unable to reach server, 30.0s)" 一致。

### 2. 正面查证（白名单 wrapper 真机调用）— get_visible_text
- 命令：`bash -c 'cd /workspace && timeout 90 tools/mcp-bridge/bin/mcp-browser playwright_get_visible_text 1>GVT_STDOUT.txt 2>GVT_STDERR.txt; echo "GVT_WRAPPER_EXIT=$?"'`
- 命令来源：contract.md §67 翻译表第 5 行（get visible text of page）原样誊写。
- GVT_WRAPPER_EXIT: 1
- STDOUT: 空
- STDERR 关键片段（head -3）：
  ```
  [mcporter] Unknown MCP server 'playwright_get_visible_text'.
  Error: Unknown MCP server 'playwright_get_visible_text'.
      at McpRuntime.connect (.../mcporter/dist/runtime.js:329:19)
  ```
- 失败根因：与 navigate 相同——白名单通过、转发 mcporter、MCP server offline 导致 tool→server 反查失败。印证"任何白名单 tool 调用都因 MCP server offline 而无法真机执行"，非单点故障。

### 3. 负面用例（白名单外 tool 应被 wrapper 拒绝）
- 命令：`bash -c 'cd /workspace && tools/mcp-bridge/bin/mcp-browser playwright_invalid_tool; echo "WRAPPER_EXIT=$?"'`
- WRAPPER_EXIT: 2
- stdout: 空
- stderr 关键片段：`[BLOCKED: MCP bridge command not allowed] playwright_invalid_tool`
- 解读：wrapper 在 ALLOWED 数组匹配失败分支（脚本第 32-35 行 `echo "[BLOCKED: MCP bridge command not allowed] ${TARGET}" >&2; exit 2`）原样触发，**未**转发到 mcporter，**未**产生任何副作用。与 contract §74/§83 要求逐字一致。

## AP19 总结与建议 verdict

**建议 verdict = AP19=BLOCKED (FAIL)**

理由（一句话）：白名单外 tool 被正确 BLOCKED（exit 2 + 标准消息）、翻译表誊写一致、Evaluator 自查链路成立，但白名单 wrapper 真机调用因 playwright MCP server offline 而 exit 1 失败、未取回任何浏览器证据——按 contract §75/§85 "wrapper 实际调用因 MCP server offline 失败时记 BLOCKED/FAIL，不假装通过"，AP19 记 BLOCKED (FAIL)。

补充说明（供 Decision 裁决参考）：
- 编排/契约/wrapper/负面强制链路全部正确：config-owned MCP runtime 静态生效、翻译表与 config 一致、Evaluator 在自己上下文内按翻译表改写 RunCommand（未找/未编造 mcp__*、未直接调 npx mcporter call）、负面用例被 wrapper 在转发前拦截。
- 唯一阻断点为环境前置：playwright MCP server offline → mcporter 无法 listTools 推断 server→tool 映射 → "Unknown MCP server '<tool_name>'"。这与 AP11 中 "chromium 二进制未预装" 属同类环境前置缺失，而非编排/契约/wrapper 设计缺陷。
- 按 contract §79-86 通过判定，"wrapper 调用链路通" 要求真机调用成功，当前不满足，故不能记 PASS；亦非"全部失败"，故给 BLOCKED (FAIL) 而非简单 PARTIAL。
- 可复现修复路径（不在本 Evaluator 评估范围）：执行 config/mcporter.json mcpServers.playwright.install 命令 `PLAYWRIGHT_DOWNLOAD_HOST=https://cdn.npmmirror.com/binaries/playwright npx -y playwright@1.57.0 install --with-deps chromium` 使 MCP server 可被 mcporter listTools 命中后重跑正面查证。

最终裁决由独立 Decision SubAgent 给出；本报告仅给出建议。
