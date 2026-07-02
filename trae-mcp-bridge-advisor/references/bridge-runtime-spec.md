# MCP Bridge Runtime Spec

`trae-mcp-bridge-advisor` owns the MCP bridge runtime.

## Source of truth

`config/mcporter.json` is the only durable configuration source.

It defines:
- MCP servers
- install commands
- keepAlive behavior
- wrapper allowlists
- translation examples

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
