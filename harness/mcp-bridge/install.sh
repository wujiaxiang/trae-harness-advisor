#!/usr/bin/env bash
# MCP Bridge 通用安装引擎（开闭原则：加新 MCP 只改 config/mcporter.json + wrapper ALLOWED）
# 职责：1.读 config 跑各 server 的 install 命令  2.生成通用 wrapper  3.启动 mcporter daemon
# 本文件不含任何 MCP server 细节（chrome 路径/启动命令/install 命令均在 config 中）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="${HARNESS_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
BRIDGE_DIR="${HARNESS_DIR}/mcp-bridge"
BIN_DIR="${BRIDGE_DIR}/bin"
DISCOVERY_DIR="${BRIDGE_DIR}/discovery"
CONFIG="${HARNESS_DIR}/../config/mcporter.json"

mkdir -p "${BIN_DIR}"
mkdir -p "${DISCOVERY_DIR}"

# === 1. 读 config，遍历所有 server，跑各自 install 命令 ===
if [[ ! -f "${CONFIG}" ]]; then
  echo "[mcp-bridge] FATAL: config not found: ${CONFIG}" >&2
  exit 1
fi

echo "[mcp-bridge] reading config: ${CONFIG}"
# 解析 config，输出 "<server_name>#<idx>\t<install_cmd>" 行
# install 字段缺失的 server 跳过；命令失败不阻断（继续下一个）
INSTALL_CMDS=$(python3 -c "
import json
c = json.load(open('${CONFIG}'))
for name, s in c.get('mcpServers', {}).items():
    for i, cmd in enumerate(s.get('install', []) or []):
        print(f'{name}#{i}\t{cmd}')
" 2>/dev/null || echo "")

if [[ -n "${INSTALL_CMDS}" ]]; then
  while IFS=$'\t' read -r name_idx cmd; do
    [[ -z "${cmd:-}" ]] && continue
    echo "[mcp-bridge] install ${name_idx}: ${cmd}"
    bash -lc "${cmd}" || echo "[mcp-bridge] install ${name_idx} FAILED (continue)"
  done <<< "${INSTALL_CMDS}"
else
  echo "[mcp-bridge] no install commands in config"
fi

# === 2. 写 env.txt（记录 mcporter 版本 + config 路径） ===
{
  echo "mcporter_version=$(npx -y mcporter --version 2>/dev/null || echo unknown)"
  echo "config=${CONFIG}"
} > "${DISCOVERY_DIR}/env.txt"

# === 3. 生成通用 wrapper（固化白名单 + 纯转发，不含 MCP 细节） ===
# 加新 MCP server 时：在下面 ALLOWED 数组追加 "server.tool" 行
cat > "${BIN_DIR}/mcp-browser" <<'WRAPPER'
#!/usr/bin/env bash
# 通用 MCP bridge wrapper：固化白名单 + 纯转发到 mcporter daemon
# 加新 MCP server 时：① 在 config/mcporter.json 加 server 条目 ② 在下面 ALLOWED 追加 server.tool
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

# === 4. 启动 mcporter daemon（自动拉起所有 keepAlive server） ===
echo "[mcp-bridge] starting mcporter daemon"
cd "${HARNESS_DIR}/.." && npx -y mcporter daemon start 2>&1 || echo "[mcp-bridge] daemon start failed (may already be running)"

# === 5. discovery + 自检 ===
run_mcporter_discovery() {
  local output="${DISCOVERY_DIR}/mcporter-list.txt"
  local errors="${DISCOVERY_DIR}/mcporter-list.err"
  cd "${HARNESS_DIR}/.." && npx -y mcporter list >"${output}" 2>"${errors}" || true
}

run_mcporter_discovery
chmod +x "${BRIDGE_DIR}/check.sh" 2>/dev/null || true
"${BRIDGE_DIR}/check.sh" --json
