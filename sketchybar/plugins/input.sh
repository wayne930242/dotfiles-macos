#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get current input source
INPUT_SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep "KeyboardLayout Name" | head -1 | awk -F'"' '{print $2}')

# If not found via that method, try another approach
if [ -z "$INPUT_SOURCE" ]; then
    INPUT_SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null | awk -F'.' '{print $NF}')
fi

# Fallback to checking input source list
if [ -z "$INPUT_SOURCE" ]; then
    INPUT_SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep -A1 "InputSourceKind" | grep "Input Mode" | awk -F'"' '{print $2}')
fi

# Map common input sources to display names
case "$INPUT_SOURCE" in
    "ABC"|"US"|"U.S."|"USExtended")
        LABEL="EN"
        ICON="󰌌"
        ;;
    "Zhuyin"|"Bopomofo"|"TraditionalChinese")
        LABEL="注"
        ICON="󰗊"
        ;;
    "Pinyin"|"SimplifiedChinese"|"SCIM")
        LABEL="拼"
        ICON="󰗊"
        ;;
    "Cangjie"|"Quick")
        LABEL="倉"
        ICON="󰗊"
        ;;
    "Japanese"|"Hiragana"|"Katakana")
        LABEL="JP"
        ICON="󰗊"
        ;;
    *)
        # Try to extract a short name
        if [ -n "$INPUT_SOURCE" ]; then
            LABEL="${INPUT_SOURCE:0:3}"
        else
            LABEL="??"
        fi
        ICON="󰌌"
        ;;
esac

sketchybar --set "$NAME" label="$LABEL" icon="$ICON"
