#!/bin/bash

source "$CONFIG_DIR/colors.sh"

CPU=$(top -l 1 | grep -E "^CPU" | grep -Eo '[0-9]+\.[0-9]+%' | head -1 | cut -d'%' -f1)

# Fallback if top doesn't work well
if [ -z "$CPU" ]; then
    CPU=$(ps -A -o %cpu | awk '{s+=$1} END {print s}' | cut -d'.' -f1)
fi

# Color based on usage
if [ "${CPU%.*}" -gt 80 ]; then
    COLOR=$RED
elif [ "${CPU%.*}" -gt 50 ]; then
    COLOR=$ORANGE
else
    COLOR=$CYAN
fi

sketchybar --set "$NAME" label="${CPU}%" icon.color=$COLOR
