#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Get weather from wttr.in (free, no API key needed)
# Format: %c = icon, %t = temperature
WEATHER=$(curl -s "wttr.in/?format=%t" 2>/dev/null | tr -d '+' | xargs)
CONDITION=$(curl -s "wttr.in/?format=%c" 2>/dev/null | xargs)

if [ -n "$WEATHER" ] && [[ ! "$WEATHER" =~ "Unknown" ]]; then
    TEMP="$WEATHER"

    # Map weather emoji to nerd font icons
    case "$CONDITION" in
        "☀️"|"☀"|"🌞") ICON="󰖙" ;;  # Clear/Sunny
        "⛅"|"🌤"|"⛅️") ICON="󰖕" ;;  # Partly cloudy
        "☁️"|"☁"|"🌥") ICON="󰖐" ;;  # Cloudy
        "🌧"|"🌦"|"🌧️") ICON="󰖗" ;;  # Rain
        "⛈"|"🌩"|"⛈️") ICON="󰙾" ;;  # Thunderstorm
        "🌨"|"❄"|"🌨️") ICON="󰖘" ;;  # Snow
        "🌫"|"🌫️") ICON="󰖑" ;;      # Fog
        *) ICON="󰖐" ;;
    esac

    sketchybar --set "$NAME" icon="$ICON" label="$TEMP"
else
    sketchybar --set "$NAME" icon="󰖐" label="--"
fi
