#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item calendar right \
           --set calendar \
                 icon="󰃰" \
                 icon.color="$ICON_COLOR" \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color="$PILL_BACKGROUND" \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color="$PILL_BORDER" \
                 background.drawing=on \
                 update_freq=30 \
                 script="$PLUGIN_DIR/calendar.sh" \
                 click_script="open 'https://calendar.google.com'"
