#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# persistent-workspaces in the AeroSpace config is the single source of the workspace list
AEROSPACE_CONFIG="$HOME/.aerospace.toml"
WORKSPACES=()
while IFS= read -r sid; do
    WORKSPACES+=("$sid")
done < <(grep -m1 '^persistent-workspaces' "$AEROSPACE_CONFIG" | grep -oE '"[^"]+"' | tr -d '"')

if [[ ${#WORKSPACES[@]} -eq 0 ]]; then
    echo "spaces.sh: no persistent-workspaces found in $AEROSPACE_CONFIG" >&2
fi

sketchybar --add event aerospace_workspace_change

for sid in "${WORKSPACES[@]}"; do
    sketchybar --add item "space.$sid" left \
               --set "space.$sid" \
                     icon="$sid" \
                     icon.font="Hack Nerd Font Mono:Bold:14.0" \
                     icon.color="$SPACE_INACTIVE" \
                     icon.highlight_color="$SPACE_ACTIVE" \
                     icon.padding_left=8 \
                     icon.padding_right=8 \
                     background.color="$SPACE_BACKGROUND" \
                     background.corner_radius=6 \
                     background.height=26 \
                     background.drawing=off \
                     label.drawing=off \
                     click_script="aerospace workspace $sid"
done

# One hidden controller refreshes every space item per event, so an event costs
# two aerospace queries instead of one query per workspace
sketchybar --add item spaces_controller left \
           --set spaces_controller \
                 drawing=off \
                 updates=on \
                 script="$PLUGIN_DIR/aerospace.sh" \
           --subscribe spaces_controller aerospace_workspace_change front_app_switched space_windows_change system_woke

sketchybar --trigger aerospace_workspace_change
