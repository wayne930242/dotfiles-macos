#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# One osascript call returns "output volume, input volume, output muted"
IFS=',' read -r VOLUME MIC_VOLUME MUTED < <(osascript -e \
    'set s to (get volume settings)
     return ((output volume of s) as text) & "," & ((input volume of s) as text) & "," & ((output muted of s) as text)')

if [[ "$MIC_VOLUME" == "0" ]]; then
    MIC_ICON="󰍭"
    MIC_COLOR="$RED"
else
    MIC_ICON="󰍬"
    MIC_COLOR="$CYAN"
fi

if [[ "$VOLUME" == "missing value" || -z "$VOLUME" ]]; then
    VOL_ICON="󰖁"
    VOL_LABEL=""
elif [[ "$MUTED" == "true" || "$VOLUME" -eq 0 ]]; then
    VOL_ICON="󰖁"
    VOL_LABEL=""
elif [[ "$VOLUME" -lt 33 ]]; then
    VOL_ICON="󰕿"
    VOL_LABEL="${VOLUME}%"
elif [[ "$VOLUME" -lt 66 ]]; then
    VOL_ICON="󰖀"
    VOL_LABEL="${VOLUME}%"
else
    VOL_ICON="󰕾"
    VOL_LABEL="${VOLUME}%"
fi

sketchybar --set "$NAME" icon="$MIC_ICON $VOL_ICON" icon.color="$MIC_COLOR" label="$VOL_LABEL"
