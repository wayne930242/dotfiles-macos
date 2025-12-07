#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Get current WiFi SSID using system_profiler (more reliable on modern macOS)
SSID=$(system_profiler SPAirPortDataType 2>/dev/null | awk -F': ' '/Current Network Information:/{getline; gsub(/^[ \t]+/, ""); gsub(/:$/, ""); print; exit}')

if [ -n "$SSID" ]; then
    ICON="󰖩"
    # Truncate SSID if too long
    if [ ${#SSID} -gt 12 ]; then
        LABEL="${SSID:0:10}.."
    else
        LABEL="$SSID"
    fi
    COLOR=$BLUE
else
    # Check ethernet on common interfaces
    ETHERNET=$(ifconfig 2>/dev/null | grep -B4 'status: active' | grep -E '^en[0-9]+:' | head -1)
    if [ -n "$ETHERNET" ]; then
        ICON="󰈀"
        LABEL="ETH"
        COLOR=$BLUE
    else
        ICON="󰖪"
        LABEL="OFF"
        COLOR=$RED
    fi
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL" icon.color="${COLOR:-$BLUE}"
