#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

sketchybar --add item media right \
           --set media \
                 icon="󰎆" \
                 icon.color="$YELLOW" \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 label.max_chars=40 \
                 background.color=0x33ffff00 \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color="$YELLOW" \
                 background.drawing=on \
                 scroll_texts=on \
                 drawing=off \
                 update_freq=3 \
                 script="$PLUGIN_DIR/media.sh" \
           --subscribe media media_change
