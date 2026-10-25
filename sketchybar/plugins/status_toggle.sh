#!/usr/bin/env bash

set -euo pipefail

# Opens or closes the status pill's popup; on opening, status_popup refreshes its items,
# which do not update while hidden.
sketchybar --set status popup.drawing=toggle
if [[ "$(sketchybar --query status | jq -r '.popup.drawing')" == "on" ]]; then
    sketchybar --trigger status_popup
fi
