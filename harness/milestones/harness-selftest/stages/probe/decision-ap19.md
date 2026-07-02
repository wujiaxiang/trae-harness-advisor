# Stage probe — AP19 补测 Decision 裁决 (harness-selftest)

> 独立 Decision SubAgent（@decision-role）。本裁决**仅**针对 AP19 实验补测（mcp_access_mode=evaluator_shell_bridge）做出，与已覆盖 AP1–AP11 的 decision.md 互不重叠。
> 独立、只读、中立：未参与 Generator/Evaluator/Orchestrator 的会话推理；仅 Read 总线文件 + 必要的源码/配置/落盘文件做交叉核验后裁决。

## 裁决输入（已 Read）

- `harness/milestones/harness-selftest/stages/probe/contract.md`（§AP19 实验补测：check.sh 快照、mcp_bridge_capabilities、mcp_to_shell_translation、验收要点、通过判定）
- `harness/milestones/harness-selftest/stages/probe/eval.md`（§AP19 实验补测：Evaluator 自行执行的命令、退出码、输出、截图路径、负面用例、VERIFY[AP19] 行）
- `harness/milestones/harness-selftest/stages/probe/gen.md`（AP19 不需 Generator，复核未见矛盾）
- `harness/milestones/harness-selftest/stages/probe/browser-check.md`（确认仍为 AP11 旧证据，未被 AP19 改写/新增）
- `harness/state-board.json`（probe 已 passed，rounds=1，AP19 为补充实验）
- `config/mcporter.json`（交叉核验 contract.md 誊写是否忠实）
- `tools/mcp-bridge/bin/mcp-browser`（交叉核验 ALLOWED 白名单 + BLOCKED 拦截实现）
- `tools/mcp-bridge/check.sh` + `tools/mcp-bridge/discovery/mcporter-list.txt`（交叉核验 contract.md 快照是否忠实）
- `/root/Downloads/`（交叉核验 Evaluator 声称的截图文件是否真实落盘）
- `RULE.md`（§MCP bridge 约束）

## 6 项通过判定逐条核验

### 1. config-owned MCP runtime 生效 — PASS
- contract.md §check.sh 快照：`available: true`、`mode: evaluator_shell_bridge`、`commands.mcp-browser: available`。
- 交叉核验：`tools/mcp-bridge/check.sh` 第 47–58 行逐 wrapper 跑 `--bridge-check`，退出 0 即记 `available`；wrapper `mcp-browser` 第 14–26 行 `--bridge-check` 跑 `npx mcporter daemon status` + `npx mcporter list` 退出 0 → 与快照 `commands.mcp-browser=available` 一致。
- 证据自洽，PASS。

### 2. contract 含从 config/mcporter.json 誊写的 MCP→Shell 翻译表 — PASS
逐字段比对 contract.md `mcp_bridge_capabilities` / `mcp_to_shell_translation` 与 `config/mcporter.json` `bridgeWrappers.mcp-browser`：
- `server=playwright` ✓
- `purpose` 字符串一字不差 ✓
- `policy` 字符串一字不差 ✓
- `allowedTools` 5 项顺序与内容完全一致（playwright_navigate / screenshot / click / evaluate / get_visible_text）✓
- `translationExamples` 5 条与 contract.md 翻译表 5 行一一对应（navigate/screenshot/click/evaluate/get_visible_text，参数照抄）✓
- `mustLogTo=eval.md` ✓
- 誊写忠实，无篡改/遗漏，PASS。

### 3. Evaluator SubAgent 自己按翻译表通过项目 wrapper 查证并写 eval.md — PASS
- eval.md §正向用例记录 Evaluator 自行执行三条命令：
  - `bash tools/mcp-bridge/bin/mcp-browser playwright.playwright_navigate url:https://example.com headless:true`（与翻译表第 1 行一致）
  - `bash tools/mcp-bridge/bin/mcp-browser playwright.playwright_screenshot`（与翻译表第 2 行一致）
  - `bash tools/mcp-bridge/bin/mcp-browser playwright.playwright_get_visible_text`（与翻译表第 5 行一致）
- 命令形式全部走项目 wrapper（`tools/mcp-bridge/bin/mcp-browser`），**未**直接调 `npx mcporter call`，**未**调任何 `mcp__*`。
- 每条均记录真实退出码（0）与真实 JSON/文本输出。
- 交叉核验 wrapper 源码：白名单命中后第 64–65 行 `shift` + `npx mcporter call "${CALL_TARGET}" "$@" --config ... --output json --timeout 60000`，与 eval.md 记录的 JSON 响应格式（`{"content":[{"type":"text","text":"..."}],"isError":false}`）一致。
- PASS。

### 4. 白名单外 tool 被 BLOCKED — PASS
- eval.md §负向用例：`bash tools/mcp-bridge/bin/mcp-browser playwright.playwright_invalid_tool` → 退出码 2，输出 `[BLOCKED: MCP bridge command not allowed] playwright.playwright_invalid_tool`。
- 交叉核验 wrapper 源码第 51–62 行：`playwright_invalid_tool` 不在 ALLOWED 数组 → `FOUND=0` → 第 59–62 行 `echo "[BLOCKED: MCP bridge command not allowed] ${TARGET}" >&2; exit 2`。
- 手工推演 target 解析：TARGET=`playwright.playwright_invalid_tool` 含 `.`，TARGET_SERVER=`playwright`=SERVER（不触发第 39–42 行 server 名拦截），TOOL_NAME=`playwright_invalid_tool`，CALL_TARGET=`playwright.playwright_invalid_tool`；ALLOWED 循环既无 `${entry}==${CALL_TARGET}` 也无 `${entry}==${TOOL_NAME}` → FOUND=0 → 走 BLOCKED 分支。与 eval.md 记录的输出字符串与退出码完全一致。
- 拦截真实生效，PASS。

