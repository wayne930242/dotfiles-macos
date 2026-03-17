#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Optional overrides:
#   WEATHER_LATITUDE / WEATHER_LONGITUDE to pin a fixed location.
LOCATION_CACHE="${TMPDIR:-/tmp}/sketchybar-weather-location.json"
LOCATION_CACHE_TTL=86400
GEO_API_URL="https://ipapi.co/json/"
WEATHER_API_URL="https://api.open-meteo.com/v1/forecast"

json_extract() {
    printf '%s' "$2" | plutil -extract "$1" raw -o - - 2>/dev/null
}

is_number() {
    [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

location_cache_is_fresh() {
    [ -f "$LOCATION_CACHE" ] || return 1

    local modified now
    modified=$(stat -f %m "$LOCATION_CACHE" 2>/dev/null) || return 1
    now=$(date +%s)

    [ $((now - modified)) -lt "$LOCATION_CACHE_TTL" ]
}

get_location_json() {
    local location_json latitude longitude

    if location_cache_is_fresh; then
        cat "$LOCATION_CACHE" 2>/dev/null
        return 0
    fi

    location_json=$(curl -fsS --max-time 10 "$GEO_API_URL" 2>/dev/null) || location_json=""
    latitude=$(json_extract latitude "$location_json")
    longitude=$(json_extract longitude "$location_json")

    if is_number "$latitude" && is_number "$longitude"; then
        printf '%s' "$location_json" > "$LOCATION_CACHE"
        printf '%s' "$location_json"
        return 0
    fi

    if [ -f "$LOCATION_CACHE" ]; then
        cat "$LOCATION_CACHE" 2>/dev/null
        return 0
    fi

    return 1
}

get_coordinates() {
    local latitude longitude location_json

    if is_number "$WEATHER_LATITUDE" && is_number "$WEATHER_LONGITUDE"; then
        printf '%s %s\n' "$WEATHER_LATITUDE" "$WEATHER_LONGITUDE"
        return 0
    fi

    location_json=$(get_location_json) || return 1
    latitude=$(json_extract latitude "$location_json")
    longitude=$(json_extract longitude "$location_json")

    if is_number "$latitude" && is_number "$longitude"; then
        printf '%s %s\n' "$latitude" "$longitude"
        return 0
    fi

    return 1
}

weather_icon() {
    case "$1" in
        0) echo "󰖙" ;;
        1|2) echo "󰖕" ;;
        3) echo "󰖐" ;;
        45|48) echo "󰖑" ;;
        51|53|55|56|57|61|63|65|66|67|80|81|82) echo "󰖗" ;;
        71|73|75|77|85|86) echo "󰖘" ;;
        95|96|99) echo "󰙾" ;;
        *) echo "󰖐" ;;
    esac
}

LOCATION=$(get_coordinates)
LATITUDE=${LOCATION%% *}
LONGITUDE=${LOCATION##* }

if is_number "$LATITUDE" && is_number "$LONGITUDE"; then
    WEATHER_JSON=$(curl -fsS --max-time 10 \
        "$WEATHER_API_URL?latitude=$LATITUDE&longitude=$LONGITUDE&current=temperature_2m,weather_code&temperature_unit=celsius&timezone=auto" \
        2>/dev/null)
else
    WEATHER_JSON=""
fi

TEMP_RAW=$(json_extract current.temperature_2m "$WEATHER_JSON")
WEATHER_CODE=$(json_extract current.weather_code "$WEATHER_JSON")

if is_number "$TEMP_RAW" && [[ "$WEATHER_CODE" =~ ^[0-9]+$ ]]; then
    ICON=$(weather_icon "$WEATHER_CODE")
    TEMP=$(printf '%.0f°C' "$TEMP_RAW")
    sketchybar --set "$NAME" icon="$ICON" label="$TEMP"
else
    sketchybar --set "$NAME" icon="󰖐" label="--"
fi
