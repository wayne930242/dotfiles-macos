#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item battery right \
           --set battery \
                 icon.color=$GREEN \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color=0x3300ff66 \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color=$GREEN \
                 background.drawing=on \
                 update_freq=120 \
                 script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery system_woke power_source_change
