#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get disk usage for root volume
DISK_INFO=$(df -H / | tail -1)
USED=$(echo "$DISK_INFO" | awk '{print $3}' | tr -d 'G')
AVAIL=$(echo "$DISK_INFO" | awk '{print $4}' | tr -d 'G')
PERCENT=$(echo "$DISK_INFO" | awk '{print $5}' | tr -d '%')

# Color based on usage
if [ "$PERCENT" -gt 90 ]; then
    COLOR=$RED
elif [ "$PERCENT" -gt 75 ]; then
    COLOR=$ORANGE
else
    COLOR=$BLUE
fi

sketchybar --set "$NAME" label="${AVAIL}B" icon.color=$COLOR
