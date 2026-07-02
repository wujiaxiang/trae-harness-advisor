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
  local config="${HARNESS_DIR}/../config/mcporter.json"

  if [[ ! -f "${config}" ]]; then
    echo "config/mcporter.json not found" > "${output}"
    echo "missing config" > "${errors}"
    return 0
  fi

  cd "${HARNESS_DIR}/.." && npx -y mcporter list >"${output}" 2>"${errors}" || true
}

{
  echo "mcporter_version=$(npx -y mcporter --version 2>/dev/null || echo unknown)"
  echo "config=${HARNESS_DIR}/../config/mcporter.json"
} > "${DISCOVERY_DIR}/env.txt"

cat > "${BIN_DIR}/mcp-browser" <<'WRAPPER'
#!/usr/bin/env bash
# 通用 MCP bridge wrapper：纯转发 + 白名单校验，不含 MCP server 细节
# 加新 MCP server 只改 config/mcporter.json + 追加本文件 ALLOWED 数组
set -euo pipefail

ALLOWED=(
  "playwright.browser_navigate"
  "playwright.browser_snapshot"
  "playwright.browser_take_screenshot"
  "playwright.browser_click"
  "playwright.browser_evaluate"
)

if [[ "${1:-}" == "--bridge-check" ]]; then
  if npx -y mcporter daemon status >/dev/null 2>&1; then
    echo "available"
    exit 0
  fi
  echo "unavailable: daemon not running"
  exit 1
fi

TARGET="${1:-}"
if [[ -z "${TARGET}" ]]; then
  echo "[BLOCKED: MCP bridge command not allowed] empty target" >&2
  exit 2
fi

# 校验白名单
FOUND=0
for entry in "${ALLOWED[@]}"; do
  if [[ "${entry}" == "${TARGET}" ]]; then
    FOUND=1
    break
  fi
done

if [[ "${FOUND}" -ne 1 ]]; then
  echo "[BLOCKED: MCP bridge command not allowed] ${TARGET}" >&2
  exit 2
fi

shift
npx -y mcporter call "${TARGET}" "$@" --output json --timeout 60000
WRAPPER
chmod +x "${BIN_DIR}/mcp-browser"

echo "[mcp-bridge] starting mcporter daemon"
cd "${HARNESS_DIR}/.." && npx -y mcporter daemon start 2>&1 || echo "[mcp-bridge] daemon start failed (may already be running)"

run_mcporter_discovery
chmod +x "${BRIDGE_DIR}/check.sh" 2>/dev/null || true
"${BRIDGE_DIR}/check.sh" --json
