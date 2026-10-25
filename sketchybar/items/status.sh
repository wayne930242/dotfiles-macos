#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# The status pill: audio, battery, and input share one background, and this anchor's popup
# holds what is rarely needed at a glance (CPU and memory, temperature, network).
# Source it after its members and before the items that live in its popup.
# The gear takes its color from CPU use every 5 s: lavender, then yellow at 30%, peach at 60%,
# red at 85% (plugins/status.sh).
sketchybar --add event status_popup \
           --add item status right \
           --set status \
                 icon="󰒓" \
                 icon.color="$ICON_COLOR" \
                 icon.padding_left=10 \
                 icon.padding_right=2 \
                 label.drawing=off \
                 background.drawing=off \
                 popup.align=right \
                 popup.y_offset=4 \
                 click_script="$PLUGIN_DIR/status_toggle.sh" \
                 update_freq=5 \
                 updates=on \
                 script="$PLUGIN_DIR/status.sh" \
           --subscribe status mouse.exited.global

sketchybar --add bracket status_group status audio battery input \
           --set status_group \
                 background.color="$PILL_BACKGROUND" \
                 background.corner_radius=8 \
                 background.height=32 \
                 background.border_width=1 \
                 background.border_color="$PILL_BORDER" \
                 background.drawing=on
