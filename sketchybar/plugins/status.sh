#!/usr/bin/env bash

# The status pill's gear: its color follows CPU use, and leaving the bar closes the popup.

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "mouse.exited.global" ]; then
    sketchybar --set status popup.drawing=off
    exit 0
fi

# iostat's second sample covers the last second (the first is an average since boot); it sleeps
# through that second instead of scanning processes as top does
idle="$(iostat -n 0 -c 2 -w 1 | tail -1 | awk '{print $3}')"
case "$idle" in
    '' | *[!0-9]*) exit 0 ;;
esac
cpu=$((100 - idle))

if [ "$cpu" -ge 85 ]; then
    color="$RED"
elif [ "$cpu" -ge 60 ]; then
    color="$ORANGE"
elif [ "$cpu" -ge 30 ]; then
    color="$YELLOW"
else
    color="$ICON_COLOR"
fi

sketchybar --set status icon.color="$color"
