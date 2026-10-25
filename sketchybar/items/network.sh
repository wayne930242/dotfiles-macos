#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Shown in the status pill's popup: it updates only while shown (updates=when_shown, the default),
# and status_popup refreshes it as the popup opens

sketchybar --add item network popup.status \
           --set network \
                 icon="󰖩" \
                 icon.color=$BLUE \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.drawing=off \
                 update_freq=120 \
                 script="$PLUGIN_DIR/network.sh" \
           --subscribe network wifi_change system_woke status_popup
