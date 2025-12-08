#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

# Hide if volume is missing value
if [ "$VOLUME" = "missing value" ] || [ -z "$VOLUME" ]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
fi

sketchybar --set "$NAME" drawing=on

if [ "$MUTED" = "true" ] || [ "$VOLUME" -eq 0 ]; then
    ICON="󰖁"
    LABEL="Mute"
elif [ "$VOLUME" -lt 33 ]; then
    ICON="󰕿"
    LABEL="${VOLUME}%"
elif [ "$VOLUME" -lt 66 ]; then
    ICON="󰖀"
    LABEL="${VOLUME}%"
else
    ICON="󰕾"
    LABEL="${VOLUME}%"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
