#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load functions without executing install.sh's command dispatcher.
# shellcheck disable=SC1090
source <(sed '/^# Main/,$d' "$PROJECT_DIR/install.sh")

if ! type restart_aerospace &>/dev/null; then
    echo "FAIL: restart_aerospace is not defined" >&2
    exit 1
fi

calls=()
pgrep_calls=0

pgrep() {
    calls+=("pgrep $*")
    pgrep_calls=$((pgrep_calls + 1))
    [ "$pgrep_calls" -eq 1 ]
}

osascript() {
    calls+=("osascript $*")
}

open() {
    calls+=("open $*")
}

aerospace() {
    calls+=("aerospace $*")
    [ "$*" = "list-modes" ]
}

sleep() {
    calls+=("sleep $*")
}

restart_aerospace >/dev/null

expected_restart_calls=(
    "pgrep -x AeroSpace"
    "osascript -e tell application \"AeroSpace\" to quit"
    "pgrep -x AeroSpace"
    "open -a AeroSpace"
    "aerospace list-modes"
)

[ "${calls[*]}" = "${expected_restart_calls[*]}" ]

calls=()
pgrep_calls=0

brew() {
    calls+=("brew $*")
}

start_services >/dev/null

expected_service_calls=(
    "brew services restart sketchybar"
    "brew services restart borders"
    "pgrep -x AeroSpace"
    "osascript -e tell application \"AeroSpace\" to quit"
    "pgrep -x AeroSpace"
    "open -a AeroSpace"
    "aerospace list-modes"
)

[ "${calls[*]}" = "${expected_service_calls[*]}" ]

echo "PASS: install service contract"
