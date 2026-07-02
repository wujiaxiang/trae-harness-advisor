#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="${HARNESS_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
BRIDGE_DIR="${HARNESS_DIR}/mcp-bridge"
BIN_DIR="${BRIDGE_DIR}/bin"
MANIFEST="${BRIDGE_DIR}/manifest.json"

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

if [[ "${1:-}" == "--json" ]]; then
  browser_err_json="$(printf '%s' "${browser_err}" | json_escape)"
  cat <<EOF
{
  "available": ${available},
  "mode": "evaluator_shell_bridge",
  "manifest": "${MANIFEST}",
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
