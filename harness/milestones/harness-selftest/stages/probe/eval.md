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

## AP19 实验补测（mcp_access_mode=evaluator_shell_bridge）

> 独立 Evaluator SubAgent 自行按 contract.md `mcp_to_shell_translation` 翻译表把 MCP/browser 意图改写为 RunCommand，只调用 `tools/mcp-bridge/bin/mcp-browser ...` 项目 wrapper 查证。Orchestrator 未代行本次浏览器观察；本节全部命令由 Evaluator 自己执行并落盘证据。

### 实测环境
- 工作目录：`/workspace`
- wrapper：`/workspace/tools/mcp-bridge/bin/mcp-browser`（已 Read 确认存在；config-owned，硬编码 `CONFIG=/workspace/config/mcporter.json`、`SERVER=playwright`、`ALLOWED=(playwright_navigate playwright_screenshot playwright_click playwright_evaluate playwright_get_visible_text)`）
- 配置源：`/workspace/config/mcporter.json`（`bridgeWrappers.mcp-browser` 与 contract.md 誊写一致）
- contract.md `mcp_bridge_capabilities` / `mcp_to_shell_translation` 与 `config/mcporter.json` 一致，无矛盾。
- Orchestrator 取证快照显示 discovery 时 playwright MCP server `offline`；Evaluator 实测时 server 已可达并真实返回 — 以 Evaluator 自行实测结果为准（"你看到什么就算通过"），不照搬 discovery 静态快照。

### 正向用例（白名单内 tool）

1. **导航（navigate）**
   - 命令：`bash tools/mcp-bridge/bin/mcp-browser playwright.playwright_navigate url:https://example.com headless:true`
   - 退出码：`0`
   - 关键输出：
     ```json
     {
       "content": [ { "type": "text", "text": "Navigated to https://example.com" } ],
       "isError": false
     }
     ```
   - 结论：wrapper 接受白名单 tool，转发到 `npx mcporter call playwright.playwright_navigate ...`，playwright MCP server 真实返回 `"Navigated to https://example.com"`，`isError:false`。**真机导航成功**（非静态检查/伪装）。

2. **截图（screenshot）**
   - 命令：`bash tools/mcp-bridge/bin/mcp-browser playwright.playwright_screenshot`
   - 退出码：`0`
   - 关键输出：
     ```json
     {
       "content": [
         { "type": "text", "text": "Screenshot saved to: ../../root/Downloads/screenshot-2026-07-02T18-17-10-843Z.png" },
         { "type": "text", "text": "Screenshot also stored in memory with name: 'screenshot'" }
       ],
       "isError": false
     }
     ```
   - 截图落盘核验：`ls -la /root/Downloads/screenshot-2026-07-02T18-17-10-843Z.png` → `-rw-r--r-- 1 root root 18789 Jul  2 18:17 ...`（真实 PNG 文件，18789 字节，非空）。
   - 截图路径：`/root/Downloads/screenshot-2026-07-02T18-17-10-843Z.png`
   - 结论：真机截图成功并落盘。

3. **取可见文本（get_visible_text）**
   - 命令：`bash tools/mcp-bridge/bin/mcp-browser playwright.playwright_get_visible_text`
   - 退出码：`0`
   - 关键输出：
     ```text
     Visible text content:
     Example Domain
     This domain is for use in documentation examples without needing permission. Avoid use in operations.
     Learn more
     ```
   - 结论：返回的可见文本与 example.com 真实页面内容一致（"Example Domain / This domain is for use in documentation examples ... / Learn more"），证明 navigate 确实打开了真实页面。

### 负向用例（白名单外 tool，须被 wrapper 拒绝）

