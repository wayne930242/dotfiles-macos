#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

sketchybar --add item weather right \
           --set weather \
                 icon="󰖐" \
                 icon.color="$ORANGE" \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label="--°C" \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.color=0x33ff6600 \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color="$ORANGE" \
                 background.drawing=on \
                 update_freq=1800 \
                 script="$PLUGIN_DIR/weather.sh"
