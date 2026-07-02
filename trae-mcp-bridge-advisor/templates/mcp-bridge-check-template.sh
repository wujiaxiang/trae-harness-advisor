#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_DIR="${MCP_BRIDGE_DIR:-${SCRIPT_DIR}}"
PROJECT_DIR="$(cd "${BRIDGE_DIR}/../.." && pwd)"
BIN_DIR="${BRIDGE_DIR}/bin"
CONFIG="${MCP_BRIDGE_CONFIG:-${PROJECT_DIR}/config/mcporter.json}"
DISCOVERY_DIR="${BRIDGE_DIR}/discovery"

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

declare -a WRAPPERS=()
while IFS= read -r wrapper_name; do
  [[ -n "${wrapper_name}" ]] && WRAPPERS+=("${wrapper_name}")
done < <(python3 - "${CONFIG}" <<'PY'
import json, sys
try:
    config = json.load(open(sys.argv[1]))
except FileNotFoundError:
    raise SystemExit(0)
for name in config.get("bridgeWrappers", {}):
    print(name)
PY
)

STATUS_FILE="$(mktemp)"
ERRORS_FILE="$(mktemp)"
trap 'rm -f "${STATUS_FILE}" "${ERRORS_FILE}"' EXIT
available=true
if [[ ! -f "${CONFIG}" || "${#WRAPPERS[@]}" -eq 0 ]]; then
  available=false
fi
for wrapper_name in "${WRAPPERS[@]}"; do
  status="$(check_command "${wrapper_name}" || true)"
  printf '%s\t%s\n' "${wrapper_name}" "${status}" >> "${STATUS_FILE}"
  if [[ -f /tmp/mcp-bridge-"${wrapper_name}".err ]]; then
    printf '%s\t%s\n' "${wrapper_name}" "$(cat /tmp/mcp-bridge-"${wrapper_name}".err)" >> "${ERRORS_FILE}"
  else
    printf '%s\t%s\n' "${wrapper_name}" "" >> "${ERRORS_FILE}"
  fi
  if [[ "${status}" != "available" ]]; then
    available=false
  fi
done

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
  python3 - "${available}" "${CONFIG}" "${DISCOVERY_DIR}/mcporter-list.txt" "${discovery_status}" "${discovery_summary}" "${discovery_err}" "${STATUS_FILE}" "${ERRORS_FILE}" <<'PY'
import json, sys
available, config, discovery_path, discovery_status, discovery_summary, discovery_err, status_path, errors_path = sys.argv[1:9]

def read_tsv(path):
    data = {}
    with open(path) as handle:
        for line in handle:
            name, _, value = line.rstrip("\n").partition("\t")
            data[name] = value
    return data

print(json.dumps({
    "available": available == "true",
    "mode": "evaluator_shell_bridge",
    "config": config,
    "discovery": {
        "status": discovery_status,
        "path": discovery_path,
        "summary": discovery_summary,
        "errors": discovery_err,
    },
    "commands": read_tsv(status_path),
    "errors": read_tsv(errors_path),
}, ensure_ascii=False, indent=2))
PY
else
  if [[ ! -f "${CONFIG}" ]]; then
    echo "config=missing"
  fi
  awk -F '\t' '{print $1 "=" $2}' "${STATUS_FILE}"
fi
