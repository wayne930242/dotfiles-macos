#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item network right \
           --set network \
                 icon="󰖩" \
                 icon.color=$BLUE \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color=0x330099ff \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color=$BLUE \
                 background.drawing=on \
                 update_freq=5 \
                 script="$PLUGIN_DIR/network.sh"
