# Follow-up Prompt — 确认 AP2/AP3 是否“真·子代理隔离”

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
