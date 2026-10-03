#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$PROJECT_DIR/.aerospace.toml"

expected_startup_layout="after-startup-command = ['layout --workspace Q --root h_tiles']"

if ! grep -Fqx "$expected_startup_layout" "$CONFIG_FILE"; then
    echo "FAIL: Q workspace is not forced to h_tiles after AeroSpace startup" >&2
    exit 1
fi

echo "PASS: AeroSpace startup layout contract"

# persistent-workspaces is the single workspace list: every entry needs a focus
# binding, a move binding, and a monitor assignment, and SketchyBar reads it
workspaces=$(grep -m1 '^persistent-workspaces' "$CONFIG_FILE" | grep -oE '"[^"]+"' | tr -d '"')
if [[ -z "$workspaces" ]]; then
    echo "FAIL: persistent-workspaces is missing or empty" >&2
    exit 1
fi

for ws in $workspaces; do
    key=$(tr '[:upper:]' '[:lower:]' <<<"$ws")
    for line in "alt-$key = 'workspace $ws'" "alt-shift-$key = 'move-node-to-workspace $ws'"; do
        if ! grep -Fq "$line" "$CONFIG_FILE"; then
            echo "FAIL: workspace $ws has no binding: $line" >&2
            exit 1
        fi
    done
    if ! grep -Eq "^$ws = " "$CONFIG_FILE"; then
        echo "FAIL: workspace $ws has no workspace-to-monitor-force-assignment" >&2
        exit 1
    fi
done

SPACES_ITEM="$PROJECT_DIR/sketchybar/items/spaces.sh"
if grep -Eq '^WORKSPACES=\("' "$SPACES_ITEM" || ! grep -Fq 'persistent-workspaces' "$SPACES_ITEM"; then
    echo "FAIL: sketchybar spaces must read persistent-workspaces instead of hard-coding them" >&2
    exit 1
fi

echo "PASS: AeroSpace workspace list contract"

# The mode indicator is driven by on-mode-changed, not per-binding triggers
if ! grep -Fqx "on-mode-changed = ['exec-and-forget sketchybar --trigger aerospace_mode_change']" "$CONFIG_FILE" \
    || grep -Fq 'aerospace_mode_change MODE=' "$CONFIG_FILE"; then
    echo "FAIL: mode changes must notify SketchyBar only through on-mode-changed" >&2
    exit 1
fi

echo "PASS: AeroSpace mode callback contract"
