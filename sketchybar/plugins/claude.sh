#!/usr/bin/env bash

# The Claude pill (items/claude.sh):
#	claude.sh               refresh: ccswitch --json into the cache, then redraw the pill
#	claude.sh toggle        open the popup from the cache, refreshing it if accounts changed, or close it
#	claude.sh switch N      switch to account N, then refresh
#	claude.sh dashboard     open ccswitch's dashboard in Herdr
# Only the refresh touches the network; the popup draws from the cache at once, then refreshes
# and redraws if ccswitch's local account list no longer matches the cache.

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

# An account's state, from ccswitch's token_state and usage error: ok; login (log in again, red);
# limited (usage API or token renewal rate limited, yellow); unavailable (usage not fetched for a
# passing reason such as the network or a token Claude Code renews on use, yellow)
STATUS='def status:
    if (.token_state | IN("relogin", "save-failed", "missing", "unknown"))
       or ((.error // "") | test("unauthorized")) then "login"
    elif ((.error // "") | test("rate limited")) or .token_state == "refresh-rate-limited" then "limited"
    elif .error != null or .usage == null then "unavailable"
    else "ok" end;'

# Fetch ccswitch --json into the cache; fails when no usable ccswitch is installed
fetch() {
    local cc json
    # A ccswitch older than --json (1.3.0) can't feed the pill
    if ! cc="$(find_ccswitch)" || ! "$cc" --help 2>/dev/null | grep -q -- '--json'; then
        return 1
    fi
    if json="$("$cc" --json 2>/dev/null)" && jq -e 'type == "array"' >/dev/null 2>&1 <<<"$json"; then
        mkdir -p "$(dirname "$CACHE")"
        (umask 077 && printf '%s\n' "$json" >"$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE")
    fi
}

refresh() {
    fetch || { sketchybar --set claude drawing=off; return; }
    draw_pill
}

popup_open() {
    [ "$(sketchybar --query claude | jq -r '.popup.drawing')" = on ]
}

# "num email active" per account, from the local --list (no network) and from the cache
listed_accounts() {
    local cc
    cc="$(find_ccswitch)" || return 1
    "$cc" --list 2>/dev/null | sed -nE 's/^ *([0-9]+): ([^ ]+) \(active\)$/\1 \2 true/p; s/^ *([0-9]+): ([^ ]+)$/\1 \2 false/p'
}

cached_accounts() {
    jq -r '.[] | "\(.num) \(.email) \(.active)"' "$CACHE" 2>/dev/null
}

# Open from the cache at once; when accounts were added, removed, or switched outside the pill
# since the last refresh, refresh and redraw. Usage alone waits for the 5-minute refresh, so
# opening the popup does not spend usage API calls (it rate-limits).
open_and_refresh() {
    local listed
    open_popup
    listed="$(listed_accounts)" || return
    [ -n "$listed" ] && [ "$listed" != "$(cached_accounts)" ] || return
    refresh
    popup_open && open_popup
}

draw_pill() {
    local num seven status
    [ -f "$CACHE" ] || { sketchybar --set claude drawing=off; return; }
    # Anthropic dropped the 5-hour window (2026-11): the week is the only limit left
    read -r num seven status < <(jq -r "$STATUS"'
        (map(select(.active)) | .[0]) as $a
        | if $a == null then "- 0 login"
          else "\($a.num) \($a.usage.seven_day.utilization // 0 | floor) \($a | status)" end' "$CACHE")
    case "$status" in
        login) sketchybar --set claude drawing=on icon.color="$RED" label="$num · !" label.color="$RED" ;;
        limited | unavailable)
            sketchybar --set claude drawing=on icon.color="$YELLOW" label="$num · 7d ?" label.color="$YELLOW" ;;
        *) sketchybar --set claude drawing=on icon.color="$(tone "$seven")" label="$num · 7d ${seven}%" label.color="$LABEL_COLOR" ;;
    esac
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
    local args=() num email active seven seven_at status label color i=0
    [ -f "$CACHE" ] || return
    close_popup
    while IFS=$'\t' read -r num email active seven seven_at status; do
        label="$(printf '%-22.22s' "$email")  "
        case "$status" in
            login) label+="login needs attention"; color="$RED" ;;
            limited) label+="usage rate limited, retry later"; color="$YELLOW" ;;
            unavailable) label+="usage unavailable for now"; color="$YELLOW" ;;
            *)
                label+="$(window 7d "$seven" "$seven_at")"
                color="$(tone "$seven")"
                [ "$color" = "$ICON_COLOR" ] && color="$LABEL_COLOR"
                ;;
        esac
        args+=(--add item "claude.row.$i" popup.claude
               --set "claude.row.$i"
                     icon="$([ "$active" = true ] && echo "●" || echo "○") $num"
                     icon.color="$([ "$active" = true ] && echo "$GREEN" || echo "$SPACE_INACTIVE")"
                     icon.padding_left=10 icon.padding_right=8
                     label="$label" label.color="$color" label.padding_right=12
                     background.drawing=off
                     click_script="$SELF switch $num")
        i=$((i + 1))
    done < <(jq -r "$STATUS"'.[] | [.num, .email, .active,
                           (.usage.seven_day.utilization // 0 | floor), (.usage.seven_day.resets_at // "null"),
                           status] | @tsv' "$CACHE")
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
        if popup_open; then close_popup; else open_and_refresh; fi
        ;;
    switch) switch_to "${2:?account number}" ;;
    dashboard) open_dashboard ;;
    *)
        case "${SENDER:-}" in
            mouse.exited.global)
                popup_open && close_popup
                ;;
            *) refresh ;;
        esac
        ;;
esac
exit 0
