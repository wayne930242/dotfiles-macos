#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Get media info from Now Playing (works with Spotify, Music, browsers, etc.)
TITLE=$(nowplaying-cli get title 2>/dev/null)
ARTIST=$(nowplaying-cli get artist 2>/dev/null)
STATE=$(nowplaying-cli get playbackRate 2>/dev/null)

# Check if media is actually playing
if [ -n "$TITLE" ] && [ "$TITLE" != "null" ] && [ "$TITLE" != "" ]; then
    if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ] && [ "$ARTIST" != "" ]; then
        LABEL="$ARTIST - $TITLE"
    else
        LABEL="$TITLE"
    fi

    # Truncate if too long
    if [ ${#LABEL} -gt 40 ]; then
        LABEL="${LABEL:0:37}..."
    fi

    # Check if playing or paused
    if [ "$STATE" = "1" ]; then
        ICON="󰎆"
    else
        ICON="󰏤"
    fi
    DRAWING="on"
else
    LABEL=""
    ICON=""
    DRAWING="off"
fi

sketchybar --set "$NAME" label="$LABEL" icon="$ICON" drawing="$DRAWING"
