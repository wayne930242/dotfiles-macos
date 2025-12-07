#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get the workspace this item represents from the first argument
WORKSPACE_ID="$1"

# Use the passed FOCUSED_WORKSPACE from aerospace, or query if not available
if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
fi

# Check if this workspace has any windows
WINDOW_COUNT=$(aerospace list-windows --workspace "$WORKSPACE_ID" 2>/dev/null | wc -l | tr -d ' ')

if [ "$WORKSPACE_ID" = "$FOCUSED_WORKSPACE" ]; then
    # Currently focused workspace - bright cyan, show background
    sketchybar --set "$NAME" \
               icon.color=$SPACE_ACTIVE \
               icon.highlight=on \
               background.drawing=on \
               background.color=$SPACE_BACKGROUND_ACTIVE
elif [ "$WINDOW_COUNT" -gt 0 ]; then
    # Has windows but not focused - dimmer cyan
    sketchybar --set "$NAME" \
               icon.color=0xaa00fff7 \
               icon.highlight=off \
               background.drawing=off
else
    # Empty and not focused - very dim
    sketchybar --set "$NAME" \
               icon.color=$SPACE_INACTIVE \
               icon.highlight=off \
               background.drawing=off
fi
