#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Claude Code accounts from ccswitch (github.com/wayne930242/cc-account-switcher): the active
# account and its 5-hour usage, refreshed every 5 minutes like ccswitch's own dashboard. A click
# lists every account's usage; clicking one switches to it. Hidden while no ccswitch with --json
# is installed.
sketchybar --add item claude right \
           --set claude \
                 icon="󰧑" \
                 icon.color="$ICON_COLOR" \
                 icon.padding_left=10 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=10 \
                 drawing=off \
                 background.color="$PILL_BACKGROUND" \
                 background.corner_radius=8 \
                 background.height=32 \
                 background.border_width=1 \
                 background.border_color="$PILL_BORDER" \
                 background.drawing=on \
                 popup.align=right \
                 popup.y_offset=4 \
                 popup.height=24 \
                 update_freq=300 \
                 updates=on \
                 script="$PLUGIN_DIR/claude.sh" \
                 click_script="$PLUGIN_DIR/claude.sh toggle" \
           --subscribe claude system_woke mouse.exited.global
