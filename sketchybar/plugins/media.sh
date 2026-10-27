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
# label scrolls through the rest. max_chars and the padding are shared by every display's bar.
MAX_CHARS=32
PAD=8
# The right pills' items stand 4 pt apart (items/net.sh), so the pill's item ends 4 pt short.
GAP=4
notch="$HOME/.cache/sketchybar/notch"
state="$HOME/.cache/sketchybar/media_fit"
if [[ ! -r "$notch" ]]; then
    sketchybar --set "$NAME" label.max_chars="$MAX_CHARS" label.padding_right="$PAD" label.drawing=on
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

# The left edge of the leftmost right pill; right items queue claude, net, status_group from
# left to right.
bound() {
    local item left
    for item in claude net status_group; do
        read -r left _ <<<"$(edges "$item")"
        if [[ -n "$left" ]]; then
            echo "$left"
            return
        fi
    done
}

# Room left between the pill and that bound.
room() {
    local right
    read -r _ right <<<"$(edges "$NAME")"
    echo $((limit - GAP - ${right:-$limit}))
}

limit="$(bound)"
if [[ -z "$limit" ]]; then
    exit 0
fi
# A fit holds until the label, the bound, or the SketchyBar process changes; refitting on
# every update would redraw the pill every 5 s.
key="$(pgrep -x sketchybar | head -1) $limit $LABEL"
if [[ "$(head -1 "$state" 2>/dev/null)" == "$key" ]]; then
    exit 0
fi

# Start from the full label and drop characters until the pill fits. Character widths vary (a
# trailing space counts for nothing), so the count comes from measuring; each step drops at
# least one character, never more than the overflow's worth at 8 pt a character.
chars="$MAX_CHARS"
[[ "$chars" -le ${#LABEL} ]] || chars=${#LABEL}
sketchybar --set "$NAME" label.max_chars="$MAX_CHARS" label.padding_right="$PAD" label.drawing=on
free="$(room)"
while [[ "$free" -lt 0 && "$chars" -gt 4 ]]; do
    chars=$((chars - (-free + 7) / 8))
    [[ "$chars" -ge 4 ]] || chars=4
    sketchybar --set "$NAME" label.max_chars="$chars"
    free="$(room)"
done
if [[ "$free" -lt 0 ]]; then
    # Too little room even for a few characters: keep only the play or pause icon
    sketchybar --set "$NAME" label.drawing=off
elif [[ "$chars" -lt ${#LABEL} ]]; then
    # A cut label scrolls; its padding takes up the rest so the gap matches the right pills'
    sketchybar --set "$NAME" label.padding_right="$((PAD + free))"
fi
printf '%s\n' "$key" >"$state"
