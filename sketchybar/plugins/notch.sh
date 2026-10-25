#!/usr/bin/env bash

set -euo pipefail

# Keeps notch_width equal to the measured notch and records where the left side must end
# for plugins/aerospace.sh; runs at load (sketchybar --update) and on display_change, which
# a scaling change or a monitor plugged in also posts.
CACHE="$HOME/.cache/sketchybar/notch"
mkdir -p "$(dirname "$CACHE")"

read -r width limit min_x max_x <<<"$("$CONFIG_DIR/helpers/notch.sh")" || true
if [[ -n "${width:-}" ]]; then
    sketchybar --bar notch_width="$width"
    echo "$limit $min_x $max_x" >"$CACHE"
else
    rm -f "$CACHE"
fi
sketchybar --trigger aerospace_workspace_change
