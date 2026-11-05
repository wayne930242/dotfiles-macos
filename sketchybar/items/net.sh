#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# The agent pill, drawn by helpers/bin/net (built by install.sh): the active Claude Code account
# and its 7-day usage from ccswitch (github.com/wayne930242/cc-account-switcher, 1.3.0 or later
# for --json), with a coffee cup while caffeine keeps the Mac awake. Its script redraws it every
# 30 s and refreshes the usage every 5 minutes. A click opens the popup: the remote QR (while
# Tailscale is up), a message to the head tower, and the GUI while a Straw Boss GUI server runs;
# caffeine on or off and when the Mac sleeps; every Claude account, clicking one to switch to it.
NET="$CONFIG_DIR/helpers/bin/net"

# padding_left=0: two items' paddings put 8 pt between them, while the status bracket ends
# 4 pt from its neighbours; dropping this side keeps the gap the same.
sketchybar --add item net right \
           --set net \
                 padding_left=0 \
                 icon="󰚩" \
                 icon.color="$SPACE_INACTIVE" \
                 update_freq=30 \
                 updates=on \
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
           --subscribe net system_woke mouse.exited.global
