#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Triggered by AeroSpace on-mode-changed, which passes no mode, so ask AeroSpace
MODE="$(aerospace list-modes --current)"

if [[ "$MODE" == "service" ]]; then
    sketchybar --set "$NAME" drawing=on label="SERVICE" icon.color="$RED" label.color="$RED"
else
    sketchybar --set "$NAME" drawing=off
fi
