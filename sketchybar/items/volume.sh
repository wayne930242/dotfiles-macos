#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Combined audio item (mic + volume in one block)
sketchybar --add item audio right \
           --set audio \
                 icon="󰍬 󰕾" \
                 icon.color="$CYAN" \
                 icon.padding_left=8 \
                 icon.padding_right=4 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color=0x3300fff7 \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color="$CYAN" \
                 background.drawing=on \
                 script="$PLUGIN_DIR/audio.sh" \
                 click_script="$PLUGIN_DIR/mic_click.sh" \
           --subscribe audio volume_change
