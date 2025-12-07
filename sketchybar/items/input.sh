#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item input right \
           --set input \
                 icon="󰌌" \
                 icon.color=$PURPLE \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color=0x33aa00ff \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color=$PURPLE \
                 background.drawing=on \
                 update_freq=3 \
                 script="$PLUGIN_DIR/input.sh"
