#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get CPU usage
CPU=$(top -l 1 | grep -E "^CPU" | grep -Eo '[0-9]+\.[0-9]+%' | head -1 | cut -d'%' -f1)
if [ -z "$CPU" ]; then
    CPU=$(ps -A -o %cpu | awk '{s+=$1} END {print s}' | cut -d'.' -f1)
fi
CPU_INT=${CPU%.*}

# Get memory usage
PAGES_ACTIVE=$(vm_stat | grep 'Pages active' | awk '{print $3}' | tr -d '.')
PAGES_WIRED=$(vm_stat | grep 'Pages wired' | awk '{print $4}' | tr -d '.')
PAGES_COMPRESSED=$(vm_stat | grep 'Pages occupied by compressor' | awk '{print $5}' | tr -d '.')
USED=$((PAGES_ACTIVE + PAGES_WIRED + PAGES_COMPRESSED))

# Convert to GB (page size = 16384 on Apple Silicon)
PAGE_SIZE=16384
USED_GB=$(echo "scale=1; $USED * $PAGE_SIZE / 1073741824" | bc)

# Color based on CPU usage
if [ "$CPU_INT" -gt 80 ]; then
    COLOR=$RED
elif [ "$CPU_INT" -gt 50 ]; then
    COLOR=$ORANGE
else
    COLOR=$CYAN
fi

sketchybar --set "$NAME" label="${CPU_INT}% ${USED_GB}G" icon.color=$COLOR
