#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Ghostty 沒有原生 tab toolbar 了（window-decoration = none 停用 macOS
# native tab，見 ghostty/config），這裡用 SketchyBar 補一排可點擊的
# tab 色塊，掛在 front_app 的 popup 下面。不是要點 front_app 才展開，
# 是 plugins/ghostty_tabs.sh 直接用 popup.drawing 開關，Ghostty 一
# 變成前景 app 就自動浮現。排序規則跟 hammerspoon/init.lua 的
# CMD+1-9 用同一套（window-id 由小到大）。

sketchybar --add event ghostty_focus_changed

# popup 預設垂直堆疊子項目，改成水平排成一排；y_offset 跟 front_app 的
# pill 拉開一點距離，避免視覺上黏在一起
sketchybar --set front_app popup.horizontal=on popup.y_offset=6

for i in $(seq 1 9); do
    sketchybar --add item "ghostty_tab.$i" popup.front_app \
               --set "ghostty_tab.$i" \
                     drawing=off \
                     padding_left=4 \
                     padding_right=4 \
                     icon.font="Hack Nerd Font Mono:Bold:12.0" \
                     label.font="Hack Nerd Font Mono:Semibold:12.0" \
                     background.corner_radius=6 \
                     background.height=26 \
                     background.padding_left=4 \
                     background.padding_right=4
done

# 隱形控制器：只負責訂閱觸發時機，實際畫面更新都在 plugins/ghostty_tabs.sh
sketchybar --add item ghostty_tabs_controller left \
           --set ghostty_tabs_controller \
                 drawing=off \
                 script="$PLUGIN_DIR/ghostty_tabs.sh" \
           --subscribe ghostty_tabs_controller front_app_switched ghostty_focus_changed
