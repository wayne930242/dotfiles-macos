#!/usr/bin/env bash

set -euo pipefail

# media-control reads Now Playing through a workaround that still works on
# macOS 15.4+, where nowplaying-cli only returns null. It prints "null" when
# nothing is playing.
INFO="$(media-control get 2>/dev/null || echo null)"

TITLE="$(jq -r '.title // empty' <<<"$INFO" 2>/dev/null || true)"

if [[ -z "$TITLE" ]]; then
    sketchybar --set "$NAME" label="" icon="" drawing=off
    exit 0
fi

ARTIST="$(jq -r '.artist // empty' <<<"$INFO")"
PLAYING="$(jq -r '.playing // false' <<<"$INFO")"

if [[ -n "$ARTIST" ]]; then
    LABEL="$ARTIST - $TITLE"
else
    LABEL="$TITLE"
fi

if [[ ${#LABEL} -gt 40 ]]; then
    LABEL="${LABEL:0:37}..."
fi

if [[ "$PLAYING" == "true" ]]; then
    ICON="󰎆"
else
    ICON="󰏤"
fi

sketchybar --set "$NAME" label="$LABEL" icon="$ICON" drawing=on
