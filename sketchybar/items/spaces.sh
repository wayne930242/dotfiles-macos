#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

WORKSPACES=("1" "2" "3" "T" "W" "G" "S" "P" "D" "A" "Z" "X")

# Add custom event for aerospace
sketchybar --add event aerospace_workspace_change

for sid in "${WORKSPACES[@]}"; do
    sketchybar --add item "space.$sid" left \
               --subscribe "space.$sid" aerospace_workspace_change \
               --set "space.$sid" \
                     icon="$sid" \
                     icon.font="Hack Nerd Font Mono:Bold:14.0" \
                     icon.color="$SPACE_INACTIVE" \
                     icon.padding_left=8 \
                     icon.padding_right=8 \
                     background.color="$SPACE_BACKGROUND" \
                     background.corner_radius=6 \
                     background.height=26 \
                     background.drawing=off \
                     label.drawing=off \
                     click_script="aerospace workspace $sid" \
                     script="$PLUGIN_DIR/aerospace.sh $sid"
done

# Trigger initial update
sketchybar --trigger aerospace_workspace_change
