#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

sketchybar --add item git left \
           --set git \
                 icon="󰊢" \
                 icon.color="$MAGENTA" \
                 icon.padding_left=12 \
                 icon.padding_right=6 \
                 label="" \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color=0x33ff00ff \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color="$MAGENTA" \
                 background.drawing=on \
                 drawing=off \
                 update_freq=5 \
                 script="$PLUGIN_DIR/git.sh"
