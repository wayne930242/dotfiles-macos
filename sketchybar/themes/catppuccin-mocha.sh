#!/usr/bin/env bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                     CATPPUCCIN MOCHA COLOR SCHEME                         ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
# Palette: https://catppuccin.com/palette (Mocha). Format: 0xAARRGGBB

# Mocha palette
MOCHA_PINK=f5c2e7
MOCHA_MAUVE=cba6f7
MOCHA_RED=f38ba8
MOCHA_PEACH=fab387
MOCHA_YELLOW=f9e2af
MOCHA_GREEN=a6e3a1
MOCHA_SKY=89dceb
MOCHA_BLUE=89b4fa
MOCHA_LAVENDER=b4befe
MOCHA_TEXT=cdd6f4
MOCHA_SUBTEXT0=a6adc8
MOCHA_OVERLAY0=6c7086
MOCHA_SURFACE1=45475a
MOCHA_SURFACE0=313244
MOCHA_BASE=1e1e2e
MOCHA_MANTLE=181825

export TRANSPARENT=0x00000000

# Bar and popup
export BAR_COLOR=0xe6$MOCHA_BASE
export BORDER_COLOR=0xff$MOCHA_SURFACE1
export POPUP_BACKGROUND_COLOR=0xf0$MOCHA_MANTLE
export POPUP_BORDER_COLOR=0xff$MOCHA_MAUVE

# Text
export ICON_COLOR=0xff$MOCHA_LAVENDER
export LABEL_COLOR=0xff$MOCHA_TEXT

# Accent slots (item icons and borders); slot names come from the archived
# cyberpunk theme, each mapped to the nearest Mocha accent
export CYAN=0xff$MOCHA_SKY
export MAGENTA=0xff$MOCHA_PINK
export YELLOW=0xff$MOCHA_YELLOW
export GREEN=0xff$MOCHA_GREEN
export RED=0xff$MOCHA_RED
export ORANGE=0xff$MOCHA_PEACH
export BLUE=0xff$MOCHA_BLUE
export PURPLE=0xff$MOCHA_MAUVE

# Item backgrounds: Mocha uses one surface for every pill; the accent border
# and icon carry the item's identity
export CYAN_BG=0xcc$MOCHA_SURFACE0
export MAGENTA_BG=0xcc$MOCHA_SURFACE0
export YELLOW_BG=0xcc$MOCHA_SURFACE0
export GREEN_BG=0xcc$MOCHA_SURFACE0
export RED_BG=0xcc$MOCHA_SURFACE0
export BLUE_BG=0xcc$MOCHA_SURFACE0
export PURPLE_BG=0xcc$MOCHA_SURFACE0

# Workspaces
export SPACE_ACTIVE=0xff$MOCHA_BASE
export SPACE_OCCUPIED=0xff$MOCHA_SUBTEXT0
export SPACE_INACTIVE=0xff$MOCHA_OVERLAY0
export SPACE_BACKGROUND=0x00$MOCHA_BASE
export SPACE_BACKGROUND_ACTIVE=0xff$MOCHA_MAUVE
