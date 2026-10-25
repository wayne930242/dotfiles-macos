#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Shown in the status pill's popup: it updates only while shown (updates=when_shown, the default),
# and status_popup refreshes it as the popup opens

sketchybar --add item system_stats popup.status \
           --set system_stats \
                 icon="󰻠" \
                 icon.color=$CYAN \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.drawing=off \
                 update_freq=5 \
                 script="$PLUGIN_DIR/system_stats.sh" \
                 click_script="open -a 'Activity Monitor'" \
           --subscribe system_stats status_popup