- 命令：`bash tools/mcp-bridge/bin/mcp-browser playwright.playwright_invalid_tool`
- 退出码：`2`
- 完整输出：`[BLOCKED: MCP bridge command not allowed] playwright.playwright_invalid_tool`
- 结论：wrapper 在 `ALLOWED` 数组匹配阶段命中 `FOUND=0` 分支，输出精确的 `[BLOCKED: MCP bridge command not allowed]` 字符串并 `exit 2`，**未**转发到 `npx mcporter call`（wrapper 第 59-62 行硬拦截）。与 contract.md `mcp_bridge_capabilities.policy`「越权处理：wrapper 对未列入 ALLOWED 的 target 输出 `[BLOCKED: MCP bridge command not allowed] <target>` 并 exit 2」一字不差。

### 约束遵守自检
- ✅ Evaluator 只调用 `tools/mcp-bridge/bin/mcp-browser ...`，未直接调用 `npx mcporter call ...`（wrapper 内部转发属 runtime 行为，非 Evaluator 直接调用）。
- ✅ 未调用任何 `mcp__*` 工具（本 SubAgent 工具集本就无 `mcp__*`，且本次完全未尝试寻找/编造）。
- ✅ 按 contract.md `mcp_to_shell_translation` 表把 MCP 意图（navigate / screenshot / get_visible_text）改写为对应 shell 命令，参数照抄（`url:https://example.com headless:true`）。
- ✅ 未修改 contract.md / gen.md / decision.md / browser-check.md / state-board.json；本次仅 Read 这些文件并写入 eval.md。
- ✅ Orchestrator 未代行本次浏览器观察（AP19 三条白名单命令的执行与落盘均由 Evaluator SubAgent 在自己的 RunCommand 上下文完成；browser-check.md 未被新增/改写）。
- ✅ 未把本地静态检查当真机通过 — 本次 navigate/screenshot/get_visible_text 均产生真实运行时输出（JSON 响应 + 真实 PNG 文件 + 真实页面文本），属真机证据。

### 运行时可用性说明
- discovery 快照（contract.md 引用）记 playwright MCP server `offline (30.0s)`；Evaluator 实测时同一 server 已可正常应答（navigate/screenshot/get_visible_text 三连成功）。该差异不构成机制问题：wrapper 机制、白名单、翻译表均成立，且本次实际取得了真机浏览器证据（非降级为"链路通/browser not found"）。
- 无 BLOCKED 原因（wrapper 可用、白名单内 tool 真实成功、白名单外 tool 正确 BLOCKED）。

### VERIFY 行
- `VERIFY[AP19]: PASS — Evaluator 在自己 SubAgent 上下文按 contract.md 翻译表改写 MCP 意图为 RunCommand，只调 tools/mcp-bridge/bin/mcp-browser wrapper：正向 navigate/screenshot/get_visible_text 三连真机成功（navigate 返回 "Navigated to https://example.com"、screenshot 落盘 /root/Downloads/screenshot-2026-07-02T18-17-10-843Z.png 18789B、get_visible_text 返回 example.com 真实页面文本），负向 playwright_invalid_tool 被 wrapper 输出 "[BLOCKED: MCP bridge command not allowed]" 并 exit 2，未调 raw npx mcporter / mcp__*，Orchestrator 未代行浏览器观察。`

### 通过判定对照
- ✅ config-owned MCP runtime 生效：`check.sh available=true, commands.mcp-browser=available`（contract.md 快照），wrapper 本体存在且可执行。
- ✅ contract 含从 `config/mcporter.json` 誊写的 MCP→Shell 翻译表（`mcp_to_shell_translation`）。
- ✅ Evaluator SubAgent 自己按翻译表通过项目 wrapper 查证并写 eval.md（本节即证据）。
- ✅ 白名单外 tool 被 BLOCKED（exit 2，精确字符串）。
- ✅ Orchestrator 不代行浏览器中间观察（AP19 全程由 Evaluator 自行执行）。
- ✅ bridge 可用，运行时浏览器调用真实成功（非降级，非 BLOCKED）。
- ✅ 额外：本次为真机通过（非"runtime browser offline; mechanism verified"降级情形）— discovery 的 offline 状态在实测时已恢复，navigate/screenshot/visible_text 均真实返回。
