#!/bin/bash

source "$CONFIG_DIR/colors.sh"

TEMP_TOOL="$CONFIG_DIR/plugins/macos-temp-tool"

# Get max CPU die temperature
TEMP=$("$TEMP_TOOL" -f "PMU tdie" -m 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)

if [ -z "$TEMP" ]; then
    # Fallback to thermal pressure
    PRESSURE=$("$TEMP_TOOL" -p 2>/dev/null | awk '{print $3}')
    sketchybar --set "$NAME" label="$PRESSURE" icon.color=$CYAN
    exit 0
fi

TEMP_INT=${TEMP%.*}

# Color based on temperature
if [ "$TEMP_INT" -gt 80 ]; then
    COLOR=$RED
elif [ "$TEMP_INT" -gt 60 ]; then
    COLOR=$ORANGE
else
    COLOR=$CYAN
fi

sketchybar --set "$NAME" label="${TEMP_INT}°" icon.color=$COLOR
