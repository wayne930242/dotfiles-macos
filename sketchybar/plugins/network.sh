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
        RSSI=$(system_profiler SPAirPortDataType 2>/dev/null | sed -n 's/.*Signal \/ Noise: \(-\{0,1\}[0-9]\{1,\}\) dBm.*/\1/p' | head -1)
        if [ -n "$RSSI" ]; then
            # RSSI (dBm) is log-scale; grade by standard signal-quality tiers
            # rather than a misleading linear percentage.
            if [ "$RSSI" -ge -50 ]; then
                LABEL="S"; COLOR=$GREEN
            elif [ "$RSSI" -ge -60 ]; then
                LABEL="A"; COLOR=$GREEN
            elif [ "$RSSI" -ge -70 ]; then
                LABEL="B"; COLOR=$BLUE
            elif [ "$RSSI" -ge -80 ]; then
                LABEL="C"; COLOR=$ORANGE
            else
                LABEL="N"; COLOR=$RED
            fi
        else
            LABEL="已連線"
            COLOR=$BLUE
        fi
    else
        ICON="󰖪"
        LABEL="未連線"
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
