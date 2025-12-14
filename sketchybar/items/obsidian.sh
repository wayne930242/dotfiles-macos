#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item obsidian right \
           --set obsidian \
                 icon="󱓧" \
                 icon.color=$PURPLE \
                 icon.padding_left=8 \
                 icon.padding_right=8 \
                 label.drawing=off \
                 background.color=0x33aa00ff \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color=$PURPLE \
                 background.drawing=on \
                 click_script="open -a 'Obsidian'"
