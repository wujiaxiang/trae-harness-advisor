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
- 安装/调用必须同源：`install`、`args`、`allowedTools`、`translationExamples` 必须匹配同一个 MCP server 的真实工具名和参数 schema。
- Playwright 类 server 不能混用：`@playwright/mcp` 的工具名是 `playwright.browser_*`；`@executeautomation/playwright-mcp-server@1.0.12` 的工具名是 `playwright_*`，且依赖 Playwright 1.57.0 / Chromium revision 1200。
- 大二进制安装要 pin 到 server 依赖版本并配置可达 CDN；例如 `PLAYWRIGHT_DOWNLOAD_HOST=https://cdn.npmmirror.com/binaries/playwright npx -y playwright@1.57.0 install --with-deps chromium`。
