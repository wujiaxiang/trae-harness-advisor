#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="${HARNESS_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
PROJECT_DIR="$(cd "${HARNESS_DIR}/.." && pwd)"
BRIDGE_DIR="${HARNESS_DIR}/mcp-bridge"
BIN_DIR="${BRIDGE_DIR}/bin"
CONFIG="${MCP_BRIDGE_CONFIG:-${PROJECT_DIR}/config/mcporter.json}"
DISCOVERY_DIR="${BRIDGE_DIR}/discovery"

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

check_command() {
  local name="$1"
  local cmd="${BIN_DIR}/${name}"
  if [[ ! -x "${cmd}" ]]; then
    echo "missing"
    return 1
  fi
  if "${cmd}" --bridge-check >/tmp/mcp-bridge-"${name}".out 2>/tmp/mcp-bridge-"${name}".err; then
    echo "available"
    return 0
  fi
  echo "unavailable"
  return 1
}

browser_status="$(check_command mcp-browser || true)"
available=false
if [[ "${browser_status}" == "available" ]]; then
  available=true
fi

browser_err=""
if [[ -f /tmp/mcp-bridge-mcp-browser.err ]]; then
  browser_err="$(cat /tmp/mcp-bridge-mcp-browser.err)"
fi

discovery_status="missing"
discovery_summary=""
if [[ -f "${DISCOVERY_DIR}/mcporter-list.txt" ]]; then
  discovery_status="present"
  discovery_summary="$(head -n 40 "${DISCOVERY_DIR}/mcporter-list.txt")"
fi

discovery_err=""
if [[ -f "${DISCOVERY_DIR}/mcporter-list.err" ]]; then
  discovery_err="$(head -n 40 "${DISCOVERY_DIR}/mcporter-list.err")"
fi

if [[ "${1:-}" == "--json" ]]; then
  browser_err_json="$(printf '%s' "${browser_err}" | json_escape)"
  discovery_summary_json="$(printf '%s' "${discovery_summary}" | json_escape)"
  discovery_err_json="$(printf '%s' "${discovery_err}" | json_escape)"
  cat <<EOF
{
  "available": ${available},
  "mode": "evaluator_shell_bridge",
  "config": "${CONFIG}",
  "discovery": {
    "status": "${discovery_status}",
    "path": "${DISCOVERY_DIR}/mcporter-list.txt",
    "summary": ${discovery_summary_json},
    "errors": ${discovery_err_json}
  },
  "commands": {
    "mcp-browser": "${browser_status}"
  },
  "errors": {
    "mcp-browser": ${browser_err_json}
  }
}
EOF
else
  echo "mcp-browser=${browser_status}"
fi
