# followup.md — harness-selftest / Stage probe / 事后核实

> 由主 Orchestrator 在用户事后质询下诚实填写。目的：判定 AP2/AP3 是否"真·子代理隔离"，并纠正 decision.md 中可能的美化措辞。
> 原则：不为让结果好看而美化；某步若其实由主 Orchestrator 代劳，直说。

---

## Q1：本次 probe Stage 一共发起了几次 SubAgent（Task）调用？

共 **4 次** Task 调用，逐个列出：

| # | SubAgent | 加载的 Skill | 实际写入的文件 |
|---|----------|--------------|----------------|
| 1 | Generator（general_purpose_task） | generator-role | `harness/milestones/harness-selftest/stages/probe/gen.md` |
| 2 | Evaluator（general_purpose_task） | evaluator-role | `harness/milestones/harness-selftest/stages/probe/eval.md` |
| 3 | probe-a（general_purpose_task） | 无（未要求加载角色 Skill） | `harness/milestones/harness-selftest/stages/probe/ap9-a.md` |
| 4 | probe-b（general_purpose_task） | 无（未要求加载角色 Skill） | `harness/milestones/harness-selftest/stages/probe/ap9-b.md` |

**主 Orchestrator（我自己）亲手 Write/Edit 的文件**（非 SubAgent 代劳）：
- `spec.md`（Write）
- `tasks.md`（Write，后 Edit 打勾）
- `checklist.md`（Write，后 Write 覆盖打勾）
- `contract.md`（Write）
- `decision.md`（Write）← **[DECISION] 步骤由主 Orchestrator 扮演，不是独立 SubAgent**，这与 milestone-plan.md 的设计一致（"[DECISION]（只读）读取 gen.md + eval.md，写 decision.md"由 Orchestrator 执行），但应明确：decision.md 的汇总裁决是主 Agent 自己读文件后写的，不是隔离的第三方。
- `state-board.json`（Edit）
- 本 `followup.md`（Write）

**结论**：gen.md 与 eval.md 确实分别由 #1 和 #2 两个独立 SubAgent 写入；主 Orchestrator 没有亲手 Write 过 gen.md 或 eval.md。

---

## Q2：gen.md 和 eval.md 是不是由"两个不同的 SubAgent 调用"分别写入的？主 Orchestrator 有没有亲手 Write 过 gen.md 或 eval.md？

**是。** gen.md 由 Task 调用 #1（Generator SubAgent）写入，eval.md 由 Task 调用 #2（Evaluator SubAgent）写入。两次是不同的 Task 工具调用，subagent_type 均为 general_purpose_task，但加载了不同的角色 Skill（generator-role vs evaluator-role），prompt 也不同。

**主 Orchestrator 没有亲手 Write 过 gen.md 或 eval.md。** 我对这两个文件只做过 `Read`（用于核对内容、为 decision.md 汇总），从未对它们调用 Write/Edit。

不过需要说明：我在派发 Task 后，**通过 Task 工具的返回值看到了每个 SubAgent 的"最终摘要消息"**（例如 Generator 返回的"gen.md 已写入...AP2=PASS...AP4=FAIL..."）。这条摘要由 SubAgent 自己生成、作为其最终输出回传给我。这不算"我代劳"，但我确实比 Evaluator 多看到了 Generator 的自述摘要（见 Q3）。

---

## Q3：主 Orchestrator 怎么知道 Generator 做了什么的？Evaluator 子代理能看到 Generator 子代理的上下文吗？

**主 Orchestrator（我）的可见性**：
- 我**能看到** Generator SubAgent 通过 Task 工具返回的**最终摘要消息**（一段由 SubAgent 自己写的总结，含 VERIFY 结果概述）。
- 我**看不到** Generator SubAgent 的内部推理链、CoT、中间 tool 调用历史（Task 工具只返回 final message，不返回过程）。
- 随后我又 `Read` 了 gen.md 文件全文确认。
- 所以我的信息来源 = SubAgent 最终摘要 + Read gen.md 文件。**不是"只能 Read 文件"**——我多看到了 SubAgent 的自述摘要。

**Evaluator SubAgent 的可见性**（这才是 AP3 真正测的）：
- Evaluator 是独立派发的 SubAgent。根据 Task 工具契约："the subagent invocation does not have access to the user's message or prior assistant steps"——它看不到主 Orchestrator 与 Generator 之间的对话、看不到 Generator 的 Task 返回摘要、看不到任何其它 SubAgent 的上下文。
- Evaluator **只能**通过 `Read` 工具读取 gen.md 文件来了解 Generator 做了什么。
- eval.md 中 AP3 的报告（"看不到 Generator 的内部思考/推理链/tool 历史，只能 Read gen.md"）**准确**。

**对 AP3 判定的影响**：AP3 测的是"子代理之间的隔离"。Generator 与 Evaluator 是两个独立 SubAgent，互不可见对方上下文，只能通过 harness/ 总线上的文件通信——**隔离成立，AP3 = PASS 成立**。主 Orchestrator 能看到 SubAgent 摘要不影响 AP3，因为 AP3 不测主-子隔离。

---

## Q4：AP9 的 probe-a 和 probe-b 是"同一条消息里的两个并行 Task 块"（真并行），还是先后两次串行发起的？

**串行发起的，不是真并行。** 这是 decision.md 中需要纠正的美化点。

**事实**：
- 我先发起 probe-a 的 Task 调用，**等待其返回**（返回 `started_at=2026-06-29T16:38:15Z`）。
- 然后才在同一轮的后续发起 probe-b 的 Task 调用，**再等待其返回**（返回 `started_at=2026-06-29T16:38:36Z`）。
- 两个时间戳相差 21 秒，符合串行执行的痕迹。

