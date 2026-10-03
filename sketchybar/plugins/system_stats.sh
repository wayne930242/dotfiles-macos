#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# CPU: iostat's second sample covers the last second; the first sample (like
# top -l 1) is an average since boot. iostat skips the process scan that makes
# top cost about 0.5s of kernel time per run.
CPU_IDLE="$(iostat -n 0 -c 2 -w 1 | tail -1 | awk '{print $3}')"
CPU_INT=$((100 - CPU_IDLE))

# Memory: one vm_stat run; used = active + wired + compressed
read -r PAGE_SIZE USED < <(vm_stat | awk '
    /page size of/                 { size = $8 }
    /^Pages active/                { gsub(/\./, "", $3); used += $3 }
    /^Pages wired/                 { gsub(/\./, "", $4); used += $4 }
    /^Pages occupied by compressor/ { gsub(/\./, "", $5); used += $5 }
    END { print size, used }')
USED_GB="$(awk -v u="$USED" -v s="$PAGE_SIZE" 'BEGIN { printf "%.1f", u * s / 1073741824 }')"

if [[ "$CPU_INT" -gt 80 ]]; then
    COLOR="$RED"
elif [[ "$CPU_INT" -gt 50 ]]; then
    COLOR="$ORANGE"
else
    COLOR="$CYAN"
fi

sketchybar --set "$NAME" label="${CPU_INT}% ${USED_GB}G" icon.color="$COLOR"