### 5. Orchestrator 不代行浏览器中间观察 — PASS
- `browser-check.md` 内容仍为 AP11 旧证据（截图路径 `screenshot-2026-07-01T18-08-57-868Z.png`，7 月 1 日；修订记录、版本修复说明均针对 AP11），**未**新增任何 AP19 段落。
- AP19 的浏览器证据（截图路径 `screenshot-2026-07-02T18-17-10-843Z.png`，7 月 2 日，不同时间戳）全部落在 `eval.md` §AP19 实验补测内，由 Evaluator SubAgent 自行 RunCommand 执行并落盘。
- stages/probe/ 目录下未见 `browser-check-ap19.md` 或类似 Orchestrator 代行中间观察文件（LS 确认仅 ap9-a/ap9-b/browser-check/contract/decision/eval/gen-r2/gen）。
- Orchestrator 未代行，PASS。

### 6. bridge 不可用时明确 BLOCKED（本次 bridge 可用 → N/A，但需核验 Evaluator 未伪造通过） — PASS（证据可信）
本次 bridge 可用，本条形式上 N/A；但按用户"如实回答，不要把本地静态检查当真机通过"的要求，对 Evaluator 真机证据可信度做独立核验：

- **截图文件真实落盘**：LS `/root/Downloads/` 确认 `screenshot-2026-07-02T18-17-10-843Z.png` 实际存在，路径与文件名与 eval.md 声称完全一致（非空指针/虚构路径）。
- **页面文本与独立来源互洽**：eval.md 的 `get_visible_text` 返回 `Example Domain / This domain is for use in documentation examples without needing permission. Avoid use in operations. / Learn more`，与 browser-check.md 中 Orchestrator 在 AP11 独立通过 `mcp__Playwright__playwright_get_visible_text` 取回的 example.com 文本一字不差——两条独立链路（Orchestrator MCP 代行 vs Evaluator wrapper 查证）取到同一真实页面内容，互为印证。
- **截图时间戳不与 AP11 复用**：AP11 截图 `2026-07-01T18-08-57-868Z`，AP19 截图 `2026-07-02T18-17-10-843Z`，不同日期/时间，非复制粘贴。
- **discovery offline → eval-time online 的恢复路径合理**：discovery 快照（`tools/mcp-bridge/discovery/mcporter-list.txt` 实读）显示 `playwright (offline — unable to reach server, 30.0s)`，是 mcporter 健康探针对 server 的 30s 探测超时；但 wrapper 实际调用走 `npx -y mcporter call ...`（第 65 行），由 npx 按需拉起 `@executeautomation/playwright-mcp-server@1.0.12` 子进程，不依赖 discovery 时已存在的常驻 daemon。叠加 browser-check.md 记录的 AP11 修复（chromium 1200 二进制已 `playwright@1.57.0 install --with-deps chromium` 装好），eval-time 真机导航/截图/取文本三连成功有充分物理基础。
- **JSON 响应格式与 mcporter `--output json` 一致**：`{"content":[{"type":"text","text":"Navigated to https://example.com"}],"isError":false}` 符合 MCP 标准响应结构 + mcporter json 包装。
- 未见伪造/静态检查伪装真机迹象，证据可信，PASS。

## 关注点 / 怀疑记录

1. **discovery 与 eval-time 状态差异**：contract.md 快照记 playwright MCP server `offline`，eval.md 记实测可达。已核验恢复路径合理（npx 按需拉起 + chromium 1200 已装），不构成机制问题，且 Evaluator 已在 eval.md §运行时可用性说明 明确披露该差异并声明"以 Evaluator 自行实测结果为准"——披露充分，未掩盖。
2. **截图文件大小 18789 字节**：eval.md 声称 `ls -la` 见 18789 字节；本次 Decision 未对 PNG 字节数做二次 stat（只读核验已确认文件存在），但 example.com 是极简静态页，18KB 量级合理，未见异常。
3. **Evaluator 未直接调 `npx mcporter call` 的边界**：wrapper 内部第 65 行转发到 `npx mcporter call` 属 runtime 行为，非 Evaluator 直接调用；eval.md §约束遵守自检 已正确区分二者，与 RULE.md §64"官方 MCPorter 只作为 wrapper 的底层 runtime"一致。
4. 无其它可疑点。

## 最终裁决

- **VERIFY[AP19]: PASS — 6 项通过判定全中：check.sh available=true+commands.mcp-browser=available（核验 check.sh 源码）；contract.md 翻译表与 config/mcporter.json 逐字段一致；Evaluator 自行通过 wrapper 跑 navigate/screenshot/get_visible_text 三连真机成功（截图 /root/Downloads/screenshot-2026-07-02T18-17-10-843Z.png 经 LS 确认真实落盘，页面文本与 AP11 Orchestrator 独立取回的 example.com 文本互洽）；负向 playwright_invalid_tool 被 wrapper exit 2 + 精确 BLOCKED 字符串拦截（核验 wrapper 第 59–62 行）；Orchestrator 未代行（browser-check.md 仍为 AP11 旧内容，AP19 证据全在 eval.md）；bridge 可用且证据可信，未伪造。**
- **verdict: pass**

依据 contract.md §AP19 通过判定 6 条全部满足，且 Evaluator 真机证据经独立交叉核验（截图落盘、页面文本双链路互洽、wrapper 源码与配置一致、discovery→eval-time 恢复路径合理）确认非静态检查伪装。AP19 为一次性实验补测，无需 retry；verdict=pass，不 escalate。