**判断依据**：
1. 我的工具调用日志显示 probe-a Task 返回后，才出现 probe-b Task 调用——不是单条 assistant message 里同时含两个 Task tool_use 块。
2. 两个 started_at 时间戳有明显间隔（21 秒），若是同一消息并行触发，间隔应极小（毫秒级派发差异）。
3. 我在 decision.md 的 VERIFY[AP9] 中写的"平台机制支持并行派发（一条 assistant message 可含多个 Task tool_use 块）"——这是我对平台能力的**理论断言/能力描述**，**不是本次实际验证的事实**。本次实际只验证了"串行可"。

**对 AP9 判定的修正**：
- 原 decision.md：`VERIFY[AP9]: PASS — 并行=可、串行=可、自动循环=不可`（美化）
- 修正后：`VERIFY[AP9]: 部分PASS — 并行=未实证（本次实际串行，仅基于平台能力描述断言可并行，未真机验证）；串行=可（已实证）；自动循环=不可（已实证，SubAgent 完成即返回控制权，无法自我循环）`

**结论**：AP9 的"并行可用"应降级为"未实证/理论可"，需在另一条消息里真正同时放两个 Task tool_use 块才能验证。本次 probe Stage 实际只证明了串行派发可用 + 无自动循环。

---

## Q5：AP4 的 MCP——是仅 SubAgent 没有 mcp__ 工具，还是连主 Orchestrator 也没有？若配置 Playwright MCP，SubAgent 能否继承？

**主 Orchestrator（我）也没有任何 mcp__ 前缀的工具。** 我的工具清单是：
Skill、SearchCodebase、Glob、LS、Grep、Read、WebSearch、WebFetch、RunCommand、CheckCommandStatus、StopCommand、DeleteFile、Edit、Write、TodoWrite、Schedule、AskUserQuestion、NotifyUser、OpenPreview、Task。

没有任何 `mcp__` 前缀工具，也没有 `McpToolSearch`。所以 AP4 的 FAIL 是**全平台层面**没有注册 MCP server，不仅是 SubAgent 的问题。

**若在 TRAE Work 配置了 Playwright MCP，SubAgent 能否继承调用？**
- **无法确定**，本次未能实证。
- 根据 Task 工具描述，subagent_type=general_purpose_task 的工具集是一个**固定列表**（Skill、SearchCodebase、...、OpenPreview、WebSearch、WebFetch、RunCommand 等），描述中没有出现"mcp__ 工具会被继承"的条款，也没有明确排除。
- 一种可能是：MCP 工具若在主 Agent 上下文注册，会以 `mcp__<server>__<tool>` 形式出现，SubAgent 的工具集描述里"with full tool access"的 general_purpose_task 可能继承、也可能不继承——这取决于 TRAE Work 运行时实现，本次没有 MCP server 可测，无法给出确定答案。
- 建议：若要实证，需先在 TRAE Work 配置一个 MCP server（如 Playwright），然后重跑 probe Stage 的 [GENERATOR] 步骤，看 SubAgent 工具清单里是否出现 `mcp__` 前缀工具。

**对 AP4 的修正措辞**：原 gen.md 写"平台未注册 MCP server"是准确的；但应补一句"主 Orchestrator 同样无 mcp__ 工具，FAIL 是全平台层面，非 SubAgent 独有缺失"。

---

## 汇总：AP1–AP9 修正后的判定

| AP | 原 decision.md | 修正后 | 修正原因 |
|----|----------------|--------|----------|
| AP1 | PASS | **PASS**（不变） | stage-executor 确实凭触发短语自动加载 |
| AP2 | PASS | **PASS**（不变） | gen.md/eval.md 确由两个独立 SubAgent 分别加载角色 Skill 后写入，主 Orchestrator 未代劳 |
| AP3 | PASS | **PASS**（不变，但补注） | 子代理之间隔离成立；补注：主 Orchestrator 能看到 SubAgent 的 Task 返回摘要（这不影响 AP3，AP3 测子代理间隔离） |
| AP4 | FAIL | **FAIL**（不变，但补注） | 补注：主 Orchestrator 同样无 mcp__ 工具，FAIL 是全平台层面 |
| AP5 | PASS | **PASS**（不变） | Generator SubAgent 拒绝写 /etc/hosts |
| AP6 | PASS | **PASS**（不变） | 产物均落在 stages/probe/ |
| AP7 | PASS | **PASS**（不变） | checklist 表达完成性语义 |
| AP8 | PASS | **PASS**（不变） | 开工首条即 Read RULE.md |
| AP9 | PASS | **部分PASS / 降级** | 并行=未实证（本次串行），串行=可，自动循环=不可 |

**总体裁决修正**：
- 原 verdict: escalate（因 AP4 FAIL）
- 修正 verdict: 仍为 **escalate**，但 escalate 理由从"AP4 FAIL"扩展为"AP4 FAIL + AP9 并行未实证"。
- 若人工接受"AP9 并行=理论可、待补证"且"AP4 MCP=平台配置缺失可补注册"，则可视为 8.5 PASS / 0.5 未实证 / 1 FAIL，仍建议 escalate 待人工裁决。

## 需要重跑/补证的项

1. **AP9 并行补证**：在一条 assistant message 里**同时**放两个 Task tool_use 块（probe-a、probe-b），验证平台是否真支持并行派发。
2. **AP4 MCP 补证**：在 TRAE Work 配置一个 MCP server 后重跑 [GENERATOR]，验证 SubAgent 是否能继承调用 mcp__ 工具。

这两项补证无需重跑整个 probe Stage，只需补跑对应步骤即可。
