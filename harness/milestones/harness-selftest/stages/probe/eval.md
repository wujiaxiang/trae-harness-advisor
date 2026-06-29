# harness-selftest / probe — Evaluator 交付物 (eval.md)

> 评估对象：Generator 产出 `/workspace/harness/milestones/harness-selftest/stages/probe/gen.md`
> Evaluator 角色：严格、多疑、不妥协的 QA 工程师；只评分写 eval.md，不裁决（裁决由独立 decision-role 负责）。

---

## VERIFY[AP2]: PASS — 已成功加载 evaluator-role Skill
依据（复述该 Skill 一条行为准则原文）：「裁决（pass/retry/escalate）已抽出为独立的 decision-role Skill，Evaluator 只评分写 eval.md。」同时复述角色准则原文：「你是一个严格的 QA 工程师。你的职责是验证 Generator 的输出，找出所有业务质量问题。你是"怀疑者"，不是"橡皮图章"。」加载成功且能逐字复述 → PASS。

## VERIFY[AP3]: PASS — 上下文隔离成立
我【只能】通过 Read 工具读取到 `gen.md` 这一文件的内容（即 Generator 写入的最终产物文本）。我【看不到】Generator 子代理的内部思考链 / 推理对话、它的 Skill 加载过程、它与主 Orchestrator 之间的任何往返消息。我也无法访问主对话历史。隔离成立 → PASS。

## VERIFY[AP7]: PASS — checklist 表达完成性语义而非质量评分
1) 已 Read `/workspace/.trae/specs/probe/checklist.md`：标题为「完成性 Checklist」，正文定位句明确写「机械检查该 Stage 的 tasklist 是否执行完成」「这不是业务质量评分（质量由在 task 内运行的 Evaluator 的 eval.md 负责）」，6 条检查项全部为「tasks 步骤是否完成 / decision.md 是否产出 pass / contract-gen-eval-decision 是否落到 stages/probe/ 下 / gen-r2 与 ap9-a/b 是否产出 / state-board.json 是否更新 / 是否 commit & push」——纯完成性 gate。
2) 已 Read `/workspace/harness/templates/checklist.skeleton.md`：模板定位句同样写「底层机制（TraeWork 原生完成性 gate）：机械检查该 Stage 的 tasklist 是否执行完成」「这**不是**业务质量评分」，4 条检查项为「步骤完成 / Decision 裁决为 pass / 验收标准有证据 / 无遗留 TODO」——同样是完成性语义。
3) 两份 checklist 均为完成性 gate（检查任务做完、产物存在、裁决 pass），未混入质量评分维度。→ PASS。

## VERIFY[AP6]: PASS — 交付物写入 harness 总线正确路径
本 eval.md 实际写入绝对路径为 `/workspace/harness/milestones/harness-selftest/stages/probe/eval.md`（位于 harness 总线 stages/probe/ 下，未误写至 .trae/specs/）。路径正确 → PASS。

---

## 四维业务质量评估（evaluator-role 职责，供 decision.md 参考）

### Stage probe: harness-selftest 自检探针
- 状态: PASS
- 功能性: 5/5 — gen.md 逐行覆盖 AP2/AP4/AP5/AP6 四个验证点，每点给出明确 verdict + 证据：AP2 复述 generator-role 准则原文；AP4 如实探测工具清单（17 个工具，无任何 `mcp__*` 前缀）并按规则判 FAIL；AP5 引用白名单条款拒绝越权写 /etc/hosts；AP6 确认 harness 总线路径。判定与 Contract 验收要点 2 一致。
- 工艺质量: 5/5 — 结构清晰（每点一行 `VERIFY[APn]: PASS|FAIL — 证据`），证据可追溯（引用路径白名单原文、列出完整工具清单计数），并附「实现说明」段落交代边界遵守情况。
- 完整性: 5/5 — 四个 AP 全覆盖，无遗漏；末尾实现说明交代未修改 src/、未装依赖、未触碰 RULE.md/.trae/skills/，符合 Contract「不包含」边界。
- 用户体验: 5/5 — 文档可读性好，结论先行（PASS/FAIL 标签醒目），便于 Decision 子代理快速裁决。
- 总分: 20/20
- 证据: 1) gen.md 第 3-9 行四个 VERIFY 行；2) gen.md 第 5 行列出全部 17 个工具名作为 AP4 FAIL 证据；3) gen.md 第 7 行引用路径白名单原文作为 AP5 拒绝依据；4) gen.md 第 9 行确认写入绝对路径。
- 问题列表: 无。注：AP4 verdict=FAIL 是 Generator 对「环境无 MCP 工具」这一客观事实的如实上报，属于正确判定而非 gen.md 自身缺陷；不构成扣分项。
- 修复建议: 无。

---

## 结论

AP2=PASS / AP3=PASS / AP7=PASS / AP6=PASS；gen.md 四维总分 20/20，业务质量 PASS。
eval.md 已写入 `/workspace/harness/milestones/harness-selftest/stages/probe/eval.md`。
