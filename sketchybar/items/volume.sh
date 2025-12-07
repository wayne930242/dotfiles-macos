#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

sketchybar --add item volume right \
           --set volume \
                 icon="󰕾" \
                 icon.color="$CYAN" \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color=0x3300fff7 \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color="$CYAN" \
                 background.drawing=on \
                 script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume volume_change \
           --add item mic right \
           --set mic \
                 icon="󰍬" \
                 icon.color="$CYAN" \
                 icon.padding_left=4 \
                 icon.padding_right=4 \
                 label.drawing=off \
                 background.drawing=off \
                 script="$PLUGIN_DIR/mic.sh" \
                 click_script="$PLUGIN_DIR/mic_click.sh" \
           --subscribe mic volume_change
