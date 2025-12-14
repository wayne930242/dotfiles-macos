#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add event aerospace_mode_change \
           --add item mode_indicator left \
           --set mode_indicator \
                 icon="󰀦" \
                 icon.color=$RED \
                 icon.padding_left=8 \
                 icon.padding_right=4 \
                 label="SERVICE" \
                 label.color=$RED \
                 label.padding_right=8 \
                 background.color=0x33ff0055 \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color=$RED \
                 background.drawing=on \
                 drawing=off \
                 script="$PLUGIN_DIR/mode_indicator.sh" \
           --subscribe mode_indicator aerospace_mode_change
