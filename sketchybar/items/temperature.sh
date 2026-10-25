#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Shown in the status pill's popup: it updates only while shown (updates=when_shown, the default),
# and status_popup refreshes it as the popup opens

sketchybar --add item temperature popup.status \
           --set temperature \
                 icon="󰔏" \
                 icon.color=$CYAN \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.drawing=off \
                 update_freq=10 \
                 script="$PLUGIN_DIR/temperature.sh" \
           --subscribe temperature status_popup
