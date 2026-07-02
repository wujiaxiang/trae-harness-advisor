---
name: trae-mcp-bridge-advisor
description: TRAE Work 项目内 MCP shell bridge 初始化与维护专家。用于新增/配置 MCP server、判断是否应桥接给 SubAgent、维护 config/mcporter.json、tools/mcp-bridge/install.sh/check.sh、wrapper 白名单、CDN/install 规范和真机验证。
---

# TRAE MCP Bridge Advisor

本 Skill 是 MCP bridge 基础设施专家。完整规范见 `SKILL.md`；中文使用时遵循同一职责边界：

- MCP runtime 由项目自维护，规范源是 `config/mcporter.json`。
- 安装/生成 wrapper/启动 daemon 由 `tools/mcp-bridge/install.sh` 负责。
- 可用性检查由 `tools/mcp-bridge/check.sh --json` 负责。
- SubAgent 只能调用项目 wrapper，不能直接调用 `npx mcporter call ...` 或 `mcp__*`。
- 新增 MCP 时必须维护安装命令、版本 pin、CDN/镜像、allowedTools、translationExamples 和负面测试。
