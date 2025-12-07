#!/bin/bash

MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

if [ "$MIC_VOLUME" -eq 0 ]; then
    osascript -e 'set volume input volume 70'
else
    osascript -e 'set volume input volume 0'
fi

sketchybar --trigger volume_change
