# 项目规范（RULE.md）

> 本文件位于项目根目录，通过 TRAE Work 云端钩子规则自动加载。
> 钩子规则文本：`在开始执行任何任务之前，必须先读取当前项目根目录的 RULE.md 文件，将其内容作为当前项目的编码规范、约束条件和行为准则。如果 RULE.md 不存在，则跳过此步骤。`
> 用户需将此钩子规则复制到 TRAE Work「设置 > 规则」中（仅需操作一次）。

## 常用命令
- 启动开发服务器: `npm run dev`
- 运行全部测试: `npm test`
- 运行单个测试文件: `npm test -- {file}`
- Lint 检查: `npm run lint`

## 关键目录结构
- src/ — 源代码
- tests/ — 测试文件
- {eval_dir} — 评估报告（Generator 和 Evaluator 写入）
- {spec_dir} — SPEC 文档和模板
- {contract_dir} — Sprint Contract
- {skill_dir} — 角色 Skill（静态配置，git 同步）

## 编码约定
- 禁止使用 `any` 类型
- 所有函数必须有类型注解
- 组件文件使用 PascalCase
- 工具函数文件使用 camelCase
- 测试文件命名为 `{filename}.test.ts`

## 全局禁止修改
- node_modules/
- dist/
- build/
- .git/
- .env 文件
- package.json（除非 Sprint Contract 明确授权）
- {skill_dir}（角色 Skill 定义）
- {spec_dir}（SPEC 文档）
- {contract_dir}（Sprint Contract）