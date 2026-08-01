#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# The active keyboard/IME source is the last non-"Non Keyboard Input Method"
# entry in AppleSelectedInputSources. AppleCurrentKeyboardLayoutInputSourceID
# is unreliable for third-party IMEs (e.g. vChewing) since it tracks the
# underlying keyboard layout, not the active input method.
SOURCE_ID=$(defaults read com.apple.HIToolbox AppleSelectedInputSources 2>/dev/null \
    | plutil -convert json -o - - 2>/dev/null \
    | jq -r '[.[] | select(.InputSourceKind != "Non Keyboard Input Method")]
              | last
              | (."Input Mode" // ."KeyboardLayout Name" // ."Bundle ID" // "")' 2>/dev/null)

case "$SOURCE_ID" in
    *vChewing*)
        LABEL="威"
        ;;
    *Zhuyin*|*Bopomofo*)
        LABEL="注"
        ;;
    *Pinyin*|*SCIM*)
        LABEL="拼"
        ;;
    *Cangjie*)
        LABEL="倉"
        ;;
    *Japanese*|*Kotoeri*)
        LABEL="日"
        ;;
    ""|*ABC*|*[Uu][Ss]*)
        LABEL="英"
        ;;
    *)
        LABEL="${SOURCE_ID##*.}"
        LABEL="${LABEL:0:2}"
        ;;
esac

sketchybar --set "$NAME" icon="󰌌" label="$LABEL"
