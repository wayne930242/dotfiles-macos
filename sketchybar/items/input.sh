#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# One of the status pill's members; items/status.sh draws their shared background

# Input source switches post a distributed notification, so no polling is needed
sketchybar --add event input_change AppleSelectedInputSourcesChangedNotification \
           --add item input right \
           --set input \
                 icon="󰌌" \
                 icon.color="$ICON_COLOR" \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.drawing=off \
                 click_script="$PLUGIN_DIR/status_toggle.sh" \
                 script="$PLUGIN_DIR/input.sh" \
           --subscribe input input_change
