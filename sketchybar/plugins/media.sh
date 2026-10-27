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

# On the built-in display the pill grows right from the notch into the right items, which
# draw under it: the Claude pill at 1512 pt. plugins/notch.sh records the built-in display's
# range; label.max_chars is fitted to the room left of the leftmost right pill there, and the
# label scrolls through the rest. max_chars is shared by every display's bar.
MAX_CHARS=32
GAP=8
notch="$HOME/.cache/sketchybar/notch"
state="$HOME/.cache/sketchybar/media_chars"
if [[ ! -r "$notch" ]]; then
    sketchybar --set "$NAME" label.max_chars="$MAX_CHARS" label.drawing=on
    rm -f "$state"
    exit 0
fi
read -r _ min_x max_x <"$notch"

# Prints the built-in display's left and right edges of the given items, drawn ones only.
edges() {
    sketchybar --query "$1" | jq -r --argjson lo "$min_x" --argjson hi "$max_x" \
        '[.bounding_rects // {} | .[] | select(.origin[0] >= $lo and .origin[0] < $hi)]
         | if length == 0 then "" else "\(.[0].origin[0] | floor) \(.[0].origin[0] + .[0].size[0] | ceil)" end'
}

# Free space between the pill and the leftmost right pill; the queue order of right items
# runs claude, net, status_group from left to right.
room() {
    local item left right="" bound=""
    read -r _ right <<<"$(edges "$NAME")"
    for item in claude net status_group; do
        read -r left _ <<<"$(edges "$item")"
        if [[ -n "$left" ]]; then
            bound="$left"
            break
        fi
    done
    if [[ -z "$right" || -z "$bound" ]]; then
        echo 0
    else
        echo $((bound - GAP - right))
    fi
}

# A character of the 14 pt Hack Nerd Font Mono is 8.4 pt wide: grow by 9 pt a character so
# growing never overflows, shrink by 8 so the loop never drops more than needed. A query
# does not report label.max_chars, so the last value set is kept in a file.
set_chars() {
    sketchybar --set "$NAME" label.max_chars="$1" label.drawing=on
    echo "$1" >"$state"
}
chars="$(cat "$state" 2>/dev/null || true)"
[[ "$chars" =~ ^[0-9]+$ && "$chars" -gt 0 && "$chars" -le "$MAX_CHARS" ]] || chars="$MAX_CHARS"
[[ "$chars" -le ${#LABEL} ]] || chars=${#LABEL}
free="$(room)"
if [[ "$free" -ge 9 && "$chars" -lt "$MAX_CHARS" ]]; then
    chars=$((chars + free / 9))
    [[ "$chars" -le "$MAX_CHARS" ]] || chars="$MAX_CHARS"
    set_chars "$chars"
    free="$(room)"
fi
while [[ "$free" -lt 0 && "$chars" -gt 4 ]]; do
    chars=$((chars - (-free + 7) / 8))
    [[ "$chars" -ge 4 ]] || chars=4
    set_chars "$chars"
    free="$(room)"
done
# Too little room even for a few characters: keep only the play or pause icon
if [[ "$free" -lt 0 ]]; then
    sketchybar --set "$NAME" label.drawing=off
fi
