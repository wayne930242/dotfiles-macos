#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# FOCUSED_WORKSPACE comes from exec-on-workspace-change; other triggers
# (focus changes, window moves, front_app_switched) omit it, so ask AeroSpace
focused="${FOCUSED_WORKSPACE:-}"
if [[ -z "$focused" ]]; then
    focused="$(aerospace list-workspaces --focused)"
fi

occupied=" $(aerospace list-windows --all --format '%{workspace}' | sort -u | tr '\n' ' ') "

args=()
while IFS= read -r item; do
    sid="${item#space.}"
    if [[ "$sid" == "$focused" ]]; then
        args+=(--set "$item" icon.color="$SPACE_ACTIVE" icon.highlight=on
               background.drawing=on background.color="$SPACE_BACKGROUND_ACTIVE")
    elif [[ "$occupied" == *" $sid "* ]]; then
        args+=(--set "$item" icon.color=0xaa00fff7 icon.highlight=off background.drawing=off)
    else
        args+=(--set "$item" icon.color="$SPACE_INACTIVE" icon.highlight=off background.drawing=off)
    fi
done < <(sketchybar --query bar | jq -r '.items[] | select(startswith("space."))')

if [[ ${#args[@]} -gt 0 ]]; then
    sketchybar "${args[@]}"
fi
