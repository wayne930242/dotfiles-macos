#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Input source switches post a distributed notification, so no polling is needed
sketchybar --add event input_change AppleSelectedInputSourcesChangedNotification \
           --add item input right \
           --set input \
                 icon="󰌌" \
                 icon.color=$PURPLE \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color="$PURPLE_BG" \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color=$PURPLE \
                 background.drawing=on \
                 script="$PLUGIN_DIR/input.sh" \
           --subscribe input input_change
