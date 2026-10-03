#!/usr/bin/env bash

set -euo pipefail

if [[ "$SENDER" == "front_app_switched" ]]; then
    sketchybar --set "$NAME" label="$INFO"
fi
