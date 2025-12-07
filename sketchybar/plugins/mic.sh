#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

if [ "$MIC_VOLUME" -eq 0 ]; then
    ICON="󰍭"
    COLOR="$RED"
else
    ICON="󰍬"
    COLOR="$CYAN"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR"
