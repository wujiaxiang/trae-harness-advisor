# Follow-up Prompt — 确认 AP2/AP3 是否“真·子代理隔离”

> **v4.3 起已并入主用例**：重跑统一用 `test-prompt.md` 的单条提示词（已含 AP9 真并行 + AP4 MCP 补证 + Decision 独立）。本文件留作首轮“事后核实”的问题记录与判读参考。

> 首轮 probe Stage 跑出 8 PASS / 1 FAIL（AP4 MCP）。但 AP2（子代理加载角色 Skill）与 AP3（上下文隔离）
> 目前是子代理**自述**。本提示词用于硬证实：gen.md / eval.md 是否确由两个独立 SubAgent 加载不同 Skill 写入，
> 而非主 Orchestrator 自己扮演两个角色。把下面整段发给同一个云端会话即可。

---

```
关于刚才 probe Stage 的执行，我要核实几点，用来判定 AP2/AP3 是否“真·子代理隔离”，而不是你（主 Orchestrator）自己扮演两个角色写的。请如实回答，不要为让结果好看而美化；某步若其实是你代劳的，请直说：

1. 本次 probe Stage 你一共发起了几次 SubAgent（Task）调用？请逐个列出：每次加载了哪个 skill（generator-role / evaluator-role / 其它）、该次子代理具体写了哪些文件。
2. gen.md 和 eval.md 是不是由“两个不同的 SubAgent 调用”分别写入的？主 Orchestrator（你自己）有没有亲手 Write 过 gen.md 或 eval.md？
3. 你（主 Agent）是怎么知道 Generator 做了什么的——是只能 Read gen.md 文件，还是能直接看到 Generator 子代理的对话/推理过程？反过来，Evaluator 子代理能看到 Generator 子代理的上下文吗？
4. AP9 的 probe-a 和 probe-b，是在“同一条消息里的两个并行 Task 块”发起的（真并行），还是先后两次串行发起的？给出你判断的依据。
5. AP4 的 MCP：是仅 SubAgent 没有 mcp__ 工具，还是连主 Orchestrator 也没有任何 mcp__ 工具？如果在 TRAE Work 里配置了 Playwright MCP，SubAgent 能否继承调用？
请把答案也追加写到 harness/milestones/harness-selftest/stages/probe/followup.md，并推到 main。
```

---

## 拿到回答后怎么判读

- 若 #1/#2 证实 **gen.md 与 eval.md 由两次不同 Task 子代理写入、主 Agent 未亲手写** → AP2 **硬验证 PASS**。
- 若 #3 证实 **主 Agent 与 Evaluator 都只能 Read gen.md、看不到 Generator 子代理上下文** → AP3 **硬验证 PASS**。
- 若任一其实是主 Agent 代劳 → 把对应 AP 降级，并在主文档把“角色分离/上下文隔离”从机制保证改为“同会话角色扮演 + 文件隔离”的弱化表述。
- #4 用于确认 AP9 的“真并行”而非串行模拟。
- #5 决定 AP4 是否可通过配置 MCP 补救，以及 SubAgent 是否能继承 MCP。

---

## 补证提示词（首轮已澄清后使用）

首轮 followup 已确认：AP2/AP3 硬验证 PASS；AP9 实为串行（并行未实证）；AP4 MCP 全平台未注册；[DECISION] 由主 Agent 兼任。
还剩两项可补证：

### 补证 1 — AP9「真并行」（无需 MCP，最便宜）

```
请做一次 AP9 真并行补证：在“同一条 assistant 消息里”同时放两个 Task tool_use 块，分别派发 probe-c 与 probe-d 两个 SubAgent，让它们各自把当前时间戳写到
harness/milestones/harness-selftest/stages/probe/ap9-c.md 和 ap9-d.md。
完成后如实报告：这两个 Task 是否在同一条消息里并行发起？两个时间戳间隔多少？据此判定平台是否“真支持并行派发”。把结论追加到 followup.md 并推 main。
```

### 补证 2 — AP4「SubAgent 是否继承 MCP」（需先配 MCP server）

> 前提：在 TRAE Work「MCP > 云端 > 创建」配置 Playwright MCP（如 `@executeautomation/playwright-mcp-server`，命令 `npx -y`）并启用。
> **判定标准**：AP4 PASS 的核心是 **SubAgent 的工具清单里出现 `mcp__Playwright__*`（或任意 `mcp__` 前缀）工具**；浏览器能否真的导航是次要（云端可能缺浏览器二进制，需 `npx playwright install`）。

```
我已在 TRAE Work 配置并启用了 Playwright MCP（@executeautomation/playwright-mcp-server）。请做 AP4 补证：
1. 先由你（主 Orchestrator）列出自己的完整工具清单，报告是否出现 mcp__ 前缀工具（这验证主 Agent 侧 MCP 是否注册成功）。
2. 派发一个加载 @generator-role 的独立 SubAgent，让它列出**自己的**完整工具清单，明确报告是否出现 mcp__Playwright__* 工具（这验证 SubAgent 是否继承 MCP）。
3. 若 SubAgent 有该工具，尝试调用一次（如 navigate about:blank 或 list tools）；若报 browser not found，照实记录——工具可见即 AP4 PASS，浏览器二进制问题单列。
把结论（主 Agent 是否有 MCP / SubAgent 是否继承 / 浏览器是否可用）追加到 harness/milestones/harness-selftest/stages/probe/followup.md 并推 main。
```
