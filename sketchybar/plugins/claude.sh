#!/usr/bin/env bash

# The Claude pill (items/claude.sh):
#	claude.sh               refresh: ccswitch --json into the cache, then redraw the pill
#	claude.sh toggle        open the popup from the cache, or close it
#	claude.sh switch N      switch to account N, then refresh
#	claude.sh dashboard     open ccswitch's dashboard in Herdr
# Only the refresh touches the network; the popup draws from the cache.

set -uo pipefail
# ${#s} counts characters, not bytes, only under a UTF-8 locale; launchd gives none
export LC_ALL=en_US.UTF-8

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# SketchyBar runs from launchd with a bare PATH: ccswitch needs Homebrew's bash 4+ and jq
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/bin:$PATH"

# SketchyBar passes CONFIG_DIR but not sketchybarrc's PLUGIN_DIR to click scripts
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
CACHE="$HOME/.cache/sketchybar/claude.json"
WARN=60
HOT=85

find_ccswitch() {
    local c
    for c in "${CCSWITCH_BIN:-}" "$(command -v ccswitch 2>/dev/null)" "$HOME/.local/bin/ccswitch" "$HOME/bin/ccswitch" "$HOME/bin/ccswitch.sh"; do
        [ -n "$c" ] && [ -x "$c" ] && { echo "$c"; return 0; }
    done
    return 1
}

# Usage colors: plain, then yellow from 60%, red from 85%
tone() {
    if [ "$1" -ge "$HOT" ]; then echo "$RED"; elif [ "$1" -ge "$WARN" ]; then echo "$YELLOW"; else echo "$ICON_COLOR"; fi
}

refresh() {
    local cc json
    # A ccswitch older than --json (1.3.0) can't feed the pill
    if ! cc="$(find_ccswitch)" || ! "$cc" --help 2>/dev/null | grep -q -- '--json'; then
        sketchybar --set claude drawing=off
        return
    fi
    if json="$("$cc" --json 2>/dev/null)" && jq -e 'type == "array"' >/dev/null 2>&1 <<<"$json"; then
        mkdir -p "$(dirname "$CACHE")"
        (umask 077 && printf '%s\n' "$json" >"$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE")
    fi
    draw_pill
}

draw_pill() {
    local num five seven bad color label
    [ -f "$CACHE" ] || { sketchybar --set claude drawing=off; return; }
    read -r num five seven bad < <(jq -r '
        (map(select(.active)) | .[0]) as $a
        | if $a == null then "- 0 0 1"
          else "\($a.num) \($a.usage.five_hour.utilization // 0 | floor) \($a.usage.seven_day.utilization // 0 | floor) \(if $a.error != null or ($a.token_state | test("dead|unknown|missing")) then 1 else 0 end)"
          end' "$CACHE")
    if [ "$bad" = 1 ]; then
        sketchybar --set claude drawing=on icon.color="$RED" label="$num · !" label.color="$RED"
        return
    fi
    color="$(tone "$five")"
    label="$num · ${five}%"
    # A nearly spent week blocks as surely as a spent 5 hours
    [ "$seven" -ge "$HOT" ] && label="$label · 7d ${seven}%" && color="$RED"
    sketchybar --set claude drawing=on icon.color="$color" label="$label" label.color="$LABEL_COLOR"
}

close_popup() {
    sketchybar --set claude popup.drawing=off --remove '/claude\.row\..*/' >/dev/null 2>&1
}

# "1d10h", "2h05m", "58m" until an ISO time
until_reset() {
    jq -rn --arg t "$1" '
        ($t | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) - now | floor
        | if . <= 0 then "now"
          elif . >= 86400 then "\(. / 86400 | floor)d\(. % 86400 / 3600 | floor)h"
          elif . >= 3600 then "\(. / 3600 | floor)h\(. % 3600 / 60 | floor | tostring | if length < 2 then "0" + . else . end)m"
          else "\(. / 60 | floor)m" end' 2>/dev/null
}

# printf pads by bytes and ↻ takes three, so pad by characters
pad() {
    local s="$1" width="$2"
    while [ "${#s}" -lt "$width" ]; do s="$s "; done
    printf '%s' "$s"
}

window() {
    local name="$1" pct="$2" at="$3" reset=""
    [ -n "$at" ] && [ "$at" != null ] && reset=" ↻$(until_reset "$at")"
    printf '%s %3s%%' "$name" "$pct"
    pad "$reset" 7
}

open_popup() {
    local args=() num email active five seven five_at seven_at state err label color i=0
    [ -f "$CACHE" ] || return
    close_popup
    while IFS=$'\t' read -r num email active five seven five_at seven_at state err; do
        if [ "$err" != "-" ] || [[ "$state" =~ dead|unknown|missing ]]; then
            label="$(printf '%-22.22s' "$email")  login needs attention"
            color="$RED"
        else
            label="$(printf '%-22.22s' "$email")  $(window 5h "$five" "$five_at")  $(window 7d "$seven" "$seven_at")"
            color="$(tone "$(( five > seven ? five : seven ))")"
            [ "$color" = "$ICON_COLOR" ] && color="$LABEL_COLOR"
        fi
        args+=(--add item "claude.row.$i" popup.claude
               --set "claude.row.$i"
                     icon="$([ "$active" = true ] && echo "●" || echo "○") $num"
                     icon.color="$([ "$active" = true ] && echo "$GREEN" || echo "$SPACE_INACTIVE")"
                     icon.padding_left=10 icon.padding_right=8
                     label="$label" label.color="$color" label.padding_right=12
                     background.drawing=off
                     click_script="$SELF switch $num")
        i=$((i + 1))
    done < <(jq -r '.[] | [.num, .email, .active,
                           (.usage.five_hour.utilization // 0 | floor), (.usage.seven_day.utilization // 0 | floor),
                           (.usage.five_hour.resets_at // "null"), (.usage.seven_day.resets_at // "null"),
                           .token_state, (.error // "-")] | @tsv' "$CACHE")
    args+=(--add item claude.row.dashboard popup.claude
           --set claude.row.dashboard
                 icon="󰕮" icon.color="$ICON_COLOR" icon.padding_left=10 icon.padding_right=8
                 label="Open ccswitch dashboard" label.color="$SPACE_INACTIVE" label.padding_right=12
                 background.drawing=off
                 click_script="$SELF dashboard")
    sketchybar "${args[@]}" --set claude popup.drawing=on
}

switch_to() {
    local cc
    close_popup
    cc="$(find_ccswitch)" || return
    sketchybar --set claude label="switching…"
    "$cc" --switch-to "$1" >/dev/null 2>&1
    refresh
}

open_dashboard() {
    close_popup
    # Herdr opens the plugin pane in its client; bring Ghostty forward so it shows
    open -a Ghostty
    herdr plugin pane open --plugin wayne930242.ccswitch --entrypoint dashboard --focus >/dev/null 2>&1
}

case "${1:-}" in
    toggle)
        if [ "$(sketchybar --query claude | jq -r '.popup.drawing')" = on ]; then close_popup; else open_popup; fi
        ;;
    switch) switch_to "${2:?account number}" ;;
    dashboard) open_dashboard ;;
    *)
        case "${SENDER:-}" in
            mouse.exited.global)
                [ "$(sketchybar --query claude | jq -r '.popup.drawing')" = on ] && close_popup
                ;;
            *) refresh ;;
        esac
        ;;
esac
exit 0
