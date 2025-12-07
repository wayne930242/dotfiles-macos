#!/bin/bash

# Map app names to sketchybar-app-font icons
# See: https://github.com/kvndrsslr/sketchybar-app-font

if [ "$SENDER" = "front_app_switched" ]; then
    sketchybar --set "$NAME" label="$INFO" icon.background.image="app.$INFO"
fi
