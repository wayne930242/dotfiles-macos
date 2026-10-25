#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# One of the status pill's members; items/status.sh draws their shared background

# Combined audio item (mic + volume in one block)
sketchybar --add item audio right \
           --set audio \
                 icon="󰍬 󰕾" \
                 icon.color="$ICON_COLOR" \
                 icon.padding_left=8 \
                 icon.padding_right=4 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.drawing=off \
                 script="$PLUGIN_DIR/audio.sh" \
                 click_script="$PLUGIN_DIR/mic_click.sh" \
           --subscribe audio volume_change
