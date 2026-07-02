#!/usr/bin/env bash
# MCP Bridge installer.
# Open/closed rule: add MCP servers and wrapper allowlists in config/mcporter.json;
# this script stays generic.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_DIR="${MCP_BRIDGE_DIR:-${SCRIPT_DIR}}"
PROJECT_DIR="$(cd "${BRIDGE_DIR}/../.." && pwd)"
BIN_DIR="${BRIDGE_DIR}/bin"
DISCOVERY_DIR="${BRIDGE_DIR}/discovery"
CONFIG="${MCP_BRIDGE_CONFIG:-${PROJECT_DIR}/config/mcporter.json}"

mkdir -p "${BIN_DIR}" "${DISCOVERY_DIR}"

if [[ ! -f "${CONFIG}" ]]; then
  echo "[mcp-bridge] FATAL: config not found: ${CONFIG}" >&2
  exit 1
fi

run_config_installs() {
  python3 - "${CONFIG}" <<'PY' | while IFS=$'\t' read -r name_idx cmd; do
import json, sys
config = json.load(open(sys.argv[1]))
for name, server in config.get("mcpServers", {}).items():
    for index, command in enumerate(server.get("install", []) or []):
        print(f"{name}#{index}\t{command}")
PY
    [[ -z "${cmd:-}" ]] && continue
    echo "[mcp-bridge] install ${name_idx}: ${cmd}"
    bash -lc "${cmd}" || echo "[mcp-bridge] install ${name_idx} FAILED (continue)"
  done
}

write_wrapper() {
  local wrapper_name="$1"
  local wrapper_path="${BIN_DIR}/${wrapper_name}"
  python3 - "${CONFIG}" "${wrapper_name}" "${wrapper_path}" <<'PY'
import json, shlex, sys

config_path, wrapper_name, wrapper_path = sys.argv[1:4]
config = json.load(open(config_path))
wrapper = config.get("bridgeWrappers", {}).get(wrapper_name)
if not wrapper:
    raise SystemExit(f"missing bridgeWrappers.{wrapper_name}")

allowed = wrapper.get("allowedTools", [])
quoted_allowed = "\n".join(f"  {shlex.quote(tool)}" for tool in allowed)
script = f"""#!/usr/bin/env bash
set -euo pipefail

CONFIG={shlex.quote(config_path)}
ALLOWED=(
{quoted_allowed}
)

if [[ "${{1:-}}" == "--bridge-check" ]]; then
  npx -y mcporter daemon status --config "${{CONFIG}}" >/dev/null
  exit $?
fi

TARGET="${{1:-}}"
if [[ -z "${{TARGET}}" ]]; then
  echo "[BLOCKED: MCP bridge command not allowed] empty target" >&2
  exit 2
fi

FOUND=0
for entry in "${{ALLOWED[@]}}"; do
  if [[ "${{entry}}" == "${{TARGET}}" ]]; then
    FOUND=1
    break
  fi
done

if [[ "${{FOUND}}" -ne 1 ]]; then
  echo "[BLOCKED: MCP bridge command not allowed] ${{TARGET}}" >&2
  exit 2
fi

shift
npx -y mcporter call "${{TARGET}}" "$@" --config "${{CONFIG}}" --output json --timeout 60000
"""
open(wrapper_path, "w").write(script)
PY
  chmod +x "${wrapper_path}"
}

write_wrappers() {
  python3 - "${CONFIG}" <<'PY' | while IFS= read -r wrapper_name; do
import json, sys
config = json.load(open(sys.argv[1]))
for name in config.get("bridgeWrappers", {}):
    print(name)
PY
    [[ -z "${wrapper_name:-}" ]] && continue
    write_wrapper "${wrapper_name}"
  done
}

run_mcporter_discovery() {
  local output="${DISCOVERY_DIR}/mcporter-list.txt"
  local errors="${DISCOVERY_DIR}/mcporter-list.err"
  {
    echo "mcporter_version=$(npx -y mcporter --version 2>/dev/null || echo unknown)"
    echo "config=${CONFIG}"
  } > "${DISCOVERY_DIR}/env.txt"
  (cd "${PROJECT_DIR}" && npx -y mcporter list --config "${CONFIG}" >"${output}" 2>"${errors}") || true
}

run_config_installs
write_wrappers
echo "[mcp-bridge] starting mcporter daemon"
(cd "${PROJECT_DIR}" && npx -y mcporter daemon start --config "${CONFIG}") || echo "[mcp-bridge] daemon start failed (may already be running)"
run_mcporter_discovery
chmod +x "${BRIDGE_DIR}/check.sh" 2>/dev/null || true
"${BRIDGE_DIR}/check.sh" --json
