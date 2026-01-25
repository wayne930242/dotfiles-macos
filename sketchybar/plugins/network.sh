#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Check WiFi power state
WIFI_POWER=$(networksetup -getairportpower en0 2>/dev/null | awk '{print $4}')

if [ "$WIFI_POWER" = "On" ]; then
    # Check if connected (has IP address)
    WIFI_IP=$(ipconfig getifaddr en0 2>/dev/null)
    if [ -n "$WIFI_IP" ]; then
        ICON="󰖩"
        LABEL="WiFi"
        COLOR=$BLUE
    else
        ICON="󰖪"
        LABEL="--"
        COLOR=$YELLOW
    fi
else
    # Check ethernet
    ETH_IP=$(ipconfig getifaddr en1 2>/dev/null || ipconfig getifaddr en2 2>/dev/null)
    if [ -n "$ETH_IP" ]; then
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
