#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item front_app left \
           --set front_app \
                 icon.drawing=off \
                 label.color=$LABEL_COLOR \
                 label.font="Hack Nerd Font Mono:Bold:13.0" \
                 label.padding_left=12 \
                 label.padding_right=12 \
                 background.color=0x33ff00ff \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color=$MAGENTA \
                 background.drawing=on \
                 script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched
