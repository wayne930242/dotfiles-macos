#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item calendar right \
           --set calendar \
                 icon="󰃰" \
                 icon.color=$CYAN \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color=0x3300fff7 \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color=$CYAN \
                 background.drawing=on \
                 update_freq=30 \
                 script="$PLUGIN_DIR/calendar.sh"
