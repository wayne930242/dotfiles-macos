#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Official AeroSpace + Sketchybar integration pattern
# $1 = workspace ID this item represents
# $FOCUSED_WORKSPACE = passed from aerospace via trigger

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    # Currently focused workspace
    sketchybar --set "$NAME" \
               icon.color=$SPACE_ACTIVE \
               icon.highlight=on \
               background.drawing=on \
               background.color=$SPACE_BACKGROUND_ACTIVE
else
    # Check if this workspace has any windows
    WINDOW_COUNT=$(aerospace list-windows --workspace "$1" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$WINDOW_COUNT" -gt 0 ]; then
        # Has windows but not focused
        sketchybar --set "$NAME" \
                   icon.color=0xaa00fff7 \
                   icon.highlight=off \
                   background.drawing=off
    else
        # Empty and not focused
        sketchybar --set "$NAME" \
                   icon.color=$SPACE_INACTIVE \
                   icon.highlight=off \
                   background.drawing=off
    fi
fi
