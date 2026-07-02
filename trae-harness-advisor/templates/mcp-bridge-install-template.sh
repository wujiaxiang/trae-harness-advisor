#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="${HARNESS_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
BRIDGE_DIR="${HARNESS_DIR}/mcp-bridge"
BIN_DIR="${BRIDGE_DIR}/bin"

mkdir -p "${BIN_DIR}"

if [[ -n "${MCP_BRIDGE_INSTALL_CMD:-}" ]]; then
  echo "[mcp-bridge] running MCP_BRIDGE_INSTALL_CMD"
  bash -lc "${MCP_BRIDGE_INSTALL_CMD}"
else
  cat > "${BIN_DIR}/mcp-browser" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--bridge-check" ]]; then
  echo "mcp-browser bridge is not configured"
  exit 1
fi
echo "[BLOCKED: MCP bridge unavailable] Set MCP_BRIDGE_INSTALL_CMD or replace harness/mcp-bridge/bin/mcp-browser with a real MCP wrapper." >&2
exit 2
EOF
  chmod +x "${BIN_DIR}/mcp-browser"
fi

chmod +x "${BRIDGE_DIR}/check.sh" 2>/dev/null || true
"${BRIDGE_DIR}/check.sh" --json
