#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# 觸發時機：front_app_switched（切到/離開 Ghostty）、ghostty_focus_changed
# （AeroSpace on-focus-changed，在 Ghostty 內部切視窗，見 .aerospace.toml）。
# 排序規則跟 hammerspoon/init.lua 的 CMD+1-9 用同一套：window-id 由小到大
# （系統全域遞增計數器，天然是建立順序，不用維護狀態檔），slot 9 固定對應
# 最新視窗（>9 個視窗時），兩邊保持一致。
#
# 全部用絕對路徑呼叫外部指令：SketchyBar 的 spawn 環境跟一般終端機不同，
# 不能假設 PATH 裡有 /opt/homebrew/bin（Ghostty 的 command 設定踩過這個坑）。
AEROSPACE_BIN="/opt/homebrew/bin/aerospace"
JQ_BIN="/usr/bin/jq"
GHOSTTY_BUNDLE_ID="com.mitchellh.ghostty"
SLOT_COUNT=9
TITLE_MAX_LEN=24

FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

# 注意：System Events 回的是底層執行檔名稱，Ghostty.app 裡的執行檔是小寫
# ghostty，不是 Finder/Dock 顯示的 "Ghostty"——實測過，不能想當然爾用大寫比對
if [ "${FRONT_APP,,}" != "ghostty" ]; then
    sketchybar --set front_app popup.drawing=off
    exit 0
fi

WINDOWS_JSON=$("$AEROSPACE_BIN" list-windows --monitor all --app-bundle-id "$GHOSTTY_BUNDLE_ID" --json 2>/dev/null)
FOCUSED_ID=$("$AEROSPACE_BIN" list-windows --focused --format "%{window-id}" 2>/dev/null)

mapfile -t IDS < <(echo "$WINDOWS_JSON" | "$JQ_BIN" -r 'sort_by(."window-id") | .[]."window-id"')
mapfile -t TITLES < <(echo "$WINDOWS_JSON" | "$JQ_BIN" -r 'sort_by(."window-id") | .[]."window-title"')

WINDOW_COUNT=${#IDS[@]}

if [ "$WINDOW_COUNT" -eq 0 ]; then
    sketchybar --set front_app popup.drawing=off
    exit 0
fi

for ((slot = 1; slot <= SLOT_COUNT; slot++)); do
    ITEM="ghostty_tab.$slot"

    if [ "$slot" -eq "$SLOT_COUNT" ] && [ "$WINDOW_COUNT" -gt "$SLOT_COUNT" ]; then
        idx=$((WINDOW_COUNT - 1))
    else
        idx=$((slot - 1))
    fi

    if [ "$idx" -ge "$WINDOW_COUNT" ]; then
        sketchybar --set "$ITEM" drawing=off
        continue
    fi

    WINDOW_ID="${IDS[$idx]}"
    TITLE="${TITLES[$idx]:-(無標題)}"
    if [ ${#TITLE} -gt "$TITLE_MAX_LEN" ]; then
        TITLE="${TITLE:0:$((TITLE_MAX_LEN - 3))}..."
    fi

    if [ "$WINDOW_ID" = "$FOCUSED_ID" ]; then
        BG_COLOR=$SPACE_BACKGROUND_ACTIVE
        FG_COLOR=$CYAN
    else
        BG_COLOR=$SPACE_BACKGROUND
        FG_COLOR=$SPACE_INACTIVE
    fi

    sketchybar --set "$ITEM" \
               drawing=on \
               icon="$slot" \
               icon.color="$FG_COLOR" \
               label="$TITLE" \
               label.color="$FG_COLOR" \
               label.drawing=on \
               background.color="$BG_COLOR" \
               background.drawing=on \
               click_script="$AEROSPACE_BIN focus --window-id $WINDOW_ID"
done

sketchybar --set front_app popup.drawing=on
