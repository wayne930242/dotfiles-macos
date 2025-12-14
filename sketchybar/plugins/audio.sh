#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get volume
VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

# Get mic
MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

# Mic icon
if [ "$MIC_VOLUME" -eq 0 ]; then
    MIC_ICON="󰍭"
    MIC_COLOR="$RED"
else
    MIC_ICON="󰍬"
    MIC_COLOR="$CYAN"
fi

# Volume icon and label
if [ "$VOLUME" = "missing value" ] || [ -z "$VOLUME" ]; then
    VOL_ICON="󰖁"
    VOL_LABEL=""
elif [ "$MUTED" = "true" ] || [ "$VOLUME" -eq 0 ]; then
    VOL_ICON="󰖁"
    VOL_LABEL=""
elif [ "$VOLUME" -lt 33 ]; then
    VOL_ICON="󰕿"
    VOL_LABEL="${VOLUME}%"
elif [ "$VOLUME" -lt 66 ]; then
    VOL_ICON="󰖀"
    VOL_LABEL="${VOLUME}%"
else
    VOL_ICON="󰕾"
    VOL_LABEL="${VOLUME}%"
fi

sketchybar --set "$NAME" icon="$MIC_ICON $VOL_ICON" icon.color="$MIC_COLOR" label="$VOL_LABEL"
