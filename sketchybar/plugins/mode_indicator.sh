#!/bin/bash

source "$CONFIG_DIR/colors.sh"

MODE="$MODE"

if [ "$MODE" = "service" ]; then
    # Service mode - show warning indicator and change bar color
    sketchybar --bar border_color=$RED \
               --set mode_indicator drawing=on label="SERVICE" icon.color=$RED label.color=$RED
else
    # Main mode - restore normal bar
    sketchybar --bar border_color=$BORDER_COLOR \
               --set mode_indicator drawing=off
fi
