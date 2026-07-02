# MCP Bridge Runtime Spec

`trae-mcp-bridge-advisor` owns the MCP bridge runtime.

## Source of truth

`config/mcporter.json` is the only durable configuration source.

It defines:
- MCP servers
- install commands
- keepAlive behavior
- wrapper server ownership
- wrapper allowlists
- translation examples

## Install/call consistency

`mcpServers.*.install`, `mcpServers.*.args`, `bridgeWrappers.*.server`, `bridgeWrappers.*.allowedTools`, and `bridgeWrappers.*.translationExamples` must describe the same MCP server implementation.

Before adding or replacing a server:
1. Pin the server package/version when possible.
2. Confirm the runtime dependency that owns external binaries.
3. Probe the real `tools/list` schema; do not reuse tool names from a different MCP server.
4. Remember that `mcporter call` targets are `server.tool`; wrappers must forward to that form rather than passing a bare tool name.
5. Keep shell examples on `tools/mcp-bridge/bin/{wrapper}` and include required runtime parameters such as `headless:true`.

Playwright example:
- `@playwright/mcp` uses `playwright.browser_*` tool names and may look for a system Chrome distribution depending on version/defaults.
- `@executeautomation/playwright-mcp-server@1.0.12` uses `playwright_*` tool names and depends on `playwright@1.57.0` / Chromium revision 1200.

Mixing the install command for one Playwright runtime with the server/tool names of another creates binary-path or allowlist mismatches.

## Runtime files

- `tools/mcp-bridge/install.sh`
- `tools/mcp-bridge/check.sh`
- `tools/mcp-bridge/bin/` generated at install time
- `tools/mcp-bridge/discovery/` generated at install/check time

## Consumer contract

Downstream Skills such as `trae-harness-advisor` must not generate this runtime.

They may only:
1. Check whether the runtime is installed.
2. Run `tools/mcp-bridge/check.sh --json`.
3. Read `config/mcporter.json`.
4. Copy allowlists and translation examples into their own contract files.
5. Tell SubAgents to call project wrappers only.
