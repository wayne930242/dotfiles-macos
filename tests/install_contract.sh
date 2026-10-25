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

launchctl() {
    calls+=("launchctl $*")
}

# The launch agent is written to a scratch directory, never to the real LaunchAgents
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
NET_BIN="$scratch/net"
NET_AGENT_PLIST="$scratch/LaunchAgents/$NET_AGENT_LABEL.plist"
NET_LOG="$scratch/Logs/sketchybar-net.log"
WALL_BIN="$scratch/wallgen"
WALL_AGENT_PLIST="$scratch/LaunchAgents/$WALL_AGENT_LABEL.plist"
WALL_LOG="$scratch/Logs/wallgen.log"
printf '#!/bin/sh\n' >"$NET_BIN"
printf '#!/bin/sh\n' >"$WALL_BIN"
chmod +x "$NET_BIN" "$WALL_BIN"
uid="$(id -u)"

start_services >/dev/null

expected_service_calls=(
    "brew services restart sketchybar"
    "brew services restart borders"
    "launchctl bootout gui/$uid/$NET_AGENT_LABEL"
    "launchctl bootstrap gui/$uid $NET_AGENT_PLIST"
    "launchctl kickstart gui/$uid/$NET_AGENT_LABEL"
    "launchctl bootout gui/$uid/$WALL_AGENT_LABEL"
    "launchctl bootstrap gui/$uid $WALL_AGENT_PLIST"
    "launchctl kickstart gui/$uid/$WALL_AGENT_LABEL"
    "pgrep -x AeroSpace"
    "osascript -e tell application \"AeroSpace\" to quit"
    "pgrep -x AeroSpace"
    "open -a AeroSpace"
    "aerospace list-modes"
)

[ "${calls[*]}" = "${expected_service_calls[*]}" ]

# The agent runs the built helper's feed and is a valid property list
plutil -lint "$NET_AGENT_PLIST" >/dev/null
[ "$(plutil -extract ProgramArguments.0 raw "$NET_AGENT_PLIST")" = "$NET_BIN" ]
[ "$(plutil -extract ProgramArguments.1 raw "$NET_AGENT_PLIST")" = "feed" ]

# The wallpaper agent runs `wallgen apply` hourly, in the background
plutil -lint "$WALL_AGENT_PLIST" >/dev/null
[ "$(plutil -extract ProgramArguments.0 raw "$WALL_AGENT_PLIST")" = "$WALL_BIN" ]
[ "$(plutil -extract ProgramArguments.1 raw "$WALL_AGENT_PLIST")" = "apply" ]
[ "$(plutil -extract StartInterval raw "$WALL_AGENT_PLIST")" = "3600" ]
[ "$(plutil -extract ProcessType raw "$WALL_AGENT_PLIST")" = "Background" ]

calls=()
stop_services >/dev/null
expected_stop_calls=(
    "brew services stop sketchybar"
    "brew services stop borders"
    "launchctl bootout gui/$uid/$NET_AGENT_LABEL"
    "launchctl bootout gui/$uid/$WALL_AGENT_LABEL"
)
[ "${calls[*]}" = "${expected_stop_calls[*]}" ]

# Restore brings back the restored configs' services, not this checkout's agents
calls=()
pgrep_calls=0
start_services --without-agents >/dev/null
expected_restore_calls=(
    "brew services restart sketchybar"
    "brew services restart borders"
    "pgrep -x AeroSpace"
    "osascript -e tell application \"AeroSpace\" to quit"
    "pgrep -x AeroSpace"
    "open -a AeroSpace"
    "aerospace list-modes"
)
[ "${calls[*]}" = "${expected_restore_calls[*]}" ]
grep -q 'start_services --without-agents' "$PROJECT_DIR/install.sh"

echo "PASS: install service contract"
