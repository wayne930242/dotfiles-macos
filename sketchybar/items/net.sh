#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# The Straw Boss net: helpers/bin/net (built by install.sh) runs as a launchd agent and
# shows this pill while a Straw Boss GUI server runs and sets its icon, counts, and their
# colors; a click opens the net as a popup.
NET="$CONFIG_DIR/helpers/bin/net"

# padding_left=0: two items' paddings put 8 pt between them, while the status bracket ends
# 4 pt from its neighbours; dropping this side keeps the gap to the Claude pill the same.
sketchybar --add item net right \
           --set net \
                 padding_left=0 \
                 icon="󰚩" \
                 icon.color="$SPACE_INACTIVE" \
                 icon.padding_left=10 \
                 icon.padding_right=6 \
                 label.drawing=off \
                 drawing=off \
                 label.padding_left=0 \
                 label.padding_right=10 \
                 background.color="$PILL_BACKGROUND" \
                 background.corner_radius=8 \
                 background.height=32 \
                 background.border_width=1 \
                 background.border_color="$PILL_BORDER" \
                 background.drawing=on \
                 popup.align=right \
                 popup.y_offset=4 \
                 popup.height=24 \
                 script="$NET event" \
                 click_script="$NET toggle" \
           --subscribe net mouse.exited.global
