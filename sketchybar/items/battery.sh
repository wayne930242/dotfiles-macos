#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# One of the status pill's members; items/status.sh draws their shared background

sketchybar --add item battery right \
           --set battery \
                 icon.color="$ICON_COLOR" \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.drawing=off \
                 click_script="$PLUGIN_DIR/status_toggle.sh" \
                 update_freq=120 \
                 script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery system_woke power_source_change
