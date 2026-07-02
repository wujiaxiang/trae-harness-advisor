#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="${HARNESS_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
BRIDGE_DIR="${HARNESS_DIR}/mcp-bridge"
BIN_DIR="${BRIDGE_DIR}/bin"
DISCOVERY_DIR="${BRIDGE_DIR}/discovery"

mkdir -p "${BIN_DIR}"
mkdir -p "${DISCOVERY_DIR}"

run_mcporter_discovery() {
  local output="${DISCOVERY_DIR}/mcporter-list.txt"
  local errors="${DISCOVERY_DIR}/mcporter-list.err"

  {
    echo "MCP_BRIDGE_DISCOVER=${MCP_BRIDGE_DISCOVER:-0}"
    echo "MCP_BRIDGE_SERVER_NAME=${MCP_BRIDGE_SERVER_NAME:-}"
    echo "MCP_BRIDGE_SERVER_CMD=${MCP_BRIDGE_SERVER_CMD:-}"
    echo "MCP_BRIDGE_HTTP_URL=${MCP_BRIDGE_HTTP_URL:-}"
  } > "${DISCOVERY_DIR}/env.txt"

  if [[ "${MCP_BRIDGE_DISCOVER:-0}" != "1" ]]; then
    echo "discovery skipped; set MCP_BRIDGE_DISCOVER=1" > "${output}"
    return 0
  fi

  if [[ -n "${MCP_BRIDGE_SERVER_NAME:-}" ]]; then
    npx -y mcporter list "${MCP_BRIDGE_SERVER_NAME}" --brief >"${output}" 2>"${errors}" || true
    return 0
  fi

  if [[ -n "${MCP_BRIDGE_SERVER_CMD:-}" ]]; then
    npx -y mcporter list --stdio "${MCP_BRIDGE_SERVER_CMD}" --brief >"${output}" 2>"${errors}" || true
    return 0
  fi

  if [[ -n "${MCP_BRIDGE_HTTP_URL:-}" ]]; then
    npx -y mcporter list --http-url "${MCP_BRIDGE_HTTP_URL}" --brief >"${output}" 2>"${errors}" || true
    return 0
  fi

  npx -y mcporter list --timeout "${MCP_BRIDGE_DISCOVERY_TIMEOUT_MS:-5000}" >"${output}" 2>"${errors}" || true
}

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

run_mcporter_discovery
chmod +x "${BRIDGE_DIR}/check.sh" 2>/dev/null || true
"${BRIDGE_DIR}/check.sh" --json
