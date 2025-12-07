#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get memory usage using vm_stat
PAGES_FREE=$(vm_stat | grep 'Pages free' | awk '{print $3}' | tr -d '.')
PAGES_INACTIVE=$(vm_stat | grep 'Pages inactive' | awk '{print $3}' | tr -d '.')
PAGES_ACTIVE=$(vm_stat | grep 'Pages active' | awk '{print $3}' | tr -d '.')
PAGES_SPECULATIVE=$(vm_stat | grep 'Pages speculative' | awk '{print $3}' | tr -d '.')
PAGES_WIRED=$(vm_stat | grep 'Pages wired' | awk '{print $4}' | tr -d '.')
PAGES_COMPRESSED=$(vm_stat | grep 'Pages occupied by compressor' | awk '{print $5}' | tr -d '.')

# Calculate used memory (in pages, 1 page = 16384 bytes on Apple Silicon)
USED=$((PAGES_ACTIVE + PAGES_WIRED + PAGES_COMPRESSED))
TOTAL=$((USED + PAGES_FREE + PAGES_INACTIVE + PAGES_SPECULATIVE))

# Convert to percentage
if [ "$TOTAL" -gt 0 ]; then
    PERCENTAGE=$((USED * 100 / TOTAL))
else
    PERCENTAGE=0
fi

# Convert to GB for display
PAGE_SIZE=16384
USED_GB=$(echo "scale=1; $USED * $PAGE_SIZE / 1073741824" | bc)

# Color based on usage
if [ "$PERCENTAGE" -gt 80 ]; then
    COLOR=$RED
elif [ "$PERCENTAGE" -gt 60 ]; then
    COLOR=$ORANGE
else
    COLOR=$MAGENTA
fi

sketchybar --set "$NAME" label="${USED_GB}G" icon.color=$COLOR
