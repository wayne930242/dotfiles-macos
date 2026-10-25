#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"
# shellcheck disable=SC1091
source "$CONFIG_DIR/helpers/icon_map.sh"

# FOCUSED_WORKSPACE comes from exec-on-workspace-change; other triggers
# (focus changes, window moves, front_app_switched) omit it, so ask AeroSpace
focused="${FOCUSED_WORKSPACE:-}"
if [[ -z "$focused" ]]; then
    focused="$(aerospace list-workspaces --focused)"
fi

# One pass over the windows collects each workspace's app glyphs (sketchybar-app-font) into
# icons_<workspace>, one "|"-separated glyph per app. Workspace names are letters and digits,
# and indirect variables work in the system bash 3.2 too, which has no associative arrays.
while IFS='|' read -r ws app; do
    [[ -n "$ws" && -n "$app" ]] || continue
    __icon_map "$app"
    var="icons_$ws"
    # shellcheck disable=SC2154 # icon_result is set by __icon_map
    printf -v "$var" '%s' "${!var:-}${icon_result}|"
done < <(aerospace list-windows --all --format '%{workspace}|%{app-name}' | sort -u)

# The space items, from the list items/spaces.sh made them from (cheaper than a bar query)
spaces=()
while IFS= read -r sid; do
    spaces+=("space.$sid")
done < <(grep -m1 '^persistent-workspaces' "$HOME/.aerospace.toml" | grep -oE '"[^"]+"' | tr -d '"')

# render CAP: draws every workspace with at most CAP app glyphs each
render() {
    local cap="$1" item sid list icons n glyph args=()
    for item in "${spaces[@]}"; do
        sid="${item#space.}"
        list="icons_$sid"
        list="${!list:-}"
        icons="" n=0
        while [[ -n "$list" && "$n" -lt "$cap" ]]; do
            glyph="${list%%|*}"
            list="${list#*|}"
            icons+="$glyph"
            n=$((n + 1))
        done
        local label=(label="$icons" label.drawing="$([[ -n "$icons" ]] && echo on || echo off)")
        local occupied="icons_$sid"
        if [[ "$sid" == "$focused" ]]; then
            args+=(--set "$item" icon.color="$SPACE_ACTIVE" icon.highlight=on label.color="$SPACE_ACTIVE"
                   background.drawing=on background.color="$SPACE_BACKGROUND_ACTIVE" "${label[@]}")
        elif [[ -n "${!occupied:-}" ]]; then
            args+=(--set "$item" icon.color="$SPACE_OCCUPIED" icon.highlight=off label.color="$SPACE_OCCUPIED"
                   background.drawing=off "${label[@]}")
        else
            args+=(--set "$item" icon.color="$SPACE_INACTIVE" icon.highlight=off background.drawing=off "${label[@]}")
        fi
    done
    if [[ ${#args[@]} -gt 0 ]]; then
        sketchybar "${args[@]}"
    fi
}

# The notch hides what is drawn under it, and left items ignore it: plugins/notch.sh records
# where the built-in display's left side must end, and glyphs are dropped until it does.
# The right edge is read from the built-in display's bar only.
right_edge() {
    sketchybar --query spaces_pad_right | jq --argjson lo "$1" --argjson hi "$2" \
        '[.bounding_rects // {} | .[] | select(.origin[0] >= $lo and .origin[0] < $hi)
          | .origin[0] + .size[0]] | max // 0 | floor'
}

cap=3
render "$cap"
notch="$HOME/.cache/sketchybar/notch"
if [[ -r "$notch" ]]; then
    read -r limit min_x max_x <"$notch"
    while [[ "$cap" -gt 0 && "$(right_edge "$min_x" "$max_x")" -gt "$limit" ]]; do
        cap=$((cap - 1))
        render "$cap"
    done
fi
