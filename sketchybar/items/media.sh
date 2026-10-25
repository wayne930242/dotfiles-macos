#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# At e, right of the notch, so a long title grows away from the notch

sketchybar --add item media e \
           --set media \
                 icon="󰎆" \
                 icon.color="$ICON_COLOR" \
                 icon.padding_left=8 \
                 icon.padding_right=6 \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 label.max_chars=32 \
                 background.color="$PILL_BACKGROUND" \
                 background.corner_radius=8 \
                 background.height=28 \
                 background.border_width=1 \
                 background.border_color="$PILL_BORDER" \
                 background.drawing=on \
                 scroll_texts=on \
                 drawing=off \
                 update_freq=5 \
                 script="$PLUGIN_DIR/media.sh"
